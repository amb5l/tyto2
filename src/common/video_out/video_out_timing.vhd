--------------------------------------------------------------------------------
-- video_out_timing.vhd                                                       --
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

library ieee;
use ieee.std_logic_1164.all;

package video_out_timing_pkg is

    component video_out_timing is
        port (

            rst       : in  std_logic;                     -- reset
            clk       : in  std_logic;                     -- pixel clock

            pix_rep   : in  std_logic;                     -- pixel repetition; 0 = none/x1, 1 = x2
            interlace : in  std_logic;
            v_tot     : in  std_logic_vector(10 downto 0); -- 1..2048 (must be odd if interlaced)
            v_act     : in  std_logic_vector(10 downto 0); -- 1..2048 (should be even)
            v_sync    : in  std_logic_vector(2 downto 0);  -- 1..7
            v_bp      : in  std_logic_vector(5 downto 0);  -- 1`..31
            h_tot     : in  std_logic_vector(11 downto 0); -- 1..4096
            h_act     : in  std_logic_vector(10 downto 0); -- 1..2048 (must be even)
            h_sync    : in  std_logic_vector(6 downto 0);  -- 1..127
            h_bp      : in  std_logic_vector(7 downto 0);  -- 0..255

            genlock   : in  std_logic;                     -- genlock (external vsync) pulse
            genlocked : out std_logic;                     -- genlock status                      
            f         : out std_logic;                     -- field ID
            vs        : out std_logic;                     -- vertical sync
            hs        : out std_logic;                     -- horizontal sync
            vblank    : out std_logic;                     -- vertical blank
            hblank    : out std_logic;                     -- horizontal blank
            ax        : out std_logic_vector(11 downto 0); -- visible area X (signed)
            ay        : out std_logic_vector(11 downto 0)  -- visible area Y (signed)

        );
    end component video_out_timing;

end package video_out_timing_pkg;

----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sync_reg_pkg.all;
use work.tyto_utils_pkg.all;

entity video_out_timing is
    port (

        rst       : in  std_logic;                     -- reset
        clk       : in  std_logic;                     -- pixel clock

        pix_rep   : in  std_logic;                     -- pixel repetition; 0 = none/x1, 1 = x2
        interlace : in  std_logic;
        v_tot     : in  std_logic_vector(10 downto 0); -- 1..2048 (must be odd if interlaced)
        v_act     : in  std_logic_vector(10 downto 0); -- 1..2048 (should be even)
        v_sync    : in  std_logic_vector(2 downto 0);  -- 1..7
        v_bp      : in  std_logic_vector(5 downto 0);  -- 1`..31
        h_tot     : in  std_logic_vector(11 downto 0); -- 1..4096
        h_act     : in  std_logic_vector(10 downto 0); -- 1..2048 (must be even)
        h_sync    : in  std_logic_vector(6 downto 0);  -- 1..127
        h_bp      : in  std_logic_vector(7 downto 0);  -- 0..255

        genlock   : in  std_logic;                     -- genlock (external vsync) pulse
        genlocked : out std_logic;                     -- genlock status                      
        f         : out std_logic;                     -- field ID
        vs        : out std_logic;                     -- vertical sync
        hs        : out std_logic;                     -- horizontal sync
        vblank    : out std_logic;                     -- vertical blank
        hblank    : out std_logic;                     -- horizontal blank
        ax        : out std_logic_vector(11 downto 0); -- visible area X (signed)
        ay        : out std_logic_vector(11 downto 0)  -- visible area Y (signed)

    );
end entity video_out_timing;

architecture synth of video_out_timing is

    signal pix_rep_s      : std_logic;                     -- } synchronised
    signal interlace_s    : std_logic;                     -- }
    signal v_tot_s        : std_logic_vector(10 downto 0); -- }
    signal v_act_s        : std_logic_vector(10 downto 0); -- }
    signal v_sync_s       : std_logic_vector(2 downto 0);  -- }
    signal v_bp_s         : std_logic_vector(5 downto 0);  -- }
    signal h_tot_s        : std_logic_vector(11 downto 0); -- }
    signal h_act_s        : std_logic_vector(10 downto 0); -- }
    signal h_sync_s       : std_logic_vector(6 downto 0);  -- }
    signal h_bp_s         : std_logic_vector(7 downto 0);  -- }

    signal pos_h_act      : unsigned(h_tot_s'range);
    signal pos_h_fp       : unsigned(h_tot_s'range);
    signal pos_v_act1     : unsigned(v_tot_s'range);
    signal pos_v_fp1      : unsigned(v_tot_s'range);
    signal pos_v_mid      : unsigned(v_tot_s'range);
    signal pos_v_bp2      : unsigned(v_tot_s'range);
    signal pos_v_act2     : unsigned(v_tot_s'range);
    signal pos_v_fp2      : unsigned(v_tot_s'range);

    signal genlock_s      : std_logic;
    signal genlock_s_1    : std_logic;
    signal genlock_start  : std_logic;
    signal genlock_end    : std_logic;
    signal genlock_window : std_logic;

    signal s1_count_h     : unsigned(h_tot_s'range);
    signal s1_h_zero      : std_logic;
    signal s1_h_bp        : std_logic;
    signal s1_h_act       : std_logic;
    signal s1_h_mid       : std_logic;
    signal s1_h_fp        : std_logic;

    signal s1_count_v     : unsigned(v_tot_s'range);
    signal s1_v_zero      : std_logic;
    signal s1_v_bp1       : std_logic;
    signal s1_v_act1      : std_logic;
    signal s1_v_fp1       : std_logic;
    signal s1_v_mid       : std_logic;
    signal s1_v_bp2       : std_logic;
    signal s1_v_act2      : std_logic;
    signal s1_v_fp2       : std_logic;

    signal s2_rep         : std_logic;
    signal s2_f           : std_logic;
    signal s2_vs          : std_logic;
    signal s2_vblank      : std_logic;
    signal s2_hs          : std_logic;
    signal s2_hblank      : std_logic;
    signal s2_ax          : signed(ax'range);
    signal s2_ay          : signed(ay'range);

begin

    SYNC : component sync_reg
        generic map (
            width           => 72,
            depth           => 2
        )
        port map (
            clk             => clk,
            d(71)           => genlock,
            d(70)           => pix_rep,
            d(69)           => interlace,
            d(68 downto 58) => v_tot,
            d(57 downto 47) => v_act,
            d(46 downto 44) => v_sync,
            d(43 downto 38) => v_bp,
            d(37 downto 26) => h_tot,
            d(25 downto 15) => h_act,
            d(14 downto 8)  => h_sync,
            d(7 downto 0)   => h_bp,
            q(71)           => genlock_s,
            q(70)           => pix_rep_s,
            q(69)           => interlace_s,
            q(68 downto 58) => v_tot_s,
            q(57 downto 47) => v_act_s,
            q(46 downto 44) => v_sync_s,
            q(43 downto 38) => v_bp_s,
            q(37 downto 26) => h_tot_s,
            q(25 downto 15) => h_act_s,
            q(14 downto 8)  => h_sync_s,
            q(7 downto 0)   => h_bp_s
        );

    s1_h_bp         <= '1' when s1_count_h = resize(unsigned(h_sync_s),h_tot_s'length) else '0';
    s1_h_act        <= '1' when s1_count_h = pos_h_act else '0';
    s1_h_mid        <= '1' when s1_count_h = shift_right(unsigned(h_tot_s),1) else '0';
    s1_h_fp         <= '1' when s1_count_h = pos_h_fp else '0';
    s1_v_bp1        <= '1' when s1_count_v = resize(unsigned(v_sync_s),v_tot_s'length) else '0';
    s1_v_act1       <= '1' when s1_count_v = pos_v_act1 else '0';
    s1_v_fp1        <= '1' when s1_count_v = pos_v_fp1 else '0';
    s1_v_mid        <= '1' when s1_count_v = pos_v_mid else '0';
    s1_v_bp2        <= '1' when s1_count_v = pos_v_bp2 else '0';
    s1_v_act2       <= '1' when s1_count_v = pos_v_act2 else '0';
    s1_v_fp2        <= '1' when s1_count_v = pos_v_fp2 else '0';

    process(rst,clk)
    begin
        if rising_edge(clk) then

            genlock_s_1   <= genlock_s;
            genlock_start <= bool2sl(s1_count_h = unsigned(h_tot_s) - 5);
            genlock_end   <= bool2sl(s1_count_h = to_unsigned(0,h_tot_s'length));
            pos_h_act     <= resize(unsigned(h_sync_s),h_tot_s'length) + resize(unsigned(h_bp_s),h_tot_s'length);
            pos_h_fp      <= pos_h_act + unsigned(h_act_s);
            pos_v_act1    <= resize(unsigned(v_sync_s),v_tot_s'length) + resize(unsigned(v_bp_s),v_tot_s'length);
            if interlace_s = '0' then
                pos_v_fp1 <= pos_v_act1 + unsigned(v_act_s);
            else
                pos_v_fp1 <= pos_v_act1 + shift_right(unsigned(v_act_s),1);
            end if;
            pos_v_mid     <= shift_right(unsigned(v_tot_s),1);
            pos_v_bp2     <= pos_v_mid + resize(unsigned(v_sync_s),v_tot_s'length);
            pos_v_act2    <= pos_v_bp2 + resize(unsigned(v_bp_s),v_tot_s'length) + 1;
            pos_v_fp2     <= pos_v_act2 + shift_right(unsigned(v_act_s),1);

            if rst = '1'
            or (genlock_s = '1' and genlock_s_1 = '0' and genlock_window = '0') -- out of lock
            then

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
                f              <= '0';
                vs             <= '0';
                hs             <= '0';
                vblank         <= '1';
                hblank         <= '1';
                ax             <= (others => '0');
                ay             <= (others => '1');

                if (genlock_s = '1' and genlock_s_1 = '0' and genlock_window = '0') then -- out of lock
                    s1_count_v <= pos_v_act1;
                    s1_v_zero  <= '0';
                    s2_vblank  <= '0';
                    vblank     <= '0';
                    s2_ay      <= (others => '1');
                end if;

            else

                if genlock_s = '1' and genlock_s_1 = '0' and genlock_window = '1' then -- in lock
                    genlocked <= '1';
                end if;

                --------------------------------------------------------------------------------
                -- pipeline stage 1

                genlock_window <= genlock_start or (genlock_window and not genlock_end);

                if s1_count_h = unsigned(h_tot_s)-1 then
                    s1_count_h <= (others => '0');
                    s1_h_zero <= '1';
                    if s1_count_v = unsigned(v_tot_s)-1 then
                        s1_count_v <= (others => '0');
                        s1_v_zero <= '1';
                    else
                        s1_count_v <= s1_count_v + 1;
                        s1_v_zero <= '0';
                    end if;
                else
                    s1_count_h <= s1_count_h + 1;
                    s1_h_zero <= '0';
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
                    s2_f <= '0';
                    s2_vs <= '1';
                end if;
                if s1_v_bp1 = '1' and s1_h_zero = '1' then
                   s2_vs <= '0';
                end if;
                if interlace_s = '1' then -- handle field 2
                    if s1_v_mid = '1' and s1_h_mid = '1' then
                        s2_f <= '1';
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
                if interlace_s = '1' then
                    if s1_v_mid = '1' and s1_h_mid = '1' then
                        s2_ay <= shift_left(signed('0' & pos_v_mid)-signed('0' & pos_v_act2),1);
                        s2_ay(0) <= '1';
                    elsif s1_h_zero = '1' then
                        if s1_v_zero = '1' then
                            s2_ay <= shift_left(-signed('0' & pos_v_act1),1);
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

                ax <= std_logic_vector(s2_ax);
                ay <= std_logic_vector(s2_ay);
                f <= s2_f;
                vs <= s2_vs;
                hs <= s2_hs;
                vblank <= s2_vblank;
                hblank <= s2_hblank;

                --------------------------------------------------------------------------------

            end if;

        end if;

    end process;

end architecture synth;
