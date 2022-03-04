--------------------------------------------------------------------------------
-- np6532_poc_128k_altera_c5e_dev.vhd                                         --
-- Altera Cyclone V E Dev Kit wrapper for the np6532_poc design (128k).       --
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
use work.np6532_poc_pkg.all;

entity np6532_poc_128k_altera_c5e_dev is
    generic (
        success_addr  : integer
    );
    port (

        -- clocks

        clkin_50_top      : in    std_logic;
        clkin_50_right    : in    std_logic;
        clkin_top_125     : in    std_logic;
        clkin_bot_125     : in    std_logic;
        clkout_sma        : out   std_logic;

        -- simple I/O

        user_dipsw        : in    std_logic_vector(3 downto 0);
        user_pb           : in    std_logic_vector(3 downto 0);
        user_led          : out   std_logic_vector(3 downto 0);
        dipsw2_4          : in    std_logic;

        uart_rxd          : in    std_logic;
        uart_txd          : out   std_logic;
        uart_rts          : in    std_logic;
        uart_cts          : out   std_logic;
        uart_rxd_led      : out   std_logic;
        uart_txd_led      : out   std_logic;

        usb_uart_rstn     : out   std_logic;
        usb_uart_rxd      : in    std_logic;
        usb_uart_txd      : out   std_logic;
        usb_uart_rts      : in    std_logic;
        usb_uart_cts      : out   std_logic;
        usb_uart_dtr      : in    std_logic;
        usb_uart_dcd      : out   std_logic;
        usb_uart_dsr      : out   std_logic;
        usb_uart_ri       : out   std_logic;
        usb_uart_gpio2    : in    std_logic;
        usb_uart_suspend  : in    std_logic;
        usb_uart_suspendn : in    std_logic;

        lcd_csn           : out   std_logic;
        lcd_d_cn          : out   std_logic;
        lcd_wen           : out   std_logic;
        lcd_data          : inout std_logic_vector(7 downto 0);

        eeprom_scl        : out   std_logic;
        eeprom_sda        : inout std_logic;

        -- DDR3

        ddr3_resetn       : out   std_logic;
        ddr3_clk_p        : out   std_logic;
        ddr3_clk_n        : out   std_logic;
        ddr3_cke          : out   std_logic;
        ddr3_csn          : out   std_logic;
        ddr3_rasn         : out   std_logic;
        ddr3_casn         : out   std_logic;
        ddr3_wen          : out   std_logic;
        ddr3_odt          : out   std_logic;
        ddr3_a            : out   std_logic_vector(13 downto 0);
        ddr3_ba           : out   std_logic_vector(2 downto 0);
        ddr3_dm           : out   std_logic_vector(3 downto 0);
        ddr3_dq           : inout std_logic_vector(31 downto 0);
        ddr3_dqs_p        : inout std_logic_vector(3 downto 0);
        ddr3_dqs_n        : inout std_logic_vector(3 downto 0);

        -- LPDDR2

        lpddr2_ck         : out   std_logic;
        lpddr2_ckn        : out   std_logic;
        lpddr2_cke        : out   std_logic;
        lpddr2_csn        : out   std_logic;
        lpddr2_ca         : out   std_logic_vector(9 downto 0);
        lpddr2_dm         : out   std_logic_vector(1 downto 0);
        lpddr2_dqs        : inout std_logic_vector(1 downto 0);
        lpddr2_dqsn       : inout std_logic_vector(1 downto 0);
        lpddr2_dq         : inout std_logic_vector(15 downto 0);

        -- flash and SRAM

        fsm_a             : out   std_logic_vector(26 downto 1);
        fsm_d             : inout std_logic_vector(15 downto 0);

        flash_resetn      : out   std_logic;
        flash_clk         : out   std_logic;
        flash_cen         : out   std_logic;
        flash_oen         : out   std_logic;
        flash_wen         : out   std_logic;
        flash_advn        : out   std_logic;
        flash_rdybsyn     : in    std_logic;

        sram_clk          : out   std_logic;
        sram_cen          : out   std_logic;
        sram_oen          : out   std_logic;
        sram_wen          : out   std_logic;
        sram_bwan         : out   std_logic;
        sram_bwbn         : out   std_logic;
        sram_advn         : out   std_logic;
        sram_adscn        : out   std_logic;
        sram_adspn        : out   std_logic;
        sram_zz           : out   std_logic;

        -- ethernet PHY A

        eneta_resetn      : out   std_logic;
        eneta_mdc         : out   std_logic;
        eneta_mdio        : inout std_logic;
        eneta_intn        : in    std_logic;
        eneta_gtx_clk     : out   std_logic;
        eneta_rx_clk      : in    std_logic;
        eneta_rx_crs      : in    std_logic;
        eneta_rx_col      : in    std_logic;
        eneta_rx_dv       : in    std_logic;
        eneta_rx_er       : in    std_logic;
        eneta_rx_d        : in    std_logic_vector(3 downto 0);
        eneta_tx_clk      : out   std_logic;
        eneta_tx_en       : out   std_logic;
        eneta_tx_er       : out   std_logic;
        eneta_tx_d        : out   std_logic_vector(3 downto 0);

        -- ethernet PHY B

        enetb_resetn      : out   std_logic;
        enetb_mdc         : out   std_logic;
        enetb_mdio        : inout std_logic;
        enetb_intn        : in    std_logic;
        enetb_gtx_clk     : out   std_logic;
        enetb_rx_clk      : in    std_logic;
        enetb_rx_crs      : in    std_logic;
        enetb_rx_col      : in    std_logic;
        enetb_rx_dv       : in    std_logic;
        enetb_rx_er       : in    std_logic;
        enetb_rx_d        : in    std_logic_vector(3 downto 0);
        enetb_tx_clk      : out   std_logic;
        enetb_tx_en       : out   std_logic;
        enetb_tx_er       : out   std_logic;
        enetb_tx_d        : out   std_logic_vector(3 downto 0);

        -- I/O connectors

        header_d          : inout std_logic_vector(7 downto 0);

        header_p          : inout std_logic_vector(5 downto 0);
        header_n          : inout std_logic_vector(5 downto 0);

        hsmc_prsntn       : in    std_logic;
        hsmc_scl          : out   std_logic;
        hsmc_sda          : inout std_logic;
        hsmc_d            : inout std_logic_vector(3 downto 0);
        hsmc_clk_in       : in    std_logic_vector(0 to 2);
        hsmc_clk_out      : out   std_logic_vector(0 to 2);
        hsmc_rx_d         : in    std_logic_vector(16 downto 0);
        hsmc_rx_led       : out   std_logic;
        hsmc_tx_d         : out   std_logic_vector(16 downto 0);
        hsmc_tx_led       : out   std_logic;

        -- USB Blaster

        fx2_resetn        : in    std_logic;
        usb_resetn        : in    std_logic;
        usb_clk           : in    std_logic;
        usb_oen           : in    std_logic;
        usb_wrn           : in    std_logic;
        usb_rdn           : in    std_logic;
        usb_addr          : inout std_logic_vector(1 downto 0);
        usb_data          : inout std_logic_vector(7 downto 0);
        usb_empty         : out   std_logic;
        usb_full          : out   std_logic;
        usb_scl           : in    std_logic;
        usb_sda           : inout std_logic;

        -- MAX5

        max5_clk          : in    std_logic;
        max5_csn          : in    std_logic;
        max5_oen          : in    std_logic;
        max5_wen          : in    std_logic;
        max5_ben          : in    std_logic_vector(3 downto 0);
        max5_rsvd         : inout std_logic_vector(3 downto 0)

    );
end entity np6532_poc_128k_altera_c5e_dev;

architecture synth of np6532_poc_128k_altera_c5e_dev is

    signal rst_ref    : std_logic;
    signal clk_cpu    : std_logic;
    signal clk_mem    : std_logic;
    signal locked     : std_logic;
    signal locked_1   : std_logic;
    signal rst        : std_logic;
    signal hold       : std_logic;
    signal irq        : std_logic;
    signal nmi        : std_logic;
    signal dma_ti     : std_logic_vector(5 downto 0);
    signal dma_to     : std_logic_vector(7 downto 0);
    signal led_user   : std_logic_vector(7 downto 0);

begin

    rst_ref <= not user_pb(0);

    CLOCK: entity work.pll_otus_50m_96m_32m
        port map (
            refclk   => clkin_50_top,
            rst      => rst_ref,
            outclk_0 => open,    -- 48MHz
            outclk_1 => open,    -- 8MHz
            outclk_2 => clk_mem, -- 96MHz
            outclk_3 => clk_cpu, -- 32MHz
            locked   => locked
        );

    process(rst_ref, locked, clk_mem)
    begin
        if rst_ref = '1' or locked = '0' then
            locked_1 <= '0';
            rst <= '1';
        elsif rising_edge(clk_mem) then
            locked_1 <= locked;
            rst <=  not locked_1;
        end if;
    end process;

    clkout_sma <= clk_cpu;

    -- system

    SYS: component np6532_poc
        generic map (
            clk_ratio     => 3,
            ram_size_log2 => 17, -- 128k
            success_addr  => success_addr
        )
        port map (
            rsta    => rst,
            clk_cpu => clk_cpu,
            clk_mem => clk_mem,
            hold    => hold,
            irq     => irq,
            nmi     => nmi,
            dma_ti  => dma_ti,
            dma_to  => dma_to,
            led     => led_user
        );

    -- I/O

    hold <= not user_pb(1);
    irq <= not user_pb(2);
    nmi <= not user_pb(3);
    dma_ti <= not header_p(5 downto 0);
    header_d <= dma_to;
    user_led <= not led_user(3 downto 0);

    -- unused outputs

    uart_txd      <= '1';
    uart_cts      <= '1';
    uart_rxd_led  <= '1';
    uart_txd_led  <= '1';
    usb_uart_rstn <= '1';
    usb_uart_txd  <= '1';
    usb_uart_cts  <= '1';
    usb_uart_dcd  <= '1';
    usb_uart_dsr  <= '1';
    usb_uart_ri   <= '1';
    lcd_csn       <= '1';
    lcd_d_cn      <= '1';
    lcd_wen       <= '1';
    eeprom_scl    <= '1';
    ddr3_resetn   <= '0';
    ddr3_clk_p    <= '0';
    ddr3_clk_n    <= '1';
    ddr3_cke      <= '0';
    ddr3_csn      <= '1';
    ddr3_rasn     <= '1';
    ddr3_casn     <= '1';
    ddr3_wen      <= '1';
    ddr3_odt      <= '0';
    ddr3_a        <= (others => '0');
    ddr3_ba       <= (others => '0');
    ddr3_dm       <= (others => '0');
    lpddr2_ck     <= '0';
    lpddr2_ckn    <= '1';
    lpddr2_cke    <= '0';
    lpddr2_csn    <= '1';
    lpddr2_ca     <= (others => '0');
    lpddr2_dm     <= (others => '0');
    fsm_a         <= (others => '0');
    flash_resetn  <= '1';
    flash_clk     <= '0';
    flash_cen     <= '1';
    flash_oen     <= '1';
    flash_wen     <= '1';
    flash_advn    <= '1';
    sram_clk      <= '0';
    sram_cen      <= '1';
    sram_oen      <= '1';
    sram_wen      <= '1';
    sram_bwan     <= '1';
    sram_bwbn     <= '1';
    sram_advn     <= '1';
    sram_adscn    <= '1';
    sram_adspn    <= '1';
    sram_zz       <= '1';
    eneta_resetn  <= '0';
    eneta_mdc     <= '1';
    eneta_gtx_clk <= '0';
    eneta_tx_clk  <= '0';
    eneta_tx_en   <= '0';
    eneta_tx_er   <= '0';
    eneta_tx_d    <= (others => '0');
    enetb_resetn  <= '0';
    enetb_mdc     <= '1';
    enetb_gtx_clk <= '0';
    enetb_tx_clk  <= '0';
    enetb_tx_en   <= '0';
    enetb_tx_er   <= '0';
    enetb_tx_d    <= (others => '0');
    hsmc_scl      <= '1';
    hsmc_clk_out  <= (others => '0');
    hsmc_rx_led   <= '1';
    hsmc_tx_d     <= (others => '0');
    hsmc_tx_led   <= '1';
    usb_empty     <= '1';
    usb_full      <= '0';

end architecture synth;
