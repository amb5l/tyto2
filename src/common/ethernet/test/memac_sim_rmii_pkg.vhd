--------------------------------------------------------------------------------
-- memac_sim_rmii_pkg.vhd                                                     --
-- MEMAC simulation support package for RMII                                  --
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

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

package memac_sim_rmii_pkg is

  procedure sim_tx_rmii_rx_clk(signal rmii : in rmii_rx_t);
  procedure sim_tx_rmii_rx_dibit(signal rmii : inout rmii_rx_t; s : in rmii_rx_dibit_t);
  procedure sim_tx_rmii_rx_dibit(signal rmii : inout rmii_rx_t; s : in rmii_rx_dibit_t; n : natural);
  procedure sim_tx_rmii_rx_octet(signal rmii : inout rmii_rx_t; s : in umii_octet_t; crs : in std_ulogic_vector(1 downto 0));
  procedure sim_tx_rmii_rx_octet(signal rmii : inout rmii_rx_t; s : in umii_octet_t; crs : in std_ulogic_vector(1 downto 0); n : natural);

end package memac_sim_rmii_pkg;

package body memac_sim_rmii_pkg is

  procedure sim_tx_rmii_rx_clk(signal rmii : in rmii_rx_t) is
    variable n : natural;
  begin
    assert rmii.spd = '0' or rmii.spd = '1'
      report "sim_tx_rmii_rx_clk: invalid spd" severity failure;
    n := 1 when rmii.spd = '1' else 10;
    for i in 1 to n loop
      wait until rising_edge(rmii.clk);
    end loop;
  end procedure sim_tx_rmii_rx_clk;

  procedure sim_tx_rmii_rx_dibit(signal rmii : inout rmii_rx_t; s : in rmii_rx_dibit_t) is
  begin
    sim_tx_rmii_rx_clk(rmii);
    rmii.crs_dv <= s.crs_dv;
    rmii.er     <= s.er;
    rmii.d      <= s.d;
  end procedure sim_tx_rmii_rx_dibit;

  procedure sim_tx_rmii_rx_dibit(signal rmii : inout rmii_rx_t; s : in rmii_rx_dibit_t; n : natural) is
  begin
    if n > 0 then
      for i in 1 to n loop
        sim_tx_rmii_rx_dibit(rmii, s);
      end loop;
    end if;
  end procedure sim_tx_rmii_rx_dibit;

  procedure sim_tx_rmii_rx_octet(signal rmii : inout rmii_rx_t; s : in umii_octet_t; crs : in std_ulogic_vector(1 downto 0)) is
  begin
    sim_tx_rmii_rx_dibit(rmii, (crs_dv => crs(0),  er => s.er(0), d => s.d(1 downto 0)));
    sim_tx_rmii_rx_dibit(rmii, (crs_dv => s.dv(0), er => s.er(0), d => s.d(3 downto 2)));
    sim_tx_rmii_rx_dibit(rmii, (crs_dv => crs(1),  er => s.er(1), d => s.d(5 downto 4)));
    sim_tx_rmii_rx_dibit(rmii, (crs_dv => s.dv(1), er => s.er(1), d => s.d(7 downto 6)));
  end procedure sim_tx_rmii_rx_octet;

  procedure sim_tx_rmii_rx_octet(signal rmii : inout rmii_rx_t; s : in umii_octet_t; crs : in std_ulogic_vector(1 downto 0); n : natural) is
  begin
    if n > 0 then
      for i in 1 to n loop
        sim_tx_rmii_rx_octet(rmii, s, crs);
      end loop;
    end if;
  end procedure sim_tx_rmii_rx_octet;

end package body memac_sim_rmii_pkg;

context memac_sim_rmii_ctx is

  library memac;
    use memac.memac_pkg.all;
    use memac.memac_rmii_pkg.all;
    use memac.memac_rx_rmii_pkg.all;
    use memac.memac_tx_rmii_pkg.all;
    use memac.memac_sim_pkg.all;
    use memac.memac_sim_rmii_pkg.all;

  library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

end context memac_sim_rmii_ctx;
