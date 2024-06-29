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

use work.tyto_types_pkg.all;
use work.memac_pkg.all;
use work.memac_util_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_rx_fe_pkg is

  constant MTU       : positive := 1522;
  constant BUF_SIZE  : positive := 8 * kByte;
  constant TAG_WIDTH : positive := 2;

  --------------------------------------------------------------------------------
  -- DUT packet descriptor queue types

  -- packet reservation
  type prd_t is record
    len  : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    flag : rx_flag_t;
  end record prd_t;
  constant PRQ_EMPTY : prd_t := (
    len  => (log2(MTU)-1 downto 0 => 'X'),
    idx  => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    flag => (others => 'X')
  );

  -- packet free
  type rx_pfd_t is record
    len : std_ulogic_vector(log2(MTU)-1 downto 0);
  end record rx_pfd_t;
  constant PFQ_EMPTY : rx_pfd_t := (len => (log2(MTU)-1 downto 0 => 'X'));

  --------------------------------------------------------------------------------
  -- expected packet queue type

  type packet_t is record
    len  : natural range 0 to MTU-1;
    data : uint8_array_t(0 to MTU-1);
  end record packet_t;
  constant PACKET_EMPTY : packet_t := (len => 0, data => (others => 0));

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

use work.tyto_types_pkg.all;
use work.memac_pkg.all;
use work.memac_util_pkg.all;
use work.crc32_eth_8_pkg.all;
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

  -- DUT
  signal rst          : std_ulogic;
  signal clk          : std_ulogic;
  signal clken        : std_ulogic;
  signal ipg_min      : std_ulogic_vector(3 downto 0);
  signal pre_inc      : std_ulogic;
  signal fcs_inc      : std_ulogic;
  signal drops        : std_ulogic_vector(31 downto 0);
  signal dut_prq_rdy  : std_ulogic;
  signal dut_prq_len  : std_ulogic_vector(log2(MTU)-1 downto 0); -- 2kB max
  signal dut_prq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal dut_prq_flag : rx_flag_t;
  signal dut_prq_stb  : std_ulogic;
  signal dut_pfq_rdy  : std_ulogic;
  signal dut_pfq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal dut_pfq_stb  : std_ulogic;
  signal dut_buf_we   : std_ulogic;
  signal dut_buf_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0); -- 8kB
  signal dut_buf_data : std_ulogic_vector(7 downto 0);
  signal dut_buf_er   : std_ulogic;
  signal umi_dv       : std_ulogic;
  signal umi_er       : std_ulogic;
  signal umi_data     : std_ulogic_vector(7 downto 0);

  -- testbench side of queues
  signal tb_prq_rdy   : std_ulogic;
  signal tb_prq_len  : std_ulogic_vector(log2(MTU)-1 downto 0); -- 2kB max
  signal tb_prq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal tb_prq_flag : rx_flag_t;
  signal tb_prq_stb  : std_ulogic;
  signal tb_pfq_rdy  : std_ulogic;
  signal tb_pfq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal tb_pfq_stb  : std_ulogic;

  -- simulation only: signals to allow shared variables to be added to waveform
  signal sim_prq_items : integer; -- v4p ignore w-303
  signal sim_pfq_items : integer; -- v4p ignore w-303
  signal sim_exp_items : integer; -- v4p ignore w-303
  signal sim_buf_space : integer; -- v4p ignore w-303

  --------------------------------------------------------------------------------
  -- buffer RAM

  type shared_buffer_t is protected
    procedure set(addr : natural; data : std_ulogic_vector);
    impure function get(addr : natural) return std_ulogic_vector;
  end protected shared_buffer_t;

  type shared_buffer_t is protected body
    variable memory : sulv_vector(0 to BUF_SIZE-1)(8 downto 0);
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

  clken <= '1';

  rst <= '1', '0' after CLK_PERIOD;

  --------------------------------------------------------------------------------
  -- transmit random packets

  P_TX: process
    variable pkt  : packet_t;
  begin
    umi_dv   <= '0';
    umi_er   <= '0';
    umi_data <= (others => 'X');
    for i in 1 to PACKET_COUNT loop
      -- random IPG
      for j in 1 to prng.rand_int(1,MTU) loop
        wait until rising_edge(clk);
      end loop;
      -- start of packet
      umi_dv   <= '1';
      umi_er   <= '0';
      -- random packet (including premable)
      pkt.len := prng.rand_int(1,MTU);
      for j in 0 to pkt.len-1 loop
        pkt.data(j) := prng.rand_int(0,255);
      end loop;
      for j in 0 to pkt.len-1 loop
        umi_data <= std_ulogic_vector(to_unsigned(pkt.data(j),8));
        wait until rising_edge(clk);
      end loop;
      report "enqueing packet - len = " & integer'image(pkt.len);
      expected.enq(pkt);
      -- end of packet
      umi_dv   <= '0';
      umi_er   <= '0';
      umi_data <= (others => 'X');
    end loop;
  end process P_TX;

  --------------------------------------------------------------------------------
  -- receive and check packets

  P_RX: process
    variable count : integer;
    variable pkt   : packet_t;
    variable rd    : std_ulogic_vector(7 downto 0);
    variable xd    : std_ulogic_vector(7 downto 0);
  begin
    count      := 0;
    ipg_min    <= x"8";
    pre_inc    <= '1';
    fcs_inc    <= '1';
    tb_prq_stb <= '0';
    loop
      wait until rising_edge(clk) and tb_prq_rdy = '1';
      pkt := expected.front;
      expected.deq;
      if not tb_prq_flag(RX_FLAG_TRUNCATE_BIT) then
        assert pkt.len = to_integer(unsigned(tb_prq_len)) report "length mismatch:" &
          " received = " & integer'image(to_integer(unsigned(tb_prq_len))) &
          " expected = " & integer'image(pkt.len)
          severity failure;
      end if;
      for i in 0 to to_integer(unsigned(tb_prq_len))-1 loop
        rd := buf.get(to_integer(unsigned(tb_prq_idx)+i) mod BUF_SIZE)(7 downto 0);
        xd := std_ulogic_vector(to_unsigned(pkt.data(i),8));
        assert rd = xd report "data mismatch:" &
          " received = " & to_hstring(rd) &
          " expected = " & to_hstring(xd)
          severity failure;
      end loop;
      count := count + 1;
      if count = PACKET_COUNT then
        report "SUCCESS";
        std.env.finish;
      end if;
      tb_prq_stb <= '1';
      tb_pfq_stb <= '1';
      tb_pfq_len <= tb_prq_len;
      wait until rising_edge(clk);
      tb_prq_stb <= '0';
      tb_pfq_stb <= '0';
      tb_pfq_len <= (others => 'X');
    end loop;
  end process P_RX;

  --------------------------------------------------------------------------------
  -- RX buffer RAM

  P_RX_BUF: process(clk)
  begin
    if rising_edge(clk) and dut_buf_we = '1' then
      buf.set(to_integer(unsigned(dut_buf_idx)),dut_buf_er & dut_buf_data);
    end if;
  end process P_RX_BUF;

  --------------------------------------------------------------------------------
  -- packet reservation queue
  -- descriptors are...
  --  enqueued here when dut_prq_stb is asserted
  --  dequeued in ...

  P_RX_PRQ: process(rst,clk)
  begin
    if rst = '1' then
      dut_prq_rdy <= '1';
      tb_prq_rdy  <= '0';
      tb_prq_len  <= (others => 'X');
      tb_prq_idx  <= (others => 'X');
      tb_prq_flag <= (others => 'X');
    elsif rising_edge(clk) then
      dut_prq_rdy <= '0' when prq.items >= PDQ_LEN else '1';
      tb_prq_rdy <= '1' when prq.items > 0  and tb_prq_stb = '0' else '0';
      tb_prq_len  <= prq.front.len;
      tb_prq_idx  <= prq.front.idx;
      tb_prq_flag <= prq.front.flag;
      if dut_prq_stb = '1' then
        prq.enq((len  => dut_prq_len,idx  => dut_prq_idx,flag => dut_prq_flag));
      end if;
      if tb_prq_stb = '1' then
        prq.deq;
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
      dut_pfq_rdy <= '0';
      dut_pfq_len <= (others => 'X');
      tb_pfq_rdy  <= '1';
    elsif rising_edge(clk) then
      tb_pfq_rdy <= '0' when pfq.items >= PDQ_LEN else '1';
      dut_pfq_rdy <= '1' when pfq.items > 0 and dut_pfq_stb = '0' else '0';
      dut_pfq_len <= pfq.front.len;
      if tb_prq_stb = '1' then
        pfq.enq((len  => tb_prq_len));
      end if;
      if dut_pfq_stb = '1' then
        pfq.deq;
      end if;
    end if;
  end process P_RX_PFQ;

  --------------------------------------------------------------------------------
  -- DUT instantiation

  DUT: component memac_rx_fe
    port map (
    rst      => rst,
    clk      => clk,
    clken    => clken,
    ipg_min  => ipg_min,
    pre_inc  => pre_inc,
    fcs_inc  => fcs_inc,
    drops    => drops,
    prq_rdy  => dut_prq_rdy,
    prq_len  => dut_prq_len,
    prq_idx  => dut_prq_idx,
    prq_flag => dut_prq_flag,
    prq_stb  => dut_prq_stb,
    pfq_rdy  => dut_pfq_rdy,
    pfq_len  => dut_pfq_len,
    pfq_stb  => dut_pfq_stb,
    buf_we   => dut_buf_we,
    buf_idx  => dut_buf_idx,
    buf_data => dut_buf_data,
    buf_er   => dut_buf_er,
    umi_dv   => umi_dv,
    umi_er   => umi_er,
    umi_data => umi_data
    );

  --------------------------------------------------------------------------------
  -- simulation waveform signals

  P_SIM: process(clk)
  begin
    if falling_edge(clk) then
      sim_prq_items <= prq.items;
      sim_pfq_items <= pfq.items;
      sim_exp_items <= expected.items;
      sim_buf_space <= buf_space.get;
    end if;
  end process P_SIM;

  --------------------------------------------------------------------------------

end architecture sim;
