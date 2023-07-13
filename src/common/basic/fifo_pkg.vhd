--------------------------------------------------------------------------------
-- fifo_pkg.vhd                                                               --
-- FIFOs.                                                                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or(at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package fifo_pkg is

  component fifo_sft is
    generic (
      width   : integer;
      depth   : integer;
      aef_lvl : integer := 1;    -- aef asserts when N words in FIFO
      aff_lvl : integer := 1;    -- aff asserts when N spaces in FIFO
      en_cut  : boolean := false -- enable/disable cut through
    );
    port (
      rst  : in    std_logic;
      clk  : in    std_logic;
      ld   : in    std_logic;
      unld : in    std_logic;
      d    : in    std_logic_vector(width-1 downto 0);
      q    : out   std_logic_vector(width-1 downto 0);
      ef   : out   std_logic;
      aef  : out   std_logic;
      aff  : out   std_logic;
      ff   : out   std_logic;
      err  : out   std_logic
    );
  end component fifo_sft;

end package fifo_pkg;

--------------------------------------------------------------------------------
-- single clock, fall through and optional cut through

library ieee;
  use ieee.std_logic_1164.all;

entity fifo_sft is
  generic (
    width   : integer;
    depth   : integer;
    aef_lvl : integer := 1;    -- aef asserts when N words in FIFO
    aff_lvl : integer := 1;    -- aff asserts when N spaces in FIFO
    en_cut  : boolean := false -- enable/disable cut through
  );
  port (
    rst  : in    std_logic;
    clk  : in    std_logic;
    ld   : in    std_logic;
    unld : in    std_logic;
    d    : in    std_logic_vector(width-1 downto 0);
    q    : out   std_logic_vector(width-1 downto 0);
    ef   : out   std_logic;
    aef  : out   std_logic;
    aff  : out   std_logic;
    ff   : out   std_logic;
    err  : out   std_logic
  );
end entity fifo_sft;

architecture behavioural of fifo_sft is

  signal wptr : integer range 0 to depth-1;
  signal rptr : integer range 0 to depth-1;
  signal cut  : std_logic;

  type fifo_t is array(0 to depth-1) of std_logic_vector(width-1 downto 0);
  signal fifo : fifo_t;

begin

  cut <= '1' when ld = '1' and unld = '1' and rptr = wptr else '0';

  q <=
    fifo(rptr) when not en_cut else
    d when cut = '1' else
    fifo(rptr) when cut = '0' else
    (others => 'X');

  process(rst,clk)
  begin
    if rst = '1' then

      wptr <= 0;
      rptr <= 0;
      ef   <= '1';
      aef  <= '1';
      aff  <= '0';
      ff   <= '0';
      err  <= '0';

    elsif rising_edge(clk) then

      if ld = '1' then
        fifo(wptr) <= d;
        wptr <= (wptr+1) mod depth;
      end if;

      if unld = '1' then
        rptr <= (rptr+1) mod depth;
      end if;

      if ld = '1' and unld = '0' then
        ef <= '0';
      elsif unld = '1' and ld = '0' and (rptr+1) mod depth = wptr then
        ef <= '1';
      end if;

      if ld = '1' and unld = '0' and (wptr+1) mod depth = (rptr+aef_lvl+1) mod depth then
        aef <= '0';
      elsif unld = '1' and ld = '0' and (rptr+aef_lvl+1) mod depth = wptr then
        aef <= '1';
      end if;

      if ld = '1' and unld = '0' and (wptr+aff_lvl+1) mod depth = rptr then
        aff <= '1';
      elsif unld = '1' and ld = '0' and (rptr+1) mod depth = (wptr+aff_lvl+1) mod depth then
        aff <= '0';
      end if;

      if ld = '1' and unld = '0' and (wptr+1) mod depth = rptr then
        ff <= '1';
      elsif unld = '1' and ld = '0' then
        ff <= '0';
      end if;

      if (ld = '1' and unld = '0' and ff = '1')
      or (unld = '1' and ld = '0' and ef = '1')
      then
        err <= '1';
      end if;

    end if;
  end process;

end architecture behavioural;
