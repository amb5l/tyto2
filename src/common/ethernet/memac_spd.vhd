--------------------------------------------------------------------------------
-- memac_spd.vhd                                                              --
-- Modular Ethernet MAC: speed detector.                                      --
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

package memac_spd_pkg is

  component memac_spd is
    port (
      ref_rst : in    std_ulogic;
      ref_clk : in    std_ulogic;
      umi_rst : in    std_ulogic;
      umi_clk : in    std_ulogic;
      umi_spd : out   std_ulogic_vector(1 downto 0)
    );
  end component memac_spd;

end package memac_spd_pkg;

--------------------------------------------------------------------------------

use work.sync_reg_u_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_spd is
  port (
    ref_rst : in    std_ulogic;
    ref_clk : in    std_ulogic;
    umi_rst : in    std_ulogic;
    umi_clk : in    std_ulogic;
    umi_spd : out   std_ulogic_vector(1 downto 0)
  );
end entity memac_spd;

architecture rtl of memac_spd is

  signal clk_div : std_ulogic_vector(3 downto 0);
  signal f       : std_ulogic;
  signal f_r     : std_ulogic;
  signal phase   : std_ulogic;
  signal count   : unsigned(9 downto 0);

begin

  P_DIV: process(umi_rst,umi_clk)
  begin
    if umi_rst = '1' then
      clk_div <= (others => '0');
    elsif rising_edge(umi_clk) then
      clk_div <= std_ulogic_vector(unsigned(clk_div)+1);
    end if;
  end process P_DIV;

  U_SYNC: sync_reg_u
    generic map (
      stages => 3
    )
    port map (
      rst  => ref_rst,
      clk  => ref_clk,
      i(0) => clk_div(3),
      o(0) => f
    );

  P_COUNT: process(ref_rst,ref_clk)
  begin
    if ref_rst = '1' then
      phase <= '0';
      count <= (others => '0');
      f_r   <= '0';
      umi_spd   <= "11";
    elsif rising_edge(ref_clk) then
      f_r <= f;
      if f = '1' and f_r = '1' then
        phase <= '1';
      elsif f = '0' and f_r = '0' then
        phase <= '0';
      end if;
      if f = '1' and f_r = '1' and phase = '0' then
        if    count >= 750 and count <= 850 then umi_spd <= "00";
        elsif count >=  70 and count <=  90 then umi_spd <= "01";
        elsif count >=  14 and count <=  18 then umi_spd <= "10";
        else                                     umi_spd <= "11";
        end if;
        count <= (others => '0');
      else
        if (not count) = 0 then
          umi_spd <= "11";
        end if;
        count <= count + 1;
      end if;
    end if;
  end process P_COUNT;

end architecture rtl;
