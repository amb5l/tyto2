--------------------------------------------------------------------------------
-- TbR6522.vhd                                                                --
-- Simulation testbench for r6522.vhd.                                        --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee ;
  use ieee.std_logic_1164.all ;

library osvvm;
  context osvvm.OsvvmContext ;

library OSVVM_Common ;
  context OSVVM_Common.OsvvmCommonContext ;

library work;
  use work.r6522_pkg.all ;
  use work.RegMasterPkg.all ;
  use work.TestCtrlPkg.all ;

entity TbR6522 is
  generic (
      TbName              : string := "TbR6522" ;
      ValidatedResultsDir : string
  );
end entity TbR6522 ;

architecture TestHarness of TbR6522 is

  -- constants
  
  constant T_RegClk : time := 31250 ps ; -- 32 MHz
  constant T_IoClk  : time := 1 us ;     -- 1 MHz

  -- DUT interface

  signal RegClk   : std_logic ;
  signal RegClkEn : std_logic ;
  signal RegRst   : std_logic ;
  signal RegCs    : std_logic ;
  signal RegWe    : std_logic ;
  signal RegRs    : std_logic_vector(3 downto 0) ;
  signal RegDw    : std_logic_vector(7 downto 0) ;
  signal RegDr    : std_logic_vector(7 downto 0) ;
  signal RegIrq   : std_logic ;
  signal IoClk    : std_logic ;
  signal IoClkEn  : std_logic ;
  signal IoRst    : std_logic ;
  signal IoPaI    : std_logic_vector(7 downto 0) ;
  signal IoPaO    : std_logic_vector(7 downto 0) ;
  signal IoPaDir  : std_logic_vector(7 downto 0) ;
  signal IoCa1    : std_logic ;
  signal IoCa2I   : std_logic ;
  signal IoCa2O   : std_logic ;
  signal IoCa2Dir : std_logic ;
  signal IoPbI    : std_logic_vector(7 downto 0) ;
  signal IoPbO    : std_logic_vector(7 downto 0) ;
  signal IoPbDir  : std_logic_vector(7 downto 0) ;
  signal IoCb1I   : std_logic ;
  signal IoCb1O   : std_logic ;
  signal IoCb1Dir : std_logic ;
  signal IoCb2I   : std_logic ;
  signal IoCb2O   : std_logic ;
  signal IoCb2Dir : std_logic ;


  -- transaction interface
  signal RegMasterRec : AddressBusRecType(
    Address       (3 downto 0),
    DataToModel   (7 downto 0),
    DataFromModel (7 downto 0)
  ) ;



begin

  -- clocks
  Osvvm.TbUtilPkg.CreateClock (
    Clk    => RegClk,
    Period => T_RegClk
  )  ;
  Osvvm.TbUtilPkg.CreateClock (
    Clk    => IoClk,
    Period => T_IoClk
  )  ;

  -- clock enables
  RegClkEn <= '1' ;
  IoClkEn <= '1' ;

  -- resets
  Osvvm.TbUtilPkg.CreateReset (
    Reset       => RegRst,
    ResetActive => '1',
    Clk         => RegClk,
    Period      => 8 * T_RegClk,
    tpd         => 1 ns
  ) ;
  Osvvm.TbUtilPkg.CreateReset (
    Reset       => IoRst,
    ResetActive => '1',
    Clk         => IoClk,
    Period      => 2 * T_IoClk,
    tpd         => 1 ns
  ) ;

  UUT_1: component r6522
    port map (
      reg_clk    => RegClk,
      reg_clken  => RegClkEn,
      reg_rst    => RegRst,
      reg_cs     => RegCs,
      reg_we     => RegWe,
      reg_rs     => RegRs,
      reg_dw     => RegDw,
      reg_dr     => RegDr,
      reg_irq    => RegIrq,
      io_clk     => IoClk,
      io_clken   => IoClkEn,
      io_rst     => IoRst,
      io_pa_i    => IoPaI,
      io_pa_o    => IoPaO,
      io_pa_dir  => IoPaDir,
      io_ca1     => IoCa1,
      io_ca2_i   => IoCa2I,
      io_ca2_o   => IoCa2O,
      io_ca2_dir => IoCa2Dir,
      io_pb_i    => IoPbI,
      io_pb_o    => IoPbO,
      io_pb_dir  => IoPbDir,
      io_cb1_i   => IoCb1I,
      io_cb1_o   => IoCb1O,
      io_cb1_dir => IoCb1Dir,
      io_cb2_i   => IoCb2I,
      io_cb2_o   => IoCb2O,
      io_cb2_dir => IoCb2Dir
    ) ;

  RegMaster_1: component RegMaster
    port map (
      -- register interface
      RegClk   => RegClk,
      RegClkEn => RegClkEn,
      RegRst   => RegRst,
      RegCs    => RegCs,
      RegWe    => RegWe,
      RegRs    => RegRs,
      RegDw    => RegDw,
      RegDr    => RegDr,
      RegIrq   => RegIrq,
      -- testbench transaction interface
      TransRec => RegMasterRec
    ) ;

  TestCtrl_1: component TestCtrl
    generic map (
      TbName              => TbName,
      ValidatedResultsDir => ValidatedResultsDir
    )
    port map (
      Reset        => RegRst,
      RegMasterRec => RegMasterRec
    ) ;

end architecture TestHarness;
