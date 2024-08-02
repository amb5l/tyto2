--------------------------------------------------------------------------------
-- memac_rx_rgmii.vhd                                                         --
-- Modular Ethernet MAC (MEMAC): receive RGMII to UMI shim.                   --
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
-- assumes rgmii_clk is center aligned
-- TODO complete IBS extraction

library ieee;
  use ieee.std_logic_1164.all;

package memac_rx_rgmii_pkg is

  component memac_rx_rgmii is
    port (
      ref_rst   : in    std_ulogic;
      ref_clk   : in    std_ulogic;                    -- 125 MHz
      umi_spdi  : in    std_ulogic_vector(1 downto 0); -- requested speed
      umi_spdo  : out   std_ulogic_vector(1 downto 0); -- measured speed
      umi_rst   : in    std_ulogic;
      umi_clk   : in    std_ulogic;
      umi_clken : out   std_ulogic;
      umi_dv    : out   std_ulogic;
      umi_er    : out   std_ulogic;
      umi_d     : out   std_ulogic_vector(7 downto 0);
      ibs_crs   : out   std_ulogic;                    -- carrier sense
      ibs_crx   : out   std_ulogic;                    -- carrier extend
      ibs_crxer : out   std_ulogic;                    -- carrier extend error
      ibs_crf   : out   std_ulogic;                    -- carrier false
      ibs_link  : out   std_ulogic;                    -- link up
      ibs_spd   : out   std_ulogic_vector(1 downto 0); -- speed
      ibs_fdx   : out   std_ulogic;                    -- full duplex
      rgmii_clk : in    std_ulogic;
      rgmii_ctl : in    std_ulogic;
      rgmii_d   : in    std_ulogic_vector(3 downto 0)
    );
  end component memac_rx_rgmii;

end package memac_rx_rgmii_pkg;

--------------------------------------------------------------------------------

use work.memac_util_pkg.all;
use work.memac_spd_pkg.all;
use work.sync_reg_u_pkg.all;
use work.iddr_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_rx_rgmii is
  port (
    ref_rst   : in    std_ulogic;
    ref_clk   : in    std_ulogic;                    -- 125 MHz
    umi_spdi  : in    std_ulogic_vector(1 downto 0); -- requested speed
    umi_spdo  : out   std_ulogic_vector(1 downto 0); -- measured speed
    umi_rst   : in    std_ulogic;
    umi_clk   : in    std_ulogic;
    umi_clken : out   std_ulogic;
    umi_dv    : out   std_ulogic;
    umi_er    : out   std_ulogic;
    umi_d     : out   std_ulogic_vector(7 downto 0);
    ibs_crs   : out   std_ulogic;                    -- carrier sense
    ibs_crx   : out   std_ulogic;                    -- carrier extend
    ibs_crxer : out   std_ulogic;                    -- carrier extend error
    ibs_crf   : out   std_ulogic;                    -- carrier false
    ibs_link  : out   std_ulogic;                    -- link up
    ibs_spd   : out   std_ulogic_vector(1 downto 0); -- speed
    ibs_fdx   : out   std_ulogic;                    -- full duplex
    rgmii_clk : in    std_ulogic;
    rgmii_ctl : in    std_ulogic;
    rgmii_d   : in    std_ulogic_vector(3 downto 0)
  );
end entity memac_rx_rgmii;

architecture rtl of memac_rx_rgmii is

  signal umi_spdi_s    : std_ulogic_vector(1 downto 0);
  signal iddr_d        : std_ulogic_vector(4 downto 0);
  signal iddr_q1       : std_ulogic_vector(4 downto 0);
  signal iddr_q2       : std_ulogic_vector(4 downto 0);
  signal rgmii_ctl_r   : std_ulogic;
  signal rgmii_ctl_f   : std_ulogic;
  signal rgmii_d_r     : std_ulogic_vector(3 downto 0);
  signal rgmii_d_f     : std_ulogic_vector(3 downto 0);
  signal rgmii_ctl_r_l : std_ulogic;

begin

  U_SYNC: component sync_reg_u
    generic map (
      STAGES    => 2,
      RST_STATE => '0'
    )
    port map (
      rst  => umi_rst,
      clk  => umi_clk,
      i    => umi_spdi,
      o    => umi_spdi_s
    );

  U_IDDR: component iddr
    port map (
      rst   => '0',
      set   => '0',
      clk   => rgmii_clk,
      clken => '1',
      d     => iddr_d,
      q1    => iddr_q1,
      q2    => iddr_q2
    );
  iddr_d <= rgmii_ctl & rgmii_d;
  rgmii_ctl_r <= iddr_q1(4);
  rgmii_d_r   <= iddr_q1(3 downto 0);
  rgmii_ctl_f <= iddr_q2(4);
  rgmii_d_f   <= iddr_q2(3 downto 0);

  P_MAIN: process(umi_rst,umi_clk)
  begin
    if umi_rst = '1' then
      umi_clken     <= '0';
      umi_dv        <= '0';
      umi_er        <= '0';
      umi_d         <= (others => '0');
      rgmii_ctl_r_l <= '0';
      ibs_crs       <= '0';
      ibs_crx       <= '0';
      ibs_crxer     <= '0';
      ibs_crf       <= '0';
      ibs_link      <= '0';
      ibs_spd       <= (others => '0');
      ibs_fdx       <= '0';
    elsif rising_edge(umi_clk) then
      -- IBS
      if umi_dv = '0' and umi_er = '0' then
        ibs_link <= umi_d(0);
        ibs_spd  <= umi_d(2 downto 1);
        ibs_fdx  <= umi_d(3);
      elsif umi_dv = '0' and umi_er = '1' then
        ibs_crs   <= bool2sl(umi_d = x"FF");
        ibs_crx   <= bool2sl(umi_d = x"0F");
        ibs_crxer <= bool2sl(umi_d = x"1F");
        ibs_crf   <= bool2sl(umi_d = x"0E");
      end if;
      -- dv, er, d
      case umi_spdi_s is
        when "00" | "01" => -- 10/100 Mbps
          umi_clken <= not umi_clken;
          if rgmii_ctl_r xor rgmii_ctl_r_l then
            umi_clken <= '1';
          end if;
          rgmii_ctl_r_l <= rgmii_ctl_r;
          if umi_clken then
            umi_dv <= rgmii_ctl_r;
            umi_er <= rgmii_ctl_f xor rgmii_ctl_r;
            umi_d  <= rgmii_d_f & rgmii_d_r;
          end if;
        when "10" => -- 1000 Mbps
          umi_clken <= '1';
          umi_dv    <= rgmii_ctl_r;
          umi_er    <= rgmii_ctl_f xor rgmii_ctl_r;
          umi_d     <= rgmii_d_f & rgmii_d_r;
        when others => -- bad
          umi_clken <= '0';
          umi_dv    <= '0';
          umi_er    <= '0';
          umi_d     <= (others => 'X');
          ibs_link  <= '0';
          ibs_spd   <= "11";
          ibs_fdx   <= '1';
          ibs_crs   <= '0';
          ibs_crx   <= '0';
          ibs_crxer <= '0';
          ibs_crf   <= '0';
      end case;
    end if;
  end process P_MAIN;

  U_SPEED: component memac_spd
    port map (
      ref_rst  => ref_rst,
      ref_clk  => ref_clk,
      umi_rst  => umi_rst,
      umi_clk  => umi_clk,
      umi_spd  => umi_spdo
    );

end architecture rtl;
