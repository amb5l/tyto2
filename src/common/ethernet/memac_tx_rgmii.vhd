--------------------------------------------------------------------------------
-- memac_tx_rgmii.vhd                                                         --
-- MEMAC transmit RGMII shim.                                                 --
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

package memac_tx_rgmii_pkg is

  component memac_tx_rgmii is
    port (
      rst          : in    std_logic;
      mac_tx_clk   : in    std_logic;
      mac_tx_ce    : in    std_logic;
      mac_tx_en    : in    std_logic;
      mac_tx_er    : in    std_logic;
      mac_tx_d     : in    std_logic_vector(7 downto 0);
      rgmii_tx_clk : out   std_logic;
      rgmii_tx_ctl : out   std_logic;
      rgmii_tx_d   : out   std_logic_vector(3 downto 0)
    );
  end component memac_tx_rgmii;

end package memac_tx_rgmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.iddr_pkg.all;

entity memac_tx_rgmii is
  port (
    rst          : in    std_logic;
    mac_tx_clk   : in    std_logic;
    mac_tx_ce    : in    std_logic;
    mac_tx_en    : in    std_logic;
    mac_tx_er    : in    std_logic;
    mac_tx_d     : in    std_logic_vector(7 downto 0);
    rgmii_tx_clk : out   std_logic;
    rgmii_tx_ctl : out   std_logic;
    rgmii_tx_d   : out   std_logic_vector(3 downto 0)
  );
end entity memac_tx_rgmii;

architecture synth of memac_tx_rgmii is
begin

  -- edge aligned clocking

  U_ODDR_CLK : oddr
    port map (rst,mac_tx_clk,mac_tx_ce,'1','0',rgmii_tx_ctl);

  U_ODDR_CTL : oddr
    port map (rst,mac_tx_clk,mac_tx_ce,mac_tx_en,mac_tx_en xor mac_tx_er,rgmii_tx_ctl);

  GEN_D: for i in 0 to 3 generate
    U_ODDR_D : oddr
      port map (rst,mac_tx_clk,mac_tx_ce,mac_tx_d(i),mac_tx_d(4+i),rgmii_tx_d(i));
  end generate GEN_D;

end architecture synth;
