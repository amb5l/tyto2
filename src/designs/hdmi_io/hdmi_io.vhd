--------------------------------------------------------------------------------
-- hdmi_io.vhd                                                                --
-- HDMI input and output.                                                     --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

package hdmi_io_pkg is

  component hdmi_io is
    generic (
      fclk       : real
    );
    port (
      rst         : in    std_logic;
      clk         : in    std_logic;
      hdmi_rx_clk : in    std_logic;
      hdmi_rx_d   : in    std_logic_vector(0 to 2);
      hdmi_tx_clk : out   std_logic;
      hdmi_tx_d   : out   std_logic_vector(0 to 2);
      status      : out   std_logic_vector(3 downto 0)
    );
  end component hdmi_io;

end package hdmi_io_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.hdmi_tx_selectio_pkg.all;

entity hdmi_io is
  generic (
    fclk        : real                                -- clock frequency (MHz), typically 100.0
  );
  port (
    rst         : in    std_logic;                    -- reference/system reset (synchronous)
    clk         : in    std_logic;                    -- reference/system clock
    hdmi_rx_clk : in    std_logic;                    -- HDMI (TMDS) clock input (+ve
    hdmi_rx_d   : in    std_logic_vector(0 to 2);     -- HDMI (TMDS) data input channels 0..2 (+ve)
    hdmi_tx_clk : out   std_logic;                    -- HDMI (TMDS) clock output (+ve)
    hdmi_tx_d   : out   std_logic_vector(0 to 2);     -- HDMI (TMDS) data output channels 0..2 (+ve)
    status      : out   std_logic_vector(3 downto 0)
  );
end entity hdmi_io;

architecture synth of hdmi_io is

  signal sclk  : std_logic;
  signal prst  : std_logic;
  signal pclk  : std_logic;
  signal tmds  : slv10_vector(0 to 2);

begin

  U_HDMI_RX: component hdmi_rx_selectio
    generic map (
      fclk  => fclk
    )
    port map (
      rst    => rst,
      clk    => clk,
      pclki  => hdmi_rx_clk,
      si     => hdmi_rx_d,
      sclko  => sclk,
      prsto  => prst,
      pclko  => pclk,
      po     => tmds,
      align  => status(0),
      lock   => status(1),
      band   => status(3 downto 2)
    );

  U_HDMI_TX: component hdmi_tx_selectio
    port map (
      sclki => sclk,
      prsti => prst,
      pclki => pclk,
      pi    => tmds,
      pclko => hdmi_tx_clk,
      so    => hdmi_tx_d
    );

end architecture synth;
