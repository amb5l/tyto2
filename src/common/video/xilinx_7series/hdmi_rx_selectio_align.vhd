--------------------------------------------------------------------------------
-- hdmi_rx_selectio_align.vhd                                                 --
-- HDMI sink front end built on Xilinx 7 Series SelectIO primitives -         --
--  TMDS alignment module.                                                    --
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
-- TODO: handle pclk domain channel skew

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;

package hdmi_rx_selectio_align_pkg is

  component hdmi_rx_selectio_align is
    generic (
      interval     : integer := 2048
    );
    port (
      prst         : in    std_logic;
      pclk         : in    std_logic;
      iserdes_q    : in    slv10_vector(0 to 2);
      iserdes_slip : out   std_logic_vector(0 to 2);
      idelay_tap   : out   std_logic_vector(4 downto 0);
      idelay_ld    : out   std_logic_vector(0 to 2);
      tmds         : out   slv10_vector(0 to 2);
      lock         : out   std_logic
    );
  end component hdmi_rx_selectio_align;

end package hdmi_rx_selectio_align_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;

entity hdmi_rx_selectio_align is
  generic (
    interval     : integer := 2048                     -- can reduce for simulation
  );
  port (
    prst         : in    std_logic;
    pclk         : in    std_logic;
    iserdes_q    : in    slv10_vector(0 to 2);         -- raw TMDS input
    iserdes_slip : out   std_logic_vector(0 to 2);     -- bit slip
    idelay_tap   : out   std_logic_vector(4 downto 0); -- tap value (0..31)
    idelay_ld    : out   std_logic_vector(0 to 2);     -- load tap value
    tmds         : out   slv10_vector(0 to 2);         -- aligned TMDS output
    lock         : out   std_logic                     -- lock status
  );
end entity hdmi_rx_selectio_align;

architecture synth of hdmi_rx_selectio_align is

  constant PCOUNT_MAX   : integer := interval-1;
  constant CCOUNT_MIN   : integer := 12;         -- minimum control character sequence length
  constant EYE_OPEN_MIN : integer := 3;          -- minimum eye open (IDELAY taps)

  type state_t is (
    IDLE,
    LOAD_TAP,
    CC_COUNT,
    CC_FINAL,
    CHECK_LOSS,
    NEXT_TAP,
    CHECK_LOCK,
    TAP_SCAN_1,
    TAP_SCAN_2,
    TAP_SCAN_3,
    TAP_SCAN_4,
    NEXT_BITSLIP,
    NEXT_CHANNEL
  );

  type skew_t is (SKEW_BAD, SKEW_0, SKEW_P1, SKEW_N1);
  type ch_skew_t is array(1 to 2) of skew_t;

  signal iserdes_cc       : slv4_vector(0 to 2);                -- control character: 4 clocks x 3 channels
  signal state            : state_t;                            -- state machine
  signal ch               : integer range 0 to 2;               -- current channel #
  signal bitslip          : integer range 0 to 9;               -- bit slip position
  signal tap              : integer range 0 to 31;              -- delay tap
  signal pcount           : integer range 0 to PCOUNT_MAX;      -- count pixels
  signal ccount           : integer range 0 to PCOUNT_MAX;      -- count control characters
  signal tap_ok           : std_logic;                          -- this tap is OK
  signal tap_ok_mask      : std_logic_vector(0 to 31);          -- tap OK mask
  signal scan_pass        : std_logic;                          -- scanning takes 2 passes
  signal scan_start       : integer range 0 to 31;              -- start of OK tap range in progress
  signal scan_tap_ok_prev : std_logic;                          -- previous scanned tap
  signal scan_this_start  : integer range 0 to 31;              -- latest OK tap range start
  signal scan_this_len    : integer range 0 to 31;              -- latest OK tap range length
  signal scan_ok_start    : integer range 0 to 31;              -- best OK tap range start
  signal scan_ok_len      : integer range 0 to 31;              -- best OK tap range length
  signal scan_ok_tap      : integer range 0 to 31;              -- best OK tap
  signal ch_lock          : std_logic_vector(0 to 2);           -- channel lock (serial)
  signal ch_skew          : ch_skew_t;                          -- channel skew (parallel)
  signal lock_p           : std_logic;                          -- parallel lock status
  signal iserdes_q1       : slv10_vector(0 to 2);               -- iserdes_q delayed by 1 clock
  signal iserdes_q2       : slv10_vector(1 to 2);               -- iserdes_q delayed by 2 clocks

begin

  -- input lock
  --  for each channel:
  --    for each bit slip position:
  --      tap OK mask = all zeroes
  --      for each input delay tap:
  --        during 2048 pixel clocks:
  --          look for N x control symbols (N = 12?)
  --          mark this tap OK if found

  process(prst,pclk)
  begin
    if prst = '1' then

      iserdes_cc       <= (others => (others => '0'));
      pcount           <= 0;
      ccount           <= 0;
      tap              <= 0;
      tap_ok           <= '0';
      tap_ok_mask      <= (others => '0');
      bitslip          <= 0;
      ch               <= 0;
      scan_pass        <= '0';
      scan_start       <= 0;
      scan_tap_ok_prev <= '1';
      scan_this_start  <= 0;
      scan_this_len    <= 0;
      scan_ok_start    <= 0;
      scan_ok_len      <= 0;
      ch_lock          <= (others => '0');
      iserdes_slip     <= (others => '0');
      idelay_tap       <= (others => '0');
      idelay_ld        <= (others => '0');
      ch_skew          <= (others => SKEW_BAD);
      lock_p           <= '0';
      iserdes_q1       <= (others => (others => '0'));
      iserdes_q2       <= (others => (others => '0'));

    elsif rising_edge(pclk) then

      -- defaults
      idelay_ld    <= (others => '0');
      iserdes_slip <= (others => '0');

      -- control character detection
      for i in 0 to 2 loop -- for each channel
        iserdes_cc(i)(0) <= '0';
        if iserdes_q(i) = "1101010100" -- } control characters
        or iserdes_q(i) = "0010101011" -- }
        or iserdes_q(i) = "0101010100" -- }
        or iserdes_q(i) = "1010101011" -- }
        then
          iserdes_cc(i)(0) <= '1';
        end if;
        iserdes_cc(i)(3 downto 1) <= iserdes_cc(i)(2 downto 0);
      end loop;

      -- serial alignment state machine
      case state is

        when IDLE =>
          tap_ok  <= '0';
          if ch_lock(ch) = '1' then -- locked, so don't change tap
            state <= CC_COUNT;
          else -- unlocked, so try all taps
            tap         <= 0;
            tap_ok_mask <= (others => '0');
            bitslip     <= 0;
            state       <= LOAD_TAP;
          end if;

        -- load current tap into IDELAY...
        when LOAD_TAP =>
          idelay_tap <= std_logic_vector(to_unsigned(tap,5));
          idelay_ld(ch) <= '1';
          pcount              <= 0;
          ccount              <= 0;
          tap_ok              <= '0';
          state               <= CC_COUNT;

        -- ...then look for control characters for (interval) pclk cycles...
        when CC_COUNT =>
          if iserdes_cc(ch)(0) = '1' then
            ccount <= ccount+1;
          else
            ccount <= 0;
          end if;
          if ccount >= CCOUNT_MIN then -- this tap was OK
            tap_ok <= '1';
          end if;
          if pcount = PCOUNT_MAX then
            pcount <= 0;
            state <= CC_FINAL;
          else
            pcount <= pcount+1;
          end if;

        -- ...then check final character
        when CC_FINAL =>
          if ccount >= CCOUNT_MIN then -- this tap was OK
            tap_ok <= '1';
          end if;
          if ch_lock(ch) = '1' then
            state <= CHECK_LOSS;
          else
            state <= NEXT_TAP;
          end if;

        -- currently locked, so check for loss
        when CHECK_LOSS =>
          if tap_ok = '0' then -- we have lost lock
            ch_lock(ch) <= '0';
            state       <= IDLE;
          else
            state       <= NEXT_CHANNEL;
          end if;

        -- not currently locked, so move to next tap or check results
        when NEXT_TAP =>
          tap_ok_mask(tap) <= tap_ok;
          if tap /= 31 then -- move to next tap
            tap   <= tap+1;
            state <= LOAD_TAP;
          else -- all taps have been tried
            tap   <= 0;
            state <= CHECK_LOCK;
          end if;

        -- initial results check
        when CHECK_LOCK =>
          if tap_ok_mask = x"00000000" then -- shortcut if no taps OK
            state <= NEXT_BITSLIP;
          elsif tap_ok_mask = x"FFFFFFFF" then -- shortcut if all taps OK
            if ch_lock(ch) = '0' then -- we have acquired lock
              ch_lock(ch)   <= '1';
              idelay_tap    <= "01111"; -- set delay to centre
              idelay_ld(ch) <= '1';
            end if;
            state <= NEXT_CHANNEL;
          else -- all taps not OK so scan
            scan_pass        <= '0';
            scan_start       <= 0;
            scan_tap_ok_prev <= '1';
            scan_this_start  <= 0;
            scan_this_len    <= 0;
            scan_ok_start    <= 0;
            scan_ok_len      <= 0;
            state            <= TAP_SCAN_1;
          end if;

        -- scan all tap outcomes (2 passes)
        when TAP_SCAN_1 =>
          if tap_ok_mask(tap) = '1' and scan_tap_ok_prev = '0' then -- OK section start
            scan_start <= tap;
          elsif tap_ok_mask(tap) = '0' and scan_tap_ok_prev = '1' then -- OK section end
            scan_this_start <= scan_start;
            scan_this_len <= ((32+tap)-scan_start) mod 32;
          end if;
          scan_tap_ok_prev <= tap_ok_mask(tap);
          if tap = 31 then
            tap <= 0;
            scan_pass <= not scan_pass;
            if scan_pass = '1' then
              state <= TAP_SCAN_2;
            end if;
          else
            tap <= tap+1;
          end if;
          if scan_this_len > scan_ok_len then
            scan_ok_start <= scan_this_start;
            scan_ok_len   <= scan_this_len;
          end if;

        -- finalise scan...
        when TAP_SCAN_2 =>
          if scan_this_len > scan_ok_len then
            scan_ok_start <= scan_this_start;
            scan_ok_len   <= scan_this_len;
          end if;
          state <= TAP_SCAN_3;

        -- ...then calculate result...
        when TAP_SCAN_3 =>
          scan_ok_tap <= scan_ok_start+(scan_ok_len/2);
          state <= TAP_SCAN_4;

        -- ...then act on result
        when TAP_SCAN_4 =>
          if scan_ok_len >= EYE_OPEN_MIN then -- lock established
            ch_lock(ch)   <= '1';
            idelay_ld(ch) <= '1';
            idelay_tap    <= std_logic_vector(to_unsigned(scan_ok_tap,5));
            state <= NEXT_CHANNEL;
          else
            state <= NEXT_BITSLIP;
          end if;
          -- assumption: no point doing more bit slips

        when NEXT_BITSLIP =>
          if bitslip /= 9 then -- move to next bitslip position
            iserdes_slip(ch) <= '1';
            bitslip          <= bitslip+1;
            tap              <= 0;
            tap_ok_mask      <= (others => '0');
            state            <= LOAD_TAP;
          else -- all bitslips have been tried
            state            <= NEXT_CHANNEL;
          end if;

        when NEXT_CHANNEL =>
          if ch = 2 then
            ch <= 0;
          else
            ch <= ch+1;
          end if;
          state <= IDLE;

      end case;

      -- parallel deskew
      if ch_lock = "111" then -- full serial lock
        if iserdes_cc(0) = "1100" then -- leading edge of control period
          for i in 1 to 2 loop
            -- compare channel i with channel 0
            if iserdes_cc(i) = "1100" then -- channel i is aligned
              ch_skew(i) <= SKEW_0;
            elsif iserdes_cc(i) = "1000" then -- channel i is 1 clock behind
              ch_skew(i) <= SKEW_N1;
            elsif iserdes_cc(i) = "1110" then -- channel i is 1 clock ahead
              ch_skew(i) <= SKEW_P1;
            else -- failure
              ch_skew(i) <= SKEW_BAD;
            end if;
          end loop;
        end if;
      end if;

      -- parallel lock status
      lock_p <= '0';
      if ch_lock = "111" -- full serial lock
      and ch_skew(1) /= SKEW_BAD -- channel 1 parallel deskewed
      and ch_skew(2) /= SKEW_BAD -- channel 2 parallel deskewed
      then
        lock_p <= '1';
      end if;

      -- output
      iserdes_q1(0 to 2) <= iserdes_q(0 to 2);
      iserdes_q2(1 to 2) <= iserdes_q1(1 to 2);
      tmds <= (others => (others => '0'));
      if lock_p = '1' then
        tmds(0) <= iserdes_q1(0);
        for i in 1 to 2 loop
          if ch_skew(i) = SKEW_P1 then
            tmds(i) <= iserdes_q2(i);
          elsif ch_skew(i) = SKEW_N1 then
            tmds(i) <= iserdes_q(i);
          else
            tmds(i) <= iserdes_q1(i);
          end if;
        end loop;
      end if;

    end if;
  end process;

  lock <= lock_p;

end architecture synth;
