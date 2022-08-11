--------------------------------------------------------------------------------
-- bpp_resample.vhd                                                           --
-- BPP PCM audio resampling.                                                  --
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

package bpp_resample_pkg is

    component bpp_resample is
        port (
            in_clk    : in  std_logic;                     -- } 4 MHz
            in_clken  : in  std_logic;                     -- }
            in_pcm    : in  std_logic_vector(1 downto 0);  -- 2 bit mono PCM
            out_clk   : in  std_logic;                     -- 12.288 MHz
            out_clken : out std_logic;                     -- 48 kHz
            out_rst   : in  std_logic;
            out_l     : out std_logic_vector(15 downto 0);
            out_r     : out std_logic_vector(15 downto 0)
        );
    end component bpp_resample;

end package bpp_resample_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.sync_reg_pkg.all;

entity bpp_resample is
    port (
        in_clk    : in  std_logic;                     -- } 4 MHz
        in_clken  : in  std_logic;                     -- }
        in_pcm    : in  std_logic_vector(1 downto 0);  -- 2 bit mono PCM
        out_clk   : in  std_logic;                     -- 12.288 MHz
        out_clken : out std_logic;                     -- 48 kHz
        out_rst   : in  std_logic;
        out_l     : out std_logic_vector(15 downto 0);
        out_r     : out std_logic_vector(15 downto 0)
    );
end entity bpp_resample;

architecture synth of bpp_resample is

    signal count  : integer range 0 to 255;
    signal sample : std_logic_vector(1 downto 0);

begin

    process(out_rst,out_clk)
    begin
        if rising_edge(out_clk) then
            if out_rst = '0' then
                count <= 0;
                out_clken <= '0';
            else
                out_clken <= '0';
                if count = 255 then
                    count <= 0;
                    out_clken <= '1';
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    RESAMPLE: sync_reg
        generic map (
            width => 2,
            depth => 3
        )
        port map (
            clk  => out_clk,
            d(1 downto 0) => in_pcm,
            q(1 downto 0) => sample
        );

    out_l <= sample & "00000000000000";
    out_r <= sample & "00000000000000";

end architecture synth;
