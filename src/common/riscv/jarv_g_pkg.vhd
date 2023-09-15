--------------------------------------------------------------------------------
-- jarv_g_pkg.vhd                                                             --
-- Just Another RISC-V: global types and constants.                           --
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
  use ieee.numeric_std.all;

package jarv_g_pkg is

  --------------------------------------------------------------------------------
  -- types


  -- destination register operations
  type rd_op_t is (
    NOP, -- no change
    INT, -- update from internally generated value e.g. another register or ALU
    EXT, -- update from external (memory)
    CSR  -- update from CSR
  );

  --------------------------------------------------------------------------------
  -- functions

  function ternary ( cond : boolean; ret_true : integer;  ret_false : integer  ) return integer;
  function ternary ( cond : boolean; ret_true : unsigned; ret_false : unsigned ) return unsigned;

  function bool2sl ( cond : boolean ) return std_logic;

  function "+"  ( a : reg_t; b : reg_t   ) return reg_t;
  function "+"  ( a : reg_t; b : integer ) return reg_t;
  function sl   ( a : reg_t; b : reg_t   ) return reg_t;
  function sr_l ( a : reg_t; b : reg_t   ) return reg_t;
  function sr_a ( a : reg_t; b : reg_t   ) return reg_t;
  function zx   ( v : reg_t              ) return reg_t;
  function sx   ( v : reg_t              ) return reg_t;

  --------------------------------------------------------------------------------
  -- opcodes

  -- base
  type rv_opcode_t is (
  --  | 000    | 001      | 010      | 011      | 100    | 101    | 110       | 111    | <-- inst[4:2]
        LOAD,    LOAD_FP,   CUSTOM_0,  MISC_MEM,  OP_IMM,  AUIPC,   OP_IMM_32, LEN_48A,  -- 00 } inst[6:5]
        STORE,   STORE_FP,  CUSTOM_1,  AMO,       OP,      LUI,     OP_32,     LEN_64,   -- 01 }
        MADD,    MSUB,      NMSUB,     NMADD,     OP_FP,   RSVD_0,  CUSTOM_2,  LEN_48B,  -- 10 }
        BRANCH,  JALR,      RSVD_1,    JAL,       SYSTEM,  RSVD_2,  CUSTOM_3,  LEN_80    -- 11 }
  );

  -- compressed
  type rvc_opcode_t is (
  --  | 000      | 001   | 010  | 011          | 100         | 101   | 110  | 111  | <-- inst[15:13]
        ADDI4SPN,  FLD,    LW,    FLW,           RSVD,         FSD,    SW,    FSW,   -- 00 } inst[1:0]
        ADDI,      JAL,    LI,    LUI_ADDI16SP,  MISC_ALU,     J,      BEQZ,  BNEZ,  -- 01 }
        SLLI,      FLDSP,  LWSP,  FLWSP,         JALR_MV_ADD,  FSDSP,  SWSP,  FSWSP  -- 10 }
  );

  --------------------------------------------------------------------------------
  -- exception and interrupt cause codes

  constant EXCEPTION_ALIGN_INSTR   : std_logic_vector(31 downto 0) := x"00000000"; -- Instruction address misaligned
  constant EXCEPTION_ACCESS_INSTR  : std_logic_vector(31 downto 0) := x"00000001"; -- Instruction access fault
  constant EXCEPTION_ILLEGAL_INSTR : std_logic_vector(31 downto 0) := x"00000002"; -- Illegal instruction
  constant EXCEPTION_BREAK         : std_logic_vector(31 downto 0) := x"00000003"; -- Breakpoint
  constant EXCEPTION_ALIGN_LOAD    : std_logic_vector(31 downto 0) := x"00000004"; -- Load address misaligned
  constant EXCEPTION_ACCESS_LOAD   : std_logic_vector(31 downto 0) := x"00000005"; -- Load access fault
  constant EXCEPTION_ALIGN_STORE   : std_logic_vector(31 downto 0) := x"00000006"; -- Store/AMO address misaligned
  constant EXCEPTION_ACCESS_STORE  : std_logic_vector(31 downto 0) := x"00000007"; -- Store/AMO access fault
  constant EXCEPTION_ECALL_U       : std_logic_vector(31 downto 0) := x"00000008"; -- Environment call from U-mode
  constant EXCEPTION_ECALL_S       : std_logic_vector(31 downto 0) := x"00000009"; -- Environment call from S-mode
  constant EXCEPTION_ECALL_H       : std_logic_vector(31 downto 0) := x"0000000A"; -- Environment call from H-mode (deprecated)
  constant EXCEPTION_ECALL_M       : std_logic_vector(31 downto 0) := x"0000000B"; -- Environment call from M-mode
  constant EXCEPTION_PAGE_INSTR    : std_logic_vector(31 downto 0) := x"0000000C"; -- Instruction page fault
  constant EXCEPTION_PAGE_LOAD     : std_logic_vector(31 downto 0) := x"0000000D"; -- Load page fault
  constant EXCEPTION_RSVD_14       : std_logic_vector(31 downto 0) := x"0000000E"; -- reserved
  constant EXCEPTION_PAGE_STORE    : std_logic_vector(31 downto 0) := x"0000000F"; -- Store/AMO page fault
  constant INTERRUPT_S_U           : std_logic_vector(31 downto 0) := x"80000000"; -- user software interrupt (deprecated)
  constant INTERRUPT_S_S           : std_logic_vector(31 downto 0) := x"80000001"; -- supervisor software interrupt
  constant INTERRUPT_S_H           : std_logic_vector(31 downto 0) := x"80000002"; -- hypervisor software interrupt (deprecated)
  constant INTERRUPT_S_M           : std_logic_vector(31 downto 0) := x"80000003"; -- machine software interrupt
  constant INTERRUPT_T_U           : std_logic_vector(31 downto 0) := x"80000004"; -- user timer interrupt (deprecated)
  constant INTERRUPT_T_S           : std_logic_vector(31 downto 0) := x"80000005"; -- supervisor timer interrupt
  constant INTERRUPT_T_H           : std_logic_vector(31 downto 0) := x"80000006"; -- hypervisor timer interrupt (deprecated)
  constant INTERRUPT_T_M           : std_logic_vector(31 downto 0) := x"80000007"; -- machine timer interrupt
  constant INTERRUPT_E_U           : std_logic_vector(31 downto 0) := x"80000008"; -- user external interrupt (deprecated)
  constant INTERRUPT_E_S           : std_logic_vector(31 downto 0) := x"80000009"; -- supervisor external interrupt
  constant INTERRUPT_E_H           : std_logic_vector(31 downto 0) := x"8000000A"; -- hypervisor external interrupt (deprecated)
  constant INTERRUPT_E_M           : std_logic_vector(31 downto 0) := x"8000000B"; -- machine external interrupt
  constant INTERRUPT_RSVD_12       : std_logic_vector(31 downto 0) := x"8000000C"; -- reserved
  constant INTERRUPT_RSVD_13       : std_logic_vector(31 downto 0) := x"8000000D"; -- reserved
  constant INTERRUPT_RSVD_14       : std_logic_vector(31 downto 0) := x"8000000E"; -- reserved
  constant INTERRUPT_RSVD_15       : std_logic_vector(31 downto 0) := x"8000000F"; -- reserved

  --------------------------------------------------------------------------------
  -- CSR addresses

  constant CSRA_MISA           : csra_t := x"301";
  constant CSRA_MVENDORID      : csra_t := x"F11";
  constant CSRA_MARCHID        : csra_t := x"F12";
  constant CSRA_MIMPID         : csra_t := x"F13";
  constant CSRA_MHARTID        : csra_t := x"F13";
  constant CSRA_MSTATUS        : csra_t := x"300";
  constant CSRA_MSTATUSH       : csra_t := x"310";
  constant CSRA_MTVEC          : csra_t := x"305";
  constant CSRA_MEDELEG        : csra_t := x"302";
  constant CSRA_MIDELEG        : csra_t := x"303";
  constant CSRA_MIP            : csra_t := x"344";
  constant CSRA_MIE            : csra_t := x"304";
  constant CSRA_MCYCLE         : csra_t := x"B00";
  constant CSRA_MINSTRET       : csra_t := x"B02";
  constant CSRA_MHPMCOUNTER3   : csra_t := x"B03";
  constant CSRA_MHPMCOUNTER4   : csra_t := x"B04";
  constant CSRA_MHPMCOUNTER5   : csra_t := x"B05";
  constant CSRA_MHPMCOUNTER6   : csra_t := x"B06";
  constant CSRA_MHPMCOUNTER7   : csra_t := x"B07";
  constant CSRA_MHPMCOUNTER8   : csra_t := x"B08";
  constant CSRA_MHPMCOUNTER9   : csra_t := x"B09";
  constant CSRA_MHPMCOUNTER10  : csra_t := x"B0A";
  constant CSRA_MHPMCOUNTER11  : csra_t := x"B0B";
  constant CSRA_MHPMCOUNTER12  : csra_t := x"B0C";
  constant CSRA_MHPMCOUNTER13  : csra_t := x"B0D";
  constant CSRA_MHPMCOUNTER14  : csra_t := x"B0E";
  constant CSRA_MHPMCOUNTER15  : csra_t := x"B0F";
  constant CSRA_MHPMCOUNTER16  : csra_t := x"B10";
  constant CSRA_MHPMCOUNTER17  : csra_t := x"B11";
  constant CSRA_MHPMCOUNTER18  : csra_t := x"B12";
  constant CSRA_MHPMCOUNTER19  : csra_t := x"B13";
  constant CSRA_MHPMCOUNTER20  : csra_t := x"B14";
  constant CSRA_MHPMCOUNTER21  : csra_t := x"B15";
  constant CSRA_MHPMCOUNTER22  : csra_t := x"B16";
  constant CSRA_MHPMCOUNTER23  : csra_t := x"B17";
  constant CSRA_MHPMCOUNTER24  : csra_t := x"B18";
  constant CSRA_MHPMCOUNTER25  : csra_t := x"B19";
  constant CSRA_MHPMCOUNTER26  : csra_t := x"B1A";
  constant CSRA_MHPMCOUNTER27  : csra_t := x"B1B";
  constant CSRA_MHPMCOUNTER28  : csra_t := x"B1C";
  constant CSRA_MHPMCOUNTER29  : csra_t := x"B1D";
  constant CSRA_MHPMCOUNTER30  : csra_t := x"B1E";
  constant CSRA_MHPMCOUNTER31  : csra_t := x"B1F";
  constant CSRA_MHPMEVENT3     : csra_t := x"323";
  constant CSRA_MHPMEVENT4     : csra_t := x"324";
  constant CSRA_MHPMEVENT5     : csra_t := x"325";
  constant CSRA_MHPMEVENT6     : csra_t := x"326";
  constant CSRA_MHPMEVENT7     : csra_t := x"327";
  constant CSRA_MHPMEVENT8     : csra_t := x"328";
  constant CSRA_MHPMEVENT9     : csra_t := x"329";
  constant CSRA_MHPMEVENT10    : csra_t := x"32A";
  constant CSRA_MHPMEVENT11    : csra_t := x"32B";
  constant CSRA_MHPMEVENT12    : csra_t := x"32C";
  constant CSRA_MHPMEVENT13    : csra_t := x"32D";
  constant CSRA_MHPMEVENT14    : csra_t := x"32E";
  constant CSRA_MHPMEVENT15    : csra_t := x"32F";
  constant CSRA_MHPMEVENT16    : csra_t := x"330";
  constant CSRA_MHPMEVENT17    : csra_t := x"331";
  constant CSRA_MHPMEVENT18    : csra_t := x"332";
  constant CSRA_MHPMEVENT19    : csra_t := x"333";
  constant CSRA_MHPMEVENT20    : csra_t := x"334";
  constant CSRA_MHPMEVENT21    : csra_t := x"335";
  constant CSRA_MHPMEVENT22    : csra_t := x"336";
  constant CSRA_MHPMEVENT23    : csra_t := x"337";
  constant CSRA_MHPMEVENT24    : csra_t := x"338";
  constant CSRA_MHPMEVENT25    : csra_t := x"339";
  constant CSRA_MHPMEVENT26    : csra_t := x"33A";
  constant CSRA_MHPMEVENT27    : csra_t := x"33B";
  constant CSRA_MHPMEVENT28    : csra_t := x"33C";
  constant CSRA_MHPMEVENT29    : csra_t := x"33D";
  constant CSRA_MHPMEVENT30    : csra_t := x"33E";
  constant CSRA_MHPMEVENT31    : csra_t := x"33F";
  constant CSRA_MCYCLEH        : csra_t := x"B80";
  constant CSRA_MINSTRETH      : csra_t := x"B82";
  constant CSRA_MHPMCOUNTER3H  : csra_t := x"B83";
  constant CSRA_MHPMCOUNTER4H  : csra_t := x"B84";
  constant CSRA_MHPMCOUNTER5H  : csra_t := x"B85";
  constant CSRA_MHPMCOUNTER6H  : csra_t := x"B86";
  constant CSRA_MHPMCOUNTER7H  : csra_t := x"B87";
  constant CSRA_MHPMCOUNTER8H  : csra_t := x"B88";
  constant CSRA_MHPMCOUNTER9H  : csra_t := x"B89";
  constant CSRA_MHPMCOUNTER10H : csra_t := x"B8A";
  constant CSRA_MHPMCOUNTER11H : csra_t := x"B8B";
  constant CSRA_MHPMCOUNTER12H : csra_t := x"B8C";
  constant CSRA_MHPMCOUNTER13H : csra_t := x"B8D";
  constant CSRA_MHPMCOUNTER14H : csra_t := x"B8E";
  constant CSRA_MHPMCOUNTER15H : csra_t := x"B8F";
  constant CSRA_MHPMCOUNTER16H : csra_t := x"B90";
  constant CSRA_MHPMCOUNTER17H : csra_t := x"B91";
  constant CSRA_MHPMCOUNTER18H : csra_t := x"B92";
  constant CSRA_MHPMCOUNTER19H : csra_t := x"B93";
  constant CSRA_MHPMCOUNTER20H : csra_t := x"B94";
  constant CSRA_MHPMCOUNTER21H : csra_t := x"B95";
  constant CSRA_MHPMCOUNTER22H : csra_t := x"B96";
  constant CSRA_MHPMCOUNTER23H : csra_t := x"B97";
  constant CSRA_MHPMCOUNTER24H : csra_t := x"B98";
  constant CSRA_MHPMCOUNTER25H : csra_t := x"B99";
  constant CSRA_MHPMCOUNTER26H : csra_t := x"B9A";
  constant CSRA_MHPMCOUNTER27H : csra_t := x"B9B";
  constant CSRA_MHPMCOUNTER28H : csra_t := x"B9C";
  constant CSRA_MHPMCOUNTER29H : csra_t := x"B9D";
  constant CSRA_MHPMCOUNTER30H : csra_t := x"B9E";
  constant CSRA_MHPMCOUNTER31H : csra_t := x"B9F";
  constant CSRA_MCOUNTEREN     : csra_t := x"306";
  constant CSRA_MCOUNTINHIBIT  : csra_t := x"320";
  constant CSRA_MSCRATCH       : csra_t := x"340";
  constant CSRA_MEPC           : csra_t := x"341";
  constant CSRA_MCAUSE         : csra_t := x"342";
  constant CSRA_MTVAL          : csra_t := x"343";
  constant CSRA_MCONFIGPTR     : csra_t := x"F15";
  constant CSRA_MENVCFG        : csra_t := x"30A";
  constant CSRA_MENVCFGH       : csra_t := x"31A";
  constant CSRA_MSECCFG        : csra_t := x"747";
  constant CSRA_MSECCFGH       : csra_t := x"757";

  --------------------------------------------------------------------------------

end package jarv_g_pkg;

package body jarv_g_pkg is

  --------------------------------------------------------------------------------
  -- functions: ternaries and related

  function ternary (
    cond      : boolean;
    ret_true  : integer;
    ret_false : integer
  ) return integer is
  begin
    if cond then return ret_true; else return ret_false; end if;
  end function ternary;

  function ternary (
    cond      : boolean;
    ret_true  : unsigned;
    ret_false : unsigned
  ) return unsigned is
  begin
    if cond then return ret_true; else return ret_false; end if;
  end function ternary;

  function bool2sl ( cond : boolean ) return std_logic is
  begin
    if cond then return '1'; else return '0'; end if;
  end function bool2sl;

  --------------------------------------------------------------------------------
  -- functions: reg_t support

  -- add reg_t to reg_t
  function "+" (
    a : reg_t;
    b : reg_t
  ) return reg_t is
  begin
    return reg_t(unsigned(a)+unsigned(b));
  end function "+";

  -- add reg_t to integer
  function "+" (
    a : reg_t;
    b : integer
  ) return reg_t is
  begin
    return reg_t(unsigned(a)+b);
  end function "+";

  -- shift left
  function sl (
    a : reg_t;
    b : reg_t
  ) return reg_t is
  begin
    return reg_t(shift_left(unsigned(a)to_integer(unsigned(b))));
  end function sl;

  -- shift right logical
  function sr_l (
    a : reg_t;
    b : reg_t
  ) return reg_t is
  begin
    return reg_t(shift_right(unsigned(a)to_integer(unsigned(b))));
  end function sr_l;

  -- shift right arithmetic
  function sr_a (
    a : reg_t;
    b : reg_t
  ) return reg_t is
  begin
    return reg_t(shift_right(signed(a)to_integer(unsigned(b))));
  end function sr_a;

  -- zero extend
  function zx (v : reg_t) return reg_t is
  begin
    return reg_t(resize(unsigned(v),32));
  end function zx;

  -- sign extend
  function sx (v : reg_t) return reg_t is
  begin
    return reg_t(resize(signed(v),32));
  end function sx;

  --------------------------------------------------------------------------------

end package body jarv_g_pkg;
