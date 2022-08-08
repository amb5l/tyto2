--------------------------------------------------------------------------------
-- r6522.vhd                                                                  --
-- R6522 compatible Versatile Interface Adapter.                              --
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

package r6522_pkg is

    component r6522 is
        port (

            reg_clk    : in  std_logic;                    -- register interface: clock
            reg_clken  : in  std_logic;                    -- register interface: clock enable
            reg_rst    : in  std_logic;                    -- register interface: reset
            reg_cs     : in  std_logic;                    -- register interface: chip select
            reg_we     : in  std_logic;                    -- register interface: write enable
            reg_rs     : in  std_logic_vector(3 downto 0); -- register interface: register select
            reg_dw     : in  std_logic_vector(7 downto 0); -- register interface: write data
            reg_dr     : out std_logic_vector(7 downto 0); -- register interface: read data
            reg_irq    : out std_logic;                    -- register interface: interrupt request

            io_clk     : in  std_logic;                    -- I/O clock        } typically
            io_clken   : in  std_logic;                    -- I/O clock enable }  1MHz
            io_pa_i    : in  std_logic_vector(7 downto 0); -- I/O port A inputs
            io_pa_o    : out std_logic_vector(7 downto 0); -- I/O port A outputs
            io_pa_dir  : out std_logic_vector(7 downto 0); -- I/O port A directions (1 = out)
            io_ca1     : in  std_logic;
            io_ca2_i   : in  std_logic;
            io_ca2_o   : out std_logic;
            io_ca2_dir : out std_logic;
            io_pb_i    : in  std_logic_vector(7 downto 0); -- I/O port B inputs
            io_pb_o    : out std_logic_vector(7 downto 0); -- I/O port B outputs
            io_pb_dir  : out std_logic_vector(7 downto 0); -- I/O port B directions (1 = out)
            io_cb1_i   : in  std_logic;
            io_cb1_o   : out std_logic;
            io_cb1_dir : out std_logic;
            io_cb2_i   : in  std_logic;
            io_cb2_o   : out std_logic;
            io_cb2_dir : out std_logic

        );
    end component r6522;

end package r6522_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity r6522 is
    port (

        reg_clk    : in  std_logic;                    -- register interface: clock
        reg_clken  : in  std_logic;                    -- register interface: clock enable
        reg_rst    : in  std_logic;                    -- register interface: reset
        reg_cs     : in  std_logic;                    -- register interface: chip select
        reg_we     : in  std_logic;                    -- register interface: write enable
        reg_rs     : in  std_logic_vector(3 downto 0); -- register interface: register select
        reg_dw     : in  std_logic_vector(7 downto 0); -- register interface: write data
        reg_dr     : out std_logic_vector(7 downto 0); -- register interface: read data
        reg_irq    : out std_logic;                    -- register interface: interrupt request

        io_clk     : in  std_logic;                    -- I/O clock        } typically
        io_clken   : in  std_logic;                    -- I/O clock enable }  1MHz
        io_pa_i    : in  std_logic_vector(7 downto 0); -- I/O port A inputs
        io_pa_o    : out std_logic_vector(7 downto 0); -- I/O port A outputs
        io_pa_dir  : out std_logic_vector(7 downto 0); -- I/O port A directions (1 = out)
        io_ca1     : in  std_logic;
        io_ca2_i   : in  std_logic;
        io_ca2_o   : out std_logic;
        io_ca2_dir : out std_logic;
        io_pb_i    : in  std_logic_vector(7 downto 0); -- I/O port B inputs
        io_pb_o    : out std_logic_vector(7 downto 0); -- I/O port B outputs
        io_pb_dir  : out std_logic_vector(7 downto 0); -- I/O port B directions (1 = out)
        io_cb1_i   : in  std_logic;
        io_cb1_o   : out std_logic;
        io_cb1_dir : out std_logic;
        io_cb2_i   : in  std_logic;
        io_cb2_o   : out std_logic;
        io_cb2_dir : out std_logic

    );
end entity r6522;

architecture behavioural of r6522 is

    constant RA_ORB   : std_logic_vector(3 downto 0) := x"0";
    constant RA_ORA   : std_logic_vector(3 downto 0) := x"1";
    constant RA_DDRB  : std_logic_vector(3 downto 0) := x"2";
    constant RA_DDRA  : std_logic_vector(3 downto 0) := x"3";
    constant RA_T1C_L : std_logic_vector(3 downto 0) := x"4";
    constant RA_T1C_H : std_logic_vector(3 downto 0) := x"5";
    constant RA_T1L_L : std_logic_vector(3 downto 0) := x"6";
    constant RA_T1L_H : std_logic_vector(3 downto 0) := x"7";
    constant RA_T2C_L : std_logic_vector(3 downto 0) := x"8";
    constant RA_T2C_H : std_logic_vector(3 downto 0) := x"9";
    constant RA_SR    : std_logic_vector(3 downto 0) := x"A";
    constant RA_ACR   : std_logic_vector(3 downto 0) := x"B";
    constant RA_PCR   : std_logic_vector(3 downto 0) := x"C";
    constant RA_IFR   : std_logic_vector(3 downto 0) := x"D";
    constant RA_IER   : std_logic_vector(3 downto 0) := x"E";
    constant RA_ORA_N : std_logic_vector(3 downto 0) := x"F";


    signal irb        : std_logic_vector(7 downto 0);
    signal irb_lr     : std_logic_vector(7 downto 0);   -- PB inputs and active outputs latched by rising CA1
    signal irb_lf     : std_logic_vector(7 downto 0);   -- PB inputs and active outputs latched by rising CA1
    signal ira        : std_logic_vector(7 downto 0);
    signal ira_lr     : std_logic_vector(7 downto 0);   -- PA inputs latched by rising CA1
    signal ira_lf     : std_logic_vector(7 downto 0);   -- PA inputs latched by falling CA1


    signal orb        : std_logic_vector(7 downto 0);
    signal ora        : std_logic_vector(7 downto 0);
    signal ddrb       : std_logic_vector(7 downto 0);
    signal ddra       : std_logic_vector(7 downto 0);
    signal t1c        : std_logic_vector(15 downto 0);
    alias  t1c_h      : std_logic_vector(7 downto 0) is t1c(15 downto 8);
    alias  t1c_l      : std_logic_vector(7 downto 0) is t1c(7 downto 0);
    signal t1l        : std_logic_vector(15 downto 0);
    alias  t1l_h      : std_logic_vector(7 downto 0) is t1l(15 downto 8);
    alias  t1l_l      : std_logic_vector(7 downto 0) is t1l(7 downto 0);
    signal t2c        : std_logic_vector(15 downto 0);
    alias  t2c_h      : std_logic_vector(7 downto 0) is t2c(15 downto 8);
    alias  t2c_l      : std_logic_vector(7 downto 0) is t2c(7 downto 0);
    signal t2l        : std_logic_vector(7 downto 0);
    signal sr         : std_logic_vector(7 downto 0);
    signal acr        : std_logic_vector(7 downto 0);
    signal pcr        : std_logic_vector(7 downto 0);
    signal ifr        : std_logic_vector(7 downto 0);
    signal clr        : std_logic_vector(7 downto 0);     -- clear interrupt (write 1 to bit of ifr)
    signal ier        : std_logic_vector(7 downto 0);

    signal irq_ca2_r  : std_logic;
    signal irq_ca2_f  : std_logic;
    signal irq_ca1_r  : std_logic;
    signal irq_ca1_f  : std_logic;
    signal irq_cb2_r  : std_logic;
    signal irq_cb2_f  : std_logic;
    signal irq_cb1_r  : std_logic;
    signal irq_cb1_f  : std_logic;

    alias sr_mode     : std_logic_vector(2 downto 0) is acr(4 downto 2);
    alias irq_ca2     : std_logic is ifr(0);
    alias irq_ca1     : std_logic is ifr(1);
    alias irq_sr      : std_logic is ifr(2);
    alias irq_cb2     : std_logic is ifr(3);
    alias irq_cb1     : std_logic is ifr(4);
    alias irq_t2      : std_logic is ifr(5);
    alias irq_t1      : std_logic is ifr(6);

begin

    --------------------------------------------------------------------------------
    -- port A and B outputs

    io_pa_o <= ora;
    io_pa_dir <= ddra;
    io_pb_o <= orb;
    io_pb_dir <= ddrb;

    --------------------------------------------------------------------------------
    -- port A and B input registers with latching

    process(reg_rst,ca1_i)
        if reg_rst = '1' then
            ira_lr <= (others => '0');
        elsif rising_edge(ca1_i) then
            ira_lr <= io_pa_i
        end if;
        if reg_rst = '1' then
            ira_lf <= (others => '0');
        elsif falling_edge(ca1_i) then
            ira_lf <= io_pa_i;
        end if;
    end process;

    ira <=
        ira_lr when acr(0) = '1' and pcr(0) = '1' else
        ira_lf when acr(0) = '1' and pcr(0) = '0' else
        io_pa_i;

    process(reg_rst,cb1_i)
    begin
        if reg_rst = '1' then
            irb_lr <= (others => '0');
        elsif rising_edge(cb1_i) then
            for i in 0 to 7 loop
                if ddrb(i) = '1' then
                    irb_lr(i) <= orb(i);
                else
                    irb_lr(i) <= io_pb_i(i);
                end if;
            end loop;
        end if;
        if reg_rst = '1' then
            irb_lf <= (others => '0');
        elsif falling_edge(cb1_i) then
            for i in 0 to 7 loop
                if ddrb(i) = '1' then
                    irb_lf(i) <= orb(i);
                else
                    irb_lf(i) <= io_pb_i(i);
                end if;
            end loop;
        end if;
    end process;

    GEN_IRB: for i in 0 to 7 generate
        irb(i) <=
            irb_lr(i) when acr(1) = '1' and pcr(4) = '1' else
            irb_lf(i) when acr(1) = '1' and pcr(4) = '0' else
            io_pb_i(i) when ddrb(i) = '0' else
            orb(i);
    end generate GEN_IRB;

    --------------------------------------------------------------------------------
    -- CA1

    process(io_ca1,clr(1),ora_access)
    begin
        if clr(1) = '1' or ora_access = '1' then
            irq_ca1_r <= '0';
        elsif rising_edge(io_ca1) then
            irq_ca1_r <= '1';
        end if;
        if clr(1) = '1' or ora_access = '1' then
            irq_ca1_f <= '0';
        elsif falling_edge(io_ca1) then
            irq_ca1_f <= '1';
        end if;
    end process

    irq_ca1 <= irq_ca1_f when pcr(0) = '0' else irq_ca1_r;

   --------------------------------------------------------------------------------
    -- CA2

    process(io_ca2_i,clr(0),ora_access)
    begin
        if clr(0) = '1' or (ora_access = '1' and pcr(3) = '0' and pcr(1) = '1') then
            irq_ca2_r <= '0';
        elsif rising_edge(io_ca2_i) and pcr(3) = '0' then
            irq_ca2_r <= '1';
        end if;
        if clr(0) = '1' or (ora_access = '1' and pcr(1) = '0') then
            irq_ca2_f <= '0';
        elsif falling_edge(io_ca2_i) and pcr(3) = '0' then
            irq_ca2_f <= '1';
        end if;
    end process

    irq_ca2 <=
        irq_ca2_f when pcr(3 downto 2) = "00" else
        irq_ca2_r when pcr(3 downto 2) = "01" else
        '0';

    io_ca2_dir <= pcr(3);
    io_ca2_o <=
        handshake when pcr(3 downto 1) = "100" else
        pulse when pcr(3 downto 1) = "101" else
        '0' when pcr(3 downto 1) = "110" else
        '1' when pcr(3 downto 1) = "111" else
        '0';

    --------------------------------------------------------------------------------
    -- CB1

    process(cb1,clr(4),orb_access)
    begin
        if clr(4) = '1' or orb_access = '1' then
            irq_cb1_r <= '0';
        elsif rising_edge(cb1) then
            irq_cb1_r <= '1';
        end if;
        if clr(4) = '1' or orb_access = '1' then
            irq_cb1_f <= '0';
        elsif falling_edge(cb1) then
            irq_cb1_f <= '1';
        end if;
    end process

    irq_cb1 <= irq_cb1_f when pcr(4) = '0' else irq_cb1_r;



    io_cb1_o <=
        t2_reload   when sr_mode = "001" or sr_mode = "100" or sr_mode = "101" else
        ...

    io_cb1_dir <= '1' when
        sr_mode /= "001" or
        ...
        else '0';

   --------------------------------------------------------------------------------
    -- CB2

    process(cb2_i,clr(3),orb_access)
    begin
        if clr(3) = '1' or (orb_access = '1' and pcr(7) = '0' and pcr(5) = '1') then
            irq_cb2_r <= '0';
        elsif rising_edge(cb2_i) and pcr(7) = '0' then
            irq_cb2_r <= '1';
        end if;
        if clr(3) = '1' or (orb_access = '1' and pcr(7) = '0' and pcr(5) = '1') then
            irq_cb2_f <= '0';
        elsif falling_edge(cb2_i) and pcr(7) = '0' then
            irq_cb2_f <= '1';
        end if;
    end process

    irq_cb2 <=
        irq_cb2_f when pcr(7 downto 6) = "00" else
        irq_cb2_r when pcr(7 downto 6) = "01" else
        '0';

    io_cb2_dir <= pcr(7);
    io_cb2_o <=
        handshake when pcr(7 downto 5) = "100" else
        pulse when pcr(7 downto 5) = "101" else
        '0' when pcr(7 downto 5) = "110" else
        '1' when pcr(7 downto 5) = "111" else
        '0';

    io_cb2_o <=
        sr(7) when sr_mode(2) = '1' else
        ...

    io_cb2_dir <= '1' when
        sr_mode(2) = '1' or
        ...
        else '0';

    --------------------------------------------------------------------------------








    sr_clk <=
        not_clk when sr_mode = "000" else
        cb1_i   when sr_mode(1 downto 0) = "11" else
        cb1_o;

    with sr_mode select sr_clk <=
        not clk     when "000", -- disabled, CPU register access only
        cb1_o       when "001", -- shift in, clock driven out on CB1 from T2
        cb1_o       when "010", -- shift in, clock derived from sys clk
        cb1_i       when "011", -- shift in, CB1 = clock input
        cb1_o       when "100", -- shift out, free running, clock driven out on CB1 from T2
        cb1_o       when "101", -- shift out, clock driven out on CB1 from T2
        cb1_o       when "110", -- shift out, clock out on CB1 derived from sys clk
        cb1_i       when "111";

    process(sr_mode,sr_clk)
    begin
        if rising_edge(sr_clk) then
            case sr_mode is
                when "000" =>
                    if cs_1 = '1' and we_1 = '1' and rs_1 = RA_SR then
                        sr <= dw_1;
                    end if;
                when "001" =>
                    sr
                    sr_count <= std_logic_vector(unsigned(sr_count)+1);
                    if sr_count = "111" then
                        irq_sr <= '1';
                    end if;
                when "010" =>
                    -- generate clk/2

                when "011" => -- data in on CB2

            end case;
        end if;
        if sr_mode = "000" then
            irq_sr <= '0';
        end if;

    end process;


    --------------------------------------------------------------------------------

    irq_sr <=
        '0' when sr_mode = "000" else




    process(ifr,ier)
        variable irq : std_logic;
    begin
        irq := '0';
        for i in 0 to 7 loop
            irq := irq or (ifr(i) and ier(i));
        end loop;
        ifr(7) <= irq;
    end process;

    irq <= ifr(7);

    --------------------------------------------------------------------------------
    -- timer

    process(io_clk)
    begin
        if rising_edge(io_clk)
            if io_rst = '1' then
                t1c <= (others => '0');
            elsif io_clken = '1' then                
                if t1c = x"0000" then
                    t1c <= t1l;
                else
                    t1c <= std_logic_vector(unsigned(t1c)-1);
                end if;
            end if;
    end process;

    --------------------------------------------------------------------------------
    -- register writes

    process(reg_clk)
    begin
        if rising_edge(reg_clk) and reg_clken = '1' then
            if reg_rst = '1' then
                orb  <= (others => '0');
                ora  <= (others => '0');
                ddrb <= (others => '0');
                ddra <= (others => '0');
                acr  <= (others => '0');
                pcr  <= (others => '0');
                ifr  <= (others => '0');
                clr  <= (others => '0');
                ier  <= (others => '0');
            else
                orb_access <= bool2sl(rs=RA_ORB);
                ora_access <= bool2sl(rs=RA_ORA);
                t1c_l_read <= bool2sl(rs=RA_T1C_L and reg_we = '0');
                clr <= (others => '0');
                if reg_we = '1' then
                    case reg_rs is
                        when RA_ORB     => orb   <= reg_dw;
                        when RA_ORA_H   => ora   <= reg_dw;
                        when RA_DDRB    => ddrb  <= reg_dw;
                        when RA_DDRA    => ddra  <= reg_dw;
                        when RA_T1L_L   => t1l_l <= reg_dw;
                        when RA_T1C_H   => t1l_h <= reg_dw; t1c_h <= reg_dw; t1c_l <= t1l;
                        when RA_T1L_L   => t1l_l <= reg_dw;
                        when RA_T1L_H   => t1l_h <= reg_dw;
                        when RA_T2L_L   => t2l   <= reg_dw;
                        when RA_T2C_H   => t2c_h <= reg_dw; t2c_l <= t2l_l;
                        when RA_SR      => null; -- handled separately
                        when RA_ACR     => acr   <= reg_dw;
                        when RA_PCR     => pcr   <= reg_dw;
                        when RA_IFR     => clr   <= reg_dw;
                        when RA_IER     => ier   <= reg_dw;
                        when RA_ORA_NH  => ora   <= reg_dw;
                    end case;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- register reads

    with reg_rs select reg_dr <=
        irb   when RA_ORB,
        ira   when RA_ORA_H,
        ddrb  when RA_DDRB,
        ddra  when RA_DDRA,
        t1c_l when RA_T1C_L,
        t1c_h when RA_T1C_H,
        t1l_l when RA_T1L_L,
        t1l_h when RA_T1L_H,
        t2c_l when RA_T2C_L,
        t2c_h when RA_T2C_H,
        sr    when RA_SR,
        acr   when RA_ACR,
        pcr   when RA_PCR,
        ifr   when RA_IFR,
        ier   when RA_IER,
        ora   when RA_ORA_NH,
        x"00" when others;

    --------------------------------------------------------------------------------

end architecture behavioural;