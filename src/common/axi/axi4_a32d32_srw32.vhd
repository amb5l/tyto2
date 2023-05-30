--------------------------------------------------------------------------------
-- axi4_a32d32_srw32.vhd                                                      --
-- AXI4 (32 bit address & data) to simple read and write (32 bit) bridge.     --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or(at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi4_pkg.all;

package axi4_a32d32_srw32_pkg is

  component axi4_a32d32_srw32 is
    generic (
      addr_width : integer;
      qwa_depth  : integer := 16;
      qwd_depth  : integer := 16;
      qwb_depth  : integer := 16;
      qra_depth  : integer := 16;
      qrd_depth  : integer := 16
    );
    port (

      clk     : in    std_logic;
      rst_n   : in    std_logic;

      axi4_si : in    axi4_a32d32_h_mosi_t := AXI4_A32D32_H_MOSI_DEFAULT;
      axi4_so : out   axi4_a32d32_h_miso_t := AXI4_A32D32_H_MISO_DEFAULT;

      sw_en   : out   std_logic;
      sw_addr : out   std_logic_vector(addr_width-1 downto 0);
      sw_be   : out   std_logic_vector(3 downto 0);
      sw_data : out   std_logic_vector(31 downto 0);
      sw_rdy  : in    std_logic;

      sr_en   : out   std_logic;
      sr_addr : out   std_logic_vector(addr_width-1 downto 0);
      sr_data : in    std_logic_vector(31 downto 0);
      sr_rdy  : in    std_logic

    );
  end component axi4_a32d32_srw32;

end package axi4_a32d32_srw32_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.fifo_pkg.all;
  use work.axi4_pkg.all;

entity axi4_a32d32_srw32 is
  generic (
    addr_width : integer;
    qwa_depth  : integer := 16;
    qwd_depth  : integer := 16;
    qwb_depth  : integer := 16;
    qra_depth  : integer := 16;
    qrd_depth  : integer := 16
  );
  port (

    clk     : in    std_logic;                                          -- clock
    rst_n   : in    std_logic;                                          -- reset (active low

    axi4_si : in    axi4_a32d32_h_mosi_t := AXI4_A32D32_H_MOSI_DEFAULT; -- AXI4 slave inputs
    axi4_so : out   axi4_a32d32_h_miso_t := AXI4_A32D32_H_MISO_DEFAULT; -- AXI4 slave output

    sw_en   : out   std_logic;                                          -- simple write enable
    sw_addr : out   std_logic_vector(addr_width-1 downto 0);            -- simple write address
    sw_be   : out   std_logic_vector(3 downto 0);                       -- simple write byte enables
    sw_data : out   std_logic_vector(31 downto 0);                      -- simple write data
    sw_rdy  : in    std_logic;                                          -- simple write ready

    sr_en   : out   std_logic;                                          -- simple read enable
    sr_addr : out   std_logic_vector(addr_width-1 downto 0);            -- simple read address
    sr_data : in    std_logic_vector(31 downto 0);                      -- simple read data
    sr_rdy  : in    std_logic                                           -- simple read ready

  );
end entity axi4_a32d32_srw32;

architecture synth of axi4_a32d32_srw32 is

  -- optional AXI4 inputs that are ignored:
  -- awregion, awcache, awprot, awqos, arregion, arcache, arprot, arqos

  -- aliases to tidy code
  alias awid    is axi4_si.aw.id;
  alias awaddr  is axi4_si.aw.addr;
  alias awlen   is axi4_si.aw.len;
  alias awsize  is axi4_si.aw.size;
  alias awburst is axi4_si.aw.burst;
  alias awqos   is axi4_si.aw.qos;
  alias awvalid is axi4_si.aw.valid;
  alias awready is axi4_so.aw.ready;
  alias wdata   is axi4_si.w.data;
  alias wstrb   is axi4_si.w.strb;
  alias wlast   is axi4_si.w.last;
  alias wvalid  is axi4_si.w.valid;
  alias wready  is axi4_so.w.ready;
  alias bid     is axi4_so.b.id;
  alias bresp   is axi4_so.b.resp;
  alias bvalid  is axi4_so.b.valid;
  alias bready  is axi4_si.b.ready;
  alias arid    is axi4_si.ar.id;
  alias araddr  is axi4_si.ar.addr;
  alias arlen   is axi4_si.ar.len;
  alias arsize  is axi4_si.ar.size;
  alias arburst is axi4_si.ar.burst;
  alias arvalid is axi4_si.ar.valid;
  alias arready is axi4_so.ar.ready;
  alias rid     is axi4_so.r.id;
  alias rdata   is axi4_so.r.data;
  alias rresp   is axi4_so.r.resp;
  alias rlast   is axi4_so.r.last;
  alias rvalid  is axi4_so.r.valid;
  alias rready  is axi4_si.r.ready;

  -- write related
  signal wa_available   : std_logic;
  signal wd_available   : std_logic;
  signal sw_beat_end    : std_logic;
  signal sw_burst_end   : std_logic;
  signal sw_beat_ready  : std_logic;
  signal sw_burst_ready : std_logic;
  signal sw_busy        : std_logic;
  signal sw_len         : std_logic_vector(7 downto 0);
  signal sw_size        : std_logic_vector(2 downto 0);
  signal sw_burst       : std_logic_vector(1 downto 0);
  signal sw_last        : std_logic;

  -- read related
  signal ra_available   : std_logic;
  signal rd_available   : std_logic;
  signal sr_beat_end    : std_logic;
  signal sr_burst_end   : std_logic;
  signal sr_beat_ready  : std_logic;
  signal sr_burst_ready : std_logic;
  signal sr_count       : std_logic_vector(7 downto 0);
  signal sr_id          : std_logic_vector(7 downto 0);
  signal sr_busy        : std_logic;
  signal sr_len         : std_logic_vector(7 downto 0);
  signal sr_size        : std_logic_vector(2 downto 0);
  signal sr_burst       : std_logic_vector(1 downto 0);
  signal sr_last        : std_logic;

  -- queue: write address
  type qwa_entry_t is record
    addr  : std_logic_vector(addr_width-1 downto 0);
    len   : std_logic_vector(7 downto 0);
    size  : std_logic_vector(2 downto 0);
    burst : std_logic_vector(1 downto 0);
  end record;
  constant qwa_width : integer := addr_width+8+3+2;
  signal qwa_tail : qwa_entry_t;
  signal qwa_head : qwa_entry_t;
  signal qwa_enq  : std_logic;
  signal qwa_deq  : std_logic;
  signal qwa_d    : std_logic_vector(qwa_width-1 downto 0);
  signal qwa_q    : std_logic_vector(qwa_width-1 downto 0);
  signal qwa_ef   : std_logic;
  signal qwa_aff  : std_logic;
  function to_slv( i : qwa_entry_t ) return std_logic_vector is
  begin
    return i.burst & i.size & i.len & i.addr;
  end function to_slv;
  function from_slv( i : std_logic_vector ) return qwa_entry_t is
    variable r : qwa_entry_t;
  begin
    r.addr  := i(addr_width-1 downto 0);
    r.len   := i(addr_width+7 downto addr_width);
    r.size  := i(addr_width+10 downto addr_width+8);
    r.burst := i(addr_width+12 downto addr_width+11);
    return r;
  end function from_slv;

  -- queue: write data
  type qwd_entry_t is record
    data : std_logic_vector(31 downto 0);
    strb : std_logic_vector(3 downto 0);
    last : std_logic;
  end record;
  constant qwd_width : integer := 32+4+1;
  signal qwd_tail : qwd_entry_t;
  signal qwd_head : qwd_entry_t;
  signal qwd_enq  : std_logic;
  signal qwd_deq  : std_logic;
  signal qwd_d    : std_logic_vector(qwd_width-1 downto 0);
  signal qwd_q    : std_logic_vector(qwd_width-1 downto 0);
  signal qwd_ef   : std_logic;
  signal qwd_aff  : std_logic;
  function to_slv( i : qwd_entry_t ) return std_logic_vector is
  begin
    return i.last & i.strb & i.data;
  end function to_slv;
  function from_slv( i : std_logic_vector ) return qwd_entry_t is
    variable r : qwd_entry_t;
  begin
    r.data := i(31 downto 0);
    r.strb := i(35 downto 32);
    r.last := i(36);
    return r;
  end function from_slv;

  -- queues: writes pending and writes completed
  type qwb_entry_t is record
    id : std_logic_vector(7 downto 0);
  end record;
  constant qwb_width : integer := 8;
  signal qwp_tail : qwb_entry_t;
  signal qwp_head : qwb_entry_t;
  signal qwp_enq  : std_logic;
  signal qwp_deq  : std_logic;
  signal qwp_d    : std_logic_vector(qwb_width-1 downto 0);
  signal qwp_q    : std_logic_vector(qwb_width-1 downto 0);
  signal qwp_aff  : std_logic;
  signal qwc_tail : qwb_entry_t;
  signal qwc_head : qwb_entry_t;
  signal qwc_enq  : std_logic;
  signal qwc_deq  : std_logic;
  signal qwc_d    : std_logic_vector(qwb_width-1 downto 0);
  signal qwc_q    : std_logic_vector(qwb_width-1 downto 0);
  signal qwc_ef   : std_logic;
  function to_slv( i : qwb_entry_t ) return std_logic_vector is
  begin
    return i.id;
  end function to_slv;
  function from_slv( i : std_logic_vector ) return qwb_entry_t is
    variable r : qwb_entry_t;
  begin
    r.id := i(7 downto 0);
    return r;
  end function from_slv;

  -- queue: read address
  type qra_entry_t is record
    addr  : std_logic_vector(addr_width-1 downto 0);
    id    : std_logic_vector(7 downto 0);
    len   : std_logic_vector(7 downto 0);
    size  : std_logic_vector(2 downto 0);
    burst : std_logic_vector(1 downto 0);
  end record;
  constant qra_width : integer := addr_width+8+8+3+2;
  signal qra_tail : qra_entry_t;
  signal qra_head : qra_entry_t;
  signal qra_enq  : std_logic;
  signal qra_deq  : std_logic;
  signal qra_d    : std_logic_vector(qra_width-1 downto 0);
  signal qra_q    : std_logic_vector(qra_width-1 downto 0);
  signal qra_ef   : std_logic;
  signal qra_aff  : std_logic;
  function to_slv( i : qra_entry_t ) return std_logic_vector is
  begin
    return i.burst & i.size & i.len & i.id & i.addr;
  end function to_slv;
  function from_slv( i : std_logic_vector ) return qra_entry_t is
    variable r : qra_entry_t;
  begin
    r.addr  := i(addr_width-1 downto 0);
    r.id    := i(addr_width+7 downto addr_width);
    r.len   := i(addr_width+15 downto addr_width+8);
    r.size  := i(addr_width+18 downto addr_width+16);
    r.burst := i(addr_width+20 downto addr_width+19);
    return r;
  end function from_slv;

  -- queue: read data
  type qrd_entry_t is record
    data : std_logic_vector(31 downto 0);
    id   : std_logic_vector(7 downto 0);
    last : std_logic;
  end record;
  constant qrd_width : integer := 32+8+1;
  signal qrd_tail : qrd_entry_t;
  signal qrd_head : qrd_entry_t;
  signal qrd_enq  : std_logic;
  signal qrd_deq  : std_logic;
  signal qrd_d    : std_logic_vector(qrd_width-1 downto 0);
  signal qrd_q    : std_logic_vector(qrd_width-1 downto 0);
  signal qrd_ef   : std_logic;
  signal qrd_ff   : std_logic;
  function to_slv( i : qrd_entry_t ) return std_logic_vector is
  begin
    return i.last & i.id & i.data;
  end function to_slv;
  function from_slv( i : std_logic_vector ) return qrd_entry_t is
    variable r : qrd_entry_t;
  begin
    r.data := i(31 downto 0);
    r.id   := i(39 downto 32);
    r.last := i(40);
    return r;
  end function from_slv;

  -- simulation/debug
  signal sim_axi4 : axi4_a32d32_t;

begin

  --------------------------------------------------------------------------------

  sim_axi4       <= axi4_a32d32_hs2f(axi4_si,axi4_so);

  bresp          <= (others => '0'); -- } response is always OK
  rresp          <= (others => '0'); -- }

  wa_available   <= (awvalid and awready) or not qwa_ef;
  wd_available   <= (wvalid and wready) or not qwd_ef;

  sw_beat_end    <= sw_en and sw_rdy;
  sw_burst_end   <= sw_en and sw_rdy and sw_last;
  sw_beat_ready  <= sw_beat_end or not sw_busy;
  sw_burst_ready <= sw_burst_end or not sw_busy;

  ra_available   <= (arvalid and arready) or not qra_ef;
  rd_available   <= (rvalid and rready) or not qrd_ef;

  sr_beat_end    <= sr_en and sr_rdy;
  sr_burst_end   <= sr_en and sr_rdy and sr_last;
  sr_beat_ready  <= sr_beat_end or not sr_busy;
  sr_burst_ready <= sr_burst_end or not sr_busy;

  --------------------------------------------------------------------------------
  -- QWA

  qwa_enq        <= awvalid and awready;
  qwa_deq        <= sw_burst_ready and wa_available and wd_available;
  qwa_tail.addr  <= awaddr(addr_width-1 downto 0);
  qwa_tail.len   <= awlen;
  qwa_tail.size  <= awsize;
  qwa_tail.burst <= awburst;
  qwa_d          <= to_slv(qwa_tail);
  qwa_head       <= from_slv(qwa_q);

  QWA: component fifo_sft
    generic map (
      width   => qwa_width,
      depth   => qwa_depth,
      aef_lvl => 1,
      aff_lvl => 1,
      en_cut  => true
    )
    port map (
      rst  => not rst_n,
      clk  => clk,
      ld   => qwa_enq,
      unld => qwa_deq,
      d    => qwa_d,
      q    => qwa_q,
      ef   => qwa_ef,
      aef  => open,
      aff  => qwa_aff,
      ff   => open,
      err  => open
    );

  --------------------------------------------------------------------------------
  -- QWD

  qwd_enq       <= wvalid and wready;
  qwd_deq       <= sw_beat_ready and wd_available;
  qwd_tail.data <= wdata;
  qwd_tail.strb <= wstrb;
  qwd_tail.last <= wlast;
  qwd_d         <= to_slv(qwd_tail);
  qwd_head      <= from_slv(qwd_q);

  QWD: component fifo_sft
    generic map (
      width   => qwd_width,
      depth   => qwd_depth,
      aef_lvl => 1,
      aff_lvl => 1,
      en_cut  => true
    )
    port map (
      rst  => not rst_n,
      clk  => clk,
      ld   => qwd_enq,
      unld => qwd_deq,
      d    => qwd_d,
      q    => qwd_q,
      ef   => qwd_ef,
      aef  => open,
      aff  => qwd_aff,
      ff   => open,
      err  => open
    );

  --------------------------------------------------------------------------------
  -- QWP

  qwp_enq     <= qwa_enq;
  qwp_deq     <= sw_burst_end;
  qwp_tail.id <= awid;
  qwp_d       <= to_slv(qwp_tail);
  qwp_head    <= from_slv(qwp_q);

  QWP: component fifo_sft
    generic map (
      width   => qwb_width,
      depth   => qwb_depth,
      aef_lvl => 1,
      aff_lvl => 1,
      en_cut  => true
    )
    port map (
      rst  => not rst_n,
      clk  => clk,
      ld   => qwp_enq,
      unld => qwp_deq,
      d    => qwp_d,
      q    => qwp_q,
      ef   => open,
      aef  => open,
      aff  => qwp_aff,
      ff   => open,
      err  => open
    );

  --------------------------------------------------------------------------------
  -- QWC

  qwc_enq     <= sw_burst_end;
  qwc_deq     <= (qwc_enq or not qwc_ef) and (bready or not bvalid);
  qwc_tail    <= qwp_head;
  qwc_d       <= to_slv(qwc_tail);
  qwc_head    <= from_slv(qwc_q);

  QWC: component fifo_sft
    generic map (
      width   => qwb_width,
      depth   => qwb_depth,
      aef_lvl => 1,
      aff_lvl => 1,
      en_cut  => true
    )
    port map (
      rst  => not rst_n,
      clk  => clk,
      ld   => qwc_enq,
      unld => qwc_deq,
      d    => qwc_d,
      q    => qwc_q,
      ef   => qwc_ef,
      aef  => open,
      aff  => open,
      ff   => open,
      err  => open
    );

  --------------------------------------------------------------------------------
  -- QRA

  qra_enq        <= arvalid and arready;
  qra_deq        <= sr_burst_ready and ra_available and not qrd_ff;
  qra_tail.addr  <= araddr(addr_width-1 downto 0);
  qra_tail.id    <= arid;
  qra_tail.len   <= arlen;
  qra_tail.size  <= arsize;
  qra_tail.burst <= arburst;
  qra_d          <= to_slv(qra_tail);
  qra_head       <= from_slv(qra_q);

  QRA: component fifo_sft
    generic map (
      width   => qra_width,
      depth   => qra_depth,
      aef_lvl => 1,
      aff_lvl => 1,
      en_cut  => true
    )
    port map (
      rst  => not rst_n,
      clk  => clk,
      ld   => qra_enq,
      unld => qra_deq,
      d    => qra_d,
      q    => qra_q,
      ef   => qra_ef,
      aef  => open,
      aff  => qra_aff,
      ff   => open,
      err  => open
    );

  --------------------------------------------------------------------------------
  -- QRD

  qrd_enq       <= sr_en and sr_rdy;
  qrd_deq       <= (qrd_enq or not qrd_ef) and (rready or not rvalid);
  qrd_tail.data <= sr_data;
  qrd_tail.id   <= sr_id;
  qrd_tail.last <= sr_last;
  qrd_d         <= to_slv(qrd_tail);
  qrd_head      <= from_slv(qrd_q);

  QRD: component fifo_sft
    generic map (
      width   => qrd_width,
      depth   => qrd_depth,
      aef_lvl => 1,
      aff_lvl => 1,
      en_cut  => true
    )
    port map (
      rst  => not rst_n,
      clk  => clk,
      ld   => qrd_enq,
      unld => qrd_deq,
      d    => qrd_d,
      q    => qrd_q,
      ef   => qrd_ef,
      aef  => open,
      aff  => open,
      ff   => qrd_ff,
      err  => open
    );

  --------------------------------------------------------------------------------

  process(rst_n,clk)
    variable v_sw_addr_next : std_logic_vector(sw_addr'range);
    variable v_sr_addr_next : std_logic_vector(sr_addr'range);
  begin
    if rst_n = '0' then

      --------------------------------------------------------------------------------
      -- reset

      -- SW interface
      sw_en    <= '0';
      sw_addr  <= (others => '0');
      sw_be    <= (others => '0');
      sw_data  <= (others => '0');
      sw_busy  <= '0';
      sw_len   <= (others => '0');
      sw_size  <= (others => '0');
      sw_burst <= (others => '0');
      sw_last  <= '0';

      -- SR interface
      sr_en    <= '0';
      sr_addr  <= (others => '0');
      sr_busy  <= '0';
      sr_id    <= (others => '0');
      sr_len   <= (others => '0');
      sr_size  <= (others => '0');
      sr_burst <= (others => '0');
      sr_last  <= '0';

      -- AXI interface
      awready  <= '0';
      wready   <= '0';
      bid      <= (others => '0');
      bvalid   <= '0';
      arready  <= '0';
      rid      <= (others => '0');
      rdata    <= (others => '0');
      rlast    <= '0';
      rvalid   <= '0';

      --------------------------------------------------------------------------------

    elsif rising_edge(clk) then

      --------------------------------------------------------------------------------
      -- write

      if sw_burst = "01" or sw_burst = "10" then -- incrementing or wrapping burst
        if sw_size = "000" then -- burst of bytes
          v_sw_addr_next := std_logic_vector(unsigned(sw_addr)+1);
        elsif sw_size = "001" then -- burst of 16 bit words
          v_sw_addr_next := std_logic_vector(unsigned(sw_addr)+2);
        elsif sw_size = "010" then -- burst of 32 bit words
          v_sw_addr_next := std_logic_vector(unsigned(sw_addr)+4);
        end if;
      end if;
      if sw_burst = "10" then -- wrapping burst
        case sw_len(3 downto 0) is
          when x"1" => -- burst of 2
            if addr_width >= 3 then
              v_sw_addr_next(addr_width-1 downto 3) := sw_addr(addr_width-1 downto 3);
            end if;
          when x"3" => -- burst of 4
            if addr_width >= 4 then
              v_sw_addr_next(addr_width-1 downto 4) := sw_addr(addr_width-1 downto 4);
            end if;
          when x"7" => -- burst of 8
            if addr_width >= 5 then
              v_sw_addr_next(addr_width-1 downto 5) := sw_addr(addr_width-1 downto 5);
            end if;
          when x"F" => -- burst of 16
            if addr_width >= 6 then
              v_sw_addr_next(addr_width-1 downto 6) := sw_addr(addr_width-1 downto 6);
            end if;
          when others =>
            null;
        end case;
      end if;

      -- SW: per burst
      sw_busy  <= '1'            when qwa_deq = '1' else '0'             when sw_burst_end = '1';
      sw_len   <= qwa_head.len   when qwa_deq = '1' else (others => '0') when sw_burst_end = '1';
      sw_size  <= qwa_head.size  when qwa_deq = '1' else (others => '0') when sw_burst_end = '1';
      sw_burst <= qwa_head.burst when qwa_deq = '1' else (others => '0') when sw_burst_end = '1';

      -- SW: per burst and per beat
      sw_addr  <= qwa_head.addr  when qwa_deq = '1' else v_sw_addr_next when qwd_deq = '1' else (others => '0') when sw_burst_end = '1';

      -- SW: per beat
      sw_en    <= '1'            when qwd_deq = '1' else '0'             when sw_beat_end = '1';
      sw_be    <= qwd_head.strb  when qwd_deq = '1' else (others => '0') when sw_beat_end = '1';
      sw_data  <= qwd_head.data  when qwd_deq = '1' else (others => '0') when sw_beat_end = '1';
      sw_last  <= qwd_head.last  when qwd_deq = '1' else '0'             when sw_beat_end = '1';

      -- AXI outputs
      awready  <= '0' when (qwa_aff = '1' and qwa_deq = '0') or (qwp_aff = '1' and qwp_deq = '0') else '1';
      wready   <= not qwd_aff;
      bid      <= qwc_head.id when qwc_deq = '1' else (others => '0') when bready = '1';
      bvalid   <= '1' when qwc_deq = '1' else '0' when bready = '1';

      --------------------------------------------------------------------------------
      -- read

      if sr_burst = "01" or sr_burst = "10" then -- incrementing or wrapping burst
        if sr_size = "000" then -- burst of bytes
          v_sr_addr_next := std_logic_vector(unsigned(sr_addr)+1);
        elsif sr_size = "001" then -- burst of 16 bit words
          v_sr_addr_next := std_logic_vector(unsigned(sr_addr)+2);
        elsif sr_size = "010" then -- burst of 32 bit words
          v_sr_addr_next := std_logic_vector(unsigned(sr_addr)+4);
        end if;
      end if;
      if sr_burst = "10" then -- wrapping burst
        case sr_len(3 downto 0) is
          when x"1" => -- burst of 2
            if addr_width >= 3 then
              v_sr_addr_next(addr_width-1 downto 3) := sr_addr(addr_width-1 downto 3);
            end if;
          when x"3" => -- burst of 4
            if addr_width >= 4 then
              v_sr_addr_next(addr_width-1 downto 4) := sr_addr(addr_width-1 downto 4);
            end if;
          when x"7" => -- burst of 8
            if addr_width >= 5 then
              v_sr_addr_next(addr_width-1 downto 5) := sr_addr(addr_width-1 downto 5);
            end if;
          when x"F" => -- burst of 16
            if addr_width >= 6 then
              v_sr_addr_next(addr_width-1 downto 6) := sr_addr(addr_width-1 downto 6);
            end if;
          when others =>
            null;
        end case;
      end if;

      -- SR: per burst
      sr_busy  <= '1'            when qra_deq = '1' else '0'             when sr_burst_end = '1';
      sr_id    <= qra_head.id    when qra_deq = '1' else (others => '0') when sr_burst_end = '1';
      sr_len   <= qra_head.len   when qra_deq = '1' else (others => '0') when sr_burst_end = '1';
      sr_size  <= qra_head.size  when qra_deq = '1' else (others => '0') when sr_burst_end = '1';
      sr_burst <= qra_head.burst when qra_deq = '1' else (others => '0') when sr_burst_end = '1';

      -- SR: per burst and per beat
      if qra_deq then -- new burst
        sr_count <= (others => '0');
        sr_addr  <= qra_head.addr;
        sr_last  <= '1' when qra_head.len = x"00" else '0';
      elsif sr_beat_ready then -- new beat
        sr_count <= std_logic_vector(unsigned(sr_count)+1);
        sr_addr  <= v_sr_addr_next;
        sr_last  <= '1' when std_logic_vector(unsigned(sr_count)+1) = sr_len else '0';
      elsif sr_burst_end then -- end of burst
        sr_count <= (others => '0');
        sr_addr  <= (others => '0');
        sr_last  <= '0';
      end if;

      -- SR: per beat
      sr_en    <= '1' when qra_deq = '1' or (sr_busy = '1' and rd_available = '1') else '0' when sr_beat_end = '1';

      -- AXI outputs
      arready  <= '0' when qra_aff = '1' and qra_deq = '0' else '1';
      rid      <= qrd_head.id   when qrd_deq = '1' else (others => '0') when rready = '1';
      rdata    <= qrd_head.data when qrd_deq = '1' else (others => '0') when rready = '1';
      rlast    <= qrd_head.last when qrd_deq = '1' else '0'             when rready = '1';
      rvalid   <= '1'           when qrd_deq = '1' else '0'             when rready = '1';

      --------------------------------------------------------------------------------

    end if;
  end process;

end architecture synth;
