--------------------------------------------------------------------------------
-- tmds_cap_z7ps.vhd                                                          --
-- Zync 7 Processor System based controller module                            --
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

package tmds_cap_z7ps_pkg is

  component tmds_cap_z7ps is
    port (

      axi_clk         : out   std_logic;
      axi_rst_n       : out   std_logic;

      gpio_i          : in    std_logic_vector( 31 downto 0 );
      gpio_o          : out   std_logic_vector( 31 downto 0 );
      gpio_t          : out   std_logic_vector( 31 downto 0 );

      tmds_maxi_mosi  : out   axi4_mosi_a32d32_t;
      tmds_maxi_miso  : in    axi4_miso_a32d32_t;
      tmds_saxis_mosi : in    axi4s_mosi_64_t;
      tmds_saxis_miso : out   axi4s_miso_64_t

    );
  end component tmds_cap_z7ps;

end package tmds_cap_z7ps_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_pkg.all;

entity tmds_cap_z7ps is
  port (

    axi_clk         : out   std_logic;
    axi_rst_n       : out   std_logic;

    gpio_i          : in    std_logic_vector( 31 downto 0 );
    gpio_o          : out   std_logic_vector( 31 downto 0 );
    gpio_t          : out   std_logic_vector( 31 downto 0 );

    tmds_maxi_mosi  : out   axi4_mosi_a32d32_t;
    tmds_maxi_miso  : in    axi4_miso_a32d32_t;
    tmds_saxis_mosi : in    axi4s_mosi_64_t;
    tmds_saxis_miso : out   axi4s_miso_64_t

  );
end entity tmds_cap_z7ps;

architecture wrapper of tmds_cap_z7ps is

  -- block diagram
  component tmds_cap_z7ps_sys
    port (

      axi_clk           : out   std_logic;
      axi_rst_n         : out   std_logic_vector(  0 downto 0 );

      gpio_tri_i        : in    std_logic_vector( 31 downto 0 );
      gpio_tri_o        : out   std_logic_vector( 31 downto 0 );
      gpio_tri_t        : out   std_logic_vector( 31 downto 0 );

      tmds_maxi_awaddr  : out   std_logic_vector( 31 downto 0 );
      tmds_maxi_awlen   : out   std_logic_vector(  7 downto 0 );
      tmds_maxi_awsize  : out   std_logic_vector(  2 downto 0 );
      tmds_maxi_awburst : out   std_logic_vector(  1 downto 0 );
      tmds_maxi_awlock  : out   std_logic_vector(  0     to 0 );
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
      tmds_maxi_arlock  : out   std_logic_vector(  0     to 0 );
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
      tmds_saxis_tready : out   std_logic

    );
  end component tmds_cap_z7ps_sys;

begin

  U_BD: component tmds_cap_z7ps_sys
    port map (

      axi_clk             => axi_clk,
      axi_rst_n(0)        => axi_rst_n,

      gpio_tri_i          => gpio_i,
      gpio_tri_o          => gpio_o,
      gpio_tri_t          => gpio_t,

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
      tmds_saxis_tready   => tmds_saxis_miso.tready

    );

end architecture wrapper;
