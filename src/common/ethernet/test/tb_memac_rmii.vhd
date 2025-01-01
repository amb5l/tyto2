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

use work.memac_sim_type_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity tb_memac_rmii is
  generic (
    LOOPS : integer := 10
  );
end entity tb_memac_rmii;

architecture sim of tb_memac_rmii is

  type mii4seq_t is array (positive range <>) of mii4_t;

  type

  type src_tr_t is record
    gap : boolean;
    nybble_
  end record src_tr_t;


  signal src_tr :

begin

  -- source random sequences of RMII traffic
  -- driving them through DUTs, and the comparison queue
  P_SRC: process
    variable src_seq_ptr : mii4_seq_ptr_t;
  begin
    src_seq_ptr = new mii4_seq_t(0 to MTU-1);
    for i in 0 to MTU-1 loop
      src_seq_ptr(i).crs <= '0';
      src_seq_ptr(i).dv  <= '0';
      src_seq_ptr(i).er  <= '0';
      src_seq_ptr(i).d   <= (others => '0');
    end loop;
    src_seq <= new mii4_seq_t(0 to MTU-1)

  end process P_MAIN;

  -- convert test sequences to RMII traffic
  RX_SRC: component model_rmii_tx
    port map (
      seq      =>
      rmii_clk => src_rmii_clk,
      rmii_dv => src_rmii_dv,
      rmii_d  => src_rmii_d,
    );

  RX_DUT: component memac_rmii_rx
    port map (
    );

  TX_DUT: component memac_rmii_tx
    port map (
    );

  -- destination:
  TX_DST: component model_rmii_rx
    port map (
    );

end architecture sim;
