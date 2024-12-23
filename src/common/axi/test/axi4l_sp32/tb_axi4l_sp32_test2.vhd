--------------------------------------------------------------------------------
-- tb_axi4l_sp32_test2.vhd                                                    --
-- OSVVM based testbench for axi4l_sp32.vhd - test 2                          --
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

architecture tb_axi4l_sp32_test2 of TestCtrl is

  constant TestName : string := "tb_axi4l_sp32_test2";

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
    variable amax      : integer;
    variable d16_start : std_logic_vector( 15 downto 0 );
    variable d16_incr  : std_logic_vector( 15 downto 0 );
    variable d16       : std_logic_vector( 15 downto 0 );
    variable r16       : std_logic_vector( 15 downto 0 );
  begin
    wait until nReset = '1';
    WaitForClock(ManagerRec, 2);

    amax      := (2**(addr_width-1))-1;
    d16_start := x"3141";
    d16_incr  := x"2718";

    log("16 bit fill then check (incrementing data)");
    d16 := d16_start;
    for i in 0 to amax loop
      Write(ManagerRec, std_logic_vector(to_unsigned(i*2,32)), d16);
      d16 := std_logic_vector(unsigned(d16)+unsigned(d16_incr));
    end loop;
    d16 := d16_start;
    for i in 0 to amax loop
      Read(ManagerRec,  std_logic_vector(to_unsigned(i*2,32)), r16);
      AffirmIfEqual(r16, d16, "Manager Read Data: ");
      d16 := std_logic_vector(unsigned(d16)+unsigned(d16_incr));
    end loop;

    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ManagerRec, 2);
    WaitForBarrier(TestDone);
    wait;
  end process ManagerProc;

end architecture tb_axi4l_sp32_test2;

configuration cfg_tb_axi4l_sp32_test2 of tb_axi4l_sp32 is
  for sim
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(tb_axi4l_sp32_test2);
    end for;
  end for;
end cfg_tb_axi4l_sp32_test2;
