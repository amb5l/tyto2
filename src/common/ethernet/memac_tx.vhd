--------------------------------------------------------------------------------
-- memac_tx.vhd                                                               --
-- Modular Ethernet MAC (MEMAC) - transmit side.                              --
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

package memac_tx_pkg is

  component memac_tx is
    port (
      sys_rst   : in    std_ulogic;
      sys_clk   : in    std_ulogic;
      prq_rdy   : out   std_ulogic;
      prq_len   : in    std_ulogic_vector;
      prq_idx   : in    std_ulogic_vector;
      prq_tag   : in    std_ulogic_vector;
      prq_opt   : in    tx_opt_t;
      prq_stb   : in    std_ulogic;
      pfq_rdy   : out   std_ulogic;
      pfq_len   : out   std_ulogic_vector;
      pfq_idx   : out   std_ulogic_vector;
      pfq_tag   : out   std_ulogic_vector;
      pfq_stb   : in    std_ulogic;
      buf_en    : in    std_ulogic;
      buf_bwe   : in    std_ulogic_vector(3 downto 0);
      buf_addr  : in    std_ulogic_vector;
      buf_din   : in    std_ulogic_vector(31 downto 0);
      buf_dpin  : in    std_ulogic_vector(3 downto 0);
      buf_dout  : out   std_ulogic_vector(31 downto 0);
      buf_dpout : out   std_ulogic_vector(3 downto 0);
      umi_rst   : in    std_ulogic;
      umi_clk   : in    std_ulogic;
      umi_clken : in    std_ulogic;
      umi_dv    : out   std_ulogic;
      umi_er    : out   std_ulogic;
      umi_d     : out   std_ulogic_vector(7 downto 0)
    );
  end component memac_tx;

end package memac_tx_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_pdq_pkg.all;
use work.memac_buf_pkg.all;
use work.memac_tx_fe_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity memac_tx is
  port (

    sys_rst   : in    std_ulogic;
    sys_clk   : in    std_ulogic;

    prq_rdy   : out   std_ulogic;
    prq_len   : in    std_ulogic_vector;
    prq_idx   : in    std_ulogic_vector;
    prq_tag   : in    std_ulogic_vector;
    prq_opt   : in    tx_opt_t;
    prq_stb   : in    std_ulogic;

    pfq_rdy   : out   std_ulogic;
    pfq_len   : out   std_ulogic_vector;
    pfq_idx   : out   std_ulogic_vector;
    pfq_tag   : out   std_ulogic_vector;
    pfq_stb   : in    std_ulogic;

    buf_en    : in    std_ulogic;
    buf_bwe   : in    std_ulogic_vector(3 downto 0);
    buf_addr  : in    std_ulogic_vector;
    buf_din   : in    std_ulogic_vector(31 downto 0);
    buf_dpin  : in    std_ulogic_vector(3 downto 0);
    buf_dout  : out   std_ulogic_vector(31 downto 0);
    buf_dpout : out   std_ulogic_vector(3 downto 0);

    umi_rst   : in    std_ulogic;
    umi_clk   : in    std_ulogic;
    umi_clken : in    std_ulogic;
    umi_dv    : out   std_ulogic;
    umi_er    : out   std_ulogic;
    umi_d     : out   std_ulogic_vector(7 downto 0)

  );
end entity memac_tx;

architecture rtl of memac_tx is

  constant PRQ_W        : integer := prq_opt'length +
                                     prq_tag'length +
                                     prq_idx'length +
                                     prq_len'length;
  constant PRQ_LEN_LSB : integer := 0;
  constant PRQ_LEN_MSB : integer := PRQ_LEN_LSB+prq_len'length-1;
  constant PRQ_IDX_LSB : integer := PRQ_LEN_MSB+1;
  constant PRQ_IDX_MSB : integer := PRQ_IDX_LSB+prq_idx'length-1;
  constant PRQ_TAG_LSB : integer := PRQ_IDX_MSB+1;
  constant PRQ_TAG_MSB : integer := PRQ_TAG_LSB+prq_tag'length-1;
  constant PRQ_OPT_LSB : integer := PRQ_TAG_MSB+1;
  constant PRQ_OPT_MSB : integer := PRQ_OPT_LSB+prq_opt'length-1;

  constant PFQ_W       : integer := pfq_tag'length +
                                    pfq_idx'length +
                                    pfq_len'length;
  constant PFQ_LEN_LSB : integer := 0;
  constant PFQ_LEN_MSB : integer := PFQ_LEN_LSB+pfq_len'length-1;
  constant PFQ_IDX_LSB : integer := PFQ_LEN_MSB+1;
  constant PFQ_IDX_MSB : integer := PFQ_IDX_LSB+pfq_idx'length-1;
  constant PFQ_TAG_LSB : integer := PFQ_IDX_MSB+1;
  constant PFQ_TAG_MSB : integer := PFQ_TAG_LSB+pfq_tag'length-1;

  signal pfq_rd        : std_ulogic_vector(PFQ_W-1 downto 0);

  signal umi_prq_rdy   : std_ulogic;
  signal umi_prq_len   : std_ulogic_vector(prq_len'range);
  signal umi_prq_idx   : std_ulogic_vector(prq_idx'range);
  signal umi_prq_tag   : std_ulogic_vector(prq_tag'range);
  signal umi_prq_opt   : tx_opt_t;
  signal umi_prq_stb   : std_ulogic;
  signal umi_prq_rd    : std_ulogic_vector(PRQ_W-1 downto 0);

  signal umi_pfq_rdy   : std_ulogic;
  signal umi_pfq_len   : std_ulogic_vector(pfq_len'range);
  signal umi_pfq_idx   : std_ulogic_vector(pfq_idx'range);
  signal umi_pfq_tag   : std_ulogic_vector(pfq_tag'range);
  signal umi_pfq_stb   : std_ulogic;

  signal umi_buf_en    : std_ulogic;
  signal umi_buf_addr  : std_ulogic_vector(buf_addr'length+1 downto 0);
  signal umi_buf_dout  : std_ulogic_vector(7 downto 0);
  signal umi_buf_dpout : std_ulogic;

begin

  U_PRQ: component memac_pdq
    port map (
      a_rst   => sys_rst or umi_rst,
      w_clk   => sys_clk,
      w_clken => '1',
      w_rdy   => prq_rdy,
      w_stb   => prq_stb,
      w_data  => prq_opt & prq_tag & prq_idx & prq_len,
      r_clk   => umi_clk,
      r_clken => umi_clken,
      r_rdy   => umi_prq_rdy,
      r_stb   => umi_prq_stb,
      r_data  => umi_prq_rd
    );
  umi_prq_len <= umi_prq_rd(PRQ_LEN_MSB downto PRQ_LEN_LSB);
  umi_prq_idx <= umi_prq_rd(PRQ_IDX_MSB downto PRQ_IDX_LSB);
  umi_prq_tag <= umi_prq_rd(PRQ_TAG_MSB downto PRQ_TAG_LSB);
  umi_prq_opt <= umi_prq_rd(PRQ_OPT_MSB downto PRQ_OPT_LSB);

  U_PFQ: component memac_pdq
    port map (
      a_rst   => sys_rst or umi_rst,
      w_clk   => umi_clk,
      w_clken => umi_clken,
      w_rdy   => umi_pfq_rdy,
      w_stb   => umi_pfq_stb,
      w_data  => umi_pfq_tag & umi_pfq_idx & umi_pfq_len,
      r_clk   => sys_clk,
      r_clken => '1',
      r_rdy   => pfq_rdy,
      r_stb   => pfq_stb,
      r_data  => pfq_rd
    );
  pfq_len <= pfq_rd(PFQ_LEN_MSB downto PFQ_LEN_LSB);
  pfq_idx <= pfq_rd(PFQ_IDX_MSB downto PFQ_IDX_LSB);
  pfq_tag <= pfq_rd(PFQ_TAG_MSB downto PFQ_TAG_LSB);

  U_BUF: component memac_buf
    port map (
      cpu_clk   => sys_clk,
      cpu_en    => buf_en,
      cpu_bwe   => buf_bwe,
      cpu_addr  => buf_addr,
      cpu_din   => buf_din,
      cpu_dpin  => buf_dpin,
      cpu_dout  => buf_dout,
      cpu_dpout => buf_dpout,
      umi_clk   => umi_clk,
      umi_en    => umi_clken and umi_buf_en,
      umi_we    => '0',
      umi_addr  => umi_buf_addr,
      umi_din   => (others => '0'),
      umi_dpin  => '0',
      umi_dout  => umi_buf_dout,
      umi_dpout => umi_buf_dpout
    );

  U_FE: component memac_tx_fe
    port map (
      rst     => umi_rst,
      clk     => umi_clk,
      clken   => umi_clken,
      dv      => umi_dv,
      er      => umi_er,
      d       => umi_d,
      prq_rdy => umi_prq_rdy,
      prq_len => umi_prq_len,
      prq_idx => umi_prq_idx,
      prq_tag => umi_prq_tag,
      prq_opt => umi_prq_opt,
      prq_stb => umi_prq_stb,
      pfq_rdy => umi_pfq_rdy,
      pfq_len => umi_pfq_len,
      pfq_idx => umi_pfq_idx,
      pfq_tag => umi_pfq_tag,
      pfq_stb => umi_pfq_stb,
      buf_re  => umi_buf_en,
      buf_idx => umi_buf_addr,
      buf_d   => umi_buf_dout,
      buf_er  => umi_buf_dpout
    );

end architecture rtl;
