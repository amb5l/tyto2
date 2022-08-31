--------------------------------------------------------------------------------
-- tb_ps2_to_usbhid.vhd                                                       --
-- Simulation testbench for ps2_to_usbhid.vhd.                                --
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
use ieee.numeric_std.all;

library std;
use std.env.finish;

library work;
use work.tyto_types_pkg.all;
use work.tyto_sim_pkg.all;
use work.ps2_to_usbhid_pkg.all;
use work.ps2set_to_usbhid_pkg.all;
use work.ps2_host_pkg.all;

entity tb_ps2_to_usbhid is
end entity tb_ps2_to_usbhid;

architecture sim of tb_ps2_to_usbhid is

    constant tps2 : time := 66 us; -- PS/2 clock period (~16.7kHz)
    constant tclk : time := 1 us;  -- clock period

    signal clk         : std_logic;
    signal rst         : std_logic;

    signal ps2_clk_i   : std_logic;
    signal ps2_clk_o   : std_logic;
    signal ps2_data_i  : std_logic;
    signal ps2_data_o  : std_logic;

    signal d2h_stb     : std_logic;
    signal d2h_data_tx : std_logic_vector(7 downto 0);
    signal d2h_data_rx : std_logic_vector(7 downto 0);

    signal h2d_req     : std_logic;
    signal h2d_ack     : std_logic;
    signal h2d_nack    : std_logic;
    signal h2d_data_tx : std_logic_vector(7 downto 0);
    signal h2d_data_rx : std_logic_vector(7 downto 0);

    signal h2d_perr    : boolean;
    signal ps2_clk     : std_logic := 'H';
    signal ps2_data    : std_logic := 'H';

    signal this_code   : std_logic_vector(7 downto 0);
    signal last        : std_logic;

    signal hid_stb     : std_logic;
    signal hid_code    : std_logic_vector(7 downto 0);
    signal hid_make    : std_logic;

    signal pass        : integer;
    signal fail        : integer;

    signal t           : time;
    signal maxlat      : time;

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

    function parity_odd(v : std_logic_vector) return std_logic is
        variable r : std_logic := '1';
    begin
        for i in v'low to v'high loop
            r := r xor v(i);
        end loop;
        return r;
    end function parity_odd;

begin

    stim_reset(rst, '1', 2 us);

    clk <=
        '1' after tclk/2 when clk = '0' else
        '0' after tclk/2 when clk = '1' else
        '1';

    process
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
    begin
        h2d_req <= '0';
        pass <= 0;
        fail <= 0;
        wait for tps2;
        i := 0;
        while true loop
            this_code <= tbl(i)(7 downto 0);
            last <= tbl(i)(8);
            -- make code(s)
            while true loop
                i := i+1;
                ps2_d2h(ps2_clk,ps2_data,tbl(i)(7 downto 0),tps2);
                if tbl(i)(8) = '0' then exit; end if;
            end loop;
            wait until falling_edge(hid_stb);
            if hid_code /= this_code or hid_make /= '1' then
                fail <= fail+1;
            else
                pass <= pass+1;
            end if;
            wait for 200 us;
            -- break code(s) (if they exist)
            if tbl(i+1) /= "000000000" then
                while true loop
                    i := i+1;
                    ps2_d2h(ps2_clk,ps2_data,tbl(i)(7 downto 0),tps2);
                    if tbl(i)(8) = '0' then exit; end if;
                end loop;
                wait until falling_edge(hid_stb);
                if hid_code /= this_code or hid_make /= '0' then
                    fail <= fail+1;
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
        end loop;
        report "pass = " & integer'image(pass) & "  fail = " & integer'image(fail) & "  max latency = " & time'image(maxlat);
        finish;
    end process;

    process(rst,d2h_stb,hid_stb)
    begin
        if rst = '1' then
        elsif rising_edge(d2h_stb) then
            t <= now;
        elsif rising_edge(hid_stb) then
            if now-t > maxlat then
                maxlat <= now-t;
            end if;
        end if;
    end process;

    UUT: component ps2_to_usbhid
        generic map (
            nonUS => true
        )
        port map (
            clk      => clk,
            rst      => rst,
            ps2_stb  => d2h_stb,
            ps2_data => d2h_data_rx,
            hid_stb  => hid_stb,
            hid_make => hid_make,
            hid_code => hid_code
        );

    HOST: component ps2_host
        generic map (
            fclk       => 1.0
        )
        port map (
            clk        => clk,
            rst        => rst,
            ps2_clk_i  => ps2_clk_i,
            ps2_clk_o  => ps2_clk_o,
            ps2_data_i => ps2_data_i,
            ps2_data_o => ps2_data_o,
            d2h_stb    => d2h_stb,
            d2h_data   => d2h_data_rx,
            h2d_req    => h2d_req,
            h2d_ack    => h2d_ack,
            h2d_nack   => h2d_nack,
            h2d_data   => h2d_data_tx
        );

    ps2_clk <= 'H';
    ps2_clk <= oco(ps2_clk_o);
    ps2_clk_i <= oci(ps2_clk);

    ps2_data <= 'H';
    ps2_data <= oco(ps2_data_o);
    ps2_data_i <= oci(ps2_data);

end architecture sim;
