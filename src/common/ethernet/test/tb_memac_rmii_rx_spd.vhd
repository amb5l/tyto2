--------------------------------------------------------------------------------
-- tb_memac_rmi_rx_spd.vhd                                                    --
-- Modular Ethernet MAC: testbench for memac_rmi_rx_spd.                      --
--------------------------------------------------------------------------------
-- (C) Copyright 2025 Adam Barnes <ambarnes@gmail.com>                        --
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

entity tb_memac_rmii_rx_spd is
end entity tb_memac_rmii_rx_spd;

use work.memac_rmii_rx_spd_pkg.all;

architecture sim of tb_memac_rmii_rx_spd is

  signal rst      : std_ulogic;
  signal clk      : std_ulogic;
  signal i_crs_dv : std_ulogic;
  signal i_er     : std_ulogic;
  signal i_d      : std_ulogic_vector(1 downto 0);
  signal o_crs_dv : std_ulogic;
  signal o_er     : std_ulogic;
  signal o_d      : std_ulogic_vector(1 downto 0);
  signal stb      : std_ulogic;
  signal spd      : std_ulogic;

begin

  DUT: component memac_rmii_rx_spd
    port map (
      rst      => rst,
      clk      => clk,
      i_crs_dv => i_crs_dv,
      i_er     => i_er,
      i_d      => i_d,
      o_crs_dv => o_crs_dv,
      o_er     => o_er,
      o_d      => o_d,
      stb      => stb,
      spd      => spd
    );

end architecture sim;

--------------------------------------------------------------------------------
-- configurations

configuration cfg_tb_memac_rmii_behavioural of tb_memac_rmii_rx_spd is
  for sim
    for DUT: memac_rmii_rx_spd
      use entity memac.memac_rmii_rx(rtl);
    end for;
  end for;
end configuration cfg_tb_memac_rmii_behavioural;

configuration cfg_tb_memac_rmii_post_syn_func of tb_memac_rmii_rx_spd is
  for sim
    for DUT: memac_rmii_rx
      use entity work.memac_rmii_rx(STRUCTURE);
    end for;
  end for;
end configuration cfg_tb_memac_rmii_post_syn_func;


--------------------------------------------------------------------------------