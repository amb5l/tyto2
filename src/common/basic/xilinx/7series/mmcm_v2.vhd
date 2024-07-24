--------------------------------------------------------------------------------
-- mmcm_v2.vhd                                                                --
-- Wrapper for Xilinx 7 series MMCM, version 2.                               --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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

package mmcm_v2_pkg is

  component mmcm_v2 is
    generic (
      mul    : real;
      div    : integer;
      odiv0  : real;
      odiv1  : integer := 0;
      odiv2  : integer := 0;
      odiv3  : integer := 0;
      odiv4  : integer := 0;
      odiv5  : integer := 0;
      odiv6  : integer := 0;
      phase0 : real    := 0.0;
      phase1 : real    := 0.0;
      phase2 : real    := 0.0;
      phase3 : real    := 0.0;
      phase4 : real    := 0.0;
      phase5 : real    := 0.0;
      phase6 : real    := 0.0;
      duty0  : real    := 0.5;
      duty1  : real    := 0.5;
      duty2  : real    := 0.5;
      duty3  : real    := 0.5;
      duty4  : real    := 0.5;
      duty5  : real    := 0.5;
      duty6  : real    := 0.5
    );
    port (
      rsti  : in    std_ulogic;
      clki  : in    std_ulogic;
      rsto  : out   std_ulogic;
      clk0  : out   std_ulogic;
      clk1  : out   std_ulogic;
      clk2  : out   std_ulogic;
      clk3  : out   std_ulogic;
      clk4  : out   std_ulogic;
      clk5  : out   std_ulogic;
      clk6  : out   std_ulogic
    );
  end component mmcm_v2;

end package mmcm_v2_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity mmcm_v2 is
  generic (
    mul    : real;
    div    : integer;
    odiv0  : real;
    odiv1  : integer := 0;
    odiv2  : integer := 0;
    odiv3  : integer := 0;
    odiv4  : integer := 0;
    odiv5  : integer := 0;
    odiv6  : integer := 0;
    phase0 : real    := 0.0;
    phase1 : real    := 0.0;
    phase2 : real    := 0.0;
    phase3 : real    := 0.0;
    phase4 : real    := 0.0;
    phase5 : real    := 0.0;
    phase6 : real    := 0.0;
    duty0  : real    := 0.5;
    duty1  : real    := 0.5;
    duty2  : real    := 0.5;
    duty3  : real    := 0.5;
    duty4  : real    := 0.5;
    duty5  : real    := 0.5;
    duty6  : real    := 0.5
  );
  port (
    rsti  : in    std_ulogic; -- reference reset in
    clki  : in    std_ulogic; -- reference clock in
    rsto  : out   std_ulogic; -- reset based on MMCM lock
    clk0  : out   std_ulogic; -- clock output 0
    clk1  : out   std_ulogic; -- clock output 1
    clk2  : out   std_ulogic; -- clock output 2
    clk3  : out   std_ulogic; -- clock output 3
    clk4  : out   std_ulogic; -- clock output 4
    clk5  : out   std_ulogic; -- clock output 5
    clk6  : out   std_ulogic  -- clock output 6
  );
end entity mmcm_v2;

architecture rtl of mmcm_v2 is

  signal locked  : std_ulogic;                -- MMCM locked output
  signal clkfb   : std_ulogic;                -- feedback

  function qdiv (div : integer) return integer is
  begin
    if div = 0 then
      return 128;
    else
      return div;
    end if;
  end function qdiv;

  function oe (div : integer) return boolean is
  begin
    if div = 0 then
      return false;
    else
      return true;
    end if;
  end function oe;

begin

  rsto <= not locked;

  MMCM: component mmcme2_adv
    generic map (
      bandwidth            => "OPTIMIZED",
      clkfbout_mult_f      => mul,
      clkfbout_phase       => 0.0,
      clkfbout_use_fine_ps => false,
      clkin1_period        => 10.0,
      clkin2_period        => 0.0,
      clkout0_divide_f     => odiv0,
      clkout0_duty_cycle   => duty0,
      clkout0_phase        => phase0,
      clkout0_use_fine_ps  => false,
      clkout1_divide       => qdiv(odiv1),
      clkout1_duty_cycle   => duty1,
      clkout1_phase        => phase1,
      clkout1_use_fine_ps  => false,
      clkout2_divide       => qdiv(odiv2),
      clkout2_duty_cycle   => duty2,
      clkout2_phase        => phase2,
      clkout2_use_fine_ps  => false,
      clkout3_divide       => qdiv(odiv3),
      clkout3_duty_cycle   => duty3,
      clkout3_phase        => phase3,
      clkout3_use_fine_ps  => false,
      clkout4_cascade      => false,
      clkout4_divide       => qdiv(odiv4),
      clkout4_duty_cycle   => duty4,
      clkout4_phase        => phase4,
      clkout4_use_fine_ps  => false,
      clkout5_divide       => qdiv(odiv5),
      clkout5_duty_cycle   => duty5,
      clkout5_phase        => phase5,
      clkout5_use_fine_ps  => false,
      clkout6_divide       => qdiv(odiv6),
      clkout6_duty_cycle   => duty6,
      clkout6_phase        => phase6,
      clkout6_use_fine_ps  => false,
      compensation         => "ZHOLD",
      divclk_divide        => div,
      is_clkinsel_inverted => '0',
      is_psen_inverted     => '0',
      is_psincdec_inverted => '0',
      is_pwrdwn_inverted   => '0',
      is_rst_inverted      => '0',
      ref_jitter1          => 0.01,
      ref_jitter2          => 0.01,
      ss_en                => "FALSE",
      ss_mode              => "CENTER_HIGH",
      ss_mod_period        => 10000,
      startup_wait         => false
    )
    port map (
      pwrdwn               => '0',
      rst                  => rsti,
      locked               => locked,
      clkin1               => clki,
      clkin2               => '0',
      clkinsel             => '1',
      clkinstopped         => open,
      clkfbin              => clkfb,
      clkfbout             => clkfb,
      clkfboutb            => open,
      clkfbstopped         => open,
      clkout0              => clk0,
      clkout0b             => open,
      clkout1              => clk1,
      clkout1b             => open,
      clkout2              => clk2,
      clkout2b             => open,
      clkout3              => clk3,
      clkout3b             => open,
      clkout4              => clk4,
      clkout5              => clk5,
      clkout6              => clk6,
      dclk                 => '0',
      daddr                => (others => '0'),
      den                  => '0',
      dwe                  => '0',
      di                   => (others => '0'),
      do                   => open,
      drdy                 => open,
      psclk                => '0',
      psdone               => open,
      psen                 => '0',
      psincdec             => '0'
    );

end architecture rtl;
