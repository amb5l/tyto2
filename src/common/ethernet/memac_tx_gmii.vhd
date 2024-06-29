--------------------------------------------------------------------------------
-- memac_tx_gmii.vhd                                                          --
-- Modular Ethernet MAC (MEMAC): transmit UMI to GMII shim.                   --
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

package memac_tx_gmii_pkg is

  component memac_tx_gmii is
    port (
        clk_125m  : in    std_ulogic;
        rst       : in    std_ulogic;
        umi_spd   : in    std_ulogic_vector(1 downto 0);
        umi_clk   : out   std_ulogic;
        umi_dv    : in    std_ulogic;
        umi_er    : in    std_ulogic;
        umi_d     : in    std_ulogic_vector(7 downto 0);
        gmii_clko : out   std_ulogic;                    -- GMII gtxclk
        gmii_clki : in    std_ulogic;                    -- MII txclk
        gmii_dv   : out   std_ulogic;
        gmii_er   : out   std_ulogic;
        gmii_d    : out   std_ulogic_vector(7 downto 0)
    );
  end component memac_tx_gmii;

end package memac_tx_gmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity memac_tx_gmii is
  port (
    clk_125m  : in    std_ulogic;
    rst       : in    std_ulogic;
    umi_spd   : in    std_ulogic_vector(1 downto 0);
    umi_clk   : out   std_ulogic;
    umi_dv    : in    std_ulogic;
    umi_er    : in    std_ulogic;
    umi_d     : in    std_ulogic_vector(7 downto 0);
    gmii_clko : out   std_ulogic;                    -- GMII gtxclk
    gmii_clki : in    std_ulogic;                    -- MII txclk
    gmii_dv   : out   std_ulogic;
    gmii_er   : out   std_ulogic;
    gmii_d    : out   std_ulogic_vector(7 downto 0)
  );
end entity memac_tx_gmii;

architecture synth of memac_tx_gmii is

  signal umi_dv_r : std_ulogic;
  signal umi_er_r : std_ulogic;
  signal umi_d_r  : std_ulogic_vector(7 downto 0);

begin

  umi_clk <= clk_125m when umi_spd(1) = '1' else gmii_clki;

  process(rst,umi_clk)
  begin
    if rst = '1' then
      gmii_clko <= '0';
      gmii_dv   <= '0';
      gmii_er   <= '0';
      gmii_d    <= (others => '0');
    elsif rising_edge(umi_clk) then
      umi_dv_r <= umi_dv;
      umi_er_r <= umi_er;
      umi_d_r  <= umi_d;
      gmii_clko <= '0';
      gmii_dv   <= umi_dv_r;
      gmii_er   <= umi_er_r;
      gmii_d    <= umi_d_r;
    elsif falling_edge(umi_clk) then
      gmii_clko <= umi_spd(1);
    end if;
  end process;

end architecture synth;
