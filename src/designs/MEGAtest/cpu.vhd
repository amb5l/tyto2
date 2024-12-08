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
      ht_we      : out   std_ulogic_vector(3 downto 0);
      ht_addr    : out   std_ulogic_vector(7 downto 2);
      ht_dout    : out   std_ulogic_vector(31 downto 0);
      ht_din     : in    std_ulogic_vector(31 downto 0)
    );
  end component cpu;

end package cpu_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.tyto_utils_pkg.all;
use work.mb_mcs_wrapper_pkg.all;
use work.vga_text_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

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
    ht_we      : out   std_ulogic_vector(3 downto 0);
    ht_addr    : out   std_ulogic_vector(7 downto 2);
    ht_dout    : out   std_ulogic_vector(31 downto 0);
    ht_din     : in    std_ulogic_vector(31 downto 0)
  );
end entity cpu;

architecture rtl of cpu is

  signal gpi        : sulv_vector(1 to 4)(31 downto 0);
  signal gpo        : sulv_vector(1 to 4)(31 downto 0);
  signal io_mosi    : mb_mcs_io_mosi_t;
  signal io_miso    : mb_mcs_io_miso_t;
  signal buf_rstb   : std_ulogic;
  signal buf_rrdy   : std_ulogic;

  signal decode_buf : std_ulogic;
  signal decode_ts  : std_ulogic;
  signal decode_ht  : std_ulogic;

begin

  U_MCU: component mb_mcs_wrapper
    port map (
      rst      => rst,
      clk      => clk,
      uart_tx  => open,
      uart_rx  => '1',
      gpi      => gpi,
      gpo      => gpo,
      io_mosi  => io_mosi,
      io_miso  => io_miso
    );

  -- GPIO mappings

  P_GPIO: process(all)
  begin

    vtg_mode        <= gpo(1)(3 downto 0);
    txt_params.bcol <= gpo(1)(7 downto 4);
    txt_params.repx <= gpo(1)(8);
    txt_params.repy <= gpo(1)(9);
    txt_params.cols <= gpo(1)(23 downto 16);
    txt_params.rows <= gpo(1)(30 downto 24);
    txt_params.ox   <= gpo(2)(11 downto 0);
    txt_params.oy   <= gpo(2)(27 downto 16);

    gpi <= (others => (others => '0'));
    gpi(1)(0) <= ts_bsy;
    gpi(3) <= to_std_ulogic_vector(GIT_COMMIT);
    gpi(4)(3 downto 0) <= to_std_ulogic_vector(BOARD_REV);

  end process P_GPIO;

  -- memory mapped I/O

  decode_buf <= bool2sl(io_mosi.addr(29 downto 28) = "00"); -- 0xC0000000
  decode_ts  <= bool2sl(io_mosi.addr(29 downto 28) = "01"); -- 0xD0000000
  decode_ht  <= bool2sl(io_mosi.addr(29 downto 28) = "10"); -- 0xE0000000

  buf_en   <= (io_mosi.astb or io_mosi.wstb or io_mosi.rstb) and decode_buf;
  buf_we   <= io_mosi.be when io_mosi.wstb else (others => '0');
  buf_addr <= io_mosi.addr(buf_addr'range);
  buf_dout <= io_mosi.wdata;
  buf_rstb <= io_mosi.rstb and decode_buf;
  fd(clk,buf_rstb,buf_rrdy);

  ts_en    <= (io_mosi.astb or io_mosi.wstb or io_mosi.rstb) and decode_ts;
  ts_we    <= io_mosi.wstb;
  ts_addr  <= io_mosi.addr(ts_addr'range);
  ts_dout  <= io_mosi.wdata(ts_dout'range);

  ht_en    <= (io_mosi.astb or io_mosi.wstb or io_mosi.rstb) and decode_ht;
  ht_we    <= io_mosi.be when io_mosi.wstb else (others => '0');
  ht_addr  <= io_mosi.addr(ht_addr'range);
  ht_dout  <= io_mosi.wdata;

  io_miso.rdata <=
    buf_din          when decode_buf else
    x"0000" & ts_din when decode_ts  else
    ht_din           when decode_ht  else
    (others => '0');

  io_miso.rdy <=
    io_mosi.wstb or
    (decode_buf and buf_rrdy) or
    (decode_ts and ts_rdy) or
    (decode_ht and io_mosi.rstb);

end architecture rtl;
