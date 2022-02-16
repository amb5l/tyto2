--------------------------------------------------------------------------------
-- T65_functest.vhd                                                           --
-- Simulation of T65 core running Klaus Dormann's 6502 functional test.       --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
--                                                                            --
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
use std.env.finish;

library work;
use work.T65_Pack.all;

entity T65_functest is
    generic (
        bin_file : string;
        ref_file : string;
        start_address : integer
    );
end entity T65_functest;

architecture sim of T65_functest is

    component T65 is
        port(
            Mode    : in  std_logic_vector(1 downto 0);      -- "00" => 6502, "01" => 65C02, "10" => 65C816
            BCD_en  : in  std_logic := '1';             -- '0' => 2A03/2A07, '1' => others

            Res_n   : in  std_logic;
            Enable  : in  std_logic;
            Clk     : in  std_logic;
            Rdy     : in  std_logic := '1';
            Abort_n : in  std_logic := '1';
            IRQ_n   : in  std_logic := '1';
            NMI_n   : in  std_logic := '1';
            SO_n    : in  std_logic := '1';
            R_W_n   : out std_logic;
            Sync    : out std_logic;
            EF      : out std_logic;
            MF      : out std_logic;
            XF      : out std_logic;
            ML_n    : out std_logic;
            VP_n    : out std_logic;
            VDA     : out std_logic;
            VPA     : out std_logic;
            A       : out std_logic_vector(23 downto 0);
            DI      : in  std_logic_vector(7 downto 0);
            DO      : out std_logic_vector(7 downto 0);
            -- 6502 registers (MSB) PC, SP, P, Y, X, A (LSB)
            Regs    : out std_logic_vector(63 downto 0);
            DEBUG   : out T_t65_dbg;
            NMI_ack : out std_logic
        );
    end component T65;

    signal clk           : std_logic;

    signal res_n         : std_logic;
    signal r_w_n         : std_logic;
    signal sync          : std_logic;
    signal a             : std_logic_vector(23 downto 0);
    signal di            : std_logic_vector(7 downto 0);
    signal do            : std_logic_vector(7 downto 0);
    signal regs          : std_logic_vector(63 downto 0);
    signal regs_pc       : std_logic_vector(15 downto 0); -- signals can be added to waveform, aliases cannot
    signal regs_s        : std_logic_vector(7 downto 0);
    signal regs_p        : std_logic_vector(7 downto 0);
    signal regs_y        : std_logic_vector(7 downto 0);
    signal regs_x        : std_logic_vector(7 downto 0);
    signal regs_a        : std_logic_vector(7 downto 0);

    signal sync_1        : std_logic;
    signal regs_pc_1     : std_logic_vector(15 downto 0);
    signal regs_pc_2     : std_logic_vector(15 downto 0);

    signal trace_pc_prev : std_logic_vector(15 downto 0);
    signal trace_pc      : std_logic_vector(15 downto 0);
    signal trace_s       : std_logic_vector(7 downto 0);
    signal trace_p       : std_logic_vector(7 downto 0);
    signal trace_a       : std_logic_vector(7 downto 0);
    signal trace_x       : std_logic_vector(7 downto 0);
    signal trace_y       : std_logic_vector(7 downto 0);
    signal trace_stb     : std_logic;

    signal started       : boolean;
    signal count_i       : integer;
    signal count_c       : integer;

    type ram_64k_t is array(65535 downto 0) of integer range 0 to 255;
    signal ram : ram_64k_t;

begin

    -- 1MHz clock
    clk <=
        '1' after 500 ns when clk = '0' else
        '0' after 500 ns when clk = '1' else
        '0';

    do_test: process
        file f : text open read_mode is ref_file;
        variable l : line;
        variable ref_pc : std_logic_vector(15 downto 0);
        variable ref_s, ref_p, ref_a, ref_x, ref_y : std_logic_vector(7 downto 0);
    begin
        count_c <= 1;
        res_n <= '0';
        wait for 5 us;
        res_n <= '1';
        while not endfile(f) loop
            wait until rising_edge(clk);
            if started then
                count_c <= count_c + 1;
            end if;
            if trace_stb = '1' then
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
        report "*** END OF FILE ***";
        report "instruction count: " & integer'image(count_i) & "  cycle count: " & integer'image(count_c);
        finish;
    end process do_test;

    UUT: component T65
        port map (
            Mode    => "00",
            BCD_en  => '1',
            Res_n   => res_n,
            Enable  => '1',
            Clk     => clk,
            Rdy     => '1',
            Abort_n => '1',
            IRQ_n   => '1',
            NMI_n   => '1',
            SO_n    => '1',
            R_W_n   => r_w_n,
            Sync    => sync,
            EF      => open,
            MF      => open,
            XF      => open,
            ML_n    => open,
            VP_n    => open,
            VDA     => open,
            VPA     => open,
            A       => a,
            DI      => di,
            DO      => do,
            Regs    => regs,
            DEBUG   => open,
            NMI_ack => open
        );

    regs_pc <= regs(63 downto 48);
    regs_s  <= regs(39 downto 32);
    regs_p  <= regs(31 downto 24);
    regs_y  <= regs(23 downto 16);
    regs_x  <= regs(15 downto 8);
    regs_a  <= regs(7 downto 0);

    di <= do when r_w_n = '0' else std_logic_vector(to_unsigned(ram(to_integer(unsigned(a(15 downto 0)))) , 8));
    do_ram: process(res_n, clk)
        impure function raminit return ram_64k_t is
            type char_file_t is file of character;
            file file_in    : char_file_t open read_mode is bin_file;
            variable c      : character;
            variable m  : ram_64k_t := (others => 0);
        begin
            for i in 0 to 65535 loop
                read(file_in, c);
                m(i) := character'POS(c);
            end loop;
            file_close(file_in);
            -- set reset vector to 0x400
            m(16#FFFC#) := 0;
            m(16#FFFD#) := 4;
            return m;
        end function raminit;
    begin
        if rising_edge(res_n) then
            ram <= raminit;
        elsif rising_edge(clk) then
            if r_w_n = '0' then
                ram(to_integer(unsigned(a(15 downto 0)))) <= to_integer(unsigned(do));
            end if;
        end if;
    end process do_ram;

    do_trace: process(res_n, clk)
    begin
        if res_n = '0' then
            sync_1        <= '0';
            regs_pc_1     <= regs_pc;
            regs_pc_2     <= regs_pc_1;
            started       <= false;
            count_i       <= 0;
            trace_stb     <= '0';
            trace_pc_prev <= (others => 'U');
            trace_pc      <= (others => 'U');
            trace_s       <= (others => 'U');
            trace_p       <= (others => 'U');
            trace_a       <= (others => 'U');
            trace_x       <= (others => 'U');
            trace_y       <= (others => 'U');
        elsif rising_edge(clk) then
            sync_1 <= sync;
            regs_pc_1 <= regs_pc;
            regs_pc_2 <= regs_pc_1;
            trace_stb <= '0';
            if sync_1 = '1' then -- capture final register states resulting from previous instruction
                count_i       <= count_i + 1;
                trace_pc_prev <= trace_pc;
                trace_pc      <= to_stdlogicvector(to_bitvector(regs_pc_1));
                trace_s       <= to_stdlogicvector(to_bitvector(regs_s));
                trace_p       <= to_stdlogicvector(to_bitvector(regs_p));
                trace_a       <= to_stdlogicvector(to_bitvector(regs_a));
                trace_x       <= to_stdlogicvector(to_bitvector(regs_x));
                trace_y       <= to_stdlogicvector(to_bitvector(regs_y));
                if (to_integer(unsigned(regs_pc_1)) = start_address) or started then
                    trace_stb <= '1';
                    started <= true;
                end if;
            end if;
        end if;
    end process do_trace;

end architecture sim;
