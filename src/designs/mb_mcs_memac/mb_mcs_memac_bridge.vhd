--------------------------------------------------------------------------------
-- mb_mcs_memac_bridge.vhd                                                    --
-- Bridge from mb_mcs CPU I/O bus to MEMAC queues and buffers.                --
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

use work.tyto_types_pkg.all;
use work.memac_pkg.all;
use work.memac_util_pkg.all;
use work.mb_mcs_wrapper_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package mb_mcs_memac_bridge_pkg is

  component mb_mcs_memac_bridge is
    port (
      rst          : in    std_ulogic;
      clk          : in    std_ulogic;
      io_mosi      : in    mb_mcs_io_mosi_t;
      io_miso      : out   mb_mcs_io_miso_t;
      md_stb       : out   std_ulogic;
      md_r_w       : out   std_ulogic;
      md_pa        : out   std_ulogic_vector(4 downto 0);
      md_ra        : out   std_ulogic_vector(4 downto 0);
      md_wd        : out   std_ulogic_vector(15 downto 0);
      md_rd        : in    std_ulogic_vector(15 downto 0);
      md_rdy       : in    std_ulogic;
      tx_prq_rdy   : in    std_ulogic;
      tx_prq_idx   : out   std_ulogic_vector;
      tx_prq_len   : out   std_ulogic_vector;
      tx_prq_tag   : out   std_ulogic_vector;
      tx_prq_opt   : out   tx_opt_t;
      tx_prq_stb   : out   std_ulogic;
      tx_pfq_rdy   : in    std_ulogic;
      tx_pfq_idx   : in    std_ulogic_vector;
      tx_pfq_len   : in    std_ulogic_vector;
      tx_pfq_tag   : in    std_ulogic_vector;
      tx_pfq_stb   : out   std_ulogic;
      tx_buf_en    : out   std_ulogic;
      tx_buf_bwe   : out   std_ulogic_vector(3 downto 0);
      tx_buf_addr  : out   std_ulogic_vector;
      tx_buf_din   : out   std_ulogic_vector(31 downto 0);
      tx_buf_dpin  : out   std_ulogic_vector(3 downto 0);
      tx_buf_dout  : in    std_ulogic_vector(31 downto 0);
      tx_buf_dpout : in    std_ulogic_vector(3 downto 0);
      rx_prq_rdy   : in    std_ulogic;
      rx_prq_idx   : in    std_ulogic_vector;
      rx_prq_len   : in    std_ulogic_vector;
      rx_prq_flag  : in    rx_flag_t;
      rx_prq_stb   : out   std_ulogic;
      rx_pfq_rdy   : in    std_ulogic;
      rx_pfq_len   : out   std_ulogic_vector;
      rx_pfq_stb   : out   std_ulogic;
      rx_buf_en    : out   std_ulogic;
      rx_buf_bwe   : out   std_ulogic_vector(3 downto 0);
      rx_buf_addr  : out   std_ulogic_vector;
      rx_buf_din   : out   std_ulogic_vector(31 downto 0);
      rx_buf_dpin  : out   std_ulogic_vector(3 downto 0);
      rx_buf_dout  : in    std_ulogic_vector(31 downto 0);
      rx_buf_dpout : in    std_ulogic_vector(3 downto 0)
    );
  end component mb_mcs_memac_bridge;

end package mb_mcs_memac_bridge_pkg;

--------------------------------------------------------------------------------

use work.memac_pkg.all;
use work.memac_util_pkg.all;
use work.mb_mcs_wrapper_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity mb_mcs_memac_bridge is
  port (
    rst          : in    std_ulogic;
    clk          : in    std_ulogic;
    io_mosi      : in    mb_mcs_io_mosi_t;
    io_miso      : out   mb_mcs_io_miso_t;
    md_stb       : out   std_ulogic;
    md_r_w       : out   std_ulogic;
    md_pa        : out   std_ulogic_vector(4 downto 0);
    md_ra        : out   std_ulogic_vector(4 downto 0);
    md_wd        : out   std_ulogic_vector(15 downto 0);
    md_rd        : in    std_ulogic_vector(15 downto 0);
    md_rdy       : in    std_ulogic;
    tx_prq_rdy   : in    std_ulogic;
    tx_prq_idx   : out   std_ulogic_vector;
    tx_prq_len   : out   std_ulogic_vector;
    tx_prq_tag   : out   std_ulogic_vector;
    tx_prq_opt   : out   tx_opt_t;
    tx_prq_stb   : out   std_ulogic;
    tx_pfq_rdy   : in    std_ulogic;
    tx_pfq_idx   : in    std_ulogic_vector;
    tx_pfq_len   : in    std_ulogic_vector;
    tx_pfq_tag   : in    std_ulogic_vector;
    tx_pfq_stb   : out   std_ulogic;
    tx_buf_en    : out   std_ulogic;
    tx_buf_bwe   : out   std_ulogic_vector(3 downto 0);
    tx_buf_addr  : out   std_ulogic_vector;
    tx_buf_din   : out   std_ulogic_vector(31 downto 0);
    tx_buf_dpin  : out   std_ulogic_vector(3 downto 0);
    tx_buf_dout  : in    std_ulogic_vector(31 downto 0);
    tx_buf_dpout : in    std_ulogic_vector(3 downto 0);
    rx_prq_rdy   : in    std_ulogic;
    rx_prq_idx   : in    std_ulogic_vector;
    rx_prq_len   : in    std_ulogic_vector;
    rx_prq_flag  : in    rx_flag_t;
    rx_prq_stb   : out   std_ulogic;
    rx_pfq_rdy   : in    std_ulogic;
    rx_pfq_len   : out   std_ulogic_vector;
    rx_pfq_stb   : out   std_ulogic;
    rx_buf_en    : out   std_ulogic;
    rx_buf_bwe   : out   std_ulogic_vector(3 downto 0);
    rx_buf_addr  : out   std_ulogic_vector;
    rx_buf_din   : out   std_ulogic_vector(31 downto 0);
    rx_buf_dpin  : out   std_ulogic_vector(3 downto 0);
    rx_buf_dout  : in    std_ulogic_vector(31 downto 0);
    rx_buf_dpout : in    std_ulogic_vector(3 downto 0)
  );
end entity mb_mcs_memac_bridge;

architecture rtl of mb_mcs_memac_bridge is

  signal sel_tx_buf_std : std_ulogic;
  signal sel_tx_buf_err : std_ulogic;
  signal sel_tx_pq_lo   : std_ulogic;
  signal sel_tx_pq_hi   : std_ulogic;
  signal sel_rx_buf_std : std_ulogic;
  signal sel_rx_buf_err : std_ulogic;
  signal sel_rx_pq_lo   : std_ulogic;
  signal sel_rx_pq_hi   : std_ulogic;
  signal sel_md         : std_ulogic;

  signal tx_prq_opt_r   : tx_opt_t;
  signal tx_prq_tag_r   : std_ulogic_vector(tx_prq_tag'range);

  signal astb_l : std_ulogic;
  signal wstb_l : std_ulogic;
  signal rstb_l : std_ulogic;
  signal rrdy   : std_ulogic;

begin

-- 64k regions
-- A19-A16
-- 0000     TX buffer, no byte error flags asserted on write
-- 0001     TX buffer, byte error flags asserted on write
-- 001x     TX PRQ (write) PFQ (read)
--            lo = | idx | len |
--            hi = tag/flag
-- 0100     RX buffer data
-- 0101     RX buffer byte error flags
-- 011x     RX PRQ (read) PFQ (write)
-- 1xxx     MDIO

  P_COMB: process(all)
  begin

    --------------------------------------------------------------------------------
    -- I/O bus

    sel_tx_buf_std <= bool2sl(io_mosi.addr(19 downto 16) = "0000");
    sel_tx_buf_err <= bool2sl(io_mosi.addr(19 downto 16) = "0001");
    sel_tx_pq_lo   <= bool2sl(io_mosi.addr(19 downto 17) = "001" and io_mosi.addr(2) = '0');
    sel_tx_pq_hi   <= bool2sl(io_mosi.addr(19 downto 17) = "001" and io_mosi.addr(2) = '1');
    sel_rx_buf_std <= bool2sl(io_mosi.addr(19 downto 16) = "0100");
    sel_rx_buf_err <= bool2sl(io_mosi.addr(19 downto 16) = "0101");
    sel_rx_pq_lo   <= bool2sl(io_mosi.addr(19 downto 17) = "011" and io_mosi.addr(2) = '0');
    sel_rx_pq_hi   <= bool2sl(io_mosi.addr(19 downto 17) = "011" and io_mosi.addr(2) = '1');
    sel_md         <= io_mosi.addr(19);

    tx_prq_len  <= io_mosi.wdata(tx_prq_len'range);
    tx_prq_idx  <= io_mosi.wdata(16+tx_prq_idx'high downto 16);
    tx_prq_tag  <= tx_prq_tag_r;
    tx_prq_opt  <= tx_prq_opt_r;
    tx_prq_stb  <= sel_tx_pq_lo and io_mosi.wstb;

    tx_pfq_stb  <= sel_tx_pq_lo and io_mosi.rstb;

    tx_buf_en   <= io_mosi.astb and (sel_tx_buf_std or sel_tx_buf_err);
    tx_buf_bwe  <= io_mosi.be when (io_mosi.wstb = '1' or wstb_l = '1') else (others => '0');
    tx_buf_addr <= io_mosi.addr(tx_buf_addr'high downto 2);
    tx_buf_din  <= io_mosi.wdata;
    tx_buf_dpin <= io_mosi.be when sel_tx_buf_err else (others => '0');

    rx_prq_stb  <= sel_rx_pq_lo and io_mosi.rstb;

    rx_pfq_len  <= io_mosi.wdata(rx_pfq_len'range);
    rx_pfq_stb  <= sel_rx_pq_lo and io_mosi.wstb;

    rx_buf_en   <= io_mosi.astb and (sel_rx_buf_std or sel_rx_buf_err);
    rx_buf_bwe  <= io_mosi.be when (io_mosi.wstb = '1' or wstb_l = '1') else (others => '0');
    rx_buf_addr <= io_mosi.addr(rx_buf_addr'high downto 2);
    rx_buf_din  <= io_mosi.wdata;
    rx_buf_dpin <= io_mosi.be when sel_rx_buf_err else (others => '0');

    md_stb <= io_mosi.astb and sel_md;
    md_r_w <= io_mosi.rstb;
    md_pa  <= io_mosi.addr(11 downto 7);
    md_ra  <= io_mosi.addr(6 downto 2);
    md_wd  <= io_mosi.wdata(15 downto 0);

    io_miso.rdy <=
      (io_mosi.wstb and (
        sel_tx_buf_std or
        sel_tx_buf_err or
        sel_tx_pq_lo   or
        sel_tx_pq_hi   or
        sel_rx_buf_std or
        sel_rx_buf_err or
        sel_rx_pq_lo   or
        sel_rx_pq_hi   or
        sel_md
      )) or
      (rstb_l and (
        sel_tx_buf_std or
        sel_tx_buf_err or
        sel_tx_pq_lo   or
        sel_tx_pq_hi   or
        sel_rx_buf_std or
        sel_rx_buf_err or
        sel_rx_pq_lo   or
        sel_rx_pq_hi   or
        (sel_md and md_rdy)
      ));

    if    sel_tx_buf_std then
      io_miso.rdata <= tx_buf_dout;
    elsif sel_tx_buf_err then
      io_miso.rdata <= (
        31 downto 24 => tx_buf_dpout(3),
        23 downto 16 => tx_buf_dpout(2),
        15 downto  8 => tx_buf_dpout(1),
         7 downto  0 => tx_buf_dpout(0)
      );
    elsif sel_tx_pq_lo then
      io_miso.rdata(15 downto  0) <= (tx_pfq_len'range => tx_pfq_len, others => '0');
      io_miso.rdata(31 downto 16) <= (16+tx_pfq_idx'length-1 downto 16 => tx_pfq_idx, others => '0');
    elsif sel_tx_pq_hi then
      io_miso.rdata(15 downto  0) <= (others => '0');
      io_miso.rdata(31 downto 16) <= (16+tx_pfq_tag'length-1 downto 16 => tx_pfq_tag, others => '0');
    elsif sel_rx_buf_std then
      io_miso.rdata <= rx_buf_dout;
    elsif sel_rx_buf_err then
      io_miso.rdata <= (
        31 downto 24 => rx_buf_dpout(3),
        23 downto 16 => rx_buf_dpout(2),
        15 downto  8 => rx_buf_dpout(1),
         7 downto  0 => rx_buf_dpout(0)
      );
    elsif sel_rx_pq_lo then
      rx_pfq_stb <= io_mosi.wstb;
      rx_prq_stb <= not io_mosi.wstb;
      io_miso.rdata(15 downto  0) <= (rx_prq_len'range => rx_prq_len, others => '0');
      io_miso.rdata(31 downto 16) <= (16+rx_prq_idx'length-1 downto 16 => rx_prq_idx, others => '0');
    elsif sel_rx_pq_hi then
      io_miso.rdata <= (rx_prq_flag'range => rx_prq_flag, others => '0');
    elsif sel_md then
      io_miso.rdata <= x"0000" & md_rd;
    else
      io_miso.rdata <= (others => 'X');
    end if;

  end process P_COMB;

  P_SYNC: process(rst, clk)
  begin
    if rst = '1' then
      tx_prq_tag_r <= (others => '0');
      astb_l <= '0';
      wstb_l <= '0';
      rstb_l <= '0';
      rrdy   <= '0';
    elsif rising_edge(clk) then
      if sel_tx_pq_hi and io_mosi.wstb then
        if io_mosi.be(0) then
          tx_prq_opt_r <= io_mosi.wdata(tx_prq_opt_r'range);
        end if;
        if io_mosi.be(2) then
          tx_prq_tag_r <= io_mosi.wdata(16+tx_prq_tag'high downto 16);
        end if;
      end if;
      if io_mosi.astb = '1' and io_miso.rdy = '0' then
        astb_l <= '1';
      elsif astb_l = '1' and io_miso.rdy = '1' then
        astb_l <= '0';
      end if;
      if io_mosi.wstb = '1' and io_miso.rdy = '0' then
        wstb_l <= '1';
      elsif wstb_l = '1' and io_miso.rdy = '1' then
        wstb_l <= '0';
      end if;
      if io_mosi.rstb = '1' and io_miso.rdy = '0' then
        rstb_l <= '1';
      elsif rstb_l = '1' and io_miso.rdy = '1' then
        rstb_l <= '0';
      end if;
      rrdy <= io_mosi.rstb;
    end if;
  end process P_SYNC;

end architecture rtl;
