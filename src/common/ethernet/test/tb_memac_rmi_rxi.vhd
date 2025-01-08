--------------------------------------------------------------------------------
-- tb_memac_rmi_rx.vhd                                                        --
-- Modular Ethernet MAC: testbench for memac_rmi_rx.                          --
--------------------------------------------------------------------------------
-- (C) Copyright 2025 Adam Barnes <ambarnes@gmail.com>                        --
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
-- Test operation:
-- 1. Create random RMII traffic sequences.
-- 2. Drive each sequence into the RMII RX DUT, and also the comparison queue.
-- 3. Wire the RMII RX and TX DUT UMII interfaces back to back.
-- 4. Capture RMII traffic sequences from the RMII TX DUT.
-- 5. Compare them with the sequences in the comparison queue.
--------------------------------------------------------------------------------
-- type for queue package instance

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_rmii_rx_types_pkg is

  type rmii8_t is record
    crs_dv : std_logic_vector(3 downto 0);
    er     : std_logic_vector(3 downto 0);
    d      : std_logic_vector(7 downto 0);
  end record rmii8_t;

  constant RMII8_U : rmii8_t := (others => (others => 'U'));

end package tb_memac_rmii_rx_types_pkg;

--------------------------------------------------------------------------------
-- queue package instance

use work.tb_memac_rmii_rx_types_pkg.all;
library memac;

package tb_memac_rmii_rx_queue_rmii8_pkg is
  new memac.memac_sim_queue_pkg generic map(queue_item_t => rmii8_t, empty => RMII8_U);

--------------------------------------------------------------------------------
-- testbench

use work.tb_memac_rmii_rx_types_pkg.all;

library memac;
  context memac.memac_sim_rmii_rx_ctx;

entity tb_memac_rmii_rx is
  generic (
    FRAME_SETS         : positive := 10;   -- how many sets of frames to generate
    FRAMES_PER_SET_MAX : positive := 10;   -- maximum number of frames per set
    CRL_MIN            : positive := 1;    -- carrier loss period - minimum, dibits
    CRL_MAX            : positive := 100;  -- carrier loss period - maximum, dibits
    CRS_MIN            : positive := 1;    -- carrier sense period (before frame) - minimum, dibits
    CRS_MAX            : positive := 20;   -- carrier sense period (before frame) - maximum, dibits
    PRE_MIN            : positive := 1;    -- frame preamble - minimum, octets
    PRE_MAX            : positive := 20;   -- frame preamble - maximum, octets
    FRAME_MIN          : positive := 1;    -- minimum frame length, octets (less than 42 violates spec)
    FRAME_MAX          : natural  := 1522; -- maximum frame length, octets (aka MTU)
    IPG_MIN            : positive := 1;    -- inter packet gap - minimum, octets
    IPG_MAX            : positive := 100   -- inter packet gap - maximum, octets
  );
end entity tb_memac_rmii_rx;

architecture sim of tb_memac_rmii_rx is

  type rmii_t is record
    crs_dv : std_logic;
    er     : std_logic;
    d      : std_logic_vector(1 downto 0);
  end record rmii_t;
  
  signal rst         : std_ulogic;
  signal clk         : std_ulogic;

  signal rmii_link   : std_ulogic;
  signal rmii_spd    : std_ulogic;
  signal rmii_clken  : std_ulogic;
  signal rmii_dv     : std_ulogic; -- v4p ignore w-303 (for waveform)
  signal rmii_crs_dv : std_ulogic;
  signal rmii_er     : std_ulogic;
  signal rmii_d      : std_ulogic_vector(1 downto 0);

  signal umii_clken  : std_ulogic;
  signal umii_dv     : std_ulogic;
  signal umii_er     : std_ulogic;
  signal umii_d      : std_ulogic_vector(7 downto 0);

  signal dbg_crs_dv  : std_ulogic_vector(3 downto 0);
  signal dbg_er      : std_ulogic_vector(3 downto 0);

  shared variable xq  : work.tb_memac_rmii_rx_queue_rmii8_pkg.queue_t; -- expected queue

begin

  --------------------------------------------------------------------------------
  -- basics

  rst <= '1', '0' after 100 ns;

  clk <= '0' when clk = 'U' else not clk after RMII_CLK_PERIOD/2;

  --------------------------------------------------------------------------------
  -- drive DUT RMII input
  -- TODO:
  -- false carrier event
  -- DV glitch
  -- DV negation at odd nybble

  rmii_dv <= '0' when rmii_crs_dv = '0' else '1'; -- useful wavefore

  P_SOURCE: process
    variable prng   : prng_t;
    variable rmii   : rmii_t;
    variable rmii8  : rmii8_t;
    variable n      : natural;
    variable d      : std_ulogic_vector(7 downto 0);

  procedure stim_rmii_tx_clk is
    variable n : natural;
  begin
    n := 10 when rmii_spd = '0' else 1;
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure stim_rmii_tx_clk;

  procedure stim_rmii_tx_clk(n : natural) is
  begin
    if n > 0 then
      for i in 1 to n loop
        stim_rmii_tx_clk;
      end loop;
    end if;
  end procedure stim_rmii_tx_clk;

  procedure stim_rmii_tx2(s : in rmii_t) is
  begin
    stim_rmii_tx_clk;
    rmii_crs_dv <= s.crs_dv;
    rmii_er     <= s.er;
    rmii_d      <= s.d;
  end procedure stim_rmii_tx2;

  procedure stim_rmii_tx2(s : in rmii_t; n : in natural) is
  begin
    if n > 0 then
      for i in 1 to n loop
        stim_rmii_tx2(s);
      end loop;
    end if;
  end procedure stim_rmii_tx2;

  procedure stim_rmii_tx8(s : in rmii8_t) is
  begin
    stim_rmii_tx2((s.crs_dv(0), s.er(0), s.d(1 downto 0)));
    stim_rmii_tx2((s.crs_dv(1), s.er(1), s.d(3 downto 2)));
    stim_rmii_tx2((s.crs_dv(2), s.er(2), s.d(5 downto 4)));
    stim_rmii_tx2((s.crs_dv(3), s.er(3), s.d(7 downto 6)));
  end procedure stim_rmii_tx8;

  begin

    -- initialise
    xq.reset;
    prng.rand_seed(123, 456);
    rmii_link   <= 'X';
    rmii_spd    <= 'X';
    rmii_crs_dv <= '0';
    rmii_er     <= '0';
    rmii_d      <= (others => '0');
    wait until falling_edge(rst);
    stim_rmii_tx_clk;

    -- startup:
    rmii_link   <= '0';
    rmii_spd    <= 'X';
    rmii_crs_dv <= 'X';
    rmii_er     <= 'X';
    rmii_d      <= (others => 'X');


    -- timing permutations at start of frame

    LOOP_SPEED: for test_speed in 0 to 1 loop                                   -- speed (10/100)
      LOOP_LINK: for test_link in -1 to 10 loop                                 -- link up to carrier sense
        LOOP_CRL: for test_crl in 2 to 5 loop                                   -- carrier loss period (>= 2 otherwise looks like toggling CRS_DV)
          LOOP_CRS: for test_crs in 1 to 5 loop                                 -- rmii_crs_dv assertion relative to premable
            LOOP_ACT: for test_act in 2 to 8 loop                               -- active period
              report "speed = " & to_string(test_speed) & "  " &
                      "crl = " & to_string(test_crl) & "  " &
                      "crs = " & to_string(test_crs) & "  " &
                      "act = " & to_string(test_act)
                      severity note;
              -- initial conditions
              rmii_link   <= 'X';
              rmii_spd    <= 'X';
              rmii_crs_dv <= '0';
              rmii_er     <= '0';
              rmii_d      <= (others => '0');
              -- period: carrier loss
              xq.enq(rmii8_t'("0000", "0000", x"00"), test_crl mod 4);          -- queue whole octets
              wait for test_crl * RMII_CLK_PERIOD;
              -- period: carrier sense before preamble
              xq.enq(("0000", "0000", x"00"), test_crl mod 4);                  -- queue whole octets

              rmii_crs_dv <= 'X';
              wait for test_crs * RMII_CLK_PERIOD;
              -- period: activity (frame contents)
              -- link is sampled on the first cycle of preamble
              for i in 0 to test_act-1 loop
                if i = 0 then
                  rmii_link <= '1' when test_link = 1 else '0';
                  rmii_spd  <= '0' when test_speed = 0 else '1';
                else
                  rmii_link <= 'X';
                end if;
                if i < 2 then
                  rmii := ('1', '0', "01");                                     -- 1st and 2nd dibit must be clean preamble
                else
                  d := prng.rand_slv(0,7,8);
                  rmii.crs_dv := 'X' when i mod 2 = 0 else '1';                 -- DV = 1, CRS = X
                  rmii.er     := d(2);
                  rmii.d      := d(1 downto 0);
                end if;
                rmii8 := (others => (others => 'U')) when i mod 4 = 0;
                rmii8.crs_dv(i mod 4)                       := rmii.crs_dv;
                rmii8.er(i mod 4)                           := rmii.er;
                rmii8.d(1+(2*(i mod 4)) downto 2*(i mod 4)) := rmii.d;
                if i mod 4 = 3 then
                  xq.enq(rmii8);
                  report "enq rmii8 = " & to_string(rmii8.crs_dv) & " " & to_string(rmii8.er) & " " & to_string(rmii8.d) severity note;
                end if;
                stim_rmii_tx2(rmii);
              end loop;
            end loop LOOP_ACT;
          end loop LOOP_CRS;
        end loop LOOP_CRL;
      end loop LOOP_LINK;
    end loop LOOP_SPEED;
    report "SOURCE FINISHED" severity note;
    xq.enq(("0000", "0000", "X0X0X0X0")); -- request stop
    wait;
  end process P_SOURCE;

  --------------------------------------------------------------------------------
  -- check DUT RMII8 (internal) and UMII (output)

  P_CHECK: process(rst, clk)

    variable umii_dv_prev : std_ulogic := 'U';

    impure function signal_states return string is
    begin
      return
        "       umii_dv = "    & to_string(umii_dv) & LF &
        "       umii_er = "    & to_string(umii_er) & LF &
        "        umii_d = "     & to_string(umii_d) & LF &
        "    dbg_crs_dv = " & to_string(dbg_crs_dv) & LF &
        "        dbg_er = "     & to_string(dbg_er);
    end function signal_states;

    impure function expected_states return string is
    begin
      return
        "    crs_dv = " & to_string(xq.front.crs_dv) & LF &
        "        er = "     & to_string(xq.front.er) & LF &
        "         d = "      & to_string(xq.front.d);
    end function expected_states;

    procedure compare is
    begin
      if dbg_crs_dv /= xq.front.crs_dv
      or dbg_er     /= xq.front.er
      or umii_d     /= xq.front.d
      then
        report "miscompare:" & LF &
               "  expected:" & LF & expected_states & LF &
               "  got:" & LF & signal_states severity failure;
      end if;
    end procedure compare;

  begin

    if rst then

      umii_dv_prev := 'U';

    elsif rising_edge(clk) and umii_clken = '1' then

      -- check for special stop pattern
      if  xq.front = ("0000", "0000", "X0X0X0X0") then
        report "FINISHED" severity note;
        std.env.stop;
      end if;

      -- simple validity checks
      assert valid(umii_dv)
        report "umii_dv is invalid" severity failure;
      assert valid(umii_er)
        report "umii_er is invalid" severity failure;
      assert valid(umii_d)
        report "umii_d is invalid" severity failure;
      if umii_dv = '1' then
        assert valid(umii_dv_prev)
          report "umii_dv_prev is invalid" severity failure;
        if umii_dv_prev = '0' then -- first octet of frame
          assert valid(dbg_crs_dv(0) & dbg_crs_dv(1) & dbg_crs_dv(3))
            report "dbg_crs_dv is invalid for first octet of frame: " &
            to_string(dbg_crs_dv) severity failure;
        else
          assert valid(dbg_crs_dv(1) & dbg_crs_dv(3))
            report "dbg_crs_dv is invalid after first octet of frame: " &
            to_string(dbg_crs_dv) severity failure;
        end if;
      else
        assert valid(dbg_crs_dv)
          report "dbg_crs_dv is invalid during gap: " &
          to_string(dbg_crs_dv) severity failure;
      end if;
      assert valid(dbg_er)
        report "dbg_er is invalid" severity failure;

      -- process octet
      assert (xq.items > 0)
        report "unexpected octet" severity failure;
      if umii_dv = '0' then -- gap
        assert umii_er = '0' and umii_d = x"00" and dbg_crs_dv = "0000" and dbg_er = "0000"
          report "bad gap: " & LF & signal_states severity failure;
        compare;
      else -- activity
        if umii_dv_prev = '0' then -- first octet of frame
          while xq.items > 0 and xq.front = ("0000", "0000", x"00") loop -- flush gaps
            xq.deq;
          end loop;
        end if;
        compare;
        xq.deq;
      end if;

      -- track DV
      umii_dv_prev := umii_dv;

    end if;
  end process P_CHECK;

  --------------------------------------------------------------------------------
  -- DUT

  DUT_CLK: component memac_rmii_clken
    port map (
      rst        => rst,
      clk        => clk,
      rmii_spd   => rmii_spd,
      rmii_clken => rmii_clken,
      umii_clken => umii_clken
    );

  DUT: component memac_rx_rmii
    port map (
      rst         => rst,
      clk         => clk,
      rmii_link   => rmii_link,
      rmii_clken  => rmii_clken,
      rmii_crs_dv => rmii_crs_dv,
      rmii_er     => rmii_er,
      rmii_d      => rmii_d,
      umii_clken  => umii_clken,
      umii_dv     => umii_dv,
      umii_er     => umii_er,
      umii_d      => umii_d,
      dbg_crs_dv  => dbg_crs_dv,
      dbg_er      => dbg_er
    );

  --------------------------------------------------------------------------------

end architecture sim;

--------------------------------------------------------------------------------
-- configurations

configuration cfg_tb_memac_rmii_rx_behavioural of tb_memac_rmii_rx is
  for sim
    for DUT: memac_rx_rmii
      use entity memac.memac_rx_rmii(rtl);
    end for;
  end for;
end configuration cfg_tb_memac_rmii_rx_behavioural;

configuration cfg_tb_memac_rmii_rx_post_syn_func of tb_memac_rmii_rx is
  for sim
    for DUT: memac_rx_rmii
      use entity work.memac_rx_rmii(STRUCTURE);
    end for;
  end for;
end configuration cfg_tb_memac_rmii_rx_post_syn_func;


--------------------------------------------------------------------------------