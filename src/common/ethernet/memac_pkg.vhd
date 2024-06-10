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

  subtype tx_opt_t is std_ulogic_vector(5 downto 0);
  subtype TX_OPT_PRE_LEN_RANGE is natural range 3 downto 0;
  constant TX_OPT_PRE_AUTO_BIT : integer := 4;
  constant TX_OPT_FCS_AUTO_BIT : integer := 5;
  --function tx_opt_pre_len  (v : tx_opt_t) return std_ulogic_vector;
  --function tx_opt_pre_auto (v : tx_opt_t) return std_ulogic;
  --function tx_opt_fcs_auto (v : tx_opt_t) return std_ulogic;
  --function tx_opt_set(
  --  pre_len  : std_ulogic_vector(3 downto 0);
  --  pre_auto : std_ulogic;
  --  fcs_auto : std_ulogic
  --) return std_ulogic_vector;

  subtype rx_opt_t is std_ulogic_vector(10 downto 0);
  subtype RX_OPT_IPG_MIN_RANGE is natural range 3 downto 0;
  subtype RX_OPT_PRE_LEN_RANGE is natural range 7 downto 4;
  constant RX_OPT_PRE_INC_BIT : integer := 8;
  constant RX_OPT_FCS_INC_BIT : integer := 9;
  constant RX_OPT_CRC_INC_BIT : integer := 10;
  --function rx_opt_ipg_min (v : rx_opt_t) return std_ulogic_vector;
  --function rx_opt_pre_len (v : rx_opt_t) return std_ulogic_vector;
  --function rx_opt_pre_inc (v : rx_opt_t) return std_ulogic;
  --function rx_opt_fcs_inc (v : rx_opt_t) return std_ulogic;
  --function rx_opt_crc_inc (v : rx_opt_t) return std_ulogic;
  --function rx_opt_set(
  --  pre_len  : std_ulogic_vector(3 downto 0);
  --  pre_inc  : std_ulogic;
  --  fcs_inc  : std_ulogic;
  --  crc_inc  : std_ulogic
  --) return std_ulogic_vector;

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
  --function rx_flag_ipg_short (v : rx_flag_t) return std_ulogic;
  --function rx_flag_pre_inc   (v : rx_flag_t) return std_ulogic;
  --function rx_flag_pre_short (v : rx_flag_t) return std_ulogic;
  --function rx_flag_pre_long  (v : rx_flag_t) return std_ulogic;
  --function rx_flag_pre_bad   (v : rx_flag_t) return std_ulogic;
  --function rx_flag_data_err  (v : rx_flag_t) return std_ulogic;
  --function rx_flag_fcs_inc   (v : rx_flag_t) return std_ulogic;
  --function rx_flag_fcs_bad   (v : rx_flag_t) return std_ulogic;
  --function rx_flag_crc_inc   (v : rx_flag_t) return std_ulogic;
  --function rx_flag_truncate  (v : rx_flag_t) return std_ulogic;
  --function rx_flag_set(
  --  ipg_short : std_ulogic;
  --  pre_inc   : std_ulogic;
  --  pre_short : std_ulogic;
  --  pre_long  : std_ulogic;
  --  pre_bad   : std_ulogic;
  --  data_err  : std_ulogic;
  --  fcs_inc   : std_ulogic;
  --  fcs_bad   : std_ulogic;
  --  crc_inc   : std_ulogic;
  --  truncate  : std_ulogic
  --) return std_ulogic_vector;

end package memac_pkg;

package body memac_pkg is

  --------------------------------------------------------------------------------

  function tx_opt_pre_len(v : tx_opt_t) return std_ulogic_vector is
  begin
    return v(3 downto 0);
  end function tx_opt_pre_len;

  function tx_opt_pre_auto (v : tx_opt_t) return std_ulogic is
  begin
    return v(4);
  end function tx_opt_pre_auto;

  function tx_opt_fcs_auto (v : tx_opt_t) return std_ulogic is
  begin
    return v(5);
  end function tx_opt_fcs_auto;

  function tx_opt_set(
    pre_len  : std_ulogic_vector(3 downto 0);
    pre_auto : std_ulogic;
    fcs_auto : std_ulogic
  ) return std_ulogic_vector is
  begin
    return fcs_auto & pre_auto & pre_len;
  end function tx_opt_set;

  --------------------------------------------------------------------------------

  function rx_opt_pre_len (v : rx_opt_t) return std_ulogic_vector is
  begin
    return v(3 downto 0);
  end function rx_opt_pre_len;

  function rx_opt_pre_inc (v : rx_opt_t) return std_ulogic is
  begin
    return v(4);
  end function rx_opt_pre_inc;

  function rx_opt_fcs_inc (v : rx_opt_t) return std_ulogic is
  begin
    return v(5);
  end function rx_opt_fcs_inc;

  function rx_opt_crc_inc (v : rx_opt_t) return std_ulogic is
  begin
    return v(6);
  end function rx_opt_crc_inc;

  function rx_opt_set(
    pre_len  : std_ulogic_vector(3 downto 0);
    pre_inc  : std_ulogic;
    fcs_inc  : std_ulogic;
    crc_inc  : std_ulogic
  ) return std_ulogic_vector is
  begin
    return crc_inc & fcs_inc & pre_inc & pre_len;
  end function rx_opt_set;

  --------------------------------------------------------------------------------

  function rx_flag_ipg_short (v : rx_flag_t) return std_ulogic is
  begin
    return v(0);
  end function rx_flag_ipg_short;

  function rx_flag_pre_inc   (v : rx_flag_t) return std_ulogic is
  begin
    return v(1);
  end function rx_flag_pre_inc;

  function rx_flag_pre_short (v : rx_flag_t) return std_ulogic is
  begin
    return v(2);
  end function rx_flag_pre_short;

  function rx_flag_pre_long  (v : rx_flag_t) return std_ulogic is
  begin
    return v(3);
  end function rx_flag_pre_long;

  function rx_flag_pre_bad   (v : rx_flag_t) return std_ulogic is
  begin
    return v(4);
  end function rx_flag_pre_bad;

  function rx_flag_data_err  (v : rx_flag_t) return std_ulogic is
  begin
    return v(5);
  end function rx_flag_data_err;

  function rx_flag_fcs_inc   (v : rx_flag_t) return std_ulogic is
  begin
    return v(6);
  end function rx_flag_fcs_inc;

  function rx_flag_fcs_bad   (v : rx_flag_t) return std_ulogic is
  begin
    return v(7);
  end function rx_flag_fcs_bad;

  function rx_flag_crc_inc   (v : rx_flag_t) return std_ulogic is
  begin
    return v(8);
  end function rx_flag_crc_inc;

  function rx_flag_truncate  (v : rx_flag_t) return std_ulogic is
  begin
    return v(9);
  end function rx_flag_truncate;

  function rx_flag_set(
    ipg_short : std_ulogic;
    pre_inc   : std_ulogic;
    pre_short : std_ulogic;
    pre_long  : std_ulogic;
    pre_bad   : std_ulogic;
    data_err  : std_ulogic;
    fcs_inc   : std_ulogic;
    fcs_bad   : std_ulogic;
    crc_inc   : std_ulogic;
    truncate  : std_ulogic
  ) return std_ulogic_vector is
  begin
    return truncate & crc_inc & fcs_bad & fcs_inc & data_err & pre_bad & pre_long & pre_short & pre_inc & ipg_short;
  end function rx_flag_set;

  --------------------------------------------------------------------------------

end package body memac_pkg;