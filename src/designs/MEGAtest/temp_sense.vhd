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

begin

  bsy <= adc_busy or jtag_lock;

  U_XADC: component XADC
    generic map (
      INIT_40               => X"0000",
      INIT_41               => X"0000",
      INIT_42               => X"0800",
      INIT_43               => X"0000",
      INIT_44               => X"0000",
      INIT_45               => X"0000",
      INIT_46               => X"0000",
      INIT_47               => X"0000",
      INIT_48               => X"0000",
      INIT_49               => X"0000",
      INIT_4A               => X"0000",
      INIT_4B               => X"0000",
      INIT_4C               => X"0000",
      INIT_4D               => X"0000",
      INIT_4E               => X"0000",
      INIT_4F               => X"0000",
      INIT_50               => X"0000",
      INIT_51               => X"0000",
      INIT_52               => X"0000",
      INIT_53               => X"0000",
      INIT_54               => X"0000",
      INIT_55               => X"0000",
      INIT_56               => X"0000",
      INIT_57               => X"0000",
      INIT_58               => X"0000",
      INIT_59               => X"0000",
      INIT_5A               => X"0000",
      INIT_5B               => X"0000",
      INIT_5C               => X"0000",
      INIT_5D               => X"0000",
      INIT_5E               => X"0000",
      INIT_5F               => X"0000",
      IS_CONVSTCLK_INVERTED => '0',
      IS_DCLK_INVERTED      => '0',
      SIM_DEVICE            => "7SERIES",
      SIM_MONITOR_FILE      => "design.txt"
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
      vn           => open,
      vp           => open

    );

end architecture rtl;
