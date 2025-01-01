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
      ALIGN : string
    );
    port (
      ref_clk    : in    std_ulogic;
      ref_clk_90 : in    std_ulogic := '0';
      umii_rst   : in    std_ulogic;
      umii_spd   : in    std_ulogic_vector(1 downto 0);
      umii_clk   : out   std_ulogic;
      umii_clken : out   std_ulogic;
      umii_dv    : in    std_ulogic;
      umii_er    : in    std_ulogic;
      umii_d     : in    std_ulogic_vector(7 downto 0);
      rgmii_clk  : out   std_ulogic;
      rgmii_ctl  : out   std_ulogic;
      rgmii_d    : out   std_ulogic_vector(3 downto 0)
    );
  end component memac_tx_rgmii;

end package memac_tx_rgmii_pkg;

--------------------------------------------------------------------------------

use work.memac_util_pkg.all;
use work.sync_reg_u_pkg.all;
use work.oddr_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_tx_rgmii is
  generic (
    ALIGN : string -- "EDGE" or "CENTER"
  );
  port (
    ref_clk    : in    std_ulogic;
    ref_clk_90 : in    std_ulogic := '0'; -- not used when edge aligned
    umii_spd   : in    std_ulogic_vector(1 downto 0);
    umii_rst   : in    std_ulogic;
    umii_clk   : out   std_ulogic;
    umii_clken : out   std_ulogic;
    umii_dv    : in    std_ulogic;
    umii_er    : in    std_ulogic;
    umii_d     : in    std_ulogic_vector(7 downto 0);
    rgmii_clk  : out   std_ulogic;
    rgmii_ctl  : out   std_ulogic;
    rgmii_d    : out   std_ulogic_vector(3 downto 0)
  );
end entity memac_tx_rgmii;

architecture rtl of memac_tx_rgmii is

  signal cycle        : std_ulogic_vector(6 downto 0);
  signal cycles       : std_ulogic_vector(6 downto 0);
  signal rgmii_clken  : std_ulogic;
  signal rgmii_clk_d1 : std_ulogic;
  signal rgmii_clk_d2 : std_ulogic;
  signal rgmii_ctl_d1 : std_ulogic;
  signal rgmii_ctl_d2 : std_ulogic;
  signal rgmii_d_d1   : std_ulogic_vector(3 downto 0);
  signal rgmii_d_d2   : std_ulogic_vector(3 downto 0);
  signal umii_spd_s   : std_ulogic_vector(1 downto 0);
  signal umii_clken_e : std_ulogic;
  signal umii_dv_r    : std_ulogic;
  signal umii_er_r    : std_ulogic;
  signal umii_d_r     : std_ulogic_vector(7 downto 0);
  signal oddr_d1      : std_ulogic_vector(4 downto 0);
  signal oddr_d2      : std_ulogic_vector(4 downto 0);
  signal oddr_q       : std_ulogic_vector(4 downto 0);

begin

  umii_clk <= ref_clk;

  U_SYNC: component sync_reg_u
    generic map (
      STAGES    => 2,
      RST_STATE => '0'
    )
    port map (
      rst  => umii_rst,
      clk  => umii_clk,
      i    => umii_spd,
      o    => umii_spd_s
    );

  P_SYNC: process(umii_rst,umii_clk)
  begin
    if umii_rst = '1' then

      cycle        <= (others => '0');
      cycles       <= (others => '0');
      umii_clken_e <= '0';
      umii_clken   <= '0';
      rgmii_clken  <= '0';
      rgmii_clk_d1 <= '0';
      rgmii_clk_d2 <= '0';
      rgmii_ctl_d1 <= '0';
      rgmii_ctl_d2 <= '0';
      rgmii_d_d1   <= (others => '0');
      rgmii_d_d2   <= (others => '0');

    elsif rising_edge(umii_clk) then

      -- UMI cycles per octet: 125MHz, 12.5MHz or 1.25MHz
      cycles <=
        std_ulogic_vector(to_unsigned(  9,cycles'length)) when umii_spd_s(0) = '1' else
        std_ulogic_vector(to_unsigned( 99,cycles'length));
      if umii_spd_s(1) = '0' then
        if cycle = cycles then
          cycle <= (others => '0');
        else
          cycle <= std_ulogic_vector((unsigned(cycle) + 1));
        end if;
      end if;
      umii_clken <= umii_clken_e;
      -- input registers
      if umii_clken = '1' then
        umii_dv_r <= umii_dv;
        umii_er_r <= umii_er;
        umii_d_r  <= umii_d;
      end if;
      -- ODDR inputs
      rgmii_clken  <= '0';
      if umii_spd_s(1) = '1' then -- 1000Mbps
        umii_clken_e <= '1';
        rgmii_clken  <= '1';
        rgmii_clk_d1 <= '1';
        rgmii_clk_d2 <= '0';
        rgmii_ctl_d1 <= umii_dv_r;
        rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        rgmii_d_d1   <= umii_d_r(3 downto 0);
        rgmii_d_d2   <= umii_d_r(7 downto 4);
      elsif umii_spd_s(0) = '1' then -- 100Mbps
        umii_clken_e <= bool2sl(unsigned(cycle) = 5);
        if    unsigned(cycle) = 8 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umii_dv_r;
          rgmii_ctl_d2 <= umii_dv_r;
          rgmii_d_d1   <= umii_d_r(3 downto 0);
          rgmii_d_d2   <= umii_d_r(3 downto 0);
        elsif unsigned(cycle) = 0 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umii_dv_r;
          rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        elsif unsigned(cycle) = 1 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umii_er_r xor umii_dv_r;
          rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        elsif unsigned(cycle) = 3 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umii_dv_r;
          rgmii_ctl_d2 <= umii_dv_r;
          rgmii_d_d1   <= umii_d_r(7 downto 4);
          rgmii_d_d2   <= umii_d_r(7 downto 4);
        elsif unsigned(cycle) = 5 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umii_dv_r;
          rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        elsif unsigned(cycle) = 6 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umii_er_r xor umii_dv_r;
          rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        end if;
      else -- 10 Mbps
        umii_clken_e <= bool2sl(unsigned(cycle) = 95);
        if    unsigned(cycle) = 98 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umii_dv_r;
          rgmii_ctl_d2 <= umii_dv_r;
          rgmii_d_d1   <= umii_d_r(3 downto 0);
          rgmii_d_d2   <= umii_d_r(3 downto 0);
        elsif unsigned(cycle) = 23 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umii_er_r xor umii_dv_r;
          rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        elsif unsigned(cycle) = 48 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '1';
          rgmii_clk_d2 <= '1';
          rgmii_ctl_d1 <= umii_dv_r;
          rgmii_ctl_d2 <= umii_dv_r;
          rgmii_d_d1   <= umii_d_r(7 downto 4);
          rgmii_d_d2   <= umii_d_r(7 downto 4);
        elsif unsigned(cycle) = 73 then
          rgmii_clken  <= '1';
          rgmii_clk_d1 <= '0';
          rgmii_clk_d2 <= '0';
          rgmii_ctl_d1 <= umii_er_r xor umii_dv_r;
          rgmii_ctl_d2 <= umii_er_r xor umii_dv_r;
        end if;
      end if;
    end if;
  end process P_SYNC;

  GEN_ALIGN: if ALIGN = "EDGE" generate

    U_ODDR_CLK: component oddr
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

    signal rgmii_clken_180  : std_ulogic;
    signal rgmii_clk_d1_180 : std_ulogic;
    signal rgmii_clk_d2_180 : std_ulogic;

  begin

    P_180: process(umii_clk)
    begin
      if falling_edge(umii_clk) then
        rgmii_clken_180  <= rgmii_clken;
        rgmii_clk_d1_180 <= rgmii_clk_d1;
        rgmii_clk_d2_180 <= rgmii_clk_d2;
      end if;
    end process P_180;

    U_ODDR_CLK: component oddr
      port map (
        rst   => '0',
        set   => '0',
        clk   => ref_clk_90,
        clken => rgmii_clken_180,
        d1(0) => rgmii_clk_d1_180,
        d2(0) => rgmii_clk_d2_180,
        q(0)  => rgmii_clk
      );

  end generate GEN_ALIGN;

  U_ODDR: component oddr
    port map (
      rst   => '0',
      set   => '0',
      clk   => ref_clk,
      clken => rgmii_clken,
      d1    => oddr_d1,
      d2    => oddr_d2,
      q     => oddr_q
    );
  oddr_d1   <= rgmii_ctl_d1 & rgmii_d_d1;
  oddr_d2   <= rgmii_ctl_d2 & rgmii_d_d2;
  rgmii_ctl <= oddr_q(4);
  rgmii_d   <= oddr_q(3 downto 0);

end architecture rtl;
