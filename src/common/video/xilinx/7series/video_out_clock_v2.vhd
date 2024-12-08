--------------------------------------------------------------------------------
-- video_out_clock_v2.vhd                                                     --
-- Pixel and serialiser clock synthesiser (dynamically configured MMCM).      --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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

package video_out_clock_v2_pkg is

  component video_out_clock_v2 is
    port (
      rsti    : in    std_ulogic;
      clki    : in    std_ulogic;
      sel     : in    std_ulogic_vector(1 downto 0);
      rsto    : out   std_ulogic;
      clko    : out   std_ulogic;
      clko_x5 : out   std_ulogic
    );
  end component video_out_clock_v2;

end package video_out_clock_v2_pkg;

----------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.mmcm_drp_pkg.all;
use work.sync_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity video_out_clock_v2 is
  port (
    rsti    : in    std_ulogic;                    -- input (reference) clock synchronous reset
    clki    : in    std_ulogic;                    -- input (reference) clock
    sel     : in    std_ulogic_vector(1 downto 0); -- output clock select: 00 = 25.2, 01 = 27.0, 10 = 74.25, 11 = 148.5
    rsto    : out   std_ulogic;                    -- output clock synchronous reset
    clko    : out   std_ulogic;                    -- pixel clock
    clko_x5 : out   std_ulogic                     -- serialiser clock (5x pixel clock)
  );
end entity video_out_clock_v2;

architecture rtl of video_out_clock_v2 is

  constant TABLE : sulv_vector(0 to 127)(39 downto 0) := (
    16#00# => x"06" & x"1145" & x"1000",
    16#01# => x"07" & x"0000" & x"8000",
    16#02# => x"08" & x"1083" & x"1000",
    16#03# => x"09" & x"0080" & x"8000",
    16#04# => x"0A" & x"130d" & x"1000",
    16#05# => x"0B" & x"0080" & x"8000",
    16#06# => x"0C" & x"1145" & x"1000",
    16#07# => x"0D" & x"0000" & x"8000",
    16#08# => x"0E" & x"1145" & x"1000",
    16#09# => x"0F" & x"0000" & x"8000",
    16#0A# => x"10" & x"1145" & x"1000",
    16#0B# => x"11" & x"0000" & x"8000",
    16#0C# => x"12" & x"1145" & x"1000",
    16#0D# => x"13" & x"3000" & x"8000",
    16#0E# => x"14" & x"13CF" & x"1000",
    16#0F# => x"15" & x"4800" & x"8000",
    16#10# => x"16" & x"0083" & x"C000",
    16#11# => x"18" & x"002C" & x"FC00",
    16#12# => x"19" & x"7C01" & x"8000",
    16#13# => x"1A" & x"7DE9" & x"8000",
    16#14# => x"28" & x"FFFF" & x"0000",
    16#15# => x"4E" & x"0900" & x"66FF",
    16#16# => x"CF" & x"1000" & x"666F",
    16#20# => x"06" & x"1145" & x"1000",
    16#21# => x"07" & x"0000" & x"8000",
    16#22# => x"08" & x"10C4" & x"1000",
    16#23# => x"09" & x"0080" & x"8000",
    16#24# => x"0A" & x"1452" & x"1000",
    16#25# => x"0B" & x"0080" & x"8000",
    16#26# => x"0C" & x"1145" & x"1000",
    16#27# => x"0D" & x"0000" & x"8000",
    16#28# => x"0E" & x"1145" & x"1000",
    16#29# => x"0F" & x"0000" & x"8000",
    16#2A# => x"10" & x"1145" & x"1000",
    16#2B# => x"11" & x"0000" & x"8000",
    16#2C# => x"12" & x"1145" & x"1000",
    16#2D# => x"13" & x"2800" & x"8000",
    16#2E# => x"14" & x"15D7" & x"1000",
    16#2F# => x"15" & x"2800" & x"8000",
    16#30# => x"16" & x"0083" & x"C000",
    16#31# => x"18" & x"00FA" & x"FC00",
    16#32# => x"19" & x"7C01" & x"8000",
    16#33# => x"1A" & x"7DE9" & x"8000",
    16#34# => x"28" & x"FFFF" & x"0000",
    16#35# => x"4E" & x"1900" & x"66FF",
    16#36# => x"CF" & x"0100" & x"666F",
    16#40# => x"06" & x"1145" & x"1000",
    16#41# => x"07" & x"0000" & x"8000",
    16#42# => x"08" & x"1041" & x"1000",
    16#43# => x"09" & x"0000" & x"8000",
    16#44# => x"0A" & x"1145" & x"1000",
    16#45# => x"0B" & x"0000" & x"8000",
    16#46# => x"0C" & x"1145" & x"1000",
    16#47# => x"0D" & x"0000" & x"8000",
    16#48# => x"0E" & x"1145" & x"1000",
    16#49# => x"0F" & x"0000" & x"8000",
    16#4A# => x"10" & x"1145" & x"1000",
    16#4B# => x"11" & x"0000" & x"8000",
    16#4C# => x"12" & x"1145" & x"1000",
    16#4D# => x"13" & x"2400" & x"8000",
    16#4E# => x"14" & x"1491" & x"1000",
    16#4F# => x"15" & x"1800" & x"8000",
    16#50# => x"16" & x"0083" & x"C000",
    16#51# => x"18" & x"00FA" & x"FC00",
    16#52# => x"19" & x"7C01" & x"8000",
    16#53# => x"1A" & x"7DE9" & x"8000",
    16#54# => x"28" & x"FFFF" & x"0000",
    16#55# => x"4E" & x"0900" & x"66FF",
    16#56# => x"CF" & x"1000" & x"666F",
    16#60# => x"06" & x"1145" & x"1000",
    16#61# => x"07" & x"0000" & x"8000",
    16#62# => x"08" & x"1041" & x"1000",
    16#63# => x"09" & x"00C0" & x"8000",
    16#64# => x"0A" & x"1083" & x"1000",
    16#65# => x"0B" & x"0080" & x"8000",
    16#66# => x"0C" & x"1145" & x"1000",
    16#67# => x"0D" & x"0000" & x"8000",
    16#68# => x"0E" & x"1145" & x"1000",
    16#69# => x"0F" & x"0000" & x"8000",
    16#6A# => x"10" & x"1145" & x"1000",
    16#6B# => x"11" & x"0000" & x"8000",
    16#6C# => x"12" & x"1145" & x"1000",
    16#6D# => x"13" & x"2400" & x"8000",
    16#6E# => x"14" & x"1491" & x"1000",
    16#6F# => x"15" & x"1800" & x"8000",
    16#70# => x"16" & x"0083" & x"C000",
    16#71# => x"18" & x"00FA" & x"FC00",
    16#72# => x"19" & x"7C01" & x"8000",
    16#73# => x"1A" & x"7DE9" & x"8000",
    16#74# => x"28" & x"FFFF" & x"0000",
    16#75# => x"4E" & x"0900" & x"66FF",
    16#76# => x"CF" & x"1000" & x"666F",
    others => (39 downto 0 => '0')
  );

  -- The 7 series LVDS serdes is rated at as follows for DDR outputs:
  --  1200Mbps max for -2 speed grade
  --  950Mbps max for -1 speed grade
  -- 1485Mbps (for full HD) overclocks these, so we use a fictional
  --  recipe for the MMCM to achieve timing closure:
  --   m = 9.25, d = 1, outdiv0 = 2.0, outdiv1 = 6
  --    => fVCO = 925 MHz, fclko_x5 = 462.5 MHz, fclko = 154.166 MHz
  function INIT return mmcm_drp_init_t is
    variable r : mmcm_drp_init_t;
  begin
    r := MMCM_DRP_INIT;  -- start with safe defaults
    r.tck       := 10.0; -- override where required...
    r.mul       := 9.25;
    r.div       := 1;
    r.odiv0     := 2.0;
    r.odiv(1)   := 6;
    return r;
  end function INIT;

  signal rsta : std_ulogic;

begin

  MMCM: component mmcm_drp -- v4p ignore w-301 (unconnected outputs)
  generic map (
    TABLE => TABLE,
    INIT  => INIT
  )
  port map (
    rsti  => rsti,
    clki  => clki,
    sel   => sel,
    rsto  => rsta,
    clko0 => clko_x5,
    clko1 => clko
  );

  CDC: component sync
    generic map (
      SR => "1"
    )
    port map (
      rst  => rsta,
      clk  => clko,
      i(0) => rsta,
      o(0) => rsto
    );

end architecture rtl;
