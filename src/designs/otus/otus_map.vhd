--------------------------------------------------------------------------------
-- otus_map.vhd                                                               --
-- Otus memory map control.                                                   --
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

entity otus_map is
    generic (
        ram_size_log2 : integer                                      -- 16 = 64k, 17 = 128k, 18 = 256k
    )
    port map (

        clk         : in  std_logic;
        clken       : in  std_logic;
        rst         : in  std_logic;

        core_if_al  : in  std_logic_vector(15 downto 0);              -- instruction fetch address - logical
        core_if_ap  : out std_logic_vector(ram_size_log2-1 downto 0); -- instruction fetch address - physical
        core_if_z   : out std_logic;                                  -- instruction fetch returns zero
        core_ls_al  : in  std_logic_vector(15 downto 0);              -- load/store address - logical
        core_ls_ap  : out std_logic_vector(ram_size_log2-1 downto 0); -- load/store address - physical
        core_ls_we  : in  std_logic;                                  -- store write enable
        core_ls_z   : out std_logic;                                  -- load returns zero
        core_ls_wp  : out std_logic;                                  -- store to write protected area of RAM
        core_ls_ext : out std_logic;                                  -- load/store is external (I/O)
        core_ls_dwx : in  std_logic;                                  -- store (write) data to external device
        core_ls_dwr : out std_logic;                                  -- load (read) data from external device

        crtc_cs     : out std_logic;
        crtc_dr     : in  std_logic_vector(7 downto 0);
    
        acia_cs     : out std_logic;
        acia_dr     : in  std_logic_vector(7 downto 0);
    
        serproc_cs  : out std_logic;
        serproc_dr  : in  std_logic_vector(7 downto 0);
    
        vidproc_cs  : out std_logic;
        vidproc_dr  : in  std_logic_vector(7 downto 0);
    
        viaa_cs     : out std_logic;
        viaa_dr     : in  std_logic_vector(7 downto 0);
    
        viab_cs     : out std_logic;
        viab_dr     : in  std_logic_vector(7 downto 0);
    
        fdc_cs      : out std_logic;
        fdc_dr      : in  std_logic_vector(7 downto 0);
    
        adlc_cs     : out std_logic;
        adlc_dr     : in  std_logic_vector(7 downto 0);
    
        adc_cs      : out std_logic;
        adc_dr      : in  std_logic_vector(7 downto 0);
    
        tube_cs     : out std_logic;
        tube_dr     : std_logic_vector(7 downto 0)

    );
end entity otus_memmap;

architecture synth of otus_memmap is

    --------------------------------------------------------------------------------
    -- I/O regions

    constant BASE_FRED    : std_logic_vector(15 downto 8) := x"FC";
    constant BASE_JIM     : std_logic_vector(15 downto 8) := x"FD";
    constant BASE_SHEILA  : std_logic_vector(15 downto 8) := x"FE";

    --------------------------------------------------------------------------------
    -- address ranges within SHEILA
                                                                      -- | Otus* | model B | model B |
                                                                      -- | range | range   | req**   |
                                                                      -- +-------+---------+---------+
    constant BASE_CRTC    : std_logic_vector(7 downto 3) := "00000";  -- |       | 00-07   | 00-01   |
    constant BASE_ACIA    : std_logic_vector(7 downto 3) := "00001";  -- |       | 08-0F   | 08-09   |
    constant BASE_SERPROC : std_logic_vector(7 downto 4) := "0001";   -- |       | 10-1F   | 10      |
    constant BASE_VIDPROC : std_logic_vector(7 downto 4) := "0010";   -- |       | 20-2F   | 20-21   |
    constant BASE_MAP     : std_logic_vector(7 downto 4) := "0011";   -- |       | 30-3F   | 30      | ***
    constant BASE_VIAA    : std_logic_vector(7 downto 4) := "0100";   -- | 40-4F | 40-5F   | 40-4F   |
    constant BASE_....    : std_logic_vector(7 downto 4) := "0101";   -- | 50-5F |         |         |
    constant BASE_VIAB    : std_logic_vector(7 downto 4) := "0110";   -- | 60-6F | 60-7F   | 60-6F   |
    constant BASE_EXT7    : std_logic_vector(7 downto 4) := "0111";   -- | 70-7F |         |         |
    constant BASE_FDC     : std_logic_vector(7 downto 5) := "1000";   -- | 80-87 | 80-9F   | 80-87   |
    constant BASE_....    : std_logic_vector(7 downto 5) := "1000";   -- | 88-8F |         |         |
    constant BASE_EXT9    : std_logic_vector(7 downto 4) := "1001";   -- | 90-9F |         |         |
    constant BASE_ADLC    : std_logic_vector(7 downto 5) := "1010";   -- | A0-AF | A0-BF   | A0-A3   |
    constant BASE_....    : std_logic_vector(7 downto 4) := "1011";   -- | B0-BF |         |         |
    constant BASE_ADC     : std_logic_vector(7 downto 5) := "1100";   -- | C0-CF | C0-DF   | C0-C3   |
    constant BASE_....    : std_logic_vector(7 downto 4) := "1101";   -- | D0-DF |         |         |
    constant BASE_TUBE    : std_logic_vector(7 downto 5) := "1110";   -- | E0-EF | E0-FF   | E0-E7   |
    constant BASE_....    : std_logic_vector(7 downto 4) := "1111";   -- | F0-FF |         |         |

    -- * where different from model B
    -- ** min range required by underlying hardware
    -- *** model B has ROMSEL, Otus has more (implemented here)

    --------------------------------------------------------------------------------
    -- map control
    
    -- FE30 ROMSEL      sets sideways banks for instruction fetches, loads and stores
    -- FE30 ROMSEL      sets sideways banks for instruction fetches and loads
    -- FE30 ROMSEL      sets sideways banks for instruction fetches
    -- FE32 BANKD       sets sideways bank for loads and stores
    -- FE32 BANKD       sets sideways bank for loads and stores
    -- FE33 BANKW       sets sideways bank for stores
    
    -- FE34 ACCCON      B+/Master
    -- 

    --------------------------------------------------------------------------------
    -- map control

    constant RA_ROMSEL : std_logic_vector(3 downto 0) := x"0"; -- register address: ROMSEL
    constant RA_WP0    : std_logic_vector(3 downto 0) := x"E"; -- register address: write protect (lower)
    constant RA_WP1    : std_logic_vector(3 downto 0) := x"F"; -- register address: write protect (upper)

    signal map_cs      : std_logic;
    signal map_dr      : std_logic_vector(7 downto 0);

    signal reg_romsel  : std_logic_vector(3 downto 0);
    signal reg_wp      : std_logic_vector(15 downto 0);
    alias  reg_wp0     : std_logic_vector(7 downto 0) is reg_wp(7 downto 0);
    alias  reg_wp1     : std_logic_vector(7 downto 0) is reg_wp(15 downto 8);

    signal sw_bank     : std_logic_vector(3 downto 0);
    signal sw_wp       : std_logic;
    signal sw_z        : std_logic;

    --------------------------------------------------------------------------------
    -- functions

    function decode(
        addr : std_logic_vector;
        base : std_logic_vector
    ) return std_logic is
    begin
        if addr(base'range) = base then
            return '1';
        else
            return '0';
        end if;
    end function decode;

    function pad(n : integer; v : std_logic_vector) return std_logic_vector is
        variable r: std_logic_vector(n-1 downto 0);
    begin
        r := (others => '0');
        r(v'length-1 downto 0) := v;
        return r;
    end function pad;

    --------------------------------------------------------------------------------

begin

    --------------------------------------------------------------------------------
    -- logical (CPU) memory map
    --
    --  range       contents
    --  0000-3FFF   lower 16k of normal RAM
    --  4000-7FFF   upper 16k of normal RAM
    --  8000-BFFF   sideways ROM/RAM banks (1, 4 or 12)
    --  C000-FBFF   OS ROM
    --  FC00-FCFF   FRED   } hardware (load/store)
    --  FD00-FDFF   JIM    } and
    --  FE00-FEFF   SHEILA } init code (instruction fetch)
    --  FF00-FFFF   MOS ROM
    --
    -- physical RAM memory map
    --                                      --- physical RAM ---
    --  range       contents                64k     128k    256k
    --  00000-03FFF lower 16k of fixed RAM
    --  04000-07FFF upper 16k of fixed RAM
    --  08000-0BFFF sideways bank:          15      15      15
    --  0C000-0FFFF MOS ROM 
    --  10000-13FFF sideways bank:           -      3       11
    --  14000-17FFF sideways bank:           -      2       10
    --  18000-1BFFF sideways bank:           -      1       9
    --  1C000-1FFFF sideways bank:           -      0       8
    --  20000-23FFF sideways bank:           -      -       7
    --  24000-27FFF sideways bank:           -      -       6
    --  28000-2BFFF sideways bank:           -      -       5
    --  2C000-2FFFF sideways bank:           -      -       4
    --  30000-33FFF sideways bank:           -      -       3
    --  34000-37FFF sideways bank:           -      -       2
    --  38000-3BFFF sideways bank:           -      -       1
    --  3C000-3FFFF sideways bank:           -      -       0
    --
    --------------------------------------------------------------------------------
    -- mapping of instruction fetches to RAM

    core_if_ap(13 downto 0) <= core_if_al(13 downto 0);
    with core_if_al(15 downto 14) select core_if_ap(17 downto 14) <=
        "0000" when "00",           -- lower 16k of fixed RAM
        "0001" when "01",           -- upper 16k of fixed RAM
        "0011" when "11",           -- ROM
        sw_bank when others;        -- sideways bank

    if_z <= sw_z when if_al(15 downto 14) = "10" else '0';

    --------------------------------------------------------------------------------
    -- mapping of load/stores to RAM and I/O

    ls_ap(13 downto 0) <= ls_al(13 downto 0);
    with ls_al(15 downto 14) select ls_ap(17 downto 14) <=
        "0000" when "00",           -- lower 16k of fixed RAM
        "0001" when "01",           -- upper 16k of fixed RAM
        "0011" when "11",           -- ROM
        sw_bank when others;        -- sideways bank

    ls_z <= sw_z when ls_al(15 downto 14) = "10" else '0';

    ls_wp <=
        '1' when ls_al(15 downto 14) = "11" else
        sw_wp when ls_al(15 downto 14) = "10" else
        '0';

    ls_ext <= fred or jim or sheila;

    --------------------------------------------------------------------------------
    -- I/O address decoding

    fred   <= '1' when ls_al(15 downto 8) = BASE_FRED   else '0';
    jim    <= '1' when ls_al(15 downto 8) = BASE_JIM    else '0';
    sheila <= '1' when ls_al(15 downto 8) = BASE_SHEILA else '0';

    crtc_cs    <= sheila and decode(ls_al(7 downto 0), BASE_CRTC    );
    acia_cs    <= sheila and decode(ls_al(7 downto 0), BASE_ACIA    );
    serproc_cs <= sheila and decode(ls_al(7 downto 0), BASE_SERPROC );
    vidproc_cs <= sheila and decode(ls_al(7 downto 0), BASE_VIDPROC );
    map_cs     <= sheila and decode(ls_al(7 downto 0), BASE_MAP     );
    viaa_cs    <= sheila and decode(ls_al(7 downto 0), BASE_VIAA    );
    ext_cs     <= sheila and decode(ls_al(7 downto 0), BASE_EXT     );
    viab_cs    <= sheila and decode(ls_al(7 downto 0), BASE_VIAB    );
    fdc_cs     <= sheila and decode(ls_al(7 downto 0), BASE_FDC     );
    adlc_cs    <= sheila and decode(ls_al(7 downto 0), BASE_ADLC    );
    adc_cs     <= sheila and decode(ls_al(7 downto 0), BASE_ADC     );
    tube_cs    <= sheila and decode(ls_al(7 downto 0), BASE_TUBE    );

    --------------------------------------------------------------------------------
    -- I/O read mux

    process(clk)
    begin
        if rising_edge(clk) and clken = '1' then
            -- I/O reads
            if    decode(a, BASE_CRTC    ) = '1' then ls_drx <= crtc_dr
            elsif decode(a, BASE_ACIA    ) = '1' then ls_drx <= acia_dr,
            elsif decode(a, BASE_SERPROC ) = '1' then ls_drx <= serproc_dr,
            elsif decode(a, BASE_VIDPROC ) = '1' then ls_drx <= vidproc_dr,
            elsif decode(a, BASE_MAP     ) = '1' then ls_drx <= map_dr,
            elsif decode(a, BASE_VIAA    ) = '1' then ls_drx <= viaa_dr,
            elsif decode(a, BASE_VIAB    ) = '1' then ls_drx <= viab_dr,
            elsif decode(a, BASE_FDC     ) = '1' then ls_drx <= fdc_dr,
            elsif decode(a, BASE_ADLC    ) = '1' then ls_drx <= adlc_dr,
            elsif decode(a, BASE_ADC     ) = '1' then ls_drx <= adc_dr,
            elsif decode(a, BASE_TUBE    ) = '1' then ls_drx <= tube_dr
            else  ls_drx <= (others => '0');
        end if;
    end process(clk);

    --------------------------------------------------------------------------------
    -- map control

    process(clk)
    begin
        if rising_edge(clk) and clken = '1' then
            if rst = '1' then -- synchronous reset
                reg_romsel <= (others => '1');
                reg_wp <= (others => '0');
                sw_bank <= (1 => '1', others => '0');
                sw_z <= '0';
                sw_wp <= '1';
            else
                if sheila = '1' and ls_al(base'high downto base_width) == base(base'high downto base_width) then
                    case ls_al(base_width downto 0) is
                        when RA_ROMSEL =>
                            if ls_we = '1' then
                                reg_romsel <= ls_dwx(3 downto 0);
                                sw_bank <= "0010";
                                sw_z <= '0';
                                sw_wp <= reg_wp(15);
                                if (ram_size_log2 = 17) then -- 128k
                                    if ls_dwx(3 downto 2) = "00" then
                                        sw_bank <= "01" & not ls_dwx(1 downto 0);
                                        sw_wp <= reg_wp(to_integer(unsigned(ls_dwx(1 downto 0))));
                                    else
                                        sw_z <= '1'
                                        sw_wp <= '1';
                                    end if;
                                elsif (ram_size_log2 = 18) then -- 256k
                                    if to_integer(unsigned(ls_dwx(3 downto 0))) < 12 then
                                        sw_bank <= std_logic_vector(to_unsigned(15-to_integer(unsigned(ls_dwx(3 downto 0))),4));
                                        sw_wp <= reg_wp(to_integer(unsigned(ls_dwx(3 downto 0))));
                                    else
                                        sw_z <= '1';
                                        sw_wp <= '1';
                                    end if;
                                end if;
                            end if;
                        when RA_WP0 =>
                            if ls_we = '1' then
                                reg_wp0 <= ls_dwx;
                            end if;
                        when RA_WP1 =>
                            if ls_we = '1' then
                                reg_wp1 <= ls_dwx;
                            end if;
                        when others => null;
                    end case;
                end if; -- sheila = '1' etc
            end if; -- rst = '1'
        end if; -- rising_edge(clk)
    end process;

    -- register reads

    with to_integer(unsigned(ls_al(3 downto 0))) select map_dr <=
        pad(8,reg_romsel) when RA_ROMSEL,
        pad(8,reg_wp0)    when RA_WP0,
        pad(8,reg_wp1)    when RA_WP1,
        (others => '0')    when others;

end architecture otus_memmap;
