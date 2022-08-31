--------------------------------------------------------------------------------
-- tb_ps2_host.vhd                                                            --
-- Simulation testbench for ps2_host.vhd.                                     --
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
use work.tyto_sim_pkg.all;
use work.ps2_host_pkg.all;

entity tb_ps2_host is
end entity tb_ps2_host;

architecture sim of tb_ps2_host is

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
    signal d2h_pass    : integer;
    signal d2h_fail    : integer;

    signal h2d_req     : std_logic;
    signal h2d_ack     : std_logic;
    signal h2d_nack    : std_logic;
    signal h2d_data_tx : std_logic_vector(7 downto 0);
    signal h2d_data_rx : std_logic_vector(7 downto 0);
    signal h2d_pass    : integer;
    signal h2d_fail    : integer;

    signal h2d_perr   : boolean;
    signal ps2_clk    : std_logic := 'H';
    signal ps2_data   : std_logic := 'H';

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
            signal   s_clk   : out std_logic;
            signal   s_data  : out std_logic;
            constant p_data  : in std_logic_vector(7 downto 0);
            constant period  : in time;
            constant corrupt : in std_logic_vector(10 downto 0) := (others => '0')
        ) is
        begin
            -- start
            wait for period/2;
            s_clk <= oco('0');
            s_data <= oco(corrupt(0));
            wait for period/2;
            s_clk <= oco('1');
            -- data
            for i in 0 to 7 loop
                wait for period/2;
                s_clk <= oco('0');
                s_data <= oco(p_data(i) xor corrupt(1+i));
                wait for period/2;
                s_clk <= oco('1');
            end loop;
            -- parity
            wait for period/2;
            s_clk <= oco('0');
            s_data <= oco(parity_odd(p_data) xor corrupt(9));
            wait for period/2;
            s_clk <= oco('1');
            -- stop
            wait for period/2;
            s_clk <= oco('0');
            s_data <= oco(not corrupt(10));
            wait for period/2;
            s_clk <= oco('1');
            s_data <= oco('1');
        end procedure ps2_d2h;
        procedure ps2_h2d(
            signal   s_clk  : inout std_logic;
            signal   s_data : inout std_logic;
            signal   p_data : out std_logic_vector(7 downto 0);
            signal   p_perr : out boolean;
            constant period : in time
        ) is
            variable sr : std_logic_vector(10 downto 0);
        begin
            wait until oci(s_clk) = '0';
            wait until oci(s_data) = '0';
            wait until oci(s_clk) = '1';
            for i in 0 to 10 loop
                wait for period/2;
                s_clk <= oco('0');
                s_data <= oco('1');
                if i = 10 then
                    s_data <= oco('0');
                end if;
                wait for period/2;
                s_clk <= oco('1');
                sr(i) := oci(s_data);
            end loop;
            s_data <= oco('1');
            p_data <= sr(7 downto 0);
            p_perr <= sr(8) /= parity_odd(sr(7 downto 0));
        end procedure ps2_h2d;
    begin
        h2d_req <= '0';
        wait for tps2;
        for i in 0 to 255 loop
            d2h_data_tx <= std_logic_vector(to_unsigned(i,8));
            ps2_d2h(ps2_clk, ps2_data, std_logic_vector(to_unsigned(i,8)), tps2);
            wait for 100 us;
        end loop;
        wait for 100 us;
        for i in 0 to 255 loop
            wait until falling_edge(clk);
            h2d_data_tx <= std_logic_vector(to_unsigned(i,8));
            h2d_req <= '1';
            ps2_h2d(ps2_clk, ps2_data, h2d_data_rx, h2d_perr, tps2 );
            wait until h2d_ack = '1' or h2d_nack = '1';
            wait until falling_edge(clk);
            h2d_req <= '0';
            wait for 100 us;
        end loop;
        report "D2H: pass = " & integer'image(d2h_pass) & "  fail = " & integer'image(d2h_fail);
        report "H2D: pass = " & integer'image(h2d_pass) & "  fail = " & integer'image(h2d_fail);
        finish;
    end process;

    process(rst,d2h_stb)
    begin
        if rst = '1' then
            d2h_pass <= 0;
            d2h_fail <= 0;
        elsif falling_edge(d2h_stb) then
            if d2h_data_rx /= d2h_data_tx then
                d2h_fail <= d2h_fail+1;
            else
                d2h_pass <= d2h_pass+1;
            end if;
        end if;
    end process;

    process(rst,h2d_req)
    begin
        if rst = '1' then
            h2d_pass <= 0;
            h2d_fail <= 0;
        elsif falling_edge(h2d_req) then
            if h2d_data_rx /= h2d_data_tx then
                h2d_fail <= h2d_fail+1;
            else
                h2d_pass <= h2d_pass+1;
            end if;
        end if;
    end process;

    UUT: component ps2_host
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
