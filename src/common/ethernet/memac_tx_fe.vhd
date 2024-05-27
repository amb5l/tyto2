--------------------------------------------------------------------------------
-- memac_tx_fe.vhd                                                            --
-- Modular Ethernet MAC: transmit front end.                                  --
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

package memac_tx_fe_pkg is

  type memac_tx_opt_t is record
    pre_len  : std_ulogic_vector(3 downto 0);
    pre_auto : std_ulogic;
    fcs_auto : std_ulogic;
  end record memac_tx_opt_t;

 constant MEMAC_TX_OPT_DEFAULT : memac_tx_opt_t := (
    pre_len  => x"8",
    pre_auto => 'X',
    fcs_auto => 'X'
  );

  component memac_tx_fe is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      prq_rdy  : in    std_ulogic;
      prq_len  : in    std_ulogic_vector;
      prq_idx  : in    std_ulogic_vector;
      prq_tag  : in    std_ulogic_vector;
      prq_opt  : in    memac_tx_opt_t := MEMAC_TX_OPT_DEFAULT;
      prq_stb  : out   std_ulogic;
      pfq_rdy  : in    std_ulogic;
      pfq_len  : out   std_ulogic_vector;
      pfq_idx  : out   std_ulogic_vector;
      pfq_tag  : out   std_ulogic_vector;
      pfq_stb  : out   std_ulogic;
      buf_re   : out   std_ulogic;
      buf_idx  : out   std_ulogic_vector;
      buf_data : in    std_ulogic_vector(7 downto 0);
      buf_er   : in    std_ulogic;
      phy_dv   : out   std_ulogic;
      phy_er   : out   std_ulogic;
      phy_data : out   std_ulogic_vector(7 downto 0)
    );
  end component memac_tx_fe;

end package memac_tx_fe_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

use work.memac_util_pkg.all;
use work.crc32_eth_8_pkg.all;
use work.memac_tx_fe_pkg.all;

entity memac_tx_fe is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    prq_rdy  : in    std_ulogic;
    prq_len  : in    std_ulogic_vector;
    prq_idx  : in    std_ulogic_vector;
    prq_tag  : in    std_ulogic_vector;
    prq_opt  : in    memac_tx_opt_t := MEMAC_TX_OPT_DEFAULT;
    prq_stb  : out   std_ulogic;
    pfq_rdy  : in    std_ulogic;
    pfq_len  : out   std_ulogic_vector;
    pfq_idx  : out   std_ulogic_vector;
    pfq_tag  : out   std_ulogic_vector;
    pfq_stb  : out   std_ulogic;
    buf_re   : out   std_ulogic;
    buf_idx  : out   std_ulogic_vector;
    buf_data : in    std_ulogic_vector(7 downto 0);
    buf_er   : in    std_ulogic;
    phy_dv   : out   std_ulogic;
    phy_er   : out   std_ulogic;
    phy_data : out   std_ulogic_vector(7 downto 0)
  );
end entity memac_tx_fe;

architecture rtl of memac_tx_fe is

  constant COUNT_MAX : integer := 15;

  type state_t is (IDLE,PRE,PKT,FCS,IPG,FIN);

  type phy_sel_t is (IPG,PRE,SFD,DATA,FCS1,FCS2,FCS3,FCS4);

  signal s1_state    : state_t;
  signal s1_count    : integer range 0 to COUNT_MAX;
  signal s1_prq_rdy  : std_ulogic;
  signal s1_prq_len  : std_ulogic_vector(prq_len'range);
  signal s1_prq_idx  : std_ulogic_vector(prq_idx'range);
  signal s1_prq_tag  : std_ulogic_vector(prq_tag'range);
  signal s1_prq_opt  : memac_tx_opt_t;
  signal s1_prq_stb  : std_ulogic;
  signal s1_pfq_rdy  : std_ulogic;
  signal s1_pfq_len  : std_ulogic_vector(pfq_len'range);
  signal s1_pfq_idx  : std_ulogic_vector(pfq_idx'range);
  signal s1_pfq_tag  : std_ulogic_vector(pfq_tag'range);
  signal s1_pfq_stb  : std_ulogic;
  signal s1_pkt_opt  : memac_tx_opt_t;
  signal s1_phy_sel  : phy_sel_t;
  signal s1_buf_re   : std_ulogic;
  signal s1_buf_len  : std_ulogic_vector(prq_len'range);
  signal s1_buf_idx  : std_ulogic_vector(buf_idx'range);

  signal s2_phy_sel  : phy_sel_t;
  signal s2_buf_data : std_ulogic_vector(buf_data'range);
  signal s2_buf_er   : std_ulogic;

  signal s3_phy_sel  : phy_sel_t;
  signal s3_buf_data : std_ulogic_vector(buf_data'range);
  signal s3_buf_er   : std_ulogic;
  signal s3_crc32    : std_ulogic_vector(31 downto 0);

  signal s4_phy_dv   : std_ulogic;
  signal s4_phy_er   : std_ulogic;
  signal s4_phy_data : std_ulogic_vector(7 downto 0);

begin

  s1_prq_rdy  <= prq_rdy;
  s1_prq_len  <= prq_len;
  s1_prq_idx  <= prq_idx;
  s1_prq_tag  <= prq_tag;
  s1_prq_opt  <= prq_opt;
  prq_stb     <= s1_prq_stb;
  s1_pfq_rdy  <= pfq_rdy;
  pfq_len     <= s1_pfq_len;
  pfq_idx     <= s1_pfq_idx;
  pfq_tag     <= s1_pfq_tag;
  pfq_stb     <= s1_pfq_stb;
  buf_re      <= s1_buf_re;
  buf_idx     <= s1_buf_idx;
  s2_buf_data <= buf_data;
  s2_buf_er   <= buf_er;
  phy_dv      <= s4_phy_dv;
  phy_er      <= s4_phy_er;
  phy_data    <= s4_phy_data;

  P_MAIN: process(rst,clk)
  begin
    if rst = '1' then

      s1_state    <= IDLE;
      s1_count    <= 0;
      s1_prq_stb  <= '0';
      s1_pfq_len  <= (others => 'X');
      s1_pfq_idx  <= (others => 'X');
      s1_pfq_tag  <= (others => 'X');
      s1_pfq_stb  <= '0';
      s1_pkt_opt  <= MEMAC_TX_OPT_DEFAULT;
      s1_buf_re   <= '0';
      s1_buf_len  <= (others => '0');
      s1_buf_idx  <= (others => '0');
      s2_phy_sel  <= IPG;
      s3_phy_sel  <= IPG;
      s3_buf_data <= (others => '0');
      s3_buf_er   <= '0';
      s3_crc32    <= (others => '1');
      s4_phy_dv   <= '0';
      s4_phy_er   <= '0';
      s4_phy_data <= (others => 'X');

    elsif rising_edge(clk) then

      --------------------------------------------------------------------------------
      -- stage 1

      s1_prq_stb <= '0';
      s1_pfq_stb <= '0';

      case s1_state is

        when IDLE =>
          if s1_prq_rdy = '1' then
            s1_prq_stb <= '1';
            s1_pfq_len <= s1_prq_len;
            s1_pfq_idx <= s1_prq_idx;
            s1_pfq_tag <= s1_prq_tag;
            s1_pkt_opt <= s1_prq_opt;
            s1_phy_sel <= PRE;
            s1_buf_re  <= '0' when s1_prq_opt.pre_auto = '1' else '1';
            s1_buf_len <= s1_prq_len;
            s1_buf_idx <= s1_prq_idx;
            s1_state <= PRE;
            s1_count <= 0;
          end if;

        when PRE =>
          s1_count <= s1_count + 1;
          if s1_count = to_integer(unsigned(s1_pkt_opt.pre_len))-2 then
            s1_phy_sel <= SFD when s1_pkt_opt.pre_auto = '1' else DATA;
          elsif s1_count = to_integer(unsigned(s1_pkt_opt.pre_len))-1 then
            s1_phy_sel <= DATA;
            s1_buf_re  <= '1';
            s1_state   <= PKT;
            s1_count   <= 0;
          end if;

        when PKT =>
          if unsigned(s1_buf_len) = 1 then
            s1_pfq_stb <= '1';
            s1_buf_re  <= '0';
            if s1_pkt_opt.fcs_auto = '1' then
              s1_phy_sel <= FCS1;
              s1_state   <= FCS;
            else
              s1_phy_sel <= IPG;
              s1_state   <= IPG;
            end if;
            s1_count <= 0;
          end if;

        when FCS =>
          case s1_count mod 4 is
            when 0      => s1_phy_sel <= FCS2;
            when 1      => s1_phy_sel <= FCS3;
            when 2      => s1_phy_sel <= FCS4;
            when others => s1_phy_sel <= FCS1;
          end case;
          if s1_count = 3 then
            s1_phy_sel <= IPG;
            s1_state   <= IPG;
            s1_count   <= 0;
          else
            s1_count <= s1_count + 1;
          end if;

        when IPG =>
          if s1_count = 9 then
            s1_state <= FIN;
            s1_count <= 0;
          else
            s1_count <= s1_count + 1;
          end if;

        when FIN =>
          if s1_pfq_rdy = '1' then
            s1_state   <= IDLE;
          end if;

      end case;

      if s1_buf_re = '1' then
        s1_buf_idx <= std_ulogic_vector(unsigned(s1_buf_idx)+1);
        s1_buf_len <= std_ulogic_vector(unsigned(s1_buf_len)-1);
      end if;

      --------------------------------------------------------------------------------
      -- stage 2

      s2_phy_sel <= s1_phy_sel;

      --------------------------------------------------------------------------------
      -- stage 3

      s3_phy_sel  <= s2_phy_sel;
      s3_buf_data <= s2_buf_data;
      s3_buf_er   <= s2_buf_er;

      if s2_phy_sel = SFD then
        s3_crc32 <= (others => '1');
      elsif s2_phy_sel = DATA then
        s3_crc32 <= crc32_eth_8(s2_buf_data,s3_crc32);
      end if;

      --------------------------------------------------------------------------------
      -- stage 4

      s4_phy_dv <= '0' when s3_phy_sel = IPG else '1';

      s4_phy_er <= s3_buf_er when s3_phy_sel = DATA else '0';

      case s3_phy_sel is
        when IPG  => s4_phy_data <= (others => 'X');
        when PRE  => s4_phy_data <= x"55";
        when SFD  => s4_phy_data <= x"D5";
        when DATA => s4_phy_data <= s3_buf_data;
        when FCS1 => s4_phy_data <= s3_crc32(31 downto 24);
        when FCS2 => s4_phy_data <= s3_crc32(23 downto 16);
        when FCS3 => s4_phy_data <= s3_crc32(15 downto  8);
        when FCS4 => s4_phy_data <= s3_crc32( 7 downto  0);
      end case;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

end architecture rtl;