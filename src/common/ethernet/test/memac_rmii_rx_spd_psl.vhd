vunit memac_rmii_rx_spd_psl(memac_rmii_rx_spd(rtl)) {

-- clock
  default clock is rising_edge(clk);

  -- asynchronous reset
  assert always rst = '1' -> r_count  = (r_count'range => '0');
  assert always rst = '1' -> rdy      = '0';
  assert always rst = '1' -> i_state  = IDLE;
  assert always rst = '1' -> i_count  = (i_count'range => '0');
  assert always rst = '1' -> i_bad    = '0';
  assert always rst = '1' -> d_count  = (d_count'range => '0');
  assert always rst = '1' -> spd      = '0';
  assert always rst = '1' -> o_crs_dv = '0';
  assert always rst = '1' -> o_er     = '0';
  assert always rst = '1' -> o_d      = (o_d'range => '0');

  -- restrict analysis: every execution trace starts with a 1 clock reset
  --  and 64 clocks of quiet time to allow rdy to assert
  restrict {
    rst = '1' and i_crs_dv = '0' and i_er = '0' and i_d = "00";
    rst = '0' and i_crs_dv = '0' and i_er = '0' and i_d = "00" [*64];
    rst = '0' [*]
  };

  -- r_count behaviour
  assert always (
    {
      rdy = '0';
      true
    } |-> r_count = prev(r_count) + 1
  ) abort rst = '1';

  -- rdy behaviour
  assert always (
    {
      not r_count = 0;
      true
    } |-> rdy = '1'
  ) abort rst = '1';

  -- crs_dv negation during preamble or frame
  assert always (
    {
      (i_state = PRE or i_state = FIN) and i_crs_dv = '0';
      true
    } |-> i_state = FIN2
  ) abort rst = '1';

  -- crs_dv toggling at end of frame
  assert always (
    {
      i_state = FIN2 and i_crs_dv = '1';
      true
    } |-> i_state = FIN
  ) abort rst = '1';

  -- 2 negated cycles of crs_dv cause transition to idle

  assert always (
    {
      i_crs_dv = '0' [*2];
      true
    } |-> i_state = IDLE
  ) abort rst = '1';

  -- counter is set to 1 at transition out of idle
  assert always (
    {
      i_state = IDLE;
      i_state /= IDLE
    } |-> i_count = 1
  ) abort rst = '1';

  -- counter increments throughout frame
  assert always (
    {
      i_crs_dv = '1' and i_state /= IDLE;
      true
    } |->i_count = prev(i_count) + 1
  ) abort rst = '1';

  -- counter is zeroed at transition to idle
  assert always (
    {
      true;
      i_state = IDLE
    } |-> i_count = 0
  ) abort rst = '1';

  -- good start of preamble
  assert always (
    {
      i_crs_dv = '0' [*2];
      i_crs_dv = '1' and i_er = '0' and i_d = "00" [*0 to 2];
      rdy = '1' and i_crs_dv = '1' and i_er = '0' and i_d = "01";
      true
    } |-> i_state = PRE
  ) abort rst = '1';

  -- bad start of preamble
  assert always (
    {
      i_crs_dv = '0' [*2];
      i_crs_dv = '1' and i_er = '0' and i_d = "00" [*0 to 2];
      rdy = '1' and i_crs_dv = '1' and (i_er = '1' or i_d = "10" or i_d = "11");
      true
    } |-> i_state = FIN and i_bad = '1'
  ) abort rst = '1';

  -- truncated preamble
  assert always (
    {
      i_state = PRE and i_crs_dv = '0';
      true
    } |-> i_state = FIN2 and i_bad = '1'
  ) abort rst = '1';

  -- corruption during preamble
  assert always (
    {
      i_state = PRE and i_crs_dv = '1' and (i_er = '1' or i_d = "10");
      true
    } |-> i_state = FIN and i_bad = '1'
  ) abort rst = '1';

  -- octet aligned SFD (preamble + SFD is < 64 dibits) -> scheduled speed upshift
  assert always (
    {
      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "11" and i_count(5 downto 2) /= "1111" and i_count(1 downto 0) = "11";
      true
    } |-> i_state = FIN and ((d_count = prev(i_count) + 1 and prev(d_count) = 0) or (d_count = prev(d_count) + 1))
  ) abort rst = '1';

  -- octet aligned SFD (preamble + SFD = 64 dibits) -> immediate speed upshift
  assert always (
    {
      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "11" and i_count(5 downto 2) = "1111" and i_count(1 downto 0) = "11";
      true
    } |-> i_state = FIN and spd = '1' and ((d_count = 0 and prev(d_count) = 0) or (d_count = prev(d_count) + 1 and prev(d_count) /= 0))
  ) abort rst = '1';

  -- non octet aligned SFD
  assert always (
    {
      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "11" and i_count(1 downto 0) /= "11";
      true
    } |-> i_state = FIN and i_bad = '1' and ((d_count = prev(d_count) + 1 and prev(d_count) /= 0) or (d_count = 0 and prev(d_count) = 0))
  ) abort rst = '1';

  -- d_count behaviour
  assert always (
    {
      d_count /= 0;
      true
    } |-> d_count = prev(d_count) + 1
  ) abort rst = '1';

  -- spd assertion by d_count
  assert always (
    {
      not d_count = 0;
      true
    } |-> spd = '1'
  ) abort rst = '1';

  -- 64 cycles of preamble -> 10Mbps
  assert always (
    {
      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "01" and not i_count = 0;
      true
    } |-> spd = '0'
  ) abort rst = '1';

}
