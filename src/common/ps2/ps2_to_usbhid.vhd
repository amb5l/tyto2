--------------------------------------------------------------------------------
-- ps2_to_usbhid.vhd                                                          --
-- PS/2 to USB HID transcoder.                                                --
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

package ps2_to_usbhid_pkg is

    component ps2_to_usbhid is
        generic (
            nonUS    : boolean := true                   -- set false for US keyboards
        );
        port (
            clk      : in  std_logic;                    -- clock (>30MHz recommended)
            rst      : in  std_logic;                    -- reset
            ps2_stb  : in  std_logic;                    -- PS/2 code strobe
            ps2_data : in  std_logic_vector(7 downto 0); -- PS/2 code data
            hid_stb  : out std_logic;                    -- USB HID code strobe
            hid_data : out std_logic_vector(7 downto 0); -- USB HID code data
            hid_make : out std_logic                     -- USB HID make (1) or break (0)
        );
    end component ps2_to_usbhid;

end package ps2_to_usbhid_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tyto_types_pkg.all;
use work.ps2set_to_usbhid_pkg.all; -- PS/2 set specific data

entity ps2_to_usbhid is
    generic (
        nonUS    : boolean := true                   -- set false for US keyboards
    );
    port (
        clk      : in  std_logic;                    -- clock (>30MHz recommended)
        rst      : in  std_logic;                    -- reset
        ps2_stb  : in  std_logic;                    -- PS/2 code strobe
        ps2_data : in  std_logic_vector(7 downto 0); -- PS/2 code data
        hid_stb  : out std_logic;                    -- USB HID code strobe
        hid_data : out std_logic_vector(7 downto 0); -- USB HID code data
        hid_make : out std_logic                     -- USB HID make (1) or break (0)
    );
end entity ps2_to_usbhid;

architecture synth of ps2_to_usbhid is

    constant tbl_size : integer := 512;
    constant tbl_init_data : slv_8_0_t := ps2set_to_usbhid(nonUS);
    function tbl_init(tbl_size : integer; tbl_init_data : slv_8_0_t) return slv_8_0_t is
        variable r : slv_8_0_t(0 to tbl_size-1);
    begin
        r := (others => (others => '0'));
        for i in 0 to tbl_init_data'length-1 loop
            r(i) := tbl_init_data(i);
        end loop;
        return r;
    end function tbl_init;
    constant tbl : slv_8_0_t(0 to 511) := tbl_init(tbl_size,tbl_init_data);

    signal ps2_code : std_logic_vector(7 downto 0); -- latches ps2_data

    signal len       : integer range 0 to 7; -- PS/2 sequence length so far
    signal i         : integer range 0 to 7; -- index into a PS/2 sequence during search
    signal tbl_addr  : integer range 0 to tbl'length-1;
    signal tbl_data  : std_logic_vector(8 downto 0);
    signal last      : std_logic;

    alias tbl_last   : std_logic is tbl_data(8);
    alias tbl_prefix : std_logic is tbl_data(8);
    alias tbl_code   : std_logic_vector(7 downto 0) is tbl_data(7 downto 0);


    signal hid_code  : std_logic_vector(7 downto 0);
    signal prefix    : slv_7_0_t(0 to 6);

    type state_t is (
            IDLE,
            NEXT_CODE,
            MAKE_PREFIX,
            MAKE_MATCH,
            MAKE_SKIP,
            BREAK_PREFIX,
            BREAK_MATCH,
            BREAK_SKIP
        );
    signal state     : state_t;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            tbl_data <= tbl(tbl_addr); -- synchronous ROM
            hid_stb <= '0';
            if rst = '1' then
                state <= IDLE;
                tbl_addr <= 0;
                last <= '0';
                len <= 0;
                i <= 0;
                hid_code <= (others => '0');
                ps2_code <= (others => '0');
                hid_data <= (others => '0');
                hid_make <= '0';
            else
                tbl_addr <= tbl_addr+1; -- address advances unless held
                case state is

                    when IDLE =>
                        if ps2_stb = '1' then
                            state <= NEXT_CODE;
                            ps2_code <= ps2_data;
                        else
                            tbl_addr <= 0;
                        end if;

                    when NEXT_CODE => -- get HID code for next entry
                        if last = '0' then
                            hid_code <= tbl_code;
                            last <= tbl_last;
                            if len = 0 then
                                state <= MAKE_MATCH;
                            else
                                state <= MAKE_PREFIX;
                            end if;
                        else -- no match found
                            state <= IDLE;
                            tbl_addr <= 0;
                            last <= '0';
                            len <= 0;
                        end if;

                    when MAKE_PREFIX => -- check currently prefix(es)
                        if tbl_prefix = '1' and tbl_code = prefix(i) then
                            if i = len-1 then -- prefixes match so far
                                state <= MAKE_MATCH;
                                i <= 0;
                            else
                                i <= i+1;
                            end if;
                        else
                            if tbl_prefix = '0' then
                                state <= BREAK_PREFIX;
                                i <= 0;
                            else
                                state <= MAKE_SKIP;
                            end if;
                        end if;

                    when MAKE_MATCH => -- check for make match
                        if tbl_code = ps2_code then -- potential match
                            if tbl_prefix = '0' then -- full match
                                state <= IDLE;
                                tbl_addr <= 0;
                                last <= '0';
                                len <= 0;
                                hid_stb <= '1';
                                hid_data <= hid_code;
                                hid_make <= '1';
                            else -- prefix match
                                state <= IDLE;
                                tbl_addr <= 0;
                                last <= '0';
                                prefix(len) <= ps2_code;
                                len <= len+1;
                            end if;
                        else -- no match, move on to check break
                            if tbl_prefix = '0' then
                                if len = 0 then
                                    state <= BREAK_MATCH;
                                else
                                    state <= BREAK_PREFIX;
                                end if;
                            else
                                state <= MAKE_SKIP;
                            end if;
                        end if;

                    when MAKE_SKIP => -- skip remaining make code(s)
                        if tbl_prefix = '0' then -- last code
                            if len = 0 then
                                state <= BREAK_MATCH;
                            else
                                state <= BREAK_PREFIX;
                            end if;
                        end if;

                    when BREAK_PREFIX => -- check currently prefix(es)
                        if tbl_prefix = '1' and tbl_code = prefix(i) then
                            if i = len-1 then -- prefixes match so far
                                state <= BREAK_MATCH;
                                i <= 0;
                            else
                                i <= i+1;
                            end if;
                        else
                            if tbl_prefix = '0' then
                                state <= NEXT_CODE;
                                i <= 0;
                            else
                                state <= BREAK_SKIP;
                            end if;
                        end if;

                    when BREAK_MATCH => -- check this entry for a break match
                        if tbl_code = ps2_code then -- potential match
                            if tbl_prefix = '0' then -- full match
                                state <= IDLE;
                                tbl_addr <= 0;
                                last <= '0';
                                len <= 0;
                                hid_stb <= '1';
                                hid_data <= hid_code;
                                hid_make <= '0';
                            else -- prefix match
                                state <= IDLE;
                                tbl_addr <= 0;
                                last <= '0';
                                prefix(len) <= ps2_code;
                                len <= len+1;
                            end if;
                        else -- no match
                            if tbl_prefix = '0' then
                                state <= NEXT_CODE;
                            else
                                state <= BREAK_SKIP;
                            end if;
                        end if;

                    when BREAK_SKIP =>
                        if tbl_prefix = '0' then -- last code
                            state <= NEXT_CODE;
                        end if;

                    when others =>
                        state <= IDLE;
                        tbl_addr <= 0;
                        len <= 0;
                        i <= 0;

                end case;

            end if;
        end if;
    end process;

end architecture synth;

