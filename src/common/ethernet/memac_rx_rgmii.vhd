--------------------------------------------------------------------------------
-- memac_rx_rgmii.vhd                                                         --
-- Modular Ethernet MAC (MEMAC): receive GMII to UMI shim.                    --
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

package memac_rx_rgmii_pkg is

  component memac_rx_rgmii is
    port (
      rst          : in    std_logic;
      mac_rx_clk   : out   std_logic;
      mac_rx_dv    : out   std_logic;
      mac_rx_er    : out   std_logic;
      mac_rx_d     : out   std_logic_vector(7 downto 0);
      rgmii_rx_clk : in    std_logic;
      rgmii_rx_ctl : in    std_logic;
      rgmii_rx_d   : in    std_logic_vector(3 downto 0)
    );
  end component memac_rx_rgmii;

end package memac_rx_rgmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.iddr_pkg.all;

entity memac_rx_rgmii is
  port (
    rst          : in    std_logic;
    mac_rx_clk   : out   std_logic;
    mac_rx_dv    : out   std_logic;
    mac_rx_er    : out   std_logic;
    mac_rx_d     : out   std_logic_vector(7 downto 0);
    rgmii_rx_clk : in    std_logic;
    rgmii_rx_ctl : in    std_logic;
    rgmii_rx_d   : in    std_logic_vector(3 downto 0)
  );
end entity memac_rx_rgmii;

architecture synth of memac_rx_rgmii is

  signal rgmii_rx_ctl_r : std_logic;
  signal rgmii_rx_ctl_f : std_logic;

begin

  -- centre aligned clocking

  U_IDDR_CTL : iddr
    port map (rst,rgmii_rx_clk,rgmii_rx_ctl,rgmii_rx_ctl_r,rgmii_rx_ctl_f);

  mac_dv <= rgmii_rx_ctl_r;
  mac_er <= rgmii_rx_ctl_r xor rgmii_rx_ctl_f;

  GEN_D: for i in 0 to 3 generate
    U_IDDR_D : IDDR
      port map (rst,rgmii_rx_clk,rgmii_rx_d(i),mac_rx_d(i),mac_rx_d(4+i));
  end generate GEN_D;

end architecture synth;
