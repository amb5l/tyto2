--------------------------------------------------------------------------------
-- tmds_cap_io.vhd                                                            --
-- AMD/Xilinx 7 series I/O for the tmds_cap design.                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

library work;
  use work.axi4_pkg.all;
  use work.axi4s_pkg.all;

package tmds_cap_io_pkg is

  component tmds_cap_io is
    port (

      rst            : in    std_logic;
      clk_200m       : in    std_logic;

      axi_rst_n      : in    std_logic;
      axi_clk        : in    std_logic;
      saxi4_mosi     : in    axi4_a32d32_h_mosi_t;
      saxi4_miso     : out   axi4_a32d32_h_miso_t;
      maxi4s_mosi    : out   axi4s_64_mosi_t;
      maxi4s_miso    : in    axi4s_64_miso_t;

      gpo            : out   std_logic_vector(7 downto 0);
      gpi            : in    std_logic_vector(7 downto 0);

      hdmi_rx_clk_p  : in    std_logic;
      hdmi_rx_clk_n  : in    std_logic;
      hdmi_rx_d_p    : in    std_logic_vector(0 to 2);
      hdmi_rx_d_n    : in    std_logic_vector(0 to 2);

      hdmi_tx_clk_p  : out   std_logic;
      hdmi_tx_clk_n  : out   std_logic;
      hdmi_tx_d_p    : out   std_logic_vector(0 to 2);
      hdmi_tx_d_n    : out   std_logic_vector(0 to 2)

    );
  end component tmds_cap_io;

end package tmds_cap_io_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi4_pkg.all;
  use work.axi4s_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.hdmi_tx_selectio_pkg.all;
  use work.tmds_cap_csr_pkg.all;
  use work.tmds_cap_stream_pkg.all;

entity tmds_cap_io is
  port (

    rst            : in    std_logic;
    clk_200m       : in    std_logic;

    axi_rst_n      : in    std_logic;
    axi_clk        : in    std_logic;
    saxi4_mosi     : in    axi4_a32d32_h_mosi_t;
    saxi4_miso     : out   axi4_a32d32_h_miso_t;
    maxi4s_mosi    : out   axi4s_64_mosi_t;
    maxi4s_miso    : in    axi4s_64_miso_t;

    gpo            : out   std_logic_vector(7 downto 0);
    gpi            : in    std_logic_vector(7 downto 0);

    hdmi_rx_clk_p  : in    std_logic;
    hdmi_rx_clk_n  : in    std_logic;
    hdmi_rx_d_p    : in    std_logic_vector(0 to 2);
    hdmi_rx_d_n    : in    std_logic_vector(0 to 2);

    hdmi_tx_clk_p  : out   std_logic;
    hdmi_tx_clk_n  : out   std_logic;
    hdmi_tx_d_p    : out   std_logic_vector(0 to 2);
    hdmi_tx_d_n    : out   std_logic_vector(0 to 2)

  );
end entity tmds_cap_io;

architecture synth of tmds_cap_io is

  signal idelayctrl_rdy : std_logic;
  signal gpi_i          : std_logic_vector(31 downto 0);
  signal gpo_i          : std_logic_vector(31 downto 0);

  signal hdmi_rx_clku   : std_logic;
  signal hdmi_rx_clk    : std_logic;
  signal hdmi_rx_d      : std_logic_vector(0 to 2);
  signal prst           : std_logic;
  signal pclk           : std_logic;
  signal sclk           : std_logic;
  signal tmds           : slv10_vector(0 to 2);
  signal rx_status      : hdmi_rx_selectio_status_t;
  signal tmds_lock      : std_logic;
  signal hdmi_tx_clk    : std_logic;
  signal hdmi_tx_d      : std_logic_vector(0 to 2);

  signal cap_rst        : std_logic;                     -- capture reset
  signal cap_size       : std_logic_vector(31 downto 0); -- capture size (pixels)
  signal cap_en         : std_logic;                     -- capture enable
  signal cap_test       : std_logic;                     -- capture test
  signal cap_run        : std_logic;                     -- capture running
  signal cap_stop       : std_logic;                     -- capture stopped
  signal cap_loss       : std_logic;                     -- capture loss of TMDS lock
  signal cap_ovf        : std_logic;                     -- capture FIFO overflow
  signal cap_unf        : std_logic;                     -- capture FIFO underflow
  signal cap_count      : std_logic_vector(31 downto 0); -- capture count (pixels)

begin

  --------------------------------------------------------------------------------
  -- TMDS capture - control/status registers and streaming

  gpi_i <= (31 => idelayctrl_rdy, 7 downto 0 => gpi, others => '0');
  gpo <= gpo_i(7 downto 0);

  U_CSR: component tmds_cap_csr
    port map (
      axi_clk        => axi_clk,
      axi_rst_n      => axi_rst_n,
      saxi_mosi      => saxi4_mosi,
      saxi_miso      => saxi4_miso,
      gpi            => gpi_i,
      gpo            => gpo_i,
      tmds_status    => rx_status,
      cap_rst        => cap_rst,
      cap_size       => cap_size,
      cap_en         => cap_en,
      cap_test       => cap_test,
      cap_run        => cap_run,
      cap_stop       => cap_stop,
      cap_loss       => cap_loss,
      cap_ovf        => cap_ovf,
      cap_unf        => cap_unf,
      cap_count      => cap_count
   );

  U_STREAM: component tmds_cap_stream
    port map (
      prst        => prst,
      pclk        => pclk,
      tmds        => tmds,
      tmds_lock   => tmds_lock,
      cap_rst     => cap_rst,
      cap_size    => cap_size,
      cap_en      => cap_en,
      cap_test    => cap_test,
      cap_run     => cap_run,
      cap_stop    => cap_stop,
      cap_loss    => cap_loss,
      cap_ovf     => cap_ovf,
      cap_unf     => cap_unf,
      cap_count   => cap_count,
      axi_clk     => axi_clk,
      axi_rst_n   => axi_rst_n,
      maxi4s_mosi => maxi4s_mosi,
      maxi4s_miso => maxi4s_miso
    );

  --------------------------------------------------------------------------------
  -- HDMI I/O

  U_HDMI_RX: component hdmi_rx_selectio
    generic map (
      fclk   => 100.0
    )
    port map (
      rst    => not axi_rst_n,
      clk    => axi_clk,
      pclki  => hdmi_rx_clk,
      si     => hdmi_rx_d,
      sclko  => sclk,
      prsto  => prst,
      pclko  => pclk,
      po     => tmds,
      status => rx_status
    );

  tmds_lock <=
    rx_status.lock and
    rx_status.align_s(0) and
    rx_status.align_s(1) and
    rx_status.align_s(2) and
    rx_status.align_p;

  U_HDMI_TX: component hdmi_tx_selectio
    port map (
      sclki => sclk,
      prsti => prst,
      pclki => pclk,
      pi    => tmds,
      pclko => hdmi_tx_clk,
      so    => hdmi_tx_d
    );

  --------------------------------------------------------------------------------
  -- I/O primitives

  U_IDELAYCTRL: idelayctrl
    port map (
      rst    => rst,
      refclk => clk_200m,
      rdy    => idelayctrl_rdy
    );

  U_IBUFDS: component ibufds
    port map (
      i  => hdmi_rx_clk_p,
      ib => hdmi_rx_clk_n,
      o  => hdmi_rx_clku
    );

  U_BUFG: component bufg
    port map (
      i  => hdmi_rx_clku,
      o  => hdmi_rx_clk
    );

  U_OBUFDS: component obufds
    port map (
      i  => hdmi_tx_clk,
      o  => hdmi_tx_clk_p,
      ob => hdmi_tx_clk_n
    );

  GEN_CH: for i in 0 to 2 generate

    U_IBUFDS: component ibufds
      port map (
        i  => hdmi_rx_d_p(i),
        ib => hdmi_rx_d_n(i),
        o  => hdmi_rx_d(i)
      );

    U_OBUFDS: component obufds
      port map (
        i  => hdmi_tx_d(i),
        o  => hdmi_tx_d_p(i),
        ob => hdmi_tx_d_n(i)
      );

  end generate GEN_CH;

  --------------------------------------------------------------------------------

end architecture synth;
