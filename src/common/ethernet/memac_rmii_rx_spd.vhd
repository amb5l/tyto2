--------------------------------------------------------------------------------
-- memac_rmii_rx_spd.vhd                                                      --
-- Modular Ethernet MAC (MEMAC): RMII receive speed detection.                --
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

library ieee;
  use ieee.std_logic_1164.all;

package memac_rmii_rx_spd_pkg is

  component memac_rmii_rx_spd is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      i_crs_dv : in    std_ulogic;
      i_er     : in    std_ulogic;
      i_d      : in    std_ulogic_vector(1 downto 0);
      o_crs_dv : out   std_ulogic;
      o_er     : out   std_ulogic;
      o_d      : out   std_ulogic_vector(1 downto 0);
      spd      : out   std_ulogic
    );
  end component memac_rmii_rx_spd;

end package memac_rmii_rx_spd_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity memac_rmii_rx_spd is
  port (

    rst      : in    std_ulogic;
    clk      : in    std_ulogic;

    i_crs_dv : in    std_ulogic;                    -- }
    i_er     : in    std_ulogic;                    -- } RMII input
    i_d      : in    std_ulogic_vector(1 downto 0); -- }

    o_crs_dv : out   std_ulogic;                    -- }
    o_er     : out   std_ulogic;                    -- } RMII output (delayed by 65 clocks)
    o_d      : out   std_ulogic_vector(1 downto 0); -- }

    spd      : out   std_ulogic                     -- speed: 0 = 10Mbps, 1 = 100Mbps, valid 1 clock before RMII output

  );
end entity memac_rmii_rx_spd;

architecture rtl of memac_rmii_rx_spd is

  constant STAGES : integer := 64;

  type i_state_t is (
    IDLE, -- waiting for start of preamble
    PRE,  -- in preamble
    FIN,  -- finishing frame
    FIN2  -- handle potential crs_dv toggling
  );

  signal r_count : unsigned(5 downto 0); -- counter for readiness (covers unknown state of SR after reset)
  signal rdy     : std_ulogic;           -- output is ready (SR is initialised)
  signal i_state : i_state_t;            -- input timing state
  signal i_count : unsigned(5 downto 0); -- input timing counter
  signal i_bad   : std_ulogic;           -- v4p ignore w-303 | input error flag for verification
  signal d_count : unsigned(5 downto 0); -- counter for delayed shift to 100

  -- shift register to delay RMII to align with speed change
  type sr_stage_t is record
    crs_dv : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
  end record sr_stage_t;
  type sr_t is array(1 to STAGES) of sr_stage_t;
  signal sr : sr_t;

begin

  P_MAIN: process(rst, clk)
  begin
    if rst then

      r_count  <= (others => '0');
      rdy      <= '0';
      i_state  <= IDLE;
      i_count  <= (others => '0');
      i_bad    <= '0';
      d_count  <= (others => '0');
      spd      <= '0';
      sr       <= (others => (d => "XX", others => 'X')); -- SRL primitive does not have a reset port
      o_crs_dv <= '0';
      o_er     <= '0';
      o_d      <= (others => '0');

    elsif rising_edge(clk) then

      --------------------------------------------------------------------------------
      -- input timing state machine

      i_bad <= '0'; -- momentary

      case i_state is

          when IDLE =>
            i_count <= (others => '0');
            if rdy = '1' and i_crs_dv = '1' then
              if i_er = '0' and i_d = "01" then
                i_count <= (0 => '1', others => '0');
                i_state <= PRE;
              elsif i_er = '1' or i_d = "10" or i_d = "11" then -- e.g. false carrier
                i_bad   <= '1';
                i_count <= (0 => '1', others => '0');
                i_state <= FIN;
              end if;
            end if;

          when PRE =>
            if i_crs_dv = '0' then -- truncated preamble
              i_bad   <= '1';
              i_state <= FIN2;
            elsif i_er = '1' or i_d = "00" or i_d = "10" then -- corrupt preamble
              i_bad   <= '1';
              i_state <= FIN;
            elsif i_d = "01" then -- preamble di-bit
              if (not i_count) = 0 then -- terminal count
                spd     <= '0'; -- long preamble -> 10Mbps
                i_state <= FIN;
              end if;
            elsif i_d = "11" then -- SFD di-bit
              if i_count(1 downto 0) = "11" then -- octet aligned
                if (not i_count) = 0 then -- terminal count
                  spd <= '1'; -- short preamble -> 100Mbps
                else
                  d_count <= i_count + 1 when d_count = 0; -- schedule speed change to 100Mbps, if no change is currently scheduled
                end if;
              else -- not octet aligned
                i_bad   <= '1';
              end if;
              i_state <= FIN;
            end if;
            i_count <= i_count + 1;

          when FIN =>
            i_count <= i_count + 1;
            i_state <= FIN2 when i_crs_dv = '0';

          when FIN2 =>
            if i_crs_dv = '1' then -- crs_dv is toggling at the end of a frame
              i_count <= i_count + 1;
              i_state <= FIN;
            else
              i_count <= (others => '0');
              i_state <= IDLE;
            end if;

      end case;

      --------------------------------------------------------------------------------
      -- delay counter, to align upshift with SR output

      if d_count /= 0 then
        spd <= '1' when (not d_count) = 0; -- terminal count
        d_count <= d_count + 1;
      end if;

      --------------------------------------------------------------------------------
      -- readiness counter

      rdy     <= '1' when not r_count = 0;
      r_count <= r_count + 1 when rdy = '0';

      --------------------------------------------------------------------------------
      -- shift register delays RMII to allow time for speed detection

      sr(sr'left).crs_dv <= i_crs_dv;
      sr(sr'left).er     <= i_er;
      sr(sr'left).d      <= i_d;
      sr(sr'left + 1 to sr'right) <= sr(sr'left to sr'right - 1);

      --------------------------------------------------------------------------------
      -- output RMII is 1 cycle later than speed change
      -- to allow for 1 cycle latency of clken generation

      o_crs_dv <= '0'             when not rdy else sr(sr'right).crs_dv;
      o_er     <= '0'             when not rdy else sr(sr'right).er;
      o_d      <= (others => '0') when not rdy else sr(sr'right).d;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

  --------------------------------------------------------------------------------
  -- for verification with PSL

  -- clock
  -- psl default clock is rising_edge(clk);

  -- asynchronous reset
  -- psl assert always rst = '1' -> r_count  = (r_count'range => '0');
  -- psl assert always rst = '1' -> rdy      = '0';
  -- psl assert always rst = '1' -> i_state  = IDLE;
  -- psl assert always rst = '1' -> i_count  = (i_count'range => '0');
  -- psl assert always rst = '1' -> i_bad    = '0';
  -- psl assert always rst = '1' -> d_count  = (d_count'range => '0');
  -- psl assert always rst = '1' -> spd      = '0';
  -- psl assert always rst = '1' -> o_crs_dv = '0';
  -- psl assert always rst = '1' -> o_er     = '0';
  -- psl assert always rst = '1' -> o_d      = (o_d'range => '0');

  -- restrict analysis: every execution trace starts with a 1 clock reset
  --  and 64 clocks of quiet time to allow rdy to assert
  -- psl
  --  restrict {
  --    rst = '1' and i_crs_dv = '0' and i_er = '0' and i_d = "00";
  --    rst = '0' and i_crs_dv = '0' and i_er = '0' and i_d = "00" [*64];
  --    rst = '0' [*]
  --  };

  -- r_count behaviour
  -- psl
  --  assert always (
  --    {
  --      rdy = '0';
  --      true
  --    } |-> r_count = prev(r_count) + 1
  --  ) abort rst = '1';

  -- rdy behaviour
  -- psl
  --  assert always (
  --    {
  --      not r_count = 0;
  --      true
  --    } |-> rdy = '1'
  --  ) abort rst = '1';

  -- crs_dv negation during preamble or frame
  -- psl
  --  assert always (
  --    {
  --      (i_state = PRE or i_state = FIN) and i_crs_dv = '0';
  --      true
  --    } |-> i_state = FIN2
  --  ) abort rst = '1';

  -- crs_dv toggling at end of frame
  -- psl
  --  assert always (
  --    {
  --      i_state = FIN2 and i_crs_dv = '1';
  --      true
  --    } |-> i_state = FIN
  --  ) abort rst = '1';

  -- 2 negated cycles of crs_dv cause transition to idle
  -- psl
  --  assert always (
  --    {
  --      i_crs_dv = '0' [*2];
  --      true
  --    } |-> i_state = IDLE
  --  ) abort rst = '1';
  -- end psl

  -- counter is set to 1 at transition out of idle
  -- psl
  --  assert always (
  --    {
  --      i_state = IDLE;
  --      i_state /= IDLE
  --    } |-> i_count = 1
  --  ) abort rst = '1';

  -- counter increments throughout frame
  -- psl
  --  assert always (
  --    {
  --      i_crs_dv = '1' and i_state /= IDLE;
  --      true
  --    } |->i_count = prev(i_count) + 1
  --  ) abort rst = '1';

  -- counter is zeroed at transition to idle
  -- psl
  --  assert always (
  --    {
  --      true;
  --      i_state = IDLE
  --    } |-> i_count = 0
  --  ) abort rst = '1';

  -- good start of preamble
  -- psl
  --  assert always (
  --    {
  --      i_crs_dv = '0' [*2];
  --      i_crs_dv = '1' and i_er = '0' and i_d = "00" [*0 to 2];
  --      rdy = '1' and i_crs_dv = '1' and i_er = '0' and i_d = "01";
  --      true
  --    } |-> i_state = PRE
  --  ) abort rst = '1';

  -- bad start of preamble
  -- psl
  --  assert always (
  --    {
  --      i_crs_dv = '0' [*2];
  --      i_crs_dv = '1' and i_er = '0' and i_d = "00" [*0 to 2];
  --      rdy = '1' and i_crs_dv = '1' and (i_er = '1' or i_d = "10" or i_d = "11");
  --      true
  --    } |-> i_state = FIN and i_bad = '1'
  --  ) abort rst = '1';

  -- truncated preamble
  -- psl
  --  assert always (
  --    {
  --      i_state = PRE and i_crs_dv = '0';
  --      true
  --    } |-> i_state = FIN2 and i_bad = '1'
  --  ) abort rst = '1';

  -- corruption during preamble
  -- psl
  --  assert always (
  --    {
  --      i_state = PRE and i_crs_dv = '1' and (i_er = '1' or i_d = "10");
  --      true
  --    } |-> i_state = FIN and i_bad = '1'
  --  ) abort rst = '1';

  -- octet aligned SFD (preamble + SFD is < 64 dibits) -> scheduled speed upshift
  -- psl
  --  assert always (
  --    {
  --      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "11" and i_count(5 downto 2) /= "1111" and i_count(1 downto 0) = "11";
  --      true
  --    } |-> i_state = FIN and ((d_count = prev(i_count) + 1 and prev(d_count) = 0) or (d_count = prev(d_count) + 1))
  --  ) abort rst = '1';

  -- octet aligned SFD (preamble + SFD = 64 dibits) -> immediate speed upshift
  -- psl
  --  assert always (
  --    {
  --      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "11" and i_count(5 downto 2) = "1111" and i_count(1 downto 0) = "11";
  --      true
  --    } |-> i_state = FIN and spd = '1' and ((d_count = 0 and prev(d_count) = 0) or (d_count = prev(d_count) + 1 and prev(d_count) /= 0))
  --  ) abort rst = '1';

  -- non octet aligned SFD
  -- psl
  --  assert always (
  --    {
  --      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "11" and i_count(1 downto 0) /= "11";
  --      true
  --    } |-> i_state = FIN and i_bad = '1' and ((d_count = prev(d_count) + 1 and prev(d_count) /= 0) or (d_count = 0 and prev(d_count) = 0))
  --  ) abort rst = '1';

  -- d_count behaviour
  -- psl
  --  assert always (
  --    {
  --      d_count /= 0;
  --      true
  --    } |-> d_count = prev(d_count) + 1
  --  ) abort rst = '1';

  -- spd assertion by d_count
  -- psl
  --  assert always (
  --    {
  --      not d_count = 0;
  --      true
  --    } |-> spd = '1'
  --  ) abort rst = '1';

  -- 64 cycles of preamble -> 10Mbps
  -- psl
  --  assert always (
  --    {
  --      i_state = PRE and i_crs_dv = '1' and i_er = '0' and i_d = "01" and not i_count = 0;
  --      true
  --    } |-> spd = '0'
  --  ) abort rst = '1';

  -- don't change speed

  --------------------------------------------------------------------------------

end architecture rtl;
