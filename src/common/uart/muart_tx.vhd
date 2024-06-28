--------------------------------------------------------------------------------
-- muart_tx.vhd                                                               --
-- Modular UART: TX side.                                                     --
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

package muart_tx_pkg is

  component muart_tx is
    generic (
      DIV : integer -- fCLK/DIV = fBAUD
    );
    port (
      rst   : in    std_ulogic;
      clk   : in    std_ulogic;
      d     : in    std_ulogic_vector(7 downto 0);
      valid : in    std_ulogic;
      ready : out   std_ulogic;
      q     : out   std_ulogic
    );
  end component muart_tx;

end package muart_tx_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity muart_tx is
  generic (
    DIV : integer -- fCLK/DIV = fBAUD
  );
  port (
    rst   : in    std_ulogic;
    clk   : in    std_ulogic;
    d     : in    std_ulogic_vector(7 downto 0);
    valid : in    std_ulogic;
    ready : out   std_ulogic;
    q     : out   std_ulogic
  );
end entity muart_tx;

architecture rtl of muart_tx is

  signal bit_count   : integer range 0 to 9;
  signal clk_count : integer range 0 to DIV-1;
  signal sr          : std_ulogic_vector(7 downto 0);
  signal busy        : std_ulogic;

begin

  P_MAIN: process(rst,clk)
  begin
    if rst = '1' then
      bit_count <= 0;
      clk_count <= 0;
      sr        <= (others => '0');
      busy      <= '0';
      q         <= '1';
      ready     <= '1';
    elsif rising_edge(clk) then
      if valid = '1' and ready = '1' then
        sr    <= d;
        ready <= '0';
      end if;
      if busy = '0' then
        if ready = '0' then
          -- start bit
          bit_count <= 0;
          clk_count <= 0;
          q         <= '0';
          busy      <= '1';
        end if;
      elsif busy = '1' then
        if clk_count = DIV - 1 then
          if bit_count = 9 then -- end of character
            bit_count <= 0;
            clk_count <= 0;
            if ready = '0' then
              -- next start bit
              q         <= '0';
            elsif ready = '1' then
              -- done
              busy <= '0';
            end if;
          else
            if bit_count = 8 then
              -- stop bit
              q <= '1';
            else
              -- data bits
              sr <= '0' & sr(7 downto 1);
              q  <= sr(0);
              if bit_count = 7 then
                ready <= '1';
              end if;
            end if;
            bit_count <= bit_count + 1;
          end if;
          clk_count <= 0;
        else
          clk_count <= clk_count + 1;
        end if;
      end if;
    end if;
  end process P_MAIN;

end architecture rtl;
