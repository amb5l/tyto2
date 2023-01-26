library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.i2c_rom_2k_pkg.all;

entity tb_i2c_rom_2k is
end entity tb_i2c_rom_2k;

architecture sim of tb_i2c_rom_2k is

  constant ti2c : time := 5 us;
  constant I2C_SLAVE_ADDRESS : std_logic_vector(7 downto 1) := "1010000";

  procedure i2c_start(
           t    : in    time;
    signal scl  : out   std_logic;
    signal sda  : out   std_logic
  ) is
  begin
    sda <= '0';
    wait for t;
    scl <= '0';
    wait for t;
    sda <= 'Z';
  end procedure i2c_start;

  procedure i2c_stop(
           t    : in    time;
    signal scl  : out   std_logic;
    signal sda  : out   std_logic
  ) is
  begin
    sda <= '0';
    wait for t;
    scl <= 'Z';
    wait for t;
    sda <= 'Z';
    wait for t;
  end procedure i2c_stop;

  procedure i2c_bit(
           t    : in    time;
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
    wait for t;
    scl <= 'Z';
    wait for t;
    din := sda;
    scl <= '0';
    wait for t;
    sda <= 'Z';
  end procedure i2c_bit;

  procedure i2c_byte(
           t    : in    time;
           dout : in    std_logic_vector(7 downto 0);
           din  : out   std_logic_vector(7 downto 0);
    signal scl  : out   std_logic;
    signal sda  : inout std_logic
  ) is
  begin
    for i in 7 downto 0 loop
      i2c_bit(t,dout(i),din(i),scl,sda);
    end loop;
  end procedure i2c_byte;

  procedure i2c_set_subaddr(
           t       : in    time;
           addr    : in    std_logic_vector(7 downto 1);
           subaddr : in    std_logic_vector(7 downto 0);
    signal scl     : out   std_logic;
    signal sda     : inout std_logic
  ) is
    variable r : std_logic_vector(7 downto 0);
    variable ack : std_logic;
  begin
    i2c_start(t,scl,sda);
    i2c_byte(t,addr & '0',r,scl,sda);
    i2c_bit(t,'1',ack,scl,sda);
    if ack = '0' then
      i2c_byte(t,subaddr,r,scl,sda);
      i2c_bit(t,'1',ack,scl,sda);
    end if;
    i2c_stop(t,scl,sda);
  end procedure i2c_set_subaddr;

  procedure i2c_read(
           t       : in    time;
           addr    : in    std_logic_vector(7 downto 1);
    signal scl     : out   std_logic;
    signal sda     : inout std_logic
  ) is
    variable r : std_logic_vector(7 downto 0);
    variable ack : std_logic;
  begin
    i2c_start(t,scl,sda);
    i2c_byte(t,addr & '1',r,scl,sda);
    i2c_bit(t,'1',ack,scl,sda);
    if ack = '0' then
      i2c_byte(t,x"FF",r,scl,sda);
      i2c_bit(t,'1',ack,scl,sda);
    end if;
    i2c_stop(t,scl,sda);
  end procedure i2c_read;

  signal reset : std_logic;
  signal scl   : std_logic := 'Z';
  signal sda   : std_logic := 'Z';

  signal scl_i : std_logic;
  signal sda_i : std_logic;
  signal sda_o : std_logic;

begin

  scl <= 'H'; -- pullups
  sda <= 'H'; -- "

  process
  begin
    reset <= '1';
    wait for ti2c;
    reset <= '0';
    wait for ti2c;
    i2c_set_subaddr(ti2c,I2C_SLAVE_ADDRESS,x"00",scl,sda);
    i2c_read(ti2c,I2C_SLAVE_ADDRESS,scl,sda);
    wait;
  end process;

  DUT: component i2c_rom_2k
    generic map (
      addr => "1010000"
    )
    port map (
      reset => reset,
      scl   => scl_i,
      sda_o => sda_o,
      sda_i => sda_i
    );

  scl_i <= '0' when scl = '0' else '1' when scl = 'H' else 'X';
  sda_i <= '0' when sda = '0' else '1' when sda = 'H' else 'X';
  sda <= '0' when sda_o = '0' else 'Z';

end architecture sim;
