--------------------------------------------------------------------------------
-- memac_rx_rmii.vhd                                                          --
-- Modular Ethernet MAC (MEMAC): receive RMII to UMI shim.                    --
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
-- speed detection:
-- wait for preamble
-- count 01 occurrences
-- wait for SFD - last di-bit duration indicates link speed


library ieee;
  use ieee.std_logic_1164.all;

package memac_rx_rmii_pkg is

  component memac_rx_rmii is
    port (
      rst         : in    std_ulogic;
      clk         : out   std_ulogic;
      spd         : in    std_ulogic;
      umi_clken   : out   std_ulogic;
      umi_dv      : out   std_ulogic;
      umi_er      : out   std_ulogic;
      umi_d       : out   std_ulogic_vector(7 downto 0);
      rmii_clk    : in    std_ulogic;
      rmii_crs_dv : in    std_ulogic;
      rmii_er     : in    std_ulogic;
      rmii_d      : in    std_ulogic_vector(1 downto 0)
    );
  end component memac_rx_rmii;

end package memac_rx_rmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity memac_rx_rmii is
  port (
    rst         : in    std_ulogic;                    -- reset
    clk         : out   std_ulogic;                    -- 50MHz
    spd         : in    std_ulogic;                    -- link speed: 0 = 10Mbps, 1 = 100Mbps
    umi_clken   : out   std_ulogic;                    -- UMI clock enable
    umi_crs     : out   std_ulogic;                    -- UMI carrier sense
    umi_dv      : out   std_ulogic;
    umi_er      : out   std_ulogic;
    umi_d       : out   std_ulogic_vector(7 downto 0);
    rmii_clk    : in    std_ulogic;
    rmii_crs_dv : in    std_ulogic;
    rmii_er     : in    std_ulogic;
    rmii_d      : in    std_ulogic_vector(1 downto 0)
  );
end entity memac_rx_rmii;

architecture rtl of memac_rx_rmii is

  -- input pipeline

  signal s0_crs_dv   : std_ulogic;
  signal s0_er       : std_ulogic;
  signal s0_d        : std_ulogic_vector(1 downto 0);

  signal s1_crs_dv   : std_ulogic;
  signal s1_er       : std_ulogic;
  signal s1_d        : std_ulogic_vector(1 downto 0);
  signal s1_dibit    : std_ulogic;                    -- dibit ID, 0 = 1st, 1 = 2nd
  signal s1_dvx      : std_ulogic;                    -- DV, extended by 1 cycle

  signal s2_crs      : std_ulogic;                    -- recovered CRS
  signal s2_dv       : std_ulogic;                    -- recovered DV
  signal s2_er       : std_ulogic;
  signal s2_d        : std_ulogic_vector(1 downto 0);
  signal s2_dibit    : std_ulogic;                    -- dibit ID  } 0 = lower, 1 = upper
  signal s2_nibble   : std_ulogic;                    -- nibble ID }

begin

  s0_crs_dv <= rmii_crs_dv;
  s0_er     <= rmii_er;
  s0_d      <= rmii_d;


  --P_CRS_DV_SEPARATE:


  P_MAIN: process(rst,clk)
  begin
    if rst then

      s1_crs_dv  <= '0';
      s1_er      <= '0';
      s1_d       <= (others => '0');
      s1_dibit <= '0';
      s1_dvx     <= '0';
      s2_crs     <= '0';
      s2_dv      <= '0';
      s2_er      <= '0';
      s2_d       <= (others => '0');
      s2_dibit <= '0';

    elsif rising_edge(clk) then

      s1_crs_dv <= s0_crs_dv;
      s1_er     <= s0_er;
      s1_d      <= s0_d;
      s1_dibit <=
        '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
        '1' when s1_dibit = '0' and s1_dvx = '1' else
        '0';
      s1_dvx <=
        '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
        '1' when s1_dvx = '0' and s0_crs_dv = '1' and s1_d = "01";

      s2_crs <=
        '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
        '1' when s2_crs = '0' and s2_dv = '0' and s1_crs_dv = '1' and s1_d = "01" else
        '0' when s2_crs = '1' and s1_crs_dv = '0' and s1_dibit = '0';
      s2_dv <=
        '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
        '1' when s2_dv = '0' and s1_crs_dv = '1' and s1_d = "01" else
        '0' when s2_dv = '1' and s0_crs_dv = '0' and s1_crs_dv = '0';

      s2_er      <= s1_er;
      s2_d       <= s1_d;
      s2_dibit <= s1_dibit;
      s2_nibble <= '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
                   not s2_nibble when s2_dibit;


      umi_dv <= s2_dv and s2_nibble and s2_dibit;
      umi_er <= s2_er;
      umi_d(1 downto 0) <= s2_d when s2_nibble = '0' and s2_dibit = '0';
      umi_d(3 downto 2) <= s2_d when s2_nibble = '0' and s2_dibit = '1';
      umi_d(5 downto 4) <= s2_d when s2_nibble = '1' and s2_dibit = '0';
      umi_d(7 downto 6) <= s2_d when s2_nibble = '1' and s2_dibit = '1';

      -- packet starts at leading edge of DV



    end if;
  end process P_MAIN;


end architecture rtl;
