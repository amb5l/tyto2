--------------------------------------------------------------------------------
-- memac_fcs.vhd                                                              --
-- MEMAC Frame Check Sequence (CRC32).                                        --
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
-- Adds a cycle of latency to the data stream. Appends Frame Check Sequence.
-- This is always the MAGIC constant for correctly received frames that
-- include an FCS.

library ieee;
  use ieee.std_logic_1164.all;

package memac_fcs_pkg is

  component memac_fcs is
    port (
      rst : in    std_logic;
      clk : in    std_logic;
      eni : in    std_logic;
      di  : in    std_logic_vector(7 downto 0);
      eno : out   std_logic;
      do  : out   std_logic_vector(7 downto 0);
      ok  : out   std_logic
    );
  end component memac_fcs;

end package memac_fcs_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.crc32_eth_8_pkg.all;

entity memac_fcs is
  port (
    rst : in    std_logic;
    clk : in    std_logic;
    eni : in    std_logic;
    di  : in    std_logic_vector(7 downto 0);
    eno : out   std_logic;
    do  : out   std_logic_vector(7 downto 0);
    ok  : out   std_logic
  );
end entity memac_fcs;

architecture synth of memac_fcs is

  constant MAGIC : std_logic_vector(31 downto 0) := x"C704DD7B";

  signal di_1  : std_logic_vector(7 downto 0);
  signal crc32 : std_logic_vector(31 downto 0);
  signal eni_p : std_logic_vector(1 to 5);
  signal ok_i  : std_logic;
  signal ok_q  : std_logic;

begin

  process(clk)
  begin
    if rst = '1' then
      di_1  <= (others => '0');
      crc32 <= (others => '1');
      eni_p <= (others => '0');
      ok_q  <= '0';
    elsif rising_edge(clk) then
      if eni = '1' then
        di_1 <= di;
        crc32 <= crc32_eth_8(di,crc32);
      end if;
      eni_p(1 to 5) <= eni & eni_p(1 to 4);
      if eni = '0' and eni_p(1) = '1' then
        ok_q <= ok_i;
      end if;
    end if;
  end process;

  do <=
    di_1                    when eni_p(1) = '1' else
    not crc32(31 downto 24) when eni_p(2) = '1' else
    not crc32(23 downto 16) when eni_p(3) = '1' else
    not crc32(15 downto  8) when eni_p(4) = '1' else
    not crc32( 7 downto  0) when eni_p(5) = '1' else
    x"00";

  eno <= '1' when unsigned(eni_p) /= 0 else '0';

  ok_i <=
    '1' when eni = '0' and eni_p(1) = '1' and crc32  = MAGIC else
    '0' when eni = '0' and eni_p(1) = '1' and crc32 /= MAGIC else
    ok_q;
  ok <= ok_i;

end architecture synth;