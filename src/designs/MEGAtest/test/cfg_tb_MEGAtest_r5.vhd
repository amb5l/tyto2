--------------------------------------------------------------------------------
-- cfg_tb_MEGAtest_r5_fast.vhd
--------------------------------------------------------------------------------

architecture mmcm_v2_fast of mmcm_v2 is
begin

  P_RST: process(rsti)
  begin
    if rsti = 'U' and now = 0 ps then
      rsto <= '1';
    elsif rsti = '1' or rsti = 'H' then
      rsto <= '1';
    elsif rsti = '0' or rsti = 'L' then
      rsto <= '0' after 1 us;
    else
      rsto <= 'X';
    end if;
  end process P_RST;

  P_COMB: process(all)
  begin
    clk0 <= '0' when clk0 = 'U' else not clk0 after  5 ns; -- 200 MHz
    clk1 <= '0' when clk1 = 'U' else not clk1 after 10 ns; -- 100 MHz
    clk2 <= clk1'delayed(7.5 ns);
    clk3 <= '0';
    clk4 <= '0';
    clk5 <= '0';
    clk6 <= '0';
  end process P_COMB;

end architecture mmcm_v2_fast;

--------------------------------------------------------------------------------

architecture video_out_clock_v2_fast of video_out_clock_v2 is

  constant t : time_vector(0 to 3) := (3968 ps, 3704 ps, 1347 ps, 673 ps);

begin

  P_RST: process(rsti)
  begin
    if rsti = 'U' and now = 0 ps then
      rsto <= '1';
    elsif rsti = '1' or rsti = 'H' then
      rsto <= '1';
    elsif rsti = '0' or rsti = 'L' then
      rsto <= '0' after 1 us;
    else
      rsto <= 'X';
    end if;
  end process P_RST;

  P_MAIN: process
    variable s : integer range 0 to 3;
  begin
    clko    <= '0';
    clko_x5 <= '0';
    wait for 0 ps;
    loop
      s := to_integer(unsigned(sel));
      for i in 1 to 5 loop
        wait for t(s);
        clko_x5 <= not clko_x5;
      end loop;
      clko <= not clko;
    end loop;
    wait for 5*t(s);
  end process P_MAIN;

end architecture video_out_clock_v2_fast;

--------------------------------------------------------------------------------

configuration cfg_clk_rst_fast of clk_rst is
  for rtl
    for U_MMCM: mmcm_v2
      use entity work.mmcm_v2(mmcm_v2_fast);
    end for;
  end for;
end configuration cfg_clk_rst_fast;

configuration cfg_display_fast of display is
  for rtl
    for U_MMCM: video_out_clock_v2
      use entity work.video_out_clock_v2(video_out_clock_v2_fast);
    end for;
  end for;
end configuration cfg_display_fast;

configuration cfg_MEGAtest_fast of MEGAtest is
  for rtl
    for U_CLK_RST: clk_rst
      use configuration work.cfg_clk_rst_fast;
    end for;
    for U_DISPLAY: display
      use configuration work.cfg_display_fast;
    end for;
  end for;
end configuration cfg_MEGAtest_fast;

configuration cfg_MEGAtest_r5_fast of MEGAtest_r5 is
  for rtl
    for MAIN: MEGAtest
      use configuration work.cfg_MEGAtest_fast;
    end for;
  end for;
end configuration cfg_MEGAtest_r5_fast;

configuration cfg_tb_MEGAtest_r5_fast of tb_MEGAtest_r5 is
  for sim
    for DUT: MEGAtest_r5
      use configuration work.cfg_MEGAtest_r5_fast;
    end for;
  end for;
end configuration cfg_tb_MEGAtest_r5_fast;

configuration cfg_tb_MEGAtest_r5_std of tb_MEGAtest_r5 is
  for sim
    for DUT: MEGAtest_r5
      use entity work.MEGAtest_r5(rtl);
    end for;
  end for;
end configuration cfg_tb_MEGAtest_r5_std;

--------------------------------------------------------------------------------
