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
    clk_free : boolean;  -- free running clock
    w_depth  : positive; -- write FIFO depth
    r_depth  : positive; -- read FIFO depth
    tRP      : positive;  -- reset pulse width
    tRPH     : positive;  -- reset assertion to chip select assertion
    tCSHI    : positive;  -- chip select high
    tRWR     : positive;  -- read-write recovery
    tLAT     : positive;  -- latency
    tCSH     : natural;   -- chip select high (read cycles)
    tCSM     : positive;  -- chip select, max
  end record hram_ctrl_params_t;

  -- 133MHz HyperRAM, 100MHz clock
  constant HRAM_CTRL_PARAMS_133_100 : hram_ctrl_params_t := (
    clk_free => false,
    w_depth  => 64,
    r_depth  => 64,
    tRP      => 20,    -- 200 ns
    tRPH     => 40,    -- 400 ns
    tCSHI    => 1,     -- 10 ns
    tRWR     => 4,     -- 40 ns
    tLAT     => 4,     -- 40 ns
    tCSH     => 1,     -- 10 ns
    tCSM     => 400    -- 4 us
  );

  component model_hram_ctrl is
    generic (
      A_MSB  : integer range 19 to 29;
      B_MSB  : integer range 0 to 19;
      PARAMS : hram_ctrl_params_t
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
      h_rst_n   : out   std_ulogic;
      h_clk     : out   std_ulogic;
      h_cs_n    : out   std_ulogic;
      h_rwds    : out   std_ulogic;
      h_dq      : inout std_ulogic_vector(7 downto 0)
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
    be   => (others => 'X'),
    data => (others => 'X')
  );

  subtype r_item_t is std_ulogic_vector(15 downto 0);

  constant R_FIFO_EMPTY : r_item_t := (others => 'X');

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
    A_MSB  : integer range 19 to 29; -- address MSB (22 => 8Mx8)
    B_MSB  : integer range 0 to 19;  -- burst size MSB (19 => 1Mx16)
    PARAMS : hram_ctrl_params_t
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

    h_rst_n   : out   std_ulogic;                        -- reset
    h_clk     : out   std_ulogic;                        -- clock
    h_cs_n    : out   std_ulogic;                        -- chip select
    h_rwds    : out   std_ulogic;                        -- read/write data strobe
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

  constant clk_free : boolean  := PARAMS.clk_free ;
  constant w_depth  : positive := PARAMS.w_depth  ;
  constant r_depth  : positive := PARAMS.r_depth  ;
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
    LAT,    -- initial latency
    ALAT,   -- additional latency
    WR,     -- write beat
    RD,     -- read beat
    CSH,    -- wait before chip select high (to allow final RWDS/DQ activity)
    RWR,    -- read-write recovery
    UNKNOWN -- unknown/crazy
  );

  signal qclk     : time;                              -- quarter clock period
  signal state    : state_t := UNKNOWN;                -- state machine state
  signal count    : integer;                           -- general purpose counter
  signal ca       : std_ulogic_vector(47 downto 0);    -- command/address latch
  signal bsize    : std_ulogic_vector(B_MSB downto 0); -- burst size latch
  signal bcount   : integer;                           -- burst counter
  signal alat_req : std_ulogic;                        -- additional latency required (RWDS high during CA phase)
  signal pause    : std_ulogic;                        -- indicates pause (b/c FIFO empty)
  signal r_data   : r_item_t;                          -- read data latch

  --------------------------------------------------------------------------------

  shared variable w_fifo : work.w_fifo_pkg.fifo_t;
  shared variable r_fifo : work.r_fifo_pkg.fifo_t;

  --------------------------------------------------------------------------------

begin

  --------------------------------------------------------------------------------
  -- check parameters

  -- TODO uncomment
  P_PARAMS: process
  begin
    --assert tLAT >= 3 and tLAT <= 8
    --  report "tLAT = " & integer'image(params.tLAT) & "; must be in the range 3 to 8" severity failure;
    wait;
  end process P_PARAMS;

  --------------------------------------------------------------------------------
  -- measure quarter clock period for phase shifted h_clk

  P_QCLK: process(s_clk)
  begin
    if res01x(s_clk) /= 'X' then
      qclk <= (now - s_clk'last_event) / 4;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- controller

  P_MAIN: process(s_rst, s_clk)

    --------------------------------------------------------------------------------
    -- encapsulate most of the controller logic in a procedure
    --  because 'return' can be used to skip unnecessary stages

    procedure proc_ctrl is
      variable v_pause : std_ulogic;
      variable v_addr  : std_ulogic_vector(A_MSB downto 1);
    begin

      --------------------------------------------------------------------------------
      -- unknown reset or clock => unknown outputs

      if res01x(s_rst) = 'X' or res01x(s_clk) = 'X' then
        s_a_ready <= 'X';
        s_w_ready <= 'X';
        s_r_valid <= 'X';
        s_r_data  <= (others => 'X');
        h_rst_n   <= 'X';
        h_clk     <= 'X';
        h_cs_n    <= 'X';
        h_rwds    <= 'X';
        h_dq      <= (others => 'X');
        state     <= UNKNOWN;
        count     <= 0;
        ca        <= (others => 'X');
        bsize     <= (others => 'X');
        bcount    <= 0;
        alat_req  <= 'X';
        pause     <= 'X';
        w_fifo.reset(w_depth);
        r_fifo.reset(r_depth);
        return;
      end if;

      --------------------------------------------------------------------------------
      -- leading edge of reset

      if rising_edge(s_rst) then
        s_a_ready <= '0';
        s_w_ready <= '0';
        s_r_valid <= '0';
        s_r_data  <= (others => 'X');
        h_rst_n   <= '0';
        h_clk     <= '0';
        h_cs_n    <= '1';
        h_rwds    <= 'Z';
        h_dq      <= (others => 'Z');
        state     <= RESET;
        count     <= 0;
        ca        <= (others => 'X');
        bsize     <= (others => 'X');
        bcount    <= 0;
        alat_req  <= '0';
        pause     <= '0';
        w_fifo.reset(w_depth);
        r_fifo.reset(r_depth);
        return;
      end if;

      --------------------------------------------------------------------------------
      -- rising edge

      if rising_edge(s_clk) and s_rst = '0' then

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
        if s_r_valid and s_r_ready then
          r_fifo.unload;
        end if;
        s_r_data <= r_fifo.q;

        -- state machine
        case state is

          when RESET =>
            if count = tRP-1 then
              h_rst_n <= '1';
            elsif count = tRPH-1 then
              s_a_ready <= '1';
              s_w_ready <= '1';
              count     <= 0;
              state     <= IDLE;
            end if;

          when IDLE =>
            if pause = '1' then                                           -- resume from pause
              if (ca(47) = '0' and w_fifo.level >= 1)
              or (ca(47) = '1' and r_fifo.level < r_depth-1)
              then
                h_cs_n <= '0';
                pause  <= '0';
                state  <= CS;
              end if;
            elsif s_a_valid and s_a_ready then                            -- accept new cycle
              if (s_a_r_w = '1' and r_fifo.level < PARAMS.r_depth)        -- read, and there is room for data in FIFO
              or (s_a_r_w = '0' and w_fifo.level > 0)                     -- write, and there is data in FIFO
              or (s_a_r_w = '0' and s_w_valid = '1' and s_w_ready = '1')  -- write, and there will be data in FIFO
              then
                ca(47) <= s_a_r_w;
                ca(46) <= s_a_reg;
                ca(45) <= not s_a_wrap;
                ca(44 downto A_MSB+13) <= (others => '0');
                ca(A_MSB+12 downto 16) <= s_a_addr(A_MSB downto 4);
                ca(15 downto 3) <= (others => '0');
                ca(2 downto 0) <= s_a_addr(3 downto 1);
                bsize     <= s_a_size;
                bcount    <= 0;
                s_a_ready <= '0';
                h_cs_n    <= '0';
                state     <= CS;
              end if;
            end if;

          when CS =>
            h_dq   <= ca(47 downto 40);
            state  <= CA1;

          when CA1 =>
            h_dq   <= ca(31 downto 24);
            state <= CA2;

          when CA2 =>
            h_dq  <= ca(15 downto 8);
            state <= CA3;

          when CA3 =>
            alat_req <= h_rwds and not ca(46); -- no additional latency for registers
            h_dq  <= (others => 'X') when ca(47) = '0' else (others => 'Z');
            count <= 1;
            state <= LAT;

          when LAT =>
            if count >= tLAT-1 then
              count <= 0;
              if alat_req and not ca(46) then
                state <= ALAT;
              else
                if ca(47) = '0' then
                  h_rwds <= not w_fifo.q.be(1);
                  h_dq   <= w_fifo.q.data(15 downto 8);
                  state  <= WR;
                else
                  state <= RD;
                end if;
              end if;
            else
              count <= count + 1;
            end if;

          when ALAT =>
            if count >= tLAT-1 then
              count <= 0;
              if ca(47) = '0' then
                h_rwds <= not w_fifo.q.be(1);
                h_dq   <= w_fifo.q.data(15 downto 8);
                state  <= WR;
              else
                state <= RD;
              end if;
            else
              count <= count + 1;
            end if;

          when WR =>
            v_pause := '0';
            if w_fifo.level = 1 and bcount /= unsigned(bsize)-1 then
              v_pause := '1';
            end if;
            if bcount = unsigned(bsize)-1
            or w_fifo.level = 1
            then
              h_cs_n <= '1';
              h_rwds <= 'Z';
              h_dq   <= (others => 'Z');
              count  <= 0;
              pause <= v_pause;
              if tRWR >= 4 then
                state <= RWR;
              else
                s_a_ready <= not v_pause;
                state <= IDLE;
              end if;

            else
              h_rwds <= not w_fifo.q.be(1);
              h_dq   <= w_fifo.q.data(15 downto 8);
            end if;
            v_addr := ca(A_MSB+12 downto 16) & ca(2 downto 0);
            v_addr := std_ulogic_vector(unsigned(v_addr) + 1);
            ca(A_MSB+12 downto 16) <= v_addr(A_MSB downto 4);
            ca(2 downto 0) <= v_addr(3 downto 1);
            bcount <= bcount + 1;

          when RD =>
            v_pause := '0';
            if r_fifo.level = r_depth-1 and bcount /= unsigned(bsize)-1 then
              v_pause := '1';
            end if;
            if bcount = unsigned(bsize)-1
            or r_fifo.level = r_depth-1
            then
              count <= 0;
              pause <= v_pause;
              if tCSH > 0 then
                state <= CSH;
              else
                h_cs_n <= '1';
                if tRWR >= 4 then
                  state <= RWR;
                else
                  s_a_ready <= not v_pause;
                  state <= IDLE;
                end if;
              end if;
            end if;
            v_addr := ca(A_MSB+12 downto 16) & ca(2 downto 0);
            v_addr := std_ulogic_vector(unsigned(v_addr) + 1);
            ca(A_MSB+12 downto 16) <= v_addr(A_MSB downto 4);
            ca(2 downto 0) <= v_addr(3 downto 1);
            bcount <= bcount + 1;

          when CSH =>
            if count >= tCSHI-1 then
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
            if count >= tRWR-4 then
              s_a_ready <= not pause;
              state     <= IDLE;
            else
              count <= count + 1;
            end if;

          when UNKNOWN =>
            h_cs_n <= 'X';
            h_rwds <= 'X';
            h_dq  <= (others => 'X');

        end case;

      end if;

      --------------------------------------------------------------------------------

      if falling_edge(s_clk) then
        case state is
          when CA1 =>
            h_dq  <= ca(39 downto 32);
          when CA2 =>
            h_dq <= ca(23 downto 16);
          when CA3 =>
            h_dq <= ca(7 downto 0);
          when LAT | ALAT =>
            h_dq  <= (others => 'Z');
          when WR =>
            h_rwds <= not w_fifo.q.be(0);
            h_dq   <= w_fifo.q.data(7 downto 0);
            w_fifo.unload;
          when others =>
            h_dq  <= (others => 'X');
        end case;
      end if;

      --------------------------------------------------------------------------------

    end procedure proc_ctrl;

    --------------------------------------------------------------------------------

  begin

    proc_ctrl;
    if clk_free or res01x(h_cs_n) = '0' then
      h_clk <= s_clk after qclk;
    end if;

  end process;

  --------------------------------------------------------------------------------
  -- read data capture

  P_READ: process
  begin
    wait until rising_edge(h_rwds) and state = RD;
    wait for qclk;
    r_data(15 downto 8) <= res01x(h_dq);
    wait until falling_edge(h_rwds);
    r_data(7 downto 0) <= res01x(h_dq);
    wait for 0 ps;
    r_fifo.load(r_data);
  end process P_READ;

  --------------------------------------------------------------------------------

end architecture model;
