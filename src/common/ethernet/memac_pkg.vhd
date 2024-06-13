--------------------------------------------------------------------------------
-- memac_pkg.vhd                                                              --
-- Modular Ethernet MAC: common types and constants.                          --
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

package memac_pkg is

  type tx_ctrl_t is record
    spd : std_ulogic_vector(1 downto 0);  -- speed
  end record tx_ctrl_t;

  subtype tx_opt_t is std_ulogic_vector(5 downto 0);
  subtype TX_OPT_PRE_LEN_RANGE is natural range 3 downto 0;
  constant TX_OPT_PRE_AUTO_BIT : integer := 4;
  constant TX_OPT_FCS_AUTO_BIT : integer := 5;

  type rx_ctrl_t is record
    spd     : std_ulogic_vector(1 downto 0);  -- speed
    ipg_min : std_ulogic_vector(3 downto 0);  -- IPG minimum
    pre_len : std_ulogic_vector(3 downto 0);  -- preamble length
    pre_inc : std_ulogic;                     -- include preamble
    fcs_inc : std_ulogic;                     -- include FCS
  end record rx_ctrl_t;

  type rx_stat_t is record
    spd       : std_ulogic_vector(1 downto 0);  -- speed
    ibs_crs   : std_ulogic;                     -- IBS carrier sense
    ibs_crx   : std_ulogic;                     -- IBS carrier extend
    ibs_crxer : std_ulogic;                     -- IBS carrier extend error
    ibs_crf   : std_ulogic;                     -- IBS carrier false
    ibs_link  : std_ulogic;                     -- IBS link up
    ibs_spd   : std_ulogic_vector(1 downto 0);  -- IBS speed
    ibs_fdx   : std_ulogic;                     -- IBS full duplex
    drops     : std_ulogic_vector(31 downto 0); -- packet drop counter
  end record rx_stat_t;

  subtype rx_flag_t is std_ulogic_vector(9 downto 0);
  constant RX_FLAG_IPG_SHORT_BIT : integer := 0;
  constant RX_FLAG_PRE_INC_BIT   : integer := 1;
  constant RX_FLAG_PRE_SHORT_BIT : integer := 2;
  constant RX_FLAG_PRE_LONG_BIT  : integer := 3;
  constant RX_FLAG_PRE_BAD_BIT   : integer := 4;
  constant RX_FLAG_DATA_ERR_BIT  : integer := 5;
  constant RX_FLAG_FCS_INC_BIT   : integer := 6;
  constant RX_FLAG_FCS_BAD_BIT   : integer := 7;
  constant RX_FLAG_CRC_INC_BIT   : integer := 8;
  constant RX_FLAG_TRUNCATE_BIT  : integer := 9;

end package memac_pkg;
