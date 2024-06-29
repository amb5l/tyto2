--------------------------------------------------------------------------------
-- mb_mcs_muart_digilent_nexys_video.vhd                                      --
-- Board specific variant of the mb_mcs_muart design.                         --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

use work.tyto_types_pkg.all;
use work.mmcm_v2_pkg.all;
use work.sync_reg_u_pkg.all;
use work.mb_mcs_wrapper_pkg.all;
use work.muart_fifo_pkg.all;
use work.muart_tx_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity mb_mcs_muart_digilent_nexys_video is
  port (

    -- clocks
    clki_100m      : in    std_logic;
--  gtp_clk_p      : in    std_logic;
--  gtp_clk_n      : in    std_logic;
--  fmc_mgt_clk_p  : in    std_logic;
--  fmc_mgt_clk_n  : in    std_logic;

    -- LEDs, buttons and switches
    led            : out   std_logic_vector(7 downto 0);
--  btn_c          : in    std_logic;
--  btn_d          : in    std_logic;
--  btn_l          : in    std_logic;
--  btn_r          : in    std_logic;
--  btn_u          : in    std_logic;
    btn_rst_n      : in    std_logic;
--  sw             : in    std_logic_vector(7 downto 0);

    -- OLED
    oled_res_n     : out   std_logic;
    oled_d_c       : out   std_logic;
    oled_sclk      : out   std_logic;
    oled_sdin      : out   std_logic;
--  oled_vbat_dis  : out   std_logic;
--  oled_vdd_dis   : out   std_logic;

--  HDMI RX
--  hdmi_rx_clk_p  : in    std_logic;
--  hdmi_rx_clk_n  : in    std_logic;
--  hdmi_rx_d_p    : in    std_logic_vector(0 to 2);
--  hdmi_rx_d_n    : in    std_logic_vector(0 to 2);
--  hdmi_rx_scl    : in    std_logic;
--  hdmi_rx_sda    : inout std_logic;
--  hdmi_rx_cec    : in    std_logic;
--  hdmi_rx_hpd    : out   std_logic;
    hdmi_rx_txen   : out   std_logic;

    -- HDMI TX
    hdmi_tx_clk_p  : out   std_logic;
    hdmi_tx_clk_n  : out   std_logic;
    hdmi_tx_d_p    : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n    : out   std_logic_vector(0 to 2);
--  hdmi_tx_scl    : out   std_logic;
--  hdmi_tx_sda    : inout std_logic;
--  hdmi_tx_cec    : out   std_logic;
--  hdmi_tx_hpd    : in    std_logic;

    -- DisplayPort
--  dp_tx_p        : out   std_logic_vector(0 to 1);
--  dp_tx_n        : out   std_logic_vector(0 to 1);
--  dp_tx_aux_p    : inout std_logic;
--  dp_tx_aux_n    : inout std_logic;
--  dp_tx_aux2_p   : inout std_logic;
--  dp_tx_aux2_n   : inout std_logic;
--  dp_tx_hpd      : in    std_logic;

    -- audio codec
    ac_mclk        : out   std_logic;
--  ac_lrclk       : out   std_logic;
--  ac_bclk        : out   std_logic;
    ac_dac_sdata   : out   std_logic;
--  ac_adc_sdata   : in    std_logic;

    -- PMODs
--  ja             : inout std_logic_vector(7 downto 0);
--  jb             : inout std_logic_vector(7 downto 0);
--  jc             : inout std_logic_vector(7 downto 0);
--  xa_p           : inout std_logic_vector(3 downto 0);
--  xa_n           : inout std_logic_vector(3 downto 0);

    -- UART
    uart_rx_out    : out   std_logic;
    uart_tx_in     : in    std_logic;

    -- ethernet
    eth_rst_n      : out   std_logic;
    eth_txck       : out   std_logic;
    eth_txctl      : out   std_logic;
    eth_txd        : out   std_logic_vector(3 downto 0);
--  eth_rxck       : in    std_logic;
--  eth_rxctl      : in    std_logic;
--  eth_rxd        : in    std_logic_vector(3 downto 0);
    eth_mdc        : out   std_logic;
--  eth_mdio       : inout std_logic;
--  eth_int_n      : in    std_logic;
--  eth_pme_n      : in    std_logic;

    -- fan
--  fan_pwm        : out   std_logic;

    -- FTDI
--  ftdi_clko      : in    std_logic;
--  ftdi_rxf_n     : in    std_logic;
--  ftdi_txe_n     : in    std_logic;
    ftdi_rd_n      : out   std_logic;
    ftdi_wr_n      : out   std_logic;
    ftdi_siwu_n    : out   std_logic;
    ftdi_oe_n      : out   std_logic;
--  ftdi_d         : inout std_logic_vector(7 downto 0);
--  ftdi_spien     : out   std_logic;

    -- PS/2
--  ps2_clk        : inout std_logic;
--  ps2_data       : inout std_logic;

    -- QSPI
    qspi_cs_n      : out   std_logic;
--  qspi_dq        : inout std_logic_vector(3 downto 0);

    -- SD
--  sd_reset       : out   std_logic;
--  sd_cclk        : out   std_logic;
--  sd_cmd         : out   std_logic;
--  sd_d           : inout std_logic_vector(3 downto 0);
--  sd_cd          : in    std_logic;

    -- I2C
--  i2c_scl        : inout std_logic;
--  i2c_sda        : inout std_logic;

    -- VADJ
--  set_vadj       : out   std_logic_vector(1 downto 0);
--  vadj_en        : out   std_logic;

    -- FMC
--  fmc_clk0_m2c_p : in    std_logic;
--  fmc_clk0_m2c_n : in    std_logic;
--  fmc_clk1_m2c_p : in    std_logic;
--  fmc_clk1_m2c_n : in    std_logic;
--  fmc_la_p       : inout std_logic_vector(33 downto 0);
--  fmc_la_n       : inout std_logic_vector(33 downto 0);

    -- DDR3
    ddr3_reset_n   : out   std_logic
--  ddr3_ck_p      : out   std_logic_vector(0 downto 0);
--  ddr3_ck_n      : out   std_logic_vector(0 downto 0);
--  ddr3_cke       : out   std_logic_vector(0 downto 0);
--  ddr3_ras_n     : out   std_logic;
--  ddr3_cas_n     : out   std_logic;
--  ddr3_we_n      : out   std_logic;
--  ddr3_odt       : out   std_logic_vector(0 downto 0);
--  ddr3_addr      : out   std_logic_vector(14 downto 0);
--  ddr3_ba        : out   std_logic_vector(2 downto 0);
--  ddr3_dm        : out   std_logic_vector(1 downto 0);
--  ddr3_dq        : inout std_logic_vector(15 downto 0);
--  ddr3_dqs_p     : inout std_logic_vector(1 downto 0);
--  ddr3_dqs_n     : inout std_logic_vector(1 downto 0)

  );
end entity mb_mcs_muart_digilent_nexys_video;

architecture rtl of mb_mcs_muart_digilent_nexys_video is

  constant fCLK : integer := 100000000; -- 100 MHz
  constant BAUD : integer := 115200;
  constant DIV  : integer := fCLK / BAUD;

  signal rst_a         : std_ulogic;
  signal clk_100m      : std_logic;
  signal rst_100m      : std_ulogic; -- clk_100m synchronous reset
  signal gpi           : sulv_vector(1 to 4)(31 downto 0);
  signal gpo           : sulv_vector(1 to 4)(31 downto 0);
  signal io_mosi       : mb_mcs_io_mosi_t;
  signal io_miso       : mb_mcs_io_miso_t;
  signal fifo_tx_ready : std_ulogic;
  signal fifo_tx_valid : std_ulogic;
  signal fifo_tx_d     : std_ulogic_vector(7 downto 0);
  signal uart_tx_ready : std_ulogic;
  signal uart_tx_valid : std_ulogic;
  signal uart_tx_d     : std_ulogic_vector(7 downto 0);

  function ternary(cond : boolean; t : integer; f : integer) return integer is
  begin
    if cond then return t; else return f; end if;
  end function;

begin

  --------------------------------------------------------------------------------
  -- clock/reset

  --------------------------------------------------------------------------------
  -- MMCM generates 200MHz, 125MHz and 100MHz from 100MHz reference

  U_MMCM: component mmcm_v2
    generic map (
      mul    => 10.0,
      div    => 1,
      odiv0  => 10.0
    )
    port map (
      rsti  => not btn_rst_n,
      clki  => clki_100m,
      rsto  => rst_a,
      clk0  => clk_100m,
      clk1  => open,
      clk2  => open,
      clk3  => open,
      clk4  => open,
      clk5  => open,
      clk6  => open
    );

  U_SYNC_RST_100M: component sync_reg_u
    generic map (
      stages    => 3,
      rst_state => '1'
    )
    port map (
      rst  => '0',
      clk  => clk_100m,
      i(0) => rst_a,
      o(0) => rst_100m
    );

  --------------------------------------------------------------------------------
  -- MicroBlaze V MCS (CPU core)

  U_MCU: component mb_mcs_wrapper
    port map (
      rst      => rst_100m,
      clk      => clk_100m,
      uart_tx  => open,
      uart_rx  => '1',
      gpi      => gpi,
      gpo      => gpo,
      io_mosi  => io_mosi,
      io_miso  => io_miso
    );


  --------------------------------------------------------------------------------
  -- glue

  led       <= gpo(1)(7 downto 0);
  gpi(1)(0) <= fifo_tx_ready;

  fifo_tx_valid <= io_mosi.wstb and io_mosi.be(0);
  fifo_tx_d     <= io_mosi.wdata(7 downto 0);
  io_miso.rdata <= (others => '0');
  io_miso.rdy   <= '1';

  --------------------------------------------------------------------------------
  -- FIFO and UART

  U_FIFO: component muart_fifo
    generic map (
      DEPTH_LOG2 => 11
    )
    port map (
      rst     => rst_100m,
      clk     => clk_100m,
      i_ready => fifo_tx_ready,
      i_valid => fifo_tx_valid,
      i_d     => fifo_tx_d,
      o_ready => uart_tx_ready,
      o_valid => uart_tx_valid,
      o_d     => uart_tx_d
    );

  U_UART_TX: component muart_tx
    generic map (
      DIV => DIV
    )
    port map (
      rst   => rst_100m,
      clk   => clk_100m,
      d     => uart_tx_d,
      valid => uart_tx_valid,
      ready => uart_tx_ready,
      q     => uart_rx_out
    );

  --------------------------------------------------------------------------------

  -- unused I/Os

  hdmi_rx_txen   <= '0';
  U_HDMI_TX_CLK: component obufds port map ( i => '0', o => hdmi_tx_clk_p,  ob => hdmi_tx_clk_n  );
  U_HDMI_TX_D0:  component obufds port map ( i => '0', o => hdmi_tx_d_p(0), ob => hdmi_tx_d_n(0) );
  U_HDMI_TX_D1:  component obufds port map ( i => '0', o => hdmi_tx_d_p(1), ob => hdmi_tx_d_n(1) );
  U_HDMI_TX_D2:  component obufds port map ( i => '0', o => hdmi_tx_d_p(2), ob => hdmi_tx_d_n(2) );
  oled_res_n     <= '0';
  oled_d_c       <= '0';
  oled_sclk      <= '0';
  oled_sdin      <= '0';
  ac_mclk        <= '0';
  ac_dac_sdata   <= '0';
  eth_rst_n      <= '0';
  eth_txck       <= '0';
  eth_txctl      <= '0';
  eth_txd        <= (others => '0');
  eth_mdc        <= '0';
  ftdi_rd_n      <= '1';
  ftdi_wr_n      <= '1';
  ftdi_siwu_n    <= '1';
  ftdi_oe_n      <= '1';
  qspi_cs_n      <= '1';
  ddr3_reset_n   <= '0';

  --------------------------------------------------------------------------------

end architecture rtl;
