--------------------------------------------------------------------------------
-- audio_out_test_tone.vhd                                                    --
-- Simple test tone generator (fs = 48kHz).                                   --
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

package audio_out_test_tone_pkg is

  component audio_out_test_tone is
    port (
      rst   : in   std_logic;
      clk   : in   std_logic;
      clken : in   std_logic;
      l     : out  std_logic_vector(15 downto 0);
      r     : out  std_logic_vector(15 downto 0)
    );
  end component audio_out_test_tone;

end package audio_out_test_tone_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity audio_out_test_tone is
  port (
    rst   : in   std_logic;
    clk   : in   std_logic;
    clken : in   std_logic;
    l     : out  std_logic_vector(15 downto 0);
    r     : out  std_logic_vector(15 downto 0)
  );
end entity audio_out_test_tone;

architecture synth of audio_out_test_tone is

  signal count_t     : integer range 0 to 108;   -- tone generation counter
  signal a4          : std_logic;                -- ~440Hz
  signal a3          : std_logic;                -- ~220Hz
  signal count_2     : integer range 0 to 24000; -- 2Hz pulse counter
  signal count_p     : integer range 0 to 3;
  signal en_l        : std_logic;
  signal en_r        : std_logic;

begin

  MAIN: process (rst, clk) is
  begin
    if rst = '1' then
      count_t <= 0;
      a4      <= '0';
      a3      <= '0';
      count_2 <= 0;
      count_p <= 0;
      en_l    <= '0';
      en_r    <= '0';
      l       <= (others => '0');
      r       <= (others => '0');
    elsif rising_edge(clk) then
      if clken = '1' then
        count_t <= (count_t+1) mod 109;
        if count_t = 108 then
          a4 <= '0';
          a3 <= not a3;
        elsif count_t = 54 then
          a4 <= '1';
        end if;
        count_2 <= (count_2+1) mod 24000;
        if count_2 = 0 then
          count_p <= (count_p+1) mod 4;
        end if;
        case count_p is
          when 0 => en_l <= '1'; en_r <= '0';
          when 1 => en_l <= '0'; en_r <= '0';
          when 2 => en_l <= '0'; en_r <= '1';
          when 3 => en_l <= '0'; en_r <= '0';
        end case;
        if en_l = '1' then
          if a4 = '1' then
            l <= std_logic_vector(to_signed(+16384, 16));
          else
            l <= std_logic_vector(to_signed(-16384, 16));
          end if;
        else
          l <= (others => '0');
        end if;
        if en_r = '1' then
          if a3 = '1' then
            r <= std_logic_vector(to_signed(+16384, 16));
          else
            r <= std_logic_vector(to_signed(-16384, 16));
          end if;
        else
          r <= (others => '0');
        end if;
      end if;
    end if;
  end process MAIN;

end architecture synth;
