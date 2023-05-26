--------------------------------------------------------------------------------
-- axi4_a32d32_srw32.vhd
-- AXI4 (32 bit address, 32 bit data) to simple read and write (32 bit) bridge
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

      clk     : in    std_logic;                                      -- clock
      rst_n   : in    std_logic;                                      -- reset (active low

      axi4_si : in    axi4_a32d32_h_mosi_t := AXI4_A32D32_H_MOSI_DEFAULT; -- AXI4 slave inputs
      axi4_so : out   axi4_a32d32_h_miso_t := AXI4_A32D32_H_MISO_DEFAULT; -- AXI4 slave output

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

    clk     : in    std_logic;                                      -- clock
    rst_n   : in    std_logic;                                      -- reset (active low

    axi4_si : in    axi4_a32d32_h_mosi_t := AXI4_A32D32_H_MOSI_DEFAULT; -- AXI4 slave inputs
    axi4_so : out   axi4_a32d32_h_miso_t := AXI4_A32D32_H_MISO_DEFAULT; -- AXI4 slave output

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
end entity axi4_a32d32_srw32;

architecture synth of axi4_a32d32_srw32 is

  -- optional AXI4 inputs that are ignored:
  -- awregion, awcache, awprot, awqos, arregion, arcache, arprot, arqos

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

  -- queue: write address
  type qwa_entry_t is record
    addr  : std_logic_vector(addr_width-1 downto 0);
    len   : std_logic_vector(7 downto 0);
    size  : std_logic_vector(2 downto 0);
    burst : std_logic_vector(1 downto 0);
  end record;
  constant QWA_INIT : qwa_entry_t := (
      addr  => (others => '0'),
      len   => (others => '0'),
      size  => (others => '0'),
      burst => (others => '0')
    );
  type qwa_t is array(0 to qwa_depth-1) of qwa_entry_t;
  signal qwa      : qwa_t;
  signal qwa_wptr : integer := 0;
  signal qwa_rptr : integer := 0;

  -- queue: write data
  type qwd_entry_t is record
    data : std_logic_vector(31 downto 0);
    strb : std_logic_vector(3 downto 0);
    last : std_logic;
  end record;
  constant QWD_INIT : qwd_entry_t := (
      data => (others => '0'),
      strb => (others => '0'),
      last => '0'
    );
  type qwd_t is array(0 to qwd_depth-1) of qwd_entry_t;
  signal qwd      : qwd_t;
  signal qwd_wptr : integer := 0;
  signal qwd_rptr : integer := 0;

  -- queues: write pending cycles and write completed
  type qwb_entry_t is record
    id : std_logic_vector(7 downto 0);
  end record;
  constant QWB_INIT : qwb_entry_t := (
      id => (others => '0')
    );
  type qwb_t is array(0 to qwb_depth-1) of qwb_entry_t;
  signal qwp      : qwb_t;
  signal qwp_wptr : integer := 0;
  signal qwp_rptr : integer := 0;
  signal qwc      : qwb_t;
  signal qwc_wptr : integer := 0;
  signal qwc_rptr : integer := 0;

  -- queue: read address
  type qra_entry_t is record
    id    : std_logic_vector(7 downto 0);
    addr  : std_logic_vector(addr_width-1 downto 0);
    len   : std_logic_vector(7 downto 0);
    size  : std_logic_vector(2 downto 0);
    burst : std_logic_vector(1 downto 0);
  end record;
  constant QRA_INIT : qra_entry_t := (
      id    => (others => '0'),
      addr  => (others => '0'),
      len   => (others => '0'),
      size  => (others => '0'),
      burst => (others => '0')
    );
  type qra_t is array(0 to qra_depth-1) of qra_entry_t;
  signal qra      : qra_t;
  signal qra_wptr : integer := 0;
  signal qra_rptr : integer := 0;

  -- queue: read data
  type qrd_entry_t is record
    id   : std_logic_vector(7 downto 0);
    data : std_logic_vector(31 downto 0);
    last : std_logic;
  end record;
  constant QRD_INIT : qrd_entry_t := (
      id   => (others => '0'),
      data => (others => '0'),
      last => '0'
    );
  type qrd_t is array(0 to qrd_depth-1) of qrd_entry_t;
  signal qrd      : qrd_t;
  signal qrd_wptr : integer := 0;
  signal qrd_rptr : integer := 0;

  -- SW state
  signal sw_busy  : std_logic;
  signal sw_len   : std_logic_vector(7 downto 0);
  signal sw_size  : std_logic_vector(2 downto 0);
  signal sw_burst : std_logic_vector(1 downto 0);
  signal sw_last  : std_logic;

  -- SR state
  signal sr_count : std_logic_vector(7 downto 0);
  signal sr_id    : std_logic_vector(7 downto 0);
  signal sr_busy  : std_logic;
  signal sr_len   : std_logic_vector(7 downto 0);
  signal sr_size  : std_logic_vector(2 downto 0);
  signal sr_burst : std_logic_vector(1 downto 0);
  signal sr_last  : std_logic;

  -- simulation/debug
  signal sim_axi4 : axi4_a32d32_t;

begin

  sim_axi4 <= axi4_a32d32_hs2f(axi4_si,axi4_so);

  bresp <= (others => '0'); -- } response is always OK
  rresp <= (others => '0'); -- }

  process(rst_n,clk)

      procedure q_status(
                 rptr  : in    integer;
                 wptr  : in    integer;
                 depth : in    integer;
        variable ef    : out   boolean;          -- empty
        variable aff   : out   boolean;          -- almost full (N-2 entries)
        variable ff    : out   boolean           -- full (N-1 entries)
      ) is
      begin
        ef  := rptr = wptr;
        aff := (wptr+2) mod depth = rptr;
        ff  := (wptr+1) mod depth = rptr;
      end procedure q_status;

      procedure q_update(
        signal   rptr  : inout integer;
        signal   wptr  : inout integer;
                 depth : in    integer;
        variable enq   : in    boolean;          -- enqueue
        variable deq   : in    boolean;          -- dequeue
        variable cut   : out   boolean           -- cut through
      ) is
      begin
        cut := enq and deq and rptr = wptr;
        if enq then
          wptr <= (wptr+1) mod depth;
        end if;
        if deq then
          rptr <= (rptr+1) mod depth;
        end if;
      end procedure q_update;

    variable v_qwa_enq        : boolean;     -- enqueue write address
    variable v_qwa_deq        : boolean;     -- dequeue write address
    variable v_qwa_ef         : boolean;     -- QWA is empty
    variable v_qwa_aff        : boolean;     -- QWA is almost full
    variable v_qwa_ff         : boolean;     -- QWA is full
    variable v_qwa_cut        : boolean;     -- cut through write address queue
    variable v_qwa_new        : qwa_entry_t; -- next entry for write address queue
    variable v_qwa_head       : qwa_entry_t; -- head of write address queue

    variable v_qwd_enq        : boolean;     -- enqueue write data
    variable v_qwd_deq        : boolean;     -- dequeue write data
    variable v_qwd_ef         : boolean;     -- QWD is empty
    variable v_qwd_aff        : boolean;     -- QWD is almost full
    variable v_qwd_ff         : boolean;     -- QWD is full
    variable v_qwd_cut        : boolean;     -- cut through write data queue
    variable v_qwd_new        : qwd_entry_t; -- next entry for write data queue
    variable v_qwd_head       : qwd_entry_t; -- head of write data queue

    variable v_qwp_enq        : boolean;     -- enqueue write pending cycle
    variable v_qwp_deq        : boolean;     -- dequeue write pending cycle
    variable v_qwp_ef         : boolean;     -- QWP is empty
    variable v_qwp_aff        : boolean;     -- QWP is almost full
    variable v_qwp_ff         : boolean;     -- QWP is full
    variable v_qwp_cut        : boolean;     -- cut through write pending queue
    variable v_qwp_new        : qwb_entry_t; -- next entry for write pending queue
    variable v_qwp_head       : qwb_entry_t; -- head of write pending queue

    variable v_qwc_enq        : boolean;     -- enqueue write completed cycle
    variable v_qwc_deq        : boolean;     -- dequeue write completed cycle
    variable v_qwc_ef         : boolean;     -- QWC is empty
    variable v_qwc_aff        : boolean;     -- QWC is almost full
    variable v_qwc_ff         : boolean;     -- QWC is full
    variable v_qwc_cut        : boolean;     -- cut through write complete queue
    variable v_qwc_new        : qwb_entry_t; -- next entry for write complete queue
    variable v_qwc_head       : qwb_entry_t; -- head of write complete queue

    variable v_qra_enq        : boolean;     -- enqueue read address
    variable v_qra_deq        : boolean;     -- dequeue read address
    variable v_qra_ef         : boolean;     -- QRA is empty
    variable v_qra_aff        : boolean;     -- QRA is almost full
    variable v_qra_ff         : boolean;     -- QRA is full
    variable v_qra_cut        : boolean;     -- cut through read address queue
    variable v_qra_new        : qra_entry_t; -- next entry for read address queue
    variable v_qra_head       : qra_entry_t; -- head of read address queue

    variable v_qrd_enq        : boolean;     -- enqueue read data
    variable v_qrd_deq        : boolean;     -- dequeue read data
    variable v_qrd_ef         : boolean;     -- QRD is empty
    variable v_qrd_aff        : boolean;     -- QRD is almost full
    variable v_qrd_ff         : boolean;     -- QRD is full
    variable v_qrd_cut        : boolean;     -- cut through read data queue
    variable v_qrd_new        : qrd_entry_t; -- next entry for read data queue
    variable v_qrd_head       : qrd_entry_t; -- head of read data queue

    variable v_wa_available   : boolean;     -- address available for SW cycle
    variable v_wd_available   : boolean;     -- data available for SW cycle
    variable v_ra_available   : boolean;     -- address available for SR cycle
    variable v_rd_available   : boolean;     -- AXI or QRD can accept SR data

    variable v_sw_beat_end    : boolean;     -- SW cycle is at end of data beat
    variable v_sw_beat_ready  : boolean;     -- SW is ready for a new data beat
    variable v_sw_burst_end   : boolean;     -- SW cycle is at end of burst
    variable v_sw_burst_ready : boolean;     -- SW is ready for a new burst
    variable v_sw_addr_next   : std_logic_vector(addr_width-1 downto 0);

    variable v_sr_beat_end    : boolean;     -- SR cycle is at end of data beat
    variable v_sr_beat_ready  : boolean;     -- SR is ready for a new data beat
    variable v_sr_burst_end   : boolean;     -- SR cycle is at end of burst
    variable v_sr_burst_ready : boolean;     -- SR is ready for a new burst
    variable v_sr_addr_next   : std_logic_vector(addr_width-1 downto 0);
    variable v_sr_count_next  : std_logic_vector(7 downto 0);

  begin
    if rst_n = '0' then

      --------------------------------------------------------------------------------
      -- reset

      -- queues
      qwa      <= (others => QWA_INIT);
      qwa_wptr <= 0;
      qwa_rptr <= 0;
      qwd      <= (others => QWD_INIT);
      qwd_wptr <= 0;
      qwd_rptr <= 0;
      qwp      <= (others => QWB_INIT);
      qwp_wptr <= 0;
      qwp_rptr <= 0;
      qwc      <= (others => QWB_INIT);
      qwc_wptr <= 0;
      qwc_rptr <= 0;
      qra      <= (others => QRA_INIT);
      qra_wptr <= 0;
      qra_rptr <= 0;
      qrd      <= (others => QRD_INIT);
      qrd_wptr <= 0;
      qrd_rptr <= 0;

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

      q_status( qwa_rptr, qwa_wptr, qwa_depth, v_qwa_ef, v_qwa_aff, v_qwa_ff );
      q_status( qwd_rptr, qwd_wptr, qwd_depth, v_qwd_ef, v_qwd_aff, v_qwd_ff );
      q_status( qwp_rptr, qwp_wptr, qwb_depth, v_qwp_ef, v_qwp_aff, v_qwp_ff );
      q_status( qwc_rptr, qwc_wptr, qwb_depth, v_qwc_ef, v_qwc_aff, v_qwc_ff );

      v_wa_available := (awvalid = '1' and awready = '1') or not v_qwa_ef;
      v_wd_available := (wvalid = '1' and wready = '1')   or not v_qwd_ef;

      v_sw_beat_end    := sw_en = '1' and sw_rdy = '1' and sw_last = '0';
      v_sw_burst_end   := sw_en = '1' and sw_rdy = '1' and sw_last = '1';
      v_sw_beat_ready  := sw_busy = '0' or v_sw_beat_end;
      v_sw_burst_ready := sw_busy = '0' or v_sw_burst_end;

      v_qwa_enq := awvalid = '1' and awready = '1';
      v_qwa_deq := v_sw_burst_ready and v_wa_available and v_wd_available;
      v_qwd_enq := wvalid = '1' and wready = '1';
      v_qwd_deq := v_sw_beat_ready and v_wd_available;
      v_qwp_enq := v_qwa_enq;
      v_qwp_deq := v_sw_burst_end;
      v_qwc_enq := v_sw_burst_end;
      v_qwc_deq := (v_qwc_enq or not v_qwc_ef) and (bvalid = '0' or bready = '1');

      q_update(  qwa_rptr, qwa_wptr, qwa_depth, v_qwa_enq, v_qwa_deq, v_qwa_cut );
      q_update(  qwd_rptr, qwd_wptr, qwd_depth, v_qwd_enq, v_qwd_deq, v_qwd_cut );
      q_update(  qwp_rptr, qwp_wptr, qwb_depth, v_qwp_enq, v_qwp_deq, v_qwp_cut );
      q_update(  qwc_rptr, qwc_wptr, qwb_depth, v_qwc_enq, v_qwc_deq, v_qwc_cut );

      v_qwa_new.addr  := awaddr(addr_width-1 downto 0);
      v_qwa_new.len   := awlen;
      v_qwa_new.size  := awsize;
      v_qwa_new.burst := awburst;
      v_qwd_new.data  := wdata;
      v_qwd_new.strb  := wstrb;
      v_qwd_new.last  := wlast;
      v_qwp_new.id    := awid;
      v_qwc_new       := v_qwp_head;

      qwa(qwa_wptr) <= v_qwa_new when v_qwa_enq;
      qwd(qwd_wptr) <= v_qwd_new when v_qwd_enq;
      qwp(qwp_wptr) <= v_qwp_new when v_qwp_enq;
      qwc(qwc_wptr) <= v_qwc_new when v_qwc_enq;

      v_qwa_head := v_qwa_new when v_qwa_cut else qwa(qwa_rptr);
      v_qwd_head := v_qwd_new when v_qwd_cut else qwd(qwd_rptr);
      v_qwp_head := v_qwp_new when v_qwp_cut else qwp(qwp_rptr);
      v_qwc_head := v_qwc_new when v_qwc_cut else qwc(qwp_rptr);

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
      sw_busy  <= '1' when v_qwa_deq else '0' when v_sw_burst_end;
      sw_len   <= v_qwa_head.len   when v_qwa_deq else (others => '0') when v_sw_burst_end;
      sw_size  <= v_qwa_head.size  when v_qwa_deq else (others => '0') when v_sw_burst_end;
      sw_burst <= v_qwa_head.burst when v_qwa_deq else (others => '0') when v_sw_burst_end;

      -- SW: per burst and per beat
      sw_addr  <= v_qwa_head.addr  when v_qwa_deq else v_sw_addr_next when v_qwd_deq else (others => '0') when v_sw_burst_end;

      -- SW: per beat
      sw_en    <= '1'              when v_qwd_deq else '0'             when v_sw_beat_end or v_sw_burst_end;
      sw_be    <= v_qwd_head.strb  when v_qwd_deq else (others => '0') when v_sw_beat_end or v_sw_burst_end;
      sw_data  <= v_qwd_head.data  when v_qwd_deq else (others => '0') when v_sw_beat_end or v_sw_burst_end;
      sw_last  <= v_qwd_head.last  when v_qwd_deq else '0'             when v_sw_beat_end or v_sw_burst_end;

      -- AXI outputs
      awready  <= '0' when (v_qwa_aff and not v_qwa_deq) or (v_qwp_aff and not v_qwp_deq) else '1';
      wready   <= '0' when v_qwd_aff else '1';
      bid      <= v_qwc_head.id when v_qwc_deq else (others => '0') when bready = '1';
      bvalid   <= '1' when v_qwc_deq else '0' when bready = '1';

      --------------------------------------------------------------------------------
      -- read

      q_status( qra_rptr, qra_wptr, qra_depth, v_qra_ef, v_qra_aff, v_qra_ff );
      q_status( qrd_rptr, qrd_wptr, qrd_depth, v_qrd_ef, v_qrd_aff, v_qrd_ff );

      v_ra_available := (arvalid = '1' and arready = '1') or not v_qra_ef;
      v_rd_available := (rvalid = '1' and rready = '1')   or not v_qrd_ef;

      v_sr_beat_end    := sr_en = '1' and sr_rdy = '1' and sr_last = '0';
      v_sr_burst_end   := sr_en = '1' and sr_rdy = '1' and sr_last = '1';
      v_sr_beat_ready  := sr_busy = '0' or v_sr_beat_end;
      v_sr_burst_ready := sr_busy = '0' or v_sr_burst_end;

      v_qra_enq := arvalid = '1' and arready = '1';
      v_qra_deq := v_sr_burst_ready and v_ra_available and not v_qrd_ff;
      v_qrd_enq := sr_en = '1' and sr_rdy = '1';
      v_qrd_deq := (v_qrd_enq or not v_qrd_ef) and (rvalid = '0' or rready = '1');

      q_update( qra_rptr, qra_wptr, qra_depth, v_qra_enq, v_qra_deq, v_qra_cut );
      q_update( qrd_rptr, qrd_wptr, qrd_depth, v_qrd_enq, v_qrd_deq, v_qrd_cut );

      v_qra_new.id    := arid;
      v_qra_new.addr  := araddr(addr_width-1 downto 0);
      v_qra_new.len   := arlen;
      v_qra_new.size  := arsize;
      v_qra_new.burst := arburst;
      v_qrd_new.id    := sr_id;
      v_qrd_new.data  := sr_data;
      v_qrd_new.last  := sr_last;

      qra(qra_wptr) <= v_qra_new when v_qra_enq;
      qrd(qrd_wptr) <= v_qrd_new when v_qrd_enq;

      v_qra_head := v_qra_new when v_qra_cut else qra(qra_rptr);
      v_qrd_head := v_qrd_new when v_qrd_cut else qrd(qrd_rptr);

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
      v_sr_count_next := std_logic_vector(unsigned(sr_count)+1);

      -- SR: per burst
      sr_busy  <= '1'              when v_qra_deq else '0'             when v_sr_burst_end;
      sr_id    <= v_qra_head.id    when v_qra_deq else (others => '0') when v_sr_burst_end;
      sr_len   <= v_qra_head.len   when v_qra_deq else (others => '0') when v_sr_burst_end;
      sr_size  <= v_qra_head.size  when v_qra_deq else (others => '0') when v_sr_burst_end;
      sr_burst <= v_qra_head.burst when v_qra_deq else (others => '0') when v_sr_burst_end;

      -- SR: per burst and per beat
      if v_qra_deq then -- new burst
        sr_count <= (others => '0');
        sr_addr  <= v_qra_head.addr;
        sr_last  <= '1' when v_qra_head.len = x"00" else '0';
      elsif v_sr_beat_ready then -- new beat
        sr_count <= v_sr_count_next;
        sr_addr  <= v_sr_addr_next;
        sr_last  <= '1' when std_logic_vector(unsigned(sr_count)+1) = sr_len else '0';
      elsif v_sr_burst_end then -- end of burst
        sr_count <= (others => '0');
        sr_addr  <= (others => '0');
        sr_last  <= '0';
      end if;

      -- SR: per beat
      sr_en    <= '1' when v_qra_deq or (sr_busy = '1' and v_rd_available) else '0' when v_sr_beat_end;

      -- AXI outputs
      arready  <= '0' when v_qra_aff and not v_qra_deq else '1';
      rid      <= v_qrd_head.id   when v_qrd_deq else (others => '0') when rready = '1';
      rdata    <= v_qrd_head.data when v_qrd_deq else (others => '0') when rready = '1';
      rlast    <= v_qrd_head.last when v_qrd_deq else '0'             when rready = '1';
      rvalid   <= '1'             when v_qrd_deq else '0'             when rready = '1';

      --------------------------------------------------------------------------------

    end if;
  end process;

end architecture synth;
