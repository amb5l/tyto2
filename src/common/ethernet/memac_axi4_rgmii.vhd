--------------------------------------------------------------------------------
-- memac_axi4_rgmii.vhd                                                       --
-- MEMAC: triple speed ethernet MAC, AXI4 to RGMII.                           --
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

package memac_axi4_rgmii_pkg is

  component memac_axi4_rgmii is
    port (

      axi_clk      : in    std_logic;
      axi_rst_n    : in    std_logic;
      saxi_mosi    : in    axi4_mosi_a32d32_t;
      saxi_miso    : out   axi4_miso_a32d32_t;
      maxis_mosi   : out   axi4s_mosi_64_t;
      maxis_miso   : in    axi4s_miso_64_t;
      saxis_mosi   : in    axi4s_mosi_64_t;
      saxis_miso   : out   axi4s_miso_64_t;

      rgmii_rx_clk : in    std_logic;
      rgmii_rx_ctl : in    std_logic;
      rgmii_rx_d   : in    std_logic_vector(3 downto 0);
      rgmii_tx_clk : out   std_logic;
      rgmii_tx_ctl : out   std_logic;
      rgmii_tx_d   : out   std_logic_vector(3 downto 0);

      smi_clk      : out   std_logic;
      smi_dio      : inout std_logic

    );
  end component memac_axi4_rgmii;

end package memac_axi4_rgmii_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_pkg.all;

entity memac_axi4_rgmii is
  port (

    axi_clk      : in    std_logic;
    axi_rst_n    : in    std_logic;
    saxi_mosi    : in    axi4_mosi_a32d32_t;
    saxi_miso    : out   axi4_miso_a32d32_t;
    maxis_mosi   : out   axi4s_mosi_64_t;
    maxis_miso   : in    axi4s_miso_64_t;
    saxis_mosi   : in    axi4s_mosi_64_t;
    saxis_miso   : out   axi4s_miso_64_t;

    rgmii_rx_clk : in    std_logic;
    rgmii_rx_ctl : in    std_logic;
    rgmii_rx_d   : in    std_logic_vector(3 downto 0);
    rgmii_tx_clk : out   std_logic;
    rgmii_tx_ctl : out   std_logic;
    rgmii_tx_d   : out   std_logic_vector(3 downto 0);

    smi_clk      : out   std_logic;
    smi_dio      : inout std_logic

  );
end entity memac_axi4_rgmii;

architecture synth of memac_axi4_rgmii is
begin
  -- TODO: create this IP
end architecture synth;
