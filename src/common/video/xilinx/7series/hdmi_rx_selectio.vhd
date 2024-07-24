--------------------------------------------------------------------------------
-- hdmi_rx_selectio.vhd                                                       --
-- HDMI sink front end built on Xilinx 7 Series SelectIO primitives.          --
-- Notes:                                                                     --
-- 1) Does not include I/O buffers.                                           --
-- 2) Supports pixel clocks in the range 25..148.5MHz. -1 parts are rated at  --
-- 950Mbps (95MHz) max, and -2 parts are rated at 1200Mbps max.               --
-- Higher frequencies may not work!                                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;

package hdmi_rx_selectio_pkg is

  type hdmi_rx_selectio_status_t is record
      count_freq    : std_logic_vector(31 downto 0);
      band          : std_logic_vector(1 downto 0);
      lock          : std_logic;
      align_s       : std_logic_vector(0 to 2);
      align_p       : std_logic;
      skew_p        : slv2_vector(1 to 2);
      tap_mask      : slv32_vector(0 to 2);
      tap           : slv5_vector(0 to 2);
      bitslip       : slv4_vector(0 to 2);
      count_acycle  : slv32_vector(0 to 2);
      count_tap_ok  : slv32_vector(0 to 2);
      count_again_s : slv32_vector(0 to 2);
      count_again_p : std_logic_vector(31 downto 0);
      count_aloss_s : slv32_vector(0 to 2);
      count_aloss_p : std_logic_vector(31 downto 0);
      ctrl_char     : std_logic_vector(0 to 2);
  end record hdmi_rx_selectio_status_t;

  component hdmi_rx_selectio is
    generic (
      fclk    : real
    );
    port (
      rst     : in    std_logic;
      clk     : in    std_logic;
      pclki   : in    std_logic;
      si      : in    std_logic_vector(0 to 2);
      sclko   : out   std_logic;
      prsto   : out   std_logic;
      pclko   : out   std_logic;
      po      : out   slv10_vector(0 to 2);
      status  : out   hdmi_rx_selectio_status_t
    );
  end component hdmi_rx_selectio;

end package hdmi_rx_selectio_pkg;

----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.hdmi_rx_selectio_clk_pkg.all;
  use work.hdmi_rx_selectio_align_pkg.all;

entity hdmi_rx_selectio is
  generic (
    fclk    : real                               -- clk frequency (MHz)
  );
  port (
    rst     : in    std_logic;                   -- reset (sychronous to clk)
    clk     : in    std_logic;                   -- clock (measurement and control)
    pclki   : in    std_logic;                   -- pixel clock in
    si      : in    std_logic_vector(0 to 2);    -- serial TMDS in
    sclko   : out   std_logic;                   -- serial clock out
    prsto   : out   std_logic;                   -- pixel clock reset out
    pclko   : out   std_logic;                   -- pixel clock out
    po      : out   slv10_vector(0 to 2);        -- parallel TMDS out
    status  : out   hdmi_rx_selectio_status_t
  );
end entity hdmi_rx_selectio;

architecture synth of hdmi_rx_selectio is

  signal prst           : std_logic;                    -- pclk domain synchronous reset
  signal pclk           : std_logic;                    -- main pixel clock
  signal sclk           : std_logic;                    -- serial clock
  signal sclkb          : std_logic;                    -- serial clock inverted

  signal idelay_ld      : std_logic_vector(0 to 2);     -- load tap value
  signal idelay_tap     : std_logic_vector(4 downto 0); -- tap value (0..31)
  signal iserdes_ddly   : std_logic_vector(0 to 2);     -- serial input, delayed by IDELAYE2
  signal iserdes_slip   : std_logic_vector(0 to 2);     -- bit slip
  signal iserdes_q      : slv10_vector(0 to 2);
  signal iserdes_shift1 : std_logic_vector(0 to 2);     -- master-slave cascade
  signal iserdes_shift2 : std_logic_vector(0 to 2);     -- "

  signal status_clk     : hdmi_rx_selectio_clk_status_t;
  signal status_align   : hdmi_rx_selectio_align_status_t;

begin

  sclko <= sclk;
  prsto <= prst;
  pclko <= pclk;

  status.count_freq    <= status_clk.count_freq;
  status.band          <= status_clk.band;
  status.lock          <= status_clk.lock;
  status.align_s       <= status_align.align_s;
  status.align_p       <= status_align.align_p;
  status.skew_p        <= status_align.skew_p;
  status.tap_mask      <= status_align.tap_mask;
  status.tap           <= status_align.tap;
  status.bitslip       <= status_align.bitslip;
  status.count_acycle  <= status_align.count_acycle;
  status.count_tap_ok  <= status_align.count_tap_ok;
  status.count_again_s <= status_align.count_again_s;
  status.count_again_p <= status_align.count_again_p;
  status.count_aloss_s <= status_align.count_aloss_s;
  status.count_aloss_p <= status_align.count_aloss_p;
  status.ctrl_char     <= status_align.ctrl_char;

  -- clock and reset generation

  U_CLK: component hdmi_rx_selectio_clk
    generic map (
      fclk         => fclk
    )
    port map (
      rst     => rst,
      clk     => clk,
      pclki   => pclki,
      prsto   => prst,
      pclko   => pclk,
      sclko   => sclk,
      status  => status_clk
    );

  sclkb <= not sclk;

  -- alignment

  U_ALIGN: component hdmi_rx_selectio_align
    port map (
      rst          => rst,
      prst         => prst,
      pclk         => pclk,
      iserdes_q    => iserdes_q,
      iserdes_slip => iserdes_slip,
      idelay_tap   => idelay_tap,
      idelay_ld    => idelay_ld,
      tmds         => po,
      status       => status_align
    );

  -- SelectIO input primitives

  GEN_CH: for i in 0 to 2 generate

    U_IDELAY: component idelaye2
      generic map (
        delay_src             => "IDATAIN",
        idelay_type           => "VAR_LOAD",
        pipe_sel              => "FALSE",
        idelay_value          => 0,
        signal_pattern        => "DATA",
        refclk_frequency      => 200.0,
        high_performance_mode => "TRUE",
        cinvctrl_sel          => "FALSE"
      )
      port map (
        regrst      => '0',
        cinvctrl    => '0',
        c           => pclk,
        ce          => '0',
        inc         => '0',
        ld          => idelay_ld(i),
        ldpipeen    => '0',
        cntvaluein  => idelay_tap,
        cntvalueout => open,
        idatain     => si(i),
        datain      => '0',
        dataout     => iserdes_ddly(i)
      );

    U_ISERDESE2_M: component iserdese2
      generic map (
        serdes_mode       => "MASTER",
        interface_type    => "NETWORKING",
        iobdelay          => "IFD",
        data_width        => 10,
        data_rate         => "DDR",
        ofb_used          => "FALSE",
        dyn_clkdiv_inv_en => "FALSE",
        dyn_clk_inv_en    => "FALSE",
        num_ce            => 2,
        init_q1           => '0',
        init_q2           => '0',
        init_q3           => '0',
        init_q4           => '0',
        srval_q1          => '0',
        srval_q2          => '0',
        srval_q3          => '0',
        srval_q4          => '0'
      )
      port map (
        rst               => prst,
        dynclksel         => '0',
        clk               => sclk,
        clkb              => sclkb,
        ce1               => '1',
        ce2               => '1',
        dynclkdivsel      => '0',
        clkdiv            => pclk,
        clkdivp           => '0',
        oclk              => '0',
        oclkb             => '1',
        d                 => '0',
        ddly              => iserdes_ddly(i),
        ofb               => '0',
        bitslip           => iserdes_slip(i),
        q1                => iserdes_q(i)(9),
        q2                => iserdes_q(i)(8),
        q3                => iserdes_q(i)(7),
        q4                => iserdes_q(i)(6),
        q5                => iserdes_q(i)(5),
        q6                => iserdes_q(i)(4),
        q7                => iserdes_q(i)(3),
        q8                => iserdes_q(i)(2),
        o                 => open,
        shiftin1          => '0',
        shiftin2          => '0',
        shiftout1         => iserdes_shift1(i),
        shiftout2         => iserdes_shift2(i)
      );

    U_ISERDESE2_S: component iserdese2
      generic map (
        serdes_mode       => "SLAVE",
        interface_type    => "NETWORKING",
        iobdelay          => "IFD",
        data_width        => 10,
        data_rate         => "DDR",
        ofb_used          => "FALSE",
        dyn_clkdiv_inv_en => "FALSE",
        dyn_clk_inv_en    => "FALSE",
        num_ce            => 2,
        init_q1           => '0',
        init_q2           => '0',
        init_q3           => '0',
        init_q4           => '0',
        srval_q1          => '0',
        srval_q2          => '0',
        srval_q3          => '0',
        srval_q4          => '0'
      )
      port map (
        rst               => prst,
        dynclksel         => '0',
        clk               => sclk,
        clkb              => sclkb,
        ce1               => '1',
        ce2               => '1',
        dynclkdivsel      => '0',
        clkdiv            => pclk,
        clkdivp           => '0',
        oclk              => '0',
        oclkb             => '1',
        d                 => '0',
        ddly              => '0',
        ofb               => '0',
        bitslip           => iserdes_slip(i),
        q1                => open,
        q2                => open,
        q3                => iserdes_q(i)(1),
        q4                => iserdes_q(i)(0),
        q5                => open,
        q6                => open,
        q7                => open,
        q8                => open,
        o                 => open,
        shiftin1          => iserdes_shift1(i),
        shiftin2          => iserdes_shift2(i),
        shiftout1         => open,
        shiftout2         => open
      );

  end generate GEN_CH;

  ----------------------------------------------------------------------

end architecture synth;

