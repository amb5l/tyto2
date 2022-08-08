--------------------------------------------------------------------------------
-- otus_sysvia.vhd                                                            --
-- Otus system VIA.                                                           --
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

package otus_sysvia_pkg is

    component otus_sysvia is
        port (

            clk_32m     : in  std_logic;
            clk_8m      : in  std_logic;
            rst_32m     : in  std_logic;
            rst_8m      : in  std_logic;
            clken_8m_1m : in  std_logic;

            reg_clk     : in  std_logic;                    -- register interface: clock
            reg_clken   : in  std_logic;                    -- register interface: clock enable
            reg_rst     : in  std_logic;                    -- register interface: reset
            reg_cs      : in  std_logic;                    -- register interface: chip select
            reg_we      : in  std_logic;                    -- register interface: write enable
            reg_rs      : in  std_logic_vector(3 downto 0); -- register interface: register select
            reg_dw      : in  std_logic_vector(7 downto 0); -- register interface: write data
            reg_dr      : out std_logic_vector(7 downto 0); -- register interface: read data
            reg_irq     : out std_logic;                    -- register interface: interrupt request

            kb_en       : out std_logic;                    -- keyboard: write enable
            kb_col      : out std_logic_vector(3 downto 0); -- keyboard: column
            kb_row      : out std_logic_vector(2 downto 0); -- keyboard: row
            kb_press    : in  std_logic;                    -- keyboard: keyswitch pressed (1)
            kb_int      : in  std_logic;                    -- keyboard: interrupt
            kb_led_s    : out std_logic;                    -- keyboard: shift lock LED
            kb_led_c    : out std_logic;                    -- keyboard: caps lock LED

            crtc_sa     : out std_logic_vector(1 downto 0); -- CRTC: start address
            crtc_vs     : in  std_logic;                    -- CRTC: vertical sync

            lp_stb      : in  std_logic;                    -- light pen: strobe

            paddle_i    : in  std_logic_vector(1 downto 0); -- paddle: button input 0

            adc_eoc     : in  std_logic;                    -- ADC: end of conversion

            sg_we       : out std_logic;                    -- sound generator: write enable
            sg_dw       : out std_logic_vector(7 downto 0); -- sound generator: write data

            sp_re       : out std_logic;                    -- speech processor: read enable
            sp_we       : out std_logic;                    -- speech processor: write enable
            sp_dw       : out std_logic_vector(7 downto 0); -- speech processor: write data
            sp_dr       : in  std_logic_vector(7 downto 0); -- speech processor: read data
            sp_int      : in  std_logic;                    -- speech processor: interrupt
            sp_rdy      : in  std_logic                     -- speech processor: ready

        );
    end component otus_sysvia;

end package otus_sysvia_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity otus_sysvia is
    port (

        clk_32m     : in  std_logic;
        clk_8m      : in  std_logic;
        rst_32m     : in  std_logic;
        rst_8m      : in  std_logic;
        clken_8m_1m : in  std_logic;

        reg_clk     : in  std_logic;                    -- register interface: clock
        reg_clken   : in  std_logic;                    -- register interface: clock enable
        reg_rst     : in  std_logic;                    -- register interface: reset
        reg_cs      : in  std_logic;                    -- register interface: chip select
        reg_we      : in  std_logic;                    -- register interface: write enable
        reg_rs      : in  std_logic_vector(3 downto 0); -- register interface: register select
        reg_dw      : in  std_logic_vector(7 downto 0); -- register interface: write data
        reg_dr      : out std_logic_vector(7 downto 0); -- register interface: read data
        reg_irq     : out std_logic;                    -- register interface: interrupt request

        kb_en       : out std_logic;                    -- keyboard: write enable
        kb_col      : out std_logic_vector(3 downto 0); -- keyboard: column
        kb_row      : out std_logic_vector(2 downto 0); -- keyboard: row
        kb_press    : in  std_logic;                    -- keyboard: keyswitch pressed (1)
        kb_int      : in  std_logic;                    -- keyboard: interrupt
        kb_led_s    : out std_logic;                    -- keyboard: shift lock LED
        kb_led_c    : out std_logic;                    -- keyboard: caps lock LED

        crtc_sa     : out std_logic_vector(1 downto 0); -- CRTC: start address
        crtc_vs     : in  std_logic;                    -- CRTC: vertical sync

        lp_stb      : in  std_logic;                    -- light pen: strobe

        paddle_i    : in  std_logic_vector(1 downto 0); -- paddle: button input 0

        adc_eoc     : in  std_logic;                    -- ADC: end of conversion

        sg_we       : out std_logic;                    -- sound generator: write enable
        sg_dw       : out std_logic_vector(7 downto 0); -- sound generator: write data

        sp_re       : out std_logic;                    -- speech processor: read enable
        sp_we       : out std_logic;                    -- speech processor: write enable
        sp_dw       : out std_logic_vector(7 downto 0); -- speech processor: write data
        sp_dr       : in  std_logic_vector(7 downto 0); -- speech processor: read data
        sp_int      : in  std_logic;                    -- speech processor: interrupt
        sp_rdy      : in  std_logic                     -- speech processor: ready

    );
end entity otus_sysvia;

architecture synth of otus_sysvia is

    signal reg_rs_1    : std_logic;

    signal via_pa_i    : std_logic_vector(7 downto 0);
    signal via_pa_o    : std_logic_vector(7 downto 0);
    signal via_pa_dir  : std_logic_vector(7 downto 0);
    signal via_ca1     : std_logic;
    signal via_ca2_i   : std_logic;
    signal via_ca2_o   : std_logic;
    signal via_ca2_dir : std_logic;
    signal via_pb_i    : std_logic_vector(7 downto 0);
    signal via_pb_o    : std_logic_vector(7 downto 0);
    signal via_pb_dir  : std_logic_vector(7 downto 0);
    signal via_cb1_i   : std_logic;
    signal via_cb1_o   : std_logic;
    signal via_cb1_dir : std_logic;
    signal via_cb2_i   : std_logic;
    signal via_cb2_o   : std_logic;
    signal via_cb2_dir : std_logic

    signal alat        : std_logic_vector(7 downto 0);

begin

    VIA: component r6522
        port (
            reg_clk    => clk_32m,
            reg_clken  => '1',
            reg_rst    => reg_rst,
            reg_cs     => reg_cs,
            reg_we     => reg_we,
            reg_rs     => reg_rs,
            reg_dw     => reg_dw,
            reg_dr     => reg_dr,
            reg_irq    => reg_irq,
            io_clk     => clk_8m,
            io_clken   => clken_8m_1m,
            io_pa_i    => via_pa_i,
            io_pa_o    => via_pa_o,
            io_pa_dir  => via_pa_dir,
            io_ca1     => via_ca1,
            io_ca2_i   => via_ca2_i,
            io_ca2_o   => via_ca2_o,
            io_ca2_dir => via_ca2_dir,
            io_pb_i    => via_pb_i,
            io_pb_o    => via_pb_o,
            io_pb_dir  => via_pb_dir,
            io_cb1_i   => via_cb1_i,
            io_cb1_o   => via_cb1_o,
            io_cb1_dir => via_cb1_dir,
            io_cb2_i   => via_cb2_i,
            io_cb2_o   => via_cb2_o,
            io_cb2_dir => via_cb2_dir
        );

    -- slow databus reads
    GEN1: for i in 0 to 6 generate
        via_pa_i(i) <=
            via_pa_o(i) when via_pa_dir(i) = '1' else
            sp_dr(i) when alat(1) = '0' else
            '0';
    end generate GEN1;
    via_pa_i(7) <=
        via_pa_o(7) when via_pa_dir(7) = '1' else
        not kb_press when alat(3) = '0' else -- active low in original hardware
        sp_dr(i) when alat(1) = '0' else
        '0';

    -- addressable latch
    process(reg_clk)
    begin
        if rising_edge(reg_clk) then
            reg_cs_1 <= reg_cs;
            if reg_cs_1 = '1' then
                alat(to_integer(unsigned(via_pb_o(2 downto 0)))) <= via_pb_o(3);
            end if;
        end if;
    end process;

    -- keyboard
    kb_en <= not alat(3); -- active low in original hardware
    kb_col <= via_pa_o(3 downto 0);
    kb_row <= via_pa_o(6 downto 4);
    via_pa_i(7) <= kb_press;
    via_ca2_i <= kb_int;
    kb_led_c <= not alat(6); -- active low in original hardware
    kb_led_s <= not alat(7); -- active low in original hardware

    -- CRTC
    crtc_sa <= alat(5 downto 4);
    via_ca1_i <= crtc_vs;

    -- light pen
    via_cb2_i <= lp_stb;

    -- paddle buttons
    via_pb_i(5 downto 4) <= not paddle_i(1 downto 0); -- active low in original hardware

    -- ADC
    via_cb1_i <= adc_eoc;

    -- sound generator
    sg_we <= not alat(0); -- active low in original hardware
    sg_dw <= via_pa_o;

    -- speech processor
    sp_re <= not alat(1); -- active low in original hardware
    sp_we <= not alat(2); -- active low in original hardware
    sp_dw <= via_pa_o;
    via_pb_i(6) <= not sp_rdy; -- active low in original hardware
    via_pb_i(7) <= not sp_int; -- active low in original hardware

end architecture synth;
