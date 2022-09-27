--------------------------------------------------------------------------------
-- model_secureip.vhd                                                         --
-- Simple models of secureip primitives.                                      --
-- These model are (very) incomplete, covering just enough of the behaviour   --
-- of the vendor primitives to support their use in this project.             --
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

entity oserdese2 is
  generic (
    data_rate_oq       : string  := "DDR";
    data_rate_tq       : string  := "DDR";
    data_width         : integer := 4;
    init_oq            : bit     := '0';
    init_tq            : bit     := '0';
    is_clkdiv_inverted : bit     := '0';
    is_clk_inverted    : bit     := '0';
    is_d1_inverted     : bit     := '0';
    is_d2_inverted     : bit     := '0';
    is_d3_inverted     : bit     := '0';
    is_d4_inverted     : bit     := '0';
    is_d5_inverted     : bit     := '0';
    is_d6_inverted     : bit     := '0';
    is_d7_inverted     : bit     := '0';
    is_d8_inverted     : bit     := '0';
    is_t1_inverted     : bit     := '0';
    is_t2_inverted     : bit     := '0';
    is_t3_inverted     : bit     := '0';
    is_t4_inverted     : bit     := '0';
    serdes_mode        : string  := "MASTER";
    srval_oq           : bit     := '0';
    srval_tq           : bit     := '0';
    tbyte_ctl          : string  := "FALSE";
    tbyte_src          : string  := "FALSE";
    tristate_width     : integer := 4
  );
  port (
    ofb       : out std_ulogic;
    oq        : out std_ulogic;
    shiftout1 : out std_ulogic;
    shiftout2 : out std_ulogic;
    tbyteout  : out std_ulogic;
    tfb       : out std_ulogic;
    tq        : out std_ulogic;
    clk       : in  std_ulogic;
    clkdiv    : in  std_ulogic;
    d1        : in  std_ulogic;
    d2        : in  std_ulogic;
    d3        : in  std_ulogic;
    d4        : in  std_ulogic;
    d5        : in  std_ulogic;
    d6        : in  std_ulogic;
    d7        : in  std_ulogic;
    d8        : in  std_ulogic;
    oce       : in  std_ulogic;
    rst       : in  std_ulogic;
    shiftin1  : in  std_ulogic;
    shiftin2  : in  std_ulogic;
    t1        : in  std_ulogic;
    t2        : in  std_ulogic;
    t3        : in  std_ulogic;
    t4        : in  std_ulogic;
    tbytein   : in  std_ulogic;
    tce       : in  std_ulogic
  );
end entity oserdese2;

architecture model of oserdese2 is

  signal clki    : std_logic;
  signal clkdivi : std_logic;
  signal dstb    : std_logic;
  signal d       : std_logic_vector(7 downto 0);
  signal t       : std_logic_vector(3 downto 0);
  signal sro     : std_logic_vector(7 downto 0) := (others => to_stdulogic(srval_oq)); -- output shift reg
  signal srt     : std_logic_vector(7 downto 0) := (others => to_stdulogic(srval_tq)); -- tristate shift reg

begin

  clki <= clk xor to_stdulogic(is_clk_inverted);
  clkdivi <= clkdiv xor to_stdulogic(is_clkdiv_inverted);



  -- output shift reg
  GEN_SR_DDR: if data_rate_oq="DDR" generate -- shift 2 bits per clock
    process(rst,clki,clkdivi)
    begin
      if rst = '1' then
        dstb <= '0';
        sro <= (others => '0');
      elsif rising_edge(clki) and oce = '1' then
        if dstb = '1' then
          sro <= d;
        else
          sro <= shiftin2 & shiftin1 & sro(7 downto 2);
        end if;
        dstb <= '0';        
      end if;
      if rising_edge(clkdivi) then
        dstb <= '1';
        d <=
          (d8 xor to_stdulogic(is_d8_inverted)) &
          (d7 xor to_stdulogic(is_d7_inverted)) &
          (d6 xor to_stdulogic(is_d6_inverted)) &
          (d5 xor to_stdulogic(is_d5_inverted)) &
          (d4 xor to_stdulogic(is_d4_inverted)) &
          (d3 xor to_stdulogic(is_d3_inverted)) &
          (d2 xor to_stdulogic(is_d2_inverted)) &
          (d1 xor to_stdulogic(is_d1_inverted));
      end if;
    end process;
    shiftout1 <= sro(2);
    shiftout2 <= sro(3);
    process(rst,clki)
      variable fall: std_logic;
    begin
      if rst = '1' then
        oq <= '0';
        ofb <= '0';
      elsif rising_edge(clki) then
        oq <= sro(0);
        ofb <= sro(0);
        fall := sro(1);
      elsif falling_edge(clki) then
        oq <= fall;
        ofb <= fall;
      end if;
    end process;
  end generate GEN_SR_DDR;

  -- tristate shift reg
  GEN_TR_DDR: if data_rate_tq="DDR" generate
    process(rst,clki,clkdivi)
    begin
      if rst = '1' then
        srt <= (others => '0');
      elsif rising_edge(clki) and tce = '1' then
        if dstb = '1' then     
          srt <= t(3) & t(3) & t(2) & t(2) & t(1) & t(1) & t(0) & t(0);
        else
          srt <= shiftin2 & shiftin1 & srt(7 downto 2);
        end if;
      end if;
      if rising_edge(clkdivi) then
        t <=
          (t4 xor to_stdulogic(is_t4_inverted)) &
          (t3 xor to_stdulogic(is_t3_inverted)) &
          (t2 xor to_stdulogic(is_t2_inverted)) &
          (t1 xor to_stdulogic(is_t1_inverted));      
      end if;
    end process;
    process(rst,clk)
      variable fall: std_logic;
    begin
      if rst = '1' then
        tq <= '0';
      elsif rising_edge(clki) then
        tq <= srt(0);
        fall := srt(1);
      elsif falling_edge(clki) then
        tq <= fall;
      end if;
    end process;
  end generate GEN_TR_DDR;
  GEN_TR_BUF: if data_rate_tq="BUF" generate
    process(rst,clkdivi)
    begin
      if rst = '1' then
        srt <= (others => '0');
        tq <= '0';
      elsif rising_edge(clkdivi) and tce = '1' then
        srt(0) <= tbytein;
        tq <= srt(0);
      end if;
    end process;
  end generate GEN_TR_BUF;

end architecture model;
