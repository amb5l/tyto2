--------------------------------------------------------------------------------
-- tb_axi4l_sp32_test3.vhd                                                    --
-- OSVVM based testbench for axi4l_sp32.vhd - test 3                          --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

architecture tb_axi4l_sp32_test3 of TestCtrl is

  constant TestName : string := "tb_axi4l_sp32_test3";

  signal TestDone : integer_barrier := 1;

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin

    -- Initialization of test
    SetTestName(TestName);
    SetLogEnable(PASSED, TRUE);    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE);    -- Enable INFO logs

    -- Wait for testbench initialization
    wait for 0 ns;  wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & TestName & ".txt");
    SetTranscriptMirror(TRUE);

    -- Wait for Design Reset
    wait until nReset = '1';
    ClearAlerts;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 35 ms);
    AlertIf(now >= 35 ms, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");

    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process ControlProc;

  ------------------------------------------------------------
  -- ManagerProc
  --   Generate transactions for AxiManager
  ------------------------------------------------------------
  ManagerProc : process
    variable amax     : integer;
    variable d8_start : std_logic_vector( 7 downto 0 );
    variable d8_incr  : std_logic_vector( 7 downto 0 );
    variable d8       : std_logic_vector( 7 downto 0 );
    variable r8       : std_logic_vector( 7 downto 0 );
  begin
    wait until nReset = '1';
    WaitForClock(ManagerRec, 2);

    amax      := (2**addr_width)-1;
    d8_start := x"00";
    d8_incr  := x"01";

    log("8 bit fill then check (incrementing data)");
    d8 := d8_start;
    for i in 0 to amax loop
      Write(ManagerRec, std_logic_vector(to_unsigned(i,32)), d8);
      d8 := std_logic_vector(unsigned(d8)+unsigned(d8_incr));
    end loop;
    d8 := d8_start;
    for i in 0 to amax loop
      Read(ManagerRec,  std_logic_vector(to_unsigned(i,32)), r8);
      AffirmIfEqual(r8, d8, "Manager Read Data: ");
      d8 := std_logic_vector(unsigned(d8)+unsigned(d8_incr));
    end loop;

    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ManagerRec, 2);
    WaitForBarrier(TestDone);
    wait;
  end process ManagerProc;

end architecture tb_axi4l_sp32_test3;

configuration cfg_tb_axi4l_sp32_test3 of tb_axi4l_sp32 is
  for sim
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(tb_axi4l_sp32_test3);
    end for;
  end for;
end cfg_tb_axi4l_sp32_test3;
