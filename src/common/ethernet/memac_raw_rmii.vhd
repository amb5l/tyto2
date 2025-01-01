--------------------------------------------------------------------------------
-- memac_raw_rmii.vhd                                                         --
-- Modular Ethernet MAC: raw system interface, RMII PHY interface.            --
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

package memac_raw_rmii_pkg is

  type rx_stat_t is record
    drops     : std_ulogic_vector(31 downto 0); -- packet drop counter
  end record rx_stat_t;

  component memac_raw_rmii is
    generic (
      F_SYS_CLK  : real;
      MDIO_DIV5M : integer
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
      sys_rx_spdi      : in    std_ulogic_vector(1 downto 0);
      sys_rx_spdo      : out   std_ulogic_vector(1 downto 0);
      sys_rx_ctrl      : in    rx_ctrl_t;
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

      sys_spd          : out   std_ulogic;
      sys_crs          : out   std_ulogic;
      sys_col          : out   std_ulogic;

      ref_rst          : in    std_ulogic;
      ref_clk          : in    std_ulogic;

      phy_mdc          : out   std_ulogic;
      phy_mdo          : out   std_ulogic;
      phy_mdoe         : out   std_ulogic;
      phy_mdi          : in    std_ulogic;
      phy_rmii_clk     : in    std_ulogic;
      phy_rmii_tx_en   : out   std_ulogic;
      phy_rmii_tx_d    : out   std_ulogic_vector(1 downto 0);
      phy_rmii_rx_dv   : in    std_ulogic;
      phy_rmii_rx_er   : in    std_ulogic;
      phy_rmii_rx_d    : in    std_ulogic_vector(1 downto 0)

    );
  end component memac_raw_rmii;

end package memac_raw_rmii_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_mdio_pkg.all;
use work.memac_spd_pkg.all;
use work.memac_tx_pkg.all;
use work.memac_tx_rmii_pkg.all;
use work.memac_rx_pkg.all;
use work.memac_rx_rmii_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_raw_rmii is
  generic (
    F_SYS_CLK  : real;
    MDIO_DIV5M : integer
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
    sys_rx_ctrl      : in    rx_ctrl_t;
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

    sys_spd          : out   std_ulogic;                      -- link speed: 0 = 10Mbps, 1 = 100Mbps
    sys_crs          : out   std_ulogic;                      -- carrier sense
    sys_col          : out   std_ulogic;                      -- collision detect

    ref_rst          : in    std_ulogic;                      -- reference clock reset
    ref_clk          : in    std_ulogic;                      -- reference clock

    phy_mdc          : out   std_ulogic;
    phy_mdo          : out   std_ulogic;
    phy_mdoe         : out   std_ulogic;
    phy_mdi          : in    std_ulogic;
    phy_rmii_clk     : in    std_ulogic;
    phy_rmii_tx_en   : out   std_ulogic;
    phy_rmii_tx_d    : out   std_ulogic_vector(1 downto 0);
    phy_rmii_rx_dv   : in    std_ulogic;
    phy_rmii_rx_er   : in    std_ulogic;
    phy_rmii_rx_d    : in    std_ulogic_vector(1 downto 0)

  );
end entity memac_raw_rmii;

architecture rtl of memac_raw_rmii is

  signal umi_rst          : std_ulogic;
  signal umi_clk          : std_ulogic;

  signal umi_tx_clken     : std_ulogic;
  signal umi_tx_dv        : std_ulogic;
  signal umi_tx_er        : std_ulogic;
  signal umi_tx_data      : std_ulogic_vector(7 downto 0);

  signal umi_rx_clken     : std_ulogic;
  signal umi_rx_dv        : std_ulogic;
  signal umi_rx_er        : std_ulogic;
  signal umi_rx_data      : std_ulogic_vector(7 downto 0);

begin

  --------------------------------------------------------------------------------

  U_MEMAC_MDIO: component memac_mdio
    generic map (
      F_RATIO => MDIO_DIV5M
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

  umi_rst <= 
  umi_clk <= phy_rmii_clk;

  --------------------------------------------------------------------------------

  umi_tx_rst <= sys_tx_rst;

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
      umi_rst   => umi_rst,
      umi_clk   => umi_clk,
      umi_clken => umi_tx_clken,
      umi_dv    => umi_tx_dv,
      umi_er    => umi_tx_er,
      umi_d     => umi_tx_data
    );

  U_RMII_TX: component memac_tx_rmii
    port map (
      umi_rst   => umi_rst,
      umi_clk   => umi_clk,
      umi_clken => umi_tx_clken,
      umi_dv    => umi_tx_dv,
      umi_er    => umi_tx_er,
      umi_d     => umi_tx_data,
      rmii_en   => phy_rmii_tx_en,
      rmii_d    => phy_rmii_tx_d
    );

  --------------------------------------------------------------------------------

  umi_rx_rst <= sys_rx_rst;

  U_MEMAC_RX: component memac_rx
    port map (
      sys_rst   => sys_rst,
      sys_clk   => sys_clk,
      ctrl      => sys_rx_ctrl,
      drops     => sys_rx_stat.drops,
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
      umi_rst   => umi_rst,
      umi_clk   => umi_clk,
      umi_clken => umi_rx_clken,
      umi_dv    => umi_rx_dv,
      umi_er    => umi_rx_er,
      umi_data  => umi_rx_data
    );

  U_RMII_RX: component memac_rx_rmii
    port map (
      umi_rst   => umi_rst,
      umi_clk   => umi_clk,
      umi_clken => umi_rx_clken,
      umi_dv    => umi_rx_dv,
      umi_er    => umi_rx_er,
      umi_d     => umi_rx_data,
      rmii_dv   => phy_rmii_rx_dv,
      rmii_er   => phy_rmii_rx_er,
      rmii_d    => phy_rmii_rx_d
    );

  --------------------------------------------------------------------------------

end architecture rtl;
