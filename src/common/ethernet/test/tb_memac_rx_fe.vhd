--------------------------------------------------------------------------------
-- tb_memac_rx_fe.vhd                                                         --
-- Testbench for memac_rx_fe.                                                 --
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
-- definitions required for generic package instances

use work.memac_util_pkg.all;
use work.memac_rx_fe_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_rx_fe_pkg is

  constant MTU       : positive := 1522;
  constant BUF_SIZE  : positive := 8 * kByte;
  constant TAG_WIDTH : positive := 2;

  --------------------------------------------------------------------------------
  -- packet descriptor queues

  -- packet reservation
  type prd_t is record
    len  : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    flag : memac_rx_flag_t;
  end record prd_t;
  constant RX_PRQ_EMPTY : prd_t := (
    len  => (log2(MTU)-1 downto 0 => 'X'),
    idx  => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    flag => (others => 'X')
  );

  -- packet free
  type rx_pfd_t is record
    len : std_ulogic_vector(log2(MTU)-1 downto 0);
  end record rx_pfd_t;
  constant RX_PFQ_EMPTY : rx_pfd_t := (len => (log2(MTU)-1 downto 0 => 'X'));

  --------------------------------------------------------------------------------
  -- expected packet queue

  type packet_t is record
    size : natural;
    data : sulv_array_t(0 to MTU-1)(8 downto 0);
  end record packet_t;
  constant PACKET_EMPTY : packet_t := (size => 0, data => (others => (others => 'X')));

  --------------------------------------------------------------------------------

end package tb_memac_rx_fe_pkg;

--------------------------------------------------------------------------------
-- generic package instances

use work.tb_memac_rx_fe_pkg.all;
package prq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => prd_t,EMPTY => PRQ_EMPTY);

use work.tb_memac_rx_fe_pkg.all;
package pfq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => rx_pfd_t,EMPTY => PFQ_EMPTY);

use work.tb_memac_rx_fe_pkg.all;
package packet_queue_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => packet_t,EMPTY => PACKET_EMPTY);

--------------------------------------------------------------------------------
-- testbench entity and architecture

use work.crc32_eth_8_pkg.all;
use work.memac_util_pkg.all;
use work.memac_rx_fe_pkg.all;
use work.tb_memac_rx_fe_pkg.all;
use work.prq_pkg.all;
use work.pfq_pkg.all;
use work.packet_queue_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_memac_rx_fe is
  generic (
    PACKET_COUNT : positive
  );
end entity tb_memac_rx_fe;

architecture sim of tb_memac_rx_fe is

  --------------------------------------------------------------------------------

  constant CLK_PERIOD : time    :=  8 ns;
  constant PDQ_LEN    : integer := 32;

  --------------------------------------------------------------------------------
  -- signals

  signal rst         : std_ulogic;
  signal clk         : std_ulogic;

  -- RX DUT
  signal opt      : memac_rx_opt_t;
  signal drops    : std_ulogic_vector(31 downto 0);
  signal prq_rdy  : std_ulogic;
  signal prq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal prq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal prq_flag : memac_rx_flag_t;
  signal prq_stb  : std_ulogic;
  signal pfq_rdy  : std_ulogic;
  signal pfq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal pfq_stb  : std_ulogic;
  signal buf_we   : std_ulogic;
  signal buf_wptr : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal buf_data : std_ulogic_vector(7 downto 0);
  signal buf_er   : std_ulogic;

  -- PHY
  signal phy_dv      : std_ulogic;
  signal phy_er      : std_ulogic;
  signal phy_data    : std_ulogic_vector(7 downto 0);

  -- simulation only: signals to allow shared variables to be added to waveform
  signal sim_prq_items : integer; -- v4p ignore w-303
  signal sim_pfq_items : integer; -- v4p ignore w-303
  signal sim_buf_space : integer; -- v4p ignore w-303

  --------------------------------------------------------------------------------
  -- buffer RAM

  type shared_buffer_t is protected
    procedure set(addr : natural; data : std_ulogic_vector);
    impure function get(addr : natural) return std_ulogic_vector;
  end protected shared_buffer_t;

  type shared_buffer_t is protected body
    variable memory : sulv_array_t(0 to BUF_SIZE-1)(8 downto 0);
    procedure set(addr : natural; data : std_ulogic_vector) is
    begin
      memory(addr) := data;
    end procedure set;
    impure function get(addr : natural) return std_ulogic_vector is
    begin
      return memory(addr);
    end function get;
  end protected body shared_buffer_t;

  shared variable buf : shared_buffer_t;

  --------------------------------------------------------------------------------
  -- TX buffer space tracking

  type shared_int_t is protected
    procedure set(x : integer);
    procedure add(x : integer);
    procedure sub(x : integer);
    impure function get return integer;
  end protected shared_int_t;

  type shared_int_t is protected body
    variable value : integer;
    procedure set(x : integer) is
    begin
      value := x;
    end procedure set;
    procedure add(x : integer) is
    begin
      value := value + x;
    end procedure add;
    procedure sub(x : integer) is
    begin
      value := value - x;
    end procedure sub;
    impure function get return integer is
    begin
      return value;
    end function get;
  end protected body shared_int_t;

  shared variable buf_space : shared_int_t;

  --------------------------------------------------------------------------------
  -- queues

  shared variable prq      : work.prq_pkg.queue_t;
  shared variable pfq      : work.pfq_pkg.queue_t;
  shared variable expected : work.packet_queue_pkg.queue_t;

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- initialization

  P_INIT: process
  begin
    prng.rand_seed(123,456);
    wait;
  end process P_INIT;

  --------------------------------------------------------------------------------
  -- clock and reset

  clk <=
    '1' after CLK_PERIOD/2 when clk = '0' else
    '0' after CLK_PERIOD-(CLK_PERIOD/2) when clk = '1' else
    '0';

  rst <= '1', '0' after CLK_PERIOD;

  --------------------------------------------------------------------------------
  -- transmit random packets

  P_TX: process
  begin
    -- IPG
    -- random packet length and contents (length is constrained by available space)
    -- copy packet into tx buffer
    -- wait until there is space in the buffer and the packet reservation queue
    -- enqueue packet descriptor and expected packet
  end process P_TX;

  --------------------------------------------------------------------------------
  -- receive and check packets

  P_RX: process
  begin
     -- wait for packet
     -- read packet from buffer
     -- get expected packet
     -- check size
     -- check data
     -- check FCS
     -- finish
  end process P_RX;

  --------------------------------------------------------------------------------
  -- RX buffer RAM

  P_RX_BUF: process(clk)
  begin
    if rising_edge(clk) and buf_we = '1' then
      buf.set(to_integer(unsigned(buf_wptr)),buf_er & buf_data);
    end if;
  end process P_RX_BUF;

  --------------------------------------------------------------------------------
  -- RX packet reservation queue
  -- descriptors are...
  --  enqueued here when prq_stb is asserted
  --  dequeued in P_TX

  P_RX_PRQ: process(rst,clk)
  begin
    if rst = '1' then
      prq_rdy <= '0';
    elsif rising_edge(clk) then
      prq_rdy <= '1' when prq.items < PDQ_LEN-1;
      if prq_stb = '1' then
        prq.enq((len  => prq_len,idx  => prq_idx,flag => prq_flag));
      end if;
    end if;
  end process P_RX_PRQ;

  --------------------------------------------------------------------------------
  -- RX packet free queue
  -- descriptors are...
  --  enqueued in P_TX
  --  dequeued here when pfq_stb is asserted

  P_RX_PFQ: process(rst,clk)
  begin
    if rst = '1' then
      pfq_rdy <= '0';
      pfq_len <= (others => 'X');
    elsif rising_edge(clk) then
      if pfq_stb = '1' then
        pfq.deq;
      end if;
      pfq_rdy <= '0' when pfq.items = 0 or (pfq.items = 1 and pfq_stb = '1') else '1';
      pfq_len <= pfq.front.len;
    end if;
  end process P_RX_PFQ;

  --------------------------------------------------------------------------------
  -- DUT instantiation

  DUT: component memac_rx_fe
    port map (
      rst      => rst,
      clk      => clk,
      opt      => opt,
      drops    => drops,
      prq_rdy  => prq_rdy,
      prq_len  => prq_len,
      prq_idx  => prq_idx,
      prq_flag => prq_flag,
      prq_stb  => prq_stb,
      pfq_rdy  => pfq_rdy,
      pfq_len  => pfq_len,
      pfq_stb  => pfq_stb,
      buf_we   => buf_we,
      buf_idx  => buf_wptr,
      buf_data => buf_data,
      buf_er   => buf_er,
      phy_dv   => phy_dv,
      phy_er   => phy_er,
      phy_data => phy_data
    );

  --------------------------------------------------------------------------------
  -- simulation waveform signals

  P_SIM: process(clk)
  begin
    if falling_edge(clk) then
      sim_prq_items <= prq.items;
      sim_pfq_items <= pfq.items;
      sim_buf_space <= buf_space.get;
      sim_prq_items <= prq.items;
    end if;
  end process P_SIM;

  --------------------------------------------------------------------------------

end architecture sim;
