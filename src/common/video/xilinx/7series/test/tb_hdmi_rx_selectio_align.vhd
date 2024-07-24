--------------------------------------------------------------------------------
-- tb_hdmi_rx_selectio_align.vhd                                              --
-- Simulation testbench for hdmi_rx_selectio_align.vhd.                       --
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
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library std;
  use std.env.finish;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;
  use work.hdmi_rx_selectio_align_pkg.all;

entity tb_hdmi_rx_selectio_align is
end entity tb_hdmi_rx_selectio_align;

architecture sim of tb_hdmi_rx_selectio_align is

  --------------------------------------------------------------------------------

  -- synthetic video timing to minimise simulation time
  constant VIDEO_PERIOD   : integer := 32;
  constant CONTROL_PERIOD : integer := 12;

  constant LOCK_TIME      : time := 160 us; -- depends on video timing
  constant UNLOCK_TIME    : time := 100 us; -- reasonable

  -- TODO make these timing parameters variable to exercise more IDELAYE2 taps
  constant tpclk          : time := 10 ns;
  constant tdelay         : time := 1 ns;
  constant tskew          : time := 5 ns;
  constant tbit           : time := tpclk / 10; -- serial bit time
  constant topen          : time := tbit / 4;   -- serial eye open time

  signal prst             : std_logic;
  signal pclk             : std_logic;
  signal sclk_p           : std_logic;
  signal sclk_n           : std_logic;

  signal idelay_d         : std_logic_vector(0 to 2);
  signal idelay_tap       : std_logic_vector(4 downto 0);
  signal idelay_ld        : std_logic_vector(0 to 2);
  signal iserdes_ddly     : std_logic_vector(0 to 2);
  signal iserdes_slip     : std_logic_vector(0 to 2);
  signal iserdes_q        : slv10_vector(0 to 2);
  signal iserdes_shift1   : std_logic_vector(0 to 2);
  signal iserdes_shift2   : std_logic_vector(0 to 2);

  signal video_count      : integer range 0 to VIDEO_PERIOD+CONTROL_PERIOD-1;
  signal de               : std_logic;
  signal d                : std_logic_vector(7 downto 0);
  signal c                : std_logic_vector(1 downto 0);
  signal check_de         : std_logic;
  signal check_d          : std_logic_vector(7 downto 0);
  signal check_c          : std_logic_vector(1 downto 0);

  signal tmds_p           : std_logic_vector(9 downto 0); -- TMDS parallel (character)
  signal tmds_dc          : integer range -4 to 4 := 0;   -- TMDS encode DC balance counter
  signal tmds_s           : std_logic;

  signal shiftreg         : std_logic_vector(9 downto 0);

  signal tmds_out         : slv10_vector(0 to 2);            -- DUT output
  signal status           : hdmi_rx_selectio_align_status_t; -- DUT status
  signal align            : std_logic;

  --------------------------------------------------------------------------------
  -- encode/decode functions and procedures

  function nbits(
    b : std_logic;
    v : std_logic_vector
  ) return integer is
    variable n : integer;
  begin
    n := 0;
    for i in v'low to v'high loop
      if v(i) = b then
        n := n+1;
      end if;
    end loop;
    return n;
  end function;

  function sl_to_int(b : std_logic) return integer is
  begin
    if b = '1' then return 1; else return 0; end if;
  end function sl_to_int;

  procedure dvi_encode(
    signal de  : in    std_logic;
    signal d   : in    std_logic_vector(7 downto 0);
    signal c   : in    std_logic_vector(1 downto 0);
    signal q   : out   std_logic_vector(9 downto 0);
    signal cnt : inout integer
  ) is
    variable q_m : std_logic_vector(8 downto 0);
    variable q_out : std_logic_vector(9 downto 0);
  begin
    q_m(0) := d(0);
    if (nbits('1',d) > 4)
    or ((nbits('1',d) = 4) and (d(0) = '0'))
    then
      for i in 1 to 7 loop
        q_m(i) := q_m(i-1) xnor d(i);
      end loop;
      q_m(8) := '0';
    else
      for i in 1 to 7 loop
        q_m(i) := q_m(i-1) xor d(i);
      end loop;
      q_m(8) := '1';
    end if;
    if de = '1' then
      if (cnt = 0)
      or ((nbits('1',q_m(7 downto 0)) = nbits('0',q_m(7 downto 0))))
      then
        q_out(9) := not q_m(8);
        q_out(8) := q_m(8);
        if q_m(8) = '1' then
          q_out(7 downto 0) := q_m(7 downto 0);
        else
          q_out(7 downto 0) := not q_m(7 downto 0);
        end if;
        if q_m(8) = '0' then
          cnt <= cnt + nbits('0',q_m(7 downto 0)) - nbits('1',q_m(7 downto 0));
        else
          cnt <= cnt + nbits('1',q_m(7 downto 0)) - nbits('0',q_m(7 downto 0));
        end if;
      else
        if ((cnt > 0) and (nbits('1',q_m(7 downto 0)) > nbits('0',q_m(7 downto 0))))
        or ((cnt < 0) and (nbits('0',q_m(7 downto 0)) > nbits('1',q_m(7 downto 0))))
        then
          q_out(9) := '1';
          q_out(8) := q_m(8);
          q_out(7 downto 0) := not q_m(7 downto 0);
          cnt <= cnt + (2 * sl_to_int(q_m(8))) + nbits('0',q_m(7 downto 0)) - nbits('1',q_m(7 downto 0));
        else
          q_out(9) := '0';
          q_out(8) := q_m(8);
          q_out(7 downto 0) := q_m(7 downto 0);
          cnt <= cnt - (2 * sl_to_int(not q_m(8))) + nbits('1',q_m(7 downto 0)) - nbits('0',q_m(7 downto 0));
        end if;
      end if;
    else
      case c is
        when "00"   => q_out := "1101010100";
        when "01"   => q_out := "0010101011";
        when "10"   => q_out := "0101010100";
        when "11"   => q_out := "1010101011";
        when others => q_out := "XXXXXXXXXX";
      end case;
    end if;
    q <= q_out;
  end procedure dvi_encode;

  procedure dvi_decode(
    signal q    : in    std_logic_vector(9 downto 0);
    signal de   : out   std_logic;
    signal d    : out   std_logic_vector(7 downto 0);
    signal c    : out   std_logic_vector(1 downto 0)
  ) is
  begin
    de  <= 'X';
    d   <= "XXXXXXXX";
    c   <= "XX";
    if q /= "XXXXXXXXXX" then
      de <= '1';
      d(0) <= q(0) xor q(9);
      for i in 1 to 7 loop
        d(i) <= (q(i) xor q(9)) xor ((q(i-1) xor q(9)) xnor q(8));
      end loop;
    end if;
    case q(9 downto 0) is
      when "1101010100" => c <= "00"; de <= '0';
      when "0010101011" => c <= "01"; de <= '0';
      when "0101010100" => c <= "10"; de <= '0';
      when "1010101011" => c <= "11"; de <= '0';
      when others => null;
    end case;
  end procedure dvi_decode;

  --------------------------------------------------------------------------------

begin

  pclk <=
    '1' after tpclk / 2 when pclk = '0' else
    '0' after tpclk / 2 when pclk = '1' else
    '0';

  sclk_p <=
    '1' after tpclk / 10 when sclk_p = '0' else
    '0' after tpclk / 10 when sclk_p = '1' else
    '0';

  sclk_n <=
    '0' after tpclk / 10 when sclk_n = '1' else
    '1' after tpclk / 10 when sclk_n = '0' else
    '1';

  prst <= '1', '0' after 10 ns;

  align <=
    status.align_s(0) and
    status.align_s(1) and
    status.align_s(2) and
    status.align_p;

  -- main process
  process
  begin
    wait on align until align = '1' for LOCK_TIME;
    if align = '0' then
      report "alignment should have been established by now" severity FAILURE;
    end if;
    wait on align until align = '0' for UNLOCK_TIME;
    if align = '0' then
      report "alignment has been lost" severity FAILURE;
    end if;
    report "SUCCESS!";
    finish;
  end process;

  -- generate video
  process(pclk)
    variable seed1, seed2 : positive;
    variable r : real;
  begin
    if prst = '1' then
      video_count <= 0;
      de          <= '0';
      d           <= (others => 'X');
      c           <= (others => 'X');
    elsif rising_edge(pclk) then
      uniform(seed1, seed2, r);
      if video_count < VIDEO_PERIOD then
        de <= '1';
        d <= std_logic_vector(to_unsigned(integer(round(r*real(256)-0.5)),8));
        c <= "XX";
      else
        de <= '0';
        d <= "XXXXXXXX";
        c <= std_logic_vector(to_unsigned(integer(round(r*real(4)-0.5)),2));
      end if;
      video_count <= (video_count+1) mod (VIDEO_PERIOD+CONTROL_PERIOD);
    end if;
  end process;

  -- encode
  process(de,d,c)
  begin
    dvi_encode(de,d,c,tmds_p,tmds_dc);
  end process;

  -- decode
  process(tmds_p)
  begin
    dvi_decode(tmds_p, check_de, check_d, check_c);
  end process;

  -- check encoding correctness
  process(check_de,check_d,check_c)
  begin
    if now > 0 ps then
      if (de /= 'X') and (
        (de /= check_de)
        or (de = '1' and d /= check_d)
        or (de = '0' and c /= check_c)
      )
      then
        report
          "mismatch!"  & lf &
          "encode: de = " & std_logic'image(de) &
          "  d = " &
          std_logic'image(d(7)) &
          std_logic'image(d(6)) &
          std_logic'image(d(5)) &
          std_logic'image(d(4)) &
          std_logic'image(d(3)) &
          std_logic'image(d(2)) &
          std_logic'image(d(1)) &
          std_logic'image(d(0)) &
          "  c = " &
          std_logic'image(c(1)) &
          std_logic'image(c(0)) &
          lf &
          "decode: de = " & std_logic'image(check_de) &
          "  d = " &
          std_logic'image(check_d(7)) &
          std_logic'image(check_d(6)) &
          std_logic'image(check_d(5)) &
          std_logic'image(check_d(4)) &
          std_logic'image(check_d(3)) &
          std_logic'image(check_d(2)) &
          std_logic'image(check_d(1)) &
          std_logic'image(check_d(0)) &
          "  c = " &
          std_logic'image(check_c(1)) &
          std_logic'image(check_c(0))
          severity FAILURE;
      end if;
    end if;
  end process;

  -- serialise
  process(pclk,sclk_p)
  begin
    if rising_edge(pclk) then
      shiftreg <= tmds_p;
    elsif sclk_p'event then
      shiftreg <= shiftreg(8 downto 0) & 'X';
    end if;
  end process;

  -- serial eye open/close
  process(sclk_p)
  begin
    tmds_s <= shiftreg(9), 'X' after topen;
  end process;

  -- channel skew
  idelay_d(0) <= transport tmds_s after tdelay;
  idelay_d(1) <= transport tmds_s after tdelay+tskew;
  idelay_d(2) <= transport tmds_s after tdelay+tskew+tskew;

  -- components

  DUT: component hdmi_rx_selectio_align
  generic map (
    interval    => VIDEO_PERIOD+12+11 -- minimum necessary
  )
    port map (
      prst         => prst,
      pclk         => pclk,
      iserdes_q    => iserdes_q,
      iserdes_slip => iserdes_slip,
      idelay_tap   => idelay_tap,
      idelay_ld    => idelay_ld,
      tmds         => tmds_out,
      status       => status
    );

  GEN_CH: for i in 0 to 2 generate

    U_IDELAY: component idelaye2
      generic map (
        delay_src             => "IDATAIN",
        idelay_type           => "VAR_LOAD",
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
        c           => pclk,
        ce          => '0',
        inc         => '0',
        ld          => idelay_ld(i),
        ldpipeen    => '0',
        cntvaluein  => idelay_tap,
        cntvalueout => open,
        idatain     => idelay_d(i),
        datain      => '0',
        dataout     => iserdes_ddly(i)
      );

    U_ISERDESE2_M: component iserdese2
      generic map (
        serdes_mode       => "MASTER",
        interface_type    => "NETWORKING",
        iobdelay          => "BOTH",
        data_width        => 10,
        data_rate         => "DDR",
        ofb_used          => "FALSE",
        dyn_clkdiv_inv_en => "FALSE",
        dyn_clk_inv_en    => "FALSE",
        num_ce            => 2,
        init_q1           => '0',
        init_q2           => '0',
        init_q3           => '0',
        init_q4           => '0',
        srval_q1          => '0',
        srval_q2          => '0',
        srval_q3          => '0',
        srval_q4          => '0'
      )
      port map (
        rst               => prst,
        dynclksel         => '0',
        clk               => sclk_p,
        clkb              => sclk_n,
        ce1               => '1',
        ce2               => '1',
        dynclkdivsel      => '0',
        clkdiv            => pclk,
        clkdivp           => '0',
        oclk              => '0',
        oclkb             => '1',
        d                 => '0',
        ddly              => iserdes_ddly(i),
        ofb               => '0',
        bitslip           => iserdes_slip(i),
        q1                => iserdes_q(i)(0),
        q2                => iserdes_q(i)(1),
        q3                => iserdes_q(i)(2),
        q4                => iserdes_q(i)(3),
        q5                => iserdes_q(i)(4),
        q6                => iserdes_q(i)(5),
        q7                => iserdes_q(i)(6),
        q8                => iserdes_q(i)(7),
        o                 => open,
        shiftin1          => '0',
        shiftin2          => '0',
        shiftout1         => iserdes_shift1(i),
        shiftout2         => iserdes_shift2(i)
      );

    U_ISERDESE2_S: component iserdese2
      generic map (
        serdes_mode       => "SLAVE",
        interface_type    => "NETWORKING",
        iobdelay          => "BOTH",
        data_width        => 10,
        data_rate         => "DDR",
        ofb_used          => "FALSE",
        dyn_clkdiv_inv_en => "FALSE",
        dyn_clk_inv_en    => "FALSE",
        num_ce            => 2,
        init_q1           => '0',
        init_q2           => '0',
        init_q3           => '0',
        init_q4           => '0',
        srval_q1          => '0',
        srval_q2          => '0',
        srval_q3          => '0',
        srval_q4          => '0'
      )
      port map (
        rst               => prst,
        dynclksel         => '0',
        clk               => sclk_p,
        clkb              => sclk_n,
        ce1               => '1',
        ce2               => '1',
        dynclkdivsel      => '0',
        clkdiv            => pclk,
        clkdivp           => '0',
        oclk              => '0',
        oclkb             => '1',
        d                 => '0',
        ddly              => '0',
        ofb               => '0',
        bitslip           => iserdes_slip(i),
        q1                => open,
        q2                => open,
        q3                => iserdes_q(i)(8),
        q4                => iserdes_q(i)(9),
        q5                => open,
        q6                => open,
        q7                => open,
        q8                => open,
        o                 => open,
        shiftin1          => iserdes_shift1(i),
        shiftin2          => iserdes_shift2(i),
        shiftout1         => open,
        shiftout2         => open
      );

  end generate GEN_CH;

end architecture sim;
