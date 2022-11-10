--------------------------------------------------------------------------------
-- bpp_hdtv_pcm_to_hdmi.vhd                                                   --
-- HDTV video and PCM audio to HDMI parallel TMDS.                            --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;

package bpp_hdtv_pcm_to_hdmi_pkg is

  component bpp_hdtv_pcm_to_hdmi is
    port (

      mode_vic    : in    std_logic_vector(7 downto 0);
      mode_clksel : in    std_logic_vector(1 downto 0);
      mode_pixrep : in    std_logic;
      mode_aspect : in    std_logic_vector(1 downto 0);
      mode_vs_pol : in    std_logic;
      mode_hs_pol : in    std_logic;

      hdtv_clk    : in    std_logic;
      hdtv_rst    : in    std_logic;
      hdtv_vs     : in    std_logic;
      hdtv_hs     : in    std_logic;
      hdtv_de     : in    std_logic;
      hdtv_r      : in    std_logic_vector(7 downto 0);
      hdtv_g      : in    std_logic_vector(7 downto 0);
      hdtv_b      : in    std_logic_vector(7 downto 0);

      pcm_clk     : in    std_logic;
      pcm_clken   : in    std_logic;
      pcm_rst     : in    std_logic;
      pcm_l       : in    std_logic_vector(15 downto 0);
      pcm_r       : in    std_logic_vector(15 downto 0);

      hdmi_tmds   : out   slv_9_0_t(0 to 2)

    );
  end component bpp_hdtv_pcm_to_hdmi;

end package bpp_hdtv_pcm_to_hdmi_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.video_mode_pkg.all;
  use work.vga_to_hdmi_pkg.all;

entity bpp_hdtv_pcm_to_hdmi is
  port (

    mode_vic    : in    std_logic_vector(7 downto 0);
    mode_clksel : in    std_logic_vector(1 downto 0);
    mode_pixrep : in    std_logic;
    mode_aspect : in    std_logic_vector(1 downto 0);
    mode_vs_pol : in    std_logic;
    mode_hs_pol : in    std_logic;

    hdtv_clk    : in    std_logic;
    hdtv_rst    : in    std_logic;
    hdtv_vs     : in    std_logic;
    hdtv_hs     : in    std_logic;
    hdtv_de     : in    std_logic;
    hdtv_r      : in    std_logic_vector(7 downto 0);
    hdtv_g      : in    std_logic_vector(7 downto 0);
    hdtv_b      : in    std_logic_vector(7 downto 0);

    pcm_clk     : in    std_logic;
    pcm_clken   : in    std_logic;
    pcm_rst     : in    std_logic;
    pcm_l       : in    std_logic_vector(15 downto 0);
    pcm_r       : in    std_logic_vector(15 downto 0);

    hdmi_tmds   : out   slv_9_0_t(0 to 2)

  );
end entity bpp_hdtv_pcm_to_hdmi;

architecture synth of bpp_hdtv_pcm_to_hdmi is

  signal pcm_acr : std_logic;                     -- HDMI ACR packet strobe (frequency = 128fs/N e.g. 1kHz)
  signal pcm_n   : std_logic_vector(19 downto 0); -- HDMI ACR N value
  signal pcm_cts : std_logic_vector(19 downto 0); -- HDMI ACR CTS value

begin

  -- N and CTS values for HDMI Audio Clock Regeneration; depends on pixel clock
  -- these values correspond to 48kHz audio sample rate
  pcm_n <= std_logic_vector(to_unsigned(6144, pcm_n'length));
  with to_integer(unsigned(mode_clksel)) select pcm_cts <=
        std_logic_vector(to_unsigned(148500, pcm_cts'length)) when video_clk_sel_t'pos(CLK_SEL_148M5),
        std_logic_vector(to_unsigned( 74250, pcm_cts'length)) when video_clk_sel_t'pos(CLK_SEL_74M25),
        std_logic_vector(to_unsigned( 27000, pcm_cts'length)) when others;

  -- ACR packet rate should be 128fs/N = 1kHz
  MAIN: process (pcm_rst, pcm_clk, pcm_clken) is
    variable count : integer range 0 to 47;
  begin
    if rising_edge(pcm_clk) then
      if pcm_rst = '1' then
        count   := 0;
        pcm_acr <= '0';
      elsif pcm_clken = '1' then
        pcm_acr <= '0';
        if count = 47 then
          count   := 0;
          pcm_acr <= '1';
        else
          count := count+1;
        end if;
      end if;
    end if;
  end process MAIN;

  -- VGA to HDMI converter
  CONV: component vga_to_hdmi
    generic map (
      pcm_fs    => 48.0
    )
    port map (
      dvi       => '0',
      vic       => mode_vic,
      pix_rep   => mode_pixrep,
      aspect    => mode_aspect,
      vs_pol    => mode_vs_pol,
      hs_pol    => mode_hs_pol,
      vga_rst   => hdtv_rst,
      vga_clk   => hdtv_clk,
      vga_vs    => hdtv_vs,
      vga_hs    => hdtv_hs,
      vga_de    => hdtv_de,
      vga_r     => hdtv_r,
      vga_g     => hdtv_g,
      vga_b     => hdtv_b,
      pcm_rst   => pcm_rst,
      pcm_clk   => pcm_clk,
      pcm_clken => pcm_clken,
      pcm_l     => pcm_l,
      pcm_r     => pcm_r,
      pcm_acr   => pcm_acr,
      pcm_n     => pcm_n,
      pcm_cts   => pcm_cts,
      tmds      => hdmi_tmds
    );

end architecture synth;
