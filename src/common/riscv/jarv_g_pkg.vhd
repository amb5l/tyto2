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

package jarv_g_pkg is

  -- base opcodes
  type rv_opcode_t is (
  --  | 000      | 001      | 010      | 011      | 100      | 101      | 110      | 111      |   <-- inst[4:2]
        LOAD,      LOAD_FP,   CUSTOM_0,  MISC_MEM,  OP_IMM,    AUIPC,     OP_IMM_32, LEN_48A, -- 00 } inst[6:5]
        STORE,     STORE_FP,  CUSTOM_1,  AMO,       OP,        LUI,       OP_32,     LEN_64,  -- 01 }
        MADD,      MSUB,      NMSUB,     NMADD,     OP_FP,     RSVD_0,    CUSTOM_2,  LEN_48B, -- 10 }
        BRANCH,    JALR,      RSVD_1,    JAL,       SYSTEM,    RSVD_2,    CUSTOM_3,  LEN_80   -- 11 }
  );

  -- compressed opcodes
  type rvc_opcode_t is (
  --  | 000         | 001         | 010         | 011         | 100         | 101         | 110         | 111         |   <-- inst[15:13]
        ADDI4SPN,     FLD,          LW,           FLW,          RSVD,         FSD,          SW,           FSW,        -- 00 } inst[1:0]
        ADDI,         JAL,          LI,           LUI_ADDI16SP, MISC_ALU,     J,            BEQZ,         BNEZ,       -- 01 }
        SLLI,         FLDSP,        LWSP,         FLWSP,        JALR_MV_ADD,  FSDSP,        SWSP,         FSWSP       -- 10 }
  );

  -- exceptions
  type exception_t is (
    EXCEPTION_ALIGN_INSTR,   --  0: Instruction address misaligned
    EXCEPTION_ACCESS_INSTR,  --  1: Instruction access fault
    EXCEPTION_ILLEGAL_INSTR, --  2: Illegal instruction
    EXCEPTION_BREAK,         --  3: Breakpoint
    EXCEPTION_ALIGN_LOAD,    --  4: Load address misaligned
    EXCEPTION_ACCESS_LOAD,   --  5: Load access fault
    EXCEPTION_ALIGN_STORE,   --  6: Store/AMO address misaligned
    EXCEPTION_ACCESS_STORE,  --  7: Store/AMO access fault
    EXCEPTION_ECALL_U,       --  8: Environment call from U-mode
    EXCEPTION_ECALL_S,       --  9: Environment call from S-mode
    EXCEPTION_ECALL_H,       -- 10: Environment call from H-mode (deprecated)
    EXCEPTION_ECALL_M,       -- 11: Environment call from M-mode
    EXCEPTION_PAGE_INSTR,    -- 12: Instruction page fault
    EXCEPTION_PAGE_LOAD,     -- 13: Load page fault
    EXCEPTION_RSVD_14,       -- 14: reserved
    EXCEPTION_PAGE_STORE     -- 15: Store/AMO page fault
  );

  -- interrupts
  type interrupt_t is (
    INTERRUPT_S_U,     --  0: user software interrupt (deprecated)
    INTERRUPT_S_S,     --  1: supervisor software interrupt
    INTERRUPT_S_H,     --  2: hypervisor software interrupt (deprecated)
    INTERRUPT_S_M,     --  3: machine software interrupt
    INTERRUPT_T_U,     --  4: user timer interrupt (deprecated)
    INTERRUPT_T_S,     --  5: supervisor timer interrupt
    INTERRUPT_T_H,     --  6: hypervisor timer interrupt (deprecated)
    INTERRUPT_T_M,     --  7: machine timer interrupt
    INTERRUPT_E_U,     --  8: user external interrupt (deprecated)
    INTERRUPT_E_S,     --  9: supervisor external interrupt
    INTERRUPT_E_H,     -- 10: hypervisor external interrupt (deprecated)
    INTERRUPT_E_M      -- 11: machine external interrupt
    INTERRUPT_RSVD_12, -- 12: reserved
    INTERRUPT_RSVD_13, -- 13: reserved
    INTERRUPT_RSVD_14, -- 14: reserved
    INTERRUPT_RSVD_15, -- 15: reserved
  );

  -- CSR addresses
  constant CSRA_MISA           : std_logic_vector(11 downto 0) := x"301";
  constant CSRA_MVENDORID      : std_logic_vector(11 downto 0) := x"F11";
  constant CSRA_MARCHID        : std_logic_vector(11 downto 0) := x"F12";
  constant CSRA_MIMPID         : std_logic_vector(11 downto 0) := x"F13";
  constant CSRA_MHARTID        : std_logic_vector(11 downto 0) := x"F13";
  constant CSRA_MSTATUS        : std_logic_vector(11 downto 0) := x"300";
  constant CSRA_MSTATUSH       : std_logic_vector(11 downto 0) := x"310";
  constant CSRA_MTVEC          : std_logic_vector(11 downto 0) := x"305";
  constant CSRA_MEDELEG        : std_logic_vector(11 downto 0) := x"302";
  constant CSRA_MIDELEG        : std_logic_vector(11 downto 0) := x"303";
  constant CSRA_MIP            : std_logic_vector(11 downto 0) := x"344";
  constant CSRA_MIE            : std_logic_vector(11 downto 0) := x"304";
  constant CSRA_MCYCLE         : std_logic_vector(11 downto 0) := x"B00";
  constant CSRA_MINSTRET       : std_logic_vector(11 downto 0) := x"B02";
  constant CSRA_MHPMCOUNTER3   : std_logic_vector(11 downto 0) := x"B03";
  constant CSRA_MHPMCOUNTER4   : std_logic_vector(11 downto 0) := x"B04";
  constant CSRA_MHPMCOUNTER5   : std_logic_vector(11 downto 0) := x"B05";
  constant CSRA_MHPMCOUNTER6   : std_logic_vector(11 downto 0) := x"B06";
  constant CSRA_MHPMCOUNTER7   : std_logic_vector(11 downto 0) := x"B07";
  constant CSRA_MHPMCOUNTER8   : std_logic_vector(11 downto 0) := x"B08";
  constant CSRA_MHPMCOUNTER9   : std_logic_vector(11 downto 0) := x"B09";
  constant CSRA_MHPMCOUNTER10  : std_logic_vector(11 downto 0) := x"B0A";
  constant CSRA_MHPMCOUNTER11  : std_logic_vector(11 downto 0) := x"B0B";
  constant CSRA_MHPMCOUNTER12  : std_logic_vector(11 downto 0) := x"B0C";
  constant CSRA_MHPMCOUNTER13  : std_logic_vector(11 downto 0) := x"B0D";
  constant CSRA_MHPMCOUNTER14  : std_logic_vector(11 downto 0) := x"B0E";
  constant CSRA_MHPMCOUNTER15  : std_logic_vector(11 downto 0) := x"B0F";
  constant CSRA_MHPMCOUNTER16  : std_logic_vector(11 downto 0) := x"B10";
  constant CSRA_MHPMCOUNTER17  : std_logic_vector(11 downto 0) := x"B11";
  constant CSRA_MHPMCOUNTER18  : std_logic_vector(11 downto 0) := x"B12";
  constant CSRA_MHPMCOUNTER19  : std_logic_vector(11 downto 0) := x"B13";
  constant CSRA_MHPMCOUNTER20  : std_logic_vector(11 downto 0) := x"B14";
  constant CSRA_MHPMCOUNTER21  : std_logic_vector(11 downto 0) := x"B15";
  constant CSRA_MHPMCOUNTER22  : std_logic_vector(11 downto 0) := x"B16";
  constant CSRA_MHPMCOUNTER23  : std_logic_vector(11 downto 0) := x"B17";
  constant CSRA_MHPMCOUNTER24  : std_logic_vector(11 downto 0) := x"B18";
  constant CSRA_MHPMCOUNTER25  : std_logic_vector(11 downto 0) := x"B19";
  constant CSRA_MHPMCOUNTER26  : std_logic_vector(11 downto 0) := x"B1A";
  constant CSRA_MHPMCOUNTER27  : std_logic_vector(11 downto 0) := x"B1B";
  constant CSRA_MHPMCOUNTER28  : std_logic_vector(11 downto 0) := x"B1C";
  constant CSRA_MHPMCOUNTER29  : std_logic_vector(11 downto 0) := x"B1D";
  constant CSRA_MHPMCOUNTER30  : std_logic_vector(11 downto 0) := x"B1E";
  constant CSRA_MHPMCOUNTER31  : std_logic_vector(11 downto 0) := x"B1F";
  constant CSRA_MHPMEVENT3     : std_logic_vector(11 downto 0) := x"323";
  constant CSRA_MHPMEVENT4     : std_logic_vector(11 downto 0) := x"324";
  constant CSRA_MHPMEVENT5     : std_logic_vector(11 downto 0) := x"325";
  constant CSRA_MHPMEVENT6     : std_logic_vector(11 downto 0) := x"326";
  constant CSRA_MHPMEVENT7     : std_logic_vector(11 downto 0) := x"327";
  constant CSRA_MHPMEVENT8     : std_logic_vector(11 downto 0) := x"328";
  constant CSRA_MHPMEVENT9     : std_logic_vector(11 downto 0) := x"329";
  constant CSRA_MHPMEVENT10    : std_logic_vector(11 downto 0) := x"32A";
  constant CSRA_MHPMEVENT11    : std_logic_vector(11 downto 0) := x"32B";
  constant CSRA_MHPMEVENT12    : std_logic_vector(11 downto 0) := x"32C";
  constant CSRA_MHPMEVENT13    : std_logic_vector(11 downto 0) := x"32D";
  constant CSRA_MHPMEVENT14    : std_logic_vector(11 downto 0) := x"32E";
  constant CSRA_MHPMEVENT15    : std_logic_vector(11 downto 0) := x"32F";
  constant CSRA_MHPMEVENT16    : std_logic_vector(11 downto 0) := x"330";
  constant CSRA_MHPMEVENT17    : std_logic_vector(11 downto 0) := x"331";
  constant CSRA_MHPMEVENT18    : std_logic_vector(11 downto 0) := x"332";
  constant CSRA_MHPMEVENT19    : std_logic_vector(11 downto 0) := x"333";
  constant CSRA_MHPMEVENT20    : std_logic_vector(11 downto 0) := x"334";
  constant CSRA_MHPMEVENT21    : std_logic_vector(11 downto 0) := x"335";
  constant CSRA_MHPMEVENT22    : std_logic_vector(11 downto 0) := x"336";
  constant CSRA_MHPMEVENT23    : std_logic_vector(11 downto 0) := x"337";
  constant CSRA_MHPMEVENT24    : std_logic_vector(11 downto 0) := x"338";
  constant CSRA_MHPMEVENT25    : std_logic_vector(11 downto 0) := x"339";
  constant CSRA_MHPMEVENT26    : std_logic_vector(11 downto 0) := x"33A";
  constant CSRA_MHPMEVENT27    : std_logic_vector(11 downto 0) := x"33B";
  constant CSRA_MHPMEVENT28    : std_logic_vector(11 downto 0) := x"33C";
  constant CSRA_MHPMEVENT29    : std_logic_vector(11 downto 0) := x"33D";
  constant CSRA_MHPMEVENT30    : std_logic_vector(11 downto 0) := x"33E";
  constant CSRA_MHPMEVENT31    : std_logic_vector(11 downto 0) := x"33F";
  constant CSRA_MCYCLEH        : std_logic_vector(11 downto 0) := x"B80";
  constant CSRA_MINSTRETH      : std_logic_vector(11 downto 0) := x"B82";
  constant CSRA_MHPMCOUNTER3H  : std_logic_vector(11 downto 0) := x"B83";
  constant CSRA_MHPMCOUNTER4H  : std_logic_vector(11 downto 0) := x"B84";
  constant CSRA_MHPMCOUNTER5H  : std_logic_vector(11 downto 0) := x"B85";
  constant CSRA_MHPMCOUNTER6H  : std_logic_vector(11 downto 0) := x"B86";
  constant CSRA_MHPMCOUNTER7H  : std_logic_vector(11 downto 0) := x"B87";
  constant CSRA_MHPMCOUNTER8H  : std_logic_vector(11 downto 0) := x"B88";
  constant CSRA_MHPMCOUNTER9H  : std_logic_vector(11 downto 0) := x"B89";
  constant CSRA_MHPMCOUNTER10H : std_logic_vector(11 downto 0) := x"B8A";
  constant CSRA_MHPMCOUNTER11H : std_logic_vector(11 downto 0) := x"B8B";
  constant CSRA_MHPMCOUNTER12H : std_logic_vector(11 downto 0) := x"B8C";
  constant CSRA_MHPMCOUNTER13H : std_logic_vector(11 downto 0) := x"B8D";
  constant CSRA_MHPMCOUNTER14H : std_logic_vector(11 downto 0) := x"B8E";
  constant CSRA_MHPMCOUNTER15H : std_logic_vector(11 downto 0) := x"B8F";
  constant CSRA_MHPMCOUNTER16H : std_logic_vector(11 downto 0) := x"B90";
  constant CSRA_MHPMCOUNTER17H : std_logic_vector(11 downto 0) := x"B91";
  constant CSRA_MHPMCOUNTER18H : std_logic_vector(11 downto 0) := x"B92";
  constant CSRA_MHPMCOUNTER19H : std_logic_vector(11 downto 0) := x"B93";
  constant CSRA_MHPMCOUNTER20H : std_logic_vector(11 downto 0) := x"B94";
  constant CSRA_MHPMCOUNTER21H : std_logic_vector(11 downto 0) := x"B95";
  constant CSRA_MHPMCOUNTER22H : std_logic_vector(11 downto 0) := x"B96";
  constant CSRA_MHPMCOUNTER23H : std_logic_vector(11 downto 0) := x"B97";
  constant CSRA_MHPMCOUNTER24H : std_logic_vector(11 downto 0) := x"B98";
  constant CSRA_MHPMCOUNTER25H : std_logic_vector(11 downto 0) := x"B99";
  constant CSRA_MHPMCOUNTER26H : std_logic_vector(11 downto 0) := x"B9A";
  constant CSRA_MHPMCOUNTER27H : std_logic_vector(11 downto 0) := x"B9B";
  constant CSRA_MHPMCOUNTER28H : std_logic_vector(11 downto 0) := x"B9C";
  constant CSRA_MHPMCOUNTER29H : std_logic_vector(11 downto 0) := x"B9D";
  constant CSRA_MHPMCOUNTER30H : std_logic_vector(11 downto 0) := x"B9E";
  constant CSRA_MHPMCOUNTER31H : std_logic_vector(11 downto 0) := x"B9F";
  constant CSRA_MCOUNTEREN     : std_logic_vector(11 downto 0) := x"306";
  constant CSRA_MCOUNTINHIBIT  : std_logic_vector(11 downto 0) := x"320";
  constant CSRA_MSCRATCH       : std_logic_vector(11 downto 0) := x"340";
  constant CSRA_MEPC           : std_logic_vector(11 downto 0) := x"341";
  constant CSRA_MCAUSE         : std_logic_vector(11 downto 0) := x"342";
  constant CSRA_MTVAL          : std_logic_vector(11 downto 0) := x"343";
  constant CSRA_MCONFIGPTR     : std_logic_vector(11 downto 0) := x"F15";
  constant CSRA_MENVCFG        : std_logic_vector(11 downto 0) := x"30A";
  constant CSRA_MENVCFGH       : std_logic_vector(11 downto 0) := x"31A";
  constant CSRA_MSECCFG        : std_logic_vector(11 downto 0) := x"747";
  constant CSRA_MSECCFGH       : std_logic_vector(11 downto 0) := x"757";

end package jarv_g_pkg;
