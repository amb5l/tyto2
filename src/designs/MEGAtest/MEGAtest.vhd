--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package MEGAtest_pkg is

  component MEGAtest is
    port (
      ref_rst     : in    std_ulogic;
      ref_clk     : in    std_ulogic;
      hdmi_clk_p  : out   std_ulogic;
      hdmi_clk_n  : out   std_ulogic;
      hdmi_data_p : out   std_ulogic_vector(0 to 2);
      hdmi_data_n : out   std_ulogic_vector(0 to 2)
    );
  end component MEGAtest;

end package MEGAtest_pkg;

--------------------------------------------------------------------------------

use work.clk_rst_pkg.all;
use work.cpu_pkg.all;
use work.display_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity MEGAtest is
  port (

    ref_rst     : in    std_ulogic;
    ref_clk     : in    std_ulogic;

    hdmi_clk_p  : out   std_ulogic;
    hdmi_clk_n  : out   std_ulogic;
    hdmi_data_p : out   std_ulogic_vector(0 to 2);
    hdmi_data_n : out   std_ulogic_vector(0 to 2)

  );
end entity MEGAtest;

architecture rtl of MEGAtest is

  signal s_rst      : std_ulogic;
  signal s_clk      : std_ulogic;
  signal vtg_mode   : std_ulogic_vector(3 downto 0);
  signal txt_params : txt_params_t;
  signal buf_en     : std_ulogic;
  signal buf_bwe    : std_ulogic_vector(3 downto 0);
  signal buf_addr   : std_ulogic_vector(14 downto 2);
  signal buf_dout   : std_ulogic_vector(31 downto 0);
  signal buf_din    : std_ulogic_vector(31 downto 0);

begin

  U_CLK_RST: component clk_rst
    port map (
      ref_rst     => ref_rst,
      ref_clk     => ref_clk,
      s_rst       => s_rst,
      s_clk       => s_clk,
      s_clk_dly   => open
    );

  U_CPU: component cpu
    port map (
      rst        => s_rst,
      clk        => s_clk,
      vtg_mode   => vtg_mode,
      txt_params => txt_params,
      buf_en     => buf_en,
      buf_bwe    => buf_bwe,
      buf_addr   => buf_addr,
      buf_dout   => buf_dout,
      buf_din    => buf_din
    );

  U_DISPLAY: component display
    port map (
      cpu_clk     => s_clk,
      cpu_en      => buf_en,
      cpu_bwe     => buf_bwe,
      cpu_addr    => buf_addr,
      cpu_din     => buf_dout,
      cpu_dout    => buf_din,
      vtg_mode    => vtg_mode,
      txt_params  => txt_params,
      ref_rst     => ref_rst,
      ref_clk     => ref_clk,
      hdmi_clk_p  => hdmi_clk_p,
      hdmi_clk_n  => hdmi_clk_n,
      hdmi_data_p => hdmi_data_p,
      hdmi_data_n => hdmi_data_n
    );

end architecture rtl;

--------------------------------------------------------------------------------
