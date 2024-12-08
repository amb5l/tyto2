--------------------------------------------------------------------------------
-- temp_sense.vhd                                                             --
-- XADC wrapper for temperature sensing in MEGAtest design.                   --
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

package temp_sense_pkg is

  component temp_sense is
    generic (
      STIM_FILE : string := "xadcstim.txt"
    );
    port (
      rst   : in    std_ulogic;
      clk   : in    std_ulogic;
      en    : in    std_ulogic;
      we    : in    std_ulogic;
      addr  : in    std_ulogic_vector(6 downto 0);
      din   : in    std_ulogic_vector(15 downto 0);
      dout  : out   std_ulogic_vector(15 downto 0);
      rdy   : out   std_ulogic;
      bsy   : out   std_ulogic
    );
  end component temp_sense;

end package temp_sense_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
   use unisim.vcomponents.all;

entity temp_sense is
  generic (
    STIM_FILE : string := "xadcstim.txt"
  );
  port (
    rst   : in    std_ulogic;
    clk   : in    std_ulogic;
    en    : in    std_ulogic;
    we    : in    std_ulogic;
    addr  : in    std_ulogic_vector(6 downto 0);
    din   : in    std_ulogic_vector(15 downto 0);
    dout  : out   std_ulogic_vector(15 downto 0);
    rdy   : out   std_ulogic;
    bsy   : out   std_ulogic
  );
end entity temp_sense;

architecture rtl of temp_sense is

  signal adc_busy  : std_ulogic;
  signal jtag_lock : std_ulogic;

  --------------------------------------------------------------------------------
  -- configuration register constants

  -- channel 0 = on chip temperature (n/a in default sequencer mode)
  -- no increased settling time
  -- continuous sampling
  -- bipolar operating mode
  -- internal mux
  -- average 256 samples
  -- enable coefficient averaging
  constant CFGREG0 : bit_vector := x"3400";

  -- disable OT
  -- disable alarms
  -- enable calibration coefficients
  -- default sequencer mode
  constant CFGREG1 : bit_vector := x"0FFF";

  -- enable both ADCs
  -- ADC freq = 100MHz / 100 = 1MHz
  constant CFGREG2 : bit_vector := x"6400";

  --------------------------------------------------------------------------------

begin

  bsy <= adc_busy or jtag_lock;

  U_XADC: component xadc
    generic map (
      INIT_40          => CFGREG0,
      INIT_41          => CFGREG1,
      INIT_42          => CFGREG2,
      SIM_MONITOR_FILE => STIM_FILE
    )
    port map (

      reset        => rst,

      dclk         => clk,
      den          => en,
      dwe          => we,
      daddr        => addr,
      di           => din,
      do           => dout,
      drdy         => rdy,

      jtagbusy     => open,
      jtaglocked   => jtag_lock,
      jtagmodified => open,

      convst       => '0',
      convstclk    => '0',
      muxaddr      => open,            -- external mux address
      channel      => open,            -- channel select at EOC
      busy         => adc_busy,        -- ADC conversion in progress
      eoc          => open,            -- end of conversion output
      eos          => open,            -- end of sequence output
      alm          => open,            -- alarm outputs
      ot           => open,            -- over-temperature
      vauxn        => (others => '0'),
      vauxp        => (others => '0'),
      vn           => '0',
      vp           => '0'

    );

end architecture rtl;
