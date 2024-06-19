use work.model_mdio_pkg.all;
use work.model_rgmii_rx_pkg.all;
use work.model_console_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_mb_mcs_memac_digilent_nexys_video is
  generic (
    FILENAME : string
  );
end entity tb_mb_mcs_memac_digilent_nexys_video;

architecture sim of tb_mb_mcs_memac_digilent_nexys_video is

  constant BAUD : integer := 115200;

  constant PHYAD        : std_ulogic_vector(4 downto 0) := "00001";
  constant PHY_OUI      : std_ulogic_vector(21 downto 0) := "10" & x"ABCDE";
  constant PHY_MODEL    : std_ulogic_vector(5 downto 0) := "01" & "0101";
  constant PHY_REVISION : std_ulogic_vector(3 downto 0) := x"A";
  constant PHYID1       : std_ulogic_vector(15 downto 0) := PHY_OUI(21 downto 6);
  constant PHYID2       : std_ulogic_vector(15 downto 0) := PHY_OUI(5 downto 0) & PHY_MODEL & PHY_REVISION;

  signal clki_100m     : std_ulogic;
  signal led           : std_ulogic_vector(7 downto 0);
  signal btn_rst_n     : std_ulogic;
  signal uart_rx_out   : std_ulogic;
  signal uart_tx_in    : std_ulogic;
  signal eth_rst_n     : std_ulogic;
  signal eth_txck      : std_ulogic;
  signal eth_txctl     : std_ulogic;
  signal eth_txd       : std_ulogic_vector(3 downto 0);
  signal eth_rxck      : std_ulogic;
  signal eth_rxctl     : std_ulogic;
  signal eth_rxd       : std_ulogic_vector(3 downto 0);
  signal eth_mdc       : std_ulogic;
  signal eth_mdio      : std_logic;

  signal model_rgmii_rx_en : std_ulogic;
  signal model_rgmii_rx_er : std_ulogic;
  signal model_rgmii_rx_d  : std_ulogic_vector(7 downto 0);

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

  MDIO: component model_mdio
    generic map (
      PHYAD  => PHYAD,
      PHYID1 => PHYID1,
      PHYID2 => PHYID2
    )
    port map (
      rst  => not btn_rst_n,
      mdc  => eth_mdc,
      mdio => eth_mdio
    );

  RGMII_TX: component model_rgmii_rx
    port map (
      i_clk => eth_txck,
      i_ctl => eth_txctl,
      i_d   => eth_txd,
      o_en  => model_rgmii_rx_en,
      o_er  => model_rgmii_rx_er,
      o_d   => model_rgmii_rx_d
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
