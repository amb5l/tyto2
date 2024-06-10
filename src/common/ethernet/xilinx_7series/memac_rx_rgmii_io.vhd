--------------------------------------------------------------------------------
-- memac_rx_rgmii_io.vhd                                                      --
-- Modular Ethernet MAC (MEMAC): Xilinx 7 Series specific RGMII RX I/O.       --
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

package memac_rx_rgmii_io_pkg is

  component memac_rx_rgmii_io is
    generic (
      ALIGN : string := "EDGE" -- "EDGE" or "CENTER"
    );
    port (
      i_clk   : in    std_ulogic;
      i_ctl   : in    std_ulogic;
      i_d     : in    std_ulogic_vector(3 downto 0);
      o_clkr  : out   std_ulogic;
      o_clkio : out   std_ulogic;
      o_ctl   : out   std_ulogic;
      o_d     : out   std_ulogic_vector(3 downto 0)
    );
  end component memac_rx_rgmii_io;

end package memac_rx_rgmii_io_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity memac_rx_rgmii_io is
  generic (
    ALIGN : string := "EDGE" -- "EDGE" or "CENTER"
  );
  port (
    i_clk   : in    std_ulogic;
    i_ctl   : in    std_ulogic;
    i_d     : in    std_ulogic_vector(3 downto 0);
    o_clkr  : out   std_ulogic;
    o_clkio : out   std_ulogic;
    o_ctl   : out   std_ulogic;
    o_d     : out   std_ulogic_vector(3 downto 0)
  );
end entity memac_rx_rgmii_io;

architecture struct of memac_rx_rgmii_io is

  signal i_clk_i : std_ulogic;

begin

  U_IBUF_CLK: component ibuf
    port map (
      i  => i_clk,
      o  => i_clk_i
    );

  GEN_ALIGN: if ALIGN = "EDGE" generate

    signal i_clk_d : std_ulogic;
    signal i_ctl_i : std_ulogic;
    signal i_d_i   : std_ulogic_vector(3 downto 0);

  begin

    U_IDELAY_CLK: component idelaye2
      generic map (
        delay_src             => "IDATAIN",
        idelay_type           => "FIXED",
        pipe_sel              => "FALSE",
        idelay_value          => 6,
        signal_pattern        => "CLOCK",
        refclk_frequency      => 200.0,
        high_performance_mode => "TRUE",
        cinvctrl_sel          => "FALSE"
      )
      port map (
        regrst      => '0',
        cinvctrl    => '0',
        c           => '0',
        ce          => '0',
        inc         => '0',
        ld          => '0',
        ldpipeen    => '0',
        cntvaluein  => (others => '0'),
        cntvalueout => open,
        idatain     => i_clk_i,
        datain      => '0',
        dataout     => i_clk_d
      );

    U_BUFR_CLK: component bufr
      port map (
        ce  => '1',
        clr => '0',
        i   => i_clk_d,
        o   => o_clkr
      );

    U_BUFIO_CLK: component bufio
      port map (
        i  => i_clk_d,
        o  => o_clkio
      );

    U_IBUF_CTL: component ibuf
      port map (
        i  => i_ctl,
        o  => i_ctl_i
      );

    U_IDELAY_CTL: component idelaye2
      generic map (
        delay_src             => "IDATAIN",
        idelay_type           => "FIXED",
        pipe_sel              => "FALSE",
        idelay_value          => 0,
        signal_pattern        => "DATA",
        refclk_frequency      => 200.0,
        high_performance_mode => "TRUE",
        cinvctrl_sel          => "FALSE"
      )
      port map (
        regrst      => '0',
        cinvctrl    => '0',
        c           => '0',
        ce          => '0',
        inc         => '0',
        ld          => '0',
        ldpipeen    => '0',
        cntvaluein  => (others => '0'),
        cntvalueout => open,
        idatain     => i_ctl_i,
        datain      => '0',
        dataout     => o_ctl
      );

    GEN_D: for i in 0 to 3 generate

      U_IBUF_D: component ibuf
        port map (
          i  => i_d(i),
          o  => i_d_i(i)
        );

      U_IDELAY_D: component idelaye2
        generic map (
          delay_src             => "IDATAIN",
          idelay_type           => "FIXED",
          pipe_sel              => "FALSE",
          idelay_value          => 0,
          signal_pattern        => "DATA",
          refclk_frequency      => 200.0,
          high_performance_mode => "TRUE",
          cinvctrl_sel          => "FALSE"
        )
        port map (
          regrst      => '0',
          cinvctrl    => '0',
          c           => '0',
          ce          => '0',
          inc         => '0',
          ld          => '0',
          ldpipeen    => '0',
          cntvaluein  => (others => '0'),
          cntvalueout => open,
          idatain     => i_d_i(i),
          datain      => '0',
          dataout     => o_d(i)
        );

    end generate GEN_D;

  else generate

    U_BUFR_CLK: component bufr
      port map (
        ce  => '1',
        clr => '0',
        i   => i_clk_i,
        o   => o_clkr
      );

    U_BUFIO_CLK: component bufio
      port map (
        i  => i_clk_i,
        o  => o_clkio
      );

  end generate GEN_ALIGN;

end architecture struct;
