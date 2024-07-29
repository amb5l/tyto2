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

  signal s_rst          : std_ulogic;
  signal s_clk          : std_ulogic;

  signal txt_en         : std_ulogic;
  signal txt_bwe        : std_ulogic_vector(3 downto 0);
  signal txt_addr       : std_ulogic_vector(14 downto 2);
  signal txt_dout       : std_ulogic_vector(31 downto 0);
  signal txt_din        : std_ulogic_vector(31 downto 0);

  signal txt_params     : txt_params_t;

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
      rst      => s_rst,
      clk      => s_clk,
      txt_en   => txt_en,
      txt_bwe  => txt_bwe,
      txt_addr => txt_addr,
      txt_dout => txt_dout,
      txt_din  => txt_din
    );

  txt_params.cols <= std_ulogic_vector(to_unsigned(128,txt_params.cols'length));
  txt_params.rows <= std_ulogic_vector(to_unsigned( 32,txt_params.rows'length));
  txt_params.repx <= '0';
  txt_params.repy <= '0';
  txt_params.ox   <= std_ulogic_vector(to_unsigned(128,txt_params.ox'length));
  txt_params.oy   <= std_ulogic_vector(to_unsigned(104,txt_params.oy'length));
  txt_params.bcol <= x"9"; -- light blue

  U_DISPLAY: component display
    port map (
      cpu_clk     => s_clk,
      cpu_en      => txt_en,
      cpu_bwe     => txt_bwe,
      cpu_addr    => txt_addr,
      cpu_din     => txt_dout,
      cpu_dout    => txt_din,
      vtg_mode    => "0011", -- 1280x720p60
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
