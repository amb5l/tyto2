--------------------------------------------------------------------------------

use work.vga_text_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package cpu_pkg is

  component cpu is
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
    ht_en      : out   std_ulogic;
    ht_we      : out   std_ulogic_vector(3 downto 0);
    ht_addr    : out   std_ulogic_vector(7 downto 2);
    ht_dout    : out   std_ulogic_vector(31 downto 0);
    ht_din     : in    std_ulogic_vector(31 downto 0)
  );
end entity cpu;

architecture rtl of cpu is

  signal gpi      : sulv_vector(1 to 4)(31 downto 0);
  signal gpo      : sulv_vector(1 to 4)(31 downto 0);
  signal io_mosi  : mb_mcs_io_mosi_t;
  signal io_miso  : mb_mcs_io_miso_t;
  signal buf_rstb : std_ulogic;
  signal buf_rrdy : std_ulogic;

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

  buf_en   <= (io_mosi.astb or io_mosi.wstb or io_mosi.rstb) and not io_mosi.addr(29);
  buf_we   <= io_mosi.be when io_mosi.wstb else (others => '0');
  buf_addr <= io_mosi.addr(buf_addr'range);
  buf_dout <= io_mosi.wdata;

  ht_en    <= (io_mosi.astb or io_mosi.wstb or io_mosi.rstb) and io_mosi.addr(29);
  ht_we    <= io_mosi.be when io_mosi.wstb else (others => '0');
  ht_addr  <= io_mosi.addr(ht_addr'range);
  ht_dout  <= io_mosi.wdata;

  io_miso.rdata <= ht_din when io_mosi.addr(29) else buf_din;

  buf_rstb <= io_mosi.rstb and not io_mosi.addr(29);
  fd(clk,buf_rstb,buf_rrdy);

  io_miso.rdy <= ht_en or (buf_en and io_mosi.wstb) or buf_rrdy;

end architecture rtl;

