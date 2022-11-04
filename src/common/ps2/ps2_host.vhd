--------------------------------------------------------------------------------
-- ps2_host.vhd                                                               --
-- PS/2 host interface.                                                       --
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

package ps2_host_pkg is

  component ps2_host is
    generic (
      fclk       : real
    );
    port (
      clk        : in    std_logic;
      rst        : in    std_logic;
      ps2_clk_i  : in    std_logic;
      ps2_clk_o  : out   std_logic;
      ps2_data_i : in    std_logic;
      ps2_data_o : out   std_logic;
      d2h_stb    : out   std_logic;
      d2h_data   : out   std_logic_vector(7 downto 0);
      h2d_req    : in    std_logic;
      h2d_ack    : out   std_logic;
      h2d_nack   : out   std_logic;
      h2d_data   : in    std_logic_vector(7 downto 0)
    );
  end component ps2_host;

end package ps2_host_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;

entity ps2_host is
  generic (
    fclk       : real                                -- clk frequency in MHz (>= 1.0)
  );
  port (
    clk        : in    std_logic;                    -- clock
    rst        : in    std_logic;                    -- reset
    ps2_clk_i  : in    std_logic;                    -- PS/2 serial clock in
    ps2_clk_o  : out   std_logic;                    -- PS/2 serial clock out
    ps2_data_i : in    std_logic;                    -- PS/2 serial data in
    ps2_data_o : out   std_logic;                    -- PS/2 serial data out
    d2h_stb    : out   std_logic;                    -- strobe } device to host
    d2h_data   : out   std_logic_vector(7 downto 0); -- data   }
    h2d_req    : in    std_logic;                    -- request        } host to device
    h2d_ack    : out   std_logic;                    -- acknowledge    }
    h2d_nack   : out   std_logic;                    -- no acknowledge }
    h2d_data   : in    std_logic_vector(7 downto 0)  -- data           }
  );
end entity ps2_host;

architecture synth of ps2_host is

  constant count_100us : integer := integer(ceil(100.0*fclk));
  constant count_25us  : integer := integer(ceil(25.0*fclk));

  signal   timer       : integer range 0 to count_100us-1;

  signal   ps2_ack     : std_logic;                    -- latest ack state

  -- device to host
  signal   d2h_sr      : std_logic_vector(9 downto 0); -- shift reg
  signal   d2h_count   : integer range 0 to 10;        -- clock count
  signal   d2h_lock    : boolean;                      -- lock (no parity/framing error)
  signal   d2h_req     : std_logic;                    -- request        } transfer
  signal   d2h_req_s   : std_logic_vector(0 to 2);     -- sync'd request }  parallel data
  signal   d2h_ack     : std_logic;                    -- ack            }   to host
  signal   d2h_par     : std_logic;                    -- parity

  -- host to device
  signal   h2d_act     : std_logic;                    -- active
  signal   h2d_start   : std_logic;                    -- start (100us after falling clock to start of bit 0)
  signal   h2d_doe     : std_logic;                    -- data output enable (bits 0-7,parity)
  signal   h2d_sr      : std_logic_vector(8 downto 0); -- shift reg
  signal   h2d_count   : integer range 0 to 12;        -- clock count
  signal   h2d_done    : std_logic;                    -- done
  signal   h2d_done_s  : std_logic_vector(0 to 2);     -- sync'd done
  signal   h2d_par     : std_logic;                    -- parity

  type     h2d_state_t is (s0, s1, s2, s3, s4);

  signal   h2d_state   : h2d_state_t;

begin

  --------------------------------------------------------------------------------
  -- device to host

  D2H_D: process (rst, h2d_act, d2h_ack, ps2_clk_i) is
  begin
    if rising_edge(ps2_clk_i) and h2d_act = '0' then
      d2h_sr(9 downto 0) <= ps2_data_i & d2h_sr(9 downto 1);
      if d2h_lock then
        d2h_count <= (d2h_count+1) mod 11;
      end if;
      if (d2h_lock and d2h_count = 9) or not d2h_lock then
      end if;
      if (d2h_lock and d2h_count = 10) or not d2h_lock then
        if d2h_sr(0) = '0' and d2h_sr(9) = d2h_par and ps2_data_i = '1' then
          d2h_lock <= true;
          d2h_req  <= '1';
        else
          d2h_lock <= false;
        end if;
      end if;
    end if;
    -- async resets
    if rst = '1' or h2d_act = '1' then
      d2h_sr    <= (others => '0');
      d2h_count <= 0;
      d2h_lock  <= true;
    end if;
    if rst = '1' or d2h_ack = '1' then
      d2h_req <= '0';
    end if;
  end process D2H_D;

  D2H_H: process (clk) is
  begin
    if rising_edge(clk) then
      d2h_stb <= '0';
      if rst = '1' then
        d2h_req_s <= (others => '0');
        d2h_ack   <= '0';
        d2h_data  <= (others => '0');
      else
        d2h_req_s(0 to 2) <= d2h_req & d2h_req_s(0 to 1);
        d2h_ack           <= d2h_req_s(2);
        if  d2h_req_s(1) = '1' and d2h_req_s(2) = '0' then
          d2h_data <= d2h_sr(7 downto 0);
          d2h_stb  <= '1';
        end if;
      end if;
    end if;
  end process D2H_H;

  d2h_par <= not (
                  d2h_sr(1) xor d2h_sr(2) xor d2h_sr(3) xor d2h_sr(4) xor
                  d2h_sr(5) xor d2h_sr(6) xor d2h_sr(7) xor d2h_sr(8)
                );

  --------------------------------------------------------------------------------
  -- host to device

  H2D_D: process (rst, h2d_done, h2d_act, ps2_clk_i) is
  begin
    if falling_edge(ps2_clk_i) then
      if h2d_act = '1' then
        h2d_count <= (h2d_count + 1) mod 12;
        if h2d_count = 0 then
          h2d_doe <= '1';
        elsif h2d_count = 9 then
          h2d_doe <= '0';
        end if;
        if h2d_start = '1' then
          h2d_sr <= h2d_par & h2d_data;
        else
          h2d_sr(8 downto 0) <= '0' & h2d_sr(8 downto 1);
        end if;
      end if;
    end if;
    if rising_edge(ps2_clk_i) then
      if h2d_count = 11 then -- sample ack
        h2d_done <= '1';
        ps2_ack  <= not ps2_data_i;
      end if;
    end if;
    -- async resets
    if rst = '1' then
      h2d_doe <= '0';
      h2d_sr  <= (others => '0');
    end if;
    if rst = '1' or h2d_done = '1' then
      h2d_count <= 0;
    end if;
    if rst = '1' or h2d_act = '0' then
      h2d_done <= '0';
      ps2_ack  <= '0';
    end if;
  end process H2D_D;

  H2D_H: process (rst, h2d_doe, clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        timer      <= 0;
        h2d_done_s <= (others => '0');
        h2d_state  <= S0;
        h2d_act    <= '0';
        ps2_clk_o  <= '1';
        h2d_ack    <= '0';
        h2d_nack   <= '0';
      else
        h2d_done_s(0 to 2) <= h2d_done & h2d_done_s(0 to 1);
        case h2d_state is

          when S0 =>                                            -- wait for request

            if h2d_req = '1' then
              h2d_state <= S1;
              timer     <= 0;
              ps2_clk_o <= '0';                                 -- pull clock down
            end if;

          when S1 =>

            if timer=count_100us-1 then                         -- wait for 100us (spec)
              h2d_state <= S2;
              timer     <= 0;
              h2d_act   <= '1';                                 -- assert h2d_act (hold off d2h)
              h2d_start <= '1';                                 -- pull data down (start bit) and enable shift reg load
            else
              timer <= timer+1;
            end if;

          when S2 =>

            timer <= timer+1;
            if timer=count_25us-1 then                          -- wait for 25us (spec)
              h2d_state <= S3;
              timer     <= 0;
              ps2_clk_o <= '1';                                 -- release clock, ready to receive
            end if;

          when S3 =>                                            -- wait until done, then assert ack or nack

            if h2d_done_s(1) = '1' and h2d_done_s(2) = '0' then
              h2d_state <= S4;
              h2d_act   <= '0';
              h2d_ack   <= ps2_ack;
              h2d_nack  <= not ps2_ack;
            end if;

          when S4 =>                                            -- wait until request has negated

            if h2d_req = '0' then
              h2d_state <= S0;
              h2d_ack   <= '0';
              h2d_nack  <= '0';
            end if;

          when others =>

            h2d_state <= S0;

        end case;
      end if;
      -- async resets
      if rst = '1' or h2d_doe = '1' then
        h2d_start <= '0';
      end if;
    end if;
  end process H2D_H;

  h2d_par <= not (
                  h2d_data(0) xor h2d_data(1) xor h2d_data(2) xor h2d_data(3) xor
                  h2d_data(4) xor h2d_data(5) xor h2d_data(6) xor h2d_data(7)
                );

  ps2_data_o <= '0' when h2d_start = '1' or (h2d_doe = '1' and h2d_sr(0) = '0') else '1';

--------------------------------------------------------------------------------

end architecture synth;
