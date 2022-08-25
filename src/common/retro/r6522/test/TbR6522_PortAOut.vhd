-- test case: PortABOD
-- verify port A & B output and data direction registers

architecture PortAOut of TestCtrl is

  constant TestName        : string := "PortAOut" ;
  constant ResultsLogName  : string := TbName & "_" & TestName ;
  constant ResultsFileName : string := ResultsLogName & ".txt" ;

  constant TimeOut         : time := 1 ms ;

  signal   TestDone        : integer_barrier := 1 ;

begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetAlertLogName(ResultsLogName) ;
    SetLogEnable(PASSED, TRUE) ;
    SetLogEnable(INFO,   TRUE) ;
    -- wait for testbench initialization
    wait until Reset = '1' ;
    report "Reset 1" ;
    TranscriptOpen(ResultsFileName) ;
    SetTranscriptMirror(TRUE) ;
    -- wait for reset to be released
    wait until Reset = '0' ;
    report "Reset 0" ;
    ClearAlerts ;
    -- Wait for test to finish
    WaitForBarrier(TestDone, TimeOut) ;
    AlertIf(now >= TimeOut, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    -- ?
    TranscriptClose ;
    -- AlertIfDiff(ResultsFileName, ValidatedResultsDir & ResultsFileName, "") ;
    -- ?
    EndOfTestReports ;
    std.env.stop(GetAlertCount) ;
    wait ;
  end process ControlProc ;

  ------------------------------------------------------------
  -- RegMasterProc
  --   Generate transactions for RegMaster
  ------------------------------------------------------------
  RegMasterProc: process
    variable WData, RData : std_logic_vector(7 downto 0) ;
  begin
    wait until Reset = '0' ;
    WaitForClock(RegMasterRec, 1) ;
    for i in 0 to 255 loop
      WData := std_logic_vector(to_unsigned(i, 8)) ;
      Write (RegMasterRec, R6522_RA_DDRA, WData) ; -- set all pin directions to output
      Read  (RegMasterRec, R6522_RA_DDRA, RData ) ; -- check...
      AffirmIfEqual(RData, WData, "RegMaster Read Data: ") ;
    end loop ;
    WaitForClock(RegMasterRec, 1) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process RegMasterProc;

  ------------------------------------------------------------
  -- PortWatcherProc
  --   Generate transactions for RegMaster
  ------------------------------------------------------------


end architecture PortAOut;
