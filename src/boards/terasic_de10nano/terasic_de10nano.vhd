--------------------------------------------------------------------------------
-- terasic_de10nano.vhd                                                       --
-- Top level entity for Terasic DE10-Nano board.                              --
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

entity terasic_de10nano is
    port (

      fpga_clk1_50    : in    std_logic;
      fpga_clk2_50    : in    std_logic;
      fpga_clk3_50    : in    std_logic;

      sw              : in    std_logic_vector(3:0);
      key             : in    std_logic_vector(1:0);
      led             : out   std_logic_vector(7:0);

      hdmi_tx_clk     : out   std_logic;
      hdmi_tx_d       : out   std_logic_vector(23:0);
      hdmi_tx_vs      : out   std_logic;
      hdmi_tx_hs      : out   std_logic;
      hdmi_tx_de      : out   std_logic;
      hdmi_tx_int     : in    std_logic;

      hdmi_sclk       : inout std_logic;
      hdmi_mclk       : inout std_logic;
      hdmi_lrclk      : inout std_logic;
      hdmi_i2s        : inout std_logic;

      hdmi_i2c_scl    : inout std_logic;
      hdmi_i2c_sda    : inout std_logic;

      adc_convst      : out   std_logic;
      adc_sck         : out   std_logic;
      adc_sdi         : out   std_logic;
      adc_sdo         : in    std_logic;

      arduino_reset_n : inout std_logic;
      arduino_io      : inout std_logic_vector(15:0);
      gpio_0          : inout std_logic_vector(35:0);
      gpio_1          : inout std_logic_vector(35:0)

      -- hps_conv_usb_n   : inout std_logic;
      -- hps_ddr3_addr    : out   std_logic_vector(14:0);
      -- hps_ddr3_ba      : out   std_logic_vector(2:0);
      -- hps_ddr3_cas_n   : out   std_logic;
      -- hps_ddr3_cke     : out   std_logic;
      -- hps_ddr3_ck_n    : out   std_logic;
      -- hps_ddr3_ck_p    : out   std_logic;
      -- hps_ddr3_cs_n    : out   std_logic;
      -- hps_ddr3_dm      : out   std_logic_vector(3:0);
      -- hps_ddr3_dq      : inout std_logic_vector(31:0);
      -- hps_ddr3_dqs_n   : inout std_logic_vector(3:0);
      -- hps_ddr3_dqs_p   : inout std_logic_vector(3:0);
      -- hps_ddr3_odt     : out   std_logic;
      -- hps_ddr3_ras_n   : out   std_logic;
      -- hps_ddr3_reset_n : out   std_logic;
      -- hps_ddr3_rzq     : in    std_logic;
      -- hps_ddr3_we_n    : out   std_logic;
      -- hps_enet_gtx_clk : out   std_logic;
      -- hps_enet_int_n   : inout std_logic;
      -- hps_enet_mdc     : out   std_logic;
      -- hps_enet_mdio    : inout std_logic;
      -- hps_enet_rx_clk  : in    std_logic;
      -- hps_enet_rx_data : in    std_logic_vector(3:0);
      -- hps_enet_rx_dv   : in    std_logic;
      -- hps_enet_tx_data : out   std_logic_vector(3:0);
      -- hps_enet_tx_en   : out   std_logic;
      -- hps_gsensor_int  : inout std_logic;
      -- hps_i2c0_sclk    : inout std_logic;
      -- hps_i2c0_sdat    : inout std_logic;
      -- hps_i2c1_sclk    : inout std_logic;
      -- hps_i2c1_sdat    : inout std_logic;
      -- hps_key          : inout std_logic;
      -- hps_led          : inout std_logic;
      -- hps_ltc_gpio     : inout std_logic;
      -- hps_sd_clk       : out   std_logic;
      -- hps_sd_cmd       : inout std_logic;
      -- hps_sd_data      : inout std_logic_vector(3:0);
      -- hps_spim_clk     : out   std_logic;
      -- hps_spim_miso    : in    std_logic;
      -- hps_spim_mosi    : out   std_logic;
      -- hps_spim_ss      : inout std_logic;
      -- hps_uart_rx      : in    std_logic;
      -- hps_uart_tx      : out   std_logic;
      -- hps_usb_clkout   : in    std_logic;
      -- hps_usb_data     : inout std_logic_vector(7:0);
      -- hps_usb_dir      : in    std_logic;
      -- hps_usb_nxt      : in    std_logic;
      -- hps_usb_stp      : out   std_logic;

    )
end entity terasic_de10nano;

architecture synth of terasic_de10nano is
begin

    -- unused outputs
      led         <= (others => '0');
      hdmi_tx_clk <='0';
      hdmi_tx_d   <= (others => '0');
      hdmi_tx_vs  <='0';
      hdmi_tx_hs  <='0';
      hdmi_tx_de  <='0';
      adc_convst  <='0';
      adc_sck     <='0';
      adc_sdi     <='0';

end architecture synth;
