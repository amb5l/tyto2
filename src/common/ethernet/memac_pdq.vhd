--------------------------------------------------------------------------------
-- memac_buf_pkg.vhd                                                          --
-- Modular Ethernet MAC: packet descriptor queue.                             --
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

package memac_pdq_pkg is

  component memac_pdq is
    generic (
      DEPTH_LOG2 : integer := 5 -- effective DEPTH is (2**DEPTH_log2)-1
    );
    port (
      a_rst   : in    std_ulogic;
      w_clk   : in    std_ulogic;
      w_clken : in    std_ulogic;
      w_rdy   : out   std_ulogic;
      w_stb   : in    std_ulogic;
      w_data  : in    std_ulogic_vector;
      r_clk   : in    std_ulogic;
      r_clken : in    std_ulogic;
      r_rdy   : out   std_ulogic;
      r_stb   : in    std_ulogic;
      r_data  : out   std_ulogic_vector
    );
  end component memac_pdq;

end package memac_pdq_pkg;

--------------------------------------------------------------------------------

use work.memac_util_pkg.all;
use work.sync_reg_u_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_pdq is
  generic (
    DEPTH_LOG2 : integer := 5 -- effective DEPTH is (2**DEPTH_log2)-1
  );
  port (
    a_rst   : in    std_ulogic;
    w_clk   : in    std_ulogic;
    w_clken : in    std_ulogic;
    w_rdy   : out   std_ulogic;
    w_stb   : in    std_ulogic;
    w_data  : in    std_ulogic_vector;
    r_clk   : in    std_ulogic;
    r_clken : in    std_ulogic;
    r_rdy   : out   std_ulogic;
    r_stb   : in    std_ulogic;
    r_data  : out   std_ulogic_vector
  );
end entity memac_pdq;

architecture rtl of memac_pdq is

  constant DEPTH  : integer := 2**DEPTH_LOG2;
  constant STAGES : integer := 3;

  type ram_t is array(0 to DEPTH-1) of std_ulogic_vector(w_data'range);
  signal ram : ram_t;

  signal ff      : std_ulogic;                               -- full flag
  signal ef      : std_ulogic;                               -- empty flag

  signal w_rst_s : std_ulogic;                               -- write synchronous reset
  signal w_rst   : std_ulogic;                               -- write synchronous/asynchronous reset
  signal w_stb_r : std_ulogic_vector(1 to 3);                -- write strobe, delayed
  signal w_ptr   : std_ulogic_vector(DEPTH_LOG2-1 downto 0); -- write pointer (gray)
  signal w_ptr_1 : std_ulogic_vector(DEPTH_LOG2-1 downto 0); -- write pointer + 1 (gray)
  signaL w_ff    : std_ulogic;                               -- write synchronous full flag

  signal r_rst_s : std_ulogic;                               -- read synchronous reset
  signal r_rst   : std_ulogic;                               -- read synchronous/asynchronous reset
  signal r_stb_r : std_ulogic_vector(1 to 3);                -- read strobe, delayed
  signal r_ptr   : std_ulogic_vector(DEPTH_LOG2-1 downto 0); -- read pointer (gray)
  signal r_ef    : std_ulogic;                               -- read synchronous empty flag

begin

  U_SYNC_W: component sync_reg_u
    generic map (
      stages    => STAGES,
      rst_state => '0'
    )
    port map (
      rst => '0',
      clk => w_clk,
      i(0) => a_rst,
      i(1) => ff,
      o(0) => w_rst_s,
      o(1) => w_ff
    );
  w_rst <= w_rst_s or a_rst;

  P_W: process(w_rst,w_clk)
  begin
    if w_rst = '1' then
      w_ptr   <= std_logic_vector(to_unsigned(0,w_ptr'length));
      w_ptr_1 <= bin2gray(std_logic_vector(to_unsigned(1,w_ptr'length)));
      w_rdy <= '1';
    elsif rising_edge(w_clk) and w_clken = '1' then
      w_stb_r <= w_stb & w_stb_r(1 to w_stb_r'length-1);
      if w_stb = '1' then
        ram(to_integer(unsigned(w_ptr))) <= w_data;
        w_ptr   <= bin2gray(std_ulogic_vector((unsigned(gray2bin(w_ptr  ))+1)));
        w_ptr_1 <= bin2gray(std_ulogic_vector((unsigned(gray2bin(w_ptr_1))+1)));
        w_rdy   <= '0';
      end if;
      if w_rdy = '0' and w_ff = '0' and unsigned(w_stb_r) = 0 then
        w_rdy <= '1';
      end if;
    end if;
  end process;

  U_SYNC_R: component sync_reg_u
    generic map (
      stages    => STAGES,
      rst_state => '1'
    )
    port map (
      rst  => '0',
      clk  => r_clk,
      i(0) => a_rst,
      i(1) => ef,
      o(0) => r_rst_s,
      o(1) => r_ef
    );
  r_rst <= r_rst_s or a_rst;

  P_R: process(r_rst,r_clk)
  begin
    if r_rst = '1' then
      r_ptr <= std_logic_vector(to_unsigned(0,w_ptr'length));
      r_rdy <= '0';
    elsif rising_edge(r_clk) and r_clken = '1' then
      r_stb_r <= r_stb & r_stb_r(1 to r_stb_r'length-1);
      if r_stb = '1' then
        r_ptr <= bin2gray(std_ulogic_vector((unsigned(gray2bin(w_ptr))+1)));
      end if;
      if r_rdy = '0' and r_ef = '0' and unsigned(r_stb_r) = 0 then
        r_rdy <= '1';
      end if;
    end if;
  end process;

  P_COMB: process(all)
  begin
    r_data <= ram(to_integer(unsigned(r_ptr)));
    ef <= bool2sl(w_ptr   = r_ptr);
    ff <= bool2sl(w_ptr_1 = r_ptr);
  end process P_COMB;

end architecture rtl;
