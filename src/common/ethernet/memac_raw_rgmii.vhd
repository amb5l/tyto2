--------------------------------------------------------------------------------
-- memac_raw_rgmii.vhd                                                        --
-- Modular Ethernet MAC: raw system interface, RGMII PHY interface.           --
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

use work.memac_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package memac_raw_rgmii_pkg is

  component memac_raw_rgmii is
    generic (
      MDIO_DIV5M : integer;
      TX_ALIGN   : string;
      RX_ALIGN   : string
    );
    port (

      sys_rst          : in    std_ulogic;
      sys_clk          : in    std_ulogic;

      sys_md_stb       : in    std_ulogic;
      sys_md_pre       : in    std_ulogic;
      sys_md_r_w       : in    std_ulogic;
      sys_md_pa        : in    std_ulogic_vector(4 downto 0);
      sys_md_ra        : in    std_ulogic_vector(4 downto 0);
      sys_md_wd        : in    std_ulogic_vector(15 downto 0);
      sys_md_rd        : out   std_ulogic_vector(15 downto 0);
      sys_md_rdy       : out   std_ulogic;

      sys_tx_rst       : in    std_ulogic;
      sys_tx_spd       : in    std_ulogic_vector(1 downto 0);
      sys_tx_prq_rdy   : out   std_ulogic;
      sys_tx_prq_len   : in    std_ulogic_vector;
      sys_tx_prq_idx   : in    std_ulogic_vector;
      sys_tx_prq_tag   : in    std_ulogic_vector;
      sys_tx_prq_opt   : in    tx_opt_t;
      sys_tx_prq_stb   : in    std_ulogic;
      sys_tx_pfq_rdy   : out   std_ulogic;
      sys_tx_pfq_len   : out   std_ulogic_vector;
      sys_tx_pfq_idx   : out   std_ulogic_vector;
      sys_tx_pfq_tag   : out   std_ulogic_vector;
      sys_tx_pfq_stb   : in    std_ulogic;
      sys_tx_buf_en    : in    std_ulogic;
      sys_tx_buf_bwe   : in    std_ulogic_vector(3 downto 0);
      sys_tx_buf_addr  : in    std_ulogic_vector;
      sys_tx_buf_din   : in    std_ulogic_vector(31 downto 0);
      sys_tx_buf_dpin  : in    std_ulogic_vector(3 downto 0);
      sys_tx_buf_dout  : out   std_ulogic_vector(31 downto 0);
      sys_tx_buf_dpout : out   std_ulogic_vector(3 downto 0);

      sys_rx_rst       : in    std_ulogic;
      sys_rx_spd       : in    std_ulogic_vector(1 downto 0);
      sys_rx_opt       : in    rx_opt_t;
      sys_rx_stat      : out   rx_stat_t;
      sys_rx_prq_rdy   : out   std_ulogic;
      sys_rx_prq_len   : out   std_ulogic_vector;
      sys_rx_prq_idx   : out   std_ulogic_vector;
      sys_rx_prq_flag  : out   rx_flag_t;
      sys_rx_prq_stb   : in    std_ulogic;
      sys_rx_pfq_rdy   : out   std_ulogic;
      sys_rx_pfq_len   : in    std_ulogic_vector;
      sys_rx_pfq_stb   : in    std_ulogic;
      sys_rx_buf_en    : in    std_ulogic;
      sys_rx_buf_bwe   : in    std_ulogic_vector(3 downto 0);
      sys_rx_buf_addr  : in    std_ulogic_vector;
      sys_rx_buf_din   : in    std_ulogic_vector(31 downto 0);
      sys_rx_buf_dpin  : in    std_ulogic_vector(3 downto 0);
      sys_rx_buf_dout  : out   std_ulogic_vector(31 downto 0);
      sys_rx_buf_dpout : out   std_ulogic_vector(3 downto 0);

      ref_rst          : in    std_ulogic;
      ref_clk          : in    std_ulogic;
      ref_clk_90       : in    std_ulogic;

      phy_mdc          : out   std_ulogic;
      phy_mdo          : out   std_ulogic;
      phy_mdoe         : out   std_ulogic;
      phy_mdi          : in    std_ulogic;
      phy_rgmii_tx_clk : out   std_ulogic;
      phy_rgmii_tx_ctl : out   std_ulogic;
      phy_rgmii_tx_d   : out   std_ulogic_vector(3 downto 0);
      phy_rgmii_rx_clk : in    std_ulogic;
      phy_rgmii_rx_ctl : in    std_ulogic;
      phy_rgmii_rx_d   : in    std_ulogic_vector(3 downto 0)

    );
  end component memac_raw_rgmii;

end package memac_raw_rgmii_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_mdio_pkg.all;
use work.memac_tx_pkg.all;
use work.memac_tx_rgmii_pkg.all;
use work.memac_rx_pkg.all;
use work.memac_rx_rgmii_pkg.all;
use work.memac_rx_rgmii_io_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_raw_rgmii is
  generic (
    MDIO_DIV5M : integer;
    TX_ALIGN   : string;
    RX_ALIGN   : string
  );
  port (

    sys_rst          : in    std_ulogic;
    sys_clk          : in    std_ulogic;

    sys_md_stb       : in    std_ulogic;
    sys_md_pre       : in    std_ulogic;
    sys_md_r_w       : in    std_ulogic;
    sys_md_pa        : in    std_ulogic_vector(4 downto 0);
    sys_md_ra        : in    std_ulogic_vector(4 downto 0);
    sys_md_wd        : in    std_ulogic_vector(15 downto 0);
    sys_md_rd        : out   std_ulogic_vector(15 downto 0);
    sys_md_rdy       : out   std_ulogic;

    sys_tx_rst       : in    std_ulogic;
    sys_tx_spd       : in    std_ulogic_vector(1 downto 0);
    sys_tx_prq_rdy   : out   std_ulogic;
    sys_tx_prq_len   : in    std_ulogic_vector;
    sys_tx_prq_idx   : in    std_ulogic_vector;
    sys_tx_prq_tag   : in    std_ulogic_vector;
    sys_tx_prq_opt   : in    tx_opt_t;
    sys_tx_prq_stb   : in    std_ulogic;
    sys_tx_pfq_rdy   : out   std_ulogic;
    sys_tx_pfq_len   : out   std_ulogic_vector;
    sys_tx_pfq_idx   : out   std_ulogic_vector;
    sys_tx_pfq_tag   : out   std_ulogic_vector;
    sys_tx_pfq_stb   : in    std_ulogic;
    sys_tx_buf_en    : in    std_ulogic;
    sys_tx_buf_bwe   : in    std_ulogic_vector(3 downto 0);
    sys_tx_buf_addr  : in    std_ulogic_vector;
    sys_tx_buf_din   : in    std_ulogic_vector(31 downto 0);
    sys_tx_buf_dpin  : in    std_ulogic_vector(3 downto 0);
    sys_tx_buf_dout  : out   std_ulogic_vector(31 downto 0);
    sys_tx_buf_dpout : out   std_ulogic_vector(3 downto 0);

    sys_rx_rst       : in    std_ulogic;
    sys_rx_spd       : in    std_ulogic_vector(1 downto 0);
    sys_rx_opt       : in    rx_opt_t;
    sys_rx_stat      : out   rx_stat_t;
    sys_rx_prq_rdy   : out   std_ulogic;
    sys_rx_prq_len   : out   std_ulogic_vector;
    sys_rx_prq_idx   : out   std_ulogic_vector;
    sys_rx_prq_flag  : out   rx_flag_t;
    sys_rx_prq_stb   : in    std_ulogic;
    sys_rx_pfq_rdy   : out   std_ulogic;
    sys_rx_pfq_len   : in    std_ulogic_vector;
    sys_rx_pfq_stb   : in    std_ulogic;
    sys_rx_buf_en    : in    std_ulogic;
    sys_rx_buf_bwe   : in    std_ulogic_vector(3 downto 0);
    sys_rx_buf_addr  : in    std_ulogic_vector;
    sys_rx_buf_din   : in    std_ulogic_vector(31 downto 0);
    sys_rx_buf_dpin  : in    std_ulogic_vector(3 downto 0);
    sys_rx_buf_dout  : out   std_ulogic_vector(31 downto 0);
    sys_rx_buf_dpout : out   std_ulogic_vector(3 downto 0);

    ref_rst          : in    std_ulogic;
    ref_clk          : in    std_ulogic;
    ref_clk_90       : in    std_ulogic;

    phy_mdc          : out   std_ulogic;
    phy_mdo          : out   std_ulogic;
    phy_mdoe         : out   std_ulogic;
    phy_mdi          : in    std_ulogic;
    phy_rgmii_tx_clk : out   std_ulogic;
    phy_rgmii_tx_ctl : out   std_ulogic;
    phy_rgmii_tx_d   : out   std_ulogic_vector(3 downto 0);
    phy_rgmii_rx_clk : in    std_ulogic;
    phy_rgmii_rx_ctl : in    std_ulogic;
    phy_rgmii_rx_d   : in    std_ulogic_vector(3 downto 0)

  );
end entity memac_raw_rgmii;

architecture rtl of memac_raw_rgmii is

  signal tx_umi_rst       : std_ulogic;
  signal tx_umi_clk       : std_ulogic;
  signal tx_umi_clken     : std_ulogic;
  signal tx_umi_dv        : std_ulogic;
  signal tx_umi_er        : std_ulogic;
  signal tx_umi_data      : std_ulogic_vector(7 downto 0);

  signal rx_umi_rst       : std_ulogic;
  signal rx_umi_clk       : std_ulogic;
  signal rx_umi_clken     : std_ulogic;
  signal rx_umi_dv        : std_ulogic;
  signal rx_umi_er        : std_ulogic;
  signal rx_umi_data      : std_ulogic_vector(7 downto 0);

  signal int_rgmii_rx_clk : std_ulogic;
  signal int_rgmii_rx_ctl : std_ulogic;
  signal int_rgmii_rx_d   : std_ulogic_vector(3 downto 0);

begin

  --------------------------------------------------------------------------------

  U_MEMAC_MDIO: component memac_mdio
    generic map (
      DIV5M => MDIO_DIV5M
    )
    port map (
      rst  => sys_rst,
      clk  => sys_clk,
      stb  => sys_md_stb,
      pre  => sys_md_pre,
      r_w  => sys_md_r_w,
      pa   => sys_md_pa,
      ra   => sys_md_ra,
      wd   => sys_md_wd,
      rd   => sys_md_rd,
      rdy  => sys_md_rdy,
      mdc  => phy_mdc,
      mdo  => phy_mdo,
      mdoe => phy_mdoe,
      mdi  => phy_mdi
    );

  --------------------------------------------------------------------------------

  tx_umi_rst <= ref_rst or sys_tx_rst;
  tx_umi_clk <= ref_clk;

  U_MEMAC_TX: component memac_tx
    port map (
      sys_rst   => sys_rst,
      sys_clk   => sys_clk,
      prq_rdy   => sys_tx_prq_rdy,
      prq_len   => sys_tx_prq_len,
      prq_idx   => sys_tx_prq_idx,
      prq_tag   => sys_tx_prq_tag,
      prq_opt   => sys_tx_prq_opt,
      prq_stb   => sys_tx_prq_stb,
      pfq_rdy   => sys_tx_pfq_rdy,
      pfq_len   => sys_tx_pfq_len,
      pfq_idx   => sys_tx_pfq_idx,
      pfq_tag   => sys_tx_pfq_tag,
      pfq_stb   => sys_tx_pfq_stb,
      buf_en    => sys_tx_buf_en,
      buf_bwe   => sys_tx_buf_bwe,
      buf_addr  => sys_tx_buf_addr,
      buf_din   => sys_tx_buf_din,
      buf_dpin  => sys_tx_buf_dpin,
      buf_dout  => sys_tx_buf_dout,
      buf_dpout => sys_tx_buf_dpout,
      umi_rst   => tx_umi_rst,
      umi_clk   => tx_umi_clk,
      umi_clken => tx_umi_clken,
      umi_dv    => tx_umi_dv,
      umi_er    => tx_umi_er,
      umi_d     => tx_umi_data
    );

  U_RGMII_TX: component memac_tx_rgmii
    generic map (
      ALIGN => TX_ALIGN
    )
    port map (
      ref_clk    => ref_clk,
      ref_clk_90 => ref_clk_90,
      umi_spd    => sys_tx_spd,
      umi_rst    => tx_umi_rst,
      umi_clk    => tx_umi_clk,
      umi_clken  => tx_umi_clken,
      umi_dv     => tx_umi_dv,
      umi_er     => tx_umi_er,
      umi_d      => tx_umi_data,
      rgmii_clk  => phy_rgmii_tx_clk,
      rgmii_ctl  => phy_rgmii_tx_ctl,
      rgmii_d    => phy_rgmii_tx_d
    );

  --------------------------------------------------------------------------------

  rx_umi_rst <= ref_rst or sys_rx_rst;

  U_MEMAC_RX: component memac_rx
    port map (
      sys_rst   => sys_rst,
      sys_clk   => sys_clk,
      opt       => sys_rx_opt,
      stat      => sys_rx_stat,
      prq_rdy   => sys_rx_prq_rdy,
      prq_len   => sys_rx_prq_len,
      prq_idx   => sys_rx_prq_idx,
      prq_flag  => sys_rx_prq_flag,
      prq_stb   => sys_rx_prq_stb,
      pfq_rdy   => sys_rx_pfq_rdy,
      pfq_len   => sys_rx_pfq_len,
      pfq_stb   => sys_rx_pfq_stb,
      buf_en    => sys_rx_buf_en,
      buf_bwe   => sys_rx_buf_bwe,
      buf_addr  => sys_rx_buf_addr,
      buf_din   => sys_rx_buf_din,
      buf_dpin  => sys_rx_buf_dpin,
      buf_dout  => sys_rx_buf_dout,
      buf_dpout => sys_rx_buf_dpout,
      umi_rst   => rx_umi_rst,
      umi_clk   => rx_umi_clk,
      umi_clken => rx_umi_clken,
      umi_dv    => rx_umi_dv,
      umi_er    => rx_umi_er,
      umi_data  => rx_umi_data
    );

  U_RGMII_RX: component memac_rx_rgmii
    port map (
      ref_rst   => ref_rst,
      ref_clk   => ref_clk,
      umi_spdi  => sys_rx_spd,
      umi_spdo  => sys_rx_stat.spd,
      umi_rst   => rx_umi_rst,
      umi_clk   => rx_umi_clk,
      umi_clken => rx_umi_clken,
      umi_dv    => rx_umi_dv,
      umi_er    => rx_umi_er,
      umi_d     => rx_umi_data,
      ibs_crs   => sys_rx_stat.ibs_crs,
      ibs_crx   => sys_rx_stat.ibs_crx,
      ibs_crxer => sys_rx_stat.ibs_crxer,
      ibs_crf   => sys_rx_stat.ibs_crf,
      ibs_link  => sys_rx_stat.ibs_link,
      ibs_spd   => sys_rx_stat.ibs_spd,
      ibs_fdx   => sys_rx_stat.ibs_fdx,
      rgmii_clk => int_rgmii_rx_clk,
      rgmii_ctl => int_rgmii_rx_ctl,
      rgmii_d   => int_rgmii_rx_d
    );

  U_RGMII_RX_IO: component memac_rx_rgmii_io
    generic map (
      ALIGN => RX_ALIGN
    )
    port map (
      i_clk   => phy_rgmii_rx_clk,
      i_ctl   => phy_rgmii_rx_ctl,
      i_d     => phy_rgmii_rx_d,
      o_clk   => rx_umi_clk,
      o_clkio => int_rgmii_rx_clk,
      o_ctl   => int_rgmii_rx_ctl,
      o_d     => int_rgmii_rx_d
    );

  --------------------------------------------------------------------------------

end architecture rtl;
