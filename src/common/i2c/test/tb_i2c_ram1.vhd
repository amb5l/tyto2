--------------------------------------------------------------------------------
-- tb_i2c_ram1_pkg.vhd                                                        --
-- Simulation testbench for i2c_ram1.vhd.                                     --
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
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.i2c_ram1_pkg.all;

entity tb_i2c_ram1_pkg is
end entity tb_i2c_ram1_pkg;

architecture sim of tb_i2c_ram1_pkg is

  constant TI2C              : time := 5 us;
  constant I2C_SLAVE_ADDRESS : std_logic_vector(7 downto 1) := "1010000";
  constant RAM_SIZE_LOG2     : integer := 8; -- 2**8 = 256 bytes

  signal reset : std_logic;
  signal scl   : std_logic := 'Z';
  signal sda   : std_logic := 'Z';

  signal scl_i : std_logic;
  signal sda_i : std_logic;
  signal sda_o : std_logic;

  procedure i2c_start(
    signal scl : out   std_logic;
    signal sda : out   std_logic
  ) is
  begin
    scl <= 'Z';
    sda <= 'Z';
    wait for TI2C;
    sda <= '0';
    wait for TI2C;
    scl <= '0';
    wait for TI2C;
    sda <= 'Z';
    return;
  end procedure i2c_start;

  procedure i2c_stop(
    signal scl : out   std_logic;
    signal sda : out   std_logic
  ) is
  begin
    sda <= '0';
    wait for TI2C;
    scl <= 'Z';
    wait for TI2C;
    sda <= 'Z';
    wait for TI2C;
    return;
  end procedure i2c_stop;

  procedure i2c_bit(
           dout : in    std_logic;
           din  : out   std_logic;
    signal scl  : out   std_logic;
    signal sda  : inout std_logic
  ) is
  begin
    if dout = '0' then
      sda <= '0';
    else
      sda <= 'Z';
    end if;
    wait for TI2C;
    scl <= 'Z';
    wait for TI2C;
    din := sda;
    scl <= '0';
    wait for TI2C;
    sda <= 'Z';
    return;
  end procedure i2c_bit;

  procedure i2c_byte_io(
           dout : in    std_logic_vector(7 downto 0);
           din  : out   std_logic_vector(7 downto 0);
           ack  : out   std_logic;
    signal scl  : out   std_logic;
    signal sda  : inout std_logic
  ) is
  begin
    for i in 7 downto 0 loop
      i2c_bit(dout(i),din(i),scl,sda);
    end loop;
    i2c_bit('1',ack,scl,sda);
    return;
  end procedure i2c_byte_io;

  procedure i2c_byte_o(
           dout : in    std_logic_vector(7 downto 0);
           ack  : out   std_logic;
    signal scl  : out   std_logic;
    signal sda  : inout std_logic
  ) is
    variable dummy : std_logic_vector(7 downto 0);
  begin
    i2c_byte_io(dout,dummy,ack,scl,sda);
    return;
  end procedure i2c_byte_o;

  procedure i2c_ram1_addr(
           addr : in    std_logic_vector(RAM_SIZE_LOG2-1 downto 0);
           ack  : out   std_logic;
    signal scl  : out   std_logic;
    signal sda  : inout std_logic
  ) is
    variable a  : std_logic_vector(7 downto 1);
    variable sa : std_logic_vector(7 downto 0);
  begin
    a := I2C_SLAVE_ADDRESS;
    if RAM_SIZE_LOG2 >= 12 then
      a(RAM_SIZE_LOG2-11 downto 1) := addr(RAM_SIZE_LOG2-1 downto 8);
    end if;
    sa(6 downto 0) := addr(6 downto 0);
    if RAM_SIZE_LOG2 >= 11 then
      sa(7) := addr(7);
    end if;
    i2c_byte_o(a & '0',ack,scl,sda);
    if ack = '1' then
      return;
    end if;
    i2c_byte_o(sa,ack,scl,sda);
    return;
  end procedure i2c_ram1_addr;

  procedure i2c_ram1_read(
           addr : in    std_logic_vector(RAM_SIZE_LOG2-1 downto 0);
           n    : in    integer;
           din  : out   slv8_vector;
           ack  : out   std_logic;
    signal scl  : out   std_logic;
    signal sda  : inout std_logic
  ) is
    variable a  : std_logic_vector(7 downto 1);
  begin
    a := I2C_SLAVE_ADDRESS;
    if RAM_SIZE_LOG2 >= 12 then
      a(RAM_SIZE_LOG2-11 downto 1) := addr(RAM_SIZE_LOG2-1 downto 8);
    end if;
    i2c_byte_o(a & '1',ack,scl,sda);
    if ack = '1' then
      return;
    end if;
    for i in 0 to n-1 loop
      i2c_byte_io(x"FF",din(i),ack,scl,sda);
      if ack = '1' then
        return;
      end if;
    end loop;
    return;
  end procedure i2c_ram1_read;

  function ram_init return slv8_vector is
    variable r: slv8_vector(0 to (2**RAM_SIZE_LOG2)-1);
  begin
    for i in 0 to r'length-1 loop
      r(i) := std_logic_vector(to_unsigned(i mod 256,8));
    end loop;
    return r;
  end function ram_init;

begin

  scl <= 'H'; -- pullups
  sda <= 'H'; -- "

  process
    variable ack : std_logic;
    variable din : slv8_vector(0 to (2**RAM_SIZE_LOG2)-1);
  begin

    reset <= '1';
    wait for TI2C;
    reset <= '0';
    wait for TI2C;

    i2c_start(scl,sda);
    i2c_ram1_addr(x"80",ack,scl,sda);
    i2c_stop(scl,sda);
    if ack = '1' then
      report "NACK" severity failure;
    end if;
    i2c_start(scl,sda);
    i2c_ram1_read(x"80",8,din,ack,scl,sda);
    if ack = '1' then
      report "NACK" severity failure;
    end if;
    i2c_stop(scl,sda);

    i2c_start(scl,sda);
    i2c_ram1_addr(x"90",ack,scl,sda);
    if ack = '1' then
      report "NACK" severity failure;
    end if;
    i2c_start(scl,sda);
    i2c_ram1_read(x"90",8,din,ack,scl,sda);
    if ack = '1' then
      report "NACK" severity failure;
    end if;
    i2c_stop(scl,sda);

    report "SUCCESS!";

    wait;
  end process;

  DUT: component i2c_ram1
    generic map (
      addr       => "1010000",
      depth_log2 => RAM_SIZE_LOG2, -- 2^11 = 2048 bits = 256 bytes
      init       => ram_init
    )
    port map (
      reset      => reset,
      scl        => scl_i,
      sda_o      => sda_o,
      sda_i      => sda_i
    );

  scl_i <= '0' when scl = '0' else '1' when scl = 'H' else 'X';
  sda_i <= '0' when sda = '0' else '1' when sda = 'H' else 'X';
  sda <= '0' when sda_o = '0' else 'Z';

end architecture sim;
