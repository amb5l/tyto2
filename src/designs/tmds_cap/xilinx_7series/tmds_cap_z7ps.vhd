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

      axi_clk     : out   std_logic;
      axi_rst_n   : out   std_logic;

      maxi4_mosi  : out   axi4_a32d32_h_mosi_t;
      maxi4_miso  : in    axi4_a32d32_h_miso_t;
      saxi4s_mosi : in    axi4s_64_mosi_t;
      saxi4s_miso : out   axi4s_64_miso_t

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

    axi_clk     : out   std_logic;
    axi_rst_n   : out   std_logic;

    maxi4_mosi  : out   axi4_a32d32_h_mosi_t;
    maxi4_miso  : in    axi4_a32d32_h_miso_t;
    saxi4s_mosi : in    axi4s_64_mosi_t;
    saxi4s_miso : out   axi4s_64_miso_t

  );
end entity tmds_cap_z7ps;

architecture wrapper of tmds_cap_z7ps is

  -- block diagram
  component tmds_cap_z7ps_sys
    port (

      axi_clk        : out   std_logic;
      axi_rst_n      : out   std_logic_vector(  0 downto 0 );

      maxi32_awaddr  : out   std_logic_vector( 31 downto 0 );
      maxi32_awlen   : out   std_logic_vector(  7 downto 0 );
      maxi32_awsize  : out   std_logic_vector(  2 downto 0 );
      maxi32_awburst : out   std_logic_vector(  1 downto 0 );
      maxi32_awlock  : out   std_logic_vector(  0     to 0 );
      maxi32_awcache : out   std_logic_vector(  3 downto 0 );
      maxi32_awprot  : out   std_logic_vector(  2 downto 0 );
      maxi32_awqos   : out   std_logic_vector(  3 downto 0 );
      maxi32_awvalid : out   std_logic;
      maxi32_awready : in    std_logic;
      maxi32_wdata   : out   std_logic_vector( 31 downto 0 );
      maxi32_wstrb   : out   std_logic_vector(  3 downto 0 );
      maxi32_wlast   : out   std_logic;
      maxi32_wvalid  : out   std_logic;
      maxi32_wready  : in    std_logic;
      maxi32_bready  : out   std_logic;
      maxi32_bresp   : in    std_logic_vector(  1 downto 0 );
      maxi32_bvalid  : in    std_logic;
      maxi32_araddr  : out   std_logic_vector( 31 downto 0 );
      maxi32_arlen   : out   std_logic_vector(  7 downto 0 );
      maxi32_arsize  : out   std_logic_vector(  2 downto 0 );
      maxi32_arburst : out   std_logic_vector(  1 downto 0 );
      maxi32_arlock  : out   std_logic_vector(  0     to 0 );
      maxi32_arcache : out   std_logic_vector(  3 downto 0 );
      maxi32_arprot  : out   std_logic_vector(  2 downto 0 );
      maxi32_arqos   : out   std_logic_vector(  3 downto 0 );
      maxi32_arvalid : out   std_logic;
      maxi32_arready : in    std_logic;
      maxi32_rdata   : in    std_logic_vector( 31 downto 0 );
      maxi32_rresp   : in    std_logic_vector(  1 downto 0 );
      maxi32_rlast   : in    std_logic;
      maxi32_rvalid  : in    std_logic;
      maxi32_rready  : out   std_logic;

      saxis64_tdata  : in    std_logic_vector( 63 downto 0 );
      saxis64_tkeep  : in    std_logic_vector(  7 downto 0 );
      saxis64_tlast  : in    std_logic;
      saxis64_tvalid : in    std_logic;
      saxis64_tready : out   std_logic

    );
  end component tmds_cap_z7ps_sys;

begin

  U_BD: component tmds_cap_z7ps_sys
    port map (

      axi_clk          => axi_clk,
      axi_rst_n(0)     => axi_rst_n,

      maxi32_awaddr    => maxi4_mosi.aw.addr,
      maxi32_awlen     => maxi4_mosi.aw.len,
      maxi32_awsize    => maxi4_mosi.aw.size,
      maxi32_awburst   => maxi4_mosi.aw.burst,
      maxi32_awlock(0) => open,
      maxi32_awcache   => maxi4_mosi.aw.cache,
      maxi32_awprot    => maxi4_mosi.aw.prot,
      maxi32_awqos     => maxi4_mosi.aw.qos,
      maxi32_awvalid   => maxi4_mosi.aw.valid,
      maxi32_awready   => maxi4_miso.aw.ready,
      maxi32_wdata     => maxi4_mosi.w.data,
      maxi32_wstrb     => maxi4_mosi.w.strb,
      maxi32_wlast     => maxi4_mosi.w.last,
      maxi32_wvalid    => maxi4_mosi.w.valid,
      maxi32_wready    => maxi4_miso.w.ready,
      maxi32_bready    => maxi4_mosi.b.ready,
      maxi32_bresp     => maxi4_miso.b.resp,
      maxi32_bvalid    => maxi4_miso.b.valid,
      maxi32_araddr    => maxi4_mosi.ar.addr,
      maxi32_arlen     => maxi4_mosi.ar.len,
      maxi32_arsize    => maxi4_mosi.ar.size,
      maxi32_arburst   => maxi4_mosi.ar.burst,
      maxi32_arlock(0) => open,
      maxi32_arcache   => maxi4_mosi.ar.cache,
      maxi32_arprot    => maxi4_mosi.ar.prot,
      maxi32_arqos     => maxi4_mosi.ar.qos,
      maxi32_arvalid   => maxi4_mosi.ar.valid,
      maxi32_arready   => maxi4_miso.ar.ready,
      maxi32_rdata     => maxi4_miso.r.data,
      maxi32_rresp     => maxi4_miso.r.resp,
      maxi32_rlast     => maxi4_miso.r.last,
      maxi32_rvalid    => maxi4_miso.r.valid,
      maxi32_rready    => maxi4_mosi.r.ready,

      saxis64_tdata    => saxi4s_mosi.tdata,
      saxis64_tkeep    => saxi4s_mosi.tkeep,
      saxis64_tlast    => saxi4s_mosi.tlast,
      saxis64_tvalid   => saxi4s_mosi.tvalid,
      saxis64_tready   => saxi4s_miso.tready

    );

end architecture wrapper;
