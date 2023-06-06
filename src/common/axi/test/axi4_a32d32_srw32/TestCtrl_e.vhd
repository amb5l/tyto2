--------------------------------------------------------------------------------
-- TestCtrl_e.vhd                                                             --
-- OSVVM based testbench for axi4_a32d32_srw32.vhd                            --
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

library osvvm_common;
  context osvvm_common.OsvvmCommonContext;

package TestCtrl_pkg is

  component TestCtrl is
    generic (
      addr_width : integer
    );
    port (
      Clk        : in    std_logic;
      nReset     : in    std_logic;
      ManagerRec : inout AddressBusRecType
    );
  end component TestCtrl;

end package TestCtrl_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.Axi4Context;

library work;
  use work.OsvvmTestCommonPkg.all;

entity TestCtrl is
  generic (
    addr_width : integer
  );
  port (
    Clk        : in    std_logic;
    nReset     : in    std_logic;
    ManagerRec : inout AddressBusRecType
  );
end entity TestCtrl;
