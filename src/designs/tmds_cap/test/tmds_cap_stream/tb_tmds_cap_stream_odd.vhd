
architecture tb_tmds_cap_stream_odd of TestCtrl is

  constant TestName : string := "tb_tmds_cap_stream_odd";

  constant TxPixels : integer := 15;
  constant TxWords  : integer := integer(ceil(real(TxPixels)/2.0));
  constant TxBytes  : integer := 4*TxPixels;
  constant TxParam  : std_logic_vector(PARAM_WIDTH-1 downto 0) := (0 => '1', others => '0');

  signal TestDone   : integer_barrier := 1;

begin

  cap_test <= '0';

  ControlProc: process
  begin
    SetTestName(TestName);
    SetLogEnable(PASSED, TRUE);
    SetLogEnable(INFO,   TRUE);
    wait for 0 ns;  wait for 0 ns;
    TranscriptOpen(OSVVM_RESULTS_DIR & TestName & ".txt");
    SetTranscriptMirror(TRUE);
    wait until rst_n = '1';
    ClearAlerts;
    WaitForBarrier(TestDone, 1 ms);
    AlertIf(now >= 1 ms, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    TranscriptClose;
    EndOfTestReports;
    std.env.stop;
    wait;
  end process ControlProc;

  tpclk <= 10 ns; -- 100 MHz (same as AXI)
  cap_size <= std_logic_vector(to_unsigned(TxPixels,cap_size'length));
  TxProc: process
  begin
    wait;
  end process TxProc;

  RxProc: process
    variable RxBurstMode : AddressBusFifoBurstModeType;
    variable RxParam     : std_logic_vector(PARAM_WIDTH-1 downto 0);
    variable RxWords     : integer;
    variable RxData      : std_logic_vector(DATA_WIDTH+USER_WIDTH-1 downto 0);
    variable TxData      : std_logic_vector(DATA_WIDTH-1 downto 0);
    constant User        : std_logic_vector(USER_WIDTH-1 downto 0) := (others => '0');
  begin
    WaitForClock(RxRec, 2);

    SetBurstMode(RxRec, STREAM_BURST_WORD_PARAM_MODE) ;
    GetBurstMode(RxRec,RxBurstMode);
    AffirmIfEqual(RxBurstMode, STREAM_BURST_WORD_PARAM_MODE, "RxBurstMode") ;

    GetBurst(RxRec, RxWords, RxParam) ;
    AffirmIfEqual(RxParam, TxParam, "RxParam");
    AffirmIfEqual(RxWords, TxWords, "RxWords");

    TxData := FirstWord;
    for i in 0 to TxWords-1 loop
      RxData := Pop(RxRec.BurstFifo);
      if i = TxWords-1 then
        TxData(DATA_WIDTH-1 downto DATA_WIDTH/2) := (others => 'U');
      end if;
      AffirmIfEqual(RxData, TxData & User, "RxData");
      TxData := std_logic_vector(unsigned(TxData)+unsigned(IncrWord));
    end loop ;

    WaitForClock(RxRec, 2);
    WaitForBarrier(TestDone);
    wait;
  end process RxProc;

end architecture tb_tmds_cap_stream_odd;

configuration cfg_tb_tmds_cap_stream_odd of tb_tmds_cap_stream is
  for sim
    for CTRL: TestCtrl
      use entity work.TestCtrl(tb_tmds_cap_stream_odd);
    end for;
  end for;
end cfg_tb_tmds_cap_stream_odd;
