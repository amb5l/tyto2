--------------------------------------------------------------------------------
-- tyto_utils_pkg.vhd                                                         --
-- Useful functions and procedures etc.                                       --
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

package tyto_utils_pkg is

    function bool2sl(v : boolean) return std_logic;

end package tyto_utils_pkg;

package body tyto_utils_pkg is

    function bool2sl(v : boolean) return std_logic is
    begin
        if v then return '1'; else return '0'; end if;
    end function bool2sl;

end package body tyto_utils_pkg;
