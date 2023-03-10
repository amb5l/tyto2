--------------------------------------------------------------------------------
-- tmds_cap_mb.vhd                                                            --
-- MicroBlaze CPU based controller module                                     --
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
  use work.axi_pkg.all;

package tmds_cap_mb_pkg is

  component tmds_cap_mb is
    port (

      ref_rst_n       : in    std_logic;
      ref_clk         : in    std_logic;

      mig_lock        : out   std_logic;
      mig_rdy         : out   std_logic;
      clk_200m        : out   std_logic;

      uart_tx         : out   std_logic;
      uart_rx         : in    std_logic;

      gpio_i          : in    std_logic_vector( 31 downto 0 );
      gpio_o          : out   std_logic_vector( 31 downto 0 );
      gpio_t          : out   std_logic_vector( 31 downto 0 );
    
      axi_clk         : out   std_logic;
      axi_rst_n       : out   std_logic;
      tmds_maxi_mosi  : out   axi4_mosi_a32d32_t;
      tmds_maxi_miso  : in    axi4_miso_a32d32_t;
      tmds_saxis_mosi : in    axis_mosi_64_t;
      tmds_saxis_miso : out   axis_miso_64_t;
      emac_maxi_mosi  : out   axi4_mosi_a32d32_t;
      emac_maxi_miso  : in    axi4_miso_a32d32_t;
      emac_maxis_mosi : out   axis_mosi_32_t;
      emac_maxis_miso : in    axis_miso_32_t;
      emac_saxis_mosi : in    axis_mosi_32_t;
      emac_saxis_miso : out   axis_miso_32_t;

      ddr3_reset_n    : out   std_logic;
      ddr3_ck_p       : out   std_logic_vector(  0 downto 0 );
      ddr3_ck_n       : out   std_logic_vector(  0 downto 0 );
      ddr3_cke        : out   std_logic_vector(  0 downto 0 );
      ddr3_ras_n      : out   std_logic;
      ddr3_cas_n      : out   std_logic;
      ddr3_we_n       : out   std_logic;
      ddr3_odt        : out   std_logic_vector(  0 downto 0 );
      ddr3_addr       : out   std_logic_vector( 14 downto 0 );
      ddr3_ba         : out   std_logic_vector(  2 downto 0 );
      ddr3_dm         : out   std_logic_vector(  1 downto 0 );
      ddr3_dq         : inout std_logic_vector( 15 downto 0 );
      ddr3_dqs_p      : inout std_logic_vector(  1 downto 0 );
      ddr3_dqs_n      : inout std_logic_vector(  1 downto 0 )

    );
  end component tmds_cap_mb;

end package tmds_cap_mb_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_pkg.all;

entity tmds_cap_mb is
  port (

    ref_rst_n       : in    std_logic;
    ref_clk         : in    std_logic;

    mig_lock        : out   std_logic;
    mig_rdy         : out   std_logic;
    clk_200m        : out   std_logic;

    uart_tx         : out   std_logic;
    uart_rx         : in    std_logic;

    gpio_i          : in    std_logic_vector( 31 downto 0 );
    gpio_o          : out   std_logic_vector( 31 downto 0 );
    gpio_t          : out   std_logic_vector( 31 downto 0 );

    axi_clk         : out   std_logic;
    axi_rst_n       : out   std_logic;
    tmds_maxi_mosi  : out   axi4_mosi_a32d32_t;
    tmds_maxi_miso  : in    axi4_miso_a32d32_t;
    tmds_saxis_mosi : in    axis_mosi_64_t;
    tmds_saxis_miso : out   axis_miso_64_t;
    emac_maxi_mosi  : out   axi4_mosi_a32d32_t;
    emac_maxi_miso  : in    axi4_miso_a32d32_t;
    emac_maxis_mosi : out   axis_mosi_32_t;
    emac_maxis_miso : in    axis_miso_32_t;
    emac_saxis_mosi : in    axis_mosi_32_t;
    emac_saxis_miso : out   axis_miso_32_t;

    ddr3_reset_n    : out   std_logic;
    ddr3_ck_p       : out   std_logic_vector(  0 downto 0 );
    ddr3_ck_n       : out   std_logic_vector(  0 downto 0 );
    ddr3_cke        : out   std_logic_vector(  0 downto 0 );
    ddr3_ras_n      : out   std_logic;
    ddr3_cas_n      : out   std_logic;
    ddr3_we_n       : out   std_logic;
    ddr3_odt        : out   std_logic_vector(  0 downto 0 );
    ddr3_addr       : out   std_logic_vector( 14 downto 0 );
    ddr3_ba         : out   std_logic_vector(  2 downto 0 );
    ddr3_dm         : out   std_logic_vector(  1 downto 0 );
    ddr3_dq         : inout std_logic_vector( 15 downto 0 );
    ddr3_dqs_p      : inout std_logic_vector(  1 downto 0 );
    ddr3_dqs_n      : inout std_logic_vector(  1 downto 0 )

  );
end entity tmds_cap_mb;

architecture wrapper of tmds_cap_mb is

--  signal mig_rst        : std_logic;
  signal mig_lock_i     : std_logic;
  signal mig_rsto       : std_logic;

  signal cpu_rsti_n     : std_logic;
  signal cpu_rsto_n     : std_logic;

  signal ddr3_maxi_mosi : axi4_mosi_a32d128_t;
  signal ddr3_maxi_miso : axi4_miso_a32d128_t;

  component tmds_cap_mb_sys
    port (

      mig_clk           : in    std_logic;
      mig_rsti_n        : in    std_logic;
      mig_lock          : out   std_logic;
      mig_rsto          : out   std_logic;
      mig_rdy           : out   std_logic;

      clk_200m          : out   std_logic;

      cpu_lock          : in    std_logic;
      cpu_rsti_n        : in    std_logic;
      cpu_rsto_n        : out   std_logic_vector ( 0 to 0 );

      uart_rxd          : in    std_logic;
      uart_txd          : out   std_logic;

      gpio_tri_i        : in    std_logic_vector ( 31 downto 0 );
      gpio_tri_o        : out   std_logic_vector ( 31 downto 0 );
      gpio_tri_t        : out   std_logic_vector ( 31 downto 0 );

      axi_clk           : out   std_logic;
      axi_rst_n         : in    std_logic;

      tmds_maxi_awaddr  : out   std_logic_vector( 31 downto 0 );
      tmds_maxi_awlen   : out   std_logic_vector(  7 downto 0 );
      tmds_maxi_awsize  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi_awburst : out   std_logic_vector(  1 downto 0 );
      tmds_maxi_awlock  : out   std_logic_vector(  0 to     0 );
      tmds_maxi_awcache : out   std_logic_vector(  3 downto 0 );
      tmds_maxi_awprot  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi_awqos   : out   std_logic_vector(  3 downto 0 );
      tmds_maxi_awvalid : out   std_logic;
      tmds_maxi_awready : in    std_logic;
      tmds_maxi_wdata   : out   std_logic_vector( 31 downto 0 );
      tmds_maxi_wstrb   : out   std_logic_vector(  3 downto 0 );
      tmds_maxi_wlast   : out   std_logic;
      tmds_maxi_wvalid  : out   std_logic;
      tmds_maxi_wready  : in    std_logic;
      tmds_maxi_bready  : out   std_logic;
      tmds_maxi_bresp   : in    std_logic_vector(  1 downto 0 );
      tmds_maxi_bvalid  : in    std_logic;
      tmds_maxi_araddr  : out   std_logic_vector( 31 downto 0 );
      tmds_maxi_arlen   : out   std_logic_vector(  7 downto 0 );
      tmds_maxi_arsize  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi_arburst : out   std_logic_vector(  1 downto 0 );
      tmds_maxi_arlock  : out   std_logic_vector(  0 to     0 );
      tmds_maxi_arcache : out   std_logic_vector(  3 downto 0 );
      tmds_maxi_arprot  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi_arqos   : out   std_logic_vector(  3 downto 0 );
      tmds_maxi_arvalid : out   std_logic;
      tmds_maxi_arready : in    std_logic;
      tmds_maxi_rdata   : in    std_logic_vector( 31 downto 0 );
      tmds_maxi_rresp   : in    std_logic_vector(  1 downto 0 );
      tmds_maxi_rlast   : in    std_logic;
      tmds_maxi_rvalid  : in    std_logic;
      tmds_maxi_rready  : out   std_logic;

      tmds_saxis_tdata  : in    std_logic_vector( 63 downto 0 );
      tmds_saxis_tkeep  : in    std_logic_vector(  7 downto 0 );
      tmds_saxis_tlast  : in    std_logic;
      tmds_saxis_tvalid : in    std_logic;
      tmds_saxis_tready : out   std_logic;

      eth_maxi_awaddr   : out   std_logic_vector( 31 downto 0 );
      eth_maxi_awlen    : out   std_logic_vector(  7 downto 0 );
      eth_maxi_awsize   : out   std_logic_vector(  2 downto 0 );
      eth_maxi_awburst  : out   std_logic_vector(  1 downto 0 );
      eth_maxi_awlock   : out   std_logic_vector(  0 to     0 );
      eth_maxi_awcache  : out   std_logic_vector(  3 downto 0 );
      eth_maxi_awprot   : out   std_logic_vector(  2 downto 0 );
      eth_maxi_awqos    : out   std_logic_vector(  3 downto 0 );
      eth_maxi_awvalid  : out   std_logic;
      eth_maxi_awready  : in    std_logic;
      eth_maxi_wdata    : out   std_logic_vector( 31 downto 0 );
      eth_maxi_wstrb    : out   std_logic_vector(  3 downto 0 );
      eth_maxi_wlast    : out   std_logic;
      eth_maxi_wvalid   : out   std_logic;
      eth_maxi_wready   : in    std_logic;
      eth_maxi_bready   : out   std_logic;
      eth_maxi_bresp    : in    std_logic_vector(  1 downto 0 );
      eth_maxi_bvalid   : in    std_logic;
      eth_maxi_araddr   : out   std_logic_vector( 31 downto 0 );
      eth_maxi_arlen    : out   std_logic_vector(  7 downto 0 );
      eth_maxi_arsize   : out   std_logic_vector(  2 downto 0 );
      eth_maxi_arburst  : out   std_logic_vector(  1 downto 0 );
      eth_maxi_arlock   : out   std_logic_vector(  0 to     0 );
      eth_maxi_arcache  : out   std_logic_vector(  3 downto 0 );
      eth_maxi_arprot   : out   std_logic_vector(  2 downto 0 );
      eth_maxi_arqos    : out   std_logic_vector(  3 downto 0 );
      eth_maxi_arvalid  : out   std_logic;
      eth_maxi_arready  : in    std_logic;
      eth_maxi_rdata    : in    std_logic_vector( 31 downto 0 );
      eth_maxi_rresp    : in    std_logic_vector(  1 downto 0 );
      eth_maxi_rlast    : in    std_logic;
      eth_maxi_rvalid   : in    std_logic;
      eth_maxi_rready   : out   std_logic;

      emac_maxis_tdata  : out   std_logic_vector( 31 downto 0 );
      emac_maxis_tkeep  : out   std_logic_vector(  3 downto 0 );
      emac_maxis_tlast  : out   std_logic;
      emac_maxis_tvalid : out   std_logic;
      emac_maxis_tready : in    std_logic;
      emac_saxis_tdata  : in    std_logic_vector( 31 downto 0 );
      emac_saxis_tkeep  : in    std_logic_vector(  3 downto 0 );
      emac_saxis_tlast  : in    std_logic;
      emac_saxis_tvalid : in    std_logic;
      emac_saxis_tready : out   std_logic;

      ddr3_reset_n      : out   std_logic;
      ddr3_ck_p         : out   std_logic_vector(  0 downto 0 );
      ddr3_ck_n         : out   std_logic_vector(  0 downto 0 );
      ddr3_cke          : out   std_logic_vector(  0 downto 0 );
      ddr3_ras_n        : out   std_logic;
      ddr3_cas_n        : out   std_logic;
      ddr3_we_n         : out   std_logic;
      ddr3_odt          : out   std_logic_vector(  0 downto 0 );
      ddr3_addr         : out   std_logic_vector( 14 downto 0 );
      ddr3_ba           : out   std_logic_vector(  2 downto 0 );
      ddr3_dm           : out   std_logic_vector(  1 downto 0 );
      ddr3_dq           : inout std_logic_vector( 15 downto 0 );
      ddr3_dqs_p        : inout std_logic_vector(  1 downto 0 );
      ddr3_dqs_n        : inout std_logic_vector(  1 downto 0 )

    );
  end component tmds_cap_mb_sys;

begin

  mig_lock   <= mig_lock_i;
  cpu_rsti_n <= not mig_rsto;
  axi_rst_n  <= cpu_rsto_n;

  U_BD: component tmds_cap_mb_sys
    port map (

      mig_clk             => ref_clk,
      mig_rsti_n          => ref_rst_n,
      mig_lock            => mig_lock_i,
      mig_rsto            => mig_rsto,
      mig_rdy             => mig_rdy,

      clk_200m            => clk_200m,

      cpu_lock            => mig_lock_i,
      cpu_rsti_n          => cpu_rsti_n,
      cpu_rsto_n(0)       => cpu_rsto_n,

      uart_rxd            => uart_rx,
      uart_txd            => uart_tx,

      gpio_tri_i          => gpio_i,
      gpio_tri_o          => gpio_o,
      gpio_tri_t          => gpio_t,

      axi_clk             => axi_clk,
      axi_rst_n           => cpu_rsto_n,

      tmds_maxi_awaddr    => tmds_maxi_mosi.awaddr,
      tmds_maxi_awlen     => tmds_maxi_mosi.awlen,
      tmds_maxi_awsize    => tmds_maxi_mosi.awsize,
      tmds_maxi_awburst   => tmds_maxi_mosi.awburst,
      tmds_maxi_awlock(0) => tmds_maxi_mosi.awlock,
      tmds_maxi_awcache   => tmds_maxi_mosi.awcache,
      tmds_maxi_awprot    => tmds_maxi_mosi.awprot,
      tmds_maxi_awqos     => tmds_maxi_mosi.awqos,
      tmds_maxi_awvalid   => tmds_maxi_mosi.awvalid,
      tmds_maxi_awready   => tmds_maxi_miso.awready,
      tmds_maxi_wdata     => tmds_maxi_mosi.wdata,
      tmds_maxi_wstrb     => tmds_maxi_mosi.wstrb,
      tmds_maxi_wlast     => tmds_maxi_mosi.wlast,
      tmds_maxi_wvalid    => tmds_maxi_mosi.wvalid,
      tmds_maxi_wready    => tmds_maxi_miso.wready,
      tmds_maxi_bready    => tmds_maxi_mosi.bready,
      tmds_maxi_bresp     => tmds_maxi_miso.bresp,
      tmds_maxi_bvalid    => tmds_maxi_miso.bvalid,
      tmds_maxi_araddr    => tmds_maxi_mosi.araddr,
      tmds_maxi_arlen     => tmds_maxi_mosi.arlen,
      tmds_maxi_arsize    => tmds_maxi_mosi.arsize,
      tmds_maxi_arburst   => tmds_maxi_mosi.arburst,
      tmds_maxi_arlock(0) => tmds_maxi_mosi.arlock,
      tmds_maxi_arcache   => tmds_maxi_mosi.arcache,
      tmds_maxi_arprot    => tmds_maxi_mosi.arprot,
      tmds_maxi_arqos     => tmds_maxi_mosi.arqos,
      tmds_maxi_arvalid   => tmds_maxi_mosi.arvalid,
      tmds_maxi_arready   => tmds_maxi_miso.arready,
      tmds_maxi_rdata     => tmds_maxi_miso.rdata,
      tmds_maxi_rresp     => tmds_maxi_miso.rresp,
      tmds_maxi_rlast     => tmds_maxi_miso.rlast,
      tmds_maxi_rvalid    => tmds_maxi_miso.rvalid,
      tmds_maxi_rready    => tmds_maxi_mosi.rready,

      tmds_saxis_tdata    => tmds_saxis_mosi.tdata,
      tmds_saxis_tkeep    => tmds_saxis_mosi.tkeep,
      tmds_saxis_tlast    => tmds_saxis_mosi.tlast,
      tmds_saxis_tvalid   => tmds_saxis_mosi.tvalid,
      tmds_saxis_tready   => tmds_saxis_miso.tready,

      eth_maxi_awaddr     => emac_maxi_mosi.awaddr,
      eth_maxi_awlen      => emac_maxi_mosi.awlen,
      eth_maxi_awsize     => emac_maxi_mosi.awsize,
      eth_maxi_awburst    => emac_maxi_mosi.awburst,
      eth_maxi_awlock(0)  => emac_maxi_mosi.awlock,
      eth_maxi_awcache    => emac_maxi_mosi.awcache,
      eth_maxi_awprot     => emac_maxi_mosi.awprot,
      eth_maxi_awqos      => emac_maxi_mosi.awqos,
      eth_maxi_awvalid    => emac_maxi_mosi.awvalid,
      eth_maxi_awready    => emac_maxi_miso.awready,
      eth_maxi_wdata      => emac_maxi_mosi.wdata,
      eth_maxi_wstrb      => emac_maxi_mosi.wstrb,
      eth_maxi_wlast      => emac_maxi_mosi.wlast,
      eth_maxi_wvalid     => emac_maxi_mosi.wvalid,
      eth_maxi_wready     => emac_maxi_miso.wready,
      eth_maxi_bready     => emac_maxi_mosi.bready,
      eth_maxi_bresp      => emac_maxi_miso.bresp,
      eth_maxi_bvalid     => emac_maxi_miso.bvalid,
      eth_maxi_araddr     => emac_maxi_mosi.araddr,
      eth_maxi_arlen      => emac_maxi_mosi.arlen,
      eth_maxi_arsize     => emac_maxi_mosi.arsize,
      eth_maxi_arburst    => emac_maxi_mosi.arburst,
      eth_maxi_arlock(0)  => emac_maxi_mosi.arlock,
      eth_maxi_arcache    => emac_maxi_mosi.arcache,
      eth_maxi_arprot     => emac_maxi_mosi.arprot,
      eth_maxi_arqos      => emac_maxi_mosi.arqos,
      eth_maxi_arvalid    => emac_maxi_mosi.arvalid,
      eth_maxi_arready    => emac_maxi_miso.arready,
      eth_maxi_rdata      => emac_maxi_miso.rdata,
      eth_maxi_rresp      => emac_maxi_miso.rresp,
      eth_maxi_rlast      => emac_maxi_miso.rlast,
      eth_maxi_rvalid     => emac_maxi_miso.rvalid,
      eth_maxi_rready     => emac_maxi_mosi.rready,

      emac_maxis_tdata    => emac_maxis_mosi.tdata,
      emac_maxis_tkeep    => emac_maxis_mosi.tkeep,
      emac_maxis_tlast    => emac_maxis_mosi.tlast,
      emac_maxis_tvalid   => emac_maxis_mosi.tvalid,
      emac_maxis_tready   => emac_maxis_miso.tready,

      emac_saxis_tdata    => emac_saxis_mosi.tdata,
      emac_saxis_tkeep    => emac_saxis_mosi.tkeep,
      emac_saxis_tlast    => emac_saxis_mosi.tlast,
      emac_saxis_tvalid   => emac_saxis_mosi.tvalid,
      emac_saxis_tready   => emac_saxis_miso.tready,

      ddr3_reset_n        => ddr3_reset_n,
      ddr3_ck_p           => ddr3_ck_p,
      ddr3_ck_n           => ddr3_ck_n,
      ddr3_cke            => ddr3_cke,
      ddr3_ras_n          => ddr3_ras_n,
      ddr3_cas_n          => ddr3_cas_n,
      ddr3_we_n           => ddr3_we_n,
      ddr3_odt            => ddr3_odt,
      ddr3_addr           => ddr3_addr,
      ddr3_ba             => ddr3_ba,
      ddr3_dm             => ddr3_dm,
      ddr3_dq             => ddr3_dq,
      ddr3_dqs_p          => ddr3_dqs_p,
      ddr3_dqs_n          => ddr3_dqs_n

    );

end architecture wrapper;