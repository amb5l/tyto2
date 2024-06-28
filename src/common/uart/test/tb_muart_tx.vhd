--------------------------------------------------------------------------------
-- tb_muart_tx.vhd                                                            --
-- Testbench for muart_tx.                                                    --
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
-- generic package instance (data queue)

library ieee;
  use ieee.std_logic_1164.all;

package data_queue_pkg is
  new work.tyto_queue_pkg generic map(queue_item_t => integer range 0 to 255, EMPTY => 0);

--------------------------------------------------------------------------------
-- testbench

use work.tyto_sim_pkg.all;
use work.muart_tx_pkg.all;
use work.model_uart_rx_pkg.all;
use work.data_queue_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_muart_tx is
  generic (
    TEST_COUNT : integer
  );
end entity tb_muart_tx;

architecture sim of tb_muart_tx is

  constant fCLK    : integer := 100000000; -- 100 MHz
  constant tCLK    : time    := 1 sec / fCLK;
  constant BAUD    : integer := 115200;
  constant DIV     : integer := fCLK / BAUD;
  constant GAP_MAX : integer := 20*DIV;

  signal rst   : std_ulogic;
  signal clk   : std_ulogic;
  signal d     : std_ulogic_vector(7 downto 0);
  signal valid : std_ulogic;
  signal ready : std_ulogic;
  signal q     : std_ulogic;

  signal dr    : std_ulogic_vector(7 downto 0); -- received data

  shared variable dq : work.data_queue_pkg.queue_t;

  signal q_front : integer range 0 to 255; -- v4p ignore w-303
  signal q_items : integer; -- v4p ignore w-303

  signal debug : bit;

begin

  rst <= '1', '0' after tCLK;
  clk <= '0' when clk = 'U' else not clk after tCLK / 2;

  P_MAIN: process
    variable di : integer range 0 to 255;
  begin
    prng.rand_seed(123,456);
    d     <= (others => 'X');
    valid <= '0';
    for i in 0 to TEST_COUNT-1 loop
      wait for prng.rand_int(0, GAP_MAX-1) * tCLK;
      di := prng.rand_int(0,255);
      dq.enq(di); -- add data to queue
      d     <= std_ulogic_vector(to_unsigned(di,8));
      valid <= '1';
      loop
        wait until rising_edge(clk);
        exit when ready = '1';
      end loop;
      d     <= (others => 'X');
      valid <= '0';
    end loop;
    std.env.finish;
  end process P_MAIN;

  P_CHECK: process
  begin
    loop
      wait until dr'transaction'event;
      assert dr = std_ulogic_vector(to_unsigned(dq.front,8))
        report
          "mismatch: received " & to_string(dr) &
          " (" & integer'image(to_integer(unsigned(dr))) & ")" &
          " expected " & to_string(std_ulogic_vector(to_unsigned(dq.front,8))) &
          " (" & integer'image(dq.front) & ")"
        severity failure;
      dq.deq;
      debug <= not debug;
      wait for 0 ps;
    end loop;
  end process P_CHECK;

  P_WAVE: process(clk)
  begin
    if falling_edge(clk) then
      q_front <= dq.front;
      q_items <= dq.items;
    end if;
  end process P_WAVE;

  DUT: component muart_tx
    generic map (
      DIV => DIV
    )
    port map (
      rst   => rst,
      clk   => clk,
      d     => d,
      valid => valid,
      ready => ready,
      q     => q
    );

  VFY: component model_uart_rx
    generic map (
      BAUD => BAUD
    )
    port map (
      i => q,
      o => dr,
      e => open
    );

end architecture sim;
