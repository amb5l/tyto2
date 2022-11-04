--------------------------------------------------------------------------------
-- tb_np6532_poc_256k_altera_c5e_dev.vhd                                      --
-- Simulation testbench for np6532_poc_256k_altera_c5e_dev.vhd.               --
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

entity tb_np6532_poc_256k_altera_c5e_dev is
  generic (
    success_addr : integer
  );
end entity tb_np6532_poc_256k_altera_c5e_dev;

architecture sim of tb_np6532_poc_256k_altera_c5e_dev is

  signal clkin_50_top : std_logic;
  signal user_pb      : std_logic_vector(3 downto 0);
  signal user_led     : std_logic_vector(3 downto 0);

begin

  clkin_50_top <= '1' after 10 ns when clkin_50_top = '0' else
                  '0' after 10 ns when clkin_50_top = '1' else
                  '0';

  TEST: process is
  begin
    user_pb(0) <= '0';
    wait for 20 ns;
    user_pb(0) <= '1';
    wait;
  end process TEST;

  user_pb(3 downto 1) <= (others => '1');

  DUT: entity work.np6532_poc_256k_altera_c5e_dev
    generic map (
      success_addr      => success_addr
    )
    port map (
      clkin_50_top      => clkin_50_top,
      clkin_50_right    => '0',
      clkin_top_125     => '0',
      clkin_bot_125     => '0',
      clkout_sma        => open,
      user_dipsw        => (others => '0'),
      user_pb           => user_pb,
      user_led          => user_led,
      dipsw2_4          => '0',
      uart_rxd          => '0',
      uart_txd          => open,
      uart_rts          => '0',
      uart_cts          => open,
      uart_rxd_led      => open,
      uart_txd_led      => open,
      usb_uart_rstn     => open,
      usb_uart_rxd      => '0',
      usb_uart_txd      => open,
      usb_uart_rts      => '0',
      usb_uart_cts      => open,
      usb_uart_dtr      => '0',
      usb_uart_dcd      => open,
      usb_uart_dsr      => open,
      usb_uart_ri       => open,
      usb_uart_gpio2    => '0',
      usb_uart_suspend  => '0',
      usb_uart_suspendn => '0',
      lcd_csn           => open,
      lcd_d_cn          => open,
      lcd_wen           => open,
      lcd_data          => open,
      eeprom_scl        => open,
      eeprom_sda        => open,
      ddr3_resetn       => open,
      ddr3_clk_p        => open,
      ddr3_clk_n        => open,
      ddr3_cke          => open,
      ddr3_csn          => open,
      ddr3_rasn         => open,
      ddr3_casn         => open,
      ddr3_wen          => open,
      ddr3_odt          => open,
      ddr3_a            => open,
      ddr3_ba           => open,
      ddr3_dm           => open,
      ddr3_dq           => open,
      ddr3_dqs_p        => open,
      ddr3_dqs_n        => open,
      lpddr2_ck         => open,
      lpddr2_ckn        => open,
      lpddr2_cke        => open,
      lpddr2_csn        => open,
      lpddr2_ca         => open,
      lpddr2_dm         => open,
      lpddr2_dqs        => open,
      lpddr2_dqsn       => open,
      lpddr2_dq         => open,
      fsm_a             => open,
      fsm_d             => open,
      flash_resetn      => open,
      flash_clk         => open,
      flash_cen         => open,
      flash_oen         => open,
      flash_wen         => open,
      flash_advn        => open,
      flash_rdybsyn     => '0',
      sram_clk          => open,
      sram_cen          => open,
      sram_oen          => open,
      sram_wen          => open,
      sram_bwan         => open,
      sram_bwbn         => open,
      sram_advn         => open,
      sram_adscn        => open,
      sram_adspn        => open,
      sram_zz           => open,
      eneta_resetn      => open,
      eneta_mdc         => open,
      eneta_mdio        => open,
      eneta_intn        => '0',
      eneta_gtx_clk     => open,
      eneta_rx_clk      => '0',
      eneta_rx_crs      => '0',
      eneta_rx_col      => '0',
      eneta_rx_dv       => '0',
      eneta_rx_er       => '0',
      eneta_rx_d        => (others => '0'),
      eneta_tx_clk      => open,
      eneta_tx_en       => open,
      eneta_tx_er       => open,
      eneta_tx_d        => open,
      enetb_resetn      => open,
      enetb_mdc         => open,
      enetb_mdio        => open,
      enetb_intn        => '0',
      enetb_gtx_clk     => open,
      enetb_rx_clk      => '0',
      enetb_rx_crs      => '0',
      enetb_rx_col      => '0',
      enetb_rx_dv       => '0',
      enetb_rx_er       => '0',
      enetb_rx_d        => (others => '0'),
      enetb_tx_clk      => open,
      enetb_tx_en       => open,
      enetb_tx_er       => open,
      enetb_tx_d        => open,
      header_d          => open,
      header_p          => open,
      header_n          => open,
      hsmc_prsntn       => '0',
      hsmc_scl          => open,
      hsmc_sda          => open,
      hsmc_d            => open,
      hsmc_clk_in       => (others => '0'),
      hsmc_clk_out      => open,
      hsmc_rx_d         => (others => '0'),
      hsmc_rx_led       => open,
      hsmc_tx_d         => open,
      hsmc_tx_led       => open,
      fx2_resetn        => '0',
      usb_resetn        => '0',
      usb_clk           => '0',
      usb_oen           => '0',
      usb_wrn           => '0',
      usb_rdn           => '0',
      usb_addr          => open,
      usb_data          => open,
      usb_empty         => open,
      usb_full          => open,
      usb_scl           => '0',
      usb_sda           => open,
      max5_clk          => '0',
      max5_csn          => '0',
      max5_oen          => '0',
      max5_wen          => '0',
      max5_ben          => (others => '0'),
      max5_rsvd         => open
    );

end architecture sim;
