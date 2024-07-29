--------------------------------------------------------------------------------
-- video_mode_v2.vhd                                                             --
-- Video mode table.                                                          --
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

package video_mode_v2_pkg is

  type video_clk_sel_t is (
    clk_sel_25m2,
    clk_sel_27m0,
    clk_sel_74m25,
    clk_sel_148m5
  );

  type aspect_t is (
    aspect_null,
    aspect_4_3,
    aspect_16_9
  );

  type video_mode_params_t is record
    clk_sel   : std_logic_vector(1 downto 0);  -- pixel frequency select
    dmt       : std_logic;                     -- 1 = DMT, 0 = CEA
    id        : std_logic_vector(7 downto 0);  -- DMT ID or CEA/CTA VIC
    pix_rep   : std_logic;                     -- 1 = pixel doubling/repetition
    aspect    : std_logic_vector(1 downto 0);  -- 0x = normal, 10 = force 16:9, 11 = force 4:3
    interlace : std_logic;                     -- interlaced/progressive scan
    v_tot     : std_logic_vector(10 downto 0); -- vertical total lines (must be odd if interlaced)
    v_act     : std_logic_vector(10 downto 0); -- vertical active lines
    v_sync    : std_logic_vector(2 downto 0);  -- vertical sync width
    v_bp      : std_logic_vector(5 downto 0);  -- vertical back porch
    h_tot     : std_logic_vector(11 downto 0); -- horizontal total
    h_act     : std_logic_vector(10 downto 0); -- horizontal active
    h_sync    : std_logic_vector(6 downto 0);  -- horizontal sync width
    h_bp      : std_logic_vector(7 downto 0);  -- horizontal back porch
    vs_pol    : std_logic;                     -- vertical sync polarity (1 = high)
    hs_pol    : std_logic;                     -- horizontal sync polarity (1 = high)
  end record video_mode_params_t;

  constant MODE_640x480p60   : std_logic_vector(3 downto 0) := "0000";
  constant MODE_720x480p60   : std_logic_vector(3 downto 0) := "0001";
  constant MODE_720x480p60w  : std_logic_vector(3 downto 0) := "0010";
  constant MODE_1280x720p60  : std_logic_vector(3 downto 0) := "0011";
  constant MODE_1920x1080i60 : std_logic_vector(3 downto 0) := "0100";
  constant MODE_720x480i60   : std_logic_vector(3 downto 0) := "0101";
  constant MODE_720x480i60w  : std_logic_vector(3 downto 0) := "0110";
  constant MODE_1920x1080p60 : std_logic_vector(3 downto 0) := "0111";
  constant MODE_720x576p50   : std_logic_vector(3 downto 0) := "1000";
  constant MODE_720x576p50w  : std_logic_vector(3 downto 0) := "1001";
  constant MODE_1280x720p50  : std_logic_vector(3 downto 0) := "1010";
  constant MODE_1920x1080i50 : std_logic_vector(3 downto 0) := "1011";
  constant MODE_720x576i50   : std_logic_vector(3 downto 0) := "1100";
  constant MODE_720x576i50w  : std_logic_vector(3 downto 0) := "1101";
  constant MODE_1920x1080p50 : std_logic_vector(3 downto 0) := "1110";

  component video_mode_v2 is
    port (
      mode   : in    std_logic_vector(3 downto 0);
      params : out   video_mode_params_t
    );
  end component video_mode_v2;

end package video_mode_v2_pkg;

----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.video_mode_v2_pkg.all;

entity video_mode_v2 is
  port (
    mode   : in    std_logic_vector(3 downto 0);
    params : out   video_mode_params_t
  );
end entity video_mode_v2;

architecture synth of video_mode_v2 is

  type video_timing_t is record
    name      : string(1 to 16);
    dmt       : boolean;
    id        : integer;
    clk_sel   : video_clk_sel_t;
    pix_rep   : integer range 0 to 1;
    aspect    : aspect_t;
    interlace : boolean;
    v_tot     : integer;
    v_act     : integer;
    v_sync    : integer;
    v_bp      : integer;
    h_tot     : integer;
    h_act     : integer;
    h_sync    : integer;
    h_bp      : integer;
    vs_pol    : bit;
    hs_pol    : bit;
  end record video_timing_t;

  type video_timings_t is array (0 to 14) of video_timing_t;

  constant VIDEO_TIMINGS : video_timings_t :=
  (
    (
      name      => "640x480p60      ",
      dmt       => false,
      id        => 1,
      clk_sel   => CLK_SEL_25M2,
      pix_rep   => 0,
      aspect    => ASPECT_4_3,
      interlace => FALSE,
      v_tot     => 525,
      v_act     => 480,
      v_sync    => 2,
      v_bp      => 33,
      h_tot     => 800,
      h_act     => 640,
      h_sync    => 96,
      h_bp      => 48,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "720x480p60      ",
      dmt       => false,
      id        => 2,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 0,
      aspect    => ASPECT_4_3,
      interlace => FALSE,
      v_tot     => 525,
      v_act     => 480,
      v_sync    => 6,
      v_bp      => 30,
      h_tot     => 858,
      h_act     => 720,
      h_sync    => 62,
      h_bp      => 60,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "720x480p60w     ",
      dmt       => false,
      id        => 3,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => FALSE,
      v_tot     => 525,
      v_act     => 480,
      v_sync    => 6,
      v_bp      => 30,
      h_tot     => 858,
      h_act     => 720,
      h_sync    => 62,
      h_bp      => 60,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "1280x720p60     ",
      dmt       => false,
      id        => 4,
      clk_sel   => CLK_SEL_74M25,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => FALSE,
      v_tot     => 750,
      v_act     => 720,
      v_sync    => 5,
      v_bp      => 20,
      h_tot     => 1650,
      h_act     => 1280,
      h_sync    => 40,
      h_bp      => 220,
      vs_pol    => '1',
      hs_pol    => '1'
    ),
    (
      name      => "1920x1080i60    ",
      dmt       => false,
      id        => 5,
      clk_sel   => CLK_SEL_74M25,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => TRUE,
      v_tot     => 1125,
      v_act     => 1080,
      v_sync    => 5,
      v_bp      => 15,
      h_tot     => 2200,
      h_act     => 1920,
      h_sync    => 44,
      h_bp      => 148,
      vs_pol    => '1',
      hs_pol    => '1'
    ),
    (
      name      => "720x480i60      ",
      dmt       => false,
      id        => 6,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 1,
      aspect    => ASPECT_4_3,
      interlace => TRUE,
      v_tot     => 525,
      v_act     => 480,
      v_sync    => 3,
      v_bp      => 15,
      h_tot     => 1716,
      h_act     => 1440,
      h_sync    => 124,
      h_bp      => 114,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "720x480i60w     ",
      dmt       => false,
      id        => 7,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 1,
      aspect    => ASPECT_16_9,
      interlace => TRUE,
      v_tot     => 525,
      v_act     => 480,
      v_sync    => 3,
      v_bp      => 15,
      h_tot     => 1716,
      h_act     => 1440,
      h_sync    => 124,
      h_bp      => 114,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "1920x1080p60    ",
      dmt       => false,
      id        => 16,
      clk_sel   => CLK_SEL_148M5,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => FALSE,
      v_tot     => 1125,
      v_act     => 1080,
      v_sync    => 5,
      v_bp      => 36,
      h_tot     => 2200,
      h_act     => 1920,
      h_sync    => 44,
      h_bp      => 148,
      vs_pol    => '1',
      hs_pol    => '1'
    ),
    (
      name      => "720x576p50      ",
      dmt       => false,
      id        => 17,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 0,
      aspect    => ASPECT_4_3,
      interlace => FALSE,
      v_tot     => 625,
      v_act     => 576,
      v_sync    => 5,
      v_bp      => 39,
      h_tot     => 864,
      h_act     => 720,
      h_sync    => 64,
      h_bp      => 68,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "720x576p50w     ",
      dmt       => false,
      id        => 18,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => FALSE,
      v_tot     => 625,
      v_act     => 576,
      v_sync    => 5,
      v_bp      => 39,
      h_tot     => 864,
      h_act     => 720,
      h_sync    => 64,
      h_bp      => 68,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "1280x720p50     ",
      dmt       => false,
      id        => 19,
      clk_sel   => CLK_SEL_74M25,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => FALSE,
      v_tot     => 750,
      v_act     => 720,
      v_sync    => 5,
      v_bp      => 20,
      h_tot     => 1980,
      h_act     => 1280,
      h_sync    => 40,
      h_bp      => 220,
      vs_pol    => '1',
      hs_pol    => '1'
    ),
    (
      name      => "1920x1080i50    ",
      dmt       => false,
      id        => 20,
      clk_sel   => CLK_SEL_74M25,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => TRUE,
      v_tot     => 1125,
      v_act     => 1080,
      v_sync    => 5,
      v_bp      => 15,
      h_tot     => 2640,
      h_act     => 1920,
      h_sync    => 44,
      h_bp      => 148,
      vs_pol    => '1',
      hs_pol    => '1'
    ),
    (
      name      => "720x576i50      ",
      dmt       => false,
      id        => 21,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 1,
      aspect    => ASPECT_4_3,
      interlace => TRUE,
      v_tot     => 625,
      v_act     => 576,
      v_sync    => 3,
      v_bp      => 19,
      h_tot     => 1728,
      h_act     => 1440,
      h_sync    => 126,
      h_bp      => 138,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "720x576i50w     ",
      dmt       => false,
      id        => 22,
      clk_sel   => CLK_SEL_27M0,
      pix_rep   => 1,
      aspect    => ASPECT_16_9,
      interlace => TRUE,
      v_tot     => 625,
      v_act     => 576,
      v_sync    => 3,
      v_bp      => 19,
      h_tot     => 1728,
      h_act     => 1440,
      h_sync    => 126,
      h_bp      => 138,
      vs_pol    => '0',
      hs_pol    => '0'
    ),
    (
      name      => "1920x1080p50    ",
      dmt       => false,
      id        => 31,
      clk_sel   => CLK_SEL_148M5,
      pix_rep   => 0,
      aspect    => ASPECT_16_9,
      interlace => FALSE,
      v_tot     => 1125,
      v_act     => 1080,
      v_sync    => 5,
      v_bp      => 36,
      h_tot     => 2640,
      h_act     => 1920,
      h_sync    => 44,
      h_bp      => 148,
      vs_pol    => '1',
      hs_pol    => '1'
    )
  );

begin

  -- should infer 16 x N async ROM
  MAIN: process (mode) is
    variable i  : integer;
    variable vt : video_timing_t;
  begin
    i := to_integer(unsigned(mode));
    if i < 0 or i >= video_timings'length then
      i := 0;
    end if;
    vt := video_timings(i);

    params.clk_sel <= std_logic_vector(to_unsigned(video_clk_sel_t'pos(vt.clk_sel), 2));
    if vt.dmt then
      params.dmt <= '1';
    else
      params.dmt <= '0';
    end if;
    params.id <= std_logic_vector(to_unsigned(vt.id, params.id'length));
    if vt.pix_rep = 0 then
      params.pix_rep <= '0';
    else
      params.pix_rep <= '1';
    end if;
    if vt.aspect = ASPECT_16_9 then
      params.aspect <= "10";
    elsif vt.aspect = ASPECT_4_3 then
      params.aspect <= "01";
    else
      params.aspect <= "00";
    end if;
    if vt.interlace then
      params.interlace <= '1';
    else
      params.interlace <= '0';
    end if;
    params.v_tot  <= std_logic_vector(to_unsigned(vt.v_tot,  params.v_tot'length));
    params.v_sync <= std_logic_vector(to_unsigned(vt.v_sync, params.v_sync'length));
    params.v_bp   <= std_logic_vector(to_unsigned(vt.v_bp,   params.v_bp'length));
    params.v_act  <= std_logic_vector(to_unsigned(vt.v_act,  params.v_act'length));
    params.h_tot  <= std_logic_vector(to_unsigned(vt.h_tot,  params.h_tot'length));
    params.h_sync <= std_logic_vector(to_unsigned(vt.h_sync, params.h_sync'length));
    params.h_bp   <= std_logic_vector(to_unsigned(vt.h_bp,   params.h_bp'length));
    params.h_act  <= std_logic_vector(to_unsigned(vt.h_act,  params.h_act'length));
    params.vs_pol <= to_stdulogic(vt.vs_pol);
    params.hs_pol <= to_stdulogic(vt.hs_pol);
  end process MAIN;

end architecture synth;
