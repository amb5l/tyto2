library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.finish;

library work;
use work.tyto_types_pkg.all;
use work.tyto_sim_pkg.all;
use work.model_clk_src_pkg.all;
use work.bpp_conductor_pkg.all;
use work.hd6845_pkg.all;
use work.bpp_overscan_pkg.all;
use work.saa5050d_pkg.all;
use work.bpp_vidproc_pkg.all;
use work.bpp_hdtv_pkg.all;
use work.video_mode_pkg.all;
use work.video_out_timing_pkg.all;
use work.model_vga_sink_pkg.all;

entity tb_bpp_hdtv is
    generic (
        mode7_binfile : string;
        mode2_binfile : string
    );
end entity tb_bpp_hdtv;

architecture sim of tb_bpp_hdtv is

    constant v_ovr : integer := 7;
    constant h_ovr : integer := 1;

    signal clk_lock         : std_logic;
    signal clk_96m          : std_logic;
    signal clk_48m          : std_logic;
    signal clk_32m          : std_logic;
    signal clk_8m           : std_logic;
    signal rst_96m          : std_logic;
    signal rst_48m          : std_logic;
    signal rst_32m          : std_logic;
    signal rst_8m           : std_logic;
    signal clken_96m_8m     : std_logic;
    signal clken_48m_16m    : std_logic;
    signal clken_48m_12m    : std_logic;
    signal clken_48m_8m     : std_logic;
    signal clken_8m_4m      : std_logic;
    signal clken_8m_2m_0    : std_logic;
    signal clken_8m_2m_180  : std_logic;
    signal clken_8m_2m_270  : std_logic;
    signal clken_8m_1m_0    : std_logic;
    signal clken_8m_1m_90   : std_logic;

    signal clk_148m5        : std_logic;
    signal clk_74m25        : std_logic;
    signal clk_27m          : std_logic;

    signal reg_we           : std_logic;
    signal reg_rs           : std_logic;
    signal reg_dw           : std_logic_vector(7 downto 0);

    signal crtc_reg_cs      : std_logic := '0';
    signal crtc_clksel      : std_logic;
    signal crtc_clken       : std_logic;
    signal crtc_rst         : std_logic;
    signal crtc_f           : std_logic;                     -- CRTC: field ID
    signal crtc_ma          : std_logic_vector(13 downto 0); -- CRTC: memory address
    signal crtc_ra          : std_logic_vector(4 downto 0);  -- CRTC: raster (scan line) address within character
    signal crtc_vs          : std_logic;                     -- CRTC: vertical sync
    signal crtc_hs          : std_logic;                     -- CRTC: horizontal blank
    signal crtc_vb          : std_logic;                     -- CRTC: vertical blank
    signal crtc_hb          : std_logic;                     -- CRTC: horizontal sync
    signal crtc_de          : std_logic;                     -- CRTC: display enable
    signal crtc_cur         : std_logic;                     -- CRTC: cursor

    signal crtc_oe          : std_logic;                     -- CRTC: overscan display enable

    signal crtc_d           : std_logic_vector(7 downto 0);  -- CRTC: data from memory

    signal ttx_oe           : std_logic;                     -- teletext: overscan pixel enable
    signal ttx_pe           : std_logic;                     -- teletext: pixel enable
    signal ttx_p1           : std_logic_vector(2 downto 0);  -- teletext: pixel (3 bit BGR) (12 pixels per character) (upper line)
    signal ttx_p2           : std_logic_vector(2 downto 0);  -- teletext: pixel (3 bit BGR) (12 pixels per character) (lower line)

    signal vidproc_reg_cs   : std_logic := '0';
    signal vidproc_ttx      : std_logic;                     -- VIDPROC: teletext mode
    signal vidproc_clken    : std_logic;                     -- VIDPROC: pixel clock enable (12/16MHz)
    signal vidproc_pe       : std_logic;                     -- VIDPROC: pixel (display) enable
    signal vidproc_p        : std_logic_vector(2 downto 0);  -- VIDPROC: pixel data
    signal vidproc_p2       : std_logic_vector(2 downto 0);  -- VIDPROC: pixel data (2nd line for teletext scan doubling)

    signal hdtv_mode        : std_logic_vector(2 downto 0);
    signal hdtv_mode_clksel : std_logic_vector(1 downto 0);

    signal hdtv_clk         : std_logic;                     -- HDTV: clock
    signal hdtv_rst         : std_logic;                     -- HDTV: reset
    signal hdtv_vs          : std_logic;                     -- HDTV: vertical sync
    signal hdtv_hs          : std_logic;                     -- HDTV: horizontal sync
    signal hdtv_de          : std_logic;                     -- HDTV: display enable
    signal hdtv_r           : std_logic_vector(7 downto 0);  -- HDTV: red (0-255)
    signal hdtv_g           : std_logic_vector(7 downto 0);  -- HDTV: green (0-255)
    signal hdtv_b           : std_logic_vector(7 downto 0);  -- HDTV: blue (0-255)
    signal hdtv_lock        : std_logic;                     -- HDTV: genlock status

    signal cap_name         : string(1 to 5);
    signal cap_rst          : std_logic;
    signal cap_stb          : std_logic;

    signal mode7_data       : uint8_array_t(0 to 1023);
    signal mode2_data       : uint8_array_t(0 to 20479);
    
begin

    CLK_SRC_1: component model_clk_src generic map ( pn => 1, pd =>  96 ) port map ( clk => clk_96m );
    CLK_SRC_2: component model_clk_src generic map ( pn => 1, pd =>  48 ) port map ( clk => clk_48m );
    CLK_SRC_3: component model_clk_src generic map ( pn => 1, pd =>  32 ) port map ( clk => clk_32m );
    CLK_SRC_4: component model_clk_src generic map ( pn => 1, pd =>   8 ) port map ( clk => clk_8m  );
    CLK_SRC_5: component model_clk_src generic map ( pn => 2, pd => 297 ) port map ( clk => clk_148m5 );
    CLK_SRC_6: component model_clk_src generic map ( pn => 4, pd => 297 ) port map ( clk => clk_74m25 );
    CLK_SRC_7: component model_clk_src generic map ( pn => 1, pd =>  27 ) port map ( clk => clk_27m );

    hdtv_mode <= HDTV_MODE_1080i;
    with hdtv_mode_clksel select hdtv_clk <= 
        clk_148m5 when "11",
        clk_74m25 when "10",
        clk_27m when others;

    -- main test process
    process
        procedure vidproc_poke_reg(
            constant a     : in  std_logic_vector(7 downto 0);
            constant d     : in  std_logic_vector(7 downto 0);
            signal   clk   : in  std_logic;
            signal   cs    : out std_logic;
            signal   we    : out std_logic;
            signal   rs    : out std_logic;
            signal   wdata : out std_logic_vector(7 downto 0)
        ) is
        begin
            if clk = '1' then
                wait until falling_edge(clk);
            end if;
            cs <= '1';
            we <= '1';
            rs <= a(0);
            wdata <= d;
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            cs <= '0';
            we <= '0';
            rs <= '0';
            wdata <= x"00";
        end procedure vidproc_poke_reg;
        procedure crtc_poke_reg(
            constant a     : in  std_logic_vector(7 downto 0);
            constant d     : in  std_logic_vector(7 downto 0);
            signal   clk   : in  std_logic;
            signal   cs    : out std_logic;
            signal   we    : out std_logic;
            signal   rs    : out std_logic;
            signal   wdata : out std_logic_vector(7 downto 0)
        ) is
        begin
            if clk = '1' then
                wait until falling_edge(clk);
            end if;
            cs <= '1';
            we <= '1';
            rs <= '0';
            wdata <= a;
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            rs <= '1';
            wdata <= d;
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            cs <= '0';
            we <= '0';
            rs <= '0';
            wdata <= x"00";
        end procedure crtc_poke_reg;
    begin

        mode7_data <= read_bin(mode7_binfile, 1024);
        mode2_data <= read_bin(mode2_binfile, 20480);
        reg_we <= '0';
        reg_rs <= '0';
        reg_dw <= (others => '0');

        cap_name <= "mode7";
        clk_lock <= '0'; hdtv_rst <= '1'; crtc_rst <= '1'; cap_rst <= '1';
        wait for 1 us;
        clk_lock <= '1'; hdtv_rst <= '0'; cap_rst <= '0';
        wait for 1 us;
        -- set up VIDPROC for teletext
        vidproc_poke_reg( x"00", x"4B", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw);
        -- set up CRTC for teletext display timing
        crtc_poke_reg( x"00", x"3F", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"01", x"28", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"02", x"33", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"03", x"24", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"04", x"1E", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"05", x"02", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"06", x"19", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"07", x"1B", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"08", x"93", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"09", x"12", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0A", x"72", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0B", x"13", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0C", x"20", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0D", x"00", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_reg_cs <= '0';
        wait until falling_edge(crtc_clken);
        crtc_rst <= '0';
        wait until rising_edge(cap_stb);

        cap_name <= "mode2";
        clk_lock <= '0'; hdtv_rst <= '1'; crtc_rst <= '1'; cap_rst <= '1';
        wait for 1 us;
        clk_lock <= '1'; hdtv_rst <= '0'; cap_rst <= '0';
        wait for 1 us;
        -- set up VIDPROC for mode 2
        vidproc_poke_reg( x"00", x"F4", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw);
        -- Snapper Palette
        vidproc_poke_reg( x"01", x"07", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 0 = black
        vidproc_poke_reg( x"01", x"16", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 1 = red
        vidproc_poke_reg( x"01", x"25", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 2 = green
        vidproc_poke_reg( x"01", x"34", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 3 = yellow
        vidproc_poke_reg( x"01", x"43", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 4 = blue
        vidproc_poke_reg( x"01", x"52", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 5 = magenta
        vidproc_poke_reg( x"01", x"65", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 6 = flashing green (power pills)
        vidproc_poke_reg( x"01", x"70", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 7 = white (score etc)
        vidproc_poke_reg( x"01", x"83", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 8 = blue (maze)
        vidproc_poke_reg( x"01", x"97", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- 9 = black (barrier to ghost base)
        vidproc_poke_reg( x"01", x"A3", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- A = blue (ghost eyes)
        vidproc_poke_reg( x"01", x"B0", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- B = white (ghost eyes)
        vidproc_poke_reg( x"01", x"C6", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- C = red (debug)
        vidproc_poke_reg( x"01", x"D2", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- D = magenta (ghost base gate)
        vidproc_poke_reg( x"01", x"E1", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- E = cyan (ghost)
        vidproc_poke_reg( x"01", x"F5", clk_32m, vidproc_reg_cs, reg_we, reg_rs, reg_dw); -- F = green (ghost)
        -- set up CRTC for modes 0..2
        crtc_poke_reg( x"00", x"7F", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"01", x"50", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"02", x"62", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"03", x"28", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"04", x"26", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"05", x"00", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"06", x"20", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"07", x"22", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"08", x"01", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"09", x"07", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0A", x"67", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0B", x"08", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0C", x"00", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_poke_reg( x"0D", x"00", clk_32m, crtc_reg_cs, reg_we, reg_rs, reg_dw);
        crtc_reg_cs <= '0';
        wait until falling_edge(crtc_clken);
        crtc_rst <= '0';
        wait until rising_edge(cap_stb);

        finish;

    end process;

    CONDUCTOR: component bpp_conductor
        port map (
            clk_lock        => clk_lock,
            clk_96m         => clk_96m,
            clk_48m         => clk_48m,
            clk_32m         => clk_32m,
            clk_8m          => clk_8m,
            rst_96m         => rst_96m,
            rst_48m         => rst_48m,
            rst_32m         => rst_32m,
            rst_8m          => rst_8m,
            clken_96m_8m    => clken_96m_8m,
            clken_48m_16m   => clken_48m_16m,
            clken_48m_12m   => clken_48m_12m,
            clken_48m_8m    => clken_48m_8m,
            clken_8m_4m     => clken_8m_4m,
            clken_8m_2m_0   => clken_8m_2m_0,
            clken_8m_2m_180 => clken_8m_2m_180,
            clken_8m_2m_270 => clken_8m_2m_270,
            clken_8m_1m_0   => clken_8m_1m_0,
            clken_8m_1m_90  => clken_8m_1m_90
        );

    CRTC: component hd6845
        generic map (
            rst_f     => '1',
            rst_v     => to_unsigned(25,7)
        )
        port map (
            reg_clk   => clk_32m,
            reg_clken => '1',
            reg_rst   => rst_32m,
            reg_cs    => crtc_reg_cs,
            reg_we    => reg_we,
            reg_rs    => reg_rs,
            reg_dw    => reg_dw,
            reg_dr    => open,
            crt_clk   => clk_8m,
            crt_clken => crtc_clken,
            crt_rst   => crtc_rst,
            crt_ma    => crtc_ma,
            crt_ra    => crtc_ra,
            crt_f     => crtc_f,
            crt_vs    => crtc_vs,
            crt_hs    => crtc_hs,
            crt_vb    => crtc_vb,
            crt_hb    => crtc_hb,
            crt_de    => open,
            crt_cur   => crtc_cur,
            crt_lps   => '0'
        );

    crtc_de <= not (crtc_vb or crtc_hb);

    process(cap_name, crtc_ma, crtc_ra)
        variable ma : integer range 0 to 16383;
        variable ra : integer range 0 to 7;
        variable a : integer range 0 to 20479;
    begin
        ma := to_integer(unsigned(crtc_ma));
        ra := to_integer(unsigned(crtc_ra));
        if cap_name = "mode2" then
            a := (ra+(8*ma)) mod 20480;
            crtc_d <= std_logic_vector(to_unsigned(mode2_data(a),8));
        else -- mode7
            a := ma mod 1024;
            crtc_d <= std_logic_vector(to_unsigned(mode7_data(a),8));
        end if;
    end process;

    TELETEXT: component saa5050d
        port map (
            rsta      => '0',
            debug     => '0',
            chr_clk   => clk_8m,
            chr_clken => crtc_clken,
            chr_rst   => crtc_rst,
            chr_f     => crtc_ra(0),
            chr_vs    => crtc_vs,
            chr_hs    => crtc_hs,
            chr_gp    => crtc_oe,
            chr_de    => crtc_de,
            chr_d     => crtc_d(6 downto 0),
            pix_clk   => clk_48m,
            pix_clken => clken_48m_12m,
            pix_rst   => rst_48m,
            pix_gp    => ttx_oe,
            pix_de    => ttx_pe,
            pix_d1    => ttx_p1,
            pix_d2    => ttx_p2
        );

    VIDPROC: component bpp_vidproc
        port map (
            clk_48m         => clk_48m,
            clk_32m         => clk_32m,
            clk_8m          => clk_8m,
            rst_48m         => rst_48m,
            rst_32m         => rst_32m,
            rst_8m          => rst_8m,
            clken_48m_16m   => clken_48m_16m,
            clken_48m_12m   => clken_48m_12m,
            clken_48m_8m    => clken_48m_8m,
            clken_8m_4m     => clken_8m_4m,
            clken_8m_2m_0   => clken_8m_2m_0,
            clken_8m_2m_180 => clken_8m_2m_180,
            clken_8m_1m_90  => clken_8m_1m_90,
            reg_cs          => vidproc_reg_cs,
            reg_we          => reg_we,
            reg_rs          => reg_rs,
            reg_dw          => reg_dw,
            crtc_clksel     => crtc_clksel,
            crtc_clken      => crtc_clken,
            crtc_cur        => crtc_cur,
            crtc_oe         => crtc_oe,
            crtc_de         => crtc_de,
            crtc_d          => crtc_d,
            ttx_en          => vidproc_ttx,
            ttx_oe          => ttx_oe,
            ttx_pe          => ttx_pe,
            ttx_p1          => ttx_p1,
            ttx_p2          => ttx_p2,
            out_clken       => vidproc_clken,
            out_pe          => vidproc_pe,
            out_p           => vidproc_p,
            out_p2          => vidproc_p2
        );

    HDTV: component bpp_hdtv
        port map (
            crtc_clk         => clk_8m,
            crtc_clken       => crtc_clken,
            crtc_rst         => crtc_rst,
            crtc_clksel      => crtc_clksel,
            crtc_f           => crtc_f,
            crtc_vs          => crtc_vs,
            crtc_hs          => crtc_hs,
            crtc_de          => crtc_de,
            crtc_oe          => crtc_oe,
            vidproc_clk      => clk_48m,
            vidproc_clken    => vidproc_clken,
            vidproc_rst      => rst_48m,
            vidproc_ttx      => vidproc_ttx,
            vidproc_pe       => vidproc_pe,
            vidproc_p        => vidproc_p,
            vidproc_p2       => vidproc_p2,
            hdtv_mode        => hdtv_mode,
            hdtv_mode_clksel => hdtv_mode_clksel,
            hdtv_mode_vic    => open,
            hdtv_mode_pixrep => open,
            hdtv_mode_aspect => open,
            hdtv_mode_vs_pol => open,
            hdtv_mode_hs_pol => open,
            hdtv_clk         => hdtv_clk,
            hdtv_rst         => hdtv_rst,
            hdtv_vs          => hdtv_vs,
            hdtv_hs          => hdtv_hs,
            hdtv_de          => hdtv_de,
            hdtv_r           => hdtv_r,
            hdtv_g           => hdtv_g,
            hdtv_b           => hdtv_b,
            hdtv_lock        => hdtv_lock
        );

    CAPTURE: component model_vga_sink
        port map (
            vga_rst  => hdtv_rst,
            vga_clk  => hdtv_clk,
            vga_vs   => hdtv_vs,
            vga_hs   => hdtv_hs,
            vga_de   => hdtv_de,
            vga_r    => hdtv_r,
            vga_g    => hdtv_g,
            vga_b    => hdtv_b,
            cap_rst  => cap_rst,
            cap_stb  => cap_stb,
            cap_name => cap_name
        );

end architecture sim;
