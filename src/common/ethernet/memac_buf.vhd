--------------------------------------------------------------------------------
-- memac_buf_pkg.vhd                                                          --
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

      cpu_clk   : in    std_logic;
      cpu_en    : in    std_logic;
      cpu_bwe   : in    std_logic_vector(3 downto 0);
      cpu_addr  : in    std_logic_vector;
      cpu_din   : in    std_logic_vector(31 downto 0);
      cpu_dpin  : in    std_logic_vector(3 downto 0);
      cpu_dout  : out   std_logic_vector(31 downto 0);
      cpu_dpout : out   std_logic_vector(3 downto 0);

      umi_clk   : in    std_logic;
      umi_en    : in    std_logic;
      umi_we    : in    std_logic;
      umi_addr  : in    std_logic_vector;
      umi_din   : in    std_logic_vector(7 downto 0);
      umi_dpin  : in    std_logic;
      umi_dout  : out   std_logic_vector(7 downto 0);
      umi_dpout : out   std_logic

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

    cpu_clk   : in    std_logic;
    cpu_en    : in    std_logic;
    cpu_bwe   : in    std_logic_vector(3 downto 0);
    cpu_addr  : in    std_logic_vector;
    cpu_din   : in    std_logic_vector(31 downto 0);
    cpu_dpin  : in    std_logic_vector(3 downto 0);
    cpu_dout  : out   std_logic_vector(31 downto 0);
    cpu_dpout : out   std_logic_vector(3 downto 0);

    umi_clk   : in    std_logic;
    umi_en    : in    std_logic;
    umi_we    : in    std_logic;
    umi_addr  : in    std_logic_vector;
    umi_din   : in    std_logic_vector(7 downto 0);
    umi_dpin  : in    std_logic;
    umi_dout  : out   std_logic_vector(7 downto 0);
    umi_dpout : out   std_logic

  );
end entity memac_buf;

architecture rtl of memac_buf is

  signal dout_a     : sulv_vector(3 downto 0)(8 downto 0);
  signal dout_b     : sulv_vector(3 downto 0)(8 downto 0);
  signal umi_bwe    : std_ulogic_vector(3 downto 0);
  signal umi_bdout  : sulv_vector(3 downto 0)(7 downto 0);
  signal umi_bdpout : std_ulogic_vector(3 downto 0);

begin

  P_COMB: process(all)
  begin
    umi_bwe <= (others => '0');
    umi_bwe(to_integer(unsigned(umi_addr(1 downto 0)))) <= umi_we;
    case umi_addr(1 downto 0) is
      when "11"   => umi_dout <= umi_bdout(3); umi_dpout <= umi_bdpout(3);
      when "10"   => umi_dout <= umi_bdout(2); umi_dpout <= umi_bdpout(2);
      when "01"   => umi_dout <= umi_bdout(1); umi_dpout <= umi_bdpout(1);
      when others => umi_dout <= umi_bdout(0); umi_dpout <= umi_bdpout(0);
    end case;
  end process P_COMB;

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
        clk_b   => umi_clk,
        rst_b   => '0',
        en_b    => umi_en,
        we_b    => umi_bwe(i),
        addr_b  => umi_addr(umi_addr'high downto 2),
        din_b   => umi_dpin & umi_din,
        dout_b  => dout_b(i)
      );
      cpu_dout(7+(i*8) downto i*8) <= dout_a(i)(7 downto 0);
      cpu_dpout(i) <= dout_a(i)(8);
      umi_bdout(i) <= dout_b(i)(7 downto 0);
      umi_bdpout(i) <= dout_b(i)(8);
  end generate GEN_BUF;

end architecture rtl;
