library ieee;
  use ieee.std_logic_1164.all;

entity tb_mbv_mcs_test_digilent_nexys_video is
end entity tb_mbv_mcs_test_digilent_nexys_video;

architecture sim of tb_mbv_mcs_test_digilent_nexys_video is

  signal clki_100m   : std_logic;
  signal led         : std_logic_vector(7 downto 0);
  signal btn_rst_n   : std_logic;
  signal sw          : std_logic_vector(7 downto 0);
  signal uart_rx_out : std_logic;
  signal uart_tx_in  : std_logic;

component mbv_mcs_test_digilent_nexys_video is
  port (
    clki_100m     : in    std_logic;
    led           : out   std_logic_vector(7 downto 0);
    btn_rst_n     : in    std_logic;
    sw            : in    std_logic_vector(7 downto 0);
    oled_res_n    : out   std_logic;
    oled_d_c      : out   std_logic;
    oled_sclk     : out   std_logic;
    oled_sdin     : out   std_logic;
    hdmi_rx_txen  : out   std_logic;
    hdmi_tx_clk_p : out   std_logic;
    hdmi_tx_clk_n : out   std_logic;
    hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n   : out   std_logic_vector(0 to 2);
    ac_mclk       : out   std_logic;
    ac_dac_sdata  : out   std_logic;
    uart_rx_out   : out   std_logic;
    uart_tx_in    : in    std_logic;
    eth_rst_n     : out   std_logic;
    eth_txck      : out   std_logic;
    eth_txctl     : out   std_logic;
    eth_txd       : out   std_logic_vector(3 downto 0);
    eth_mdc       : out   std_logic;
    ftdi_rd_n     : out   std_logic;
    ftdi_wr_n     : out   std_logic;
    ftdi_siwu_n   : out   std_logic;
    ftdi_oe_n     : out   std_logic;
    qspi_cs_n     : out   std_logic;
    ddr3_reset_n  : out   std_logic
  );
end component mbv_mcs_test_digilent_nexys_video;

begin

  btn_rst_n <= '0', '1' after 100 ns;
  clki_100m <=
    '1' after 5 ns when clki_100m = '0' else
    '0' after 5 ns when clki_100m = '1' else
    '0';

  sw <= x"AA";
  uart_tx_in <= '0';

  DUT: component mbv_mcs_test_digilent_nexys_video
    port map (
      clki_100m     => clki_100m,
      led           => led,
      btn_rst_n     => btn_rst_n,
      sw            => sw,
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

end architecture;