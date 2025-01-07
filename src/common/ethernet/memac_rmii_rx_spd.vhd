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
      stb      : out   std_ulogic;
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
    i_crs_dv : in    std_ulogic;
    i_er     : in    std_ulogic;
    i_d      : in    std_ulogic_vector(1 downto 0);
    o_crs_dv : out   std_ulogic;
    o_er     : out   std_ulogic;
    o_d      : out   std_ulogic_vector(1 downto 0);
    stb      : out   std_ulogic;                    -- pulse on detect
    spd      : out   std_ulogic                     -- 0 = 10Mbps, 1 = 100Mbps
  );
end entity memac_rmii_rx_spd;

architecture rtl of memac_rmii_rx_spd is

  constant THRESHOLD : integer := 31;

  -- speed detection state machine
  type state_t is (IDLE, PRE, FIN, ACT);
  signal state : state_t;
  signal count : unsigned(5 downto 0); -- 0..63
  signal i_spd : std_ulogic;

  -- shift register to delay RMII to align with speed change
  type sr_stage_t is record
    crs_dv : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
  end record sr_stage_t;
  type sr_t is array(1 to THRESHOLD) of sr_stage_t;
  signal sr : sr_t;

begin

  P_MAIN: process(rst, clk)
  begin
    if rst then

      count    <= (others => '0');
      i_spd    <= 'X';
      spd      <= '1';
      sr.all   <= '0';
      o_crs_dv <= '0';
      o_er     <= '0';
      o_d      <= (others => '0');

    elsif rising_edge(clk) then

      --------------------------------------------------------------------------------
      -- state machine
      -- allow 64 clocks (16 octets @ 100Mbps) to determine speed

      stb <= '0'; -- momentary
      case state is

        when IDLE =>
          count <= (others => '0');
          if i_crs_dv = '1' then
            if i_d = "01" then
              count(0) <= '1';
              state    <= PRE;
            elsif i_d /= "00" then -- e.g. false carrier
              state <= ACT;
            end if;
          end if;

        when PRE =>
          if i_crs_dv = '0' then -- truncated frame
            state <= IDLE;
          elsif i_d /= "01" then
            if i_d = "11" and count(1 downto 0) = "11" then -- correctly aligned SFD
              if count > THRESHOLD then
                i_spd <= '0';
              else
                i_spd <= '1';
              end if;
              if not count = 0 then -- terminal count
                -- output speed change now
                if count > THRESHOLD then
                  spd <= '0';
                else
                  spd <= '1';
                end if;
                stb   <= '1';
                state <= ACT;
              else
                -- output speed change at end of SR delay
                state <= FIN;
              end if;
            else -- false carrier or other error -> abort measurement
              i_spd <= 'X';
              count <= 0;
              state <= ACT;
            end if;
          elsif not count = 0 then -- terminal count, no SFD -> abort measurement
            i_spd <= 'X';
            count <= 0;
            state <= ACT;
          end if;
          count <= count + 1;

        when FIN => -- wait to output speed change (align with SR output)
          if not count = 0 then -- terminal count
            spd <= i_spd;
            stb <= '1';
            if i_crs_dv = '0' then -- end of frame
              i_spd <= 'X';
              count <= 0;
              state <= IDLE;
            else
              count <= 0;
              state <= ACT;
            end if;
          else
            count <= count + 1;
          end if;

        when ACT => -- wait until end of frame
          if i_crs_dv = '0' then
            i_spd <= 'X';
            count <= 0;
            state <= IDLE;
          end if;

      end case;

      --------------------------------------------------------------------------------
      -- shift register delays RMII to align with speed change

      sr(sr'left).crs_dv <= i_crs_dv;
      sr(sr'left).er     <= i_er;
      sr(sr'left).d      <= i_d;
      sr(sr'left + 1 to sr'right) <= sr(sr'left to sr'right - 1);

      --------------------------------------------------------------------------------
      -- output RMII is 1 cycle later than speed change
      -- to allow for 1 cycle latency of clken generation

      o_crs_dv <= sr(sr'right).crs_dv;
      o_er     <= sr(sr'right).er;
      o_d      <= sr(sr'right).d;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

end architecture rtl;
