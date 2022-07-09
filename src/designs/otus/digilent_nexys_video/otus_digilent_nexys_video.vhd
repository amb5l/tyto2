--------------------------------------------------------------------------------
-- otus_digilent_nexys_video.vhd                                              --
-- Digilent Nexys Video board wrapper for the otus design.                    --
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
use work.mmcm_pkg.all;

entity np6532_poc_128k_digilent_nexys_video is
    generic (
            success_addr  : integer
    );
    port (

        -- clocks
        clki_100m       : in    std_logic;
--      gtp_clk_p       : in    std_logic;
--      gtp_clk_n       : in    std_logic;
--      fmc_mgt_clk_p   : in    std_logic;
--      fmc_mgt_clk_n   : in    std_logic;

        -- LEDs, buttons and switches
        led             : out   std_logic_vector(7 downto 0);
--      btn_c           : in    std_logic;
--      btn_d           : in    std_logic;
--      btn_l           : in    std_logic;
--      btn_r           : in    std_logic;
--      btn_u           : in    std_logic;
        btn_rst_n       : in    std_logic;
--      sw              : in    std_logic_vector(7 downto 0);

        -- OLED
        oled_res_n      : out   std_logic;
        oled_d_c        : out   std_logic;
        oled_sclk       : out   std_logic;
        oled_sdin       : out   std_logic;
--      oled_vbat_dis   : out   std_logic;
--      oled_vdd_dis    : out   std_logic;

        -- HDMI RX
--      hdmi_rx_clk_p   : in    std_logic;
--      hdmi_rx_clk_n   : in    std_logic;
--      hdmi_rx_d_p     : in    std_logic_vector(0 to 2);
--      hdmi_rx_d_n     : in    std_logic_vector(0 to 2);
--      hdmi_rx_sda     : inout std_logic;
--      hdmi_rx_cec     : in    std_logic;
--      hdmi_rx_hpd     : out   std_logic;
--      hdmi_rx_txen    : out   std_logic;
--      hdmi_rx_scl     : in    std_logic;

        -- HDMI TX
--      hdmi_tx_clk_p   : out   std_logic;
--      hdmi_tx_clk_n   : out   std_logic;
--      hdmi_tx_d_p     : out   std_logic_vector(0 to 2);
--      hdmi_tx_d_n     : out   std_logic_vector(0 to 2);
--      hdmi_tx_scl     : out   std_logic;
--      hdmi_tx_sda     : inout std_logic;
--      hdmi_tx_cec     : out   std_logic;
--      hdmi_tx_hpd     : in    std_logic;

        -- DisplayPort
--      dp_tx_p         : out   std_logic_vector(0 to 1);
--      dp_tx_n         : out   std_logic_vector(0 to 1);
--      dp_tx_aux_p     : inout std_logic;
--      dp_tx_aux_n     : inout std_logic;
--      dp_tx_aux2_p    : inout std_logic;
--      dp_tx_aux2_n    : inout std_logic;
--      dp_tx_hpd       : in    std_logic;

        -- audio codec
        ac_mclk         : out   std_logic;
--      ac_lrclk        : out   std_logic;
--      ac_bclk         : out   std_logic;
        ac_dac_sdata    : out   std_logic;
--      ac_adc_sdata    : in    std_logic;

        -- PMODs
        ja              : in    std_logic_vector(7 downto 0);
        jb              : in    std_logic_vector(7 downto 0);
        jc              : out   std_logic_vector(7 downto 0);
--      xa_p            : inout std_logic_vector(3 downto 0);
--      xa_n            : inout std_logic_vector(3 downto 0);

        -- UART
        uart_rx_out     : out   std_logic;
--      uart_tx_in      : in    std_logic;

        -- ethernet
        eth_rst_n       : out   std_logic;
--      eth_txck        : out   std_logic;
--      eth_txctl       : out   std_logic;
--      eth_txd         : out   std_logic_vector(3 downto 0);
--      eth_rxck        : in    std_logic;
--      eth_rxctl       : in    std_logic;
--      eth_rxd         : in    std_logic_vector(3 downto 0);
--      eth_mdc         : out   std_logic;
--      eth_mdio        : inout std_logic;
--      eth_int_n       : in    std_logic;
--      eth_pme_n       : in    std_logic;

        -- fan
--      fan_pwm         : out   std_logic;

        -- FTDI
--      ftdi_clko       : in    std_logic;
--      ftdi_rxf_n      : in    std_logic;
--      ftdi_txe_n      : in    std_logic;
        ftdi_rd_n       : out   std_logic;
        ftdi_wr_n       : out   std_logic;
        ftdi_siwu_n     : out   std_logic;
        ftdi_oe_n       : out   std_logic;
--      ftdi_d          : inout std_logic_vector(7 downto 0);
--      ftdi_spien      : out   std_logic;

        -- PS/2
        ps2_clk         : inout std_logic;
        ps2_data        : inout std_logic;

        -- QSPI
        qspi_cs_n       : out   std_logic;
--      qspi_dq         : inout std_logic_vector(3 downto 0);

        -- SD
--      sd_reset        : out   std_logic;
--      sd_cclk         : out   std_logic;
--      sd_cmd          : out   std_logic;
--      sd_d            : inout std_logic_vector(3 downto 0);
--      sd_cd           : in    std_logic;

        -- I2C
--      i2c_scl         : inout std_logic;
--      i2c_sda         : inout std_logic;

        -- VADJ
--      set_vadj        : out   std_logic_vector(1 downto 0);
--      vadj_en         : out   std_logic;

        -- FMC
--      fmc_clk0_m2c_p  : in    std_logic;
--      fmc_clk0_m2c_n  : in    std_logic;
--      fmc_clk1_m2c_p  : in    std_logic;
--      fmc_clk1_m2c_n  : in    std_logic;
--      fmc_la_p        : inout std_logic_vector(33 downto 0);
--      fmc_la_n        : inout std_logic_vector(33 downto 0);

        -- DDR3
        ddr3_reset_n    : out   std_logic
--      ddr3_ck_p       : out   std_logic_vector(0 downto 0);
--      ddr3_ck_n       : out   std_logic_vector(0 downto 0);
--      ddr3_cke        : out   std_logic_vector(0 downto 0);
--      ddr3_ras_n      : out   std_logic;
--      ddr3_cas_n      : out   std_logic;
--      ddr3_we_n       : out   std_logic;
--      ddr3_odt        : out   std_logic_vector(0 downto 0);
--      ddr3_addr       : out   std_logic_vector(14 downto 0);
--      ddr3_ba         : out   std_logic_vector(2 downto 0);
--      ddr3_dm         : out   std_logic_vector(1 downto 0);
--      ddr3_dq         : inout std_logic_vector(15 downto 0);
--      ddr3_dqs_p      : inout std_logic_vector(1 downto 0);
--      ddr3_dqs_n      : inout std_logic_vector(1 downto 0)

    );
end entity np6532_poc_128k_digilent_nexys_video;

architecture synth of np6532_poc_128k_digilent_nexys_video is

    signal clk_96m    : std_logic;
    signal clk_48m    : std_logic;
    signal clk_32m    : std_logic;
    signal clk_8m    : std_logic;
    signal rst        : std_logic;
    signal hold       : std_logic;
    signal irq        : std_logic;
    signal nmi        : std_logic;
    signal dma_ti     : std_logic_vector(6 downto 0);
    signal dma_to     : std_logic_vector(7 downto 0);
    signal led_user   : std_logic_vector(7 downto 0);

    attribute PULLTYPE: string;
    attribute PULLTYPE of ja : signal is "PULLDOWN";
    attribute PULLTYPE of jb : signal is "PULLDOWN";

begin

    CLOCK: component mmcm
        generic map (
            mul         => 48.0,
            div         => 5,
            num_outputs => 2,
            odiv0       => 10.0,
            odiv        => (20,30,120,0,0,0),
            duty_cycle  => (0.5,0.5,0.3,0.5,0.5,0.5,0.5)
        )
        port map (
            rsti        => not btn_rst_n,
            clki        => clki_100m,
            rsto        => rst,
            clk(0)      => clk_96m,
            clk(1)      => clk_48m,
            clk(2)      => clk_32m,
            clk(3)      => clk_8m,
        );

    -- system

    SYS: component otus
        generic map (
            clk_ratio     => 3,
            ram_size_log2 => 17, -- 128k
            success_addr  => success_addr
        )
        port map (
            rst       => rst,
            clk_96m   => clk_96m,
            clk_48m   => clk_48m,
            clk_32m   => clk_32m,
            clk_8m    => clk_8m,
            pix_clken => 
            pix_de    => 
            pix_d     => 
            kbd_rst   => 
            kbd_en    => 
            kbd_col   => 
            kbd_row   => 
            kbd_press => 
            mmc_sel_n => 
            mmc_sclk  => 
            mmc_mosi  => 
            mmc_miso  => 
        );


    -- video SD to HD
    
    -- total active period for modes 0,1,2,4,5 = 16.36ms
    -- total active period for 1280x1024 region of 1080p50 = 18.195286ms
    -- a differnce of 1.835ms = ~29 SD lines
    -- hence upscale buffer needs storage for ~20k pixels in mode 0
    -- for mode 7, figures are 1.794ms and 13.5k pixels
    -- SO let's have a 32k pixel upscale buffer = ~51 SD lines (mode 0)
    -- NOTE: in mode 7 we need to write even and odd lines simultaneously
    -- timing: we need to start reading from the buffer within 20 SD lines of the start of active video
    -- let's aim for 2
    
    
    -- HDMI output


    -- I/O

    hold <= ja(0);
    irq <= ja(1);
    nmi <= ja(2);
    dma_ti <= jb(6 downto 0);
    jc <= dma_to;
    led <= led_user;

    -- unused I/O

    oled_res_n      <= '0';
    oled_d_c        <= '0';
    oled_sclk       <= '0';
    oled_sdin       <= '0';
    ac_mclk         <= '0';
    ac_dac_sdata    <= '0';
    uart_rx_out     <= '1';
    eth_rst_n       <= '0';
    ftdi_rd_n       <= '1';
    ftdi_wr_n       <= '1';
    ftdi_siwu_n     <= '1';
    ftdi_oe_n       <= '1';
    ps2_clk         <= 'Z';
    ps2_data        <= 'Z';
    qspi_cs_n       <= '1';
    ddr3_reset_n    <= '0';

end architecture synth;
