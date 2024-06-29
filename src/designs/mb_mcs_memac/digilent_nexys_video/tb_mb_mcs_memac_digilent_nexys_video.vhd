use work.model_mdio_pkg.all;
use work.model_rgmii_rx_pkg.all;
use work.model_rgmii_tx_pkg.all;
use work.model_console_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_mb_mcs_memac_digilent_nexys_video is
  generic (
    FILENAME       : string;
    RGMII_TX_ALIGN : string;
    RGMII_RX_ALIGN : string
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

  signal rgmii_rx_pkt : model_rgmii_tx_pkt_t;

begin

  btn_rst_n <= '0', '1' after 10 ns;
  clki_100m <= '0' when clki_100m = 'U' else not clki_100m after 5 ns;

  uart_tx_in <= '1';

  DUT: entity work.mb_mcs_memac_digilent_nexys_video
    generic map (
        RGMII_TX_ALIGN => RGMII_TX_ALIGN,
        RGMII_RX_ALIGN => RGMII_RX_ALIGN,
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

  -- DUT transmit is center aligned
  -- TODO generic required here
  RGMII_TX: component model_rgmii_rx
    port map (
      i_clk => eth_txck,
      i_ctl => eth_txctl,
      i_d   => eth_txd,
      o_en  => model_rgmii_rx_en,
      o_er  => model_rgmii_rx_er,
      o_d   => model_rgmii_rx_d
    );

  -- DUT rx is edge aligned
  RGMII_RX: component model_rgmii_tx
    generic map (
      ALIGN => RGMII_RX_ALIGN
    )
    port map (
      spd   => "10",
      i_pkt => rgmii_rx_pkt,
      i_ack => open,
      o_clk => eth_rxck,
      o_ctl => eth_rxctl,
      o_d   => eth_rxd
    );

  P_RGMII_RX: process
  begin
    wait until led = x"04";
    wait for 10 us;
    rgmii_rx_pkt <= (
      len  => 74,
      data => (
        0 to 73 => (
          16#55#,16#55#,16#55#,16#55#,16#55#,16#55#,16#55#,16#D5#,
          16#01#,16#80#,16#C2#,16#00#,16#00#,16#0E#,16#00#,16#E0#,
          16#4C#,16#78#,16#14#,16#5B#,16#88#,16#CC#,16#02#,16#0B#,
          16#07#,16#52#,16#59#,16#5A#,16#45#,16#4E#,16#37#,16#39#,
          16#35#,16#30#,16#58#,16#04#,16#07#,16#03#,16#00#,16#E0#,
          16#4C#,16#78#,16#14#,16#5B#,16#06#,16#02#,16#0E#,16#11#,
          16#FE#,16#09#,16#00#,16#12#,16#0F#,16#01#,16#03#,16#00#,
          16#01#,16#00#,16#00#,16#FE#,16#07#,16#00#,16#12#,16#BB#,
          16#01#,16#00#,16#01#,16#01#,16#00#,16#00#,16#C5#,16#A4#,
          16#1E#,16#89#
        ),
        others => 16#AA#
      )
    );
    wait;
  end process P_RGMII_RX;

  CONSOLE: component model_console
    generic map (
      BAUD     => BAUD,
      FILENAME => FILENAME
    )
    port map (
      i => uart_rx_out
    );

end architecture sim;
