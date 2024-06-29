use work.model_console_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_mb_mcs_muart_digilent_nexys_video is
  generic (
    FILENAME : string
  );
end entity tb_mb_mcs_muart_digilent_nexys_video;

architecture sim of tb_mb_mcs_muart_digilent_nexys_video is

  constant BAUD : integer := 115200;

  signal clki_100m     : std_ulogic;
  signal btn_rst_n     : std_ulogic;
  signal uart_rx_out   : std_ulogic;
  signal uart_tx_in    : std_ulogic;

begin

  --btn_rst_n <= '0', '1' after 100 ns;
  btn_rst_n <= '1'; -- no manual reset, rely on MMCM

  clki_100m <= '0' when clki_100m = 'U' else not clki_100m after 5 ns;

  uart_tx_in <= '1';

  DUT: entity work.mb_mcs_muart_digilent_nexys_video
    port map (
        clki_100m     => clki_100m,
        led           => open,
        btn_rst_n     => btn_rst_n,
        oled_res_n    => open,
        oled_d_c      => open,
        oled_sclk     => open,
        oled_sdin     => open,
        hdmi_rx_txen  => open,
        hdmi_tx_clk_p => open,
        hdmi_tx_clk_n => open,
        hdmi_tx_d_p   => open,
        hdmi_tx_d_n   => open,
        ac_mclk       => open,
        ac_dac_sdata  => open,
        uart_rx_out   => uart_rx_out,
        uart_tx_in    => uart_tx_in,
        eth_rst_n     => open,
        eth_txck      => open,
        eth_txctl     => open,
        eth_txd       => open,
        eth_mdc       => open,
        ftdi_rd_n     => open,
        ftdi_wr_n     => open,
        ftdi_siwu_n   => open,
        ftdi_oe_n     => open,
        qspi_cs_n     => open,
        ddr3_reset_n  => open
    );

  CONSOLE: component model_console
    generic map (
      BAUD     => BAUD,
      FILENAME => FILENAME
    )
    port map (
      i => uart_rx_out
    );

end architecture sim;
