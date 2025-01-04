--------------------------------------------------------------------------------
-- memac_rx_rmii_vhd                                                          --
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

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package memac_rx_rmii_pkg is

  component memac_rx_rmii is
    port (
      rst         : in    std_ulogic;
      clk         : in    std_ulogic;
      rmii_spd    : in    std_ulogic;
      rmii_crs_dv : in    std_ulogic;
      rmii_er     : in    std_ulogic;
      rmii_d      : in    std_ulogic_vector(1 downto 0);
      umii_clken  : out   std_ulogic;
      umii_dv     : out   std_ulogic_vector(1 downto 0);
      umii_er     : out   std_ulogic_vector(1 downto 0);
      umii_d      : out   std_ulogic_vector(7 downto 0)
    );
  end component memac_rx_rmii;

end package memac_rx_rmii_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_rx_rmii is
  port (
    rst         : in    std_ulogic;
    clk         : in    std_ulogic;
    rmii_spd    : in    std_ulogic;
    rmii_crs_dv : in    std_ulogic;
    rmii_er     : in    std_ulogic;
    rmii_d      : in    std_ulogic_vector(1 downto 0);
    umii_clken  : out   std_ulogic;
    umii_dv     : out   std_ulogic_vector(1 downto 0);
    umii_er     : out   std_ulogic_vector(1 downto 0);
    umii_d      : out   std_ulogic_vector(7 downto 0)
  );
end entity memac_rx_rmii;

architecture rtl of memac_rx_rmii is

  signal rmii_count : integer range 0 to 9;
  signal rmii_clken : std_ulogic;

  signal s0_crs_dv : std_ulogic;
  signal s0_er     : std_ulogic;
  signal s0_d      : std_ulogic_vector(1 downto 0);

  signal s1_crs_dv : std_ulogic;
  signal s1_er     : std_ulogic;
  signal s1_d      : std_ulogic_vector(1 downto 0);
  signal s1_dibit  : std_ulogic;                    -- dibit ID, 0 = 1st, 1 = 2nd
  signal s1_dvx    : std_ulogic;                    -- DV, extended by 1 cycle

  signal s2_crs    : std_ulogic;                    -- recovered CRS
  signal s2_crl    : std_ulogic;                    -- carrier loss prevents spurious CRS
  signal s2_dv     : std_ulogic;                    -- recovered DV
  signal s2_er     : std_ulogic;
  signal s2_d      : std_ulogic_vector(1 downto 0);
  signal s2_dibit  : std_ulogic;                    -- dibit ID  } 0 = lower, 1 = upper
  signal s2_nybble : std_ulogic;                    -- nybble ID }
  signal s2_ipg    : std_ulogic;                    -- inter packet gap

  signal s3_clken  : std_ulogic;
  signal s3_dv     : std_ulogic_vector(1 downto 0);
  signal s3_er     : std_ulogic_vector(1 downto 0);
  signal s3_d      : std_ulogic_vector(7 downto 0);

begin

  s0_crs_dv <= rmii_crs_dv;
  s0_er     <= rmii_er;
  s0_d      <= rmii_d;

  P_MAIN: process(rst, clk)
  begin
    if rst then

      rmii_count  <= 0;
      rmii_clken  <= '0';

      s1_crs_dv   <= '0';
      s1_er       <= '0';
      s1_d        <= (others => '0');
      s1_dibit    <= '0';
      s1_dvx      <= '0';

      s2_crs      <= '0';
      s2_crl      <= '0';
      s2_dv       <= '0';
      s2_er       <= '0';
      s2_d        <= (others => '0');
      s2_dibit    <= '0';
      s2_nybble   <= '0';
      s2_ipg      <= '0';

      s3_clken    <= '0';
      s3_dv       <= (others => '0');
      s3_er       <= (others => '0');
      s3_d        <= (others => '0');

      umii_clken  <= '0';
      umii_dv     <= (others => '0');
      umii_er     <= (others => '0');
      umii_d      <= (others => '0');

    elsif rising_edge(clk) then

      rmii_clken <= '0';
      if rmii_spd = '1' then
        rmii_count <= 0;
        rmii_clken <= '1';
      elsif rmii_spd = '0' then
        if rmii_count = 9 then
          rmii_count <= 0;
          rmii_clken <= '1';
        else
          rmii_count <= rmii_count + 1;
        end if;
      end if;

      umii_clken <= '0';
      if rmii_clken then

        -- TODO: handle false carrier (d = "10" at start of frame)

        s1_crs_dv <= s0_crs_dv;
        s1_er     <= s0_er;
        s1_d      <= s0_d;
        s1_dibit <=
          '0' when s1_dvx = '0' else
          '1' when s1_dibit = '0' and s1_crs_dv = '1';
        s1_dvx <=
          '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
          '1' when s1_dvx = '0' and s0_crs_dv = '1' and s0_d = "01";

        s2_crs <=
          '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
          '1' when s1_crs_dv = '1' and s2_crl = '0' else
          '0' when s2_crs = '1' and s1_crs_dv = '0' and s1_dibit = '0';
        s2_crl <=
          '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
          '1' when s2_crs = '1' and s1_crs_dv = '0' and s1_dibit = '0' else
          '0' when s2_crs = '1' and s1_crs_dv = '0' and s1_dibit = '0';
        s2_dv <=
          '0' when s0_crs_dv = '0' and s1_crs_dv = '0' else
          '1' when s2_dv = '0' and s1_crs_dv = '1' and s1_d = "01" else
          '0' when s2_dv = '1' and s0_crs_dv = '0' and s1_crs_dv = '0';
        s2_er     <= s1_er;
        s2_d      <= s1_d;
        s2_dibit  <=
          '0' when s1_dvx = '1' and s2_dv = '0' else
          not s2_dibit when s2_dv = '1' or s2_ipg = '1';
        s2_nybble <=
          '0' when s1_dvx = '1' and s2_dv = '0' else
          not s2_nybble when s2_dibit = '1' and (s2_dv = '1' or s2_ipg = '1');
        s2_ipg <=
          '1' when s2_dv = '1' and s1_crs_dv = '0' and s0_crs_dv = '0' else
          '0' when s2_ipg = '1' and s1_crs_dv = '1' and s1_d = "01";


        s3_clken         <= s2_nybble and s2_dibit;
        s3_dv(0)         <= s2_dv  when s2_nybble = '0';
        s3_dv(1)         <= s2_dv  when s2_nybble = '1';
        s3_er(0)         <= s2_er  when s2_nybble = '0';
        s3_er(1)         <= s2_er  when s2_nybble = '1';
        s3_d(1 downto 0) <= s2_d when s2_nybble = '0' and s2_dibit = '0';
        s3_d(3 downto 2) <= s2_d when s2_nybble = '0' and s2_dibit = '1';
        s3_d(5 downto 4) <= s2_d when s2_nybble = '1' and s2_dibit = '0';
        s3_d(7 downto 6) <= s2_d when s2_nybble = '1' and s2_dibit = '1';

        umii_clken <= s3_clken;
        umii_dv    <= s3_dv when s3_clken;
        umii_er    <= s3_er when s3_clken;
        umii_d     <= s3_d  when s3_clken;

      end if;

    end if;
  end process P_MAIN;

end architecture rtl;
