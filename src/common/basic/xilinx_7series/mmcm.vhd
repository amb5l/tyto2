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
      num_outputs : integer range 1 to 7;
      odiv0       : real;
      odiv        : int_array_t(1 to 6) := (0, 0, 0, 0, 0, 0);
      duty_cycle  : real_array_t(0 to 6) := (0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
    );
    port (
      rsti        : in    std_logic;
      clki        : in    std_logic;
      rsto        : out   std_logic;
      clko        : out   std_logic_vector(0 to num_outputs-1)
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
    num_outputs : integer range 1 to 7;
    odiv0       : real;
    odiv        : int_array_t(1 to 6)  := (0, 0, 0, 0, 0, 0);
    duty_cycle  : real_array_t(0 to 6) := (0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
  );
  port (
    rsti        : in    std_logic;                           -- reference reset in
    clki        : in    std_logic;                           -- reference clock in
    rsto        : out   std_logic;                           -- reset based on MMCM lock
    clko        : out   std_logic_vector(0 to num_outputs-1) -- clock outputs
  );
end entity mmcm;

architecture struct of mmcm is

  signal locked  : std_logic;                -- MMCM locked output
  signal clko_fb : std_logic;                -- unbuffered feedback clock
  signal clki_fb : std_logic;                -- feedback clock
  signal clku    : std_logic_vector(0 to 6); -- unbuffered output clocks

  function qdiv (div : integer) return integer is
  begin
    if div = 0 then
      return 1;
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
      clkout0_duty_cycle   => duty_cycle(0),
      clkout0_phase        => 0.0,
      clkout0_use_fine_ps  => false,
      clkout1_divide       => qdiv(odiv(1)),
      clkout1_duty_cycle   => duty_cycle(1),
      clkout1_phase        => 0.0,
      clkout1_use_fine_ps  => false,
      clkout2_divide       => qdiv(odiv(2)),
      clkout2_duty_cycle   => duty_cycle(2),
      clkout2_phase        => 0.0,
      clkout2_use_fine_ps  => false,
      clkout3_divide       => qdiv(odiv(3)),
      clkout3_duty_cycle   => duty_cycle(3),
      clkout3_phase        => 0.0,
      clkout3_use_fine_ps  => false,
      clkout4_cascade      => false,
      clkout4_divide       => qdiv(odiv(4)),
      clkout4_duty_cycle   => duty_cycle(4),
      clkout4_phase        => 0.0,
      clkout4_use_fine_ps  => false,
      clkout5_divide       => qdiv(odiv(5)),
      clkout5_duty_cycle   => duty_cycle(5),
      clkout5_phase        => 0.0,
      clkout5_use_fine_ps  => false,
      clkout6_divide       => qdiv(odiv(6)),
      clkout6_duty_cycle   => duty_cycle(6),
      clkout6_phase        => 0.0,
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
      clkfbin              => clki_fb,
      clkfbout             => clko_fb,
      clkfboutb            => open,
      clkfbstopped         => open,
      clkout0              => clku(0),
      clkout0b             => open,
      clkout1              => clku(1),
      clkout1b             => open,
      clkout2              => clku(2),
      clkout2b             => open,
      clkout3              => clku(3),
      clkout3b             => open,
      clkout4              => clku(4),
      clkout5              => clku(5),
      clkout6              => clku(6),
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

  BUFG_F: component bufg
    port map (
      i => clko_fb,
      o => clki_fb
    );

  gen: for i in 0 to num_outputs-1 generate

    BUFG_OUT: component bufg
      port map (
        i => clku(i),
        o => clko(i)
      );

  end generate gen;

end architecture struct;
