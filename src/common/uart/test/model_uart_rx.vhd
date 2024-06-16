--------------------------------------------------------------------------------
-- model_uart_rx.vhd                                                          --
-- Behavioural model of the RX side of a UART.                                --
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

package model_uart_rx_pkg is

  type model_uart_rx_t is record
    change : bit;
    data   : std_ulogic_vector(7 downto 0);
  end record model_uart_rx_t;

  component model_uart_rx is
    generic (
      BAUD : integer
    );
    port (
      i : in  std_ulogic;
      o : out model_uart_rx_t
    );
  end component model_uart_rx;

end package model_uart_rx_pkg;

--------------------------------------------------------------------------------

use work.model_uart_rx_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity model_uart_rx is
  generic (
    BAUD : integer
  );
  port (
    i : in  std_ulogic;
    o : out model_uart_rx_t
  );
end entity model_uart_rx;

architecture model of model_uart_rx is

  constant P : integer := 1000000000 / BAUD; -- bit period in ns

  signal data : std_ulogic_vector(7 downto 0);

begin

  P_MAIN: process
  begin
    data <= (others => 'X');
    wait until i = '0'; -- wait for beginning of start bit
    wait for (P/2) * 1 ns; -- wait for middle of bit
    for b in 0 to 7 loop -- capture 8 data bits
      wait for P * 1 ns;
      data <= i & data(7 downto 1);
    end loop;
    wait for P * 1 ns;
    o.data   <= data;
    o.change <= not o.change;
  end process P_MAIN;

end architecture model;
