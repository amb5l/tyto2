--------------------------------------------------------------------------------
-- memac_tx_rmii.vhd                                                          --
-- Modular Ethernet MAC (MEMAC): transmit UMI to RMII shim.                   --
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

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package memac_tx_rmii_pkg is

  component memac_tx_rmii is
    port (
      rst  : in    std_ulogic;
      umii : inout umii_t;
      rmii : inout rmii_tx_t
    );
  end component memac_tx_rmii;

end package memac_tx_rmii_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_tx_rmii is
  port (
    rst  : in    std_ulogic;
    umii : inout umii_t;     -- clk is output
    rmii : inout rmii_tx_t   -- clk is input
  );
end entity memac_tx_rmii;

architecture rtl of memac_tx_rmii is

  signal i_clken : std_ulogic;
  signal i_phase : integer range 0 to 3;
  signal i_en    : std_ulogic;
  signal i_d     : std_ulogic_vector(7 downto 0);

  signal i_count : integer range 0 to 9;
  signal i_div   : integer range 0 to 9;

begin

  --umii.clk <= rmii.clk;
--
  --P_MAIN: process(rst, rmii.clk)
  --begin
  --  if rst then
  --    rmii.en  <= '0';
  --    rmii.d   <= (others => '0');
  --  elsif rising_edge(rmii.clk) then
  --    i_clken <= '0';
  --    if umii.clken = '1' then
  --      i_clken <= '1';
  --      i_phase <= 0;
  --      i_en    <= umii.dv;
  --      i_d     <= umii.d;
  --      i_div   <= 9 when rmii.spd = '1' else 0;
  --      i_count <= 0;
  --    elsif i_count = i_div then
  --      i_clken <= '1';
  --      i_count <= 0;
  --      i_phase <= (i_phase + 1) mod 4;
  --    else
  --      i_count <= i_count + 1;
  --    end if;
  --    if i_clken = '1' then
  --      case i_phase is
  --        when 0 =>
  --          rmii.en  <= i_en;
  --          rmii.d   <= i_d(1 downto 0);
  --        when 1 =>
  --          rmii.en  <= i_en(0);
  --          rmii.d   <= i_d(3 downto 2);
  --        when 2 =>
  --          rmii.en  <= i_en;
  --          rmii.d   <= i_d(5 downto 4);
  --        when 3 =>
  --          rmii.en  <= i_en;
  --          rmii.d   <= i_d(7 downto 6);
  --        when others =>
  --          i_phase <= 0;
  --      end case;
  --    end if;
  --  end if;
  --end process P_MAIN;

end architecture rtl;
