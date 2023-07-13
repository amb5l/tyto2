--------------------------------------------------------------------------------
-- hdmi_io_digilent_zybo_z7_20.vhd                                            --
-- Board specific top level wrapper for the hdmi_io design.                   --
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

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;
  use work.mmcm_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.hdmi_tx_selectio_pkg.all;

entity hdmi_io_digilent_zybo_z7_20 is
  port (

    -- clock
    clki_125m           : in    std_logic;

    -- LEDs, buttons and switches
    -- sw                  : in    std_logic_vector(3 downto 0);
    btn                 : in    std_logic_vector(3 downto 0);
    led                 : out   std_logic_vector(3 downto 0);
    led_r               : out   std_logic_vector(6 downto 5);
    led_g               : out   std_logic_vector(6 downto 5);
    led_b               : out   std_logic_vector(6 downto 5);

    -- HDMI RX
    -- hdmi_rx_hpd         : out   std_logic;
    -- hdmi_rx_scl         : inout std_logic;
    -- hdmi_rx_sda         : inout std_logic;
    hdmi_rx_clk_p       : in    std_logic;
    hdmi_rx_clk_n       : in    std_logic;
    hdmi_rx_d_p         : in    std_logic_vector(0 to 2);
    hdmi_rx_d_n         : in    std_logic_vector(0 to 2);
    -- hdmi_rx_cec         : in    std_logic;

    -- HDMI TX
    -- hdmi_tx_hpd         : in    std_logic;
    -- hdmi_tx_scl         : inout std_logic;
    -- hdmi_tx_sda         : inout std_logic;
    hdmi_tx_clk_p       : out   std_logic;
    hdmi_tx_clk_n       : out   std_logic;
    hdmi_tx_d_p         : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n         : out   std_logic_vector(0 to 2);
    hdmi_tx_cec         : out   std_logic;

    -- PMODs
    -- ja                  : inout std_logic_vector(7 downto 0);
    -- jb                  : inout std_logic_vector(7 downto 0);
    -- jc                  : inout std_logic_vector(7 downto 0);
    -- jd                  : inout std_logic_vector(7 downto 0);
    -- je                  : inout std_logic_vector(7 downto 0);

    -- Audio codec (SSM2603CPZ, I2C address 0011010)
    -- ac_bclk             : inout std_logic;
    -- ac_mclk             : in    std_logic;
    ac_muten            : out   std_logic;
    ac_pbdat            : out   std_logic;
    -- ac_pblrc            : inout std_logic;
    -- ac_recdat           : in    std_logic;
    -- ac_reclrc           : inout std_logic;
    -- ac_scl              : out   std_logic;
    -- ac_sda              : inout std_logic;

    -- RTL8211E-VL
    -- eth_int_pu_b        : in    std_logic; -- pin 20, INTB
    eth_rst_b           : out   std_logic  -- pin 29, PHYRSTB

    -- Jumper J14
    -- fan_fb_pu           : in    std_logic;

    -- Jumper J2
    -- cam_clk             : in    std_logic;
    -- cam_gpio            : in    std_logic;
    -- cam_scl             : in    std_logic;
    -- cam_sda             : inout std_logic;

    -- ATSHA204A-SSHCZ-T
    -- crypto_sda          : inout std_logic;

    -- USB OTG
    -- otg_oc              : in    std_logic;

    -- MIPI
    -- dphy_clk_lp_p       : in    std_logic;
    -- dphy_clk_lp_n       : in    std_logic;
    -- dphy_data_lp_p      : in    std_logic_vector(1 downto 0);
    -- dphy_data_lp_n      : in    std_logic_vector(1 downto 0);
    -- dphy_hs_clock_clk_p : in    std_logic;
    -- dphy_hs_clock_clk_n : in    std_logic;
    -- dphy_data_hs_p      : in    std_logic_vector(1 downto 0);
    -- dphy_data_hs_n      : in    std_logic_vector(1 downto 0)

  );
end entity hdmi_io_digilent_zybo_z7_20;

architecture synth of hdmi_io_digilent_zybo_z7_20 is

  signal rst_a          : std_logic;                -- reset, asynchronous
  signal clk_100m       : std_logic;                -- 100MHz clock
  signal clk_200m       : std_logic;                -- 200MHz clock
  signal rst_200m_s     : std_logic_vector(0 to 1); -- 200MHz reset synchroniser
  signal rst_200m       : std_logic;                -- 200MHz clock synchronous reset
  signal idelayctrl_rdy : std_logic;                -- IDELAYCTRL ready output
  signal rst_100m_s     : std_logic_vector(0 to 1); -- 100MHz reset synchroniser
  signal rst_100m       : std_logic;                -- 100MHz clock synchronous reset

  signal hdmi_rx_clku : std_logic;                  -- HDMI Rx clock, unbuffered
  signal hdmi_rx_clk  : std_logic;                  -- HDMI Rx clock, buffered/global
  signal hdmi_rx_d    : std_logic_vector(0 to 2);   -- HDMI Rx serial data channels
  signal sclk         : std_logic;                  -- serial/bit clock (from HDMI Rx)
  signal prst         : std_logic;                  -- pixel/character clock synchronous reset
  signal pclk         : std_logic;                  -- pixel/character clock (from HDMI Rx)
  signal tmds         : slv10_vector(0 to 2);       -- parallel TMDS channels (10 bits x 3)
  signal status       : hdmi_rx_selectio_status_t;  -- status from HDMI Rx block
  signal hdmi_tx_clk  : std_logic;                  -- HDMI Tx clock
  signal hdmi_tx_d    : std_logic_vector(0 to 2);   -- HDMI Tx serial data channels

begin

  -- LD5 = 200MHz and 100MHz clock OK
  led_r(5) <= '0';
  led_g(5) <= not rst_a;
  led_b(5) <= '0';

  -- LD6 = HDMI Rx serial alignment OK
  led_r(6) <= status.align_s(0);
  led_g(6) <= status.align_s(1);
  led_b(6) <= status.align_s(2);

  -- LD0 on = HDMI Rx clock lock
  -- LD1 on = HDMI Rx parallel alignment OK
  -- LD2 on = HDMI Rx clock band(0)
  -- LD3 on = HDMI Rx clock band(1)

  led(0) <= status.lock;
  led(1) <= status.align_p;
  led(2) <= status.band(0);
  led(3) <= status.band(1);

  --------------------------------------------------------------------------------
  -- clock and reset generation

  REF_CLOCK: component mmcm
    generic map (
      mul         => 8.0,
      div         => 1,
      num_outputs => 2,
      odiv0       => 10.0,
      odiv        => (5,10,10,10,10,10)
    )
    port map (
      rsti        => btn(0),
      clki        => clki_125m,
      rsto        => rst_a,
      clko(0)     => clk_100m,
      clko(1)     => clk_200m
    );

  process(rst_a,clk_200m)
  begin
    if rst_a = '1' then
      rst_200m_s(0 to 1) <= (others => '1');
      rst_200m           <= '1';
    elsif rising_edge(clk_200m) then
      rst_200m_s(0 to 1) <= rst_a & rst_200m_s(0);
      rst_200m           <= rst_200m_s(1);
    end if;
  end process;

  process(rst_200m,clk_100m)
  begin
    if rst_200m = '1' then
      rst_100m_s(0 to 1) <= (others => '1');
      rst_100m           <= '1';
    elsif rising_edge(clk_100m) then
      rst_100m_s(0 to 1) <= (rst_200m or not idelayctrl_rdy) & rst_100m_s(0);
      rst_100m           <= rst_100m_s(1);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- HDMI I/O

  HDMI_RX: component hdmi_rx_selectio
    generic map (
      FCLK => 100.0
    )
    port map (
      rst    => rst_100m,
      clk    => clk_100m,
      pclki  => hdmi_rx_clk,
      si     => hdmi_rx_d,
      sclko  => sclk,
      prsto  => prst,
      pclko  => pclk,
      po     => tmds,
      status => status
    );

  HDMI_TX: component hdmi_tx_selectio
    port map (
      sclki => sclk,
      prsti => prst,
      pclki => pclk,
      pi    => tmds,
      pclko => hdmi_tx_clk,
      so    => hdmi_tx_d
    );

  --------------------------------------------------------------------------------
  -- I/O primitives

  -- required to use I/O delay primitives
  U_IDELAYCTRL: component idelayctrl
    port map (
      rst    => rst_200m,
      refclk => clk_200m,
      rdy    => idelayctrl_rdy
    );

  -- HDMI input and output differential buffers

  U_IBUFDS: component ibufds
    port map (
      i  => hdmi_rx_clk_p,
      ib => hdmi_rx_clk_n,
      o  => hdmi_rx_clku
    );

  U_BUFG: component bufg
    port map (
      i => hdmi_rx_clku,
      o => hdmi_rx_clk
    );

  U_OBUFDS: component obufds
    port map (
      i  => hdmi_tx_clk,
      o  => hdmi_tx_clk_p,
      ob => hdmi_tx_clk_n
    );

  GEN_CH: for i in 0 to 2 generate

    U_IBUFDS: component ibufds
      port map (
        i  => hdmi_rx_d_p(i),
        ib => hdmi_rx_d_n(i),
        o  => hdmi_rx_d(i)
      );

    U_OBUFDS: component obufds
      port map (
        i  => hdmi_tx_d(i),
        o  => hdmi_tx_d_p(i),
        ob => hdmi_tx_d_n(i)
      );

  end generate GEN_CH;

  -- unused I/Os

  hdmi_tx_cec   <= '0';
  ac_muten      <= '0';
  ac_pbdat      <= '0';
  eth_rst_b     <= '1'; -- beware: asserting this reset halts clki_125m

end architecture synth;
