--------------------------------------------------------------------------------
-- overclock.vhd                                                              --
-- MEGAtest clock synthesiser (dynamically configured MMCM).                  --
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

package overclock_pkg is

  component overclock is
    port (
      rsti      : in    std_logic;
      clki      : in    std_logic;
      sel       : in    std_logic_vector(2 downto 0);
      s_rst     : out   std_logic;
      s_clk     : out   std_logic;
      s_clk_dly : out   std_logic
    );
  end component overclock;

end package overclock_pkg;

----------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.mmcm_drp_pkg.all;
use work.sync_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity overclock is
  port (
    rsti      : in    std_logic;                    -- input (reference) clock synchronous reset
    clki      : in    std_logic;                    -- input (reference) clock
    sel       : in    std_logic_vector(2 downto 0); -- output clock select: 00 = 100, 01 = 105, 10 = 110, 11 = 120 (MHz)
    s_rst     : out   std_logic;                    -- system clock synchronous reset
    s_clk     : out   std_logic;                    -- system clock (100/105/110/120 MHz)
    s_clk_dly : out   std_logic                     -- delayed system clock (100/105/110/120 MHz) for HyperRAM controller
  );
end entity overclock;

architecture rtl of overclock is

  -- TODO remove 200MHz clock from this recipe
  constant TABLE : sulv_vector(0 to 255)(39 downto 0) := (
    16#00# => x"06" & x"1000" & x"1000",
    16#01# => x"07" & x"0000" & x"8000",
    16#02# => x"08" & x"1145" & x"1000",
    16#03# => x"09" & x"0000" & x"8000",
    16#04# => x"0A" & x"9145" & x"1000",
    16#05# => x"0B" & x"0007" & x"8000",
    16#06# => x"0C" & x"1000" & x"1000",
    16#07# => x"0D" & x"0000" & x"8000",
    16#08# => x"0E" & x"1000" & x"1000",
    16#09# => x"0F" & x"0000" & x"8000",
    16#0A# => x"10" & x"1000" & x"1000",
    16#0B# => x"11" & x"0000" & x"8000",
    16#0C# => x"12" & x"1000" & x"1000",
    16#0D# => x"13" & x"0000" & x"8000",
    16#0E# => x"14" & x"1145" & x"1000",
    16#0F# => x"15" & x"0000" & x"8000",
    16#10# => x"16" & x"1041" & x"C000",
    16#11# => x"18" & x"01E8" & x"FC00",
    16#12# => x"19" & x"7001" & x"8000",
    16#13# => x"1A" & x"71E9" & x"8000",
    16#14# => x"28" & x"FFFF" & x"0000",
    16#15# => x"4E" & x"9900" & x"66FF",
    16#16# => x"CF" & x"1100" & x"666F",
    16#20# => x"06" & x"1000" & x"1000",
    16#21# => x"07" & x"0000" & x"8000",
    16#22# => x"08" & x"1145" & x"1000",
    16#23# => x"09" & x"0000" & x"8000",
    16#24# => x"0A" & x"9145" & x"1000",
    16#25# => x"0B" & x"0007" & x"8000",
    16#26# => x"0C" & x"1000" & x"1000",
    16#27# => x"0D" & x"0000" & x"8000",
    16#28# => x"0E" & x"1000" & x"1000",
    16#29# => x"0F" & x"0000" & x"8000",
    16#2A# => x"10" & x"1000" & x"1000",
    16#2B# => x"11" & x"0000" & x"8000",
    16#2C# => x"12" & x"1000" & x"1000",
    16#2D# => x"13" & x"1400" & x"8000",
    16#2E# => x"14" & x"1104" & x"1000",
    16#2F# => x"15" & x"4C00" & x"8000",
    16#30# => x"16" & x"1041" & x"C000",
    16#31# => x"18" & x"01E8" & x"FC00",
    16#32# => x"19" & x"7001" & x"8000",
    16#33# => x"1A" & x"71E9" & x"8000",
    16#34# => x"28" & x"FFFF" & x"0000",
    16#35# => x"4E" & x"9900" & x"66FF",
    16#36# => x"CF" & x"1100" & x"666F",
    16#40# => x"06" & x"1000" & x"1000",
    16#41# => x"07" & x"0000" & x"8000",
    16#42# => x"08" & x"1145" & x"1000",
    16#43# => x"09" & x"0000" & x"8000",
    16#44# => x"0A" & x"9145" & x"1000",
    16#45# => x"0B" & x"0007" & x"8000",
    16#46# => x"0C" & x"1000" & x"1000",
    16#47# => x"0D" & x"0000" & x"8000",
    16#48# => x"0E" & x"1000" & x"1000",
    16#49# => x"0F" & x"0000" & x"8000",
    16#4A# => x"10" & x"1000" & x"1000",
    16#4B# => x"11" & x"0000" & x"8000",
    16#4C# => x"12" & x"1000" & x"1000",
    16#4D# => x"13" & x"0000" & x"8000",
    16#4E# => x"14" & x"1146" & x"1000",
    16#4F# => x"15" & x"0080" & x"8000",
    16#50# => x"16" & x"1041" & x"C000",
    16#51# => x"18" & x"0184" & x"FC00",
    16#52# => x"19" & x"7C01" & x"8000",
    16#53# => x"1A" & x"7DE9" & x"8000",
    16#54# => x"28" & x"FFFF" & x"0000",
    16#55# => x"4E" & x"9900" & x"66FF",
    16#56# => x"CF" & x"8100" & x"666F",
    16#60# => x"06" & x"1000" & x"1000",
    16#61# => x"07" & x"0000" & x"8000",
    16#62# => x"08" & x"1145" & x"1000",
    16#63# => x"09" & x"0000" & x"8000",
    16#64# => x"0A" & x"9145" & x"1000",
    16#65# => x"0B" & x"0007" & x"8000",
    16#66# => x"0C" & x"1000" & x"1000",
    16#67# => x"0D" & x"0000" & x"8000",
    16#68# => x"0E" & x"1000" & x"1000",
    16#69# => x"0F" & x"0000" & x"8000",
    16#6A# => x"10" & x"1000" & x"1000",
    16#6B# => x"11" & x"0000" & x"8000",
    16#6C# => x"12" & x"1000" & x"1000",
    16#6D# => x"13" & x"0000" & x"8000",
    16#6E# => x"14" & x"1186" & x"1000",
    16#6F# => x"15" & x"0000" & x"8000",
    16#70# => x"16" & x"1041" & x"C000",
    16#71# => x"18" & x"0139" & x"FC00",
    16#72# => x"19" & x"7C01" & x"8000",
    16#73# => x"1A" & x"7DE9" & x"8000",
    16#74# => x"28" & x"FFFF" & x"0000",
    16#75# => x"4E" & x"9100" & x"66FF",
    16#76# => x"CF" & x"0100" & x"666F",
    16#80# => x"06" & x"1000" & x"1000",
    16#81# => x"07" & x"0000" & x"8000",
    16#82# => x"08" & x"128A" & x"1000",
    16#83# => x"09" & x"0000" & x"8000",
    16#84# => x"0A" & x"128A" & x"1000",
    16#85# => x"0B" & x"000F" & x"8000",
    16#86# => x"0C" & x"1000" & x"1000",
    16#87# => x"0D" & x"0000" & x"8000",
    16#88# => x"0E" & x"1000" & x"1000",
    16#89# => x"0F" & x"0000" & x"8000",
    16#8A# => x"10" & x"1000" & x"1000",
    16#8B# => x"11" & x"0000" & x"8000",
    16#8C# => x"12" & x"1000" & x"1000",
    16#8D# => x"13" & x"0000" & x"8000",
    16#8E# => x"14" & x"1145" & x"1000",
    16#8F# => x"15" & x"0000" & x"8000",
    16#90# => x"16" & x"1041" & x"C000",
    16#91# => x"18" & x"01E8" & x"FC00",
    16#92# => x"19" & x"7001" & x"8000",
    16#93# => x"1A" & x"71E9" & x"8000",
    16#94# => x"28" & x"FFFF" & x"0000",
    16#95# => x"4E" & x"9900" & x"66FF",
    16#96# => x"CF" & x"1100" & x"666F",
    16#A0# => x"06" & x"1000" & x"1000",
    16#A1# => x"07" & x"0000" & x"8000",
    16#A2# => x"08" & x"1208" & x"1000",
    16#A3# => x"09" & x"0000" & x"8000",
    16#A4# => x"0A" & x"1208" & x"1000",
    16#A5# => x"0B" & x"000C" & x"8000",
    16#A6# => x"0C" & x"1000" & x"1000",
    16#A7# => x"0D" & x"0000" & x"8000",
    16#A8# => x"0E" & x"1000" & x"1000",
    16#A9# => x"0F" & x"0000" & x"8000",
    16#AA# => x"10" & x"1000" & x"1000",
    16#AB# => x"11" & x"0000" & x"8000",
    16#AC# => x"12" & x"1000" & x"1000",
    16#AD# => x"13" & x"0000" & x"8000",
    16#AE# => x"14" & x"1186" & x"1000",
    16#AF# => x"15" & x"0000" & x"8000",
    16#B0# => x"16" & x"1041" & x"C000",
    16#B1# => x"18" & x"0139" & x"FC00",
    16#B2# => x"19" & x"7C01" & x"8000",
    16#B3# => x"1A" & x"7DE9" & x"8000",
    16#B4# => x"28" & x"FFFF" & x"0000",
    16#B5# => x"4E" & x"9100" & x"66FF",
    16#B6# => x"CF" & x"0100" & x"666F",
    16#C0# => x"06" & x"1000" & x"1000",
    16#C1# => x"07" & x"0000" & x"8000",
    16#C2# => x"08" & x"1145" & x"1000",
    16#C3# => x"09" & x"0000" & x"8000",
    16#C4# => x"0A" & x"9145" & x"1000",
    16#C5# => x"0B" & x"0007" & x"8000",
    16#C6# => x"0C" & x"1000" & x"1000",
    16#C7# => x"0D" & x"0000" & x"8000",
    16#C8# => x"0E" & x"1000" & x"1000",
    16#C9# => x"0F" & x"0000" & x"8000",
    16#CA# => x"10" & x"1000" & x"1000",
    16#CB# => x"11" & x"0000" & x"8000",
    16#CC# => x"12" & x"1000" & x"1000",
    16#CD# => x"13" & x"0000" & x"8000",
    16#CE# => x"14" & x"1105" & x"1000",
    16#CF# => x"15" & x"0080" & x"8000",
    16#D0# => x"16" & x"1041" & x"C000",
    16#D1# => x"18" & x"01E8" & x"FC00",
    16#D2# => x"19" & x"6401" & x"8000",
    16#D3# => x"1A" & x"65E9" & x"8000",
    16#D4# => x"28" & x"FFFF" & x"0000",
    16#D5# => x"4E" & x"9800" & x"66FF",
    16#D6# => x"CF" & x"1100" & x"666F",
    16#E0# => x"06" & x"1000" & x"1000",
    16#E1# => x"07" & x"0000" & x"8000",
    16#E2# => x"08" & x"1145" & x"1000",
    16#E3# => x"09" & x"0000" & x"8000",
    16#E4# => x"0A" & x"9145" & x"1000",
    16#E5# => x"0B" & x"0007" & x"8000",
    16#E6# => x"0C" & x"1000" & x"1000",
    16#E7# => x"0D" & x"0000" & x"8000",
    16#E8# => x"0E" & x"1000" & x"1000",
    16#E9# => x"0F" & x"0000" & x"8000",
    16#EA# => x"10" & x"1000" & x"1000",
    16#EB# => x"11" & x"0000" & x"8000",
    16#EC# => x"12" & x"1000" & x"1000",
    16#ED# => x"13" & x"3000" & x"8000",
    16#EE# => x"14" & x"1104" & x"1000",
    16#EF# => x"15" & x"4800" & x"8000",
    16#F0# => x"16" & x"1041" & x"C000",
    16#F1# => x"18" & x"01E8" & x"FC00",
    16#F2# => x"19" & x"6401" & x"8000",
    16#F3# => x"1A" & x"65E9" & x"8000",
    16#F4# => x"28" & x"FFFF" & x"0000",
    16#F5# => x"4E" & x"9800" & x"66FF",
    16#F6# => x"CF" & x"1100" & x"666F",
    others => x"00" & x"0000" & x"0000"
  );

  -- default to 1000MHz VCO, 100MHz clocks
  function INIT return mmcm_drp_init_t is
    variable r : mmcm_drp_init_t;
  begin
    r := MMCM_DRP_INIT;
    r.tck       := 10.0;
    r.mul       := 10.0;
    r.div       := 1;
    r.odiv0     := 10.0;
    r.odiv(1)   := 10;
    r.ophase(1) := 270.0;
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
    clko0 => s_clk,
    clko1 => s_clk_dly
  );

  CDC: component sync
    generic map (
      SR => "1"
    )
    port map (
      rst  => rsta,
      clk  => s_clk,
      i(0) => rsta,
      o(0) => s_rst
    );

end architecture rtl;
