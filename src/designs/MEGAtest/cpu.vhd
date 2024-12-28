--------------------------------------------------------------------------------

use work.vga_text_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package cpu_pkg is

  component cpu is
    generic (
      BOARD_REV  : bit_vector( 3 downto 0) := "0000";
      GIT_COMMIT : bit_vector(31 downto 0) := (others => '0')
    );
    port (
      rst        : in    std_ulogic;
      clk        : in    std_ulogic;
      vtg_mode   : out   std_ulogic_vector(3 downto 0);
      txt_params : out   vga_text_params_t;
      buf_en     : out   std_ulogic;
      buf_we     : out   std_ulogic_vector(3 downto 0);
      buf_addr   : out   std_ulogic_vector(14 downto 2);
      buf_dout   : out   std_ulogic_vector(31 downto 0);
      buf_din    : in    std_ulogic_vector(31 downto 0);
      ts_en      : out   std_ulogic;
      ts_we      : out   std_ulogic;
      ts_addr    : out   std_ulogic_vector(8 downto 2);
      ts_dout    : out   std_ulogic_vector(15 downto 0);
      ts_din     : in    std_ulogic_vector(15 downto 0);
      ts_rdy     : in    std_ulogic;
      ts_bsy     : in    std_ulogic;
      ht_en      : out   std_ulogic;
      ht_r_w     : out   std_ulogic;
      ht_bwe     : out   std_ulogic_vector(3 downto 0);
      ht_addr    : out   std_ulogic_vector(7 downto 2);
      ht_dout    : out   std_ulogic_vector(31 downto 0);
      ht_din     : in    std_ulogic_vector(31 downto 0)
    );
  end component cpu;

end package cpu_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.tyto_utils_pkg.all;
use work.axi_pkg.all;
use work.axi4l_sp32_pkg.all;
use work.mbv_maxi_j_wrapper_pkg.all;
use work.vga_text_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity cpu is
  generic (
    BOARD_REV  : bit_vector( 3 downto 0) := "0000";
    GIT_COMMIT : bit_vector(31 downto 0) := (others => '0')
  );
  port (
    rst        : in    std_ulogic;
    clk        : in    std_ulogic;
    vtg_mode   : out   std_ulogic_vector(3 downto 0);
    txt_params : out   vga_text_params_t;
    buf_en     : out   std_ulogic;
    buf_we     : out   std_ulogic_vector(3 downto 0);
    buf_addr   : out   std_ulogic_vector(14 downto 2);
    buf_dout   : out   std_ulogic_vector(31 downto 0);
    buf_din    : in    std_ulogic_vector(31 downto 0);
    ts_en      : out   std_ulogic;
    ts_we      : out   std_ulogic;
    ts_addr    : out   std_ulogic_vector(8 downto 2);
    ts_dout    : out   std_ulogic_vector(15 downto 0);
    ts_din     : in    std_ulogic_vector(15 downto 0);
    ts_rdy     : in    std_ulogic;
    ts_bsy     : in    std_ulogic;
    ht_en      : out   std_ulogic;
    ht_r_w     : out   std_ulogic;
    ht_bwe     : out   std_ulogic_vector(3 downto 0);
    ht_addr    : out   std_ulogic_vector(7 downto 2);
    ht_dout    : out   std_ulogic_vector(31 downto 0);
    ht_din     : in    std_ulogic_vector(31 downto 0)
  );
end entity cpu;

architecture rtl of cpu is

  -- AXI4-Lite bus
  signal axi_rst_n   : std_ulogic;
  signal axi4l_mosi  : axi4l_a32d32_mosi_t;
  signal axi4l_miso  : axi4l_a32d32_miso_t;

  -- simple write/read bus
  signal sp_en       : std_logic;
  signal sp_r_w      : std_logic;
  signal sp_wbe      : std_logic_vector(3 downto 0);
  signal sp_addr     : std_logic_vector(31 downto 0);
  signal sp_wdata    : std_logic_vector(31 downto 0);
  signal sp_rdata    : std_logic_vector(31 downto 0);
  signal sp_rdy      : std_logic;

  -- GPIO
  signal gpi         : sulv_vector(1 to 4)(31 downto 0);
  signal gpo         : sulv_vector(1 to 4)(31 downto 0);

  -- character buffer
  signal buf_rstb    : std_ulogic;
  signal buf_rrdy    : std_ulogic;

  -- address decode
  signal decode_buf  : std_ulogic;
  signal decode_ts   : std_ulogic;
  signal decode_ht   : std_ulogic;
  signal decode_gpio : std_ulogic;

begin

  -- CPU core

  U_MCU: component mbv_maxi_j_wrapper
    port map (
      rst      => rst,
      clk      => clk,
      arst_n   => axi_rst_n,
      axi4l_mo => axi4l_mosi,
      axi4l_mi => axi4l_miso
    );

  -- AXI bridge

  U_BRIDGE: component axi4l_sp32
    port map (
      clk      => clk,
      rst_n    => axi_rst_n,
      axi4l_si => axi4l_mosi,
      axi4l_so => axi4l_miso,
      sp_en    => sp_en,
      sp_r_w   => sp_r_w,
      sp_addr  => sp_addr,
      sp_wbe   => sp_wbe,
      sp_wdata => sp_wdata,
      sp_rdata => sp_rdata,
      sp_rdy   => sp_rdy
    );

  decode_buf  <= sp_en and bool2sl(sp_addr(29 downto 28) = "00"); -- 0xC0000000
  decode_ts   <= sp_en and bool2sl(sp_addr(29 downto 28) = "01"); -- 0xD0000000
  decode_ht   <= sp_en and bool2sl(sp_addr(29 downto 28) = "10"); -- 0xE0000000
  decode_gpio <= sp_en and bool2sl(sp_addr(29 downto 28) = "11"); -- 0xF0000000

  -- GPIO mappings

  P_GPO: process(all)
  begin
    vtg_mode        <= gpo(1)(3 downto 0);
    txt_params.bcol <= gpo(1)(7 downto 4);
    txt_params.repx <= gpo(1)(8);
    txt_params.repy <= gpo(1)(9);
    txt_params.cols <= gpo(1)(23 downto 16);
    txt_params.rows <= gpo(1)(30 downto 24);
    txt_params.ox   <= gpo(2)(11 downto 0);
    txt_params.oy   <= gpo(2)(27 downto 16);
  end process P_GPO;

  P_GPI: process(axi_rst_n, clk)
  begin
    if axi_rst_n = '0' then
      gpi <= (others => (others => '0'));
    elsif rising_edge(clk) then
      gpi <= (others => (others => '0'));
      gpi(1)(0) <= ts_bsy;
      gpi(3) <= to_std_ulogic_vector(GIT_COMMIT);
      gpi(4)(3 downto 0) <= to_std_ulogic_vector(BOARD_REV);
    end if;
  end process P_GPI;

  -- memory mapped I/O

  buf_en   <= sp_en and decode_buf;
  buf_we   <= sp_wbe when sp_r_w = '0' else (others => '0');
  buf_addr <= sp_addr(buf_addr'range);
  buf_dout <= sp_wdata;
  buf_rstb <= decode_buf and sp_r_w;
  fd(clk,buf_rstb,buf_rrdy);

  ts_en    <= sp_en and decode_ts;
  ts_we    <= not sp_r_w;
  ts_addr  <= sp_addr(ts_addr'range);
  ts_dout  <= sp_wdata(ts_dout'range);

  ht_en    <= sp_en and decode_ht;
  ht_r_w   <= sp_r_w;
  ht_bwe    <= sp_wbe when sp_r_w = '0' else (others => '0');
  ht_addr  <= sp_addr(ht_addr'range);
  ht_dout  <= sp_wdata;


  sp_rdata <=
    buf_din                                          when sp_addr(29 downto 28) = "00" else
    x"0000" & ts_din                                 when sp_addr(29 downto 28) = "01" else
    ht_din                                           when sp_addr(29 downto 28) = "10" else
    gpo(1+to_integer(unsigned(sp_addr(3 downto 2)))) when sp_addr(29 downto 28) = "11" and sp_addr(4) = '0' else
    gpi(1+to_integer(unsigned(sp_addr(3 downto 2)))) when sp_addr(29 downto 28) = "11" and sp_addr(4) = '1' else
    (others => 'X');

  sp_rdy <=
    (decode_buf and (buf_rrdy or not sp_r_w)) or
    (decode_ts and ts_rdy)                    or
    (decode_ht)                               or
    (decode_gpio);

  -- GPIO writes

  P_GPIO_W: process(axi_rst_n, clk)
  begin
    if axi_rst_n = '0' then
      gpo <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if decode_gpio and not sp_r_w then
        gpo(1+to_integer(unsigned(sp_addr(3 downto 2))))( 7 downto  0) <= sp_wdata( 7 downto  0) when sp_wbe(0) and not sp_addr(4);
        gpo(1+to_integer(unsigned(sp_addr(3 downto 2))))(15 downto  8) <= sp_wdata(15 downto  8) when sp_wbe(1) and not sp_addr(4);
        gpo(1+to_integer(unsigned(sp_addr(3 downto 2))))(23 downto 16) <= sp_wdata(23 downto 16) when sp_wbe(2) and not sp_addr(4);
        gpo(1+to_integer(unsigned(sp_addr(3 downto 2))))(31 downto 24) <= sp_wdata(31 downto 24) when sp_wbe(3) and not sp_addr(4);
      end if;
    end if;
  end process P_GPIO_W;

end architecture rtl;
