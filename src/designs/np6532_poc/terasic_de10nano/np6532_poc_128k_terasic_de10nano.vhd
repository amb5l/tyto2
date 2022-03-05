--------------------------------------------------------------------------------
-- np6532_poc_128k_terasic_de10nano.vhd                                       --
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

entity np6532_poc_128k_terasic_de10nano is
    generic (
        success_addr  : integer
    );
    port (

      fpga_clk1_50     : in    std_logic;
      fpga_clk2_50     : in    std_logic;
      fpga_clk3_50     : in    std_logic;

      sw               : in    std_logic_vector(3 downto 0);
      key              : in    std_logic_vector(1 downto 0);
      led              : out   std_logic_vector(7 downto 0);

      hdmi_tx_clk      : out   std_logic;
      hdmi_tx_d        : out   std_logic_vector(23 downto 0);
      hdmi_tx_vs       : out   std_logic;
      hdmi_tx_hs       : out   std_logic;
      hdmi_tx_de       : out   std_logic;
      hdmi_tx_int      : in    std_logic;

      hdmi_sclk        : inout std_logic;
      hdmi_mclk        : inout std_logic;
      hdmi_lrclk       : inout std_logic;
      hdmi_i2s         : inout std_logic;

      hdmi_i2c_scl     : inout std_logic;
      hdmi_i2c_sda     : inout std_logic;

      adc_convst       : out   std_logic;
      adc_sck          : out   std_logic;
      adc_sdi          : out   std_logic;
      adc_sdo          : in    std_logic;

      arduino_reset_n  : inout std_logic;
      arduino_io       : inout std_logic_vector(15 downto 0);
      gpio_0           : inout std_logic_vector(35 downto 0);
      gpio_1           : inout std_logic_vector(35 downto 0)

    );
end entity np6532_poc_128k_terasic_de10nano;

architecture synth of np6532_poc_128k_terasic_de10nano is

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

    rst_ref <= not key(0);

    CLOCK: entity work.pll_otus_50m_96m_32m
        port map (
            refclk   => fpga_clk1_50,
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

    hold <= not key(1);
    irq <= not gpio_1(6);
    nmi <= not gpio_1(7);
    dma_ti <= not gpio_1(5 downto 0);
    gpio_1(15 downto 8) <= dma_to;
    led <= led_user(7 downto 0);

    -- unused outputs

    hdmi_tx_clk <='0';
    hdmi_tx_d   <= (others => '0');
    hdmi_tx_vs  <='0';
    hdmi_tx_hs  <='0';
    hdmi_tx_de  <='0';
    adc_convst  <='0';
    adc_sck     <='0';
    adc_sdi     <='0';

end architecture synth;
