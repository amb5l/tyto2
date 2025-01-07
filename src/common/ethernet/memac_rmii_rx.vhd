--------------------------------------------------------------------------------
-- memac_rmii_rx.vhd                                                          --
-- Modular Ethernet MAC (MEMAC): receive RMII to UMI shim.                    --
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
-- TODO: ASYNC_REG constraints for crs_dv stages 1-3

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package memac_rmii_rx_pkg is

  component memac_rmii_rx is
    port (
      rst          : in    std_ulogic;
      clk          : in    std_ulogic;
      rmii_clken   : in    std_ulogic;
      rmii_crs_dv  : in    std_ulogic;
      rmii_er      : in    std_ulogic;
      rmii_d       : in    std_ulogic_vector(1 downto 0);
      umii_clken   : in    std_ulogic;
      umii_dv      : out   std_ulogic;
      umii_er      : out   std_ulogic;
      umii_d       : out   std_ulogic_vector(7 downto 0);
      dbg_crs_dv   : out   std_ulogic_vector(3 downto 0);
      dbg_er       : out   std_ulogic_vector(3 downto 0)
    );
  end component memac_rmii_rx;

end package memac_rmii_rx_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;
use work.memac_rmii_rx_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_rmii_rx is
  port (
    rst          : in    std_ulogic;
    clk          : in    std_ulogic;
    rmii_clken   : in    std_ulogic;
    rmii_crs_dv  : in    std_ulogic;
    rmii_er      : in    std_ulogic;
    rmii_d       : in    std_ulogic_vector(1 downto 0);
    umii_clken   : in    std_ulogic;
    umii_dv      : out   std_ulogic;
    umii_er      : out   std_ulogic;
    umii_d       : out   std_ulogic_vector(7 downto 0);
    dbg_crs      : out   std_ulogic_vector(3 downto 0); -- } for verification
    dbg_dv       : out   std_ulogic_vector(3 downto 0); -- }
    dbg_er       : out   std_ulogic_vector(3 downto 0)  -- }
  );
end entity memac_rmii_rx;

architecture rtl of memac_rmii_rx is

  type s_0_4_t is record -- input and first 4 pipeline stages
    crs_dv : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
  end record;

  type s_5_t is record -- CRS and DV separated
    act    : std_ulogic;
    crs    : std_ulogic;
    dv     : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
    dibit  : std_ulogic_vector(1 downto 0);
  end record;

  type s_6_t is record -- octet assembly
    crs_dv : std_ulogic;
    stb    : std_ulogic;
    crs    : std_ulogic_vector(3 downto 0);
    dv     : std_ulogic_vector(3 downto 0);
    er     : std_ulogic_vector(3 downto 0);
    d      : std_ulogic_vector(7 downto 0);
  end record;

  type s_7_t is record -- clean octets
    crs   : std_ulogic_vector(3 downto 0);
    dv    : std_ulogic_vector(3 downto 0);
    er    : std_ulogic_vector(3 downto 0);
    d     : std_ulogic_vector(7 downto 0);
  end record;

  -- pipeline stages
  signal s0    : s_0_4_t; -- alias for input
  signal s1    : s_0_4_t;
  signal s2    : s_0_4_t;
  signal s3    : s_0_4_t;
  signal s4    : s_0_4_t;
  signal s5    : s_5_t;
  signal s6    : s_6_t;
  signal s7    : s_7_t;

begin

  s0.crs_dv <= rmii_crs_dv;
  s0.er     <= rmii_er;
  s0.d      <= rmii_d;

  P_MAIN: process(rst, clk)

    variable i : integer range 0 to 3;

  begin
    if rst then

      s1.all  <= '0';
      s2.all  <= '0';
      s3.all  <= '0';
      s4.all  <= '0';
      s5.all  <= '0';
      s6.all  <= '0';
      s7.all  <= '0';
      umii_dv <= '0';
      umii_er <= '0';
      umii_d  <= (others => '0');
      dbg_crs <= (others => '0');
      dbg_dv  <= (others => '0');
      dbg_er  <= (others => '0');

    elsif rising_edge(clk) then

      -- momentary signals
      s6.stb <= '0';

      if rmii_clken = '1' then

        -- first 3 pipeline stages
        s1 <= s0;
        s2 <= s1;
        s3 <= s2; -- CRS_DV is non-metastable from here on
        s4 <= s3;

        -- stage 5: separate CRS and DV
        s5.act <=
          '0' when s3.crs_dv = '0' and s4.crs_dv = '0' else
          '1' when s4.crs_dv = '1' and s4.d /= "00";
        s5.crs <=
          '0' when s3.crs_dv = '0' and s4.crs_dv = '0' else
          '1' when s5.act = '0' and s4.crs_dv = '1' else
          '0' when s5.act = '1' and s4.crs_dv = '0';
        s5.dv <=
          '0' when s3.crs_dv = '0' and s4.crs_dv = '0' else
          '1' when s5.act = '0' and s4.crs_dv = '1' and s4.d = "01";
        s5.er <= s4.er;
        s5.d  <= s4.d;
        s5.dibit <=
          "00" when s3.crs_dv = '0' and s4.crs_dv = '0' else
          std_ulogic_vector(unsigned(s5.dibit) + 1) when s5.dv = '1';

        -- stage 6: assemble dibits into octets
        i := to_integer(unsigned(s5.dibit));
        s6.stb                   <= '1' when s5.dibit = "11" else '0';
        s6.crs(i)                <= s5.crs;
        s6.dv(i)                 <= s5.dv;
        s6.er(i)                 <= s5.er;
        s6.d(1+(i*2) downto i*2) <= s5.d;

      end if;

      -- stage 7: latch assembled octets
      if s6.stb then
        s7.crs    <= s6.crs;
        s7.dv     <= s6.dv;
        s7.er     <= s6.er;
        s7.d      <= s6.d;
      elsif umii_clken then
        s7.crs    <= (others => '0');
        s7.dv     <= (others => '0');
        s7.er     <= (others => '0');
        s7.d      <= (others => '0');
      end if;

      -- output signals
      if umii_clken then
        umii_dv <= s7.dv(3) and s7.dv(1);
        umii_er <= '1' when s7.er /= "0000" else '0';
        umii_d  <= s7.d;
        dbg_crs <= s7.crs;
        dbg_dv  <= s7.dv;
        dbg_er  <= s7.er;
      end if;

    end if;
  end process P_MAIN;

end architecture rtl;
