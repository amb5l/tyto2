--------------------------------------------------------------------------------
-- jarv_regfile.vhd                                                           --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation       --
-- either version 3 of the License or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.jarv_g_pkg.all;

package jarv_regfile_pkg is

  component jarv_regfile is
    generic (
      xlen  : integer := 32;
      opt_E : boolean := false
    );
    port (
      clk     : in    std_logic;
      rs1_sel : in    std_logic_vector(ternary(opt_E,3,4) downto 0);
      rs1_val : out   std_logic_vector(xlen-1 downto 0);
      rs2_sel : in    std_logic_vector(ternary(opt_E,3,4) downto 0);
      rs2_val : out   std_logic_vector(xlen-1 downto 0);
      rd_sel  : in    std_logic_vector(ternary(opt_E,3,4) downto 0);
      rd_val  : in    std_logic_vector(xlen-1 downto 0);
      rd_we   : in    std_logic
    );
  end component jarv_regfile;

end package jarv_regfile_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.jarv_g_pkg.all;
  use work.jarv_sdpram_pkg.all;

entity jarv_regfile is
  generic (
    xlen  : integer := 32;
    opt_E : boolean := false
  );
  port (
    clk     : in    std_logic;
    rs1_sel : in    std_logic_vector(ternary(opt_E,3,4) downto 0);
    rs1_val : out   std_logic_vector(xlen-1 downto 0);
    rs2_sel : in    std_logic_vector(ternary(opt_E,3,4) downto 0);
    rs2_val : out   std_logic_vector(xlen-1 downto 0);
    rd_sel  : in    std_logic_vector(ternary(opt_E,3,4) downto 0);
    rd_val  : in    std_logic_vector(xlen-1 downto 0);
    rd_we   : in    std_logic
  );
end entity jarv_regfile;

architecture synth of jarv_regfile is
begin

  REG_FILE_1: component jarv_sdpram
    generic map (
      data_width => 32,
      addr_width => ternary(opt_E,3,4)
    )
    port map (
      wclk  => clk,
      we    => rd_we,
      waddr => rd_sel,
      wdata => rd_val,
      raddr => rs1_sel,
      rdata => rs1_val
    );

  REG_FILE_2: component jarv_sdpram
    generic map (
      data_width => 32,
      addr_width => ternary(opt_E,3,4)
    )
    port map (
      wclk  => clk,
      we    => rd_we,
      waddr => rd_sel,
      wdata => rd_val,
      raddr => rs2_sel,
      rdata => rs2_val
    );

end architecture synth;
