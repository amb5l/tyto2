--------------------------------------------------------------------------------
-- memac_buf.vhd                                                              --
-- Modular Ethernet MAC: dual port RAM buffer.                                --
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

package memac_buf_pkg is

  component memac_buf is
    port (

      cpu_clk    : in    std_logic;
      cpu_en     : in    std_logic;
      cpu_bwe    : in    std_logic_vector(3 downto 0);
      cpu_addr   : in    std_logic_vector;
      cpu_din    : in    std_logic_vector(31 downto 0);
      cpu_dpin   : in    std_logic_vector(3 downto 0);
      cpu_dout   : out   std_logic_vector(31 downto 0);
      cpu_dpout  : out   std_logic_vector(3 downto 0);

      umii_clk   : in    std_logic;
      umii_en    : in    std_logic;
      umii_we    : in    std_logic;
      umii_addr  : in    std_logic_vector;
      umii_din   : in    std_logic_vector(7 downto 0);
      umii_dpin  : in    std_logic;
      umii_dout  : out   std_logic_vector(7 downto 0);
      umii_dpout : out   std_logic

    );
  end component memac_buf;

end package memac_buf_pkg;

use work.tyto_types_pkg.all;
use work.ram_tdp_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_buf is
  port (

    cpu_clk    : in    std_logic;
    cpu_en     : in    std_logic;
    cpu_bwe    : in    std_logic_vector(3 downto 0);
    cpu_addr   : in    std_logic_vector;
    cpu_din    : in    std_logic_vector(31 downto 0);
    cpu_dpin   : in    std_logic_vector(3 downto 0);
    cpu_dout   : out   std_logic_vector(31 downto 0);
    cpu_dpout  : out   std_logic_vector(3 downto 0);

    umii_clk   : in    std_logic;
    umii_en    : in    std_logic;
    umii_we    : in    std_logic;
    umii_addr  : in    std_logic_vector;
    umii_din   : in    std_logic_vector(7 downto 0);
    umii_dpin  : in    std_logic;
    umii_dout  : out   std_logic_vector(7 downto 0);
    umii_dpout : out   std_logic

  );
end entity memac_buf;

architecture rtl of memac_buf is

  signal dout_a      : sulv_vector(3 downto 0)(8 downto 0);
  signal dout_b      : sulv_vector(3 downto 0)(8 downto 0);
  signal umii_bsel   : std_ulogic_vector(1 downto 0);
  signal umii_bwe    : std_ulogic_vector(3 downto 0);
  signal umii_bdout  : sulv_vector(3 downto 0)(7 downto 0);
  signal umii_bdpout : std_ulogic_vector(3 downto 0);

begin

  P_COMB: process(all)
  begin
    umii_bwe <= (others => '0');
    -- this doesn't work in Vivado simulator
    -- umii_bwe(to_integer(unsigned(umii_addr(1 downto 0)))) <= umii_we;
    if umii_we = '1' then
      case umii_addr(1 downto 0) is
        when "00"   => umii_bwe(0) <= '1';
        when "01"   => umii_bwe(1) <= '1';
        when "10"   => umii_bwe(2) <= '1';
        when "11"   => umii_bwe(3) <= '1';
        when others => umii_bwe <= (others => 'X');
      end case;
    end if;
    case umii_bsel is
      when "00"   => umii_dout <= umii_bdout(0); umii_dpout <= umii_bdpout(0);
      when "01"   => umii_dout <= umii_bdout(1); umii_dpout <= umii_bdpout(1);
      when "10"   => umii_dout <= umii_bdout(2); umii_dpout <= umii_bdpout(2);
      when "11"   => umii_dout <= umii_bdout(3); umii_dpout <= umii_bdpout(3);
      when others => umii_dout <= (others => 'X'); umii_dpout <= 'X';
    end case;
  end process P_COMB;

  P_SYNC: process(umii_clk)
  begin
    if rising_edge(umii_clk) then
      umii_bsel <= umii_addr(1 downto 0);
    end if;
  end process P_SYNC;

  GEN_BUF: for i in 0 to 3 generate
    U_BUF: component ram_tdp
      port map (
        clk_a   => cpu_clk,
        rst_a   => '0',
        en_a    => cpu_en,
        we_a    => cpu_bwe(i),
        addr_a  => cpu_addr,
        din_a   => cpu_dpin(i) & cpu_din(7+(i*8) downto i*8),
        dout_a  => dout_a(i),
        clk_b   => umii_clk,
        rst_b   => '0',
        en_b    => umii_en,
        we_b    => umii_bwe(i),
        addr_b  => umii_addr(umii_addr'high downto 2),
        din_b   => umii_dpin & umii_din,
        dout_b  => dout_b(i)
      );
      cpu_dout(7+(i*8) downto i*8) <= dout_a(i)(7 downto 0);
      cpu_dpout(i) <= dout_a(i)(8);
      umii_bdout(i) <= dout_b(i)(7 downto 0);
      umii_bdpout(i) <= dout_b(i)(8);
  end generate GEN_BUF;

end architecture rtl;
