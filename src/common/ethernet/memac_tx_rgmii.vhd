--------------------------------------------------------------------------------
-- memac_tx_rgmii.vhd                                                         --
-- Modular Ethernet MAC (MEMAC): transmit UMI to RGMII shim (edge aligned).   --
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

package memac_tx_rgmii_pkg is

  component memac_tx_rgmii is
    generic (
      ALIGN : string := "EDGE" -- "EDGE" or "CENTER"
    );
    port (
      ref_clk    : in    std_ulogic;
      ref_clk_90 : in    std_ulogic := '0';
      umi_rst    : in    std_ulogic;
      umi_spd    : in    std_ulogic_vector(1 downto 0);
      umi_clk    : out   std_ulogic;
      umi_clken  : out   std_ulogic;
      umi_dv     : in    std_ulogic;
      umi_er     : in    std_ulogic;
      umi_d      : in    std_ulogic_vector(7 downto 0);
      rgmii_clk  : out   std_ulogic;
      rgmii_ctl  : out   std_ulogic;
      rgmii_d    : out   std_ulogic_vector(3 downto 0)
    );
  end component memac_tx_rgmii;

end package memac_tx_rgmii_pkg;

--------------------------------------------------------------------------------

use work.memac_util_pkg.all;
use work.oddr_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_tx_rgmii is
  generic (
    ALIGN : string := "EDGE" -- "EDGE" or "CENTER"
  );
  port (
    ref_clk    : in    std_ulogic;
    ref_clk_90 : in    std_ulogic := '0'; -- not used when edge aligned
    umi_spd    : in    std_ulogic_vector(1 downto 0);
    umi_rst    : in    std_ulogic;
    umi_clk    : out   std_ulogic;
    umi_clken  : out   std_ulogic;
    umi_dv     : in    std_ulogic;
    umi_er     : in    std_ulogic;
    umi_d      : in    std_ulogic_vector(7 downto 0);
    rgmii_clk  : out   std_ulogic;
    rgmii_ctl  : out   std_ulogic;
    rgmii_d    : out   std_ulogic_vector(3 downto 0)
  );
end entity memac_tx_rgmii;

architecture rtl of memac_tx_rgmii is

  signal cycle           : std_ulogic_vector(5 downto 0);
  signal rgmii_clken     : std_ulogic;
  signal rgmii_clk_d1    : std_ulogic;
  signal rgmii_clk_d2    : std_ulogic;
  signal rgmii_ctl_d1    : std_ulogic;
  signal rgmii_ctl_d2    : std_ulogic;
  signal rgmii_d_d1      : std_ulogic_vector(3 downto 0);
  signal rgmii_d_d2      : std_ulogic_vector(3 downto 0);
  signal umi_clken_e     : std_ulogic;
  signal umi_dv_r        : std_ulogic;
  signal umi_er_r        : std_ulogic;
  signal umi_d_r         : std_ulogic_vector(7 downto 0);

begin

  umi_clk <= ref_clk;

  P_SYNC: process(umi_rst,umi_clk)
    variable cycles : integer;
  begin
    if umi_rst = '1' then

      cycle        <= (others => '0');
      umi_clken_e  <= '0';
      umi_clken    <= '0';
      rgmii_clken  <= '0';
      rgmii_clk_d1 <= '0';
      rgmii_clk_d2 <= '0';
      rgmii_ctl_d1 <= '0';
      rgmii_ctl_d2 <= '0';
      rgmii_d_d1   <= (others => '0');
      rgmii_d_d2   <= (others => '0');

    elsif rising_edge(umi_clk) then

      -- UMI cycles per octet: 125MHz, 12.5MHz or 1.25MHz
      cycles := 1 when umi_spd(1) = '1' else 10 when umi_spd(0) = '1' else 100;
      cycle <= std_ulogic_vector((unsigned(cycle) + 1) mod cycles);
      umi_clken <= umi_clken_e;
      -- input registers
      if umi_clken = '1' then
        umi_dv_r <= umi_dv;
        umi_er_r <= umi_er;
        umi_d_r  <= umi_d;
      end if;
      -- ODDR inputs
      rgmii_clken  <= '0';
      if umi_spd(1) = '1' then -- 1000Mbps
        umi_clken_e  <= '1';
        rgmii_clken  <= '1';
        rgmii_clk_d1 <= '1';
        rgmii_clk_d2 <= '0';
        rgmii_ctl_d1 <= umi_dv_r;
        rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        rgmii_d_d1   <= umi_d_r(3 downto 0);
        rgmii_d_d2   <= umi_d_r(7 downto 4);
        cycle        <= (others => 'X');
      elsif umi_spd(0) = '1' then -- 100Mbps
        umi_clken_e <= bool2sl(unsigned(cycle) = 5);
        if    unsigned(cycle) = 8 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umi_dv_r;
          rgmii_ctl_d2 <= umi_dv_r;
          rgmii_d_d1   <= umi_d_r(3 downto 0);
          rgmii_d_d2   <= umi_d_r(3 downto 0);
        elsif unsigned(cycle) = 0 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umi_dv_r;
          rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        elsif unsigned(cycle) = 1 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umi_er_r xor umi_dv_r;
          rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        elsif unsigned(cycle) = 3 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umi_dv_r;
          rgmii_ctl_d2 <= umi_dv_r;
          rgmii_d_d1   <= umi_d_r(7 downto 4);
          rgmii_d_d2   <= umi_d_r(7 downto 4);
        elsif unsigned(cycle) = 5 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umi_dv_r;
          rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        elsif unsigned(cycle) = 6 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umi_er_r xor umi_dv_r;
          rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        end if;
      else -- 10 Mbps
        umi_clken_e <= bool2sl(unsigned(cycle) = 95);
        if    unsigned(cycle) = 98 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umi_dv_r;
          rgmii_ctl_d2 <= umi_dv_r;
          rgmii_d_d1   <= umi_d_r(3 downto 0);
          rgmii_d_d2   <= umi_d_r(3 downto 0);
        elsif unsigned(cycle) = 23 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umi_er_r xor umi_dv_r;
          rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        elsif unsigned(cycle) = 48 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umi_dv_r;
          rgmii_ctl_d2 <= umi_dv_r;
          rgmii_d_d1   <= umi_d_r(7 downto 4);
          rgmii_d_d2   <= umi_d_r(7 downto 4);
        elsif unsigned(cycle) = 73 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umi_er_r xor umi_dv_r;
          rgmii_ctl_d2 <= umi_er_r xor umi_dv_r;
        end if;
      end if;
    end if;
  end process P_SYNC;

  GEN_ALIGN: if ALIGN = "EDGE" generate

    U_ODDR: component oddr
      port map (
        rst   => '0',
        set   => '0',
        clk   => ref_clk,
        clken => rgmii_clken,
        d1(0) => rgmii_clk_d1,
        d2(0) => rgmii_clk_d2,
        q(0)  => rgmii_clk
      );

  else generate

    signal rgmii_clken_180 : std_ulogic;

  begin

    P_180: process(umi_clk)
    begin
      if falling_edge(umi_clk) then
        rgmii_clken_180 <= rgmii_clken;
      end if;
    end process P_180;

    U_ODDR: component oddr
      port map (
        rst   => '0',
        set   => '0',
        clk   => ref_clk_90,
        clken => rgmii_clken_180,
        d1(0) => rgmii_clk_d1,
        d2(0) => rgmii_clk_d2,
        q(0)  => rgmii_clk
      );

  end generate GEN_ALIGN;

  U_ODDR: component oddr
    port map (
      rst            => '0',
      set            => '0',
      clk            => ref_clk_90,
      clken          => rgmii_clken,
      d1(4)          => rgmii_ctl_d1,
      d1(3 downto 0) => rgmii_d_d1,
      d2(4)          => rgmii_ctl_d2,
      d2(3 downto 0) => rgmii_d_d2,
      q(4)           => rgmii_ctl,
      q(3 downto 0)  => rgmii_d
    );

end architecture rtl;
