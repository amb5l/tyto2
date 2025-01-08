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
      rdy      : out   std_ulogic;
      stb      : out   std_ulogic;
      spd      : out   std_ulogic;
      err      : out   std_ulogic
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
    i_crs_dv : in    std_ulogic;
    i_er     : in    std_ulogic;
    i_d      : in    std_ulogic_vector(1 downto 0);
    o_crs_dv : out   std_ulogic;
    o_er     : out   std_ulogic;
    o_d      : out   std_ulogic_vector(1 downto 0);
    rdy      : out   std_ulogic;                    -- output is ready (useful for simulation)
    stb      : out   std_ulogic;                    -- pulse on detect
    spd      : out   std_ulogic;                    -- 0 = 10Mbps, 1 = 100Mbps
    err      : out   std_ulogic                     -- error
  );
end entity memac_rmii_rx_spd;

architecture rtl of memac_rmii_rx_spd is

  constant THRESHOLD : integer := 64;

  -- speed detection state machine
  type state_t is (
    IDLE, -- waiting for start of preamble
    PRE,  -- in preamble
    W100, -- waiting for SR delay to signal 100Mbps
    FIN   -- finishing frame
  );
  signal state : state_t;
  signal count : unsigned(5 downto 0); -- 0..63

  -- shift register to delay RMII to align with speed change
  type sr_stage_t is record
    crs_dv : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
  end record sr_stage_t;
  type sr_t is array(1 to THRESHOLD) of sr_stage_t;
  signal sr : sr_t;
  signal sr_count : unsigned(5 downto 0); -- 0..63

begin

  P_MAIN: process(rst, clk)
  begin
    if rst then

      count    <= (others => '0');
      rdy      <= '0';
      spd      <= 'H'; -- '1' for synthesis, indicates failed/uninitialised for simulation
      err      <= '0';
      sr       <= (others => (d => "XX", others => 'X')); -- SRL primitive does not have a reset port
      sr_count <= (others => '0');
      o_crs_dv <= 'L';
      o_er     <= 'L';
      o_d      <= (others => 'L');

    elsif rising_edge(clk) then

      stb <= '0'; -- momentary

      --------------------------------------------------------------------------------
      -- state machine
      -- allow 64 clocks (16 octets @ 100Mbps) to determine speed

      stb <= '0'; -- momentary
      case state is

        when IDLE => -- wait for start of preamble
          err <= '0';
          if i_crs_dv = '1' and i_er = '0' then
            if i_d = "01" then
              spd      <= 'H' when spd = '1' else 'L' when spd = '0'; -- indicate uncertainty to simulation
              count(0) <= '1';
              state    <= PRE;
            elsif i_d /= "00" then -- e.g. false carrier
              state <= FIN;
            end if;
          end if;

        when PRE => -- in preamble
          if i_crs_dv = '0' then -- end of preamble before SFD
            err   <= '1';
            count <= (others => '0');
            state <= IDLE;
          elsif i_er = '1' then -- corrupt preamble
            err   <= '1';
            count <= (others => '0');
            state <= FIN;
          elsif i_d = "01" then -- preamble di-bit
            if not count = 0 then -- terminal count
              -- long preamble -> 10Mbps
              spd   <= '0'; -- 10Mbps with certainty
              stb   <= '1';
              count <= (others => '0');
              state <= FIN;
            end if;
          elsif i_d = "11" then -- SFD di-bit
            count <= (others => '0');
            state <= FIN;
            if count(1 downto 0) = "11" then -- octet aligned
              if not count = 0 then -- terminal count
                -- 100Mbps
                spd   <= '1'; -- 100Mbps with certainty
                stb   <= '1';
                count <= (others => '0');
                state <= FIN;
              else
                count <= count + 1;
                state <= W100;
              end if;
            else -- not octet aligned
              err   <= '1';
              count <= (others => '0');
              state <= FIN;
            end if;
          else -- corrupt preamble
            err   <= '1';
            count <= (others => '0');
            state <= FIN;
          end if;

        when W100 => -- wait for SR delay to align speed change to 100Mbps
          if i_crs_dv = '0' then -- truncated frame
            err   <= '1';
            count <= (others => '0');
            state <= IDLE;
          elsif not count = 0 then -- terminal count
            spd <= '1';
            stb <= '1';
            count <= (others => '0');
            state <= FIN;
          else
            count <= count + 1;
          end if;

        when FIN => -- finishing frame
          if i_crs_dv = '0' then
            count <= (others => '0');
            state <= IDLE;
          end if;

      end case;

      --------------------------------------------------------------------------------
      -- shift register delays RMII to align with speed change

      sr(sr'left).crs_dv <= i_crs_dv;
      sr(sr'left).er     <= i_er;
      sr(sr'left).d      <= i_d;
      sr(sr'left + 1 to sr'right) <= sr(sr'left to sr'right - 1);

      sr_count <= sr_count + 1 when rdy = '0';
      rdy <= '1' when not sr_count = 0;

      --------------------------------------------------------------------------------
      -- output RMII is 1 cycle later than speed change
      -- to allow for 1 cycle latency of clken generation

      -- 'L' state -> '0' for synthesis, but is useful for simulation
      o_crs_dv <= 'L'             when not rdy else sr(sr'right).crs_dv;
      o_er     <= 'L'             when not rdy else sr(sr'right).er;
      o_d      <= (others => 'L') when not rdy else sr(sr'right).d;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

end architecture rtl;
