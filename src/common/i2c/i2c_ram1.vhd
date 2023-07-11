--------------------------------------------------------------------------------
-- i2c_ram1.vhd                                                               --
-- I2C 24LCxx EEPROM emulating RAM, 1 byte sub address, 128-2048 bytes.       --
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

library work;
  use work.tyto_types_pkg.all;

package i2c_ram1_pkg is

  component i2c_ram1 is
    generic (
      addr       : std_logic_vector(7 downto 1) := "1010000";
      depth_log2 : integer range 7 to 11 := 7;
      init       : slv8_vector := (0 to 127 => x"00")
    );
    port (
      reset      : in    std_logic;
      scl        : in    std_logic;
      sda_i      : in    std_logic;
      sda_o      : out   std_logic
    );
  end component i2c_ram1;

end package i2c_ram1_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;

entity i2c_ram1 is
  generic (
    addr       : std_logic_vector(7 downto 1) := "1010000"; -- slave address (base)
    depth_log2 : integer range 7 to 11 := 7;                -- 2^depth_log2 bytes
    init       : slv8_vector := (0 to 127 => x"00")         -- initial contents
  );
  port (
    reset      : in    std_logic;                           -- reset
    scl        : in    std_logic;                           -- I2C clock
    sda_i      : in    std_logic;                           -- I2C data in
    sda_o      : out   std_logic                            -- I2C data out
  );
end entity i2c_ram1;

architecture synth of i2c_ram1 is

  type phase_t is (SLAVE_ADDR,SUB_ADDR,WRITE_DATA,READ_DATA);

  signal start    : std_logic;
  signal start1   : std_logic;
  signal start2   : std_logic;
  signal stop     : std_logic;
  signal phase    : phase_t;
  signal count    : integer range 0 to 9;
  signal r_w      : std_logic;
  signal ack      : std_logic;
  signal bsel     : std_logic_vector(2 downto 0);
  signal subaddr  : std_logic_vector(7 downto 0);
  signal sri      : std_logic_vector(7 downto 0);
  signal sro      : std_logic_vector(7 downto 0);

  signal ram      : slv8_vector(0 to (2**depth_log2)-1) := init;
  signal ram_we   : std_logic;
  signal ram_addr : std_logic_vector(depth_log2-1 downto 0);
  signal ram_din  : std_logic_vector(7 downto 0);
  signal ram_dout : std_logic_vector(7 downto 0);

begin

  -- start
  process(reset,scl,sda_i,start2)
  begin
    if reset = '1' or start2 = '1' then
      start <= '0';
    elsif falling_edge(sda_i) and scl = '1' then
      start <= '1';
    end if;
    if reset = '1' then
      start1 <= '0';
    elsif falling_edge(scl) then
      start1 <= start;
    end if;
    if reset = '1' then
      start2 <= '0';
    elsif rising_edge(scl) then
      start2 <= start1;
    end if;
  end process;

  -- stop
  process(reset,scl,sda_i)
  begin
    if reset = '1' or scl = '0' then
      stop <= '0';
    elsif rising_edge(sda_i) and scl = '1' then
      stop <= '1';
    end if;
  end process;

  -- sro, sri, count, phase, r_w, ack, subaddr, sda_o
  process(reset,start,stop,scl)
  begin
    if reset = '1' or start = '1' or stop = '1' then
      sro      <= (others => '0');
      sri      <= (others => '0');
      count    <= 0;
      phase    <= SLAVE_ADDR;
      r_w      <= '0';
      ack      <= '0';
      if reset = '1' then
        subaddr <= (others => '0');
      end if;
    elsif falling_edge(scl) then
      sro(7 downto 0) <= sro(6 downto 0) & '0';
      sri(7 downto 0) <= sri(6 downto 0) & sda_i;
      ack <= '0';
      if count = 7 then
        if phase = SLAVE_ADDR then
          r_w <= sda_i;
          bsel <= sri(2 downto 0);
          if sri(6 downto 0) = addr then
            ack <= '1';
          else
            ack <= '0';
          end if;
        elsif phase = SUB_ADDR then
          ack <= '1';
          subaddr<= sri(6 downto 0) & sda_i;
        else
          ack <= not r_w; -- don't ack reads
          subaddr <= std_logic_vector(unsigned(subaddr)+1);
        end if;
      end if;
      if count = 8 then
        sro <= ram_dout;
        if phase = SLAVE_ADDR then
          if r_w = '0' then
            phase <= SUB_ADDR;
          else
            phase <= READ_DATA;
          end if;
        elsif phase = SUB_ADDR then
          phase <= WRITE_DATA;
        end if;
        count <= 0;
      else
        count <= count+1;
      end if;
    end if;
  end process;
  sda_o <= '0' when ack = '1' else sro(7) when (phase = READ_DATA and count /= 8) else '1';

  -- synchronous RAM
  ram_we <= '1' when phase = WRITE_DATA and count = 8 else '0';
  ram_addr <=
    bsel(2 downto 0) & subaddr(7 downto 0) when depth_log2 = 11 else
    bsel(1 downto 0) & subaddr(7 downto 0) when depth_log2 = 10 else
    bsel(0)          & subaddr(7 downto 0) when depth_log2 =  9 else
                       subaddr(7 downto 0) when depth_log2 =  8 else
                       subaddr(6 downto 0); -- when depth_log2 = 7
  ram_din <= sri;
  process(scl)
  begin
    if rising_edge(scl) then
      ram_dout <= ram(to_integer(unsigned(ram_addr)));
      if ram_we = '1' then
        ram(to_integer(unsigned(ram_addr))) <= ram_din;
      end if;
    end if;
  end process;

end architecture synth;
