--------------------------------------------------------------------------------
-- tb_memac_fe.vhd                                                            --
-- Testbench for memac_tx_fe and memac_rx_fe.                                 --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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
-- TODO: verify manual FCS
--------------------------------------------------------------------------------
-- definitions required for generic package instances

use work.memac_util_pkg.all;
use work.memac_tx_fe_pkg.all;
use work.memac_rx_fe_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_fe_pkg is

  constant MTU       : positive := 1522;
  constant BUF_SIZE  : positive := 8 * kByte;
  constant TAG_WIDTH : positive := 2;

  --------------------------------------------------------------------------------
  -- packet descriptor queues

  -- TX packet reservation
  type tx_prd_t is record
    len : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    tag : std_ulogic_vector(TAG_WIDTH-1 downto 0);
    opt : memac_tx_opt_t;
  end record tx_prd_t;
  constant TX_PRQ_EMPTY : tx_prd_t := (
    len  => (log2(MTU)-1 downto 0 => 'X'),
    idx  => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    tag  => (TAG_WIDTH-1 downto 0 => 'X'),
    opt => (pre_len => x"8",pre_auto => 'X',fcs_auto => 'X')
  );

  -- TX packet free
  type tx_pfd_t is record
    len : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    tag : std_ulogic_vector(TAG_WIDTH-1 downto 0);
  end record tx_pfd_t;
  constant TX_PFQ_EMPTY : tx_pfd_t := (
    len => (log2(MTU)-1 downto 0 => 'X'),
    idx => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    tag => (TAG_WIDTH-1 downto 0 => 'X')
  );

  -- RX packet reservation
  type rx_prd_t is record
    len  : std_ulogic_vector(log2(MTU)-1 downto 0);
    idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
    flag : memac_rx_flag_t;
  end record rx_prd_t;
  constant RX_PRQ_EMPTY : rx_prd_t := (
    len  => (log2(MTU)-1 downto 0 => 'X'),
    idx  => (log2(BUF_SIZE)-1 downto 0 => 'X'),
    flag => (others => 'X')
  );

  -- RX packet free
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

end package tb_memac_fe_pkg;

--------------------------------------------------------------------------------
-- generic package instances

use work.tb_memac_fe_pkg.all;
package tx_prq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => tx_prd_t,EMPTY => TX_PRQ_EMPTY);

use work.tb_memac_fe_pkg.all;
package tx_pfq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => tx_pfd_t,EMPTY => TX_PFQ_EMPTY);

use work.tb_memac_fe_pkg.all;
package rx_prq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => rx_prd_t,EMPTY => RX_PRQ_EMPTY);

use work.tb_memac_fe_pkg.all;
package rx_pfq_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => rx_pfd_t,EMPTY => RX_PFQ_EMPTY);

use work.tb_memac_fe_pkg.all;
package packet_queue_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => packet_t,EMPTY => PACKET_EMPTY);

--------------------------------------------------------------------------------
-- testbench entity and architecture

use work.memac_util_pkg.all;
use work.memac_tx_fe_pkg.all;
use work.memac_rx_fe_pkg.all;
use work.tb_memac_fe_pkg.all;
use work.tx_prq_pkg.all;
use work.tx_pfq_pkg.all;
use work.rx_prq_pkg.all;
use work.rx_pfq_pkg.all;
use work.packet_queue_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_memac_fe is
  generic (
    PACKET_COUNT : positive
  );
end entity tb_memac_fe;

architecture sim of tb_memac_fe is

  --------------------------------------------------------------------------------

  constant CLK_PERIOD : time    :=  8 ns;
  constant PDQ_LEN    : integer := 32;

  --------------------------------------------------------------------------------
  -- signals

  signal rst         : std_ulogic;
  signal clk         : std_ulogic;

  -- TX DUT
  signal tx_prq_rdy  : std_ulogic;
  signal tx_prq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal tx_prq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal tx_prq_tag  : std_ulogic_vector(1 downto 0);
  signal tx_prq_opt  : memac_tx_opt_t := MEMAC_TX_OPT_DEFAULT;
  signal tx_prq_stb  : std_ulogic;
  signal tx_pfq_rdy  : std_ulogic;
  signal tx_pfq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal tx_pfq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal tx_pfq_tag  : std_ulogic_vector(1 downto 0);
  signal tx_pfq_stb  : std_ulogic;
  signal tx_buf_re   : std_ulogic;
  signal tx_buf_rptr : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal tx_buf_data : std_ulogic_vector(7 downto 0);
  signal tx_buf_er   : std_ulogic;

  -- TX packet generator
  signal tx_buf_wptr : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);

  -- RX DUT
  signal rx_opt      : memac_rx_opt_t;
  signal rx_drops    : std_ulogic_vector(31 downto 0);
  signal rx_prq_rdy  : std_ulogic;
  signal rx_prq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal rx_prq_idx  : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal rx_prq_flag : memac_rx_flag_t;
  signal rx_prq_stb  : std_ulogic;
  signal rx_pfq_rdy  : std_ulogic;
  signal rx_pfq_len  : std_ulogic_vector(log2(MTU)-1 downto 0);
  signal rx_pfq_stb  : std_ulogic;
  signal rx_buf_we   : std_ulogic;
  signal rx_buf_wptr : std_ulogic_vector(log2(BUF_SIZE)-1 downto 0);
  signal rx_buf_data : std_ulogic_vector(7 downto 0);
  signal rx_buf_er   : std_ulogic;

  -- PHY
  signal phy_dv      : std_ulogic;
  signal phy_er      : std_ulogic;
  signal phy_data    : std_ulogic_vector(7 downto 0);

  -- simulation only: signals to allow shared variables to be added to waveform
  signal sim_tx_prq_items : integer; -- v4p ignore w-303
  signal sim_tx_pfq_items : integer; -- v4p ignore w-303
  signal sim_tx_buf_space : integer; -- v4p ignore w-303
  signal sim_rx_prq_items : integer; -- v4p ignore w-303

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

  shared variable tx_buf, rx_buf : shared_buffer_t;

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

  shared variable tx_buf_space : shared_int_t;

  --------------------------------------------------------------------------------
  -- queues

  shared variable tx_prq   : work.tx_prq_pkg.queue_t;
  shared variable tx_pfq   : work.tx_pfq_pkg.queue_t;
  shared variable rx_prq   : work.rx_prq_pkg.queue_t;
  shared variable rx_pfq   : work.rx_pfq_pkg.queue_t;
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

  P_TX: process(rst,clk)
    variable pkt : packet_t;
    variable prd : tx_prd_t;
  begin
    if rst = '1' then
      tx_buf_wptr <= (others => '0');
      tx_buf_space.set(BUF_SIZE);
    elsif rising_edge(clk) then
      -- wait until there is space in the buffer and the packet reservation queue
      if tx_buf_space.get > 0 and tx_prq.items < PDQ_LEN-1 then
      -- random packet length and contents (length is constrained by available space)
        pkt.size := prng.rand_int(1,minimum(tx_buf_space.get,MTU));
        for i in 0 to pkt.size-1 loop
          pkt.data(i) := prng.rand_slv(0,511,9);
          --pkt.data(i) := std_ulogic_vector(to_unsigned(i mod 512,9));
        end loop;
        -- copy packet into tx buffer
        for i in 0 to pkt.size-1 loop
          tx_buf.set((to_integer(unsigned(tx_buf_wptr))+i) mod BUF_SIZE,pkt.data(i));
        end loop;
        -- enqueue packet descriptor and expected packet
        prd.len := std_ulogic_vector(to_unsigned(pkt.size,tx_prq_len'length));
        prd.idx := tx_buf_wptr;
        prd.tag := "00";
        prd.opt := (pre_len => x"8",pre_auto => '1',fcs_auto => '1');
        tx_prq.enq(prd);
        expected.enq(pkt);
        -- update write pointer and space value
        tx_buf_wptr <= std_ulogic_vector(unsigned(tx_buf_wptr)+pkt.size);
        tx_buf_space.sub(pkt.size);
        -- report
        report "transmitted packet: " & integer'image(pkt.size) & " bytes" severity note;
      end if;
      -- TODO: pace
    end if;
  end process P_TX;

  --------------------------------------------------------------------------------
  -- TX buffer RAM

  P_TX_BUF: process(rst,clk)
  begin
    if rst = '1' then
      tx_buf_data <= (others => 'X');
      tx_buf_er   <= 'X';
    elsif rising_edge(clk) and tx_buf_re = '1' then
      tx_buf_data <= tx_buf.get(to_integer(unsigned(tx_buf_rptr)))(7 downto 0);
      tx_buf_er   <= tx_buf.get(to_integer(unsigned(tx_buf_rptr)))(8);
    end if;
  end process P_TX_BUF;

  --------------------------------------------------------------------------------
  -- TX packet reservation queue
  -- descriptors are...
  --  enqueued in P_TX
  --  dequeued here when tx_prq_stb is asserted

  P_TX_PRQ: process(rst,clk)
  begin
    if rst = '1' then
      tx_prq_rdy <= '0';
      tx_prq_len <= (others => 'X');
      tx_prq_idx <= (others => 'X');
      tx_prq_tag <= (others => 'X');
      tx_prq_opt <= MEMAC_TX_OPT_DEFAULT;
    elsif rising_edge(clk) then
      if tx_prq_stb = '1' then
        tx_prq.deq;
      end if;
      tx_prq_rdy <= '1' when tx_prq.items > 0 else '0';
      tx_prq_len <= tx_prq.front.len;
      tx_prq_idx <= tx_prq.front.idx;
      tx_prq_tag <= tx_prq.front.tag;
      tx_prq_opt <= tx_prq.front.opt;
    end if;
  end process P_TX_PRQ;

  --------------------------------------------------------------------------------
  -- TX packet free queue
  -- descriptors are...
  --  enqueued here when tx_pfq_stb is asserted
  --  dequeued here (eagerly) TODO: pace this?

  P_TX_PFQ: process(rst,clk)
    variable d : tx_pfd_t;
  begin
    if rst = '1' then
      tx_pfq_rdy <= '0';
    elsif rising_edge(clk) then
      tx_pfq_rdy <= '1' when tx_pfq.items < BUF_SIZE-1 else '0';
      if tx_pfq_stb = '1' then
        d.len := tx_pfq_len;
        d.idx := tx_pfq_idx;
        d.tag := tx_pfq_tag;
        tx_pfq.enq(d);
      end if;
      if tx_pfq.items > 0 then
        tx_buf_space.add(to_integer(unsigned(tx_pfq_len)));
        report "tx_pfq.items = " & integer'image(tx_pfq.items);
        tx_pfq.deq;
      end if;
    end if;
  end process P_TX_PFQ;

  --------------------------------------------------------------------------------
  -- receive and check packets

  rx_opt <= (
    ipg_min => 12,
    pre_inc => '0',
    fcs_inc => '0',
    crc_inc => '0'
  );

  P_RX: process(rst,clk)
    variable xpkt  : packet_t;
    variable rpkt  : packet_t;
    variable rdesc : rx_prd_t;
    variable count : integer;
  begin
    if rst = '1' then
      count := 0;
    elsif rising_edge(clk) then
      -- wait for packet
      if rx_prq.items > 0 then
        -- get descriptor, packet and expected packet
        rdesc := rx_prq.front;
        rpkt.size := to_integer(unsigned(rdesc.len));
        for i in 0 to rpkt.size-1 loop
          rpkt.data(i) := rx_buf.get((to_integer(unsigned(rdesc.idx))+i) mod BUF_SIZE);
        end loop;
        xpkt := expected.front;
        -- check packet flags
        assert rdesc.flag.ipg_short = '0' report "received packet: IPG short"                           severity failure;
        assert rdesc.flag.pre_inc   = '0' report "received packet: includes preamble & SFD"             severity failure;
        assert rdesc.flag.pre_short = '0' report "received packet: short preamble (< 8)"                severity failure;
        assert rdesc.flag.pre_long  = '0' report "received packet: long preamble (> 8)"                 severity failure;
        assert rdesc.flag.pre_bad   = '0' report "received packet: bad preamble or SFD"                 severity failure;
--      assert d.flag.data_err  = '0' report "received packet: data errors"                         severity failure;
        assert rdesc.flag.fcs_inc   = '0' report "received packet: includes FCS"                        severity failure;
        assert rdesc.flag.fcs_bad   = '0' report "received packet: FCS is bad"                          severity failure;
        assert rdesc.flag.crc_inc   = '0' report "received packet: includes CRC (over payload and FCS)" severity failure;
        assert rdesc.flag.truncate  = '0' report "received packet: was truncated"                       severity failure;
        -- check packet length
        assert xpkt.size = to_integer(unsigned(rdesc.len))
          report "packet length mismatch: expected " & integer'image(xpkt.size)
            & " but got " & integer'image(rpkt.size)
          severity failure;
        -- check packet contents
        for i in 0 to rpkt.size-1 loop
          --assert rpkt.data(i) = xpkt.data(i)
          if rpkt.data(i) /= xpkt.data(i) then
            report "packet data mismatch at byte 0x" & to_hstring(to_unsigned(i,log2(BUF_SIZE)))
              & ": expected 0x" & to_hstring(xpkt.data(i))
              & " but got 0x" & to_hstring(rpkt.data(i));
            --severity failure;
            for x in 0 to rpkt.size-1 loop
              if xpkt.data(x) /= rpkt.data(x) then
                std.textio.write(std.textio.output, "address " & integer'image(x) & ": expected 0x" & to_hstring(xpkt.data(x)) & " received 0x" & to_hstring(rpkt.data(x)) & LF);
              end if;
            end loop;
            std.env.finish;
          end if;
        end loop;
        -- TODO: check FCS if included
        -- TODO: check CRC if included
        -- enqueue free, dequeue reservation, dequeue expected packet
        rx_pfq.enq((len => rdesc.len));
        rx_prq.deq;
        expected.deq;
        -- report
        report "received packet: " & integer'image(rpkt.size) & " bytes" severity note;
        -- count
        count := count + 1;
        if count >= PACKET_COUNT then
          report integer'image(count) & " packets received" severity note;
          std.env.finish;
        end if;
      end if;
      -- TODO: pace
    end if;
  end process P_RX;

  --------------------------------------------------------------------------------
  -- RX buffer RAM

  P_RX_BUF: process(clk)
  begin
    if rising_edge(clk) and rx_buf_we = '1' then
      rx_buf.set(to_integer(unsigned(rx_buf_wptr)),rx_buf_er & rx_buf_data);
    end if;
  end process P_RX_BUF;

  --------------------------------------------------------------------------------
  -- RX packet reservation queue
  -- descriptors are...
  --  enqueued here when rx_prq_stb is asserted
  --  dequeued in P_RX

  P_RX_PRQ: process(rst,clk)
  begin
    if rst = '1' then
      rx_prq_rdy <= '0';
    elsif rising_edge(clk) then
      rx_prq_rdy <= '1' when rx_prq.items < PDQ_LEN-1;
      if rx_prq_stb = '1' then
        rx_prq.enq((len  => rx_prq_len,idx  => rx_prq_idx,flag => rx_prq_flag));
      end if;
    end if;
  end process P_RX_PRQ;

  --------------------------------------------------------------------------------
  -- RX packet free queue
  -- descriptors are...
  --  enqueued in P_RX
  --  dequeued here when rx_pfq_stb is asserted

  P_RX_PFQ: process(rst,clk)
  begin
    if rst = '1' then
      rx_pfq_rdy <= '0';
      rx_pfq_len <= (others => 'X');
    elsif rising_edge(clk) then
      if rx_pfq_stb = '1' then
        rx_pfq.deq;
      end if;
      rx_pfq_rdy <= '0' when rx_pfq.items = 0 or (rx_pfq.items = 1 and rx_pfq_stb = '1') else '1';
      rx_pfq_len <= rx_pfq.front.len;
    end if;
  end process P_RX_PFQ;

  --------------------------------------------------------------------------------
  -- DUT instantiation

  U_TX: component memac_tx_fe
    port map (
      rst      => rst,
      clk      => clk,
      prq_rdy  => tx_prq_rdy,
      prq_len  => tx_prq_len,
      prq_idx  => tx_prq_idx,
      prq_tag  => tx_prq_tag,
      prq_opt  => tx_prq_opt,
      prq_stb  => tx_prq_stb,
      pfq_rdy  => tx_pfq_rdy,
      pfq_len  => tx_pfq_len,
      pfq_idx  => tx_pfq_idx,
      pfq_tag  => tx_pfq_tag,
      pfq_stb  => tx_pfq_stb,
      buf_re   => tx_buf_re,
      buf_idx  => tx_buf_rptr,
      buf_data => tx_buf_data,
      buf_er   => tx_buf_er,
      phy_dv   => phy_dv,
      phy_er   => phy_er,
      phy_data => phy_data
    );

  U_RX: component memac_rx_fe
    port map (
      rst      => rst,
      clk      => clk,
      opt      => rx_opt,
      drops    => rx_drops,
      prq_rdy  => rx_prq_rdy,
      prq_len  => rx_prq_len,
      prq_idx  => rx_prq_idx,
      prq_flag => rx_prq_flag,
      prq_stb  => rx_prq_stb,
      pfq_rdy  => rx_pfq_rdy,
      pfq_len  => rx_pfq_len,
      pfq_stb  => rx_pfq_stb,
      buf_we   => rx_buf_we,
      buf_idx  => rx_buf_wptr,
      buf_data => rx_buf_data,
      buf_er   => rx_buf_er,
      phy_dv   => phy_dv,
      phy_er   => phy_er,
      phy_data => phy_data
    );

  --------------------------------------------------------------------------------
  -- simulation waveform signals

  P_SIM: process(clk)
  begin
    if falling_edge(clk) then
      sim_tx_prq_items <= tx_prq.items;
      sim_tx_pfq_items <= tx_pfq.items;
      sim_tx_buf_space <= tx_buf_space.get;
      sim_rx_prq_items <= rx_prq.items;
    end if;
  end process P_SIM;

  --------------------------------------------------------------------------------

end architecture sim;
