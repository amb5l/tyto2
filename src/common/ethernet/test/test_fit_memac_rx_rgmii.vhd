use work.mmcm_pkg.all;
use work.memac_rx_rgmii_pkg.all;
use work.memac_rx_rgmii_io_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity test_fit_memac_rx_rgmii is
  port (
    ref_rst   : in    std_ulogic;
    ref_clk   : in    std_ulogic;                    -- 125 MHz
    umi_spdi  : in    std_ulogic_vector(1 downto 0); -- requested speed
    umi_spdo  : out   std_ulogic_vector(1 downto 0); -- measured speed
    umi_rst   : in    std_ulogic;
    umi_clk   : out   std_ulogic;
    umi_clken : out   std_ulogic;
    umi_dv    : out   std_ulogic;
    umi_er    : out   std_ulogic;
    umi_d     : out   std_ulogic_vector(7 downto 0);
    ibs_crs   : out   std_ulogic;                    -- carrier sense
    ibs_crx   : out   std_ulogic;                    -- carrier extend
    ibs_crxer : out   std_ulogic;                    -- carrier extend error
    ibs_crf   : out   std_ulogic;                    -- carrier false
    ibs_link  : out   std_ulogic;                    -- link up
    ibs_spd   : out   std_ulogic_vector(1 downto 0); -- speed
    ibs_fdx   : out   std_ulogic;                    -- full duplex
    rgmii_clk : in    std_ulogic;
    rgmii_ctl : in    std_ulogic;
    rgmii_d   : in    std_ulogic_vector(3 downto 0)
  );
end entity test_fit_memac_rx_rgmii;

architecture rtl of test_fit_memac_rx_rgmii is

  signal rst              : std_ulogic;
  signal clk_200m         : std_ulogic;

  signal rgmii_clk_io     : std_ulogic;
  signal rgmii_ctl_io     : std_ulogic;
  signal rgmii_d_io       : std_ulogic_vector(3 downto 0);

begin

  U_MMCM: component mmcm
    generic map (
      mul         => 8.0,
      div         => 1,
      num_outputs => 1,
      odiv0       => 5.0
    )
    port map (
      rsti        => ref_rst,
      clki        => ref_clk,
      rsto        => rst,
      clko(0)     => clk_200m
    );

  U_IDELAYCTRL: component idelayctrl
    port map (
      rst    => rst,
      refclk => clk_200m,
      rdy    => open
    );


--  U_MMCM_REF: component mmcme2_adv
--    generic map (
--      bandwidth            => "OPTIMIZED",
--      clkfbout_mult_f      => 8.0,
--      clkfbout_phase       => 0.0,
--      clkfbout_use_fine_ps => false,
--      clkin1_period        => 8.0, -- 125.0 MHz
--      clkin2_period        => 0.0,
--      clkout0_divide_f     => 5.0,
--      clkout0_duty_cycle   => 0.5,
--      clkout0_phase        => 0.0,
--      clkout0_use_fine_ps  => false,
--      clkout1_divide       => 10,
--      clkout1_duty_cycle   => 0.5,
--      clkout1_phase        => 0.0,
--      clkout1_use_fine_ps  => false,
--      clkout2_divide       => 10,
--      clkout2_duty_cycle   => 0.5,
--      clkout2_phase        => 0.0,
--      clkout2_use_fine_ps  => false,
--      clkout3_divide       => 10,
--      clkout3_duty_cycle   => 0.5,
--      clkout3_phase        => 0.0,
--      clkout3_use_fine_ps  => false,
--      clkout4_cascade      => false,
--      clkout4_divide       => 10,
--      clkout4_duty_cycle   => 0.5,
--      clkout4_phase        => 0.0,
--      clkout4_use_fine_ps  => false,
--      clkout5_divide       => 10,
--      clkout5_duty_cycle   => 0.5,
--      clkout5_phase        => 0.0,
--      clkout5_use_fine_ps  => false,
--      clkout6_divide       => 10,
--      clkout6_duty_cycle   => 0.5,
--      clkout6_phase        => 0.0,
--      clkout6_use_fine_ps  => false,
--      compensation         => "ZHOLD",
--      divclk_divide        => 1,
--      is_clkinsel_inverted => '0',
--      is_psen_inverted     => '0',
--      is_psincdec_inverted => '0',
--      is_pwrdwn_inverted   => '0',
--      is_rst_inverted      => '0',
--      ref_jitter1          => 0.01,
--      ref_jitter2          => 0.01,
--      ss_en                => "FALSE",
--      ss_mode              => "CENTER_HIGH",
--      ss_mod_period        => 10000,
--      startup_wait         => false
--    )
--    port map (
--      pwrdwn               => '0',
--      rst                  => ref_rst,
--      locked               => mmcm_ref_lock_a,
--      clkin1               => ref_clk,
--      clkin2               => '0',
--      clkinsel             => '1',
--      clkinstopped         => open,
--      clkfbin              => mmcm_ref_fbi,
--      clkfbout             => mmcm_ref_fbo,
--      clkfboutb            => open,
--      clkfbstopped         => open,
--      clkout0              => mmcm_ref_clkout0,
--      clkout0b             => open,
--      clkout1              => open,
--      clkout1b             => open,
--      clkout2              => open,
--      clkout2b             => open,
--      clkout3              => open,
--      clkout3b             => open,
--      clkout4              => open,
--      clkout5              => open,
--      clkout6              => open,
--      dclk                 => '0',
--      daddr                => (others => '0'),
--      den                  => '0',
--      dwe                  => '0',
--      di                   => (others => '0'),
--      do                   => open,
--      drdy                 => open,
--      psclk                => '0',
--      psdone               => open,
--      psen                 => '0',
--      psincdec             => '0'
--    );
--
--  U_BUFG_REF_CLK: component bufg
--    port map (
--      i => mmcm_ref_clkout0,
--      o => idelay_clk
--    );
--
--  U_BUFG_REF_FB: component bufg
--    port map (
--      i => mmcm_ref_fbo,
--      o => mmcm_ref_fbi
--    );
--
--  U_IDELAYCTRL: component idelayctrl
--    port map (
--      rst    => not mmcm_ref_lock_a,
--      refclk => idelay_clk,
--      rdy    => open
--    );
--
--  U_IBUF_CLK: component ibuf
--    port map (
--      i  => rgmii_clk,
--      o  => rgmii_clk_i
--    );
--
--  U_IDELAY_CLK: component idelaye2
--    generic map (
--      delay_src             => "IDATAIN",
--      idelay_type           => "FIXED",
--      pipe_sel              => "FALSE",
--      idelay_value          => 6,
--      signal_pattern        => "CLOCK",
--      refclk_frequency      => 200.0,
--      high_performance_mode => "TRUE",
--      cinvctrl_sel          => "FALSE"
--    )
--    port map (
--      regrst      => '0',
--      cinvctrl    => '0',
--      c           => '0',
--      ce          => '0',
--      inc         => '0',
--      ld          => '0',
--      ldpipeen    => '0',
--      cntvaluein  => (others => '0'),
--      cntvalueout => open,
--      idatain     => rgmii_clk_i,
--      datain      => '0',
--      dataout     => rgmii_clk_d
--    );
--
--  U_BUFIO: component bufio
--    port map (
--      i  => rgmii_clk_d,
--      o  => rgmii_clk_io
--    );
--
--  U_BUFR: component bufr
--    port map (
--      ce  => '1',
--      clr => '0',
--      i   => rgmii_clk_d,
--      o   => umi_clk
--    );
--
--  U_IBUF_CTL: component ibuf
--    port map (
--      i  => rgmii_ctl,
--      o  => rgmii_ctl_i
--    );
--
--  U_IDELAY_CTL: component idelaye2
--    generic map (
--      delay_src             => "IDATAIN",
--      idelay_type           => "FIXED",
--      pipe_sel              => "FALSE",
--      idelay_value          => 0,
--      signal_pattern        => "DATA",
--      refclk_frequency      => 200.0,
--      high_performance_mode => "TRUE",
--      cinvctrl_sel          => "FALSE"
--    )
--    port map (
--      regrst      => '0',
--      cinvctrl    => '0',
--      c           => '0',
--      ce          => '0',
--      inc         => '0',
--      ld          => '0',
--      ldpipeen    => '0',
--      cntvaluein  => (others => '0'),
--      cntvalueout => open,
--      idatain     => rgmii_ctl_i,
--      datain      => '0',
--      dataout     => rgmii_ctl_d
--    );
--
--  GEN_IDELAY_D: for i in 0 to 3 generate
--
--    U_IBUF_D: component ibuf
--      port map (
--        i  => rgmii_d(i),
--        o  => rgmii_d_i(i)
--      );
--
--    U_IDELAY_D: component idelaye2
--      generic map (
--        delay_src             => "IDATAIN",
--        idelay_type           => "FIXED",
--        pipe_sel              => "FALSE",
--        idelay_value          => 0,
--        signal_pattern        => "DATA",
--        refclk_frequency      => 200.0,
--        high_performance_mode => "TRUE",
--        cinvctrl_sel          => "FALSE"
--      )
--      port map (
--        regrst      => '0',
--        cinvctrl    => '0',
--        c           => '0',
--        ce          => '0',
--        inc         => '0',
--        ld          => '0',
--        ldpipeen    => '0',
--        cntvaluein  => (others => '0'),
--        cntvalueout => open,
--        idatain     => rgmii_d_i(i),
--        datain      => '0',
--        dataout     => rgmii_d_d(i)
--      );
--
--  end generate GEN_IDELAY_D;


  DUT: component memac_rx_rgmii
    port map (
      ref_rst   => ref_rst,
      ref_clk   => ref_clk,
      umi_spdi  => umi_spdi,
      umi_spdo  => umi_spdo,
      umi_rst   => umi_rst,
      umi_clk   => umi_clk,
      umi_clken => umi_clken,
      umi_dv    => umi_dv,
      umi_er    => umi_er,
      umi_d     => umi_d,
      ibs_crs   => ibs_crs,
      ibs_crx   => ibs_crx,
      ibs_crxer => ibs_crxer,
      ibs_crf   => ibs_crf,
      ibs_link  => ibs_link,
      ibs_spd   => ibs_spd,
      ibs_fdx   => ibs_fdx,
      rgmii_clk => rgmii_clk_io,
      rgmii_ctl => rgmii_ctl_io,
      rgmii_d   => rgmii_d_io
    );

  U_RGMII_RX_IO: component memac_rx_rgmii_io
    generic map (
      CLK_ALIGN => "EDGE"
    )
    port map (
      i_clk   => rgmii_clk,
      i_ctl   => rgmii_ctl,
      i_d     => rgmii_d,
      o_clkr  => umi_clk,
      o_clkio => rgmii_clk_io,
      o_ctl   => rgmii_ctl_io,
      o_d     => rgmii_d_io
    );

end architecture rtl;
