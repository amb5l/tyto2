architecture tb_axi4_a32d32_srw32_test1 of TestCtrl is

  signal TestDone : integer_barrier := 1;

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin

    -- Initialization of test
    SetTestName("tb_axi4_a32d32_srw32_test1");
    SetLogEnable(PASSED, TRUE);    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE);    -- Enable INFO logs

    -- Wait for testbench initialization
    wait for 0 ns;  wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & "tb_axi4_a32d32_srw32_test1.txt");
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
    variable Data : std_logic_vector(AXI_DATA_WIDTH-1 downto 0);
    variable d8 : std_logic_vector(7 downto 0);
  begin
    wait until nReset = '1';
    WaitForClock(ManagerRec, 2);
    log("Write and Read with ByteAddr = 0, 4 Bytes");
    Write(ManagerRec, x"000000_00", x"55" );
    Read(ManagerRec,  x"000000_00", d8);
    AffirmIfEqual(d8, x"55", "Manager Read Data: ");

    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(ManagerRec, 2);
    WaitForBarrier(TestDone);
    wait;
  end process ManagerProc;

end architecture tb_axi4_a32d32_srw32_test1;

configuration cfg_tb_axi4_a32d32_srw32_test1 of tb_axi4_a32d32_srw32 is
  for sim
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(tb_axi4_a32d32_srw32_test1);
    end for;
  end for;
end cfg_tb_axi4_a32d32_srw32_test1;
