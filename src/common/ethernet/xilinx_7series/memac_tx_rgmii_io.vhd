--------------------------------------------------------------------------------
-- memac_tx_rgmii_io.vhd                                                      --
-- Modular Ethernet MAC (MEMAC): Xilinx 7 Series specific RGMII TX I/O.       --
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

package memac_tx_rgmii_io_pkg is

  component memac_tx_rgmii_io is
    generic (
      ALIGN : string
    );
    port (
      i_clk : in    std_ulogic;
      i_ctl : in    std_ulogic;
      i_d   : in    std_ulogic_vector(3 downto 0);
      o_clk : out   std_ulogic;
      o_ctl : out   std_ulogic;
      o_d   : out   std_ulogic_vector(3 downto 0)
    );
  end component memac_tx_rgmii_io;

end package memac_tx_rgmii_io_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity memac_tx_rgmii_io is
  generic (
    ALIGN : string -- "EDGE" or "CENTER"
  );
  port (
    i_clk : in    std_ulogic;
    i_ctl : in    std_ulogic;
    i_d   : in    std_ulogic_vector(3 downto 0);
    o_clk : out   std_ulogic;
    o_ctl : out   std_ulogic;
    o_d   : out   std_ulogic_vector(3 downto 0)
  );
end entity memac_tx_rgmii_io;

architecture struct of memac_tx_rgmii_io is

  signal o_ctl_o : std_ulogic;
  signal o_d_o   : std_ulogic_vector(3 downto 0);

begin

  GEN_ALIGN: if ALIGN = "EDGE" generate

    o_clk <= i_clk;
    o_ctl <= i_ctl;
    o_d   <= i_d;

  else generate

    o_clk <= i_clk;
    o_ctl <= i_ctl;
    o_d   <= i_d;

    --U_ODELAY_CTL: component odelaye2
    --  generic map (
    --    delay_src             => "ODATAIN",
    --    odelay_type           => "FIXED",
    --    pipe_sel              => "FALSE",
    --    odelay_value          => 25,
    --    signal_pattern        => "DATA",
    --    refclk_frequency      => 200.0,
    --    high_performance_mode => "TRUE",
    --    cinvctrl_sel          => "FALSE"
    --  )
    --  port map (
    --    regrst      => '0',
    --    cinvctrl    => '0',
    --    c           => '0',
    --    ce          => '0',
    --    inc         => '0',
    --    ld          => '0',
    --    ldpipeen    => '0',
    --    cntvaluein  => (others => '0'),
    --    cntvalueout => open,
    --    clkin       => '0',
    --    odatain     => i_ctl,
    --    dataout     => o_ctl_o
    --  );
--
    --U_OBUF_CTL: component obuf
    --  port map (
    --    i  => o_ctl_o,
    --    o  => o_ctl
    --  );
--
    --GEN_D: for i in 0 to 3 generate
--
    --  U_ODELAY_D: component odelaye2
    --  generic map (
    --    delay_src             => "ODATAIN",
    --    odelay_type           => "FIXED",
    --    pipe_sel              => "FALSE",
    --    odelay_value          => 25,
    --    signal_pattern        => "DATA",
    --    refclk_frequency      => 200.0,
    --    high_performance_mode => "TRUE",
    --    cinvctrl_sel          => "FALSE"
    --  )
    --  port map (
    --    regrst      => '0',
    --    cinvctrl    => '0',
    --    c           => '0',
    --    ce          => '0',
    --    inc         => '0',
    --    ld          => '0',
    --    ldpipeen    => '0',
    --    cntvaluein  => (others => '0'),
    --    cntvalueout => open,
    --    clkin       => '0',
    --    odatain     => i_d(i),
    --    dataout     => o_d_o(i)
    --  );
--
    --  U_OBUF_D: component obuf
    --    port map (
    --      i  => o_d_o(i),
    --      o  => o_d(i)
    --    );
--
    --end generate GEN_D;

  end generate GEN_ALIGN;

end architecture struct;
