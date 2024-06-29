--------------------------------------------------------------------------------
-- model_console.vhd                                                          --
-- Serial console logging to a file.                                          --
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

package model_console_pkg is

  component model_console is
    generic (
      BAUD     : integer;
      FILENAME : string
    );
    port (
      i : in std_ulogic
    );
  end component model_console;

end package model_console_pkg;

--------------------------------------------------------------------------------

use work.model_uart_rx_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use std.textio.all;

entity model_console is
  generic (
    BAUD     : integer;
    FILENAME : string
  );
  port (
    i : in std_ulogic
  );
end entity model_console;

architecture model of model_console is

  constant CTRL_C : std_ulogic_vector(7 downto 0) := x"03";

  signal rd : std_ulogic_vector(7 downto 0);

begin

  P_MAIN: process
    type char_file_t is file of character;
    file f : char_file_t;
  begin
    file_open(f, FILENAME, WRITE_MODE);
    loop
      wait until rd'transaction'event;
      if rd = CTRL_C then
        report "CTRL C : quitting..." severity note;
        file_close(f);
        std.env.finish;
      end if;
      write(f, character'val(to_integer(unsigned(rd))));
    end loop;
  end process P_MAIN;

  UART: component model_uart_rx
    generic map (
      BAUD => BAUD
    )
    port map (
      i => i,
      o => rd,
      e => open
    );

end architecture model;
