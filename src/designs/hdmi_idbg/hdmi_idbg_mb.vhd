--------------------------------------------------------------------------------
-- hdmi_idbg_mb.vhd                                                           --
-- MicroBlaze CPU subsystem (block diagram) wrapper.                          --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
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

library work;
  use work.axi_pkg.all;

package hdmi_idbg_mb_pkg is

  component hdmi_idbg_mb is
    port (
      rsti     : in    std_logic;
      rsto     : out   std_logic;
      clk      : in    std_logic;
      uart_tx  : out   std_logic;
      uart_rx  : in    std_logic;
      axi_mosi : out   axi4_a32d32_mosi_t;
      axi_miso : in    axi4_a32d32_miso_t
    );
  end component hdmi_idbg_mb;

end package hdmi_idbg_mb_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_pkg.all;

entity hdmi_idbg_mb is
  port (
    rsti     : in    std_logic;
    rsto     : out   std_logic;
    clk      : in    std_logic;
    uart_tx  : out   std_logic;
    uart_rx  : in    std_logic;
    axi_mosi : out   axi4_a32d32_mosi_t;
    axi_miso : in    axi4_a32d32_miso_t
  );
end entity hdmi_idbg_mb;

architecture wrapper of hdmi_idbg_mb is

  component microblaze is
    port (
      clk         : in    std_logic;
      lock        : in    std_logic;
      rsti_n      : in    std_logic;
      rsto        : out   std_logic_vector(0 to 0);
      uart_txd    : out   std_logic;
      uart_rxd    : in    std_logic;
      axi_awaddr  : out   std_logic_vector(31 downto 0);
      axi_awprot  : out   std_logic_vector(2 downto 0);
      axi_awvalid : out   std_logic_vector(0 to 0);
      axi_awready : in    std_logic_vector(0 to 0);
      axi_wdata   : out   std_logic_vector(31 downto 0);
      axi_wstrb   : out   std_logic_vector(3 downto 0);
      axi_wvalid  : out   std_logic_vector(0 to 0);
      axi_wready  : in    std_logic_vector(0 to 0);
      axi_bresp   : in    std_logic_vector(1 downto 0);
      axi_bvalid  : in    std_logic_vector(0 to 0);
      axi_bready  : out   std_logic_vector(0 to 0);
      axi_araddr  : out   std_logic_vector(31 downto 0);
      axi_arprot  : out   std_logic_vector(2 downto 0);
      axi_arvalid : out   std_logic_vector(0 to 0);
      axi_arready : in    std_logic_vector(0 to 0);
      axi_rdata   : in    std_logic_vector(31 downto 0);
      axi_rresp   : in    std_logic_vector(1 downto 0);
      axi_rvalid  : in    std_logic_vector(0 to 0);
      axi_rready  : out   std_logic_vector(0 to 0)
    );
  end component microblaze;

begin

  BD: component microblaze
    port map (
      clk            => clk,
      lock           => not rsti,
      rsti_n         => not rsti,
      rsto(0)        => rsto,
      uart_txd       => uart_tx,
      uart_rxd       => uart_rx,
      axi_awaddr     => axi_mosi.awaddr,
      axi_awprot     => axi_mosi.awprot,
      axi_awvalid(0) => axi_mosi.awvalid,
      axi_awready(0) => axi_miso.awready,
      axi_wdata      => axi_mosi.wdata,
      axi_wstrb      => axi_mosi.wstrb,
      axi_wvalid(0)  => axi_mosi.wvalid,
      axi_wready(0)  => axi_miso.wready,
      axi_bresp      => axi_miso.bresp,
      axi_bvalid(0)  => axi_miso.bvalid,
      axi_bready(0)  => axi_mosi.bready,
      axi_araddr     => axi_mosi.araddr,
      axi_arprot     => axi_mosi.arprot,
      axi_arvalid(0) => axi_mosi.arvalid,
      axi_arready(0) => axi_miso.arready,
      axi_rdata      => axi_miso.rdata,
      axi_rresp      => axi_miso.rresp,
      axi_rvalid(0)  => axi_miso.rvalid,
      axi_rready(0)  => axi_mosi.rready
    );

end architecture wrapper;