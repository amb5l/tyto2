--------------------------------------------------------------------------------
-- memac_rx_gmii.vhd                                                          --
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

package memac_rx_gmii_pkg is

  component memac_rx_gmii is
    port (
      rst      : in    std_ulogic;
      umi_clk  : out   std_ulogic;
      umi_dv   : out   std_ulogic;
      umi_er   : out   std_ulogic;
      umi_d    : out   std_ulogic_vector(7 downto 0);
      gmii_clk : in    std_ulogic;
      gmii_dv  : in    std_ulogic;
      gmii_er  : in    std_ulogic;
      gmii_d   : in    std_ulogic_vector(7 downto 0)
    );
  end component memac_rx_gmii;

end package memac_rx_gmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity memac_rx_gmii is
  port (
    rst      : in    std_ulogic;
    umi_clk  : out   std_ulogic;
    umi_dv   : out   std_ulogic;
    umi_er   : out   std_ulogic;
    umi_d    : out   std_ulogic_vector(7 downto 0);
    gmii_clk : in    std_ulogic;
    gmii_dv  : in    std_ulogic;
    gmii_er  : in    std_ulogic;
    gmii_d   : in    std_ulogic_vector(7 downto 0)
  );
end entity memac_rx_gmii;

architecture synth of memac_rx_gmii is

begin

  umi_clk <= gmii_clk;

  P_MAIN: process(rst,gmii_clk)
  begin
    if rst = '1' then
      umi_dv <= '0';
      umi_er <= '0';
      umi_d  <= (others => '0');
    elsif rising_edge(gmii_clk) then
      umi_dv <= gmii_dv;
      umi_er <= gmii_er;
      umi_d  <= gmii_d;
    end if;
  end process P_MAIN;

end architecture synth;
