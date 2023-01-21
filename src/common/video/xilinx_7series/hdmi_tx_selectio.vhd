--------------------------------------------------------------------------------
-- hdmi_tx_selectio.vhd                                                       --
-- HDMI source front end built on Xilinx 7 Series SelectIO primitives.        --
-- 1) Does not include I/O buffers.                                           --
-- 2) Supports pixel clocks in the range 25..148.5MHz. -1 parts are rated at  --
-- 950Mbps (95MHz) max, and -2 parts are rated at 1200Mbps max.               --
-- Higher frequencies may not work!                                           --
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

package hdmi_tx_selectio_pkg is

  component hdmi_tx_selectio is
    port (
      sclki   : in    std_logic;
      prsti   : in    std_logic;
      pclki   : in    std_logic;
      pi      : in    slv_9_0_t(0 to 2);
      pclko   : in    std_logic;
      so      : out   std_logic_vector(0 to 2)
    );
  end component hdmi_tx_selectio;

end package hdmi_tx_selectio_pkg;

----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;

entity hdmi_tx_selectio is
  port (
    sclki   : in    std_logic;
    prsti   : in    std_logic;
    pclki   : in    std_logic;
    pi      : in    slv_9_0_t(0 to 2);
    pclko   : in    std_logic;
    so      : out   std_logic_vector(0 to 2)
  );
end entity hdmi_tx_selectio;

architecture synth of hdmi_tx_selectio is

  signal clk_shift1 : std_logic;
  signal clk_shift2 : std_logic;
  signal d_shift1   : std_logic_vector(0 to 2);
  signal d_shift2   : std_logic_vector(0 to 2);

begin

  --------------------------------------------------------------------------------
  -- 3x data

  GEN_CH: for i in 0 to 2 generate
  begin

    -- serialiser (master)
    U_SER_M: component oserdese2
      generic map (
        data_rate_oq   => "DDR",
        data_rate_tq   => "SDR",
        data_width     => 10,
        init_oq        => '0',
        init_tq        => '0',
        serdes_mode    => "MASTER",
        srval_oq       => '0',
        srval_tq       => '0',
        tbyte_ctl      => "FALSE",
        tbyte_src      => "FALSE",
        tristate_width => 1
      )
      port map (
        ofb            => open,
        oq             => so(i),
        shiftout1      => open,
        shiftout2      => open,
        tbyteout       => open,
        tfb            => open,
        tq             => open,
        clk            => sclki,
        clkdiv         => pclki,
        d1             => pi(i)(0),
        d2             => pi(i)(1),
        d3             => pi(i)(2),
        d4             => pi(i)(3),
        d5             => pi(i)(4),
        d6             => pi(i)(5),
        d7             => pi(i)(6),
        d8             => pi(i)(7),
        oce            => '1',
        rst            => prsti,
        shiftin1       => d_shift1(i),
        shiftin2       => d_shift1(i),
        t1             => '0',
        t2             => '0',
        t3             => '0',
        t4             => '0',
        tbytein        => '0',
        tce            => '0'
      );

    -- serialiser (slave)
    U_SER_S: component oserdese2
      generic map (
        data_rate_oq   => "DDR",
        data_rate_tq   => "SDR",
        data_width     => 10,
        init_oq        => '0',
        init_tq        => '0',
        serdes_mode    => "SLAVE",
        srval_oq       => '0',
        srval_tq       => '0',
        tbyte_ctl      => "FALSE",
        tbyte_src      => "FALSE",
        tristate_width => 1
      )
      port map (
        ofb            => open,
        oq             => open,
        shiftout1      => d_shift1(i),
        shiftout2      => d_shift2(i),
        tbyteout       => open,
        tfb            => open,
        tq             => open,
        clk            => sclki,
        clkdiv         => pclki,
        d1             => '0',
        d2             => '0',
        d3             => pi(i)(8),
        d4             => pi(i)(9),
        d5             => '0',
        d6             => '0',
        d7             => '0',
        d8             => '0',
        oce            => '1',
        rst            => prsti,
        shiftin1       => '0',
        shiftin2       => '0',
        t1             => '0',
        t2             => '0',
        t3             => '0',
        t4             => '0',
        tbytein        => '0',
        tce            => '0'
      );

  end generate GEN_CH;

  --------------------------------------------------------------------------------
  -- clock

  -- serialiser (master)
  U_SER_M: component oserdese2
    generic map (
      data_rate_oq   => "DDR",
      data_rate_tq   => "SDR",
      data_width     => 10,
      init_oq        => '0',
      init_tq        => '0',
      serdes_mode    => "MASTER",
      srval_oq       => '0',
      srval_tq       => '0',
      tbyte_ctl      => "FALSE",
      tbyte_src      => "FALSE",
      tristate_width => 1
    )
    port map (
      ofb            => open,
      oq             => so,
      shiftout1      => open,
      shiftout2      => open,
      tbyteout       => open,
      tfb            => open,
      tq             => open,
      clk            => sclki,
      clkdiv         => pclki,
      d1             => '0',
      d2             => '0',
      d3             => '0',
      d4             => '0',
      d5             => '0',
      d6             => '1',
      d7             => '1',
      d8             => '1',
      oce            => '1',
      rst            => prsti,
      shiftin1       => clk_shift1,
      shiftin2       => clk_shift2,
      t1             => '0',
      t2             => '0',
      t3             => '0',
      t4             => '0',
      tbytein        => '0',
      tce            => '0'
    );

  -- serialiser (slave)
  U_SER_S: component oserdese2
    generic map (
      data_rate_oq   => "DDR",
      data_rate_tq   => "SDR",
      data_width     => 10,
      init_oq        => '0',
      init_tq        => '0',
      serdes_mode    => "SLAVE",
      srval_oq       => '0',
      srval_tq       => '0',
      tbyte_ctl      => "FALSE",
      tbyte_src      => "FALSE",
      tristate_width => 1
    )
    port map (
      ofb            => open,
      oq             => open,
      shiftout1      => clk_shift1,
      shiftout2      => clk_shift2,
      tbyteout       => open,
      tfb            => open,
      tq             => open,
      clk            => sclki,
      clkdiv         => pclki,
      d1             => '0',
      d2             => '0',
      d3             => '1',
      d4             => '1',
      d5             => '0',
      d6             => '0',
      d7             => '0',
      d8             => '0',
      oce            => '1',
      rst            => prsti,
      shiftin1       => '0',
      shiftin2       => '0',
      t1             => '0',
      t2             => '0',
      t3             => '0',
      t4             => '0',
      tbytein        => '0',
      tce            => '0'
    );

  --------------------------------------------------------------------------------

end architecture synth;

