--------------------------------------------------------------------------------

use work.video_mode_v2_pkg.all;
use work.vga_text_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package display_pkg is

  alias txt_params_t is work.vga_text_pkg.vga_text_params_t;

  component display is
    port (
      cpu_clk     : in    std_ulogic;
      cpu_en      : in    std_ulogic;
      cpu_bwe     : in    std_ulogic_vector(3 downto 0);
      cpu_addr    : in    std_ulogic_vector(14 downto 2);
      cpu_din     : in    std_ulogic_vector(31 downto 0);
      cpu_dout    : out   std_ulogic_vector(31 downto 0);
      vtg_mode    : in    std_ulogic_vector(3 downto 0);
      txt_params  : in    vga_text_params_t;
      ref_rst     : in    std_ulogic;
      ref_clk     : in    std_ulogic;
      hdmi_clk_p  : out   std_ulogic;
      hdmi_clk_n  : out   std_ulogic;
      hdmi_data_p : out   std_ulogic_vector(0 to 2);
      hdmi_data_n : out   std_ulogic_vector(0 to 2)
    );
  end component display;

end package display_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.ram_tdp_ar_8kx32_16kx16_pkg.all;
use work.video_mode_v2_pkg.all;
use work.video_out_clock_pkg.all;
use work.video_out_timing_v2_pkg.all;
use work.char_rom_437_8x16_pkg.all;
use work.vga_text_pkg.all;
use work.dvi_tx_encoder_pkg.all;
use work.serialiser_10to1_selectio_pkg.all;
use work.display_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity display is
  port (

    cpu_clk     : in    std_ulogic;
    cpu_en      : in    std_ulogic;
    cpu_bwe     : in    std_ulogic_vector(3 downto 0);
    cpu_addr    : in    std_ulogic_vector(14 downto 2);
    cpu_din     : in    std_ulogic_vector(31 downto 0);
    cpu_dout    : out   std_ulogic_vector(31 downto 0);

    vtg_mode    : in    std_ulogic_vector(3 downto 0);
    txt_params  : in    vga_text_params_t;

    ref_rst     : in    std_ulogic;
    ref_clk     : in    std_ulogic;
    hdmi_clk_p  : out   std_ulogic;
    hdmi_clk_n  : out   std_ulogic;
    hdmi_data_p : out   std_ulogic_vector(0 to 2);
    hdmi_data_n : out   std_ulogic_vector(0 to 2)

  );
end entity display;

architecture rtl of display is

  signal buf_en      : std_ulogic;
  signal buf_addr    : std_ulogic_vector(14 downto 1);
  signal buf_data    : std_ulogic_vector(15 downto 0);
  signal vga_rst     : std_ulogic;
  signal vga_clk     : std_ulogic;
  signal vga_clk_x5  : std_ulogic;
  signal vtg         : vtg_t;
  signal vga         : vga_t;
  signal vga_d       : sulv_vector(0 to 2)(7 downto 0);
  signal tmds        : sulv_vector(0 to 2)(9 downto 0);

  signal vtg_params  : video_mode_params_t;

begin

  -- RAM
  U_RAM: component ram_tdp_ar_8kx32_16kx16
    port map (
      clk_a  => cpu_clk,
      clr_a  => '0',
      en_a   => cpu_en,
      we_a   => cpu_bwe,
      addr_a => cpu_addr,
      din_a  => cpu_din,
      dout_a => cpu_dout,
      clk_b  => vga_clk,
      clr_b  => '0',
      en_b   => buf_en,
      we_b   => (others => '0'),
      addr_b => buf_addr,
      din_b  => (others => '0'),
      dout_b => buf_data
    );

  U_MODE: video_mode_v2
    port map (
      mode   => vtg_mode,
      params => vtg_params
    );

  U_MMCM: component video_out_clock
    generic map (
      fref => 100.0
    )
    port map (
      rsti    => ref_rst,
      clki    => ref_clk,
      sel     => vtg_params.clk_sel,
      rsto    => vga_rst,
      clko    => vga_clk,
      clko_x5 => vga_clk_X5
    );

  U_TIMING: component video_out_timing_v2
    port map (
      clk       => vga_clk,
      rst       => vga_rst,
      params    => vtg_params,
      genlock   => '0',
      genlocked => open,
      vtg       => vtg
    );

  U_VGA_TEXT: component vga_text
    port map (
      rst      => vga_rst,
      clk      => vga_clk,
      params   => txt_params,
      vtg      => vtg,
      buf_en   => buf_en,
      buf_addr => buf_addr,
      buf_data => buf_data,
      vga      => vga
    );

  --------------------------------------------------------------------------------
  -- output serialisers

  U_SER_CLK: component serialiser_10to1_selectio
    port map (
      rst    => vga_rst,
      clk    => vga_clk,
      clk_x5 => vga_clk_x5,
      d      => "0000011111",
      out_p  => hdmi_clk_p,
      out_n  => hdmi_clk_n
    );

  vga_d(0) <= vga.b;
  vga_d(1) <= vga.g;
  vga_d(2) <= vga.r;

  GEN_CH: for i in 0 to 2 generate
  begin
    U_ENC: component dvi_tx_encoder
      port map (
        rst     => vga_rst,
        clk     => vga_clk,
        de      => vga.de,
        d       => vga_d(i),
        c(0)    => vga.hs xor not vtg_params.hs_pol,
        c(1)    => vga.vs xor not vtg_params.vs_pol,
        q       => tmds(i)
      );

    U_SER: component serialiser_10to1_selectio
      port map (
        rst    => vga_rst,
        clk    => vga_clk,
        clk_x5 => vga_clk_x5,
        d      => tmds(i),
        out_p  => hdmi_data_p(i),
        out_n  => hdmi_data_n(i)
      );

  end generate GEN_CH;

  --------------------------------------------------------------------------------

end architecture rtl;