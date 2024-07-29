--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package clk_rst_pkg is

  component clk_rst is
    port (
      ref_rst     : in    std_ulogic;
      ref_clk     : in    std_ulogic;
      s_rst       : out   std_ulogic;
      s_clk       : out   std_ulogic;
      s_clk_dly   : out   std_ulogic
    );
  end component clk_rst;

end package clk_rst_pkg;

--------------------------------------------------------------------------------

use work.mmcm_v2_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;


entity clk_rst is
  port (
    ref_rst     : in    std_ulogic;
    ref_clk     : in    std_ulogic;
    s_rst       : out   std_ulogic;
    s_clk       : out   std_ulogic;
    s_clk_dly   : out   std_ulogic
  );
end entity clk_rst;

architecture rtl of clk_rst is

  signal clk_200m : std_ulogic;

begin

  U_MMCM: component mmcm_v2
    generic map (
      mul    => 10.0,
      div    => 1,
      odiv0  => 5.0,
      odiv1  => 10,
      odiv2  => 10,
      phase2 => 270.0
    )
    port map (
      rsti  => ref_rst,
      clki  => ref_clk,
      rsto  => s_rst,
      clk0  => clk_200m,
      clk1  => s_clk,
      clk2  => s_clk_dly,
      clk3  => open,
      clk4  => open,
      clk5  => open,
      clk6  => open
    );

  U_IDELAYCTRL: component idelayctrl
    port map (
      rst    => s_rst,
      refclk => clk_200m,
      rdy    => open
    );

end architecture rtl;
