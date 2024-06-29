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

  component model_uart_rx is
    generic (
      BAUD : integer
    );
    port (
      i : in  std_ulogic;
      o : out std_ulogic_vector(7 downto 0);
      e : out std_logic
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
    i : in  std_ulogic;                    -- serial data in
    o : out std_ulogic_vector(7 downto 0); -- parallel data out (use o'transaction)
    e : out std_logic                      -- error (bad stop bit)
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
    wait for P * 1 ns; -- wait until middle of stop bit
    o <= data;         -- output data
    e <= not i;        -- error if stop bit is not high
  end process P_MAIN;

end architecture model;
