--------------------------------------------------------------------------------
-- mmcm.vhd                                                                   --
-- Wrapper for Xilinx 7 series MMCM.                                          --
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

library work;
use work.tyto_types_pkg.all;

package mmcm_pkg is

    component mmcm is
        generic (
            mul         : real;
            div         : integer;
            num_outputs : integer; -- 1..7
            odiv0       : real;
            odiv        : int_array(1 to 6) := (0,0,0,0,0,0)
        );
        port (
            rst_ref     : in    std_logic;                           -- external reset in
            clk_ref     : in    std_logic;                           -- reference clock in
            rst         : out   std_logic;                           -- reset based on MMCM lock
            clk         : out   std_logic_vector(0 TO num_outputs-1) -- clock outputs
        );
    end component mmcm;

end package mmcm_pkg;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tyto_types_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity mmcm is
    generic (
        mul         : real;
        div         : integer;
        num_outputs : integer; -- 1..7
        odiv0       : real;
        odiv        : int_array(1 to 6) := (0,0,0,0,0,0)
    );
    port (
        rst_ref     : in    std_logic;                           -- external reset in
        clk_ref     : in    std_logic;                           -- reference clock in
        rst         : out   std_logic;                           -- reset based on MMCM lock
        clk         : out   std_logic_vector(0 TO num_outputs-1) -- clock outputs
    );
end entity mmcm;

architecture struct of mmcm is

    signal locked       : std_logic;                -- MMCM locked output
    signal clko_fb      : std_logic;                -- unbuffered feedback clock
    signal clki_fb      : std_logic;                -- feedback clock
    signal clku         : std_logic_vector(0 to 6); -- unbuffered output clocks

    function qdiv(div : integer) return integer is
    begin
        if div = 0 then
            return 1;
        else
            return div;
        end if;
    end function qdiv;

    function oe(div : integer) return boolean is
    begin
        if div = 0 then
            return false;
        else
            return true;
        end if;
    end function oe;

begin

    rst <= not locked;

    MMCM: MMCME2_ADV
    generic map(
        BANDWIDTH               => "OPTIMIZED",
        CLKFBOUT_MULT_F         => mul,
        CLKFBOUT_PHASE          => 0.0,
        CLKFBOUT_USE_FINE_PS    => false,
        CLKIN1_PERIOD           => 10.0,
        CLKIN2_PERIOD           => 0.0,
        CLKOUT0_DIVIDE_F        => odiv0,
        CLKOUT0_DUTY_CYCLE      => 0.5,
        CLKOUT0_PHASE           => 0.0,
        CLKOUT0_USE_FINE_PS     => false,
        CLKOUT1_DIVIDE          => qdiv(odiv(1)),
        CLKOUT1_DUTY_CYCLE      => 0.5,
        CLKOUT1_PHASE           => 0.0,
        CLKOUT1_USE_FINE_PS     => false,
        CLKOUT2_DIVIDE          => qdiv(odiv(2)),
        CLKOUT2_DUTY_CYCLE      => 0.5,
        CLKOUT2_PHASE           => 0.0,
        CLKOUT2_USE_FINE_PS     => false,
        CLKOUT3_DIVIDE          => qdiv(odiv(3)),
        CLKOUT3_DUTY_CYCLE      => 0.5,
        CLKOUT3_PHASE           => 0.0,
        CLKOUT3_USE_FINE_PS     => false,
        CLKOUT4_CASCADE         => false,
        CLKOUT4_DIVIDE          => qdiv(odiv(4)),
        CLKOUT4_DUTY_CYCLE      => 0.5,
        CLKOUT4_PHASE           => 0.0,
        CLKOUT4_USE_FINE_PS     => false,
        CLKOUT5_DIVIDE          => qdiv(odiv(5)),
        CLKOUT5_DUTY_CYCLE      => 0.5,
        CLKOUT5_PHASE           => 0.0,
        CLKOUT5_USE_FINE_PS     => false,
        CLKOUT6_DIVIDE          => qdiv(odiv(6)),
        CLKOUT6_DUTY_CYCLE      => 0.5,
        CLKOUT6_PHASE           => 0.0,
        CLKOUT6_USE_FINE_PS     => false,
        COMPENSATION            => "ZHOLD",
        DIVCLK_DIVIDE           => div,
        IS_CLKINSEL_INVERTED    => '0',
        IS_PSEN_INVERTED        => '0',
        IS_PSINCDEC_INVERTED    => '0',
        IS_PWRDWN_INVERTED      => '0',
        IS_RST_INVERTED         => '0',
        REF_JITTER1             => 0.01,
        REF_JITTER2             => 0.01,
        SS_EN                   => "FALSE",
        SS_MODE                 => "CENTER_HIGH",
        SS_MOD_PERIOD           => 10000,
        STARTUP_WAIT            => false
    )
    port map (
        PWRDWN          => '0',
        RST             => rst_ref,
        LOCKED          => locked,
        CLKIN1          => clk_ref,
        CLKIN2          => '0',
        CLKINSEL        => '1',
        CLKINSTOPPED    => open,
        CLKFBIN         => clki_fb,
        CLKFBOUT        => clko_fb,
        CLKFBOUTB       => open,
        CLKFBSTOPPED    => open,
        CLKOUT0         => clku(0),
        CLKOUT0B        => open,
        CLKOUT1         => clku(1),
        CLKOUT1B        => open,
        CLKOUT2         => clku(2),
        CLKOUT2B        => open,
        CLKOUT3         => clku(3),
        CLKOUT3B        => open,
        CLKOUT4         => clku(4),
        CLKOUT5         => clku(5),
        CLKOUT6         => clku(6),
        DCLK            => '0',
        DADDR           => (others => '0'),
        DEN             => '0',
        DWE             => '0',
        DI              => (others => '0'),
        DO              => open,
        DRDY            => open,
        PSCLK           => '0',
        PSDONE          => open,
        PSEN            => '0',
        PSINCDEC        => '0'
    );

    BUFG_F: BUFG
        port map (
            I   => clko_fb,
            O   => clki_fb
        );

    GEN: for i in 0 to num_outputs-1 generate
        BUFG_OUT: BUFG
            port map (
                I   => clku(i),
                O   => clk(i)
            );
    end generate GEN;

end architecture struct;