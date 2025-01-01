--------------------------------------------------------------------------------
-- tb_memac_tx_fe.vhd                                                         --
-- Testbench for memac_tx_fe.                                                 --
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
use work.memac_tx_fe_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_fe_pkg is

  constant MTU       : positive := 1522;
  constant BUF_SIZE  : positive := 8 * kByte;
  constant TAG_WIDTH : positive := 2;

  --------------------------------------------------------------------------------
  -- packet descriptor queues

  -- packet reservation
  type prd_t is record
    len : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    tag : std_ulogic_vector(TAG_WIDTH-1 downto 0);
    opt : tx_opt_t;
  end record prd_t;
  constant PRQ_EMPTY : prd_t := (
    len  => (log2(MTU)-1 downto 0 => 'X'),
    idx  => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    tag  => (TAG_WIDTH-1 downto 0 => 'X'),
    opt => (
        TX_OPT_PRE_LEN_RANGE => x"8",
        TX_OPT_PRE_AUTO_BIT  => '1',
        TX_OPT_FCS_AUTO_BIT  => '1'
    )
  );

  -- packet free
  type pfd_t is record
    len : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    tag : std_ulogic_vector(TAG_WIDTH-1 downto 0);
  end record pfd_t;
  constant PFQ_EMPTY : pfd_t := (
    len => (log2(MTU)-1 downto 0 => 'X'),
    idx => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    tag => (TAG_WIDTH-1 downto 0 => 'X')
  );

  --------------------------------------------------------------------------------
  -- expected packet queue

  type packet_t is record
    size : natural;
    data : sulv_vector(0 to MTU-1)(8 downto 0);
  end record packet_t;
  constant PACKET_EMPTY : packet_t := (size => 0, data => (others => (others => 'X')));

  --------------------------------------------------------------------------------

end package tb_memac_fe_pkg;

--------------------------------------------------------------------------------
-- generic package instances

use work.tb_memac_fe_pkg.all;
package prq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => prd_t,EMPTY => PRQ_EMPTY);

use work.tb_memac_fe_pkg.all;
package pfq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => pfd_t,EMPTY => PFQ_EMPTY);

use work.tb_memac_fe_pkg.all;
package packet_queue_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => packet_t,EMPTY => PACKET_EMPTY);

--------------------------------------------------------------------------------
-- testbench entity and architecture

use work.tyto_types_pkg.all;
use work.crc32_eth_8_pkg.all;
use work.memac_pkg.all;
use work.memac_util_pkg.all;
use work.memac_tx_fe_pkg.all;
use work.tb_memac_fe_pkg.all;
use work.prq_pkg.all;
use work.pfq_pkg.all;
use work.packet_queue_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_memac_tx_fe is
  generic (
    PACKET_COUNT : positive
  );
end entity tb_memac_tx_fe;

architecture sim of tb_memac_tx_fe is

  --------------------------------------------------------------------------------

  constant CLK_PERIOD : time    :=  8 ns;
  constant PDQ_LEN    : integer := 32;

  --------------------------------------------------------------------------------
  -- signals

  signal rst   : std_ulogic;
  signal clk   : std_ulogic;
  signal clken : std_ulogic;

  -- DUT
  signal prq_rdy  : std_ulogic;
  signal prq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal prq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal prq_tag  : std_ulogic_vector(1 downto 0);
  signal prq_opt  : tx_opt_t;
  signal prq_stb  : std_ulogic;
  signal pfq_rdy  : std_ulogic;
  signal pfq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal pfq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal pfq_tag  : std_ulogic_vector(1 downto 0);
  signal pfq_stb  : std_ulogic;
  signal buf_re   : std_ulogic;
  signal buf_rptr : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal buf_d    : std_ulogic_vector(7 downto 0);
  signal buf_er   : std_ulogic;

  -- packet generator
  signal buf_wptr : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);

  -- PHY
  signal umii_dv : std_ulogic;
  signal umii_er : std_ulogic;
  signal umii_d  : std_ulogic_vector(7 downto 0);

  -- simulation only: signals to allow shared variables to be added to waveform
  signal sim_prq_items : integer;                        -- v4p ignore w-303
  signal sim_pfq_items : integer;                        -- v4p ignore w-303
  signal sim_buf_space : integer;                        -- v4p ignore w-303
  signal sim_crc       : std_ulogic_vector(31 downto 0); -- v4p ignore w-303
  signal sim_rfcs      : std_ulogic_vector(31 downto 0); -- v4p ignore w-303
  signal sim_xfcs      : std_ulogic_vector(31 downto 0); -- v4p ignore w-303

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

  P_TX: process(rst,clk)
    variable pkt : packet_t;
    variable prd : prd_t;
  begin
    if rst = '1' then
      buf_wptr <= (others => '0');
      buf_space.set(BUF_SIZE);
    elsif rising_edge(clk) then
      -- wait until there is space in the buffer and the packet reservation queue
      if buf_space.get > 0 and prq.items < PDQ_LEN-1 then
      -- random packet length and contents (length is constrained by available space)
        pkt.size := prng.rand_int(1,minimum(buf_space.get,MTU));
        for i in 0 to pkt.size-1 loop
          pkt.data(i) := prng.rand_slv(0,511,9);
          --pkt.data(i) := std_ulogic_vector(to_unsigned(i mod 512,9));
        end loop;
        -- copy packet into tx buffer
        for i in 0 to pkt.size-1 loop
          buf.set((to_integer(unsigned(buf_wptr))+i) mod BUF_SIZE,pkt.data(i));
        end loop;
        -- enqueue packet descriptor and expected packet
        prd.len := std_ulogic_vector(to_unsigned(pkt.size,prq_len'length));
        prd.idx := buf_wptr;
        prd.tag := "00";
        prd.opt := (
          TX_OPT_PRE_LEN_RANGE => x"8",
          TX_OPT_PRE_AUTO_BIT  => '1',
          TX_OPT_FCS_AUTO_BIT  => '1'
        );
        prq.enq(prd);
        if prd.opt(TX_OPT_FCS_AUTO_BIT) = '1' then
          pkt.size := pkt.size + 4; -- FCS
        end if;
        expected.enq(pkt);
        -- update write pointer and space value
        buf_wptr <= std_ulogic_vector(unsigned(buf_wptr)+pkt.size);
        buf_space.sub(pkt.size);
      end if;
      -- TODO: pace
    end if;
  end process P_TX;

  --------------------------------------------------------------------------------
  -- TX buffer RAM

  P_BUF: process(rst,clk)
  begin
    if rst = '1' then
      buf_d  <= (others => 'X');
      buf_er <= 'X';
    elsif rising_edge(clk) and buf_re = '1' then
      buf_d  <= buf.get(to_integer(unsigned(buf_rptr)))(7 downto 0);
      buf_er <= buf.get(to_integer(unsigned(buf_rptr)))(8);
    end if;
  end process P_BUF;

  --------------------------------------------------------------------------------
  -- TX packet reservation queue
  -- descriptors are...
  --  enqueued in P_TX
  --  dequeued here when prq_stb is asserted

  P_PRQ: process(rst,clk)
  begin
    if rst = '1' then
      prq_rdy <= '0';
      prq_len <= (others => 'X');
      prq_idx <= (others => 'X');
      prq_tag <= (others => 'X');
      prq_opt <= (
        TX_OPT_PRE_LEN_RANGE => 'X',
        TX_OPT_PRE_AUTO_BIT  => 'X',
        TX_OPT_FCS_AUTO_BIT  => 'X'
      );
    elsif rising_edge(clk) then
      if prq_stb = '1' then
        prq.deq;
      end if;
      prq_rdy <= '1' when prq.items > 0 else '0';
      prq_len <= prq.front.len;
      prq_idx <= prq.front.idx;
      prq_tag <= prq.front.tag;
      prq_opt <= prq.front.opt;
    end if;
  end process P_PRQ;

  --------------------------------------------------------------------------------
  -- TX packet free queue
  -- descriptors are...
  --  enqueued here when pfq_stb is asserted
  --  dequeued here (eagerly) TODO: pace this?

  P_PFQ: process(rst,clk)
    variable d : pfd_t;
  begin
    if rst = '1' then
      pfq_rdy <= '0';
    elsif rising_edge(clk) then
      pfq_rdy <= '1' when pfq.items < BUF_SIZE-1 else '0';
      if pfq_stb = '1' then
        d.len := pfq_len;
        d.idx := pfq_idx;
        d.tag := pfq_tag;
        pfq.enq(d);
      end if;
      if pfq.items > 0 then
        buf_space.add(to_integer(unsigned(pfq_len)));
        pfq.deq;
      end if;
    end if;
  end process P_PFQ;

  --------------------------------------------------------------------------------
  -- receive and check packets

  P_RX: process
    variable rpkt   : packet_t;
    variable xpkt   : packet_t;
    variable pcount : integer;
    variable count  : integer;
    variable crc    : std_ulogic_vector(31 downto 0);
    variable rfcs   : std_ulogic_vector(31 downto 0); -- received FCS
    variable xfcs   : std_ulogic_vector(31 downto 0); -- expected FCS
  begin
    pcount := 0;
    wait until falling_edge(rst);
    while pcount < PACKET_COUNT loop
      -- IPG
      count := 0;
      while umii_dv /= '1' loop
        count := count + 1;
        wait until falling_edge(clk);
      end loop;
      assert count >= 12 or pcount = 0
        report "IPG too short (" & integer'image(count) & " cycles)" severity failure;
      -- preamble
      for i in 1 to 7 loop
        assert umii_dv = '1'
          report "unexpected DV negation" severity failure;
        assert umii_er = '0'
          report "unexpected ER assertion" severity failure;
        assert umii_d(7 downto 0) = x"55"
          report "preamble error - expected 055, received " & to_hstring(umii_d(7 downto 0)) severity failure;
        wait until falling_edge(clk);
      end loop;
      -- SFD
      assert umii_dv = '1'
        report "unexpected DV negation" severity failure;
      assert umii_er = '0'
        report "unexpected ER assertion" severity failure;
      assert umii_d(7 downto 0) = x"D5"
          report "SFD error - expected 0D5, received " & to_hstring(umii_d(7 downto 0)) severity failure;
        wait until falling_edge(clk);
      -- packet data
      count := 0;
      while umii_dv = '1' loop
        rpkt.data(count) := umii_er & umii_d;
        count := count + 1;
        wait until falling_edge(clk);
      end loop;
      -- get expected packet
      xpkt := expected.front;
      -- check size
      while expected.items = 0 loop
        wait for 0 ps;
      end loop;
      rpkt.size := count;
      assert rpkt.size = xpkt.size
        report "received packet: " &
          integer'image(rpkt.size) & " octets recieved, " &
          integer'image(xpkt.size) & " octets expected"
          severity failure;
      -- check data
      if rpkt.data(0 to rpkt.size-5) /= xpkt.data(0 to rpkt.size-5) then
        for i in 0 to rpkt.size-5 loop
          if rpkt.data(i) /= xpkt.data(i) then
            report "received packet: at offset " & integer'image(i) &
              " expected " & to_string(xpkt.data(i)) &
              " received " & to_string(rpkt.data(i))
              severity note;
          end if;
        end loop;
        report "received packet: data error" severity failure;
      end if;
      -- check FCS
      rfcs :=
        rpkt.data(rpkt.size-4)(7 downto 0) &
        rpkt.data(rpkt.size-3)(7 downto 0) &
        rpkt.data(rpkt.size-2)(7 downto 0) &
        rpkt.data(rpkt.size-1)(7 downto 0);
      crc := (others => '1');
      for i in 0 to rpkt.size-5 loop
        crc := crc32_eth_8(rev(rpkt.data(i)(7 downto 0)),crc);
      end loop;
      xfcs := not(rev(crc));
      xfcs := xfcs(7 downto 0) & xfcs(15 downto 8) & xfcs(23 downto 16) & xfcs(31 downto 24);
      sim_crc  <= crc;
      sim_rfcs <= rfcs;
      sim_xfcs <= xfcs;
      wait for 0 ps;
      assert xfcs = rfcs
        report "received packet: FCS error - expected " & to_hstring(xfcs) &
          " received " & to_hstring(rfcs)
        severity failure;
      rpkt.size := rpkt.size - 4;
      -- finish
      expected.deq;
      rpkt.size := 0;
      rpkt.data := (others => (others => 'X'));
      pcount := pcount + 1;
    end loop;
    report "*** SUCCESS *** " & integer'image(pcount) & " packets received" severity note;
    std.env.finish;
  end process P_RX;

  --------------------------------------------------------------------------------
  -- DUT instantiation

  DUT: component memac_tx_fe
    port map (
      rst     => rst,
      clk     => clk,
      clken   => clken,
      umii_dv => umii_dv,
      umii_er => umii_er,
      umii_d  => umii_d,
      prq_rdy => prq_rdy,
      prq_len => prq_len,
      prq_idx => prq_idx,
      prq_tag => prq_tag,
      prq_opt => prq_opt,
      prq_stb => prq_stb,
      pfq_rdy => pfq_rdy,
      pfq_len => pfq_len,
      pfq_idx => pfq_idx,
      pfq_tag => pfq_tag,
      pfq_stb => pfq_stb,
      buf_re  => buf_re,
      buf_idx => buf_rptr,
      buf_d   => buf_d,
      buf_er  => buf_er
    );

  --------------------------------------------------------------------------------
  -- simulation waveform signals

  P_SIM: process(clk)
  begin
    if falling_edge(clk) then
      sim_prq_items <= prq.items;
      sim_pfq_items <= pfq.items;
      sim_buf_space <= buf_space.get;
    end if;
  end process P_SIM;

  --------------------------------------------------------------------------------

end architecture sim;
