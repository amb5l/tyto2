--------------------------------------------------------------------------------
-- model_hram_ctrl.vhd                                                        --
-- Simulation model of a HyperRAM controller.                                 --
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
-- main package declaration

library ieee;
  use ieee.std_logic_1164.all;

package model_hram_ctrl_pkg is

  -- controller parameter bundle type
  -- integers correspond to clock cycles
  type hram_ctrl_params_t is record
    tRP      : positive;  -- reset pulse width
    tRPH     : positive;  -- reset assertion to chip select assertion
    tCSHI    : positive;  -- chip select high
    tRWR     : positive;  -- read-write recovery
    tLAT     : positive;  -- latency
    tCSH     : natural;   -- chip select hold (half clk period is added)
    tCSM     : positive;  -- chip select, max
  end record hram_ctrl_params_t;

  -- 133MHz HyperRAM, 100MHz clock
  constant HRAM_CTRL_PARAMS_133_100 : hram_ctrl_params_t := (
    tRP      => 20,    -- 200 ns
    tRPH     => 40,    -- 400 ns
    tCSHI    => 1,     -- 10 ns
    tRWR     => 4,     -- 40 ns
    tLAT     => 4,     -- 40 ns
    tCSH     => 0,     -- 5 ns (min is 1/2 clock period)
    tCSM     => 400    -- 4 us
  );

  component model_hram_ctrl is
    generic (
      A_MSB    : integer range 19 to 29;
      B_MSB    : integer range 0 to 19;
      CLK_FREE : boolean;
      W_DEPTH  : positive;
      R_DEPTH  : positive;
      PARAMS   : hram_ctrl_params_t
    );
    port (
      s_rst     : in    std_ulogic;
      s_clk     : in    std_ulogic;
      s_a_ready : out   std_ulogic;
      s_a_valid : in    std_ulogic;
      s_a_r_w   : in    std_ulogic;
      s_a_reg   : in    std_ulogic;
      s_a_wrap  : in    std_ulogic;
      s_a_size  : in    std_ulogic_vector(B_MSB downto 0);
      s_a_addr  : in    std_ulogic_vector(A_MSB downto 1);
      s_w_ready : out   std_ulogic;
      s_w_valid : in    std_ulogic;
      s_w_be    : in    std_ulogic_vector(1 downto 0);
      s_w_data  : in    std_ulogic_vector(15 downto 0);
      s_r_ready : in    std_ulogic;
      s_r_valid : out   std_ulogic;
      s_r_data  : out   std_ulogic_vector(15 downto 0);
      h_rst_n   : out   std_logic;
      h_cs_n    : out   std_logic;
      h_clk     : out   std_logic;
      h_rwds    : inout std_logic;
      h_dq      : inout std_logic_vector(7 downto 0)
    );
  end component model_hram_ctrl;

end package model_hram_ctrl_pkg;

--------------------------------------------------------------------------------
-- FIFO types and constants

library ieee;
  use ieee.std_logic_1164.all;

package model_hram_ctrl_types_pkg is

  type w_item_t is record
    be   : std_ulogic_vector(1 downto 0);
    data : std_ulogic_vector(15 downto 0);
  end record w_item_t;

  constant W_FIFO_EMPTY : w_item_t := (
    be   => "XX",
    data => "XXXXXXXXXXXXXXXX"
  );

  subtype r_item_t is std_ulogic_vector(15 downto 0);

  constant R_FIFO_EMPTY : r_item_t := "XXXXXXXXXXXXXXXX";

end package model_hram_ctrl_types_pkg;

--------------------------------------------------------------------------------
-- FIFO package instances

use work.model_hram_ctrl_types_pkg.all;
package w_fifo_pkg is
  new work.tyto_fifo_pkg generic map(
    item_t => w_item_t,
    EMPTY  => W_FIFO_EMPTY,
    NAME   => "write FIFO"
  );

use work.model_hram_ctrl_types_pkg.all;
package r_fifo_pkg is
  new work.tyto_fifo_pkg generic map(
    item_t => r_item_t,
    EMPTY  => R_FIFO_EMPTY,
    NAME   => "read FIFO"
  );

--------------------------------------------------------------------------------
-- entity/architecture

use work.model_hram_ctrl_pkg.all;
use work.model_hram_ctrl_types_pkg.all;
use work.w_fifo_pkg.all;
use work.r_fifo_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity model_hram_ctrl is
  generic (
    A_MSB    : integer range 19 to 29; -- address MSB (22 => 8Mx8)
    B_MSB    : integer range 0 to 19;  -- burst size MSB (19 => 1Mx16)
    CLK_FREE : boolean;                -- free running clock
    W_DEPTH  : positive;               -- write FIFO depth
    R_DEPTH  : positive;               -- read FIFO depth
    PARAMS   : hram_ctrl_params_t
  );
  port (

    --------------------------------------------------------------------------------
    -- system interface

    -- reset and clock
    s_rst     : in    std_ulogic;                        -- reset (asynchronous)
    s_clk     : in    std_ulogic;                        -- clock

    -- A (address) channel
    s_a_ready : out   std_ulogic;
    s_a_valid : in    std_ulogic;                        -- strobe
    s_a_r_w   : in    std_ulogic;                        -- 1 = read, 0 = write
    s_a_reg   : in    std_ulogic;                        -- space: 0 = memory, 1 = register
    s_a_wrap  : in    std_ulogic;                        -- burst: 0 = linear, 1 = wrapped/hybrid
    s_a_size  : in    std_ulogic_vector(B_MSB downto 0); -- burst size
    s_a_addr  : in    std_ulogic_vector(A_MSB downto 1); -- address

    -- W (write data) channel
    s_w_ready : out   std_ulogic;                        -- ready
    s_w_valid : in    std_ulogic;                        -- valid
    s_w_be    : in    std_ulogic_vector(1 downto 0);     -- byte enable
    s_w_data  : in    std_ulogic_vector(15 downto 0);    -- data

    -- R (read data) channel
    s_r_ready : in    std_ulogic;                        -- ready
    s_r_valid : out   std_ulogic;                        -- valid
    s_r_data  : out   std_ulogic_vector(15 downto 0);    -- data

    --------------------------------------------------------------------------------
    -- HyperRAM interface

    h_rst_n   : out   std_logic;                         -- reset
    h_cs_n    : out   std_logic;                         -- chip select
    h_clk     : out   std_logic;                         -- clock
    h_rwds    : inout std_logic;                         -- read/write data strobe
    h_dq      : inout std_logic_vector(7 downto 0)       -- data bus

    --------------------------------------------------------------------------------

  );
end entity model_hram_ctrl;

architecture model of model_hram_ctrl is

  --------------------------------------------------------------------------------

  function res01x(x : std_ulogic) return std_ulogic is
  begin
    if    x = 'H' or x = '1' then return '1';
    elsif x = 'L' or x = '0' then return '0';
    else  return 'X';
    end if;
  end function res01x;

  function res01x(x : std_ulogic_vector) return std_ulogic_vector is
    variable r : std_ulogic_vector(x'range);
  begin
    for i in x'range loop
      r(i) := res01x(x(i));
    end loop;
    return r;
  end function res01x;

  function contains_x(x : std_ulogic_vector) return boolean is
  begin
    for i in x'range loop
      if x(i) = 'X' then return true; end if;
    end loop;
    return false;
  end function contains_x;

  --------------------------------------------------------------------------------
  -- break parameter bundle out to discrete signals (better for linting)

  constant tRP      : positive := PARAMS.tRP      ;
  constant tRPH     : positive := PARAMS.tRPH     ;
  constant tCSHI    : positive := PARAMS.tCSHI    ;
  constant tRWR     : positive := PARAMS.tRWR     ;
  constant tLAT     : positive := PARAMS.tLAT     ;
  constant tCSH     : natural  := PARAMS.tCSH     ;
  constant tCSM     : positive := PARAMS.tCSM     ;

  --------------------------------------------------------------------------------

  type state_t is (
    RESET,  -- reset
    IDLE,   -- idle/ready
    CS,     -- assert chip select
    CA1,    -- command/address, part 1
    CA2,    -- command/address, part 2
    CA3,    -- command/address, part 3
    ALAT,   -- additional latency
    LAT,    -- latency
    STALL,  -- stall for data
    WR,     -- write beat
    RD,     -- read beat
    CSH,    -- wait before chip select high (to allow final RWDS/DQ activity)
    RWR,    -- read-write recovery
    UNKNOWN -- unknown/crazy
  );

  signal qclk     : time := 0 ps;                      -- quarter clock period
  signal state    : state_t := UNKNOWN;                -- state machine state
  signal count    : integer;                           -- general purpose counter
  signal ca       : std_ulogic_vector(47 downto 0);    -- command/address latch
  signal bsize    : std_ulogic_vector(B_MSB downto 0); -- burst size latch
  signal bcount   : integer;                           -- burst counter
  signal alat_req : std_ulogic;                        -- additional latency required (RWDS high during CA phase)
  signal pause    : std_ulogic;                        -- indicates pause (b/c FIFO empty)

  -- internal versions of bidirectional external signals
  signal h_rwds_i  : std_ulogic;
  signal h_rwds_o  : std_ulogic;
  signal h_rwds_oe : std_ulogic;
  signal h_dq_i    : std_ulogic_vector(7 downto 0);
  signal h_dq_o    : std_ulogic_vector(7 downto 0);
  signal h_dq_oe   : std_ulogic;

  --------------------------------------------------------------------------------

  shared variable w_fifo : work.w_fifo_pkg.fifo_t;
  shared variable r_fifo : work.r_fifo_pkg.fifo_t;

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- one-off actions and checks

  -- TODO uncomment
  P_ONE_OFF: process
  begin
    --assert tLAT >= 3 and tLAT <= 8
    --  report "tLAT = " & integer'image(params.tLAT) & "; must be in the range 3 to 8" severity failure;
    wait;
  end process P_ONE_OFF;

  --------------------------------------------------------------------------------
  -- measure quarter clock period for phase shifted h_clk

  P_QCLK: process(s_clk)
    variable t : time := 0 ps;
  begin
    if rising_edge(s_clk) then
      qclk <= (now - t) / 4;
      t := now;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- bidirectional signals

  h_rwds_i  <= res01x(h_rwds);
  h_rwds    <= 'X' when res01x(h_rwds_oe) = 'X' else h_rwds_o when res01x(h_rwds_oe) = '1' else 'Z';
  h_dq_i    <= res01x(h_dq);
  h_dq      <= (others => 'X') when res01x(h_dq_oe) = 'X' else h_dq_o when res01x(h_dq_oe) = '1' else (others => 'Z');

  --------------------------------------------------------------------------------
  -- controller

  P_MAIN: process(s_rst, s_clk)

    --------------------------------------------------------------------------------
    -- encapsulate most of the controller logic in a procedure
    --  because 'return' can be used to skip unnecessary stages

    procedure proc_ctrl is

      variable v_pause : std_ulogic;

      function incr(x : std_ulogic_vector) return std_ulogic_vector is
      begin
        return std_ulogic_vector(unsigned(x)+1);
      end function incr;

    begin

      --------------------------------------------------------------------------------
      -- unknown reset or clock => unknown outputs

      if res01x(s_rst) = 'X' or res01x(s_clk) = 'X' then
        s_a_ready <= 'X';
        s_w_ready <= 'X';
        s_r_valid <= 'X';
        s_r_data  <= (others => 'X');
        h_rst_n   <= 'X';
        h_cs_n    <= 'X';
        h_rwds_o  <= 'X';
        h_rwds_oe <= 'X';
        h_dq_o    <= (others => 'X');
        h_dq_oe   <= 'X';
        state     <= UNKNOWN;
        count     <= 0;
        ca        <= (others => 'X');
        bsize     <= (others => 'X');
        bcount    <= 0;
        alat_req  <= 'X';
        pause     <= 'X';
        w_fifo.reset(W_DEPTH);
        r_fifo.reset(R_DEPTH);
        return;
      end if;

      --------------------------------------------------------------------------------
      -- reset

      if res01x(s_rst) = '1' then
        s_a_ready <= '0';
        s_w_ready <= '0';
        s_r_valid <= '0';
        s_r_data  <= (others => 'X');
        h_rst_n   <= '0';
        h_cs_n    <= '1';
        h_rwds_o  <= 'X';
        h_rwds_oe <= '0';
        h_dq_o    <= (others => 'Z');
        h_dq_oe   <= '0';
        state     <= RESET;
        count     <= 0;
        ca        <= (others => 'X');
        bsize     <= (others => 'X');
        bcount    <= 0;
        alat_req  <= '0';
        pause     <= '0';
        w_fifo.reset(W_DEPTH);
        r_fifo.reset(R_DEPTH);
        return;
      end if;

      --------------------------------------------------------------------------------
      -- rising edge

      if rising_edge(s_clk) then

        -- check for crazy inputs
        assert res01x(s_a_valid) /= 'X'
          report "s_a_valid = 'X'" severity failure;
        assert res01x(s_w_valid) /= 'X'
          report "s_w_valid = 'X'" severity failure;
        assert res01x(s_r_ready) /= 'X'
          report "s_r_ready = 'X'" severity failure;
        if res01x(s_a_valid) then
          assert res01x(s_a_r_w) /= 'X'
            report "s_a_r_w = 'X'" severity failure;
          assert res01x(s_a_reg) /= 'X'
            report "s_a_reg = 'X'" severity failure;
          assert res01x(s_a_wrap) /= 'X'
            report "s_a_wrap = 'X'" severity failure;
          assert not contains_x(s_a_size)
            report "s_a_size contains 'X'" severity failure;
          assert not contains_x(s_a_addr)
            report "s_a_addr contains 'X'" severity failure;
        end if;
        if res01x(s_w_valid) then
          assert not contains_x(s_w_be)
            report "s_w_be contains 'X'" severity failure;
          assert not contains_x(s_w_data)
            report "s_w_data contains 'X'" severity failure;
        end if;

        -- write FIFO - load
        if s_w_valid and s_w_ready then
          w_fifo.load((be => s_w_be, data => s_w_data));
        end if;

        -- read FIFO - unload
        s_r_valid <= '1' when r_fifo.level > 0  else '0';
        if s_r_valid and s_r_ready then
          r_fifo.unload;
        end if;
        s_r_data <= r_fifo.q;

        -- state machine
        case state is

          when RESET =>
            count <= count + 1;
            if count = tRP-1 then
              h_rst_n <= '1';
            end if;
            if count = tRPH-1 then
              s_a_ready <= '1';
              s_w_ready <= '1';
              count     <= 0;
              state     <= IDLE;
            end if;

          when IDLE =>
            if pause = '1' then                                           -- resume from pause
              if (ca(47) = '0' and w_fifo.level >= 1)
              or (ca(47) = '1' and r_fifo.level < R_DEPTH-1)
              then
                h_cs_n <= '0';
                pause  <= '0';
                state  <= CS;
              end if;
            elsif s_a_valid and s_a_ready then                            -- accept new cycle
              ca(47) <= res01x(s_a_r_w);
              ca(46) <= res01x(s_a_reg);
              ca(45) <= not res01x(s_a_wrap);
              ca(44 downto A_MSB+13) <= (others => '0');
              ca(A_MSB+12 downto 16) <= res01x(s_a_addr(A_MSB downto 4));
              ca(15 downto 3) <= (others => '0');
              ca(2 downto 0) <= res01x(s_a_addr(3 downto 1));
              bsize     <= res01x(s_a_size);
              bcount    <= 0;
              s_a_ready <= '0';
              h_cs_n    <= '0';
              state     <= CS;
            end if;

          when CS =>
            null;

          when CA1 =>
            h_dq_o <= ca(39 downto 32);

          when CA2 =>
            h_dq_o <= ca(23 downto 16);

          when CA3 =>
            h_dq_o <= ca(7 downto 0);

          when ALAT =>
            null;

          when LAT =>
            null;

          when STALL =>
            null;

          when WR =>
            h_rwds_o <= not w_fifo.q.be(0);
            h_dq_o   <= w_fifo.q.data(7 downto 0);
            w_fifo.unload;

          when RD =>
            null;

          when CSH =>
            null;

          when RWR =>
            if count >= tRWR-4 then
              s_a_ready <= not pause;
              state     <= IDLE;
            else
              count <= count + 1;
            end if;

          when UNKNOWN =>
            null;

        end case;

      end if;

      --------------------------------------------------------------------------------
      -- falling edge

      if falling_edge(s_clk) then
        case state is

          when RESET =>
            null;

          when IDLE =>
            null;

          when CS =>
            h_dq_o  <= ca(47 downto 40);
            h_dq_oe <= '1';
            state   <= CA1;

          when CA1 =>
            h_dq_o <= ca(31 downto 24);
            state  <= CA2;

          when CA2 =>
            h_dq_o   <= ca(15 downto 8);
            alat_req <= h_rwds_i and not ca(46); -- no additional latency for registers
            state    <= CA3;

          when CA3 =>
            h_dq_o  <= (others => 'X');
            h_dq_oe <= not ca(47);
            if ca(47 downto 46) = "01" then
              h_rwds_o <= not w_fifo.q.be(1);
              h_dq_o   <= w_fifo.q.data(15 downto 8);
              count    <= 0;
              state    <= WR;
            elsif alat_req then
              count <= 1;
              state <= ALAT;
            else
              count <= 1;
              state <= LAT;
            end if;

          when ALAT =>
            if count >= tLAT-1 then
              count <= 0;
              state <= LAT;
            else
              count <= count + 1;
            end if;

          when LAT =>
            if count >= tLAT-1 then
              count <= 0;
              if ca(47) = '0' then
                if w_fifo.level > 0 then
                  h_rwds_o  <= not w_fifo.q.be(1);
                  h_rwds_oe <= '1';
                  h_dq_o    <= w_fifo.q.data(15 downto 8);
                  h_dq_oe   <= '1';
                  state     <= WR;
                else
                  state <= STALL;
                end if;
              else
                if r_fifo.level < R_DEPTH then
                  state <= RD;
                else
                  state <= STALL;
                end if;
              end if;
            else
              count <= count + 1;
            end if;

          when STALL => -- address was ready but data wasn't...
            count <= 0;
            if ca(47) = '0' then
              if w_fifo.level > 0 then
                h_rwds_o  <= not w_fifo.q.be(1);
                h_rwds_oe <= '1';
                h_dq_o    <= w_fifo.q.data(15 downto 8);
                h_dq_oe   <= '1';
                state     <= WR;
              end if;
            else
              if r_fifo.level < R_DEPTH then
                state <= RD;
              end if;
            end if;

          when WR =>
            v_pause := '0';
            if (bcount /= unsigned(bsize)-1) and (w_fifo.level = 1 or count = tCSM-1) then
              v_pause := '1';
            end if;
            if bcount = unsigned(bsize)-1
            or w_fifo.level = 1
            or count = tCSM-1
            then
              h_rwds_o  <= 'X';
              h_rwds_oe <= '0';
              h_dq_o    <= (others => 'X');
              h_dq_oe   <= '0';
              count     <= 0;
              pause     <= v_pause;
              state     <= CSH;
            else
              h_rwds_o <= not w_fifo.q.be(1);
              h_dq_o   <= w_fifo.q.data(15 downto 8);
            end if;
            (ca(44 downto 16),ca(2 downto 0)) <= incr((ca(44 downto 16),ca(2 downto 0)));

          when RD =>
            v_pause := '0';
            if (bcount /= unsigned(bsize)-1) and (w_fifo.level = 1 or count = tCSM-1) then
              v_pause := '1';
            end if;
            if bcount = unsigned(bsize)-1
            or r_fifo.level = r_depth-1
            or count = tCSM-1
            then
              count <= 0;
              pause <= v_pause;
              state <= CSH;
            end if;
            (ca(44 downto 16),ca(2 downto 0)) <= incr((ca(44 downto 16),ca(2 downto 0)));
            bcount <= bcount + 1;

          when CSH =>
            if count >= tCSH then
              h_cs_n <= '1';
              count <= 0;
              if tRWR >= 4 then
                state <= RWR;
              else
                s_a_ready <= not pause;
                state     <= IDLE;
              end if;
            else
              count <= count + 1;
            end if;

          when RWR =>
            null;

          when UNKNOWN =>
            null;

        end case;
      end if;

      --------------------------------------------------------------------------------

    end procedure proc_ctrl;

    --------------------------------------------------------------------------------

  begin

    proc_ctrl;

  end process;

  --------------------------------------------------------------------------------
  -- clock output

  P_CLK: process
  begin
    h_clk <= '0';
    loop
      wait until falling_edge(s_clk);
      wait for qclk;
      if CLK_FREE or (res01x(h_cs_n) = '0' and state /= CS and state /= CSH) then
        h_clk <= '1';
      end if;
      wait until rising_edge(s_clk);
      wait for qclk;
      h_clk <= '0';
    end loop;
  end process P_CLK;

  --------------------------------------------------------------------------------
  -- read data capture

  P_READ: process
    variable r_data : r_item_t;
  begin
    wait until rising_edge(h_rwds_i) and state = RD;
    wait for qclk;
    r_data(15 downto 8) := h_dq_i;
    wait until falling_edge(h_rwds_i);
    r_data(7 downto 0) := h_dq_i;
    wait for 0 ps;
    r_fifo.load(r_data);
  end process P_READ;

  --------------------------------------------------------------------------------

end architecture model;
