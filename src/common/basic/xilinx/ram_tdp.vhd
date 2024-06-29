--------------------------------------------------------------------------------
-- ram_tdp.vhd                                                                --
-- True dual port RAM, separate clocks, synchronous reset.                    --
-- Infers block RAM correctly in Vivado. (VHDL-1993)                          --
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

package ram_tdp_pkg is

  component ram_tdp is
    port (
      clk_a  : in    std_ulogic;
      rst_a  : in    std_ulogic;
      en_a   : in    std_ulogic;
      we_a   : in    std_ulogic;
      addr_a : in    std_ulogic_vector;
      din_a  : in    std_ulogic_vector;
      dout_a : out   std_ulogic_vector;
      clk_b  : in    std_ulogic;
      rst_b  : in    std_ulogic;
      en_b   : in    std_ulogic;
      we_b   : in    std_ulogic;
      addr_b : in    std_ulogic_vector;
      din_b  : in    std_ulogic_vector;
      dout_b : out   std_ulogic_vector
    );
  end component ram_tdp;

end package ram_tdp_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity ram_tdp is
  port (
    clk_a  : in    std_ulogic;
    rst_a  : in    std_ulogic;
    en_a   : in    std_ulogic;
    we_a   : in    std_ulogic;
    addr_a : in    std_ulogic_vector;
    din_a  : in    std_ulogic_vector;
    dout_a : out   std_ulogic_vector;
    clk_b  : in    std_ulogic;
    rst_b  : in    std_ulogic;
    en_b   : in    std_ulogic;
    we_b   : in    std_ulogic;
    addr_b : in    std_ulogic_vector;
    din_b  : in    std_ulogic_vector;
    dout_b : out   std_ulogic_vector
  );
end entity ram_tdp;

architecture infer of ram_tdp is

  constant depth : positive := 2**addr_a'length;

  type ram_t is array(0 to depth-1) of std_ulogic_vector(din_a'range);

  shared variable ram : ram_t;

begin

  PORT_A: process(clk_a,en_a) is
  begin
    if rising_edge(clk_a) then
      if en_a = '1' then
        dout_a  <= ram(to_integer(unsigned(addr_a)));
        if we_a = '1' then
          ram(to_integer(unsigned(addr_a))) := din_a;
        end if;
      end if;
      if rst_a = '1' then
        dout_a  <= (dout_a'range => '0');
      end if;
    end if;
  end process PORT_A;

  PORT_B: process(clk_b,en_b) is
  begin
    if rising_edge(clk_b) then
      if en_b = '1' then
        dout_b  <= ram(to_integer(unsigned(addr_b)));
        if we_b = '1' then
          ram(to_integer(unsigned(addr_b))) := din_b;
        end if;
      end if;
      if rst_b = '1' then
        dout_b  <= (dout_b'range => '0');
      end if;
    end if;
  end process PORT_B;

end architecture infer;
