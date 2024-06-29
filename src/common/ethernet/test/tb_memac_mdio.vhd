--------------------------------------------------------------------------------
-- tb_memac_mdio.vhd                                                          --
-- Testbench for memac_mdio.vhd.                                              --
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
-- configurable test entity (see architectures and configurations below)

use work.memac_util_pkg.all;
use work.memac_mdio_pkg.all;
use work.model_mdio_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity test is
  generic (
    COUNT : integer
  );
end entity test;

--------------------------------------------------------------------------------
-- package for shared stuff

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_mdio_common is

  constant tCLK : time := 10 ns;

  signal rst  : std_ulogic;
  signal clk  : std_ulogic;
  signal stb  : std_ulogic;
  signal pre  : std_ulogic;
  signal r_w  : std_ulogic;
  signal pa   : std_ulogic_vector(4 downto 0);
  signal ra   : std_ulogic_vector(4 downto 0);
  signal wd   : std_ulogic_vector(15 downto 0);
  signal rd   : std_ulogic_vector(15 downto 0);
  signal rdy  : std_ulogic;
  signal mdc  : std_ulogic;

  procedure mdio_transaction(
             v_pre :       std_ulogic;
             v_r_w :       std_ulogic;
             v_pa  :       std_ulogic_vector(4 downto 0);
             v_ra  :       std_ulogic_vector(4 downto 0);
             v_wd  :       std_ulogic_vector(15 downto 0);
    signal   s_clk : in    std_ulogic;
    signal   s_stb : out   std_ulogic;
    signal   s_pre : out   std_ulogic;
    signal   s_r_w : out   std_ulogic;
    signal   s_pa  : out   std_ulogic_vector(4 downto 0);
    signal   s_ra  : out   std_ulogic_vector(4 downto 0);
    signal   s_wd  : out   std_ulogic_vector(15 downto 0);
    signal   s_rdy : in    std_ulogic
  );

end package tb_memac_mdio_common;

package body tb_memac_mdio_common is

  procedure mdio_transaction(
             v_pre :       std_ulogic;
             v_r_w :       std_ulogic;
             v_pa  :       std_ulogic_vector(4 downto 0);
             v_ra  :       std_ulogic_vector(4 downto 0);
             v_wd  :       std_ulogic_vector(15 downto 0);
    signal   s_clk : in    std_ulogic;
    signal   s_stb : out   std_ulogic;
    signal   s_pre : out   std_ulogic;
    signal   s_r_w : out   std_ulogic;
    signal   s_pa  : out   std_ulogic_vector(4 downto 0);
    signal   s_ra  : out   std_ulogic_vector(4 downto 0);
    signal   s_wd  : out   std_ulogic_vector(15 downto 0);
    signal   s_rdy : in    std_ulogic
  ) is
  begin
    s_stb <= '1';
    s_pre <= v_pre;
    s_r_w <= v_r_w;
    s_pa  <= v_pa;
    s_ra  <= v_ra;
    s_wd  <= v_wd;
    wait until rising_edge(s_clk);
    s_stb <= '0';
    while s_rdy = '0' loop
      wait until rising_edge(s_clk);
    end loop;
    s_pre <= 'X';
    s_r_w <= 'X';
    s_pa  <= (others => 'X');
    s_ra  <= (others => 'X');
    s_wd  <= (others => 'X');
  end procedure mdio_transaction;

end package body tb_memac_mdio_common;

--------------------------------------------------------------------------------
-- TEST 1

use work.tb_memac_mdio_common.all;

architecture test1 of test is

  signal mdo    : std_ulogic;
  signal mdoe   : std_ulogic;
  signal mdi    : std_ulogic;
  signal phy_sr : std_ulogic_vector(31 downto 0);
  signal phy_wd : std_ulogic_vector(15 downto 0);

begin

  rst <= '1', '0' after tCLK;
  clk <= '0' when clk = 'U' else not clk after tCLK/2;

  P_MAIN: process

    variable test_pre : std_ulogic;
    variable test_r_w : std_ulogic;
    variable test_pa  : std_ulogic_vector(4 downto 0);
    variable test_ra  : std_ulogic_vector(4 downto 0);
    variable test_wd  : std_ulogic_vector(15 downto 0);
    variable test_rd  : std_ulogic_vector(15 downto 0);

  begin

    prng.rand_seed(123,456);
    stb <= '0';
    pre <= 'X';
    r_w <= 'X';
    pa  <= (others => 'X');
    ra  <= (others => 'X');
    wd  <= (others => 'X');
    wait until rst = '0';
    for i in 0 to COUNT-1 loop
      test_pre := prng.rand_slv(0,1,1)(0);
      test_r_w := prng.rand_slv(0,1,1)(0);
      test_pa  := prng.rand_slv(0,31,5);
      test_ra  := prng.rand_slv(0,31,5);
      test_wd  := prng.rand_slv(0,65535,16);
      test_rd  := "01" & test_r_w & not test_r_w & test_pa & test_ra & "00";
      mdio_transaction(test_pre,test_r_w,test_pa,test_ra,test_wd,clk,stb,pre,r_w,pa,ra,wd,rdy);
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
      pre  => pre,
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

end architecture test1;

--------------------------------------------------------------------------------
-- TEST 2

use work.tb_memac_mdio_common.all;

architecture test2 of test is

  constant tCLK : time := 10 ns;

  signal mdo  : std_ulogic;
  signal mdoe : std_ulogic;
  signal mdi  : std_ulogic;
  signal mdio : std_logic;

begin

  rst <= '1', '0' after tCLK;
  clk <= '0' when clk = 'U' else not clk after tCLK/2;

  P_MAIN: process
  begin
    wait until rst = '0';
    mdio_transaction('1','1',"00000","00010",x"0000",clk,stb,pre,r_w,pa,ra,wd,rdy);
    assert rd = x"DEAD" report "read mismatch: read " & to_hstring(rd) & " expected 0xDEAD" severity failure;
    mdio_transaction('1','1',"00000","00011",x"0000",clk,stb,pre,r_w,pa,ra,wd,rdy);
    assert rd = x"BEEF" report "read mismatch: read " & to_hstring(rd) & " expected 0xBEEF" severity failure;
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
      pre  => pre,
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

  mdio <= mdo when mdoe = '1' else 'Z';
  mdi  <= mdio;

  U_MODEL_MDIO: component model_mdio
    generic map (
      PHYID1 => x"DEAD",
      PHYID2 => x"BEEF"
    )
    port map (
      rst  => rst,
      mdc  => mdc,
      mdio => mdio
    );

end architecture test2;

--------------------------------------------------------------------------------
-- testbench entity is wrapper for configurable test entity above

entity tb_memac_mdio is
  generic (
    COUNT : integer
  );
end entity;

architecture sim of tb_memac_mdio is

  component test is
    generic (
      COUNT : integer
    );
  end component test;

begin

  TB: component test
    generic map (
      COUNT => COUNT
    );

end architecture sim;

--------------------------------------------------------------------------------
-- configurations

configuration tb_memac_mdio_test1 of tb_memac_mdio is
  for sim
    for TB: test
      use entity work.test(test1);
    end for;
  end for;
end configuration tb_memac_mdio_test1;

configuration tb_memac_mdio_test2 of tb_memac_mdio is
  for sim
    for TB: test
      use entity work.test(test2);
    end for;
  end for;
end configuration tb_memac_mdio_test2;