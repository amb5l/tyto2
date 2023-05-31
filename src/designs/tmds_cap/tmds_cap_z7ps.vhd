--------------------------------------------------------------------------------
-- tmds_cap_z7ps.vhd                                                          --
-- Zynq 7 Processor System based controller module                            --
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

package tmds_cap_z7ps_pkg is

  component tmds_cap_z7ps is
    port (

      axi_clk          : out   std_logic;
      axi_rst_n        : out   std_logic;

      gpio_i           : in    std_logic_vector( 31 downto 0 );
      gpio_o           : out   std_logic_vector( 31 downto 0 );
      gpio_t           : out   std_logic_vector( 31 downto 0 );

      tmds_maxi4_mosi  : out   axi4_a32d32_h_mosi_t;
      tmds_maxi4_miso  : in    axi4_a32d32_h_miso_t;
      tmds_saxi4s_mosi : in    axi4s_64_mosi_t;
      tmds_saxi4s_miso : out   axi4s_64_miso_t

    );
  end component tmds_cap_z7ps;

end package tmds_cap_z7ps_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi4_pkg.all;
  use work.axi4s_pkg.all;

entity tmds_cap_z7ps is
  port (

    axi_clk          : out   std_logic;
    axi_rst_n        : out   std_logic;

    gpio_i           : in    std_logic_vector( 31 downto 0 );
    gpio_o           : out   std_logic_vector( 31 downto 0 );
    gpio_t           : out   std_logic_vector( 31 downto 0 );

    tmds_maxi4_mosi  : out   axi4_a32d32_h_mosi_t;
    tmds_maxi4_miso  : in    axi4_a32d32_h_miso_t;
    tmds_saxi4s_mosi : in    axi4s_64_mosi_t;
    tmds_saxi4s_miso : out   axi4s_64_miso_t

  );
end entity tmds_cap_z7ps;

architecture wrapper of tmds_cap_z7ps is

  -- block diagram
  component tmds_cap_z7ps_sys
    port (

      axi_clk             : out   std_logic;
      axi_rst_n           : out   std_logic_vector(  0 downto 0 );

      gpio_tri_i          : in    std_logic_vector( 31 downto 0 );
      gpio_tri_o          : out   std_logic_vector( 31 downto 0 );
      gpio_tri_t          : out   std_logic_vector( 31 downto 0 );

      tmds_maxi32_awaddr  : out   std_logic_vector( 31 downto 0 );
      tmds_maxi32_awlen   : out   std_logic_vector(  7 downto 0 );
      tmds_maxi32_awsize  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi32_awburst : out   std_logic_vector(  1 downto 0 );
      tmds_maxi32_awlock  : out   std_logic_vector(  0     to 0 );
      tmds_maxi32_awcache : out   std_logic_vector(  3 downto 0 );
      tmds_maxi32_awprot  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi32_awqos   : out   std_logic_vector(  3 downto 0 );
      tmds_maxi32_awvalid : out   std_logic;
      tmds_maxi32_awready : in    std_logic;
      tmds_maxi32_wdata   : out   std_logic_vector( 31 downto 0 );
      tmds_maxi32_wstrb   : out   std_logic_vector(  3 downto 0 );
      tmds_maxi32_wlast   : out   std_logic;
      tmds_maxi32_wvalid  : out   std_logic;
      tmds_maxi32_wready  : in    std_logic;
      tmds_maxi32_bready  : out   std_logic;
      tmds_maxi32_bresp   : in    std_logic_vector(  1 downto 0 );
      tmds_maxi32_bvalid  : in    std_logic;
      tmds_maxi32_araddr  : out   std_logic_vector( 31 downto 0 );
      tmds_maxi32_arlen   : out   std_logic_vector(  7 downto 0 );
      tmds_maxi32_arsize  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi32_arburst : out   std_logic_vector(  1 downto 0 );
      tmds_maxi32_arlock  : out   std_logic_vector(  0     to 0 );
      tmds_maxi32_arcache : out   std_logic_vector(  3 downto 0 );
      tmds_maxi32_arprot  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi32_arqos   : out   std_logic_vector(  3 downto 0 );
      tmds_maxi32_arvalid : out   std_logic;
      tmds_maxi32_arready : in    std_logic;
      tmds_maxi32_rdata   : in    std_logic_vector( 31 downto 0 );
      tmds_maxi32_rresp   : in    std_logic_vector(  1 downto 0 );
      tmds_maxi32_rlast   : in    std_logic;
      tmds_maxi32_rvalid  : in    std_logic;
      tmds_maxi32_rready  : out   std_logic;

      tmds_saxis64_tdata  : in    std_logic_vector( 63 downto 0 );
      tmds_saxis64_tkeep  : in    std_logic_vector(  7 downto 0 );
      tmds_saxis64_tlast  : in    std_logic;
      tmds_saxis64_tvalid : in    std_logic;
      tmds_saxis64_tready : out   std_logic

    );
  end component tmds_cap_z7ps_sys;

begin

  U_BD: component tmds_cap_z7ps_sys
    port map (

      axi_clk               => axi_clk,
      axi_rst_n(0)          => axi_rst_n,

      gpio_tri_i            => gpio_i,
      gpio_tri_o            => gpio_o,
      gpio_tri_t            => gpio_t,

      tmds_maxi32_awaddr    => tmds_maxi4_mosi.aw.addr,
      tmds_maxi32_awlen     => tmds_maxi4_mosi.aw.len,
      tmds_maxi32_awsize    => tmds_maxi4_mosi.aw.size,
      tmds_maxi32_awburst   => tmds_maxi4_mosi.aw.burst,
      tmds_maxi32_awlock(0) => open,
      tmds_maxi32_awcache   => tmds_maxi4_mosi.aw.cache,
      tmds_maxi32_awprot    => tmds_maxi4_mosi.aw.prot,
      tmds_maxi32_awqos     => tmds_maxi4_mosi.aw.qos,
      tmds_maxi32_awvalid   => tmds_maxi4_mosi.aw.valid,
      tmds_maxi32_awready   => tmds_maxi4_miso.aw.ready,
      tmds_maxi32_wdata     => tmds_maxi4_mosi.w.data,
      tmds_maxi32_wstrb     => tmds_maxi4_mosi.w.strb,
      tmds_maxi32_wlast     => tmds_maxi4_mosi.w.last,
      tmds_maxi32_wvalid    => tmds_maxi4_mosi.w.valid,
      tmds_maxi32_wready    => tmds_maxi4_miso.w.ready,
      tmds_maxi32_bready    => tmds_maxi4_mosi.b.ready,
      tmds_maxi32_bresp     => tmds_maxi4_miso.b.resp,
      tmds_maxi32_bvalid    => tmds_maxi4_miso.b.valid,
      tmds_maxi32_araddr    => tmds_maxi4_mosi.ar.addr,
      tmds_maxi32_arlen     => tmds_maxi4_mosi.ar.len,
      tmds_maxi32_arsize    => tmds_maxi4_mosi.ar.size,
      tmds_maxi32_arburst   => tmds_maxi4_mosi.ar.burst,
      tmds_maxi32_arlock(0) => open,
      tmds_maxi32_arcache   => tmds_maxi4_mosi.ar.cache,
      tmds_maxi32_arprot    => tmds_maxi4_mosi.ar.prot,
      tmds_maxi32_arqos     => tmds_maxi4_mosi.ar.qos,
      tmds_maxi32_arvalid   => tmds_maxi4_mosi.ar.valid,
      tmds_maxi32_arready   => tmds_maxi4_miso.ar.ready,
      tmds_maxi32_rdata     => tmds_maxi4_miso.r.data,
      tmds_maxi32_rresp     => tmds_maxi4_miso.r.resp,
      tmds_maxi32_rlast     => tmds_maxi4_miso.r.last,
      tmds_maxi32_rvalid    => tmds_maxi4_miso.r.valid,
      tmds_maxi32_rready    => tmds_maxi4_mosi.r.ready,

      tmds_saxis64_tdata    => tmds_saxi4s_mosi.tdata,
      tmds_saxis64_tkeep    => tmds_saxi4s_mosi.tkeep,
      tmds_saxis64_tlast    => tmds_saxi4s_mosi.tlast,
      tmds_saxis64_tvalid   => tmds_saxi4s_mosi.tvalid,
      tmds_saxis64_tready   => tmds_saxi4s_miso.tready

    );

end architecture wrapper;
