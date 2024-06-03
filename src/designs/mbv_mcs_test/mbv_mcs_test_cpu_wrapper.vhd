--------------------------------------------------------------------------------
-- mbv_mcs_test_cpu_wrapper.vhd                                              --
-- CPU (block diagram) wrapper for the mbv_mcs_test design.                  --
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

library ieee;
  use ieee.std_logic_1164.all;

package mbv_mcs_test_cpu_wrapper_pkg is

  component mbv_mcs_test_cpu_wrapper is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      uart_tx  : out   std_ulogic;
      uart_rx  : in    std_ulogic
    );
  end component mbv_mcs_test_cpu_wrapper;

end package mbv_mcs_test_cpu_wrapper_pkg;

--------------------------------------------------------------------------------

use work.mbv_mcs_test_cpu_wrapper_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity mbv_mcs_test_cpu_wrapper is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    uart_tx  : out   std_ulogic;
    uart_rx  : in    std_ulogic
  );
end entity mbv_mcs_test_cpu_wrapper;

architecture rtl of mbv_mcs_test_cpu_wrapper is

  -- matches the block diagram created by "mbv_mcs_test_cpu.tcl"
  component mbv_mcs_test_cpu is
  port (
    rst_n           : in    std_ulogic;
    clk             : in    std_ulogic;
    uart_txd        : out   std_ulogic;
    uart_rxd        : in    std_ulogic
  );
  end component mbv_mcs_test_cpu;

begin

  CPU: component mbv_mcs_test_cpu
    port map (
      rst_n    => not rst,
      clk      => clk,
      uart_txd => uart_tx,
      uart_rxd => uart_rx
    );

end architecture rtl;
