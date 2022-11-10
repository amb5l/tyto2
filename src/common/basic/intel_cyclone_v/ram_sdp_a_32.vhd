--------------------------------------------------------------------------------
-- ram_sdp_a_32.vhd                                                           --
-- Simple dual port RAM, asynchronous read, 32 words deep.                    --
-- Built from Intel altdpram primitive for Cyclone V.                         --
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

package ram_sdp_a_32_pkg is

  component ram_sdp_a_32 is
    generic (
      width : integer
    );
    port (
      clk   : in    std_logic;
      ce    : in    std_logic;
      we    : in    std_logic;
      wa    : in    std_logic_vector(4 downto 0);
      wd    : in    std_logic_vector(width - 1 downto 0);
      ra    : in    std_logic_vector(4 downto 0);
      rd    : out   std_logic_vector(width - 1 downto 0)
    );
  end component ram_sdp_a_32;

end package ram_sdp_a_32_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library altera_mf;
  use altera_mf.altera_mf_components.all;

entity ram_sdp_a_32 is
  generic (
    width : integer
  );
  port (
    clk   : in    std_logic;
    ce    : in    std_logic;
    we    : in    std_logic;
    wa    : in    std_logic_vector(4 downto 0);
    wd    : in    std_logic_vector(width - 1 downto 0);
    ra    : in    std_logic_vector(4 downto 0);
    rd    : out   std_logic_vector(width - 1 downto 0)
  );
end entity ram_sdp_a_32;

architecture struct of ram_sdp_a_32 is

begin

  RAM : component altdpram
    generic map (
      indata_aclr                        => "OFF",
      indata_reg                         => "INCLOCK",
      intended_device_family             => "Cyclone V",
      lpm_type                           => "altdpram",
      outdata_aclr                       => "OFF",
      outdata_reg                        => "UNREGISTERED",
      ram_block_type                     => "MLAB",
      rdaddress_aclr                     => "OFF",
      rdaddress_reg                      => "UNREGISTERED",
      rdcontrol_aclr                     => "OFF",
      rdcontrol_reg                      => "UNREGISTERED",
      read_during_write_mode_mixed_ports => "DONT_CARE",
      width                              => width,
      widthad                            => 5,
      width_byteena                      => 1,
      wraddress_aclr                     => "OFF",
      wraddress_reg                      => "INCLOCK",
      wrcontrol_aclr                     => "OFF",
      wrcontrol_reg                      => "INCLOCK"
    )
    port map (
      data                               => wd,
      inclock                            => clk,
      inclocken                          => ce,
      outclock                           => clk,
      rdaddress                          => ra,
      wraddress                          => wa,
      wren                               => we,
      q                                  => rd
    );

end architecture struct;
