--------------------------------------------------------------------------------
-- tb_memac_rmii.vhd                                                          --
-- Modular Ethernet MAC: testbench for RMII PHY interface IPs.                --
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
-- testbench

library memac;
  context memac.memac_sim_rmii_ctx;

entity tb_memac_rmii is
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
end entity tb_memac_rmii;

architecture sim of tb_memac_rmii is

  constant VERBOSE : boolean := false;

  signal rst  : std_ulogic;
  signal clk  : std_ulogic;
  signal gclk : std_ulogic;
  signal rmii : rmii_rx_t;
  signal umii : umii_t;

  shared variable rq : memac.memac_sim_queue_umii_pkg.queue_t; -- received queue
  shared variable xq : memac.memac_sim_queue_umii_pkg.queue_t; -- expected queue

begin

  --------------------------------------------------------------------------------
  -- basics

  rst <= '1', '0' after 100 ns;

  clk <= '0' when clk = 'U' else not clk after RMII_CLK_PERIOD/2;

  gclk     <= clk;
  rmii.clk <= clk;
  umii.clk <= clk;

  --------------------------------------------------------------------------------
  -- drive DUT RMII input
  -- TODO: play with CRS state during frame

  P_SOURCE: process
    variable prng   : prng_t;
    variable frames : positive;
    variable octet  : umii_octet_t;
    variable s      : integer range 0 to 1;
    variable n      : natural;
    variable d      : std_ulogic_vector(7 downto 0);

    procedure debugmsg(s : string) is
    begin
      if VERBOSE then
        report s severity note;
      end if;
    end procedure debugmsg;

  begin
    -- initialise comparison queue
    xq.reset;
    -- initialise RMII
    rmii.spd    <= 'U';
    rmii.clk    <= 'Z'; -- driven outside this process
    rmii.crs_dv <= '0';
    rmii.er     <= '0';
    rmii.d      <= (others => '0');
    -- initialise PRNG
    prng.rand_seed(123, 456);
    wait until falling_edge(rst);
    -- Starting from a carrier loss situation, bring up the carrier and
    -- generate a set of frames. Drop the carrier at the end, from somewhere
    -- before the end of the last frame to somewhere after it.
    -- Chose the speed randomly for each frame set.
    LOOP_SET: for frame_set in 1 to FRAME_SETS loop
      -- number of frames in this set
      frames := prng.rand_int(1, FRAMES_PER_SET_MAX);
      -- random speed (10/100)
      s := prng.rand_int(0, 1);
      report "set " & to_string(frame_set) & ": spd = " & to_string(s) severity note;
      rmii.spd <= '1' when s = 1 else '0';
      wait for 0 ns;                                       -- allow speed change to be seen
      -- carrier loss period
      n := prng.rand_int(CRL_MIN, CRL_MAX);                -- period length (dibits)
      debugmsg("set " & to_string(frame_set) &
        ": carrier loss period = " & to_string(n) & " clocks");
      sim_tx_rmii_rx_dibit(rmii, ('0', '0', "00"), n);     -- transmit dibits
      -- carrier sense period
      n := prng.rand_int(CRS_MIN, CRS_MAX);                -- period length (dibits)
      debugmsg("set " & to_string(frame_set) &
        ": carrier sense period = " &
        to_string(n) & " clocks");
      sim_tx_rmii_rx_dibit(rmii, ('1', '0', "00"), n);     -- transmit dibits
      -- frames
      LOOP_FRAME: for frame in 1 to frames loop
        -- preamble
        n := prng.rand_int(PRE_MIN, PRE_MAX);              -- period length (octets)
        debugmsg("set " & to_string(frame_set) &
          " frame " & to_string(frame) &
          ": preamble period = " &
          to_string(1+n) & " octets");
        octet := ( "11", "00", x"55" );                    -- preamble octet
        xq.enq(octet, n);                                  -- add octets to comparison queue
        sim_tx_rmii_rx_octet(rmii, octet, "X1");           -- transmit first octet
        sim_tx_rmii_rx_octet(rmii, octet, "XX", n-1);      -- transmit remaining octets
        -- SFD
        debugmsg("set " & to_string(frame_set) &
          " frame " & to_string(frame) &
          ": SFD (single octet)");
        octet := ( "11", "00", x"D5" );                    -- SFD octet
        xq.enq(octet);                                     -- add octet to comparison queue
        sim_tx_rmii_rx_octet(rmii, octet, "XX");           -- transmit octet
        -- frame
        n := prng.rand_int(FRAME_MIN, FRAME_MAX);          -- frame length (octets)
        debugmsg("set " & to_string(frame_set) &
        " frame " & to_string(frame) &
        ": frame period = " & to_string(n) & " octets");
        for i in 1 to n loop                               -- random frame data
          d := prng.rand_slv(0, 255, 8);                   -- random data
          octet := ( "11", "00", d );                      -- octet
          xq.enq(octet);                                   -- add octet to comparison queue
          sim_tx_rmii_rx_octet(rmii, octet, "XX");         -- transmit octet
        end loop;
        if frame /= frames then                            -- not last frame
          -- IPG
          n := prng.rand_int(IPG_MIN, IPG_MAX);            -- period length (dibits)
          debugmsg("set " & to_string(frame_set) &
          " frame " & to_string(frame) &
          ": IPG = " & to_string(n) & " octets");
          octet := ( "00", "00", x"00" );                  -- IPG octet
          xq.enq(octet, n);                                -- add octets to comparison queue
          sim_tx_rmii_rx_octet(rmii, octet, "00", n);      -- transmit octets
          -- IPG jitter
          n := prng.rand_int(0, 3);                        -- 0-3 dibits
          debugmsg("set " & to_string(frame_set) &
          " frame " & to_string(frame) &
          ": IPG jitter = " & to_string(n) & " dibits");
          sim_tx_rmii_rx_dibit(rmii, ('0', '0', "00"), n); -- transmit dibits
        end if;
      end loop LOOP_FRAME;
    end loop LOOP_SET;
    debugmsg("halting RMII source");
    octet := ( "00", "00", "X0X0X0X0" );                   -- stop simulation octet
    xq.enq(octet);                                         -- add octet to comparison queue
    sim_tx_rmii_rx_octet(rmii, octet, "00", n);            -- transmit octet
    wait;
  end process P_SOURCE;

  --------------------------------------------------------------------------------
  -- check DUT UMII output

  P_CHECK: process(umii.clk)
  begin
    if rising_edge(umii.clk) and umii.clken = '1' then
      if xq.items > 0 then
        if  xq.front.dv = "00"
        and xq.front.er = "00"
        and xq.front.d = "X0X0X0X0"
        then
          report "FINISHED" severity note;
          std.env.stop;
        end if;
      end if;
      -- accept differences between received and expected during gaps
      if umii.dv = "00" and umii.er = "00" and umii.d = x"00" then
        if xq.items > 0 then
          if  xq.front.dv = "00" and xq.front.er = "00" and xq.front.d = x"00" then
            xq.deq;
          end if;
        end if;
      else
        if umii.dv /= xq.front.dv or umii.er /= xq.front.er or umii.d /= xq.front.d then
          report "mismatch" & LF &
            "  got: " & LF &
            "    dv  = " & to_string( umii.dv  ) & LF &
            "    er  = " & to_string( umii.er  ) & LF &
            "    d   = " & to_string( umii.d   ) & LF &
            "  exp: " & LF &
            "    dv  = " & to_string( xq.front.dv  ) & LF &
            "    er  = " & to_string( xq.front.er  ) & LF &
            "    d   = " & to_string( xq.front.d   )
            severity failure;
        end if;
        xq.deq;
      end if;
    end if;
  end process P_CHECK;

  --------------------------------------------------------------------------------
  -- DUT

  DUT: component memac_rx_rmii
    port map (
      rst         => rst,
      clk         => gclk,
      rmii_spd    => rmii.spd,
      rmii_crs_dv => rmii.crs_dv,
      rmii_er     => rmii.er,
      rmii_d      => rmii.d,
      umii_clken  => umii.clken,
      umii_dv     => umii.dv,
      umii_er     => umii.er,
      umii_d      => umii.d
    );

  --------------------------------------------------------------------------------

end architecture sim;
