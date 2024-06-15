library ieee;
  use ieee.std_logic_1164.all;

entity tb_mb_mcs_memac_digilent_nexys_video is
end entity tb_mb_mcs_memac_digilent_nexys_video;

architecture sim of tb_mb_mcs_memac_digilent_nexys_video is

  signal clki_100m     : std_logic;
  signal led           : std_logic_vector(7 downto 0);
  signal btn_rst_n     : std_logic;
  signal uart_rx_out   : std_logic;
  signal uart_tx_in    : std_logic;
  signal eth_rst_n     : std_logic;
  signal eth_txck      : std_logic;
  signal eth_txctl     : std_logic;
  signal eth_txd       : std_logic_vector(3 downto 0);
  signal eth_rxck      : std_logic;
  signal eth_rxctl     : std_logic;
  signal eth_rxd       : std_logic_vector(3 downto 0);
  signal eth_mdc       : std_logic;
  signal eth_mdio      : std_logic;

begin

  btn_rst_n <= '0', '1' after 10 ns;
  clki_100m <= '0' when clki_100m = 'U' else not clki_100m after 5 ns;

  eth_rxck  <= '0';
  eth_rxctl <= '0';
  eth_rxd   <= (others => '0');

  uart_tx_in <= '1';

  DUT: entity work.mb_mcs_memac_digilent_nexys_video
    generic map (
        RGMII_TX_ALIGN => "CENTER",
        RGMII_RX_ALIGN => "CENTER",
        TX_BUF_SIZE    => 8192,
        RX_BUF_SIZE    => 8192
    )
    port map (
        clki_100m     => clki_100m,
        led           => led,
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
        eth_rst_n     => eth_rst_n,
        eth_txck      => eth_txck,
        eth_txctl     => eth_txctl,
        eth_txd       => eth_txd,
        eth_rxck      => eth_rxck,
        eth_rxctl     => eth_rxctl,
        eth_rxd       => eth_rxd,
        eth_mdc       => eth_mdc,
        eth_mdio      => eth_mdio,
        ftdi_rd_n     => open,
        ftdi_wr_n     => open,
        ftdi_siwu_n   => open,
        ftdi_oe_n     => open,
        qspi_cs_n     => open,
        ddr3_reset_n  => open
    );

  U_MODEL_MDIO: component model_mdio
    port map (
      rst  => not btn_rst_n,
      mdc  => eth_mdc,
      mdio => eth_mdio
    );


end architecture sim;
