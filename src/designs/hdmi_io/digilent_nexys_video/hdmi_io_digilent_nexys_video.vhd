--------------------------------------------------------------------------------
-- hdmi_io_digilent_nexys_video.vhd                                           --
-- Board specific top level wrapper for the hdmi_io design.                   --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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
  use work.mmcm_pkg.all;
  use work.hdmi_io_pkg.all;

entity hdmi_io_digilent_nexys_video is
  port (

    -- clocks
    clki_100m     : in    std_logic;
    -- gtp_clk_p       : in    std_logic;
    -- gtp_clk_n       : in    std_logic;
    -- fmc_mgt_clk_p   : in    std_logic;
    -- fmc_mgt_clk_n   : in    std_logic;

    -- LEDs, buttons and switches
    led           : out   std_logic_vector(7 downto 0);
    -- btn_c           : in    std_logic;
    -- btn_d           : in    std_logic;
    -- btn_l           : in    std_logic;
    -- btn_r           : in    std_logic;
    -- btn_u           : in    std_logic;
    btn_rst_n     : in    std_logic;
    -- sw              : in    std_logic_vector(7 downto 0);

    -- OLED
    oled_res_n    : out   std_logic;
    oled_d_c      : out   std_logic;
    oled_sclk     : out   std_logic;
    oled_sdin     : out   std_logic;
    -- oled_vbat_dis   : out   std_logic;
    -- oled_vdd_dis    : out   std_logic;

    -- HDMI RX
    hdmi_rx_clk_p : in    std_logic;
    hdmi_rx_clk_n : in    std_logic;
    hdmi_rx_d_p   : in    std_logic_vector(0 to 2);
    hdmi_rx_d_n   : in    std_logic_vector(0 to 2);
    -- hdmi_rx_scl     : in    std_logic;
    -- hdmi_rx_sda     : inout std_logic;
    -- hdmi_rx_cec     : in    std_logic;
    -- hdmi_rx_hpd     : out   std_logic;
    -- hdmi_rx_txen    : out   std_logic;

    -- HDMI TX
    hdmi_tx_clk_p : out   std_logic;
    hdmi_tx_clk_n : out   std_logic;
    hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
    -- hdmi_tx_scl     : out   std_logic;
    -- hdmi_tx_sda     : inout std_logic;
    -- hdmi_tx_cec     : out   std_logic;
    -- hdmi_tx_hpd     : in    std_logic;

    -- DisplayPort
    -- dp_tx_p         : out   std_logic_vector(0 to 1);
    -- dp_tx_n         : out   std_logic_vector(0 to 1);
    -- dp_tx_aux_p     : inout std_logic;
    -- dp_tx_aux_n     : inout std_logic;
    -- dp_tx_aux2_p    : inout std_logic;
    -- dp_tx_aux2_n    : inout std_logic;
    -- dp_tx_hpd       : in    std_logic;

    -- audio codec
    ac_mclk       : out   std_logic;
    -- ac_lrclk        : out   std_logic;
    -- ac_bclk         : out   std_logic;
    ac_dac_sdata  : out   std_logic;
    -- ac_adc_sdata    : in    std_logic;

    -- PMODs
    -- ja              : inout std_logic_vector(7 downto 0);
    -- jb              : inout std_logic_vector(7 downto 0);
    -- jc              : inout std_logic_vector(7 downto 0);
    -- xa_p            : inout std_logic_vector(3 downto 0);
    -- xa_n            : inout std_logic_vector(3 downto 0);

    -- UART
    uart_rx_out   : out   std_logic;
    -- uart_tx_in      : in    std_logic;

    -- ethernet
    eth_rst_n     : out   std_logic;
    -- eth_txck        : out   std_logic;
    -- eth_txctl       : out   std_logic;
    -- eth_txd         : out   std_logic_vector(3 downto 0);
    -- eth_rxck        : in    std_logic;
    -- eth_rxctl       : in    std_logic;
    -- eth_rxd         : in    std_logic_vector(3 downto 0);
    -- eth_mdc         : out   std_logic;
    -- eth_mdio        : inout std_logic;
    -- eth_int_n       : in    std_logic;
    -- eth_pme_n       : in    std_logic;

    -- fan
    -- fan_pwm         : out   std_logic;

    -- FTDI
    -- ftdi_clko       : in    std_logic;
    -- ftdi_rxf_n      : in    std_logic;
    -- ftdi_txe_n      : in    std_logic;
    ftdi_rd_n     : out   std_logic;
    ftdi_wr_n     : out   std_logic;
    ftdi_siwu_n   : out   std_logic;
    ftdi_oe_n     : out   std_logic;
    -- ftdi_d          : inout std_logic_vector(7 downto 0);
    -- ftdi_spien      : out   std_logic;

    -- PS/2
    -- ps2_clk         : inout std_logic;
    -- ps2_data        : inout std_logic;

    -- QSPI
    qspi_cs_n     : out   std_logic;
    -- qspi_dq         : inout std_logic_vector(3 downto 0);

    -- SD
    -- sd_reset        : out   std_logic;
    -- sd_cclk         : out   std_logic;
    -- sd_cmd          : out   std_logic;
    -- sd_d            : inout std_logic_vector(3 downto 0);
    -- sd_cd           : in    std_logic;

    -- I2C
    -- i2c_scl         : inout std_logic;
    -- i2c_sda         : inout std_logic;

    -- VADJ
    -- set_vadj        : out   std_logic_vector(1 downto 0);
    -- vadj_en         : out   std_logic;

    -- FMC
    -- fmc_clk0_m2c_p  : in    std_logic;
    -- fmc_clk0_m2c_n  : in    std_logic;
    -- fmc_clk1_m2c_p  : in    std_logic;
    -- fmc_clk1_m2c_n  : in    std_logic;
    -- fmc_la_p        : inout std_logic_vector(33 downto 0);
    -- fmc_la_n        : inout std_logic_vector(33 downto 0);

    -- DDR3
    ddr3_reset_n  : out   std_logic
  -- ddr3_ck_p       : out   std_logic_vector(0 downto 0);
  -- ddr3_ck_n       : out   std_logic_vector(0 downto 0);
  -- ddr3_cke        : out   std_logic_vector(0 downto 0);
  -- ddr3_ras_n      : out   std_logic;
  -- ddr3_cas_n      : out   std_logic;
  -- ddr3_we_n       : out   std_logic;
  -- ddr3_odt        : out   std_logic_vector(0 downto 0);
  -- ddr3_addr       : out   std_logic_vector(14 downto 0);
  -- ddr3_ba         : out   std_logic_vector(2 downto 0);
  -- ddr3_dm         : out   std_logic_vector(1 downto 0);
  -- ddr3_dq         : inout std_logic_vector(15 downto 0);
  -- ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
  -- ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

  );
end entity hdmi_io_digilent_nexys_video;

architecture synth of hdmi_io_digilent_nexys_video is

  signal rst_a          : std_logic;
  signal clk_100m       : std_logic;
  signal clk_200m       : std_logic;
  signal clk_spare      : std_logic_vector(2 to 6);
  signal rst_200m_s     : std_logic_vector(0 to 1);
  signal rst_200m       : std_logic;
  signal idelayctrl_rdy : std_logic;
  signal rst_100m_s     : std_logic_vector(0 to 1);
  signal rst_100m       : std_logic;

  signal hdmi_rx_clku   : std_logic;
  signal hdmi_rx_clk    : std_logic;
  signal hdmi_rx_d      : std_logic_vector(0 to 2);

  signal hdmi_tx_clk    : std_logic;
  signal hdmi_tx_d      : std_logic_vector(0 to 2);

begin

  led(4) <= not rst_100m;
  led(5) <= idelayctrl_rdy
  led(6) <= not rst_200m;
  led(7) <= '1';

  --------------------------------------------------------------------------------
  -- clock and reset generation

  U_MMCM: component mmcm
    generic map (
      mul         => 10.0,
      div         => 1,
      num_outputs => 2,
      odiv0       => 10.0,
      odiv        => (5, 10, 10, 10, 10, 10)
    )
    port map (
      rsti        => not btn_rst_n,
      clki        => clki_100m,
      rsto        => rst_a,
      clko(0)     => clk_100m,
      clko(1)     => clk_200m,
      clko(2 to 6) => clk_spare(2 to 6)
    );

  process(rst_a,clk_200m)
  begin
    if rst_a = '1' then
      rst_200m_s(0 to 1) <= (others => '1');
      rst_200m <= '1';
    elsif rising_edge(clk_200m) then
      rst_200m_s(0 to 1) <= rst_a & rst_100m_s(0);
      rst_200m <= rst_200m_s(1);
    end if;
  end process;

  process(rst_a,clk_100m)
  begin
    if rst_a = '1' then
      rst_100m_s(0 to 1) <= (others => '1');
      rst_100m <= '1';
    elsif rising_edge(clk_100m) then
      rst_100m_s(0 to 1) <= (rst_a or not idelayctrl_rdy) & rst_100m_s(0);
      rst_100m <= rst_100m_s(1);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- main design

  MAIN: component hdmi_io
    generic map (
      fclk        => 100.0
    )
    port map (
      rst         => rst_100m,
      clk         => clk_100m,
      hdmi_rx_clk => hdmi_rx_clk,
      hdmi_rx_d   => hdmi_rx_d,
      hdmi_tx_clk => hdmi_tx_clk,
      hdmi_tx_d   => hdmi_tx_d,
      status      => led(3 downto 0)
    );

  --------------------------------------------------------------------------------
  -- I/O primitives

  -- required to use I/O delay primitives
  U_IDELAYCTRL: idelayctrl
    port map (
      rst    => rst_200m, -- assumption!!! is asserted for >60ns
      refclk => clk_200m,
      rdy    => idelayctrl_rdy
    );

  -- HDMI input and output buffers

  U_IBUFDS_CLK: component ibufds
    port map (
      i  => hdmi_rx_clk_p,
      ib => hdmi_rx_clk_n,
      o  => hdmi_rx_clku
    );

  U_IBUFG: component ibufg
    port map (
      i => hdmi_rx_clku,
      o => hdmi_rx_clk
    );

  U_OBUFDS_CLK: component obufds
    port map (
      i  => hdmi_tx_clk,
      o  => hdmi_tx_clk_p,
      ob => hdmi_tx_clk_n
    );

  GEN_CH: for i in 0 to 2 generate

    U_IBUFDS: component ibufds
      port map (
        i  => hdmi_rx_d_p,
        ib => hdmi_rx_d_n,
        o  => hdmi_rx_d
      );

    U_OBUFDS: component obufds
      port map (
        i  => hdmi_tx_d,
        o  => hdmi_tx_d_p,
        ob => hdmi_tx_d_n
      );

  end generate GEN_CH;

  --------------------------------------------------------------------------------
  -- unused I/Os

  oled_res_n   <= '0';
  oled_d_c     <= '0';
  oled_sclk    <= '0';
  oled_sdin    <= '0';
  ac_mclk      <= '0';
  ac_dac_sdata <= '0';
  uart_rx_out  <= '1';
  eth_rst_n    <= '0';
  ftdi_rd_n    <= '1';
  ftdi_wr_n    <= '1';
  ftdi_siwu_n  <= '1';
  ftdi_oe_n    <= '1';
  qspi_cs_n    <= '1';
  ddr3_reset_n <= '0';

  --------------------------------------------------------------------------------

end architecture synth;
