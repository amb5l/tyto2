--------------------------------------------------------------------------------
-- hdmi_rx_selectio_fm.vhd                                                    --
-- HDMI sink front end built on Xilinx 7 Series SelectIO primitives -         --
--  frequency measurement module.                                             --
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

package hdmi_rx_selectio_fm_pkg is

  constant FM_FMIN_MHZ     : real    := 24.0;                                    -- min frequency
  constant FM_FMAX_MHZ     : real    := 150.0;                                   -- max frequency
  constant FM_INTERVAL_US  : integer := 100;                                     -- interval
  constant FM_FTOL_MHZ     : real    := 0.5;                                     -- tolerance
  constant FM_FCOUNT_MAX   : integer := integer(FM_INTERVAL_US*FM_FMAX_MHZ)-1;
  constant FM_FCOUNT_44M   : integer := integer(FM_INTERVAL_US*44);              -- boundaries between different MMCM recipes
  constant FM_FCOUNT_70M   : integer := integer(FM_INTERVAL_US*70);              -- "
  constant FM_FCOUNT_120M  : integer := integer(FM_INTERVAL_US*120);             -- "

  component hdmi_rx_selectio_fm is
    generic (
      fclk : real
    );
    port (
      rst  : in    std_logic;
      clk  : in    std_logic;
      mclk : in    std_logic;
      mval : out   integer range 0 to FM_FCOUNT_MAX;
      mstb : out   std_logic;
      mack : in    std_logic
    );
  end component hdmi_rx_selectio_fm;

end package hdmi_rx_selectio_fm_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.hdmi_rx_selectio_fm_pkg.all;

entity hdmi_rx_selectio_fm is
  generic (
    fclk : real
  );
  port (
    rst  : in    std_logic;
    clk  : in    std_logic;
    mclk : in    std_logic;
    mval : out   integer range 0 to FM_FCOUNT_MAX;
    mstb : out   std_logic;
    mack : in    std_logic
  );
end entity hdmi_rx_selectio_fm;

architecture synth of hdmi_rx_selectio_fm is

  constant FM_FCOUNT_MIN   : integer := integer(FM_INTERVAL_US*FM_FMIN_MHZ)-1;
  constant FM_TCOUNT_MAX   : integer := integer(FM_INTERVAL_US*fclk)-1;
  constant FM_FDELTA_MAX   : integer := integer(FM_INTERVAL_US*FM_FTOL_MHZ);

  type fmo_state_t is (FM_UNLOCKED,FM_LOCKING,FM_LOCKED);

  signal fmi_rst_s      : std_logic_vector(0 to 1);                       -- reset synchronisers
  alias  fmi_rst        : std_logic is fmi_rst_s(1);                      -- reset
  signal fmi_fcount     : integer range 0 to FM_FCOUNT_MAX;               -- frequency counter
  signal fmi_fvalue     : integer range 0 to FM_FCOUNT_MAX;               -- latest frequency value
  signal fmi_toggle_s   : std_logic_vector(0 to 2);
  signal fmo_tcount     : integer range 0 to FM_TCOUNT_MAX;               -- interval counter
  signal fmo_toggle     : std_logic;
  signal fmo_fvalue     : integer range 0 to FM_TCOUNT_MAX;
  signal fmo_fdelta     : integer range -FM_TCOUNT_MAX to FM_TCOUNT_MAX;
  signal fmo_fdelta_abs : integer range 0 to FM_TCOUNT_MAX;
  signal fmo_chg        : std_logic;
  signal fmo_ack        : std_logic;
  signal fmo_state      : fmo_state_t;


begin

  -- mclk frequency measurement

  -- symchronise to mclk domain
  process(rst,mclk)
  begin
    if rst = '1' then
      fmi_rst_s <= (others => '1');
      fmi_toggle_s <= (others => '0');
    elsif rising_edge(mclk) then
      fmi_rst_s(0 to 1) <= rst & fmi_rst_s(0);
      fmi_toggle_s(0 to 2) <= fmo_toggle & fmi_toggle_s(0 to 1);
    end if;
  end process;

  process(fmi_rst,mclk)
  begin
    if fmi_rst = '1' then
      fmi_fvalue <= 0;
      fmi_fcount <= 0;
    elsif rising_edge(mclk) then
      fmi_fcount <= fmi_fcount+1;
      if fmi_toggle_s(1) /= fmi_toggle_s(2) then
        fmi_fvalue <= fmi_fcount;
        fmi_fcount <= 0;
      end if;
    end if;
  end process;

  process(rst,clk)
  begin
    if rst = '1' then
      fmo_tcount <= 0;
      fmo_toggle <= '0';
      fmo_state <= FM_UNLOCKED;
      fmo_fvalue <= 0;
      fmo_chg <= '0';
    elsif rising_edge(clk) then
      if fmo_tcount = FM_TCOUNT_MAX then
        fmo_tcount <= 0;
        fmo_toggle <= not fmo_toggle;
        case fmo_state is
          when FM_UNLOCKED =>
            if fmi_fvalue > FM_FCOUNT_MIN then
              fmo_fvalue <= fmi_fvalue;
              fmo_state <= FM_LOCKING;
            else
              fmo_fvalue <= 0;
            end if;
          when FM_LOCKING =>
            if fmo_fdelta_abs <= FM_FDELTA_MAX then
              fmo_chg <= '1';
              fmo_state <= FM_LOCKED;
            else
              fmo_fvalue <= 0;
              fmo_state <= FM_UNLOCKED;
            end if;
          when FM_LOCKED =>
            if fmo_fdelta_abs > FM_FDELTA_MAX then
              fmo_fvalue <= 0;
              fmo_state <= FM_UNLOCKED;
            end if;
        end case;
      else
        fmo_tcount <= fmo_tcount+1;
      end if;
      if fmo_ack = '1' then
        fmo_chg <= '0';
      end if;
    end if;
  end process;

  fmo_fdelta <= fmo_fvalue-fmi_fvalue;
  fmo_fdelta_abs <= fmo_fdelta when fmo_fdelta >= 0 else -fmo_fdelta;

end architecture synth;
