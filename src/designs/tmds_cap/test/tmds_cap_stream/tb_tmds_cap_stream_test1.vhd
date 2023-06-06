architecture tb_tmds_cap_stream_test1 of TestCtrl is

  constant TestName : string := "tb_tmds_cap_stream_test1";

  signal TestDone : integer_barrier := 1;

begin

  ControlProc: process
  begin
    SetTestName(TestName);
    SetLogEnable(PASSED, TRUE);
    SetLogEnable(INFO,   TRUE);
    wait for 0 ns;  wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & TestName & ".txt");
    SetTranscriptMirror(TRUE);
    wait until nReset = '1';
    ClearAlerts;
    WaitForBarrier(TestDone, 35 ms);
    AlertIf(now >= 35 ms, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process ControlProc;

  AxiStreamRxProc : process
    variable NumBytes : integer; 
  begin
    WaitForClock(StreamRxRec, 2); 
    GetBurst(StreamRxRec, NumBytes);
    AffirmIfEqual(NumBytes, 32, "Receiver: NumBytes Received");
    CheckBurstIncrement(RxBurstFifo, 1, NumBytes, DATA_WIDTH);
    WaitForClock(StreamRxRec, 2);
    WaitForBarrier(TestDone);
    wait;
  end process AxiStreamRxProc;

end architecture tb_tmds_cap_stream_test1;

configuration cfg_tb_tmds_cap_stream_test1 of tb_tmds_cap_stream_test1 is
  for sim
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(tb_tmds_cap_stream_test1);
    end for;
  end for;
end cfg_tb_tmds_cap_stream_test1;
