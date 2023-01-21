--------------------------------------------------------------------------------
-- hdmi_io.vhd                                                                --
-- HDMI input and output.                                                     --
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

package hdmi_io_pkg is

  component hdmi_io is
    generic (
      fclk       : real
    );
    port (

      rst        : in    std_logic;
      clk        : in    std_logic;

      hdmi_rx_clk_p : out   std_logic;
      hdmi_rx_clk_n : out   std_logic;
      hdmi_rx_d_p   : out   std_logic_vector(0 to 2);
      hdmi_rx_d_n   : out   std_logic_vector(0 to 2)

      hdmi_tx_clk_p : out   std_logic;
      hdmi_tx_clk_n : out   std_logic;
      hdmi_tx_d_p   : out   std_logic_vector(0 to 2);
      hdmi_tx_d_n   : out   std_logic_vector(0 to 2)

    );
  end component hdmi_io;

end package hdmi_io_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity hdmi_io is
  generic (
    fclk          : real                                -- clock frequency (MHz), typically 100.0
  );
  port (

    rst           : in    std_logic;                    -- reference/system reset (synchronous)
    clk           : in    std_logic;                    -- reference/system clock

    hdmi_rx_clk_p : out   std_logic;                    -- HDMI (TMDS) clock input (+ve)
    hdmi_rx_clk_n : out   std_logic;                    -- HDMI (TMDS) clock input (-ve)
    hdmi_rx_d_p   : out   std_logic_vector(0 to 2);     -- HDMI (TMDS) data input channels 0..2 (+ve)
    hdmi_rx_d_n   : out   std_logic_vector(0 to 2)      -- HDMI (TMDS) data input channels 0..2 (-ve)

    hdmi_tx_clk_p : out   std_logic;                    -- HDMI (TMDS) clock output (+ve)
    hdmi_tx_clk_n : out   std_logic;                    -- HDMI (TMDS) clock output (-ve)
    hdmi_tx_d_p   : out   std_logic_vector(0 to 2);     -- HDMI (TMDS) data output channels 0..2 (+ve)
    hdmi_tx_d_n   : out   std_logic_vector(0 to 2)      -- HDMI (TMDS) data output channels 0..2 (-ve)

  );
end entity hdmi_io;

architecture synth of hdmi_io is

begin

  U_HDMI_RX: component hdmi_rx_selectio
    generic (
      fclk  => 100.0
    )
    port (
      rst   => rst,
      clk   => clk,
      pclki => 
      si    => hdmi_rx_d
      pclko => pclk
      po    => hdmi_rx_pd
    );

end architecture synth;
