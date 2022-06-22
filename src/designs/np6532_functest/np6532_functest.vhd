--------------------------------------------------------------------------------
-- np6532_functest.vhd                                                        --
-- Simulation of np6532 core running Klaus Dormann's 6502 functional test.    --
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
use ieee.math_real.all; -- for uniform function
use ieee.std_logic_textio.all;

library std;
use std.textio.all;
use std.env.all;

library work;
use work.np6532_pkg.all;
use work.np65_decoder_pkg.all;

entity np6532_functest is
    generic (
        vector_init : integer;
        start_address : integer;
        ref_file : string
    );
end entity np6532_functest;

architecture sim of np6532_functest is

    constant clk_ratio      : integer := 3;
    constant clk_mem_period : time := 10 ns;
    constant test_hold      : boolean := true;
    constant test_nmi       : boolean := true;
    constant test_irq       : boolean := true;

    signal clk_phase     : integer range 0 to (clk_ratio*2)-1 := 0;
    signal clk_cpu       : std_logic;
    signal clk_mem       : std_logic;

    signal rst           : std_logic;
    signal rsto          : std_logic;

    signal hold          : std_logic;
    signal nmi           : std_logic;
    signal irq           : std_logic;
    signal if_al         : std_logic_vector(15 downto 0);
    signal if_ap         : std_logic_vector(15 downto 0);
    signal if_z          : std_logic;
    signal ls_al         : std_logic_vector(15 downto 0);
    signal ls_ap         : std_logic_vector(15 downto 0);
    signal ls_en         : std_logic;
    signal ls_re         : std_logic;
    signal ls_we         : std_logic;
    signal ls_wp         : std_logic;
    signal ls_z          : std_logic;
    signal ls_ext        : std_logic;
    signal ls_drx        : std_logic_vector(7 downto 0);
    signal ls_dwx        : std_logic_vector(7 downto 0);
    signal trace_stb     : std_logic;
    signal trace_nmi     : std_logic;
    signal trace_irq     : std_logic;
    signal trace_op      : std_logic_vector(23 downto 0);
    signal trace_pc      : std_logic_vector(15 downto 0);
    signal trace_s       : std_logic_vector(7 downto 0);
    signal trace_p       : std_logic_vector(7 downto 0);
    signal trace_a       : std_logic_vector(7 downto 0);
    signal trace_x       : std_logic_vector(7 downto 0);
    signal trace_y       : std_logic_vector(7 downto 0);
    signal dma_en        : std_logic;
    signal dma_a         : std_logic_vector(15 downto 3);
    signal dma_bwe       : std_logic_vector(7 downto 0);
    signal dma_dw        : std_logic_vector(63 downto 0);
    signal dma_dr        : std_logic_vector(63 downto 0);

    signal trace_pc_prev : std_logic_vector(15 downto 0);
    signal started       : boolean;
    signal count_i       : integer;
    signal count_c       : integer;

    signal interval_nmi  : integer;
    signal count_nmi     : integer;
    signal interval_irq  : integer;
    signal count_irq     : integer;

    signal count_hold    : integer range 0 to 3;
    signal count_hold_0  : integer range 0 to 3;
    signal count_hold_1  : integer range 0 to 3;

    signal test_case     : std_logic_vector(7 downto 0); -- functest code's test case - use to avoid stack test (case 3)

begin

    clk_phase <= (clk_phase+1) mod (clk_ratio*2) after clk_mem_period/2;
    clk_mem <= '1' when clk_phase mod 2 = 0 else '0';
    clk_cpu <= '1' when clk_phase = 0 else '0';

    if_ap <= if_al;
    if_z <= '0';
    ls_ap <= ls_al;
    ls_wp <= '0';
    ls_z <= '0';
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
            wait until rising_edge(clk_cpu);
            if started and hold = '0' and trace_nmi = '0' and trace_irq = '0' then
                count_c <= count_c + 1;
            end if;
            if trace_stb = '1' and trace_nmi = '0' and trace_irq = '0' then
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

    do_track: process(rst, clk_cpu)
    begin
        if rst = '1' then
            started <= false;
            count_i <= 0;
            trace_pc_prev <= (others => 'U');
        elsif falling_edge(clk_cpu) then
            if trace_stb = '1' and trace_nmi = '0' and trace_irq = '0' then
                if to_integer(unsigned(trace_pc)) = start_address then
                    count_i <= 1;
                    started <= true;
                else
                    count_i <= count_i+1;
                end if;
            end if;
        elsif rising_edge(clk_cpu) then
            if trace_stb = '1' then
                trace_pc_prev <= trace_pc;
            end if;
        end if;
    end process;

    dma_en <= '0';
    dma_a <= (others => '0');
    dma_bwe <= (others => '0');
    dma_dw <= (others => '0');

    UUT: component np6532
        generic map (
            clk_ratio     => clk_ratio,
            ram_size_log2 => 16,
            jmp_rst       => std_logic_vector(to_unsigned(vector_init,16)),
            vec_irq       => x"FFF8" -- hijack IRQ to make it invisible to functional test code
        )
        port map (
            rsti      => rst,
            rsto      => rsto,
            clk_cpu   => clk_cpu,
            clk_mem   => clk_mem,
            clken     => open,
            hold      => hold,
            nmi       => nmi,
            irq       => irq,
            if_al     => if_al,
            if_ap     => if_ap,
            if_z      => if_z,
            ls_al     => ls_al,
            ls_ap     => ls_ap,
            ls_en     => ls_en,
            ls_re     => ls_re,
            ls_we     => ls_we,
            ls_wp     => ls_wp,
            ls_z      => ls_z,
            ls_ext    => ls_ext,
            ls_drx    => ls_drx,
            ls_dwx    => ls_dwx,
            trace_stb => trace_stb,
            trace_nmi => trace_nmi,
            trace_irq => trace_irq,
            trace_op  => trace_op,
            trace_pc  => trace_pc,
            trace_s   => trace_s,
            trace_p   => trace_p,
            trace_a   => trace_a,
            trace_x   => trace_x,
            trace_y   => trace_y,
            dma_en    => dma_en,
            dma_a     => dma_a,
            dma_bwe   => dma_bwe,
            dma_dw    => dma_dw,
            dma_dr    => dma_dr
        );

    -- NMI and IRQ testing

    process(clk_cpu)
        variable seed1, seed2 : integer := 123;
        impure function rand_int(min, max : integer) return integer is
            variable r : real;
        begin
            uniform(seed1, seed2, r);
            return integer(round(r*real(max-min+1)+real(min)-0.5));
        end function;
    begin
        if rising_edge(clk_cpu) then
            if rsto = '1' then
                nmi          <= '0';
                irq          <= '0';
                interval_nmi <= 0;
                count_nmi    <= 0;
                interval_irq <= 0;
                count_irq    <= 0;
                test_case    <= (others => '0');
            elsif trace_stb = '1' then -- advex => instruction advance            
                if trace_p(5) = '1' then -- flag X set = init done
                    if test_nmi and nmi = '0' and test_case /= x"03" then
                        if interval_nmi = 0 then
                            nmi <= '1';
                            interval_nmi <= rand_int(0,15);
                        else
                            interval_nmi <= interval_nmi-1;
                        end if;
                    end if;
                    if test_irq and irq = '0' and test_case /= x"03" then
                        if interval_irq = 0 then
                            irq <= '1';
                            interval_irq <= rand_int(0,15);
                        else
                            interval_irq <= interval_irq-1;
                        end if;
                    end if;
                end if;
                -- nmi/irq ack registers/counters
                if ls_we = '1' then
                    if ls_al = x"FE3E" then -- NMI ack
                        count_nmi <= count_nmi+1;
                        nmi <= '0';
                    elsif ls_al = x"FE3F" then -- IRQ ack
                        count_irq <= count_irq+1;
                        irq <= '0';
                    end if;
                end if;
                -- test case
                if ls_we = '1' and ls_al = x"0200" then
                    test_case <= ls_dwx;
                end if;                
            end if;
        end if;
    end process;

    -- hold generation
    -- try combinations of 1-4 cycle assertions and 1-4 cycle gaps

    process(clk_cpu)
    begin
        if rising_edge(clk_cpu) then
            if rsto = '1' then
                hold <= '0';
                count_hold <= 0;
                count_hold_0 <= 0;
                count_hold_1 <= 0;
            elsif test_hold then
                if hold = '0' then
                    if count_hold = count_hold_0 then
                        hold <= '1';
                        count_hold <= 0;
                    else
                        count_hold <= (count_hold+1) mod 4;
                    end if;
                else -- hold = '1'
                    if count_hold = count_hold_1 then
                        hold <= '0';
                        count_hold <= 0;
                        count_hold_1 <= (count_hold_1+1) mod 4;
                        if count_hold_1 = 0 then
                            count_hold_0 <= (count_hold_0+1) mod 4;
                        end if;
                    else
                        count_hold <= count_hold+1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture sim;
