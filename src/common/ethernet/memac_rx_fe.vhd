--------------------------------------------------------------------------------
-- memac_rx_fe.vhd                                                            --
-- Modular Ethernet MAC: receive front end.                                   --
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

package memac_rx_fe_pkg is

  type memac_rx_opt_t is record
    ipg_min : integer;    -- minimum IPG
    pre_inc : std_ulogic; -- include preamble & SFD
    fcs_inc : std_ulogic; -- include FCS
    crc_inc : std_ulogic; -- include CRC
  end record memac_rx_opt_t;

  type memac_rx_flag_t is record
    ipg_short : std_ulogic; -- short IPG
    pre_inc   : std_ulogic; -- includes preamble & SFD
    pre_short : std_ulogic; -- short preamble (< 8)
    pre_long  : std_ulogic; -- long preamble (> 8)
    pre_bad   : std_ulogic; -- bad preamble or SFD
    data_err  : std_ulogic; -- data errors
    fcs_inc   : std_ulogic; -- includes FCS
    fcs_bad   : std_ulogic; -- FCS is bad
    crc_inc   : std_ulogic; -- includes CRC (over payload and FCS)
    truncate  : std_ulogic; -- was truncated
  end record memac_rx_flag_t;

  component memac_rx_fe is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      opt      : in    memac_rx_opt_t;
      drops    : out   std_ulogic_vector(31 downto 0);
      prq_rdy  : in    std_ulogic;
      prq_len  : out   std_ulogic_vector;
      prq_idx  : out   std_ulogic_vector;
      prq_flag : out   memac_rx_flag_t;
      prq_stb  : out   std_ulogic;
      pfq_rdy  : in    std_ulogic;
      pfq_len  : in    std_ulogic_vector;
      pfq_stb  : out   std_ulogic;
      buf_we   : out   std_ulogic;
      buf_idx  : out   std_ulogic_vector;
      buf_data : out   std_ulogic_vector(7 downto 0);
      buf_er   : out   std_ulogic;
      phy_dv   : in    std_ulogic;
      phy_er   : in    std_ulogic;
      phy_data : in    std_ulogic_vector(7 downto 0)
    );
  end component memac_rx_fe;

end package memac_rx_fe_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use work.memac_util_pkg.all;
use work.crc32_eth_8_pkg.all;

use work.memac_rx_fe_pkg.all;

entity memac_rx_fe is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    opt      : in    memac_rx_opt_t;
    drops    : out   std_ulogic_vector(31 downto 0);
    prq_rdy  : in    std_ulogic;
    prq_len  : out   std_ulogic_vector;
    prq_idx  : out   std_ulogic_vector;
    prq_flag : out   memac_rx_flag_t;
    prq_stb  : out   std_ulogic;
    pfq_rdy  : in    std_ulogic;
    pfq_len  : in    std_ulogic_vector;
    pfq_stb  : out   std_ulogic;
    buf_we   : out   std_ulogic;
    buf_idx  : out   std_ulogic_vector;
    buf_data : out   std_ulogic_vector(7 downto 0);
    buf_er   : out   std_ulogic;
    phy_dv   : in    std_ulogic;
    phy_er   : in    std_ulogic;
    phy_data : in    std_ulogic_vector(7 downto 0)
  );
end entity memac_rx_fe;

architecture rtl of memac_rx_fe is

  constant COUNT_MAX : integer := 15;

  type state_t is (IDLE,DROP,PRE,PKT,FCS,IPG);

  signal state      : state_t;
  signal count      : integer range 0 to COUNT_MAX;
  signal pkt_opt    : memac_rx_opt_t;
  signal phy_dv_r   : std_ulogic_vector(1 to 5);
  signal phy_er_r   : std_ulogic_vector(phy_dv_r'range);
  signal phy_data_r : sulv_array_t(phy_dv_r'range)(7 downto 0);
  signal buf_wr     : std_ulogic;
  signal buf_wptr   : std_ulogic_vector(buf_idx'range);
  signal buf_rptr   : std_ulogic_vector(buf_idx'range);
  signal buf_ff     : std_ulogic;
  signal crc32      : std_logic_vector(31 downto 0);
  signal pfq_stb_r  : std_ulogic_vector(1 to 4);

begin

  P_MAIN: process(rst,clk)
  begin
    if rst = '1' then

      state      <= IDLE;
      count      <= 0;
      pkt_opt    <= (ipg_min => 12, pre_inc => '0', fcs_inc => '0', crc_inc => '0');
      phy_dv_r   <= (phy_dv_r'range => '0');
      phy_er_r   <= (phy_er_r'range => '0');
      phy_data_r <= (phy_data_r'range => (phy_data_r'element'range => '0'));
      prq_len    <= (prq_len'range => '0');
      prq_idx    <= (prq_idx'range => '0');
      prq_flag   <= (others => '0');
      prq_stb    <= '0';
      buf_wptr   <= (buf_wptr'range => '0');
      buf_rptr   <= (buf_rptr'range => '0');
      buf_ff     <= '0';
      crc32      <= (crc32'range => '1');
      drops      <= (drops'range => '0');
      pfq_stb_r  <= (pfq_stb_r'range => '0');

    elsif rising_edge(clk) then

      phy_dv_r   <= phy_dv   & phy_dv_r   ( phy_dv_r'low   to phy_dv_r'high-1   );
      phy_er_r   <= phy_er   & phy_er_r   ( phy_er_r'low   to phy_er_r'high-1   );
      phy_data_r <= phy_data & phy_data_r ( phy_data_r'low to phy_data_r'high-1 );
      prq_stb <= '0';

      case state is

        when IDLE =>
          crc32 <= (others => '1');
          if phy_dv_r(4) = '1' then
            if prq_rdy = '1' then
              buf_wr  <= opt.pre_inc;
              prq_len <= (prq_len'range => '0');
              prq_flag.pre_inc <= opt.pre_inc;
              prq_flag.fcs_bad <= '1';
              state <= PRE;
              count <= 0;
            else
              incr(drops);
              state <= DROP;
              count <= 0;
            end if;
          end if;

        when DROP =>
          if phy_dv_r(4) = '0' then
            state <= IPG;
            count <= 0;
          end if;

        when PRE =>
          count <= count + 1;
          if phy_data_r(5) = x"D5" then
            if count < 7 then
              prq_flag.pre_short <= '1';
            elsif count > 7 then
              prq_flag.pre_long <= '1';
            end if;
            buf_wr <= '1';
            state  <= PKT;
            count  <= 0;
          elsif phy_data_r(5) = x"55" then
            if count > 6 then
              prq_flag.pre_long <= '1';
            end if;
          else
            prq_flag.pre_bad <= '1';
            buf_wr <= '1';
            state <= PKT;
            count <= 0;
          end if;
          if phy_er_r(5) = '1' then
            prq_flag.pre_bad <= '1';
          end if;
          if phy_dv_r(4) = '0' then -- premature end of packet
            buf_wr <= '0';
            state  <= IPG;
            count  <= 0;
          end if;

        when PKT =>
          crc32 <= crc32_eth_8(phy_data_r(5),crc32);
          if phy_er_r(5) = '1' then
            prq_flag.data_err <= '1';
          end if;
          if phy_dv & phy_dv_r = "011111" then -- FCS is next
            buf_wr <= pkt_opt.fcs_inc;
            prq_flag.fcs_inc <= pkt_opt.fcs_inc;
            state  <= FCS;
            count  <= 0;
          elsif phy_dv_r(4) = '0' then -- this is last byte
            buf_wr  <= '0';
            prq_stb <= '1';
            state   <= IPG;
            count   <= 0;
          end if;

        when FCS =>
          count <= count + 1;
          if count = 0 then
            if  crc32( 31 downto 24 ) = phy_data_r(5)
            and crc32( 23 downto 16 ) = phy_data_r(4)
            and crc32( 15 downto  8 ) = phy_data_r(3)
            and crc32(  7 downto  0 ) = phy_data_r(2)
            then
              prq_flag.fcs_bad <= '0';
            end if;
          elsif count = 3 then
            buf_wr  <= '0';
            prq_stb <= '1';
            state   <= IPG;
            count   <= 0;
          else
            count <= count + 1;
          end if;

        when IPG =>
          if phy_dv_r(3) = '1' then
            prq_flag <= (others => '0');
            if count < pkt_opt.ipg_min-2 then
              prq_flag.ipg_short <= '1';
            end if;
            state <= IDLE;
            count <= 0;
          elsif count < COUNT_MAX then
            count <= count + 1;
          end if;

      end case;

      if buf_ff = '0' then
        if buf_wr = '1' and unsigned(buf_wptr)+1 = unsigned(buf_rptr) then
          buf_ff <= '1';
        end if;
      else
        if unsigned(buf_rptr) /= unsigned(buf_wptr) then
          buf_ff <= '0';
        end if;
      end if;

      if buf_wr = '1' then
        if buf_ff = '0' then
          incr(buf_wptr);
          incr(prq_len);
        else
          prq_flag.truncate <= '1';
        end if;
      end if;

      if prq_stb = '1' then
        prq_idx  <= buf_wptr;
        prq_flag <= (others => '0');
      end if;

      pfq_stb_r <= pfq_stb  & pfq_stb_r(pfq_stb_r'low to pfq_stb_r'high-1);
      pfq_stb <= bool2sl(pfq_rdy = '1' and unsigned(pfq_stb & pfq_stb_r) = 0);
      if pfq_stb = '1' then
        buf_rptr <= std_ulogic_vector(unsigned(buf_rptr) + unsigned(pfq_len));
      end if;

    end if;
  end process P_MAIN;

  buf_we   <= buf_wr and not buf_ff;
  buf_idx  <= buf_wptr;
  buf_data <= phy_data_r(5);
  buf_er   <= phy_er_r(5);

end architecture rtl;
