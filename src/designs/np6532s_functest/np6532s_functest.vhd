--------------------------------------------------------------------------------
-- np6532s_functest.vhd                                                       --
-- Simulation of np6532s core running Klaus Dormann's 6502 functional test.   --
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
use ieee.std_logic_textio.all;

library std;
use std.textio.all;
use std.env.all;

library work;
use work.np6532s_pkg.all;

entity np6532s_functest is
    generic (
        vector_init : integer;
        start_address : integer;
        ref_file : string
    );
end entity np6532s_functest;

architecture sim of np6532s_functest is

    signal clk      : std_logic;
    signal hold     : std_logic;
    signal rst      : std_logic;
    signal nmi      : std_logic;
    signal irq      : std_logic;
    signal if_al    : std_logic_vector(15 downto 0);
    signal if_ap    : std_logic_vector(15 downto 0);
    signal if_z     : std_logic;
    signal ls_al    : std_logic_vector(15 downto 0);
    signal ls_ap    : std_logic_vector(15 downto 0);
    signal ls_en    : std_logic;
    signal ls_re    : std_logic;
    signal ls_we    : std_logic;
    signal ls_wp    : std_logic;
    signal ls_ext   : std_logic;
    signal ls_drx   : std_logic_vector(7 downto 0);
    signal ls_dwx   : std_logic_vector(7 downto 0);
    signal trace_en : std_logic;
    signal trace_pc : std_logic_vector(15 downto 0);
    signal trace_s  : std_logic_vector(7 downto 0);
    signal trace_p  : std_logic_vector(7 downto 0);
    signal trace_a  : std_logic_vector(7 downto 0);
    signal trace_x  : std_logic_vector(7 downto 0);
    signal trace_y  : std_logic_vector(7 downto 0);
    signal dma_a    : std_logic_vector(15 downto 3);
    signal dma_bwe  : std_logic_vector(7 downto 0);
    signal dma_dw   : std_logic_vector(63 downto 0);
    signal dma_dr   : std_logic_vector(63 downto 0);

    signal trace_pc_prev : std_logic_vector(15 downto 0);
    signal started       : boolean;
    signal count_i       : integer;
    signal count_c       : integer;
    
begin

    clk <=
        '1' after 10ns when clk = '0' else
        '0' after 10ns when clk = '1' else
        '0';

    hold <= '0';
    nmi <= '0';
    irq <= '0';    
    if_ap <= if_al;
    if_z <= '0';    
    ls_ap <= ls_al;
    ls_wp <= '0';
    ls_ext <= '0';

    do_test: process
        file f : text open read_mode is ref_file;
        variable l : line;
        variable ref_pc : std_logic_vector(15 downto 0);
        variable ref_s, ref_p, ref_a, ref_x, ref_y : std_logic_vector(7 downto 0);
    begin
        count_c <= 1;
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        while not endfile(f) loop
            wait until rising_edge(clk);
            if started then
                count_c <= count_c + 1;
            end if;
            if trace_en = '1' then
                if count_i > 0 and count_i mod 100000 = 0 then
                    report "instruction count: " & integer'image(count_i) & "  cycle count: " & integer'image(count_c);
                end if;
                if trace_pc_prev /= "UUUUUUUUUUUUUUUU" and trace_pc_prev = trace_pc then
                    report "PC = " & to_hstring(to_bitvector(trace_pc))
                        & "  S = " & to_hstring(to_bitvector(trace_s))
                        & "  P = " & to_hstring(to_bitvector(trace_p))
                        & "  A = " & to_hstring(to_bitvector(trace_a))
                        & "  X = " & to_hstring(to_bitvector(trace_x))
                        & "  Y = " & to_hstring(to_bitvector(trace_y));
                    report "*** INFINITE LOOP ***";
                    report "instruction count: " & integer'image(count_i) & "  cycle count: " & integer'image(count_c);
                    finish;
                end if;
                if started then
                    readline(f, l);
                    hread(l,ref_pc);
                    hread(l,ref_s);
                    hread(l,ref_p);
                    hread(l,ref_a);
                    hread(l,ref_x);
                    hread(l,ref_y);
                    if trace_pc /= ref_pc or trace_s /= ref_s or trace_p /= ref_p or trace_a /= ref_a or trace_x /= ref_x or trace_y /= ref_y then
                        report "PC = " & to_hstring(to_bitvector(trace_pc)) &  "/" & to_hstring(to_bitvector(ref_pc))
                            & "  S = " & to_hstring(to_bitvector(trace_s)) & "/" & to_hstring(to_bitvector(ref_s))
                            & "  P = " & to_hstring(to_bitvector(trace_p)) & "/" & to_hstring(to_bitvector(ref_p))
                            & "  A = " & to_hstring(to_bitvector(trace_a)) & "/" & to_hstring(to_bitvector(ref_a))
                            & "  X = " & to_hstring(to_bitvector(trace_x)) & "/" & to_hstring(to_bitvector(ref_x))
                            & "  Y = " & to_hstring(to_bitvector(trace_y)) & "/" & to_hstring(to_bitvector(ref_y));
                        report "*** MISMATCH ***";
                        report "instruction count: " & integer'image(count_i) & "  cycle count: " & integer'image(count_c);
                        finish;
                    end if;
                end if;
            end if;
        end loop;
        report "instruction count: " & integer'image(count_i) & "  cycle count: " & integer'image(count_c);
        report "*** END OF FILE ***";
        report "instruction count: " & integer'image(count_i) & "  cycle count: " & integer'image(count_c);
        finish;
    end process do_test;

    do_track: process(rst, clk)
    begin
        if rst = '1' then
            started <= false;
            count_i <= 0;
            trace_pc_prev <= (others => 'U');
        elsif falling_edge(clk) then
            if trace_en = '1' then
                if to_integer(unsigned(trace_pc)) = start_address then
                    count_i <= 1;
                    started <= true;
                else
                    count_i <= count_i+1;                
                end if;
            end if;
        elsif rising_edge(clk) then
            if trace_en = '1' then
                trace_pc_prev <= trace_pc;
            end if;
        end if;
    end process;

    UUT: component np6532s
        generic map (
            ram_size_log2 => 16,
            vector_init => std_logic_vector(to_unsigned(vector_init,16))
        )
        port map (
            clk      => clk,
            hold     => hold,
            rst      => rst,
            nmi      => nmi,
            irq      => irq,
            if_al    => if_al,
            if_ap    => if_ap,
            if_z     => if_z,
            ls_al    => ls_al,
            ls_ap    => ls_ap,
            ls_en    => ls_en,
            ls_re    => ls_re,
            ls_we    => ls_we,
            ls_wp    => ls_wp,
            ls_ext   => ls_ext,
            ls_drx   => ls_drx,
            ls_dwx   => ls_dwx,
            trace_en => trace_en,
            trace_pc => trace_pc,
            trace_s  => trace_s,
            trace_p  => trace_p,
            trace_a  => trace_a,
            trace_x  => trace_x,
            trace_y  => trace_y,
            dma_a    => dma_a,
            dma_bwe  => dma_bwe,
            dma_dw   => dma_dw,
            dma_dr   => dma_dr
        );

end architecture sim;
