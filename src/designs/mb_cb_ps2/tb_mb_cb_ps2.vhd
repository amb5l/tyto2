--------------------------------------------------------------------------------
-- tb_mb_cb_ps2.vhd                                                           --
-- Simulation testbench for mb_cb_ps2.vhd.                                    --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
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

library std;
use std.env.finish;

library work;
use work.tyto_types_pkg.all;
use work.tyto_sim_pkg.all;
use work.mb_cb_ps2_pkg.all;
use work.model_vga_sink_pkg.all;
use work.ps2set_to_usbhid_pkg.all;

entity tb_mb_cb_ps2 is
end entity tb_mb_cb_ps2;

architecture sim of tb_mb_cb_ps2 is

    constant tps2 : time := 66 us; -- PS/2 clock period (~16.7kHz)

    signal cpu_clk    : std_logic;
    signal cpu_rst    : std_logic;

    signal pix_clk    : std_logic;
    signal pix_rst    : std_logic;

    signal uart_tx    : std_logic;
    signal uart_rx    : std_logic;

    signal ps2_clk    : std_logic;
    signal ps2_clk_i  : std_logic;
    signal ps2_clk_o  : std_logic;
    signal ps2_data   : std_logic;
    signal ps2_data_i : std_logic;
    signal ps2_data_o : std_logic;

    signal pal_ntsc   : std_logic;

    signal vga_vs     : std_logic;
    signal vga_hs     : std_logic;
    signal vga_de     : std_logic;
    signal vga_r      : std_logic_vector(7 downto 0);
    signal vga_g      : std_logic_vector(7 downto 0);
    signal vga_b      : std_logic_vector(7 downto 0);

    signal cap_stb    : std_logic;

    signal debug      : std_logic_vector(15 downto 0);
    signal hid_code   : std_logic_vector(7 downto 0);
    signal last       : std_logic;
    signal pass       : integer;
    signal fail       : integer;

    function oco(i : std_logic) return std_logic is
    begin
        if i = '0' or i = 'L' then
            return '0';
        elsif i = '1' or i = 'H' then
            return 'Z';
        else
            return 'U';
        end if;
    end function oco;

    function oci(i : std_logic) return std_logic is
    begin
        if i = '0' or i = 'L' then
            return '0';
        elsif i = '1' or i = 'H' then
            return '1';
        else
            return 'U';
        end if;
    end function oci;

begin

    stim_clock(cpu_clk, 10 ns);  -- 100 MHz
    stim_reset(cpu_rst, '1', 200 ns);
    stim_clock(pix_clk, 37037 ps); -- ~27 MHz
    stim_reset(pix_rst, '1', 200 ns);

    process

        function parity_odd(v : std_logic_vector) return std_logic is
            variable r : std_logic := '1';
        begin
            for i in v'low to v'high loop
                r := r xor v(i);
            end loop;
            return r;
        end function parity_odd;

        procedure ps2_d2h(
            signal   ps2_clk  : out std_logic;
            signal   ps2_data : out std_logic;
            constant d2h_data : in std_logic_vector(7 downto 0);
            constant period   : in time;
            constant corrupt  : in std_logic_vector(10 downto 0) := (others => '0')
        ) is
        begin
            -- start
            wait for period/2;
            ps2_clk <= oco('0');
            ps2_data <= oco(corrupt(0));
            wait for period/2;
            ps2_clk <= oco('1');
            -- data
            for i in 0 to 7 loop
                wait for period/2;
                ps2_clk <= oco('0');
                ps2_data <= oco(d2h_data(i) xor corrupt(1+i));
                wait for period/2;
                ps2_clk <= oco('1');
            end loop;
            -- parity
            wait for period/2;
            ps2_clk <= oco('0');
            ps2_data <= oco(parity_odd(d2h_data) xor corrupt(9));
            wait for period/2;
            ps2_clk <= oco('1');
            -- stop
            wait for period/2;
            ps2_clk <= oco('0');
            ps2_data <= oco(not corrupt(10));
            wait for period/2;
            ps2_clk <= oco('1');
            ps2_data <= oco('1');
        end procedure ps2_d2h;

        constant tbl : slv_8_0_t := ps2set_to_usbhid(true);
        variable i : integer;
        variable n : integer;

    begin
        ps2_clk <= 'Z';
        ps2_data <= 'Z';
        pass <= 0;
        fail <= 0;
        i := 0;
        n := 0;
        wait for 1 ms;
        while true loop
            hid_code <= tbl(i)(7 downto 0);
            last <= tbl(i)(8);
            -- make code(s)
            while true loop
                i := i+1;
                ps2_d2h(ps2_clk,ps2_data,tbl(i)(7 downto 0),tps2);
                --report "i: " & integer'image(i) & "  sending " & integer'image(to_integer(unsigned(tbl(i)(7 downto 0))));
                if tbl(i)(8) = '0' then exit; end if;
            end loop;
            wait until falling_edge(debug(15));
            if debug(7 downto 0) /= hid_code or debug(8) /= '1' then
                fail <= fail+1;
                report "mismatch!" severity FAILURE;
            else
                pass <= pass+1;
            end if;
            wait for 200us;
            -- break code(s) (if they exist)
            if tbl(i+1) /= "000000000" then
                while true loop
                    i := i+1;
                    ps2_d2h(ps2_clk,ps2_data,tbl(i)(7 downto 0),tps2);
                    --report "i: " & integer'image(i) & "  sending " & integer'image(to_integer(unsigned(tbl(i)(7 downto 0))));
                    if tbl(i)(8) = '0' then exit; end if;
                end loop;
                wait until falling_edge(debug(15));
                if debug(7 downto 0) /= hid_code or debug(8) /= '0' then
                    fail <= fail+1;
                    report "mismatch!" severity FAILURE;
                else
                    pass <= pass+1;
                end if;
                wait for 200 us;
            else
                report "no break code";
                i := i+1;
            end if;
            i := i+1;
            if last = '1' then
                exit;
            end if;
            n := n+1;
            if n mod 10 = 0 then
                -- wait for display to stabilise
                wait until rising_edge(cap_stb);
                wait until rising_edge(cap_stb);
            end if;
        end loop;
        report "pass = " & integer'image(pass) & "  fail = " & integer'image(fail);
        finish;
        wait;
    end process;

    ps2_clk <= 'H';
    ps2_clk <= oco(ps2_clk_o);
    ps2_clk_i <= oci(ps2_clk);

    ps2_data <= 'H';
    ps2_data <= oco(ps2_data_o);
    ps2_data_i <= oci(ps2_data);

    UUT: component mb_cb_ps2
        port map (
            cpu_clk    => cpu_clk,
            cpu_rst    => cpu_rst,
            pix_clk    => pix_clk,
            pix_rst    => pix_rst,
            uart_tx    => uart_tx,
            uart_rx    => uart_rx,
            ps2_clk_i  => ps2_clk_i,
            ps2_clk_o  => ps2_clk_o,
            ps2_data_i => ps2_data_i,
            ps2_data_o => ps2_data_o,
            vga_vs     => vga_vs,
            vga_hs     => vga_hs,
            vga_de     => vga_de,
            vga_r      => vga_r,
            vga_g      => vga_g,
            vga_b      => vga_b,
            debug      => debug
        );

    CAPTURE: component model_vga_sink
        port map (
            vga_rst  => '0',
            vga_clk  => pix_clk,
            vga_vs   => vga_vs,
            vga_hs   => vga_hs,
            vga_de   => vga_de,
            vga_r    => vga_r,
            vga_g    => vga_g,
            vga_b    => vga_b,
            cap_rst  => '0',
            cap_stb  => cap_stb,
            cap_name => "tb_mb_cb_ps2"
        );

end architecture sim;
