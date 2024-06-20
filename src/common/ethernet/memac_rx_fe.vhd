--------------------------------------------------------------------------------
-- memac_rx_fe.vhd                                                            --
-- Modular Ethernet MAC (MEMAC): receive front end.                           --
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

package memac_rx_fe_pkg is

  component memac_rx_fe is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      clken    : in    std_ulogic;
      ipg_min  : in    std_ulogic_vector(3 downto 0);
      pre_inc  : in    std_ulogic;
      fcs_inc  : in    std_ulogic;
      drops    : out   std_ulogic_vector(31 downto 0);
      prq_rdy  : in    std_ulogic;
      prq_len  : out   std_ulogic_vector;
      prq_idx  : out   std_ulogic_vector;
      prq_flag : out   rx_flag_t;
      prq_stb  : out   std_ulogic;
      pfq_rdy  : in    std_ulogic;
      pfq_len  : in    std_ulogic_vector;
      pfq_stb  : out   std_ulogic;
      buf_we   : out   std_ulogic;
      buf_idx  : out   std_ulogic_vector;
      buf_data : out   std_ulogic_vector(7 downto 0);
      buf_er   : out   std_ulogic;
      umi_dv   : in    std_ulogic;
      umi_er   : in    std_ulogic;
      umi_data : in    std_ulogic_vector(7 downto 0)
    );
  end component memac_rx_fe;

end package memac_rx_fe_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.memac_pkg.all;
use work.memac_util_pkg.all;
use work.crc32_eth_8_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_rx_fe is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    clken    : in    std_ulogic;
    ipg_min  : in    std_ulogic_vector(3 downto 0);
    pre_inc  : in    std_ulogic;
    fcs_inc  : in    std_ulogic;
    drops    : out   std_ulogic_vector(31 downto 0);
    prq_rdy  : in    std_ulogic;
    prq_len  : out   std_ulogic_vector;
    prq_idx  : out   std_ulogic_vector;
    prq_flag : out   rx_flag_t;
    prq_stb  : out   std_ulogic;
    pfq_rdy  : in    std_ulogic;
    pfq_len  : in    std_ulogic_vector;
    pfq_stb  : out   std_ulogic;
    buf_we   : out   std_ulogic;
    buf_idx  : out   std_ulogic_vector;
    buf_data : out   std_ulogic_vector(7 downto 0);
    buf_er   : out   std_ulogic;
    umi_dv   : in    std_ulogic;
    umi_er   : in    std_ulogic;
    umi_data : in    std_ulogic_vector(7 downto 0)
  );
end entity memac_rx_fe;

architecture rtl of memac_rx_fe is

  constant COUNT_MAX : integer := 15;

  type state_t is (IDLE,DROP,PRE,PKT,FCS,IPG);

  signal state      : state_t;
  signal count      : integer range 0 to COUNT_MAX;
  signal umi_dv_r   : std_ulogic_vector(1 to 5);
  signal umi_er_r   : std_ulogic_vector(umi_dv_r'range);
  signal umi_data_r : sulv_vector(umi_dv_r'range)(7 downto 0);
  signal buf_wr     : std_ulogic;
  signal buf_wptr   : std_ulogic_vector(buf_idx'range);
  signal buf_rptr   : std_ulogic_vector(buf_idx'range);
  signal buf_ff     : std_ulogic;
  signal crc32      : std_ulogic_vector(31 downto 0);
  signal pfq_rdy_r  : std_ulogic;
  signal pfq_len_r  : std_ulogic_vector(pfq_len'range);
  signal pfq_stb_r  : std_ulogic_vector(1 to 4);

begin

  P_MAIN: process(rst,clk)
  begin
    if rst = '1' then

      state      <= IDLE;
      count      <= 0;
      umi_dv_r   <= (umi_dv_r'range => '0');
      umi_er_r   <= (umi_er_r'range => '0');
      umi_data_r <= (umi_data_r'range => (umi_data_r'element'range => '0'));
      prq_len    <= (prq_len'range => '0');
      prq_idx    <= (prq_idx'range => '0');
      prq_flag   <= (others => '0');
      prq_stb    <= '0';
      buf_wr     <= '0';
      buf_wptr   <= (buf_wptr'range => '0');
      buf_rptr   <= (buf_rptr'range => '0');
      buf_ff     <= '0';
      crc32      <= (crc32'range => '1');
      drops      <= (drops'range => '0');
      pfq_rdy_r  <= '0';
      pfq_len_r  <= (pfq_len_r'range => '0');
      pfq_stb    <= '0';
      pfq_stb_r  <= (pfq_stb_r'range => '0');

    elsif rising_edge(clk) and clken = '1' then

      umi_dv_r   <= umi_dv   & umi_dv_r   ( umi_dv_r'low   to umi_dv_r'high-1   );
      umi_er_r   <= umi_er   & umi_er_r   ( umi_er_r'low   to umi_er_r'high-1   );
      umi_data_r <= umi_data & umi_data_r ( umi_data_r'low to umi_data_r'high-1 );
      pfq_rdy_r  <= pfq_rdy;
      pfq_len_r  <= pfq_len;

      prq_stb    <= '0';

      case state is

        when IDLE =>
          crc32 <= (others => '1');
          if umi_dv_r(4) = '1' then
            if prq_rdy = '1' then
              buf_wr  <= pre_inc;
              prq_len <= (prq_len'range => '0');
              prq_flag(RX_FLAG_PRE_INC_BIT) <= pre_inc;
              prq_flag(RX_FLAG_FCS_BAD_BIT) <= '1';
              if pre_inc then
                state <= PKT;
              else
                state <= PRE;
              end if;
              count <= 0;
            else
              incr(drops);
              state <= DROP;
              count <= 0;
            end if;
          end if;

        when DROP =>
          if umi_dv_r(4) = '0' then
            state <= IPG;
            count <= 0;
          end if;

        when PRE =>
          count <= count + 1;
          if umi_data_r(5) = x"D5" then
            if count < 7 then
              prq_flag(RX_FLAG_PRE_SHORT_BIT) <= '1';
            elsif count > 7 then
              prq_flag(RX_FLAG_PRE_LONG_BIT) <= '1';
            end if;
            buf_wr <= '1';
            state  <= PKT;
            count  <= 0;
          elsif umi_data_r(5) = x"55" then
            if count > 6 then
              prq_flag(RX_FLAG_PRE_LONG_BIT) <= '1';
            end if;
          else
            prq_flag(RX_FLAG_PRE_BAD_BIT) <= '1';
            buf_wr <= '1';
            state <= PKT;
            count <= 0;
          end if;
          if umi_er_r(5) = '1' then
            prq_flag(RX_FLAG_PRE_BAD_BIT) <= '1';
          end if;
          if umi_dv_r(4) = '0' then -- premature end of packet
            buf_wr <= '0';
            state  <= IPG;
            count  <= 0;
          end if;

        when PKT =>
          crc32 <= crc32_eth_8(umi_data_r(5),crc32);
          if umi_er_r(5) = '1' then
            prq_flag(RX_FLAG_DATA_ERR_BIT) <= '1';
          end if;
          if umi_dv & umi_dv_r = "011111" then -- FCS is next
            buf_wr <= fcs_inc;
            prq_flag(RX_FLAG_FCS_INC_BIT) <= fcs_inc;
            state  <= FCS;
            count  <= 0;
          elsif umi_dv_r(4) = '0' then -- this is last byte
            buf_wr  <= '0';
            prq_stb <= '1';
            count   <= 0;
            if umi_dv_r(3) = '1' then
              prq_flag <= (others => '0');
              prq_flag(RX_FLAG_IPG_SHORT_BIT) <= '1';
              state <= IDLE;
            else
              state <= IPG;
            end if;
          end if;

        when FCS =>
          count <= count + 1;
          if count = 0 then
            if  crc32( 31 downto 24 ) = umi_data_r(5)
            and crc32( 23 downto 16 ) = umi_data_r(4)
            and crc32( 15 downto  8 ) = umi_data_r(3)
            and crc32(  7 downto  0 ) = umi_data_r(2)
            then
              prq_flag(RX_FLAG_FCS_BAD_BIT) <= '0';
            end if;
          elsif count = 3 then
            buf_wr  <= '0';
            prq_stb <= '1';
            count   <= 0;
            if umi_dv_r(3) = '1' then
              prq_flag <= (others => '0');
              prq_flag(RX_FLAG_IPG_SHORT_BIT) <= '1';
              state <= IDLE;
            else
              state <= IPG;
            end if;
          else
            count <= count + 1;
          end if;

        when IPG =>
          if umi_dv_r(3) = '1' then
            prq_flag <= (others => '0');
            if count < to_integer(unsigned(ipg_min))-2 then
              prq_flag(RX_FLAG_IPG_SHORT_BIT) <= '1';
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
          prq_flag(RX_FLAG_TRUNCATE_BIT) <= '1';
        end if;
      end if;

      if prq_stb = '1' then
        prq_idx  <= buf_wptr;
        prq_flag <= (others => '0');
      end if;

      pfq_stb_r <= pfq_stb  & pfq_stb_r(pfq_stb_r'low to pfq_stb_r'high-1);
      pfq_stb <= bool2sl(pfq_rdy_r = '1' and unsigned(pfq_stb & pfq_stb_r) = 0);
      if pfq_stb = '1' then
        buf_rptr <= std_ulogic_vector(unsigned(buf_rptr) + unsigned(pfq_len_r));
      end if;

    end if;
  end process P_MAIN;

  buf_we   <= buf_wr and not buf_ff;
  buf_idx  <= buf_wptr;
  buf_data <= umi_data_r(5);
  buf_er   <= umi_er_r(5);

end architecture rtl;
