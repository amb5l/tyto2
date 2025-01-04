--------------------------------------------------------------------------------
-- memac_rmii_pkg.vhd                                                         --
-- Modular Ethernet MAC: RMII types and constants.                            --
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

library ieee;
  use ieee.std_logic_1164.all;

package memac_rmii_pkg is

  type rmii_rx_t is record
    spd    : std_logic;
    clk    : std_logic;
    crs_dv : std_logic;
    er     : std_logic;
    d      : std_logic_vector(1 downto 0);
  end record rmii_rx_t;

  type rmii_rx_dibit_t is record
    crs_dv : std_logic;
    er     : std_logic;
    d      : std_logic_vector(1 downto 0);
  end record rmii_rx_dibit_t;

  type rmii_tx_t is record
    spd   : std_logic;
    clk   : std_logic;
    en    : std_logic;
    d     : std_logic_vector(1 downto 0);
  end record rmii_tx_t;

  constant RMII_CLK_PERIOD : time := 20 ns;

end package memac_rmii_pkg;
