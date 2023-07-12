--------------------------------------------------------------------------------
-- i2c_rep_uni.vhd                                                            --
-- I2C repeater - unidirectional.                                             --
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

library ieee;
  use ieee.std_logic_1164.all;

package i2c_rep_uni_pkg is

  component i2c_rep_uni is
    port (
      reset : in	  std_logic; -- reset
      m_scl : inout std_logic; -- master I2C clock
      m_sda : inout std_logic; -- master I2C data
      s_scl : inout std_logic; -- slave I2C clock
      s_sda : inout std_logic  -- slave I2C data
    );
  end component i2c_rep_uni;

end package i2c_rep_uni_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;

entity i2c_rep_uni is
	port (
    reset : in	  std_logic; -- reset
		m_scl : inout std_logic; -- master I2C clock
		m_sda : inout std_logic; -- master I2C data
		s_scl : inout std_logic; -- slave I2C clock
		s_sda : inout std_logic  -- slave I2C data
	);
end entity i2c_rep_uni;

architecture synth of i2c_rep_uni is

  signal m_scl_i          : std_logic;
  signal m_sda_o          : std_logic;
  signal m_sda_i          : std_logic;
  signal s_scl_o          : std_logic;
  signal s_sda_o          : std_logic;
  signal s_sda_i          : std_logic;

  signal m_start_toggle   : std_logic;
  signal m_stop_toggle    : std_logic;
  signal m_active         : std_logic;
  signal m_restart_toggle : std_logic;
  signal m_first_toggle   : std_logic;
  signal count_rst        : std_logic;
  signal count            : integer range 0 to 8;
  signal r_w              : std_logic_vector(0 to 1);
  signal s2m              : std_logic;

begin

  m_scl <= 'Z';
  m_sda <= '0' when m_sda_o = '0' else 'Z';
  s_scl <= '0' when s_scl_o = '0' else 'Z';
  s_sda <= '0' when s_sda_o = '0' else 'Z';

  m_scl_i <= m_scl;
  m_sda_i <= m_sda;
  m_sda_o <= '0' when s2m = '1' and s_sda_i = '0' else '1';
  s_scl_o <= m_scl_i;
  s_sda_i <= s_sda;
  s_sda_o <= '0' when s2m = '0' and m_sda_i = '0' else '1';

  -- toggles at start only (not restart)
  process(reset,m_sda_i)
  begin
    if reset = '1' then
      m_start_toggle <= '0';
    elsif falling_edge(m_sda_i) and m_scl_i >= 'H' then
      m_start_toggle <= not m_stop_toggle;
    end if;
  end process;

  -- toggles at stop
  process(reset,m_sda_i)
  begin
    if reset = '1' then
      m_stop_toggle <= '0';
    elsif rising_edge(m_sda_i) and m_scl_i >= 'H' then
      m_stop_toggle <= m_start_toggle;
    end if;
  end process;

  m_active  <= m_start_toggle xor m_stop_toggle;

  -- toggles at start or restart
  process(reset,m_sda_i)
  begin
    if reset = '1' then
      m_restart_toggle <= '0';
    elsif falling_edge(m_sda_i) and m_scl_i >= 'H' then
      m_restart_toggle <= not m_restart_toggle;
    end if;
  end process;

  -- toggles at first clock after start/restart
  process(reset,m_scl_i)
  begin
    if reset = '1' then
      m_first_toggle <= '0';
    elsif falling_edge(m_scl_i) then
      m_first_toggle <= m_restart_toggle;
    end if;
  end process;

  count_rst <= m_restart_toggle xor m_first_toggle;

  process(count_rst,m_scl_i)
  begin
    if count_rst = '1' then
      count <= 0;
    elsif rising_edge(m_scl_i) then
      if count = 8 then
        count <= 0;
      else
        count <= count+1;
      end if;
    end if;
  end process;

  process(m_active,m_scl_i)
  begin
    if m_active = '0' then
      r_w   <= (others => '0');
    elsif rising_edge(m_scl_i) then
      r_w(1) <= r_w(0);
      if count = 7 then
        r_w(0) <= r_w(0) or m_sda_i;
      end if;
    end if;
  end process;

  process(m_active,m_scl_i)
  begin
    if m_active = '0' then
      s2m <= '0';
    elsif falling_edge(m_scl_i) then
      if count = 8 then
        s2m <= not r_w(1);
      else
        s2m <= r_w(1);
      end if;
    end if;
  end process;

end architecture synth;
