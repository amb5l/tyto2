vunit memac_rmii_rx_psl(memac_rmii_rx(rtl)) {

  -- clock
  default clock is rising_edge(clk);

  -- asynchronous reset
  assert always rst = '1' -> s1_crs_dv = '0';
  assert always rst = '1' -> s1_er     = '0';
  assert always rst = '1' -> s1_d      = "00";
  assert always rst = '1' -> s2_crs_dv = '0';
  assert always rst = '1' -> s2_er     = '0';
  assert always rst = '1' -> s2_d      = "00";
  assert always rst = '1' -> s3_crs_dv = '0';
  assert always rst = '1' -> s3_er     = '0';
  assert always rst = '1' -> s3_d      = "00";
  assert always rst = '1' -> s4_crs_dv = '0';
  assert always rst = '1' -> s4_er     = '0';
  assert always rst = '1' -> s4_d      = "00";
  assert always rst = '1' -> s5_act    = '0';
  assert always rst = '1' -> s5_crs    = '0';
  assert always rst = '1' -> s5_dv     = '0';
  assert always rst = '1' -> s5_er     = '0';
  assert always rst = '1' -> s5_d      = "00";
  assert always rst = '1' -> s5_dibit  = "00";
  assert always rst = '1' -> s6_stb    = '0';
  assert always rst = '1' -> s6_crs    = x"0";
  assert always rst = '1' -> s6_dv     = x"0";
  assert always rst = '1' -> s6_er     = x"0";
  assert always rst = '1' -> s6_d      = x"00";
  assert always rst = '1' -> s7_crs    = x"0";
  assert always rst = '1' -> s7_dv     = x"0";
  assert always rst = '1' -> s7_er     = x"0";
  assert always rst = '1' -> s7_d      = x"00";
  assert always rst = '1' -> umii_dv   = '0';
  assert always rst = '1' -> umii_er   = '0';
  assert always rst = '1' -> umii_d    = x"00";

  -- sequences
  sequence seq_null_half_speed is
    {
      rmii_clken = '0';
      rmii_clken = '1'
    };
  sequence seq_crs_half_speed is
    {
      rmii_clken = '0';
      rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "00"
    };
  sequence seq_pre_half_speed is
    {
      rmii_clken = '0';
      rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "01"
    };

  -- restrict reset behaviour
  restrict {
    rst = '1' and rmii_clken = '0' and umii_clken = '0' and rmii_crs_dv = '0' and rmii_er = '0' and rmii_d = "00";
    rst = '0'  [*]
  };

  -- assume umii_clken behaviour
  -- assume {
  --   rmii_clken = '1' [*4]} |-> umii_clken = '1';
  -- assume {seq_null_half_speed [*4]} |-> umii_clken = '1';

  -- pipeline stages 0..4
  assert always (
  {
    rmii_clken = '1';
    true
  } |->
    s1_crs_dv = prev(rmii_crs_dv) and
    s1_er     = prev(rmii_er)     and
    s1_d      = prev(rmii_d)      and
    s2_crs_dv = prev(s1_crs_dv) and
    s2_er     = prev(s1_er)     and
    s2_d      = prev(s1_d)      and
    s3_crs_dv = prev(s2_crs_dv) and
    s3_er     = prev(s2_er)     and
    s3_d      = prev(s2_d)      and
    s4_crs_dv = prev(s3_crs_dv) and
    s4_er     = prev(s3_er)     and
    s4_d      = prev(s3_d)
    ) abort rst = '1';

  -- s5_act
  assert always (
    {
      rmii_clken = '1' and s4_crs_dv = '1' and s4_d /= "00";
      true
    } |-> s5_act = '1'
  ) abort rst = '1';

  assert always (
    {
      rmii_clken = '1' and s5_act = '1' and s3_crs_dv = '0' and s4_crs_dv = '0';
      true
    } |-> s5_act = '0'
  ) abort rst = '1';

  -- s5_crs
  assert always (
    {
      rmii_clken = '1' and s5_act = '0' and s4_crs_dv = '1';
      true
    } |-> s5_crs = '1'
  ) abort rst = '1';
  assert always (
    {
      rmii_clken = '1' and s5_crs = '1' and s4_crs_dv = '0';
      true
    } |-> s5_crs = '0'
  ) abort rst = '1';

  -- s5_dv
   assert always (
     {
       rmii_clken = '1' and s5_act = '0' and s4_crs_dv = '1' and s4_d = "01";
       true
     } |-> s5_dv = '1'
   ) abort rst = '1';
   assert always (
     {
       rmii_clken = '1' and s3_crs_dv = '0' and s4_crs_dv = '0';
       true
     } |-> s5_dv = '0'
   ) abort rst = '1';
   assert never
     s5_dv = '1' and prev(s5_dv) = '0' and prev(s5_dv,2) = '1';

  -- s5_er
  assert always (
    {
      true and rmii_clken = '1';
      true
    } |-> s5_er = prev(s4_er)
  ) abort rst = '1';

  -- s5_d
  assert always (
    {
      true and rmii_clken = '1';
      true
    } |-> s5_d = prev(s4_d)
  ) abort rst = '1';

  -- s5_dibit
  assert always (
    {
      rmii_clken = '1' and s3_crs_dv = '0' and s4_crs_dv = '0';
      true
    } |-> s5_dibit = "00"
  ) abort rst = '1';
  assert always (
    {
      rmii_clken = '1' and s5_dv = '1' and not (s3_crs_dv = '0' and s4_crs_dv = '0');
      true
    } |-> s5_dibit = std_ulogic_vector(unsigned(prev(s5_dibit,1)) + 1)
  ) abort rst = '1';

  -- s6_dv, s6_er and s6_d
  assert always (
    {
      true and rmii_clken = '1';
      true
    } |->
          s6_dv(to_integer(unsigned(prev(s5_dibit))))    = prev(s5_dv)
      and s6_er(to_integer(unsigned(prev(s5_dibit))))    = prev(s5_er)
      and s6_d(to_integer(unsigned(prev(s5_dibit)))*2)   = prev(s5_d(0))
      and s6_d(to_integer(unsigned(prev(s5_dibit)))*2+1) = prev(s5_d(1))
  ) abort rst = '1';

  -- s6_stb
  assert always (
    {
      true and rmii_clken = '1';
      true
    } |-> s6_stb = (prev(s5_dibit(0)) and prev(s5_dibit(1)))
  ) abort rst = '1';

--  -- first preamble octet to s6 (full speed)
--
--    --  assert always (
--    --    {
--    --      rmii_clken = '1' and rmii_crs_dv = '0';
--    --      rmii_clken = '1' and rmii_crs_dv = '0';
--    --      rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "00" [*0 to 3];
--    --      rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "01" [*4];
--    --      rmii_clken = '1' [*6]
--    --    } |->
--    --          s6_dv    = x"F"
--    --      and s6_er(0) = prev(rmii_er,9)
--    --      and s6_er(1) = prev(rmii_er,8)
--    --      and s6_er(2) = prev(rmii_er,7)
--    --      and s6_er(3) = prev(rmii_er,6)
--    --      and s6_d     = x"55"
--    --      and s6_stb   = '1'
--    --  ) abort rst = '1';
--
--  -- first preamble octet to s6 (half speed)
--
--    --  assert always (
--    --    {
--    --      rmii_clken = '0';
--    --      rmii_clken = '1' and rmii_crs_dv = '0';
--    --      rmii_clken = '0';
--    --      rmii_clken = '1' and rmii_crs_dv = '0';
--    --      seq_crs_half_speed [*0 to 3];
--    --      seq_pre_half_speed [*4];
--    --      seq_null_half_speed [*6]
--    --    } |->
--    --          s6_dv    = x"F"
--    --      and s6_er(0) = prev(rmii_er,9)
--    --      and s6_er(1) = prev(rmii_er,8)
--    --      and s6_er(2) = prev(rmii_er,7)
--    --      and s6_er(3) = prev(rmii_er,6)
--    --      and s6_d     = x"55"
--    --      and s6_stb   = '1'
--    --  ) abort rst = '1';

--  -- packing first 4 di-bits of preamble into octet
--
--    --  sequence seq_crs is  {
--    --    rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "00";
--    --    rst = '0' and rmii_clken = '0' [*0 to 9]
--    --  };
--    --  assert always (
--    --    {
--    --      rmii_clken = '1' and rmii_crs_dv = '0';
--    --      true and rmii_clken = '0' [*0 to 9];
--    --      rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "00" [*0 to 1];
--    --      true and rmii_clken = '0' [*0 to 9];
--    --      rmii_clken = '1' and rmii_crs_dv = '1' and rmii_d = "01";
--    --      true and rmii_clken = '0' [*0 to 9];
--    --      true [*];
--    --    } -> eventually!(s6_stb = '1'
--    --  ) abort rst = '1';

}