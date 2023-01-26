library ieee;
  use ieee.std_logic_1164.all;

package i2c_rom_2k_pkg is

  component i2c_rom_2k is
    generic (
      addr  : std_logic_vector(7 downto 1)
    );
    port (
      reset : in	  std_logic;
      scl   : in	  std_logic;
      sda_i : in    std_logic;
      sda_o : out   std_logic
    );
  end component i2c_rom_2k;

end package i2c_rom_2k_pkg;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity i2c_rom_2k is
  generic (
    addr  : std_logic_vector(7 downto 1)
  );
	port (
    reset : in	  std_logic;
		scl   : in	  std_logic;
		sda_i : in    std_logic;
		sda_o : out   std_logic
	);
end entity i2c_rom_2k;

architecture synth of i2c_rom_2k is

  type phase_t is (SLAVE_ADDR,SUB_ADDR,WRITE_DATA,READ_DATA);

  signal start   : std_logic;
  signal start1  : std_logic;
  signal start2  : std_logic;
  signal stop    : std_logic;
  signal phase   : phase_t;
  signal count   : integer range 0 to 9;
  signal r_w     : std_logic;
  signal ack     : std_logic;
  signal subaddr : std_logic_vector(7 downto 0);
  signal sri     : std_logic_vector(7 downto 0);
  signal sro     : std_logic_vector(7 downto 0);

  type rom_t is array(0 to 255) of std_logic_vector(7 downto 0);
  constant rom : rom_t := (
    x"01", x"02", x"03", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00",
    x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"
  );

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
      sro     <= (others => '0');
      sri     <= (others => '0');
      count   <= 0;
      phase   <= SLAVE_ADDR;
      r_w     <= '0';
      ack     <= '0';
      if reset = '1' then
        subaddr <= (others => '0');
      end if;
    elsif falling_edge(scl) then
      sro(7 downto 0) <= sro(6 downto 0) & '0';
      sri(7 downto 0) <= sri(6 downto 0) & sda_i;
      ack <= '0';
      if count = 7 then
        ack <= '1';
        if phase = SLAVE_ADDR then
          r_w <= sda_i;
          if sri(6 downto 0) /= addr then
            ack <= '0';
          end if;
        elsif phase = SUB_ADDR then
          subaddr <= sri;
        end if;
      end if;
      if count = 8 then
        sro     <= rom(to_integer(unsigned(subaddr)));
        if phase = SLAVE_ADDR then
          if r_w = '0' then
            phase <= SUB_ADDR;
          else
            phase <= READ_DATA;
          end if;
        elsif phase = SUB_ADDR then
          phase <= WRITE_DATA;
        elsif phase = WRITE_DATA or phase = READ_DATA  then
          subaddr <= std_logic_vector(unsigned(subaddr)+1);
        end if;
        count <= 0;
      else
        count <= count+1;
      end if;
    end if;
  end process;
  sda_o <= '0' when ack = '1' else sro(7) when phase = READ_DATA else '1';

end architecture synth;
