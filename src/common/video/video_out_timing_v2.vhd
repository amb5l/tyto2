--------------------------------------------------------------------------------
-- video_out_timing_v2.vhd                                                       --
-- Video timing (sync/blank/active) generator.                                --
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

use work.video_mode_v2_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package video_out_timing_v2_pkg is

  type vtg_t is record
    f      : std_ulogic;
    vs     : std_ulogic;
    hs     : std_ulogic;
    vblank : std_ulogic;
    hblank : std_ulogic;
    ax     : std_ulogic_vector(11 downto 0);
    ay     : std_ulogic_vector(11 downto 0);
  end record vtg_t;

  component video_out_timing_v2 is
    generic (
      HOLD      : boolean := false
    );
    port (
      rst       : in    std_ulogic;
      clk       : in    std_ulogic;
      params    : in    video_mode_params_t;
      genlock   : in    std_ulogic;
      genlocked : out   std_ulogic;
      vtg       : out   vtg_t
    );
  end component video_out_timing_v2;

end package video_out_timing_v2_pkg;

----------------------------------------------------------------------

use work.tyto_utils_pkg.all;
use work.video_mode_v2_pkg.all;
use work.sync_reg_u_pkg.all;
use work.video_out_timing_v2_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity video_out_timing_v2 is
  generic (
    HOLD      : boolean := false           -- hold until genlock pulse received
  );
  port (
    rst       : in    std_ulogic;          -- pixel clock domain reset
    clk       : in    std_ulogic;          -- pixel clock
    params    : in    video_mode_params_t; -- video mode parameters
    genlock   : in    std_ulogic;          -- genlock pulse
    genlocked : out   std_ulogic;          -- genlock status
    vtg       : out   vtg_t                -- video timing generator

  );
end entity video_out_timing_v2;

architecture rtl of video_out_timing_v2 is

  signal run            : std_ulogic;

  signal pos_h_act      : unsigned(params.h_tot'range);
  signal pos_h_fp       : unsigned(params.h_tot'range);
  signal pos_v_act1     : unsigned(params.v_tot'range);
  signal pos_v_fp1      : unsigned(params.v_tot'range);
  signal pos_v_mid      : unsigned(params.v_tot'range);
  signal pos_v_bp2      : unsigned(params.v_tot'range);
  signal pos_v_act2     : unsigned(params.v_tot'range);
  signal pos_v_fp2      : unsigned(params.v_tot'range);

  signal genlock_s      : std_ulogic;
  signal genlock_s_1    : std_ulogic;
  signal genlock_start  : std_ulogic;
  signal genlock_end    : std_ulogic;
  signal genlock_window : std_ulogic;

  signal s1_count_h     : unsigned(params.h_tot'range);
  signal s1_h_zero      : std_ulogic;
  signal s1_h_bp        : std_ulogic;
  signal s1_h_act       : std_ulogic;
  signal s1_h_mid       : std_ulogic;
  signal s1_h_fp        : std_ulogic;

  signal s1_count_v     : unsigned(params.v_tot'range);
  signal s1_v_zero      : std_ulogic;
  signal s1_v_bp1       : std_ulogic;
  signal s1_v_act1      : std_ulogic;
  signal s1_v_fp1       : std_ulogic;
  signal s1_v_mid       : std_ulogic;
  signal s1_v_bp2       : std_ulogic;
  signal s1_v_act2      : std_ulogic;
  signal s1_v_fp2       : std_ulogic;

  signal s2_rep         : std_ulogic;
  signal s2_f           : std_ulogic;
  signal s2_vs          : std_ulogic;
  signal s2_vblank      : std_ulogic;
  signal s2_hs          : std_ulogic;
  signal s2_hblank      : std_ulogic;
  signal s2_ax          : signed(vtg.ax'range);
  signal s2_ay          : signed(vtg.ay'range);

begin

  P_COMB: process(all)
  begin
    s1_h_bp   <= '1' when s1_count_h = resize(unsigned(params.h_sync), params.h_tot'length) else '0';
    s1_h_act  <= '1' when s1_count_h = pos_h_act else '0';
    s1_h_mid  <= '1' when s1_count_h = shift_right(unsigned(params.h_tot), 1) else '0';
    s1_h_fp   <= '1' when s1_count_h = pos_h_fp else '0';
    s1_v_bp1  <= '1' when s1_count_v = resize(unsigned(params.v_sync), params.v_tot'length) else '0';
    s1_v_act1 <= '1' when s1_count_v = pos_v_act1 else '0';
    s1_v_fp1  <= '1' when s1_count_v = pos_v_fp1 else '0';
    s1_v_mid  <= '1' when s1_count_v = pos_v_mid else '0';
    s1_v_bp2  <= '1' when s1_count_v = pos_v_bp2 else '0';
    s1_v_act2 <= '1' when s1_count_v = pos_v_act2 else '0';
    s1_v_fp2  <= '1' when s1_count_v = pos_v_fp2 else '0';
    pos_h_act     <= resize(unsigned(params.h_sync), params.h_tot'length) + resize(unsigned(params.h_bp), params.h_tot'length);
    pos_h_fp      <= pos_h_act + unsigned(params.h_act);
    pos_v_act1    <= resize(unsigned(params.v_sync), params.v_tot'length) + resize(unsigned(params.v_bp), params.v_tot'length);
    if params.interlace = '0' then
      pos_v_fp1 <= pos_v_act1 + unsigned(params.v_act);
    else
      pos_v_fp1 <= pos_v_act1 + shift_right(unsigned(params.v_act), 1);
    end if;
    pos_v_mid  <= shift_right(unsigned(params.v_tot), 1);
    pos_v_bp2  <= pos_v_mid + resize(unsigned(params.v_sync), params.v_tot'length);
    pos_v_act2 <= pos_v_bp2 + resize(unsigned(params.v_bp), params.v_tot'length) + 1;
    pos_v_fp2  <= pos_v_act2 + shift_right(unsigned(params.v_act), 1);
  end process P_COMB;

  SYNC: component sync_reg_u
    generic map (
      stages => 2
    )
    port map (
      rst  => rst,
      clk  => clk,
      i(0) => genlock,
      o(0) => genlock_s
    );

  P_MAIN: process (rst, clk) is
  begin
    if rst = '1' then

      run            <= '0';
      s1_count_h     <= (others => '0');
      s1_h_zero      <= '1';
      s1_count_v     <= (others => '0');
      s1_v_zero      <= '1';
      s2_rep         <= '0';
      s2_f           <= '0';
      s2_vs          <= '0';
      s2_vblank      <= '1';
      s2_hs          <= '0';
      s2_hblank      <= '1';
      s2_ax          <= (others => '0');
      s2_ay          <= (others => '0');
      genlocked      <= '0';
      genlock_window <= '0';
      vtg.f          <= '0';
      vtg.vs         <= '0';
      vtg.hs         <= '0';
      vtg.vblank     <= '1';
      vtg.hblank     <= '1';
      vtg.ax         <= (others => '0');
      vtg.ay         <= (others => '1');
      genlock_s_1   <= '0';
      genlock_start <= '0';
      genlock_end   <= '0';

    elsif rising_edge(clk) then

      genlock_s_1   <= genlock_s;
      genlock_start <= ternary(s1_count_h = unsigned(params.h_tot) - 5, '1', '0');
      genlock_end   <= ternary(s1_count_h = to_unsigned(0, params.h_tot'length), '1', '0');

      if genlock_s = '1' and genlock_s_1 = '0' and genlock_window = '0' then

        -- out of lock, re-establish

        run            <= '1';
        s1_count_h     <= (others => '0');
        s1_h_zero      <= '1';
        s1_count_v     <= pos_v_act1;
        s1_v_zero      <= '0';
        s2_rep         <= '0';
        s2_f           <= '0';
        s2_vs          <= '0';
        s2_vblank      <= '0';
        s2_hs          <= '0';
        s2_hblank      <= '1';
        s2_ax          <= (others => '0');
        s2_ay          <= (others => '1');
        genlocked      <= '0';
        genlock_window <= '0';
        vtg.f          <= '0';
        vtg.vs         <= '0';
        vtg.hs         <= '0';
        vtg.vblank     <= '0';
        vtg.hblank     <= '1';
        vtg.ax         <= (others => '0');
        vtg.ay         <= (others => '1');

      elsif run = '1' or not hold then

        if genlock_s = '1' and genlock_s_1 = '0' and genlock_window = '1' then
          -- lock established
          genlocked <= '1';
        end if;

        --------------------------------------------------------------------------------
        -- pipeline stage 1

        genlock_window <= genlock_start or (genlock_window and not genlock_end);

        if s1_count_h = unsigned(params.h_tot)-1 then
          s1_count_h <= (others => '0');
          s1_h_zero  <= '1';
          if s1_count_v = unsigned(params.v_tot)-1 then
            s1_count_v <= (others => '0');
            s1_v_zero  <= '1';
          else
            s1_count_v <= s1_count_v + 1;
            s1_v_zero  <= '0';
          end if;
        else
          s1_count_h <= s1_count_h + 1;
          s1_h_zero  <= '0';
        end if;

        --------------------------------------------------------------------------------
        -- pipeline stage 2

        -- pixel repetition
        if s1_h_act = '1' then
          s2_rep <= '0';
        else
          s2_rep <= not s2_rep;
        end if;

        -- v sync
        if s1_v_zero = '1' and s1_h_zero = '1' then
          s2_f  <= '0';
          s2_vs <= '1';
        end if;
        if s1_v_bp1 = '1' and s1_h_zero = '1' then
          s2_vs <= '0';
        end if;
        -- handle field 2
        if params.interlace = '1' then
          if s1_v_mid = '1' and s1_h_mid = '1' then
            s2_f  <= '1';
            s2_vs <= '1';
          end if;
          if s1_v_bp2 = '1' and s1_h_mid = '1' then
            s2_vs <= '0';
          end if;
        end if;

        -- v blank
        if (s1_v_act1 = '1' or s1_v_act2 = '1') and s1_h_zero = '1' then
          s2_vblank <= '0';
        end if;
        if (s1_v_fp1 = '1' or s1_v_fp2 = '1') and s1_h_zero = '1' then
          s2_vblank <= '1';
        end if;

        -- h sync
        if s1_h_zero = '1' then
          s2_hs <= '1';
        end if;
        if s1_h_bp = '1' then
          s2_hs <= '0';
        end if;

        -- h blank
        if s1_h_act = '1' then
          s2_hblank <= '0';
        end if;
        if s1_h_fp = '1' then
          s2_hblank <= '1';
        end if;

        -- ax
        if s1_h_zero = '1' then
          s2_ax <= -signed(pos_h_act);
        else
          s2_ax <= s2_ax + 1;
        end if;

        -- ay
        if params.interlace = '1' then
          if s1_v_mid = '1' and s1_h_mid = '1' then
            s2_ay    <= shift_left(signed('0' & pos_v_mid)-signed('0' & pos_v_act2), 1);
            s2_ay(0) <= '1';
          elsif s1_h_zero = '1' then
            if s1_v_zero = '1' then
              s2_ay <= shift_left(-signed('0' & pos_v_act1), 1);
            else
              s2_ay <= s2_ay + 2;
            end if;
          end if;
        else
          if s1_h_zero = '1' then
            if s1_v_zero = '1' then
              s2_ay <= -signed('0' & pos_v_act1);
            else
              s2_ay <= s2_ay + 1;
            end if;
          end if;
        end if;

        --------------------------------------------------------------------------------
        -- pipeline stage 3: outputs

        vtg.ax     <= std_ulogic_vector(s2_ax);
        vtg.ay     <= std_ulogic_vector(s2_ay);
        vtg.f      <= s2_f;
        vtg.vs     <= s2_vs;
        vtg.hs     <= s2_hs;
        vtg.vblank <= s2_vblank;
        vtg.hblank <= s2_hblank;

      --------------------------------------------------------------------------------

      end if;

    end if;

  end process P_MAIN;

end architecture rtl;
