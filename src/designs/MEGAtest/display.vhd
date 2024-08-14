--------------------------------------------------------------------------------

use work.video_mode_v2_pkg.all;
use work.vga_text_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package display_pkg is

  type display_params_t is record
    mode       : std_ulogic_vector(3 downto 0);
    txt_params : vga_text_params_t;
  end record display_params_t;

  component display is
    port (
      cpu_params  : in    display_params_t;
      cpu_clk     : in    std_ulogic;
      cpu_en      : in    std_ulogic;
      cpu_we      : in    std_ulogic_vector(3 downto 0);
      cpu_addr    : in    std_ulogic_vector(14 downto 2);
      cpu_din     : in    std_ulogic_vector(31 downto 0);
      cpu_dout    : out   std_ulogic_vector(31 downto 0);
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
use work.tyto_utils_pkg.all;
use work.sync_pkg.all;
use work.ram_tdp_ar_8kx32_pkg.all;
use work.video_mode_v2_pkg.all;
use work.video_out_clock_v2_pkg.all;
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

    cpu_params  : in    display_params_t;
    cpu_clk     : in    std_ulogic;
    cpu_en      : in    std_ulogic;
    cpu_we      : in    std_ulogic_vector(3 downto 0);
    cpu_addr    : in    std_ulogic_vector(14 downto 2);
    cpu_din     : in    std_ulogic_vector(31 downto 0);
    cpu_dout    : out   std_ulogic_vector(31 downto 0);

    ref_rst     : in    std_ulogic;
    ref_clk     : in    std_ulogic;
    hdmi_clk_p  : out   std_ulogic;
    hdmi_clk_n  : out   std_ulogic;
    hdmi_data_p : out   std_ulogic_vector(0 to 2);
    hdmi_data_n : out   std_ulogic_vector(0 to 2)

  );
end entity display;

architecture rtl of display is

  signal buf_en       : std_ulogic;
  signal buf_addr     : std_ulogic_vector(14 downto 1);
  signal buf_rsel     : std_ulogic;
  signal buf_d32      : std_ulogic_vector(31 downto 0);
  signal buf_data     : std_ulogic_vector(15 downto 0);
  signal vga_rst      : std_ulogic;
  signal vga_clk      : std_ulogic;
  signal vga_clk_x5   : std_ulogic;
  signal vtg          : vtg_t;
  signal vga          : vga_t;
  signal vga_d        : sulv_vector(0 to 2)(7 downto 0);
  signal tmds         : sulv_vector(0 to 2)(9 downto 0);

  signal vga_params   : display_params_t;
  signal vtg_params_d : video_mode_params_t;
  signal vtg_params_q : video_mode_params_t;

begin

  -- RAM
  U_RAM: component ram_tdp_ar_8kx32
    port map (
      clk_a  => cpu_clk,
      clr_a  => '0',
      en_a   => cpu_en,
      we_a   => cpu_we,
      addr_a => cpu_addr,
      din_a  => cpu_din,
      dout_a => cpu_dout,
      clk_b  => vga_clk,
      clr_b  => '0',
      en_b   => buf_en,
      we_b   => (others => '0'),
      addr_b => buf_addr(14 downto 2),
      din_b  => (others => '0'),
      dout_b => buf_d32
    );

  U_FD1: fd(vga_clk,buf_addr(1),buf_rsel);
  buf_data <= buf_d32(31 downto 16) when buf_rsel = '1' else buf_d32(15 downto 0);

  U_SYNC: component sync -- v4p ignore w-301 (missing rst port)
    generic map (
      WIDTH  => 49
    )
    port map (
      clk => vga_clk,
      i( 3 downto  0) => cpu_params.mode,
      i(11 downto  4) => cpu_params.txt_params.cols,
      i(18 downto 12) => cpu_params.txt_params.rows,
      i(          19) => cpu_params.txt_params.repx,
      i(          20) => cpu_params.txt_params.repy,
      i(32 downto 21) => cpu_params.txt_params.ox,
      i(44 downto 33) => cpu_params.txt_params.oy,
      i(48 downto 45) => cpu_params.txt_params.bcol,
      o( 3 downto  0) => vga_params.mode,
      o(11 downto  4) => vga_params.txt_params.cols,
      o(18 downto 12) => vga_params.txt_params.rows,
      o(          19) => vga_params.txt_params.repx,
      o(          20) => vga_params.txt_params.repy,
      o(32 downto 21) => vga_params.txt_params.ox,
      o(44 downto 33) => vga_params.txt_params.oy,
      o(48 downto 45) => vga_params.txt_params.bcol
    );

  U_MODE: component video_mode_v2
    port map (
      mode   => vga_params.mode,
      params => vtg_params_d
    );

  U_FD2  : fd( vga_clk, vtg_params_d.clk_sel,   vtg_params_q.clk_sel   );
  U_FD3  : fd( vga_clk, vtg_params_d.dmt,       vtg_params_q.dmt       );
  U_FD4  : fd( vga_clk, vtg_params_d.id,        vtg_params_q.id        );
  U_FD5  : fd( vga_clk, vtg_params_d.pix_rep,   vtg_params_q.pix_rep   );
  U_FD6  : fd( vga_clk, vtg_params_d.aspect,    vtg_params_q.aspect    );
  U_FD7  : fd( vga_clk, vtg_params_d.interlace, vtg_params_q.interlace );
  U_FD8  : fd( vga_clk, vtg_params_d.v_tot,     vtg_params_q.v_tot     );
  U_FD9  : fd( vga_clk, vtg_params_d.v_act,     vtg_params_q.v_act     );
  U_FD10 : fd( vga_clk, vtg_params_d.v_sync,    vtg_params_q.v_sync    );
  U_FD11 : fd( vga_clk, vtg_params_d.v_bp,      vtg_params_q.v_bp      );
  U_FD12 : fd( vga_clk, vtg_params_d.h_tot,     vtg_params_q.h_tot     );
  U_FD13 : fd( vga_clk, vtg_params_d.h_act,     vtg_params_q.h_act     );
  U_FD14 : fd( vga_clk, vtg_params_d.h_sync,    vtg_params_q.h_sync    );
  U_FD15 : fd( vga_clk, vtg_params_d.h_bp,      vtg_params_q.h_bp      );
  U_FD16 : fd( vga_clk, vtg_params_d.vs_pol,    vtg_params_q.vs_pol    );
  U_FD17 : fd( vga_clk, vtg_params_d.hs_pol,    vtg_params_q.hs_pol    );

  U_MMCM: component video_out_clock_v2
    port map (
      rsti    => ref_rst,
      clki    => ref_clk,
      sel     => vtg_params_q.clk_sel,
      rsto    => vga_rst,
      clko    => vga_clk,
      clko_x5 => vga_clk_X5
    );

  U_TIMING: component video_out_timing_v2
    port map (
      clk       => vga_clk,
      rst       => vga_rst,
      params    => vtg_params_q,
      genlock   => '0',
      genlocked => open,
      vtg       => vtg
    );

  U_VGA_TEXT: component vga_text
    port map (
      rst      => vga_rst,
      clk      => vga_clk,
      params   => vga_params.txt_params,
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
        c(0)    => vga.hs xor not vtg_params_q.hs_pol,
        c(1)    => vga.vs xor not vtg_params_q.vs_pol,
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