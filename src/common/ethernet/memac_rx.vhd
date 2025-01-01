--------------------------------------------------------------------------------
-- memac_rx.vhd                                                               --
-- Modular Ethernet MAC (MEMAC) - receive side.                               --
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

package memac_rx_pkg is

  component memac_rx is
    port (
      sys_rst    : in    std_ulogic;
      sys_clk    : in    std_ulogic;
      ctrl       : in    rx_ctrl_t;
      drops      : out   std_ulogic_vector(31 downto 0);
      prq_rdy    : out   std_ulogic;
      prq_len    : out   std_ulogic_vector;
      prq_idx    : out   std_ulogic_vector;
      prq_flag   : out   rx_flag_t;
      prq_stb    : in    std_ulogic;
      pfq_rdy    : out   std_ulogic;
      pfq_len    : in    std_ulogic_vector;
      pfq_stb    : in    std_ulogic;
      buf_en     : in    std_ulogic;
      buf_bwe    : in    std_ulogic_vector(3 downto 0);
      buf_addr   : in    std_ulogic_vector;
      buf_din    : in    std_ulogic_vector(31 downto 0);
      buf_dpin   : in    std_ulogic_vector(3 downto 0);
      buf_dout   : out   std_ulogic_vector(31 downto 0);
      buf_dpout  : out   std_ulogic_vector(3 downto 0);
      umii_rst   : in    std_ulogic;
      umii_clk   : in    std_ulogic;
      umii_clken : in    std_ulogic;
      umii_dv    : in    std_ulogic;
      umii_er    : in    std_ulogic;
      umii_data  : in    std_ulogic_vector(7 downto 0)
    );
  end component memac_rx;

end package memac_rx_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_pdq_pkg.all;
use work.memac_buf_pkg.all;
use work.memac_rx_fe_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_rx is
  port (

    sys_rst    : in    std_ulogic;
    sys_clk    : in    std_ulogic;

    ctrl       : in    rx_ctrl_t;
    drops      : out   std_ulogic_vector(31 downto 0);

    prq_rdy    : out   std_ulogic;
    prq_len    : out   std_ulogic_vector;
    prq_idx    : out   std_ulogic_vector;
    prq_flag   : out   rx_flag_t;
    prq_stb    : in    std_ulogic;

    pfq_rdy    : out   std_ulogic;
    pfq_len    : in    std_ulogic_vector;
    pfq_stb    : in    std_ulogic;

    buf_en     : in    std_ulogic;
    buf_bwe    : in    std_ulogic_vector(3 downto 0);
    buf_addr   : in    std_ulogic_vector;
    buf_din    : in    std_ulogic_vector(31 downto 0);
    buf_dpin   : in    std_ulogic_vector(3 downto 0);
    buf_dout   : out   std_ulogic_vector(31 downto 0);
    buf_dpout  : out   std_ulogic_vector(3 downto 0);

    umii_rst   : in    std_ulogic;
    umii_clk   : in    std_ulogic;
    umii_clken : in    std_ulogic;
    umii_dv    : in    std_ulogic;
    umii_er    : in    std_ulogic;
    umii_data  : in    std_ulogic_vector(7 downto 0)

  );
end entity memac_rx;

architecture rtl of memac_rx is

  constant PRQ_W            : integer := prq_flag'length +
                                         prq_idx'length +
                                         prq_len'length;
  constant PRQ_LEN_LSB      : integer := 0;
  constant PRQ_LEN_MSB      : integer := PRQ_LEN_LSB+prq_len'length-1;
  constant PRQ_IDX_LSB      : integer := PRQ_LEN_MSB+1;
  constant PRQ_IDX_MSB      : integer := PRQ_IDX_LSB+prq_idx'length-1;
  constant PRQ_FLAG_LSB     : integer := PRQ_IDX_MSB+1;
  constant PRQ_FLAG_MSB     : integer := PRQ_FLAG_LSB+prq_flag'length-1;

  signal prq_rd       : std_ulogic_vector(PRQ_W-1 downto 0);

  signal umii_prq_rdy  : std_ulogic;
  signal umii_prq_len  : std_ulogic_vector(prq_len'range);
  signal umii_prq_idx  : std_ulogic_vector(prq_idx'range);
  signal umii_prq_flag : rx_flag_t;
  signal umii_prq_stb  : std_ulogic;

  signal umii_pfq_rdy  : std_ulogic;
  signal umii_pfq_len  : std_ulogic_vector(pfq_len'range);
  signal umii_pfq_stb  : std_ulogic;

  signal umii_buf_we   : std_ulogic;
  signal umii_buf_addr : std_ulogic_vector(buf_addr'length+1 downto 0);
  signal umii_buf_data : std_ulogic_vector(7 downto 0);
  signal umii_buf_er   : std_ulogic;

begin


  U_PRQ: component memac_pdq
    port map (
      a_rst   => sys_rst or umii_rst,
      w_clk   => umii_clk,
      w_clken => '1',
      w_rdy   => umii_prq_rdy,
      w_stb   => umii_prq_stb,
      w_data  => umii_prq_flag & umii_prq_idx & umii_prq_len,
      r_clk   => sys_clk,
      r_clken => umii_clken,
      r_rdy   => prq_rdy,
      r_stb   => prq_stb,
      r_data  => prq_rd
    );
  prq_len  <= prq_rd(PRQ_LEN_MSB downto PRQ_LEN_LSB);
  prq_idx  <= prq_rd(PRQ_IDX_MSB downto PRQ_IDX_LSB);
  prq_flag <= prq_rd(PRQ_FLAG_MSB downto PRQ_FLAG_LSB);

  U_PFQ: component memac_pdq
    port map (
      a_rst   => sys_rst or umii_rst,
      w_clk   => sys_clk,
      w_clken => '1',
      w_rdy   => pfq_rdy,
      w_stb   => pfq_stb,
      w_data  => pfq_len,
      r_clk   => umii_clk,
      r_clken => umii_clken,
      r_rdy   => umii_pfq_rdy,
      r_stb   => umii_pfq_stb,
      r_data  => umii_pfq_len
    );

  U_BUF: component memac_buf
    port map (
      cpu_clk    => sys_clk,
      cpu_en     => buf_en,
      cpu_bwe    => buf_bwe,
      cpu_addr   => buf_addr,
      cpu_din    => buf_din,
      cpu_dpin   => buf_dpin,
      cpu_dout   => buf_dout,
      cpu_dpout  => buf_dpout,
      umii_clk   => umii_clk,
      umii_en    => umii_clken and umii_buf_we,
      umii_we    => umii_buf_we,
      umii_addr  => umii_buf_addr,
      umii_din   => umii_buf_data,
      umii_dpin  => umii_buf_er,
      umii_dout  => open,
      umii_dpout => open
    );

  U_FE: component memac_rx_fe
    port map (
      rst       => umii_rst,
      clk       => umii_clk,
      clken     => umii_clken,
      ipg_min   => ctrl.ipg_min,
      pre_inc   => ctrl.pre_inc,
      fcs_inc   => ctrl.fcs_inc,
      drops     => drops,
      prq_rdy   => umii_prq_rdy,
      prq_len   => umii_prq_len,
      prq_idx   => umii_prq_idx,
      prq_flag  => umii_prq_flag,
      prq_stb   => umii_prq_stb,
      pfq_rdy   => umii_pfq_rdy,
      pfq_len   => umii_pfq_len,
      pfq_stb   => umii_pfq_stb,
      buf_we    => umii_buf_we,
      buf_idx   => umii_buf_addr,
      buf_data  => umii_buf_data,
      buf_er    => umii_buf_er,
      umii_dv   => umii_dv,
      umii_er   => umii_er,
      umii_data => umii_data
    );

    -- TODO: BUFG for phy clk out ?

end architecture rtl;
