--------------------------------------------------------------------------------
-- np6532s_poc.vhd                                                            --
-- Minimal proof of concept for np6532s CPU. Requires board specific wrapper. --
-- Can be built with 64k, 128k or 256k of physical RAM. Uses Acorn BBC Micro  --
-- approach to accessing RAM beyond 64k (16k "sideways" bank switching).      --
-- RAM size is controlled by generic. Supports 64k, 128k and 256k.            --
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

package np6532s_poc_pkg is

    component np6532s_poc is
        generic (
            ram_size_log2 : integer;
            success_addr  : integer
        );
        port (

            clk    : in  std_logic;
            rst    : in  std_logic;
            hold   : in  std_logic;
            irq    : in  std_logic;
            nmi    : in  std_logic;
            dma_ti : in  std_logic_vector(5 downto 0);
            dma_to : out std_logic_vector(7 downto 0);
            led    : out std_logic_vector(7 downto 0)

        );
    end component np6532s_poc;

end package np6532s_poc_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.np6532s_pkg.all;

entity np6532s_poc is
    generic (
        ram_size_log2 : integer;
        success_addr  : integer        
    );
    port (

        clk    : in  std_logic;
        rst    : in  std_logic;
		hold   : in  std_logic;
		irq    : in  std_logic;
		nmi    : in  std_logic;
        dma_ti : in  std_logic_vector(5 downto 0);
        dma_to : out std_logic_vector(7 downto 0);
        led    : out std_logic_vector(7 downto 0)

    );
end entity np6532s_poc;

architecture synth of np6532s_poc is

    signal  if_al           : std_logic_vector(15 downto 0);
    signal  if_ap           : std_logic_vector(17 downto 0);
    signal  if_z            : std_logic;

    signal  ls_al           : std_logic_vector(15 downto 0);
    signal  ls_ap           : std_logic_vector(17 downto 0);
    signal  ls_en           : std_logic;
    signal  ls_re           : std_logic;
    signal  ls_we           : std_logic;
    signal  ls_z            : std_logic;
    signal  ls_wp           : std_logic;
    signal  ls_ext          : std_logic;
    signal  ls_drx          : std_logic_vector(7 downto 0);
    signal  ls_dwx          : std_logic_vector(7 downto 0);

    signal  trace_en        : std_logic;
    signal  trace_pc        : std_logic_vector(15 downto 0);
    signal  trace_pc_prev   : std_logic_vector(15 downto 0);
    signal  rst_core        : std_logic;
    signal  pulse           : std_logic;
    signal  success         : std_logic;

    signal  sideways_bank   : std_logic_vector(3 downto 0); -- MS bits of physical RAM address of sideways bank
    signal  sideways_z      : std_logic;                    -- 1 = sideways bank does not physically exist
    signal  sideways_wp     : std_logic;                    -- 1 = sideways bank is write protected

    signal  hw_reg_romsel   : std_logic_vector(3 downto 0);
    signal  hw_reg_wp       : std_logic_vector(15 downto 0);
    alias   hw_reg_wp0      : std_logic_vector(7 downto 0) is hw_reg_wp(7 downto 0);
    alias   hw_reg_wp1      : std_logic_vector(7 downto 0) is hw_reg_wp(15 downto 8);
    signal  hw_reg_led      : std_logic_vector(7 downto 0);
    signal  hw_reg_timer    : std_logic_vector(31 downto 0);
    alias   hw_reg_tim0     : std_logic_vector(7 downto 0) is hw_reg_timer(7 downto 0);
    signal  hw_reg_tim1     : std_logic_vector(7 downto 0);
    signal  hw_reg_tim2     : std_logic_vector(7 downto 0);
    signal  hw_reg_tim3     : std_logic_vector(7 downto 0);

    signal  dma_en          : std_logic;
    signal  dma_a           : std_logic_vector(ram_size_log2-1 downto 3);
    signal  dma_bwe         : std_logic_vector(7 downto 0);
    signal  dma_dw          : std_logic_vector(63 downto 0);
    signal  dma_dr          : std_logic_vector(63 downto 0);

    attribute keep_hierarchy : string;
    attribute keep_hierarchy of CORE : label is "yes";

    -- hardware register addresses (offsets from FE00)
    constant RA_ROMSEL  : std_logic_vector(7 downto 0) := x"30";
    constant RA_WP0     : std_logic_vector(7 downto 0) := x"3E";
    constant RA_WP1     : std_logic_vector(7 downto 0) := x"3F";
    constant RA_LED     : std_logic_vector(7 downto 0) := x"70";
    constant RA_TIM0    : std_logic_vector(7 downto 0) := x"78";
    constant RA_TIM1    : std_logic_vector(7 downto 0) := x"79";
    constant RA_TIM2    : std_logic_vector(7 downto 0) := x"7A";
    constant RA_TIM3    : std_logic_vector(7 downto 0) := x"7B";

begin

    led(0) <= pulse;
    led(1) <= success;
    led(7 downto 2) <= hw_reg_led(5 downto 0);

    CORE: component np6532s
        generic map (
            ram_size_log2 => ram_size_log2,
            vector_init   => x"FC00"
        )
        port map (
            clk         => clk,
            hold        => hold,
            rst         => rst_core,
            nmi         => nmi,
            irq         => irq,
            if_al       => if_al,
            if_ap       => if_ap(ram_size_log2-1 downto 0),
            if_z        => if_z,
            ls_al       => ls_al,
            ls_ap       => ls_ap(ram_size_log2-1 downto 0),
            ls_en       => ls_en,
            ls_re       => ls_re,
            ls_we       => ls_we,
            ls_wp       => ls_wp,
            ls_ext      => ls_ext,
            ls_drx      => ls_drx,
            ls_dwx      => ls_dwx,
            trace_en    => trace_en,
            trace_pc    => trace_pc,
            trace_s     => open,
            trace_p     => open,
            trace_a     => open,
            trace_x     => open,
            trace_y     => open,
            dma_a       => dma_a,
            dma_bwe     => dma_bwe,
            dma_dw      => dma_dw,
            dma_dr      => dma_dr


        );

    -- infinite loop => reset, toggle LED
    process(rst, clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rst_core <= '1';
                pulse <= '0';
                success <= '0';
                trace_pc_prev <= x"FFFC"; -- initial PC can *never* equal this
            else
                rst_core <= '0';
                if trace_en = '1' then
                    if trace_pc = trace_pc_prev then
                        rst_core <= '1';
                        if rst_core = '0' then
                            pulse <= not pulse;
                        end if;
                        success <= '0';
                        if success_addr = to_integer(unsigned(trace_pc)) then
                            success <= '1';
                        end if;
                    end if;
                    trace_pc_prev <= trace_pc;                
                end if;
            end if;
        end if;
    end process;

    -- logical (CPU) memory map:
    --  region      contents
    --  0000-3FFF   lower 16k of fixed RAM
    --  4000-7FFF   upper 16k of fixed RAM
    --  8000-BFFF   sideways RAM banks (1, 4 or 12)
    --  C000-FBFF   ROM
    --  FC00-FEFF   hardware
    --  FF00-FFFF   ROM

    -- physical RAM memory map:
    --  region      contents                64k     128k    256k
    --  00000-03FFF lower 16k of fixed RAM
    --  04000-07FFF upper 16k of fixed RAM
    --  08000-0BFFF sideways RAM bank:      15      15      15
    --  0C000-0FFFF ROM
    --  10000-13FFF sideways RAM bank:       -      3       11
    --  14000-17FFF sideways RAM bank:       -      2       10
    --  18000-1BFFF sideways RAM bank:       -      1       9
    --  1C000-1FFFF sideways RAM bank:       -      0       8
    --  20000-23FFF sideways RAM bank:       -      -       7
    --  24000-27FFF sideways RAM bank:       -      -       6
    --  28000-2BFFF sideways RAM bank:       -      -       5
    --  2C000-2FFFF sideways RAM bank:       -      -       4
    --  30000-33FFF sideways RAM bank:       -      -       3
    --  34000-37FFF sideways RAM bank:       -      -       2
    --  38000-3BFFF sideways RAM bank:       -      -       1
    --  3C000-3FFFF sideways RAM bank:       -      -       0

    if_ap(13 downto 0) <= if_al(13 downto 0);
    with if_al(15 downto 14) select if_ap(17 downto 14) <=
        "0000" when "00",           -- lower 16k of fixed RAM
        "0001" when "01",           -- upper 16k of fixed RAM
        "0011" when "11",           -- ROM
        sideways_bank when others;  -- sideways RAM banks

    if_z <= sideways_z when if_al(15 downto 14) = "10" else '0';

    ls_ap(13 downto 0) <= ls_al(13 downto 0);
    with ls_al(15 downto 14) select ls_ap(17 downto 14) <=
        "0000" when "00",           -- lower 16k of fixed RAM
        "0001" when "01",           -- upper 16k of fixed RAM
        "0011" when "11",           -- ROM
        sideways_bank when others;  -- sideways RAM banks

    ls_z <= sideways_z when ls_al(15 downto 14) = "10" else '0';

    ls_wp <=
        '1' when ls_al(15 downto 14) = "11" else
        sideways_wp when ls_al(15 downto 14) = "10" else
        '0';

    ls_ext <= '1' when ls_al(15 downto 10) = "111111"
        and ls_al(9 downto 8) /= "11" else '0';

    -- hardware registers
    -- ROMSEL   sideways bank select (0..15)
    -- WP0      write protect for sideways banks 0..7
    -- WP1      write protect for sideways banks 8..15

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then -- synchronous reset
                hw_reg_romsel <= (others => '1');
                sideways_bank <= (1 => '1', others => '0');
                sideways_z <= '0';
                sideways_wp <= '0';
                hw_reg_wp <= (others => '0');
                hw_reg_led <= (others => '0');
                hw_reg_timer <= (others => '0');
            else
                hw_reg_timer <= std_logic_vector(unsigned(hw_reg_timer)+1);
                if ls_al(15 downto 8) = x"FE" then
                    if ls_we = '1' then -- writes
                        case ls_al(7 downto 0) is
                            when RA_ROMSEL =>
                                hw_reg_romsel <= ls_dwx(3 downto 0);
                                sideways_bank <= "0010";
                                sideways_z <= '0';
                                sideways_wp <= hw_reg_wp(15);
                                if (ram_size_log2 = 17) then -- 128k
                                    if ls_dwx(3 downto 2) = "00" then
                                        sideways_bank <= "01" & not ls_dwx(1 downto 0);
                                        sideways_wp <= hw_reg_wp(to_integer(unsigned(ls_dwx(1 downto 0))));
                                    else
                                        sideways_z <= '1';
                                        sideways_wp <= '1';
                                    end if;
                                elsif (ram_size_log2 = 18) then -- 256k
                                    if to_integer(unsigned(ls_dwx(3 downto 0))) < 12 then
                                        sideways_bank <= std_logic_vector(to_unsigned(15-to_integer(unsigned(ls_dwx(3 downto 0))),4));
                                        sideways_wp <= hw_reg_wp(to_integer(unsigned(ls_dwx(3 downto 0))));
                                    else
                                        sideways_z <= '1';
                                        sideways_wp <= '1';
                                    end if;
                                end if;
                            when RA_WP0 =>
                                hw_reg_wp0 <= ls_dwx;
                            when RA_WP1 =>
                                hw_reg_wp1 <= ls_dwx;
                            when RA_LED =>
                                hw_reg_led <= ls_dwx;
                            when RA_TIM0 =>
                            when RA_TIM1 =>
                            when RA_TIM2 =>
                            when RA_TIM3 =>
                                hw_reg_timer <= (others => '0');
                            when others =>
                                null;
                        end case;
                    else -- reads
                        case ls_al(7 downto 0) is
                            when RA_ROMSEL => ls_drx <= "0000" & hw_reg_romsel;
                            when RA_WP0    => ls_drx <= hw_reg_wp0;
                            when RA_WP1    => ls_drx <= hw_reg_wp1;
                            when RA_LED    => ls_drx <= hw_reg_led;
                            when RA_TIM0   => ls_drx <= hw_reg_tim0;
                                              hw_reg_tim1 <= hw_reg_timer(15 downto 8);
                                              hw_reg_tim2 <= hw_reg_timer(23 downto 16);
                                              hw_reg_tim3 <= hw_reg_timer(31 downto 24);
                            when RA_TIM1   => ls_drx <= hw_reg_tim1;
                            when RA_TIM2   => ls_drx <= hw_reg_tim2;
                            when RA_TIM3   => ls_drx <= hw_reg_tim3;
                            when others    => ls_drx <= x"00";
                        end case;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- dummy DMA stuff

    process(clk)
        variable i: integer;
    begin
        if rising_edge(clk) then
        	if dma_ti(0) = '1' then
        		dma_a <= (others => '0');
        	else
        		dma_a <= std_logic_vector(unsigned(dma_a)+1);
        	end if;
        	if dma_ti(1) = '1' then
        		dma_bwe <= (others => '0');
        	else
        		dma_bwe <= std_logic_vector(unsigned(dma_bwe)+1);
        	end if;
        	if dma_ti(2) = '1' then
        		dma_dw <= (others => '0');
        	else
        		dma_dw <= std_logic_vector(unsigned(dma_dw)+1);
        	end if;
            i := to_integer(unsigned(dma_ti(5 downto 3)));
            dma_to <= dma_dr(7+(i*8) downto i*8);
       end if;
    end process;

end architecture synth;
