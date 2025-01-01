--------------------------------------------------------------------------------
-- memac_tx_rmii.vhd                                                          --
-- Modular Ethernet MAC (MEMAC): transmit UMI to RMII shim.                   --
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

package memac_tx_rmii_pkg is

  component memac_tx_rmii is
    port (
      umii_rst   : in    std_ulogic;
      umii_clk   : out   std_ulogic;
      umii_clken : out   std_ulogic;
      umii_dv    : in    std_ulogic;
      umii_er    : in    std_ulogic;
      umii_d     : in    std_ulogic_vector(7 downto 0);
      rmii_clk   : in    std_ulogic;
      rmii_en    : out   std_ulogic;
      rmii_d     : out   std_ulogic_vector(1 downto 0)
    );
  end component memac_tx_rmii;

end package memac_tx_rmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_tx_rmii is
  port (
    umii_rst   : in    std_ulogic;
    umii_clk   : out   std_ulogic;
    umii_clken : out   std_ulogic;
    umii_dv    : in    std_ulogic;
    umii_er    : in    std_ulogic;
    umii_d     : in    std_ulogic_vector(7 downto 0);
    rmii_clk   : in    std_ulogic;
    rmii_en    : out   std_ulogic;
    rmii_d     : out   std_ulogic_vector(1 downto 0)
  );
end entity memac_tx_rmii;

architecture rtl of memac_tx_rmii is

begin

end architecture rtl;
