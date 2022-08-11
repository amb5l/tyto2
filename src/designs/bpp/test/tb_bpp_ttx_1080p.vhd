library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

library work;
use work.tyto_types_pkg.all;
use work.tyto_sim_pkg.all;
use work.model_clk_src_pkg.all;
use work.bpp_conductor_pkg.all;
use work.hd6845_pkg.all;
use work.bpp_overscan_pkg.all;
use work.saa5050d_pkg.all;
use work.bpp_vidproc_pkg.all;
use work.bpp_hdtv_upscale_pkg.all;
use work.video_mode_pkg.all;
use work.video_out_timing_pkg.all;
use work.model_vga_sink_pkg.all;

entity tb_bpp_ttx_1080p is
    generic (
        filename : string
    );
end entity tb_bpp_ttx_1080p;

architecture sim of tb_bpp_ttx_1080p is

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
    signal clken_48m_16m    : std_logic;
    signal clken_48m_12m    : std_logic;
    signal clken_48m_2m_180 : std_logic;
    signal clken_48m_1m_90  : std_logic;
    signal clken_8m_4m      : std_logic;
    signal clken_8m_2m_0    : std_logic;
    signal clken_8m_2m_180  : std_logic;
    signal clken_8m_1m_0    : std_logic;
    signal clken_8m_1m_90   : std_logic;

    signal pix_clk          : std_logic;
    signal pix_rst          : std_logic;
                            
    signal reg_we           : std_logic;
    signal reg_rs           : std_logic;
    signal reg_dw           : std_logic_vector(7 downto 0);
                            
    signal crtc_reg_cs      : std_logic := '0';
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
                            
    signal ttx_chr          : std_logic_vector(7 downto 0);  -- teletext: character code
    signal ttx_oe           : std_logic;                     -- teletext: overscan pixel enable
    signal ttx_pe           : std_logic;                     -- teletext: pixel enable
    signal ttx_pu           : std_logic_vector(2 downto 0);  -- teletext: pixel (3 bit BGR) (12 pixels per character) (upper line)
    signal ttx_pl           : std_logic_vector(2 downto 0);  -- teletext: pixel (3 bit BGR) (12 pixels per character) (lower line)
                            
    signal vidproc_reg_cs   : std_logic := '0';
    signal vidproc_ttx      : std_logic;                     -- VIDPROC: teletext mode
    signal vidproc_clken    : std_logic;                     -- VIDPROC: pixel clock enable (12/16MHz)
    signal vidproc_pe       : std_logic;                     -- VIDPROC: pixel (display) enable
    signal vidproc_p        : std_logic_vector(2 downto 0);  -- VIDPROC: pixel data
    signal vidproc_p2       : std_logic_vector(2 downto 0);  -- VIDPROC: pixel data (2nd line for teletext scan doubling)
                            
    signal mode_clk_sel     : std_logic_vector(1 downto 0);  -- display mode: pixel frequency select
    signal mode_dmt         : std_logic;                     -- display mode: 1 = DMT, 0 = CEA
    signal mode_id          : std_logic_vector(7 downto 0);  -- display mode: DMT ID or CEA/CTA VIC
    signal mode_pix_rep     : std_logic;                     -- display mode: 1 = pixel doubling/repetition
    signal mode_aspect      : std_logic_vector(1 downto 0);  -- display mode: 0x = normal, 10 = force 16:9, 11 = force 4:3
    signal mode_interlace   : std_logic;                     -- display mode: interlaced/progressive scan
    signal mode_v_tot       : std_logic_vector(10 downto 0); -- display mode: vertical total lines (must be odd if interlaced)
    signal mode_v_act       : std_logic_vector(10 downto 0); -- display mode: vertical total lines (must be odd if interlaced)
    signal mode_v_sync      : std_logic_vector(2 downto 0);  -- display mode: vertical sync width
    signal mode_v_bp        : std_logic_vector(5 downto 0);  -- display mode: vertical back porch
    signal mode_h_tot       : std_logic_vector(11 downto 0); -- display mode: horizontal total
    signal mode_h_act       : std_logic_vector(10 downto 0); -- display mode: vertical total lines (must be odd if interlaced)
    signal mode_h_sync      : std_logic_vector(6 downto 0);  -- display mode: horizontal sync width
    signal mode_h_bp        : std_logic_vector(7 downto 0);  -- display mode: horizontal back porch
    signal mode_vs_pol      : std_logic;                     -- display mode: vertical sync polarity (1 = high)
    signal mode_hs_pol      : std_logic;                     -- display mode: horizontal sync polarity (1 = high)
                            
    signal genlock_en       : std_logic;                     -- } genlock logic
    signal genlock_done     : std_logic;                     -- }
    signal genlock          : std_logic;                     -- genlock pulse to VTG
    signal genlocked        : std_logic;                     -- VTG genlock status
                            
    signal vtg_rst          : std_logic;                     -- video timing generator: reset
    signal vtg_vs           : std_logic;                     -- video timing generator: vertical sync
    signal vtg_hs           : std_logic;                     -- video timing generator: horizontal sync
    signal vtg_vblank       : std_logic;                     -- video timing generator: vertical blank
    signal vtg_hblank       : std_logic;                     -- video timing generator: horizontal blank
    signal vtg_de           : std_logic;                     -- video timing generator: display enable
    signal vtg_ax           : std_logic_vector(11 downto 0); -- video timing generator: active area X (signed)
    signal vtg_ay           : std_logic_vector(11 downto 0); -- video timing generator: active area Y (signed)
                            
    signal vga_vs           : std_logic;
    signal vga_hs           : std_logic;
    signal vga_de           : std_logic;
    signal vga_r            : std_logic_vector(7 downto 0);
    signal vga_g            : std_logic_vector(7 downto 0);
    signal vga_b            : std_logic_vector(7 downto 0);
    signal cap_rst          : std_logic;
    signal cap_stb          : std_logic;
    
    signal ttx_data         : uint8_array_t(0 to 1023);

begin

    stim_reset(cap_rst, '1', 500 ns);
    stim_reset(clk_lock, '0', 500 ns);
    stim_reset(pix_rst, '1', 500 ns);
    stim_reset(vtg_rst, '1', 3 ms);

    CLK_SRC_1: component model_clk_src generic map ( n => 1, d =>  96 ) port map ( clk => clk_96m );
    CLK_SRC_2: component model_clk_src generic map ( n => 1, d =>  48 ) port map ( clk => clk_48m );
    CLK_SRC_3: component model_clk_src generic map ( n => 1, d =>  32 ) port map ( clk => clk_32m );
    CLK_SRC_4: component model_clk_src generic map ( n => 1, d =>   8 ) port map ( clk => clk_8m  );
    CLK_SRC_5: component model_clk_src generic map ( n => 2, d => 297 ) port map ( clk => pix_clk );

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
        ttx_data <= read_bin(filename, 1024);
        crtc_rst <= '1';
        reg_we <= '0';
        reg_rs <= '0';
        reg_dw <= (others => '0');
        wait until falling_edge(rst_32m);
        -- set up VIDPROC for teletext output
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
        wait;
    end process;

    CONDUCTOR: component bpp_conductor
        port map (
            clk_lock         => clk_lock,
            clk_96m          => clk_96m,
            clk_48m          => clk_48m,
            clk_32m          => clk_32m,
            clk_8m           => clk_8m,
            rst_96m          => rst_96m,
            rst_48m          => rst_48m,
            rst_32m          => rst_32m,
            rst_8m           => rst_8m,
            clken_48m_16m    => clken_48m_16m,
            clken_48m_12m    => clken_48m_12m,
            clken_48m_2m_180 => clken_48m_2m_180,
            clken_48m_1m_90  => clken_48m_1m_90, 
            clken_8m_4m      => clken_8m_4m,
            clken_8m_2m_0    => clken_8m_2m_0,
            clken_8m_2m_180  => clken_8m_2m_180,
            clken_8m_1m_0    => clken_8m_1m_0,
            clken_8m_1m_90   => clken_8m_1m_90
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

    OVERSCAN: component bpp_overscan
        generic map (
            v_ovr => v_ovr,
            h_ovr => h_ovr
        )
        port map (
            clk   => clk_8m, 
            clken => clken_8m_2m_180,
            rst   => rst_8m,
            f     => crtc_f,
            vs    => crtc_vs,
            hs    => crtc_hs,
            en    => crtc_oe
        );

    process(crtc_rst,crtc_vs,crtc_oe,genlock)
    begin
        if crtc_rst = '1' then
            genlock_en <= '1';
            genlock_done <= '1';
        elsif crtc_vs = '1' then
            genlock_en <= '0';
            genlock_done <= '0';
        else
            if falling_edge(crtc_oe) then
                genlock_en <= '1';
                genlock_done <= genlock_en;
            end if;
        end if;
    end process;
    genlock <= crtc_f and crtc_oe and genlock_en and not genlock_done; -- pulse at beginning of 2nd captured line

    ttx_chr <= std_logic_vector(to_unsigned(ttx_data(to_integer(unsigned(crtc_ma(9 downto 0)))),8));

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
            chr_d     => ttx_chr(6 downto 0),
            pix_clk   => clk_48m,
            pix_clken => clken_48m_12m,
            pix_rst   => rst_48m,
            pix_gp    => ttx_oe,
            pix_de    => ttx_pe,
            pix_du    => ttx_pu,
            pix_dl    => ttx_pl
        );

    VIDPROC: component bpp_vidproc
        port map (
            reg_clk       => clk_32m,
            reg_rst       => rst_32m,
            reg_cs        => vidproc_reg_cs,
            reg_we        => reg_we,
            reg_rs        => reg_rs,
            reg_dw        => reg_dw,
            reg_dr        => open,
            crtc_clken_2m => clken_8m_2m_180,
            crtc_clken_1m => clken_8m_1m_90,
            crtc_clken    => crtc_clken,
            crtc_cur      => crtc_cur,
            crtc_oe       => crtc_oe,
            crtc_de       => '0',             -- } no graphics for now
            crtc_d        => x"00",           -- }
            pix_rst       => rst_48m,
            pix_clk       => clk_48m,
            pix_clken_16m => clken_48m_16m,
            pix_clken_12m => clken_48m_12m,
            pix_clken_2m  => clken_48m_2m_180,
            pix_clken_1m  => clken_48m_1m_90,
            ttx_en        => vidproc_ttx,
            ttx_oe        => ttx_oe,
            ttx_pe        => ttx_pe,
            ttx_pu        => ttx_pu,
            ttx_pl        => ttx_pl,
            out_clken     => vidproc_clken,
            out_pe        => vidproc_pe,
            out_p         => vidproc_p,
            out_p2        => vidproc_p2
        );

    MODE: entity work.video_mode
        port map (
            mode      => MODE_1920x1080p50,
            clk_sel   => mode_clk_sel,
            dmt       => mode_dmt,
            id        => mode_id,
            pix_rep   => mode_pix_rep,
            aspect    => mode_aspect,
            interlace => mode_interlace,
            v_tot     => mode_v_tot,
            v_act     => mode_v_act,
            v_sync    => mode_v_sync,
            v_bp      => mode_v_bp,
            h_tot     => mode_h_tot,
            h_act     => mode_h_act,
            h_sync    => mode_h_sync,
            h_bp      => mode_h_bp,
            vs_pol    => mode_vs_pol,
            hs_pol    => mode_hs_pol
        );

    VTG: component video_out_timing
        port map (
            rst       => vtg_rst,
            clk       => pix_clk,
            pix_rep   => mode_pix_rep,
            interlace => mode_interlace,
            v_tot     => mode_v_tot,
            v_act     => mode_v_act,
            v_sync    => mode_v_sync,
            v_bp      => mode_v_bp,
            h_tot     => mode_h_tot,
            h_act     => mode_h_act,
            h_sync    => mode_h_sync,
            h_bp      => mode_h_bp,
            genlock   => genlock,
            genlocked => genlocked,
            f         => open,
            vs        => vtg_vs,
            hs        => vtg_hs,
            vblank    => vtg_vblank,
            hblank    => vtg_hblank,
            ax        => vtg_ax,
            ay        => vtg_ay
        );

    vtg_de <= not (vtg_vblank or vtg_hblank);

    UPSCALE: component bpp_upscale
        generic map (
            v_ovr => v_ovr,
            h_ovr => h_ovr
        )
        port map (
            in_clk   => clk_48m,
            in_clken => vidproc_clken,
            in_rst   => rst_48m,
            in_ttx   => vidproc_ttx,
            in_vrst  => crtc_vs,
            in_pe    => vidproc_pe,
            in_p     => vidproc_p,
            in_p2    => vidproc_p2,
            out_clk  => pix_clk,
            out_rst  => pix_rst,
            vtg_vs   => vtg_vs,
            vtg_hs   => vtg_hs,
            vtg_de   => vtg_de,
            vtg_ax   => vtg_ax,
            vtg_ay   => vtg_ay,
            vga_vs   => vga_vs,
            vga_hs   => vga_hs,
            vga_de   => vga_de,
            vga_r    => vga_r,
            vga_g    => vga_g,
            vga_b    => vga_b
        );

    CAPTURE: component model_vga_sink
        generic map (
            name    => "tb_bpp_ttx_1080p"
        )
        port map (
            vga_rst => pix_rst,
            vga_clk => pix_clk,
            vga_vs  => vga_vs,
            vga_hs  => vga_hs,
            vga_de  => vga_de,
            vga_r   => vga_r,
            vga_g   => vga_g,
            vga_b   => vga_b,
            cap_rst => cap_rst,
            cap_stb => cap_stb
        );

end architecture sim;
