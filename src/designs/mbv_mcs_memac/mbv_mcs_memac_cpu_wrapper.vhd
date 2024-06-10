--------------------------------------------------------------------------------
-- mbv_mcs_memac_cpu_wrapper.vhd                                              --
-- CPU (block diagram) wrapper for the mbv_mcs_memac design.                  --
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

use work.tyto_types_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package mbv_mcs_memac_cpu_wrapper_pkg is

  type mcs_io_mosi_t is record
    astb  : std_ulogic;
    addr  : std_ulogic_vector(31 downto 0);
    be    : std_ulogic_vector(3 downto 0);
    wstb  : std_ulogic;
    wdata : std_ulogic_vector(31 downto 0);
    rstb  : std_ulogic;
  end record mcs_io_mosi_t;

  type mcs_io_miso_t is record
    rdata : std_ulogic_vector(31 downto 0);
    rdy   : std_ulogic;
  end record mcs_io_miso_t;

  component mbv_mcs_memac_cpu_wrapper is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      uart_tx  : out   std_ulogic;
      uart_rx  : in    std_ulogic;
      gpi      : in    sulv_vector(1 to 4)(31 downto 0);
      gpo      : out   sulv_vector(1 to 4)(31 downto 0);
      io_mosi  : out   mcs_io_mosi_t;
      io_miso  : in    mcs_io_miso_t
    );
  end component mbv_mcs_memac_cpu_wrapper;

end package mbv_mcs_memac_cpu_wrapper_pkg;

--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.mbv_mcs_memac_cpu_wrapper_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity mbv_mcs_memac_cpu_wrapper is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    uart_tx  : out   std_ulogic;
    uart_rx  : in    std_ulogic;
    gpi      : in    sulv_vector(1 to 4)(31 downto 0);
    gpo      : out   sulv_vector(1 to 4)(31 downto 0);
    io_mosi  : out   mcs_io_mosi_t;
    io_miso  : in    mcs_io_miso_t
  );
end entity mbv_mcs_memac_cpu_wrapper;

architecture rtl of mbv_mcs_memac_cpu_wrapper is

  -- matches the block diagram created by "mbv_mcs_memac_cpu.tcl"
  component mbv_mcs_memac_cpu is
  port (
    rst_n           : in    std_ulogic;
    clk             : in    std_ulogic;
    uart_txd        : out   std_ulogic;
    uart_rxd        : in    std_ulogic;
    gpio1_tri_i     : in    std_ulogic_vector(31 downto 0);
    gpio2_tri_i     : in    std_ulogic_vector(31 downto 0);
    gpio3_tri_i     : in    std_ulogic_vector(31 downto 0);
    gpio4_tri_i     : in    std_ulogic_vector(31 downto 0);
    gpio1_tri_o     : out   std_ulogic_vector(31 downto 0);
    gpio2_tri_o     : out   std_ulogic_vector(31 downto 0);
    gpio3_tri_o     : out   std_ulogic_vector(31 downto 0);
    gpio4_tri_o     : out   std_ulogic_vector(31 downto 0);
    io_addr_strobe  : out   std_ulogic;
    io_address      : out   std_ulogic_vector(31 downto 0);
    io_byte_enable  : out   std_ulogic_vector(3 downto 0);
    io_write_strobe : out   std_ulogic;
    io_write_data   : out   std_ulogic_vector(31 downto 0);
    io_read_strobe  : out   std_ulogic;
    io_read_data    : in    std_ulogic_vector(31 downto 0);
    io_ready        : in    std_ulogic
  );
  end component mbv_mcs_memac_cpu;

begin

  CPU: component mbv_mcs_memac_cpu
    port map (
      rst_n           => not rst,
      clk             => clk,
      uart_txd        => uart_tx,
      uart_rxd        => uart_rx,
      gpio1_tri_i     => gpi(1),
      gpio2_tri_i     => gpi(2),
      gpio3_tri_i     => gpi(3),
      gpio4_tri_i     => gpi(4),
      gpio1_tri_o     => gpo(1),
      gpio2_tri_o     => gpo(2),
      gpio3_tri_o     => gpo(3),
      gpio4_tri_o     => gpo(4),
      io_addr_strobe  => io_mosi.astb,
      io_address      => io_mosi.addr,
      io_byte_enable  => io_mosi.be,
      io_write_strobe => io_mosi.wstb,
      io_write_data   => io_mosi.wdata,
      io_read_strobe  => io_mosi.rstb,
      io_read_data    => io_miso.rdata,
      io_ready        => io_miso.rdy
    );

end architecture rtl;
