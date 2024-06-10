use work.memac_util_pkg.all;
use work.memac_mdio_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_memac_mdio is
  generic (
    COUNT : integer
  );
end entity;

architecture sim of tb_memac_mdio is

  constant tCLK : time := 10 ns;

  signal rst  : std_ulogic;
  signal clk  : std_ulogic;
  signal stb  : std_ulogic;
  signal r_w  : std_ulogic;
  signal pa   : std_ulogic_vector(4 downto 0);
  signal ra   : std_ulogic_vector(4 downto 0);
  signal wd   : std_ulogic_vector(15 downto 0);
  signal rd   : std_ulogic_vector(15 downto 0);
  signal rdy  : std_ulogic;
  signal mdc  : std_ulogic;
  signal mdo  : std_ulogic;
  signal mdoe : std_ulogic;
  signal mdi  : std_ulogic;

  signal phy_sr : std_ulogic_vector(31 downto 0);
  signal phy_wd : std_ulogic_vector(15 downto 0);

begin

  rst <= '1', '0' after tCLK;
  clk <= '0' when clk = 'U' else not clk after tCLK/2;

  P_MAIN: process

    variable test_r_w : std_ulogic;
    variable test_pa  : std_ulogic_vector(4 downto 0);
    variable test_ra  : std_ulogic_vector(4 downto 0);
    variable test_wd  : std_ulogic_vector(15 downto 0);
    variable test_rd  : std_ulogic_vector(15 downto 0);

    procedure mdio_transaction(t_r_w : std_ulogic; t_pa : std_ulogic_vector(4 downto 0); t_ra : std_ulogic_vector(4 downto 0); t_wd : std_ulogic_vector(15 downto 0)) is
    begin
      while rdy = '0' loop
        wait until rising_edge(clk);
      end loop;
      stb <= '1';
      r_w <= t_r_w;
      pa  <= t_pa;
      ra  <= t_ra;
      wd  <= t_wd;
      wait until rising_edge(clk);
      stb <= '0';
      r_w <= 'X';
      pa  <= (others => 'X');
      ra  <= (others => 'X');
      wd  <= (others => 'X');
    end procedure mdio_transaction;

  begin

    prng.rand_seed(123,456);
    stb <= '0';
    r_w <= 'X';
    pa  <= (others => 'X');
    ra  <= (others => 'X');
    wd  <= (others => 'X');
    wait until rst = '0';
    for i in 0 to COUNT-1 loop
      test_r_w := prng.rand_slv(0,1,1)(0);
      test_pa  := prng.rand_slv(0,31,5);
      test_ra  := prng.rand_slv(0,31,5);
      test_wd  := prng.rand_slv(0,65535,16);
      test_rd  := "01" & test_r_w & not test_r_w & test_pa & test_ra & "00";
      mdio_transaction(test_r_w,test_pa,test_ra,test_wd);
      wait until rising_edge(clk) and rdy = '1';
      if test_r_w = '0' then
        assert test_wd = phy_wd report "write mismatch: tx " & to_hstring(test_wd) & " rx " & to_hstring(phy_wd) severity failure;
      else
        assert rd = test_rd report "read mismatch: tx " & to_hstring(test_rd) & " rx " & to_hstring(rd) severity failure;
      end if;
    end loop;
    std.env.finish;
  end process P_MAIN;

  DUT: component memac_mdio
    generic map (
      DIV5M => 20 -- 100 MHz / 20 = 5 MHz
    )
    port map (
      rst  => rst,
      clk  => clk,
      stb  => stb,
      r_w  => r_w,
      pa   => pa,
      ra   => ra,
      wd   => wd,
      rd   => rd,
      rdy  => rdy,
      mdc  => mdc,
      mdo  => mdo,
      mdoe => mdoe,
      mdi  => mdi
    );

  -- model PHY behaviour
  -- read result is inverse of written pattern
  P_PHY: process(rst,mdc)
  begin
    if rst = '1' then
      phy_sr <= (others => 'X');
    elsif rising_edge(mdc) then
      phy_sr <= phy_sr(30 downto 0) & mdo;
    end if;
  end process P_PHY;
  mdi <= phy_sr(15);
  phy_wd <= phy_sr(15 downto 0);

end architecture sim;
