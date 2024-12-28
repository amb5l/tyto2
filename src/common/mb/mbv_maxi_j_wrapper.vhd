--------------------------------------------------------------------------------
-- mbv_maxi_j_wrapper.vhd                                                     --
-- Wrapper for the mb_mcs block diagram.                                      --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

use work.tyto_types_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

use work.axi_pkg.all;

package mbv_maxi_j_wrapper_pkg is

  component mbv_maxi_j_wrapper is
    port (
      rst      : in  std_ulogic;
      clk      : in  std_ulogic;
      arst_n   : out std_ulogic;
      axi4l_mo : out axi4l_a32d32_mosi_t;
      axi4l_mi : in  axi4l_a32d32_miso_t
    );
  end component mbv_maxi_j_wrapper;

end package mbv_maxi_j_wrapper_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.axi_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity mbv_maxi_j_wrapper is
  port (
    rst      : in  std_ulogic;
    clk      : in  std_ulogic;
    arst_n   : out std_ulogic;
    axi4l_mo : out axi4l_a32d32_mosi_t;
    axi4l_mi : in  axi4l_a32d32_miso_t
  );
end entity mbv_maxi_j_wrapper;

architecture rtl of mbv_maxi_j_wrapper is

  -- matches the block diagram created by "mbv_maxi_j.tcl"
  component mbv_maxi_j is
    port (
      clk          : in  std_logic;
      rst_n        : in  std_logic;
      arst_n       : out std_logic_vector ( 0      to 0 );
      maxi_awaddr  : out std_logic_vector ( 31 downto 0 );
      maxi_awprot  : out std_logic_vector (  2 downto 0 );
      maxi_awvalid : out std_logic_vector (  0     to 0 );
      maxi_awready : in  std_logic_vector (  0     to 0 );
      maxi_wdata   : out std_logic_vector ( 31 downto 0 );
      maxi_wstrb   : out std_logic_vector (  3 downto 0 );
      maxi_wvalid  : out std_logic_vector (  0     to 0 );
      maxi_wready  : in  std_logic_vector (  0     to 0 );
      maxi_bresp   : in  std_logic_vector (  1 downto 0 );
      maxi_bvalid  : in  std_logic_vector (  0     to 0 );
      maxi_bready  : out std_logic_vector (  0     to 0 );
      maxi_araddr  : out std_logic_vector ( 31 downto 0 );
      maxi_arprot  : out std_logic_vector (  2 downto 0 );
      maxi_arvalid : out std_logic_vector (  0     to 0 );
      maxi_arready : in  std_logic_vector (  0     to 0 );
      maxi_rdata   : in  std_logic_vector ( 31 downto 0 );
      maxi_rresp   : in  std_logic_vector (  1 downto 0 );
      maxi_rvalid  : in  std_logic_vector (  0     to 0 );
      maxi_rready  : out std_logic_vector (  0     to 0 )
    );
  end component mbv_maxi_j;

begin

  CPU: component mbv_maxi_j
    port map (
      rst_n           => not rst,
      clk             => clk,
      arst_n(0)       => arst_n,
      maxi_awaddr     => axi4l_mo.awaddr,
      maxi_awprot     => axi4l_mo.awprot,
      maxi_awvalid(0) => axi4l_mo.awvalid,
      maxi_awready(0) => axi4l_mi.awready,
      maxi_wdata      => axi4l_mo.wdata,
      maxi_wstrb      => axi4l_mo.wstrb,
      maxi_wvalid(0)  => axi4l_mo.wvalid,
      maxi_wready(0)  => axi4l_mi.wready,
      maxi_bresp      => axi4l_mi.bresp,
      maxi_bvalid(0)  => axi4l_mi.bvalid,
      maxi_bready(0)  => axi4l_mo.bready,
      maxi_araddr     => axi4l_mo.araddr,
      maxi_arprot     => axi4l_mo.arprot,
      maxi_arvalid(0) => axi4l_mo.arvalid,
      maxi_arready(0) => axi4l_mi.arready,
      maxi_rdata      => axi4l_mi.rdata,
      maxi_rresp      => axi4l_mi.rresp,
      maxi_rvalid(0)  => axi4l_mi.rvalid,
      maxi_rready(0)  => axi4l_mo.rready
    );

end architecture rtl;

