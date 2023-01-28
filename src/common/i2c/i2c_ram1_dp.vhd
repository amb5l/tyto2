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
      reset      : in	   std_logic;
      scl        : in	   std_logic;
      sda_i      : in    std_logic;
      sda_o      : out   std_logic;
      dp_clk     : in	  std_logic;
      dp_we      : in	  std_logic;
      dp_addr    : in	  std_logic_vector(depth_log2-1 downto 0);
      dp_din     : in   std_logic_vector(7 downto 0);
      dp_dout    : out  std_logic_vector(7 downto 0)
    );
  end component i2c_ram1;

end package i2c_ram1_pkg;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;

entity i2c_ram1 is
  generic (
    addr       : std_logic_vector(7 downto 1) := "1010000"; -- slave address (base)
    depth_log2 : integer range 7 to 11 := 7;                   -- 2^depth_log2 bytes
    init       : slv8_vector := (0 to 127 => x"00")            -- initial contents
  );                                                           
	port (                                                       
    reset      : in	  std_logic;                               -- reset
		scl        : in	  std_logic;                               -- I2C clock
		sda_i      : in   std_logic;                               -- I2C data in
		sda_o      : out  std_logic                                -- I2C data out
    dp_clk     : in	  std_logic;                               -- RAM clk          } 2nd port
    dp_we      : in	  std_logic;                               -- RAM write enable }
    dp_addr    : in	  std_logic_vector(depth_log2-1 downto 0); -- RAM address      }
    dp_din     : in   std_logic_vector(7 downto 0);            -- RAM data in      }
    dp_dout    : out  std_logic_vector(7 downto 0)             -- RAM data out     }
	);
end entity i2c_ram1;

architecture synth of i2c_ram1 is

  type phase_t is (SLAVE_ADDR,SUB_ADDR,WRITE_DATA,READ_DATA);

  signal start      : std_logic;
  signal start1     : std_logic;
  signal start2     : std_logic;
  signal stop       : std_logic;
  signal phase      : phase_t;
  signal count      : integer range 0 to 9;
  signal r_w        : std_logic;
  signal ack        : std_logic;
  signal bsel       : std_logic_vector(2 downto 0);
  signal subaddr    : std_logic_vector(7 downto 0);
  signal sri        : std_logic_vector(7 downto 0);
  signal sro        : std_logic_vector(7 downto 0);

  signal ram_we_a   : std_logic;
  signal ram_addr_a : std_logic_vector(depth_log2-1 downto 0);
  signal ram_din_a  : std_logic_vector(7 downto 0);
  signal ram_dout_a : std_logic_vector(7 downto 0);
  signal ram_we_b   : std_logic;
  signal ram_addr_b : std_logic_vector(depth_log2-1 downto 0);
  signal ram_din_b  : std_logic_vector(7 downto 0);
  signal ram_dout_b : std_logic_vector(7 downto 0);

  function ram_init return std_logic_vector_2d is
    variable r : std_logic_vector_2d(0 to (2**depth_log2)-1,7 downto 0);
  begin
    r := (others => (others => '0'));
    for i in 0 to  (2**depth_log2)-1 loop
      for j in 0 to 7 loop
        r(i)(j) := init(i)(j);
      end loop;
    end loop;
    return r;
  end function ram_init;

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
        ack <= '1';
        if phase = SLAVE_ADDR then
          r_w <= sda_i;
          bsel <= sri(2 downto 0);
          if sri(6 downto 0) /= addr then
            ack <= '0';
          end if;
        elsif phase = SUB_ADDR then
          subaddr<= sri(6 downto 0) & sda_i;
        else
          subaddr <= std_logic_vector(unsigned(subaddr)+1);
        end if;
      end if;
      if count = 8 then
        sro <= ram_dout_a;
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
  sda_o <= '0' when ack = '1' else sro(7) when phase = READ_DATA else '1';

  -- synchronous RAM (dual port)
  ram_clk_a <= scl;
  ram_we_a <= '1' when phase = WRITE_DATA and count = 8 else '0';
  ram_addr_a <=
    bsel(2 downto 0) & subaddr(7 downto 0) when depth_log2 = 11 else
    bsel(1 downto 0) & subaddr(7 downto 0) when depth_log2 = 10 else
    bsel(0)          & subaddr(7 downto 0) when depth_log2 =  9 else
                       subaddr(7 downto 0) when depth_log2 =  8 else
                       subaddr(6 downto 0); -- when depth_log2 = 7
  ram_din_a <= sri;
  ram_clkb <= dp_clk;
  ram_we_b <= dp_we;
  ram_addr_b <= dp_addr;
  ram_din_b <= dp_din;
  dp_dout <= ram_dout_b;
  RAM: component ram_tdp_ar
    generic map (
      width      => 8,
      depth_log2 => depth_log2,
      init       => sl2d_t(ram_init)
    )
    port map (
      clk_a      => ram_clk_a,
      rst_a      => '0',
      ce_a       => '1',
      we_a       => ram_we_a,
      addr_a     => ram_addr_a,
      din_a      => ram_din_a,
      dout_a     => ram_dout_a,
      clk_b      => ram_clk_b
      rst_b      => '0',
      ce_b       => '1',
      we_b       => ram_we_a,
      addr_b     => ram_addr_a,
      din_b      => ram_din_a,
      dout_b     => ram_dout_a,
    );

end architecture synth;
