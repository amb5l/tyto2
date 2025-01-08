--------------------------------------------------------------------------------
-- memac_sim_rmii_pkg.vhd                                                     --
-- MEMAC simulation support package for RMII                                  --
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

package memac_sim_rmii_pkg is

  constant RMII_CLK_PERIOD : time := 20 ns;

end package memac_sim_rmii_pkg;

context memac_sim_rmii_rx_ctx is

  library memac;
    use memac.memac_pkg.all;
    use memac.memac_rmii_pkg.all;
    use memac.memac_rmii_clk_pkg.all;
    use memac.memac_rx_rmii_pkg.all;
    use memac.memac_sim_pkg.all;
    use memac.memac_sim_rmii_pkg.all;

  library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

end context memac_sim_rmii_rx_ctx;
