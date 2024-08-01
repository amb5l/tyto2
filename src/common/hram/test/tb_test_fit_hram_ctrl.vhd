use work.tyto_sim_pkg.all;
use work.model_hram_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_test_fit_hram_ctrl is
end entity tb_test_fit_hram_ctrl;

architecture sim of tb_test_fit_hram_ctrl is

  type data_vector is array(natural range <>) of std_ulogic_vector(15 downto 0);

  constant tclk   : time := 10 ns; -- 50 MHz !!!
  constant tdelay : time := 3 ns;
  constant TEST_SIZE : integer := 2**16;

  signal debug     : std_ulogic_vector(5 downto 0);

  signal ref_rst   : std_ulogic;
  signal ref_clk   : std_ulogic;

  signal u_clk_o   : std_ulogic;
  signal u_clk     : std_ulogic;
  signal u_rst     : std_ulogic;
  signal u_a_ready : std_ulogic;
  signal u_a_valid : std_ulogic;
  signal u_a_r_w   : std_ulogic;
  signal u_a_reg   : std_ulogic;
  signal u_a_wrap  : std_ulogic;
  signal u_a_size  : std_ulogic_vector(5 downto 0);
  signal u_a_addr  : std_ulogic_vector(31 downto 0);
  signal u_w_ready : std_ulogic;
  signal u_w_valid : std_ulogic;
  signal u_w_be    : std_ulogic_vector(1 downto 0);
  signal u_w_data  : std_ulogic_vector(15 downto 0);
  signal u_r_ready : std_ulogic;
  signal u_r_valid : std_ulogic;
  signal u_r_data  : std_ulogic_vector(15 downto 0);

  signal s_clk_o   : std_ulogic;
  signal s_clk     : std_ulogic;
  signal s_rst     : std_ulogic;
  signal s_a_ready : std_ulogic;
  signal s_a_valid : std_ulogic;
  signal s_a_r_w   : std_ulogic;
  signal s_a_reg   : std_ulogic;
  signal s_a_wrap  : std_ulogic;
  signal s_a_size  : std_ulogic_vector(5 downto 0);
  signal s_a_addr  : std_ulogic_vector(31 downto 0);
  signal s_w_ready : std_ulogic;
  signal s_w_valid : std_ulogic;
  signal s_w_be    : std_ulogic_vector(1 downto 0);
  signal s_w_data  : std_ulogic_vector(15 downto 0);
  signal s_r_ready : std_ulogic;
  signal s_r_valid : std_ulogic;
  signal s_r_data  : std_ulogic_vector(15 downto 0);

  signal h_rst_n   : std_logic;
  signal h_cs_n    : std_logic;
  signal h_clk     : std_logic;
  signal h_rwds    : std_logic;
  signal h_dq      : std_logic_vector(7 downto 0);

  constant ADDR_IDREG0  : integer := 16#0000#;
  constant ADDR_IDREG1  : integer := 16#0002#;
  constant ADDR_CFGREG0 : integer := 16#1000#;
  constant ADDR_CFGREG1 : integer := 16#1002#;

  constant DATA_IDREG0  : std_ulogic_vector(15 downto 0) := "0000110010000011";
  constant DATA_IDREG1  : std_ulogic_vector(15 downto 0) := x"0000";
  constant DATA_CFGREG0 : std_ulogic_vector(15 downto 0) := "1000111111110111";
  constant DATA_CFGREG1 : std_ulogic_vector(15 downto 0) := x"0002";

  function hram_params(i : hram_params_t) return hram_params_t is
    variable r : hram_params_t;
  begin
    r := i;
    r.tVCS := 10.0; -- override tVCS to shorten simulation time
    return r;
  end function hram_params;

  component test_fit_hram_ctrl is
    port (
      debug     : out   std_logic_vector(5 downto 0);
      ref_rst   : in    std_logic;
      ref_clk   : in    std_logic;
      s_clk_o   : out   std_logic;
      s_rst_o   : out   std_logic;
      s_a_ready : out   std_logic;
      s_a_valid : in    std_logic;
      s_a_r_w   : in    std_logic;
      s_a_reg   : in    std_logic;
      s_a_wrap  : in    std_logic;
      s_a_size  : in    std_logic_vector(5 downto 0);
      s_a_addr  : in    std_logic_vector(22 downto 1);
      s_w_ready : out   std_logic;
      s_w_valid : in    std_logic;
      s_w_be    : in    std_logic_vector(1 downto 0);
      s_w_data  : in    std_logic_vector(15 downto 0);
      s_r_ready : in    std_logic;
      s_r_valid : out   std_logic;
      s_r_data  : out   std_logic_vector(15 downto 0);
      h_rst_n   : out   std_logic;
      h_cs_n    : out   std_logic;
      h_clk     : out   std_logic;
      h_rwds    : inout std_logic;
      h_dq      : inout std_logic_vector(7 downto 0)
    );
  end component test_fit_hram_ctrl;


begin

  ref_clk <= '0' when ref_clk = 'U' else not ref_clk after tclk/2;

  --s_clk <= << signal tb_test_fit_hram_ctrl.DUT.s_clk : std_ulogic >>;
  s_clk <= s_clk_o;

  P_TEST: process

    constant B_RD  : std_ulogic := '1';
    constant B_WR  : std_ulogic := '0';
    constant B_REG : std_ulogic := '1';
    constant B_MEM : std_ulogic := '0';
    constant B_WRAP: std_ulogic := '1'; -- v4p ignore w-303
    constant B_LIN : std_ulogic := '0';

    variable addr   : integer;
    variable size   : integer;
    variable w_data : data_vector(0 to 63) := (others => (others => 'X'));
    variable r_data : data_vector(0 to 63) := (others => (others => 'X'));
    variable prng   : prng_t;

    procedure burst(
      r_w  : in    std_ulogic;
      reg  : in    std_ulogic;
      wrap : in    std_ulogic;
      size : in    integer;
      addr : in    integer;
      data : inout data_vector
    ) is
    begin
      s_a_valid <= '1';
      s_a_r_w   <= r_w;
      s_a_reg   <= reg;
      s_a_wrap  <= wrap;
      s_a_size  <= std_ulogic_vector(to_unsigned(size,s_a_size'length));
      s_a_addr  <= std_ulogic_vector(to_unsigned(addr,s_a_addr'length));
      loop
        wait until rising_edge(s_clk);
        if s_a_ready = '1' then exit; end if;
      end loop;
      s_a_valid <= '0';
      s_a_r_w   <= 'X';
      s_a_reg   <= 'X';
      s_a_wrap  <= 'X';
      s_a_size  <= (others => 'X');
      s_a_addr  <= (others => 'X');
      s_w_valid <= not r_w;
      s_r_ready <= r_w;
      for i in 0 to size-1 loop
        if r_w = '0' then
          s_w_be   <= "11";
          s_w_data <= data(i);
        end if;
        loop
          wait until rising_edge(s_clk);
          if (s_w_valid and s_w_ready)
          or (s_r_valid and s_r_ready)
          then
            exit;
          end if;
        end loop;
        if r_w = '1' then
          data(i) := s_r_data;
        end if;
      end loop;
      s_w_valid <= '0';
      s_w_be    <= (others => 'X');
      s_w_data  <= (others => 'X');
      s_r_ready <= '0';
    end procedure burst;

  begin

    ref_rst   <= '1';
    s_a_valid <= '0';
    s_a_r_w   <= 'X';
    s_a_reg   <= 'X';
    s_a_wrap  <= 'X';
    s_a_size  <= (others => 'X');
    s_a_addr  <= (others => 'X');
    s_w_valid <= '0';
    s_w_be    <= (others => 'X');
    s_w_data  <= (others => 'X');
    s_r_ready <= '0';

    wait for 100 ns;
    ref_rst <= '0';
    wait for 240*tclk;
    wait until rising_edge(s_clk);

    w_data(0) := DATA_CFGREG0;
    burst(B_WR,B_REG,B_LIN,1,ADDR_CFGREG0,w_data);

    w_data(0) := DATA_CFGREG1;
    burst(B_WR,B_REG,B_LIN,1,ADDR_CFGREG1,w_data);

    burst(B_RD,B_REG,B_LIN,1,ADDR_IDREG0,r_data);
    assert r_data(0) = DATA_IDREG0
      report "IDREG0 mismatch - read " & to_hstring(r_data(0)) & " expected " & to_hstring(DATA_IDREG0) severity failure;

    burst(B_RD,B_REG,B_LIN,1,ADDR_IDREG1,r_data);
    assert r_data(0) = DATA_IDREG1
      report "IDREG1 mismatch - read " & to_hstring(r_data(0)) & " expected " & to_hstring(DATA_IDREG1) severity failure;

    burst(B_RD,B_REG,B_LIN,1,ADDR_CFGREG0,r_data);
    assert r_data(0) = DATA_CFGREG0
      report "CFGREG0 mismatch - read " & to_hstring(r_data(0)) & " expected " & to_hstring(DATA_CFGREG0) severity failure;

    burst(B_RD,B_REG,B_LIN,1,ADDR_CFGREG1,r_data);
    assert r_data(0) = DATA_CFGREG1
      report "CFGREG1 mismatch - read " & to_hstring(r_data(0)) & " expected " & to_hstring(DATA_CFGREG1) severity failure;

    -- fill
    prng.rand_seed(123,456);
    addr := 0;
    loop
      size := prng.rand_int(1,64);
      for i in 0 to size-1 loop
        w_data(i) := prng.rand_slv(0,65535,16);
      end loop;
      burst(B_WR,B_MEM,B_LIN,size,addr,w_data);
      addr := addr + (2*size);
      if addr >= TEST_SIZE then exit; end if;
    end loop;

    -- test
    prng.rand_seed(123,456);
    addr := 0;
    loop
      size := prng.rand_int(1,64);
      for i in 0 to size-1 loop
        w_data(i) := prng.rand_slv(0,65535,16);
      end loop;
      burst(B_RD,B_MEM,B_LIN,size,addr,r_data);
      assert r_data(0 to size-1) = w_data(0 to size-1)
        report "data mismatch at address " & integer'image(addr) severity failure;
      addr := addr + (2*size);
      if addr >= TEST_SIZE then exit; end if;
    end loop;

    std.env.finish;

    wait;
  end process P_TEST;

  MEM: component model_hram
    generic map (
      SIM_MEM_SIZE => TEST_SIZE,
      OUTPUT_DELAY => "MAX",
      PARAMS       => hram_params(HRAM_8Mx8_100_3V0)
    )
    port map (
      rst_n => h_rst_n,
      cs_n  => h_cs_n,
      clk   => h_clk,
      rwds  => h_rwds,
      dq    => h_dq
    );

  DUT: component test_fit_hram_ctrl
    port map (
      debug     => debug,
      ref_rst   => ref_rst,
      ref_clk   => ref_clk,
      s_clk_o   => s_clk_o,
      s_rst_o   => s_rst,
      s_a_ready => u_a_ready,
      s_a_valid => u_a_valid,
      s_a_r_w   => u_a_r_w,
      s_a_reg   => u_a_reg,
      s_a_wrap  => u_a_wrap,
      s_a_size  => u_a_size,
      s_a_addr  => u_a_addr(22 downto 1),
      s_w_ready => u_w_ready,
      s_w_valid => u_w_valid,
      s_w_be    => u_w_be,
      s_w_data  => u_w_data,
      s_r_ready => u_r_ready,
      s_r_valid => u_r_valid,
      s_r_data  => u_r_data,
      h_rst_n   => h_rst_n,
      h_cs_n    => h_cs_n,
      h_clk     => h_clk,
      h_rwds    => h_rwds,
      h_dq      => h_dq
    );

  h_rwds <= 'L';

  -- signal delays to absorb clock skew
    s_a_ready <= u_a_ready 'delayed(tdelay);
    u_a_valid <= s_a_valid 'delayed(tdelay);
    u_a_r_w   <= s_a_r_w   'delayed(tdelay);
    u_a_reg   <= s_a_reg   'delayed(tdelay);
    u_a_wrap  <= s_a_wrap  'delayed(tdelay);
    u_a_size  <= s_a_size  'delayed(tdelay);
    u_a_addr  <= s_a_addr  'delayed(tdelay);
    s_w_ready <= u_w_ready 'delayed(tdelay);
    u_w_valid <= s_w_valid 'delayed(tdelay);
    u_w_be    <= s_w_be    'delayed(tdelay);
    u_w_data  <= s_w_data  'delayed(tdelay);
    u_r_ready <= s_r_ready 'delayed(tdelay);
    s_r_valid <= u_r_valid 'delayed(tdelay);
    s_r_data  <= u_r_data  'delayed(tdelay);

end architecture sim;