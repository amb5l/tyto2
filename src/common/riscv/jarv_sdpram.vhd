--------------------------------------------------------------------------------
-- jarv_sdpram.vhd                                                            --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation       --
-- either version 3 of the License or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package jarv_sdpram_pkg is

  component jarv_sdpram is
    generic (
      data_width : integer;
      addr_width : integer
    );
    port (
      wclk    : in    std_logic;
      we      : in    std_logic;
      waddr   : in    std_logic_vector(addr_width-1 downto 0);
      wdata   : in    std_logic_vector(data_width-1 downto 0);
      raddr   : in    std_logic_vector(addr_width-1 downto 0);
      rdata   : out   std_logic_vector(data_width-1 downto 0)
    );
  end component jarv_sdpram;

end package jarv_sdpram_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity jarv_sdpram is
  generic (
    data_width : integer;
    addr_width : integer
  );
  port (
    wclk    : in    std_logic;
    we      : in    std_logic;
    waddr   : in    std_logic_vector(addr_width-1 downto 0);
    wdata   : in    std_logic_vector(data_width-1 downto 0);
    raddr   : in    std_logic_vector(addr_width-1 downto 0);
    rdata   : out   std_logic_vector(data_width-1 downto 0)
  );
end entity jarv_sdpram;

architecture infer of jarv_sdpram is

  subtype ram_word_t is std_logic_vector(data_width-1 downto 0);
  type ram_t is array(natural range <>) of ram_word_t;
  signal ram : ram_t;

begin

  process(wclk)
  begin
    if rising_edge(wclk) then
      if we = '1' then
        ram(to_integer(unsigned(waddr))) <= wdata;
      end if;
    end if;
  end process;

  rdata <= ram(to_integer(unsigned(raddr)));

end architecture infer;
