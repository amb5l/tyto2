--------------------------------------------------------------------------------
-- qmtech_wukong.vhd                                                          --
-- Top level entity for QMTech Wukong board.                                  --
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

entity qmtech_wukong is
  port (

    -- clocks
    clki_50m    : in    std_logic;

    -- LEDs and keys
    led_n       : out   std_logic_vector(1 downto 0);
    key_n       : in    std_logic_vector(1 downto 0);

    -- serial (UART)
    ser_tx      : out   std_logic;
    ser_rx      : in    std_logic;

    -- HDMI output
    hdmi_clk_p  : out   std_logic;
    hdmi_clk_n  : out   std_logic;
    hdmi_d_p    : out   std_logic_vector(0 to 2);
    hdmi_d_n    : out   std_logic_vector(0 to 2);
    hdmi_scl    : out   std_logic;
    hdmi_sda    : inout std_logic;
    hdmi_cec    : out   std_logic;
    hdmi_hpd    : in    std_logic;

    -- ethernet
    eth_rst_n   : out   std_logic;
    eth_gtx_clk : out   std_logic;
    eth_txclk   : out   std_logic;
    eth_txen    : out   std_logic;
    eth_txer    : out   std_logic;
    eth_txd     : out   std_logic_vector(7 downto 0);
    eth_rxclk   : in    std_logic;
    eth_rxdv    : in    std_logic;
    eth_rxer    : in    std_logic;
    eth_rxd     : in    std_logic_vector(7 downto 0);
    eth_crs     : in    std_logic;
    eth_col     : in    std_logic;
    eth_mdc     : out   std_logic;
    eth_mdio    : inout std_logic;

    -- DDR3
    ddr3_rst_n  : out   std_logic;
    ddr3_ck_p   : out   std_logic_vector(0 downto 0);
    ddr3_ck_n   : out   std_logic_vector(0 downto 0);
    ddr3_cke    : out   std_logic_vector(0 downto 0);
    ddr3_ras_n  : out   std_logic;
    ddr3_cas_n  : out   std_logic;
    ddr3_we_n   : out   std_logic;
    ddr3_odt    : out   std_logic_vector(0 downto 0);
    ddr3_addr   : out   std_logic_vector(13 downto 0);
    ddr3_ba     : out   std_logic_vector(2 downto 0);
    ddr3_dm     : out   std_logic_vector(1 downto 0);
    ddr3_dq     : inout std_logic_vector(15 downto 0);
    ddr3_dqs_p  : inout std_logic_vector(1 downto 0);
    ddr3_dqs_n  : inout std_logic_vector(1 downto 0);

    -- I/O connectors
    j10         : inout std_logic_vector(7 downto 0);
    j11         : inout std_logic_vector(7 downto 0);
    jp2         : inout std_logic_vector(15 downto 0);
    j12         : inout std_logic_vector(33 downto 0);

    -- MGTs
    mgt_clk_p   : in    std_logic_vector(0 to 1);
    mgt_clk_n   : in    std_logic_vector(0 to 1);
    mgt_tx_p    : out   std_logic_vector(3 downto 0);
    mgt_tx_n    : out   std_logic_vector(3 downto 0);
    mgt_rx_p    : out   std_logic_vector(3 downto 0);
    mgt_rx_n    : out   std_logic_vector(3 downto 0)

  );
end entity qmtech_wukong;

architecture synth of qmtech_wukong is

begin

  -- safe states
  ser_tx       <= '1';
  hdmi_scl     <= 'Z';
  hdmi_sda     <= 'Z';
  eth_rst_n    <= '0';
  ddr3_reset_n <= '0';

end architecture synth;
