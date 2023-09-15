--------------------------------------------------------------------------------
-- jarv_cpu.vhd                                                               --
-- Just Another RISC-V: CPU variant                                           --
-- privilege levels: M only                                                   --
-- base ISA: RV32I or RV32E (generic option)                                  --
-- Standard Extensions:                                                       --
--   Zicsr (Control and Status Register Instructions)                         --
--   C (Compressed Instructions) (generic option)                             --
-- memory interface: simple synchronous, dual port                            --
-- interrupts: single IRQ                                                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation       --
-- either version 3 of the License or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package jarv_cpu_pkg is

  component jarv_cpu is
  end component jarv_cpu;

end package jarv_cpu_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.jarv_g_pkg.all;

entity jarv_cpu is
  generic (
    tag_width              : positive := 4;
    opt_E                  : boolean := false;              -- base ISA: false for RV32I, true for RV32E
    opt_C                  : boolean := true;               -- C Standard Extension: true to enable
    opt_relax_decode       : boolean := false;              -- relaxed instruction decoding: true to enable
    dont_care              : std_logic := '-';              -- change to 'X' for simulation
    reset_pc               : std_logic_vector(31 downto 0)
  );
  port (
    rst      : std_logic;                                   -- async reset
    clk      : std_logic;
    if_addr  : out std_logic_vector(31 downto 1);
    if_data  : in  std_logic_vector(31 downto 0);
    ls_re    : out std_logic;
    ls_we    : out std_logic;
    ls_sz    : out std_logic_vector(1 downto 0);
    ls_addr  : out std_logic_vector(31 downto 0);
    ls_wdata : out std_logic_vector(31 downto 0);
    ls_rdata : in  std_logic_vector(31 downto 0)

    --debug_exec  : out std_logic;
    --debug_pc    : out u32_t;
    --debug_reg : out u32_array_t(0 to 31);
    --debug_csr   : out u32_array_t(0 to csr_num-1)
  );
end entity jarv_cpu;

architecture synth of jarv_cpu is

  --------------------------------------------------------------------------------
  -- types

  subtype tag_t is std_logic_vector(tag_width-1 downto 0);
  type tag_array_t is array(natural range <>) of tag_t;

  -- destination register operations
  type rd_op_t is (
    NOP, -- no change
    INT, -- update from internally generated value e.g. another register or ALU
    EXT, -- update from external (memory)
    CSR  -- update from CSR
  );

  type csr_def_t is record
    name      : string;
    address   : csra_t;
    writable  : std_logic_vector(31 downto 0);
    hardwired : std_logic_vector(31 downto 0);
  end record csr_def_t;

  type csr_defs_t is array(natural range <>) of csr_def_t;

  --------------------------------------------------------------------------------
  -- constants

  constant misa_val   : std_logic_vector(31 downto 0) := ternary(opt_C,x"40000104",x"40000100");
  constant iaddr_mask : std_logic_vector(31 downto 0) := ternary(opt_C,x"FFFFFFFE",x"FFFFFFFC");

  constant csr_defs : csr_defs_t := (
    ( "misa"      , CSRA_MISA      , x"00000000" , misa_val    ),
    ( "mstatus"   , CSRA_MSTATUS   , x"00000000" , x"00000000" ),
    ( "mstatush"  , CSRA_MSTATUSH  , x"00000000" , x"00000000" ),
    ( "mtvec"     , CSRA_MTVEC     , iaddr_mask  , x"00000000" ),
    ( "mip"       , CSRA_MIP       , x"00000000" , x"00000000" ),
    ( "mie"       , CSRA_MIE       , x"FFFFFFFF" , x"00000000" ),
    ( "mcycle"    , CSRA_MCYCLE    , x"FFFFFFFF" , x"00000000" ),
    ( "minstret"  , CSRA_MINSTRET  , x"FFFFFFFF" , x"00000000" ),
    ( "mcycleh"   , CSRA_MCYCLEH   , x"FFFFFFFF" , x"00000000" ),
    ( "minstreth" , CSRA_MINSTRETH , x"FFFFFFFF" , x"00000000" ),
    ( "mscratch"  , CSRA_MSCRATCH  , x"FFFFFFFF" , x"00000000" ),
    ( "mepc"      , CSRA_MEPC      , x"FFFFFFFC" , x"00000000" ),
    ( "mcause"    , CSRA_MCAUSE    , x"FFFFFFFF" , x"00000000" )
  );

  constant reg_count : integer := ternary(opt_E,16,32);
  constant csr_count : integer := csr_defs'pos(csr_defs'right)+1;

  --------------------------------------------------------------------------------
  -- signals

  -- registers
  signal pc            : reg_t;                         -- program counter
  signal btarget       : reg_t;                         -- branch target
  signal reg           : reg_array_t(0 to reg_count-1); -- register file
  signal csr           : reg_array_t(0 to csr_count-1); -- control and status registers

  -- tags
  signal tag_pc        : tag_t;
  signal tag_btarget   : tag_t;
  signal tag_reg       : tag_array_t(reg'range);
  signal tag_csr       : tag_array_t(csr'range);

  -- register related
  signal pc_next       : reg_t;
  signal reg_prev    : reg_array_t(0 to 31); --
  signal csr_prev      : reg_array_t(0 to csr_num-1);
  signal rs1_sel       : std_logic_vector(4 downto 0); -- source register 1 select
  signal rs1_val       : reg_t;                        -- source register 1 value
  signal rs2_sel       : std_logic_vector(4 downto 0); -- source register 2 select
  signal rs2_val       : reg_t;                        -- source register 2 value
  signal rd_op_next    : rd_op_t;
  signal rd_op         : rd_op_t;
  signal rd_sel_next   : std_logic_vector(4 downto 0); -- destination register 1 select (for next cycle)
  signal rd_sel        : std_logic_vector(4 downto 0); -- destination register 1 select
  signal rd_val_next   : reg_t;
  signal rd_val        : reg_t;
  signal rd_load       : std_logic;
  signal rd_width_next : std_logic_vector(2 downto 0);
  signal rd_width      : std_logic;
  signal csr_re        : std_logic;
  signal csr_we        : std_logic;
  signal csr_addr      : csra_t;
  signal csr_val       : reg_t;
  signal csr_val_next  : reg_t;

  -- 32 bit instruction fields
  signal i32_opcode   : std_logic_vector( 6 downto 0); -- instruction field: i32_opcode
  signal i32_rd       : std_logic_vector( 4 downto 0); -- instruction field: destination register
  signal i32_funct3   : std_logic_vector( 2 downto 0); -- instruction field:
  signal i32_rs1      : std_logic_vector( 4 downto 0); -- instruction field: source register 1
  signal i32_rs2      : std_logic_vector( 4 downto 0); -- instruction field: source register 2
  signal i32_funct7   : std_logic_vector( 6 downto 0); -- instruction field:
  signal i32_i_imm    : std_logic_vector(11 downto 0); -- instruction field:
  signal i32_s_imm    : std_logic_vector(11 downto 0); -- instruction field:
  signal i32_b_imm    : std_logic_vector(12 downto 1); -- instruction field:
  signal i32_u_imm    : std_logic_vector(19 downto 0); -- instruction field:
  signal i32_j_imm    : std_logic_vector(20 downto 1); -- instruction field:
  signal i32_shamt    : std_logic_vector(4 downto 0);

  -- 16 bit (compressed) instruction fields
  signal i16_opcode   : std_logic_vector(4 downto 0);
  signal i16_rs1      : std_logic_vector(4 downto 0);
  signal i16_rs1_c    : std_logic_vector(2 downto 0);
  signal i16_rs2      : std_logic_vector(4 downto 0);
  signal i16_rs2_c    : std_logic_vector(2 downto 0);
  signal i16_rd       : std_logic_vector(4 downto 0);
  signal i16_rd_c     : std_logic_vector(2 downto 0);
  signal i16_imm6     : std_logic_vector(5 downto 0);
  signal i16_j_imm    : std_logic_vector(11 downto 1);
  signal i16_b_imm    : std_logic_vector(8 downto 1);
  signal i16_funct1   : std_logic;
  signal i16_funct2   : std_logic_vector(1 downto 0);
  signal i16_funct2b  : std_logic_vector(1 downto 0);
  signal i16_funct3   : std_logic_vector(2 downto 0);
  signal i16_funct4   : std_logic_vector(3 downto 0);
  signal i16_shamt    : std_logic_vector(4 downto 0);
  signal i16_loffset6 : std_logic_vector(7 downto 2);
  signal i16_soffset6 : std_logic_vector(7 downto 2);
  signal i16_offset5  : std_logic_vector(6 downto 2);
  signal i16_nzuimm   : std_logic_vector(9 downto 0);

  -- comparators for conditional set and branch instructions
  signal comps_lt     : std_logic;
  signal comps_ltu    : std_logic;
  signal comps_lti    : std_logic;
  signal comps_ltiu   : std_logic;
  signal compb_eq     : std_logic;
  signal compb_ne     : std_logic;
  signal compb_lt     : std_logic;
  signal compb_ge     : std_logic;
  signal compb_ltu    : std_logic;
  signal compb_geu    : std_logic;

  --------------------------------------------------------------------------------
  -- aliases

  -- instruction
  alias  i32          : std_logic_vector(31 downto 0) is if_data;
  alias  i16          : std_logic_vector(15 downto 0) is if_data(15 downto 0);

  -- CSRs
  alias csr_misa      : reg_t is csr(csr_idx(csr_defs, "misa"      ));
  alias csr_mstatus   : reg_t is csr(csr_idx(csr_defs, "mstatus"   ));
  alias csr_mstatush  : reg_t is csr(csr_idx(csr_defs, "mstatush"  ));
  alias csr_mtvec     : reg_t is csr(csr_idx(csr_defs, "mtvec"     ));
  alias csr_mip       : reg_t is csr(csr_idx(csr_defs, "mip"       ));
  alias csr_mie       : reg_t is csr(csr_idx(csr_defs, "mie"       ));
  alias csr_mcycle    : reg_t is csr(csr_idx(csr_defs, "mcycle"    ));
  alias csr_minstret  : reg_t is csr(csr_idx(csr_defs, "minstret"  ));
  alias csr_mcycleh   : reg_t is csr(csr_idx(csr_defs, "mcycleh"   ));
  alias csr_minstreth : reg_t is csr(csr_idx(csr_defs, "minstreth" ));
  alias csr_mscratch  : reg_t is csr(csr_idx(csr_defs, "mscratch"  ));
  alias csr_mepc      : reg_t is csr(csr_idx(csr_defs, "mepc"      ));
  alias csr_mcause    : reg_t is csr(csr_idx(csr_defs, "mcause"    ));

  -- CSR bit fields
  alias  csr_mstatus_uie  : std_logic                     is csr_mstatus(0);
  alias  csr_mstatus_sie  : std_logic                     is csr_mstatus(1);
  alias  csr_mstatus_hie  : std_logic                     is csr_mstatus(2);
  alias  csr_mstatus_mie  : std_logic                     is csr_mstatus(3);
  alias  csr_mstatus_upie : std_logic                     is csr_mstatus(4);
  alias  csr_mstatus_spie : std_logic                     is csr_mstatus(5);
  alias  csr_mstatus_hpie : std_logic                     is csr_mstatus(6);
  alias  csr_mstatus_mpie : std_logic                     is csr_mstatus(7);
  alias  csr_mstatus_spp  : std_logic                     is csr_mstatus(8);
  alias  csr_mstatus_hpp  : std_logic_vector(1 downto 0)  is csr_mstatus(10 downto 9);
  alias  csr_mstatus_mpp  : std_logic_vector(1 downto 0)  is csr_mstatus(12 downto 11);
  alias  csr_mstatus_fs   : std_logic_vector(1 downto 0)  is csr_mstatus(14 downto 13);
  alias  csr_mstatus_xs   : std_logic_vector(1 downto 0)  is csr_mstatus(16 downto 15);
  alias  csr_mstatus_mprv : std_logic                     is csr_mstatus(17);
  alias  csr_mstatus_sum  : std_logic                     is csr_mstatus(18);
  alias  csr_mstatus_mxr  : std_logic                     is csr_mstatus(19);
  alias  csr_mstatus_tvm  : std_logic                     is csr_mstatus(20);
  alias  csr_mstatus_tw   : std_logic                     is csr_mstatus(21);
  alias  csr_mstatus_tsr  : std_logic                     is csr_mstatus(22);
  alias  csr_mstatus_rsvd : std_logic_vector(7 downto 0)  is csr_mstatus(30 downto 23);
  alias  csr_mstatus_sd   : std_logic                     is csr_mstatus(31);
  alias  csr_mie_usie     : std_logic                     is csr_mip(0);
  alias  csr_mie_ssie     : std_logic                     is csr_mip(1);
  alias  csr_mie_msie     : std_logic                     is csr_mip(3);
  alias  csr_mie_utie     : std_logic                     is csr_mip(4);
  alias  csr_mie_stie     : std_logic                     is csr_mip(5);
  alias  csr_mie_mtie     : std_logic                     is csr_mip(7);
  alias  csr_mie_ueie     : std_logic                     is csr_mip(8);
  alias  csr_mie_seie     : std_logic                     is csr_mip(9);
  alias  csr_mie_meie     : std_logic                     is csr_mip(11);
  alias  csr_mie_rsvd     : std_logic_vector(19 downto 0) is csr_mie(31 downto 12);
  alias  csr_mtvec_mode   : std_logic_vector(1 downto 0)  is csr_mtvec(1 downto 0);
  alias  csr_mtvec_base   : std_logic_vector(31 downto 2) is csr_mtvec(31 downto 2);
  alias  csr_mip_usip     : std_logic                     is csr_mip(0);
  alias  csr_mip_ssip     : std_logic                     is csr_mip(1);
  alias  csr_mip_msip     : std_logic                     is csr_mip(3);
  alias  csr_mip_utip     : std_logic                     is csr_mip(4);
  alias  csr_mip_stip     : std_logic                     is csr_mip(5);
  alias  csr_mip_mtip     : std_logic                     is csr_mip(7);
  alias  csr_mip_ueip     : std_logic                     is csr_mip(8);
  alias  csr_mip_seip     : std_logic                     is csr_mip(9);
  alias  csr_mip_meip     : std_logic                     is csr_mip(11);
  alias  csr_mcause_code  : std_logic_vector(3 downto 0)  is csr_mcause(3 downto 0);
  alias  csr_mcause_type  : std_logic                     is csr_mcause(31);

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- instruction fetch

  if_addr <= std_logic_vector(pc_next(31 downto 1));

  --------------------------------------------------------------------------------
  -- instruction bit fields

  i32_opcode   <= i32( 6 downto  0);
  i32_rd       <= i32(11 downto  7);
  i32_funct3   <= i32(14 downto 12);
  i32_rs1      <= i32(19 downto 15);
  i32_rs2      <= i32(24 downto 20);
  i32_funct7   <= i32(31 downto 25);
  i32_funct12  <= i32(31 downto 20);
  i32_i_imm    <= i32(31 downto 20);
  i32_s_imm    <= i32(31 downto 25) & i32(11 downto 7);
  i32_b_imm    <= i32(31) & i32(7) & i32(30 downto 25) & i32(11 downto 8);
  i32_u_imm    <= i32(31 downto 12);
  i32_j_imm    <= i32(31) & i32(19 downto 12) & i32(20) & i32(30 downto 21);
  i32_shamt    <= i32(24 downto 20);

  i16_opcode   <= i16(15 downto 13) & i16(1 downto 0);
  i16_rs1      <= i16(11 downto 7);
  i16_rs1_c    <= i16(9 downto 7);
  i16_rs2      <= i16(6 downto 2);
  i16_rs2_c    <= i16(4 downto 2);
  i16_rd       <= i16(11 downto 7);
  i16_rd_c     <= i16(4 downto 2);
  i16_rd_rs1   <= i16(11 downto 7);
  i16_rd_rs1_c <= i16(9 downto 7);
  i16_nzuimm   <= i16(5 downto 2) & i16(9 downto 6) & i16(2) & i16(3);
  i16_j_imm    <= i16(12) & i16(8) & i16(10 downto 9) & i16(6) & i16(7) & i16(2) & i16(11) & i16(5 downto 3);
  i16_b_imm    <= i16(12) & i16(6 downto 5) & i16(2) & i16(11 downto 10) & i16(4 downto 3);
  i16_imm6     <= i16(12) & i16(6 downto 2);
  i16_shamt    <= i16(6 downto 2);
  i16_funct1   <= i16(12);
  i16_funct2   <= i16(6 downto 5);
  i16_funct2b  <= i16(11 downto 10);
  i16_funct3   <= i16(15 downto 13);
  i16_funct6   <= i16(15 downto 10);
  i16_loffset6 <= i16(3 downto 2) & i16(12) & i16(6 downto 4);
  i16_soffset6 <= i16(8 downto 7) & i16(12 downto 9);
  i16_offset5 <= i16(5) & i16(12 downto 10) & i16(6);

  --------------------------------------------------------------------------------
  -- instruction decode

  -- beware incomplete sensitivity list
  process(rst,i32,comps,compb,irq,csr_we)

    variable v_exception : boolean;
    variable v_exception : exception_t;
    variable v_csr_bad   : boolean;

  begin

    -- defaults

    v_exception       := false;
    v_exception_cause := -1;
    v_csr_bad         := false;

    rs1_sel       <= (others => dont_care);
    rs2_sel       <= (others => dont_care);
    rd_op_next    <= NOP;
    rd_sel_next   <= (others => dont_care);
    rd_val_next   <= (others => dont_care);
    rd_width_next <= (others => dont_care);
    ls_re         <= '0';
    ls_we         <= '0';
    ls_sz         <= (others => dont_care);
    ls_addr       <= (others => dont_care);
    ls_wdata      <= (others => dont_care);
    csr_re        <= '0';
    csr_we        <= '0';
    csr_addr      <= (others => dont_care);
    csr_val_next  <= (others => dont_care);

    if opt_C and i32_opcode(1 downto 0) /= "11" then -- 16 bit instruction
      pc_next <= pc+2;
    else -- 32 bit instruction
      pc_next <= pc+4;
    end if;

    -- instruction decode

    --------------------------------------------------------------------------------
    -- reset

    if rst = '1' then
      pc_next <= reset_pc;

    --------------------------------------------------------------------------------
    -- external interrupt

    elsif irq = '1' and (interrupts enabled) then
      pc_next    <= csr_mtvec_base;
      csr_mepc   <= pc(31 downto 1) & '0';
      csr_mcause <=

    --------------------------------------------------------------------------------
    -- RV32I/RV32E base instruction set

    -- LUI
    elsif i32_opcode = "0110111" then
      mnemonic    <= "LUI";
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= i32_u_imm & x"000";

    -- AUIPC
    elsif i32_opcode = "0010111" then
      mnemonic    <= "AUIPC";
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= pc+(i32_u_imm & x"000");

    -- JAL
    elsif i32_opcode = "1101111" then
      mnemonic    <= "JAL";
      rs1_sel     <= i32_rs1;
      pc_next     <= pc+signex(i32_j_imm & '0');
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= pc+4;

    -- JALR
    elsif i32_opcode = "1100111" then
      mnemonic    <= "JALR";
      rs1_sel     <= i32_rs1;
      pc_next     <= rs1_val+signex(i32_i_imm); -- pc_next(0) forced to zero below
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= pc+4;

    -- BEQ
    elsif i32_opcode = "1100011" and i32_funct3 = "000" then
      mnemonic <= "BEQ";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      if compb_eq = '1' then
        pc_next <= pc+signex(i32_b_imm & '0');
      end if;

    -- BNE
    elsif i32_opcode = "1100011" and i32_funct3 = "001" then
      mnemonic <= "BNE";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      if compb_ne = '1' then
        pc_next <= pc+signex(i32_b_imm & '0');
      end if;

    -- BLT
    elsif i32_opcode = "1100011" and i32_funct3 = "100" then
      mnemonic <= "BLT";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      if compb_lt = '1' then
        pc_next <= pc+signex(i32_b_imm & '0');
      end if;

    -- BGE
    elsif i32_opcode = "1100011" and i32_funct3 = "101" then
      mnemonic <= "BGE";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      if compb_ge = '1' then
        pc_next <= pc+signex(i32_b_imm & '0');
      end if;

    -- BLTU
    elsif i32_opcode = "1100011" and i32_funct3 = "110" then
      mnemonic <= "BLTU";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      if compb_ltu = '1' then
        pc_next <= pc+signex(i32_b_imm & '0');
      end if;

    -- BGEU
    elsif i32_opcode = "1100011" and i32_funct3 = "111" then
      mnemonic <= "BGEU";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      if compb_geu = '1' then
        pc_next <= pc+signex(i32_b_imm & '0');
      end if;

    -- LB
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0000011" and i32_funct3 = "000" then
      mnemonic      <= "LB";
      rs1_sel       <= i32_rs1;
      rd_op_next    <= MEM;
      rd_sel_next   <= i32_rd;
      rd_width_next <= i32_funct3(2 downto 0);
      ls_re         <= '1';
      ls_sz         <= i32_funct3(1 downto 0);
      ls_addr       <= rs1_val+signex(i32_s_imm);

    -- LH
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0000011" and i32_funct3 = "001" then
      mnemonic      <= "LH";
      rs1_sel       <= i32_rs1;
      rd_op_next    <= MEM;
      rd_sel_next   <= i32_rd;
      rd_width_next <= i32_funct3(2 downto 0);
      ls_re         <= '1';
      ls_sz         <= i32_funct3(1 downto 0);
      ls_addr       <= rs1_val+signex(i32_s_imm);

    -- LW
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0000011" and i32_funct3 = "010" then
      mnemonic      <= "LW";
      rs1_sel       <= i32_rs1;
      rd_op_next    <= MEM;
      rd_sel_next   <= i32_rd;
      rd_width_next <= i32_funct3(2 downto 0);
      ls_re         <= '1';
      ls_sz         <= i32_funct3(1 downto 0);
      ls_addr       <= rs1_val+signex(i32_s_imm);

    -- LBU
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0000011" and i32_funct3 = "100" then
      mnemonic      <= "LBU";
      rs1_sel       <= i32_rs1;
      rd_op_next    <= MEM;
      rd_sel_next   <= i32_rd;
      rd_width_next <= i32_funct3(2 downto 0);
      ls_re         <= '1';
      ls_sz         <= i32_funct3(1 downto 0);
      ls_addr       <= rs1_val+signex(i32_s_imm);

    -- LHU
    elsif i32_opcode = "0000011" and i32_funct3 = "101" then
      mnemonic      <= "LHU";
      rs1_sel       <= i32_rs1;
      rd_op_next    <= MEM;
      rd_sel_next   <= i32_rd;
      rd_width_next <= i32_funct3(2 downto 0);
      ls_re         <= '1';
      ls_sz         <= i32_funct3(1 downto 0);
      ls_addr       <= rs1_val+signex(i32_s_imm);

    -- SB
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0100011" and i32_funct3 = "000" then
      mnemonic <= "SB";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      ls_we    <= '1';
      ls_sz    <= i32_funct3(1 downto 0);
      ls_addr  <= rs1_val+signex(i32_s_imm);
      ls_wdata <= rs2_val;

    -- SH
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0100011" and i32_funct3 = "001" then
      mnemonic <= "SH";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      ls_we    <= '1';
      ls_sz    <= i32_funct3(1 downto 0);
      ls_addr  <= rs1_val+signex(i32_s_imm);
      ls_wdata <= rs2_val;

    -- SW
    -- TODO: allow i32_funct3(2) to be ignored
    elsif i32_opcode = "0100011" and i32_funct3 = "010" then
      mnemonic <= "SW";
      rs1_sel  <= i32_rs1;
      rs2_sel  <= i32_rs2;
      ls_we    <= '1';
      ls_sz    <= i32_funct3(1 downto 0);
      ls_addr  <= rs1_val+signex(i32_s_imm);
      ls_wdata <= rs2_val;

    -- ADDI
    elsif i32_opcode = "0010011" and i32_funct3 = "000" then
      if i32_rd = "00000" and i32_rs1 = "00000" then
        mnemonic <= "NOP";
      else
        mnemonic <= "ADDI";
      end if;
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val+signex(i32_i_imm);

    -- SLTI
    elsif i32_opcode = "0010011" and i32_funct3 = "010" then
      mnemonic    <= "SLTI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= (0=>comps_ltiothers=>'0');

    -- SLTIU
    elsif i32_opcode = "0010011" and i32_funct3 = "011" then
      mnemonic    <= "SLTIU";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= (0=>comps_ltiuothers=>'0');

    -- XORI
    elsif i32_opcode = "0010011" and i32_funct3 = "100" then
      mnemonic    <= "XORI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val xor signex(i32_i_imm);

    -- ORI
    elsif i32_opcode = "0010011" and i32_funct3 = "110" then
      mnemonic    <= "ORI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val or signex(i32_i_imm);

    -- ANDI
    elsif i32_opcode = "0010011" and i32_funct3 = "111" then
      mnemonic    <= "ANDI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val and signex(i32_i_imm);

    -- SLLI
    elsif i32_opcode = "0010011" and i32_funct3 = "001" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "SLLI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= sl(rs1_vali32_shamt);

    -- SRLI
    elsif i32_opcode = "0010011" and i32_funct3 = "101" and ((opt_relax_decode and i32_funct7(5) = '0') or i32_funct7 = "0000000") then
      mnemonic    <= "SRLI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= sr_l(rs1_vali32_shamt);

    -- SRAI
    elsif i32_opcode = "0010011" and i32_funct3 = "101" and ((opt_relax_decode and i32_funct7(5) = '1') or i32_funct7 = "0100000") then
      mnemonic    <= "SRAI";
      rs1_sel     <= i32_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= sr_a(rs1_vali32_shamt);

    -- ADD
    elsif i32_opcode = "0110011" and i32_funct3 = "000" and ((opt_relax_decode and i32_funct7(5) = '0') or i32_funct7 = "0000000") then
      mnemonic    <= "ADD";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val+rs2_val;

    -- SUB
    elsif i32_opcode = "0110011" and i32_funct3 = "000" and ((opt_relax_decode and i32_funct7(5) = '1') or i32_funct7 = "0100000") then
      mnemonic    <= "SUB";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val-rs2_val;

    -- SLL
    elsif i32_opcode = "0110011" and i32_funct3 = "001" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "SLL";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= sl(rs1_valto_integer(rs2_val(4 downto 0)));

    -- SLT
    elsif i32_opcode = "0110011" and i32_funct3 = "010" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "SLT";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= (0 => comps_lt others => '0');

    -- SLTU
    elsif i32_opcode = "0110011" and i32_funct3 = "011" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "SLTU";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= (0 => comps_ltu others => '0');

    -- XOR
    elsif i32_opcode = "0110011" and i32_funct3 = "100" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "XOR";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val xor rs2_val;

    -- SRL
    elsif i32_opcode = "0110011" and i32_funct3 = "101" and ((opt_relax_decode and i32_funct7(5) = '0') or i32_funct7 = "0000000") then
      mnemonic    <= "SRL";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= sr_l(rs1_valrs2_val(4 downto 0));

    -- SRA
    elsif i32_opcode = "0110011" and i32_funct3 = "101" and ((opt_relax_decode and i32_funct7(5) = '1') or i32_funct7 = "0100000") then
      mnemonic    <= "SRA";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= sr_a(rs1_valrs2_val(4 downto 0));

    -- OR
    elsif i32_opcode = "0110011" and i32_funct3 = "110" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "OR";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val or rs2_val;

    -- AND
    elsif i32_opcode = "0110011" and i32_funct3 = "111" and (opt_relax_decode or i32_funct7 = "0000000") then
      mnemonic    <= "AND";
      rs1_sel     <= i32_rs1;
      rs2_sel     <= i32_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i32_rd;
      rd_val_next <= rs1_val and rs2_val;

    -- FENCE
    elsif i32_opcode = "0001111" and i32_funct3 = "000" and i32_funct12(11 downto 8) = "0000" then
      mnemonic <= "FENCE";
      null; -- we have a very simple memory interface

    -- ECALL
    elsif i32_opcode = "1110011" and i32_funct3 = "000" and ((opt_relax_decode and i32_funct12(0) = '0') or i32_funct12 = "000000000000") then
      mnemonic    <= "ECALL";
      v_exception := EXCEPTION_ECALL_M;

    -- EBREAK
    elsif i32_opcode = "1110011" and i32_funct3 = "000" and ((opt_relax_decode and i32_funct12(0) = '1') or i32_funct12 = "000000000001") then
      mnemonic    <= "EBREAK";
      v_exception := EXCEPTION_BREAK;

    -- MRET
    elsif i32_opcode = "1110011" and i32_funct7 = "0011000" and (opt_relax_decode or (i32_funct3=0 and i32_rs1=0 and i32_rs2=2 and i32_rd=0)) then
      mnemonic <= "MRET";
      pc_next  <= csr(csr_name_t'pos(csr_mepc));

    --------------------------------------------------------------------------------
    -- instruction set extension: Zicsr

    -- CSRRW
    -- sets rd to old CSR value sets new CSR value to rs1
    elsif i32_opcode = "1110011" and funct3 = "001" then
      mnemonic    <= "rs1";
      rs1_sel      <= i32_rs1;
      rd_op_next   <= CSR;
      rd_sel_next  <= i32_rd;
      csr_we       <= '1';
      csr_addr     <= i32_i_imm;
      csr_val_next <= rs1_val;

    -- CSRRS
    elsif i32_opcode = "1110011" and funct3 = "010" then
      mnemonic    <= "CSRRS";
      rs1_sel      <= i32_rs1;
      rd_op_next   <= CSR;
      rd_sel_next  <= i32_rd;
      csr_we       <= '1';
      csr_addr     <= i32_i_imm;
      csr_val_next <= csr_val or rs1_val;

    -- CSRRC
    elsif i32_opcode = "1110011" and funct3 = "011" then
      mnemonic    <= "CSRRC";
      rs1_sel      <= i32_rs1;
      rd_op_next   <= CSR;
      rd_sel_next  <= i32_rd;
      csr_we       <= '1';
      csr_addr     <= i32_i_imm;
      csr_val_next <= csr_val and not rs1_val;

    -- CSRRWI
    elsif i32_opcode = "1110011" and funct3 = "101" then
      mnemonic    <= "CSRRWI";
      rd_op_next   <= CSR;
      rd_sel_next  <= i32_rd;
      csr_we       <= '1';
      csr_addr     <= i32_i_imm;
      csr_val_next <= zeroex(rs1_sel);

    -- CSRRSI
    elsif i32_opcode = "1110011" and funct3 = "110" then
      mnemonic    <= "CSRRSI";
      rd_op_next   <= CSR;
      rd_sel_next  <= i32_rd;
      csr_we       <= '1';
      csr_addr     <= i32_i_imm;
      csr_val_next <= csr_val or zeroex(rs1_sel);

    -- CSRRCI
    elsif i32_opcode = "1110011" and funct3 = "111" then
      mnemonic    <= "CSRRCI";
      rd_op_next   <= CSR;
      rd_sel_next  <= i32_rd;
      csr_we       <= '1';
      csr_addr     <= i32_i_imm;
      csr_val_next <= csr_val and not zeroex(rs1_sel);

    --------------------------------------------------------------------------------
    -- instruction set extension: C (compressed instructions)

    -- C.ADDI4SPN
    elsif opt_C and i16_opcode = "00000" and (opt_relax_decode or i16_nzuimm /= "0000000000") then
      mnemonic     <= "C.ADDI4SPN";
      rd_op_next   <= INT;
      rd_sel_next  <= "01" & i16_rd_c;
      rd_val_next  <= reg(2)+zeroex(i16_nzuimm & "00");

    -- C.LW
    elsif opt_C and i16_opcode = "01000" then
      mnemonic     <= "C.LW";
      rs1_sel      <= "01" & i16_rs1_c;
      rd_op_next   <= MEM;
      rd_sel_next  <= "01" & i16_rd_c;
      ls_re        <= '1';
      ls_sz        <= "10";
      ls_addr      <= rs1_val+zeroex(i16_offset5);

    -- C.SW
    elsif opt_C and i16_opcode = "11000" then
      mnemonic <= "C.SW";
      rs1_sel  <= "01" & i16_rs1_c;
      rs2_sel  <= "01" & i16_rs2_c;
      ls_we    <= '1';
      ls_sz    <= "10";
      ls_addr  <= rs1_val+zeroex(i16_offset5);
      ls_wdata <= rs2_val;

    -- C.NOP C.ADDI (HINTs do nothing)
    elsif opt_C and i16_opcode = "00001" then
      if i16_rs1 = "00000" then
        mnemonic <= "C.NOP";
      else
        mnemonic <= "C.ADDI";
      end if;
      rs1_sel     <= i16_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd;
      rd_val_next <= rs1_val+signex(i16_imm6);

    -- C.JAL
    elsif opt_C and i16_opcode = "00101" then
      mnemonic    <= "C.JAL";
      rd_op_next  <= INT;
      rd_sel_next <= "00001";
      rd_val_next <= pc+2;
      pc_next <= pc+signex(i16_j_imm & '0');

    -- C.LI (HINTs do nothing)
    elsif opt_C and i16_opcode = "01001" then
      mnemonic    <= "C.LI";
      rd_op_next  <= INT;
      rd_sel_next <= i16_rd;
      rd_val_next <= signex(i16_imm6);

    -- C.ADDI16SP
    elsif opt_C and i16_opcode = "01101" and (opt_relax_decode or i16_imm6 /= "000000") then
      mnemonic    <= "C.ADDI16SP";
      rs1_sel     <= "00010";
      rd_op_next  <= INT;
      rd_sel_next <= "00010";
      rd_val_next <= rs1_val+signex(i16_imm6 & '0');

    -- C.LUI
    elsif opt_C and i16_opcode = "01101" then
      mnemonic    <= "C.LUI";
      rd_op_next  <= INT;
      rd_sel_next <= i16_rd;
      rd_val_next <= signex(i16_imm620) & x"000";

    -- C.SRLI (TODO: catch SRLI64?)
    elsif opt_C and i16_opcode = "10001" and i16_funct2b = "00" and (opt_relax_decode or i16(12) = '0') then
      mnemonic    <= "C.SRLI";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= sr_l(rs1_vali16_shamt);

    -- C.SRAI
    elsif opt_C and i16_opcode = "10001" and i16_funct2b = "01" and (opt_relax_decode or i16(12) = '0') then
      mnemonic    <= "C.SRAI";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= sr_a(rs1_vali16_shamt);

    -- C.ANDI
    elsif opt_C and i16_opcode = "10001" and i16_funct2b = "10" then
      mnemonic    <= "C.ANDI";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= rs1_val and signex(i16_imm6);

    -- C.SUB
    elsif opt_C and i16_opcode = "10001" and i16_funct1 = '0' and i16_funct2b = "11" and i16_funct2 = "00" then
      mnemonic    <= "C.SUB";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rs2_sel     <= "01" & i16_rd_rs2_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= rs1_val-rs2_val;

    -- C.XOR
    elsif opt_C and i16_opcode = "10001" and i16_funct1 = '0' and i16_funct2b = "11" and i16_funct2 = "01" then
      mnemonic    <= "C.XOR";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rs2_sel     <= "01" & i16_rs2_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= rs1_val xor rs2_val;

    -- C.OR
    elsif opt_C and i16_opcode = "10001" and i16_funct1 = '0' and i16_funct2b = "11" and i16_funct2 = "10" then
      mnemonic    <= "C.OR";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rs2_sel     <= "01" & i16_rs2_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= rs1_val or rs2_val;

    -- C.AND
    elsif opt_C and i16_opcode = "10001" and i16_funct1 = '0' and i16_funct2b = "11" and i16_funct2 = "11" then
      mnemonic    <= "C.AND";
      rs1_sel     <= "01" & i16_rd_rs1_c;
      rs2_sel     <= "01" & i16_rs2_c;
      rd_op_next  <= INT;
      rd_sel_next <= "01" & i16_rd_rs1_c;
      rd_val_next <= rs1_val and rs2_val;

    -- C.J
    elsif opt_C and i16_opcode = "10101" then
      mnemonic <= "C.J";
      pc_next  <= pc+signex(i16_j_imm & '0');

    -- C.BEQZ
    elsif opt_C and i16_opcode = "11001" then
      mnemonic <= "C.BEQZ";
      if compb_eq = '1' then
        pc_next <= pc+signex(i16_b_imm & '0');
      end if;

    -- C.BNEZ
    elsif opt_C and i16_opcode = "11101" then
      mnemonic <= "C.BNEZ";
      if compb_ne = '1' then
        pc_next <= pc+signex(i16_b_imm & '0');
      end if;

    -- C.SLLI (TODO: catch SLLI64?)
    elsif opt_C and i16_opcode = "00010" and (opt_relax_decode or i16(12) = '0') then
      mnemonic     <= "C.SLLI";
      rs1_sel     <= i16_rd_rs1;
      rd_op_next  <= INT;
      rd_sel_next <= i16_rd_rs1;
      rd_val_next <= sl(rs1_vali16_shamt);

    -- C.LWSP
    elsif opt_C and i16_opcode = "01010" then
      mnemonic    <= "C.LWSP";
      rs1_sel     <= "00010"; -- x2
      rd_op_next  <= MEM;
      rd_sel_next <= i16_rd;
      ls_re       <= '1';
      ls_we       <= '0';
      ls_sz       <= "10";
      ls_addr     <= rs1_val+zeroex(i16_loffset6 & "00");

    -- C.JR
    elsif opt_C and i16_opcode = "10010" and i16_funct1 = '0' and i16_rs1 /= "00000" and i16_rs2 = "00000" then
      mnemonic <= "C.JR";
      pc_next  <= rs1_val; -- pc_next(0) forced to zero below

    -- C.MV
    elsif opt_C and i16_opcode = "10010" and i16_funct1 = '0' and i16_rs2 /= "00000" then
      mnemonic    <= "C.MV";
      rs1_sel     <= i16_rd_rs1;
      rs2_sel     <= i16_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i16_rd_rs1;
      rd_val_next <= rs2_val;

    -- C.EBREAK
    elsif opt_C and i16_opcode = "10010" and i16_funct1 = '1' and i16_rd = "00000" and i16_rs2 = "00000" then
      mnemonic    <= "C.EBREAK";
      v_exception := EXCEPTION_BREAK;

    -- C.JALR
    elsif opt_C and i16_opcode = "10010" and i16_funct1 = '1' and i16_rd /= "00000" and i16_rs2 = "00000" then
      mnemonic    <= "C.JALR";
      pc_next     <= rs1_val; -- pc_next(0) forced to zero below
      rd_op_next  <= INT;
      rd_sel_next <= "00001";
      rd_val_next <= pc+2;

    -- C.ADD
    elsif opt_C and i16_opcode = "10010" and i16_funct1 = '1' and i16_rd_rs1 /= "00000" and i16_rs2 /= "00000" then
      mnemonic    <= "C.ADD";
      rs1_sel     <= i16_rd_rs1;
      rs2_sel     <= i16_rs2;
      rd_op_next  <= INT;
      rd_sel_next <= i16_rd_rs1;
      rd_val_next <= rs1_val+rs2_val;

    -- C.SWSP
    elsif opt_C and i16_opcode = "11010" then
      mnemonic <= "C.SWSP";
      rs1_sel  <= "00010"; -- x2
      rs2_sel  <= i16_rs2;
      ls_re    <= '1';
      ls_we    <= '1';
      ls_sz    <= "10";
      ls_addr  <= rs1_val+zeroex(i16_soffset6 & "00");
      ls_wdata <= rs2_val;

    --------------------------------------------------------------------------------
    -- illegal instruction

    else
      mnemonic     <= "ILLEGAL";
      v_exception := EXCEPTION_ILLEGAL_INSTR;

    end if;

    --------------------------------------------------------------------------------
    -- check for illegal CSR accesses

    -- TODO check for writes to read only CSRs

    -- check for accesses to non-existent CSRs (unless relaxed)
    if csr_we = '1' and not opt_relax_csr_nonex then
      v_csr_bad := true;
      for i in 0 to csr_num-1 loop
        if csr_addr = csr_def(i).address then
          v_csr_bad := false;
        end if;
      end loop;
    end if;
    if v_csr_bad then
      v_exception := EXCEPTION_ILLEGAL_INSTR;
    end if;

    --------------------------------------------------------------------------------
    -- take interrupt/exception

    if irq = '1' and interrupt enabled
    or v_exception /= EXCEPTION_NONE
    then
      pc_next  <= csr_mtvec(31 downto 2) & "00";
      csr_mepc <= pc(31 downto 1) & '0';

      exception <= true;
      exception_cause <= v_exception;
    end if;

    --------------------------------------------------------------------------------
    -- always

    if opt_C then
      pc_next(0) <= '0';
    else
      pc_next(1 downto 0) <= "00";
    end if;

  end process;

  --------------------------------------------------------------------------------
  -- comparators for conditional sets and branches

  comps_lt   <= bool2sl(   signed(rs1_val) <    signed(rs2_val)              );
  comps_ltu  <= bool2sl( unsigned(rs1_val) <  unsigned(rs2_val)              );
  comps_lti  <= bool2sl(   signed(rs1_val) <  resize(  signed(i32_i_imm),32) );
  comps_ltiu <= bool2sl( unsigned(rs1_val) <  resize(unsigned(i32_i_imm),32) );
  compb_eq   <= bool2sl(           rs1_val =  rs2_val                        );
  compb_ne   <= bool2sl(           rs1_val /= rs2_val                        );
  compb_lt   <= bool2sl(   signed(rs1_val) <    signed(rs2_val)              );
  compb_ge   <= bool2sl(   signed(rs1_val) >=   signed(rs2_val)              );
  compb_ltu  <= bool2sl( unsigned(rs1_val) <  unsigned(rs2_val)              );
  compb_geu  <= bool2sl( unsigned(rs1_val) >= unsigned(rs2_val)              );

  --------------------------------------------------------------------------------
  -- registers and trace

  rs1_val <= reg(to_integer(unsigned(rs1_sel(ternary(opt_E,3,4) downto 0))));
  rs2_val <= reg(to_integer(unsigned(rs2_sel(ternary(opt_E,3,4) downto 0))));

  reg(0) <= 0;
  gen_reg: for i in 1 to ternary(opt_E,15,31) generate
    reg(i) <=
      reg_prev(i) when advance = '0' or rd_op = NOP or i /= to_integer(unsigned(rd_sel)) else
      rd_val        when rd_op = INT else
      csr_rdata     when rd_op = CSR else
      signex(ls_rdata( 7 downto 0)) when rd_width = "000" else
      signex(ls_rdata(15 downto 0)) when rd_width = "001" else
             ls_rdata(31 downto 0)  when rd_width = "010" else
      zeroex(ls_rdata( 7 downto 0)) when rd_width = "100" else
      zeroex(ls_rdata(15 downto 0)) when rd_width = "101" else
      (others => dont_care);
  end generate gen_reg;

  process(rst,clk)
  begin
    if rst = '1' then

      pc <= reset_pc and iaddr_mask;
      reg_prev <= (others => '0');
      for i in 0 to csr_num-1 loop
        csr(i) <= csr_def(i).fixed_value;
      end loop;

      tag_pc  <= (others => '0');
      tag_reg <= (others => (others => '0'));
      tag_csr <= (others => (others => '0'));



      rd_op      <= NOP;
      csr_rdata <= (others => '0');

    elsif rising_edge(clk) then
      trace_stb <= '0';
      if advance = '1' then

        --------------------------------------------------------------------------------
        -- update tags
        -- advance tag for everything except...
        -- destination register (if there is one)
        -- PC (if its value depends on an outdated register)

        --------------------------------------------------------------------------------


        pc         <= pc_next and iaddr_mask;
        reg_prev <= reg;
        rd_op      <= rd_op_next;
        rd_sel     <= rd_sel_next;
        rd_val     <= rd_val_next;
        rd_width   <= rd_width_next;

        -- CSR instructions - reads and writes
        for i in 0 to csr_num-1 loop
          if csr_addr = csr_def(i).addr then
            csr_rdata <= csr(i);
            if csr_we = '1' then
              csr(i) <= (csr_wdata and csr_def(i).write_mask) or csr_def(i).fixed_value;
            end if;
          end if;
        end loop;
        -- other CSR writes
        -- "A trap into M-mode also writes fields GVA MPIE and MIE in mstatus/mstatush and writes CSRs mepc mcause mtval mtval2 and mtinst."
        if exception then
          csr(mepc)   <= pc;
          csr(mcause) <= exception_cause;
        end if;

      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------

  debug_stb   <= adv;
  debug_pc    <= pc;
  debug_reg <= reg;
  debug_csr   <= csr;


end architecture synth;