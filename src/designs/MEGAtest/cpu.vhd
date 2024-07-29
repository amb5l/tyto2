--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package cpu_pkg is

  component cpu is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      txt_en   : out   std_ulogic;
      txt_bwe  : out   std_ulogic_vector(3 downto 0);
      txt_addr : out   std_ulogic_vector(14 downto 2);
      txt_dout : out   std_ulogic_vector(31 downto 0);
      txt_din  : in    std_ulogic_vector(31 downto 0)
    );
  end component cpu;

end package cpu_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.mb_mcs_wrapper_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity cpu is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    txt_en   : out   std_ulogic;
    txt_bwe  : out   std_ulogic_vector(3 downto 0);
    txt_addr : out   std_ulogic_vector(14 downto 2);
    txt_dout : out   std_ulogic_vector(31 downto 0);
    txt_din  : in    std_ulogic_vector(31 downto 0)
  );
end entity cpu;

architecture rtl of cpu is

  signal gpi     : sulv_vector(1 to 4)(31 downto 0);
  signal gpo     : sulv_vector(1 to 4)(31 downto 0);
  signal io_mosi : mb_mcs_io_mosi_t;
  signal io_miso : mb_mcs_io_miso_t;

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

end architecture rtl;

