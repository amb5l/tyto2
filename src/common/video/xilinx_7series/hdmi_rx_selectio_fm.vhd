--------------------------------------------------------------------------------
-- hdmi_rx_selectio_fm.vhd                                                    --
-- HDMI sink front end built on Xilinx 7 Series SelectIO primitives -         --
--  frequency measurement module.                                             --
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

package hdmi_rx_selectio_fm_pkg is

  constant FM_FMIN_MHZ     : real    := 24.0;                                    -- min frequency
  constant FM_FMAX_MHZ     : real    := 150.0;                                   -- max frequency
  constant FM_INTERVAL_US  : integer := 100;                                     -- interval
  constant FM_FTOL_MHZ     : real    := 0.5;                                     -- tolerance
  constant FM_FCOUNT_MAX   : integer := integer(real(FM_INTERVAL_US)*FM_FMAX_MHZ)-1;
  constant FM_FCOUNT_24M   : integer := integer(FM_INTERVAL_US*24);              -- boundaries between different MMCM recipes
  constant FM_FCOUNT_44M   : integer := integer(FM_INTERVAL_US*44);              -- "
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
      mf   : out   integer range 0 to FM_FCOUNT_MAX;
      mok  : out   std_logic
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
    mf   : out   integer range 0 to FM_FCOUNT_MAX;
    mok  : out   std_logic
  );
end entity hdmi_rx_selectio_fm;

architecture synth of hdmi_rx_selectio_fm is

  constant FM_FCOUNT_MIN   : integer := integer(real(FM_INTERVAL_US)*FM_FMIN_MHZ)-1;
  constant FM_TCOUNT_MAX   : integer := integer(real(FM_INTERVAL_US)*fclk)-1;
  constant FM_FDELTA_MAX   : integer := integer(real(FM_INTERVAL_US)*FM_FTOL_MHZ);

  type c_state_t is (UNLOCKED,LOCKING,LOCKED);

  -- mclk domain
  signal m_rst_s      : std_logic_vector(0 to 1);                       -- reset synchronisers
  alias  m_rst        : std_logic is m_rst_s(1);                        -- reset
  signal m_fcount     : integer range 0 to FM_FCOUNT_MAX;               -- frequency counter
  signal m_fvalue     : integer range 0 to FM_FCOUNT_MAX;               -- latest frequency value
  signal m_toggle_s   : std_logic_vector(0 to 2);

  -- clk domain
  signal c_tcount     : integer range 0 to FM_TCOUNT_MAX;               -- interval counter
  signal c_toggle     : std_logic;
  signal c_fvalue     : integer range 0 to FM_FCOUNT_MAX;
  signal c_fdelta     : integer range -FM_FCOUNT_MAX to FM_FCOUNT_MAX;
  signal c_fdelta_abs : integer range 0 to FM_FCOUNT_MAX;
  signal c_state      : c_state_t;

  -- attributes
  attribute async_reg : string;
  attribute async_reg of m_rst_s    : signal is "TRUE";
  attribute async_reg of m_toggle_s : signal is "TRUE";
  attribute async_reg of c_fvalue   : signal is "TRUE";

begin

  mf <= c_fvalue;
  mok <= '1' when c_state = LOCKED else '0';

  -- symchronise to mclk domain
  process(rst,mclk)
  begin
    if rst = '1' then
      m_rst_s <= (others => '1');
      m_toggle_s <= (others => '0');
    elsif rising_edge(mclk) then
      m_rst_s(0 to 1) <= rst & m_rst_s(0);
      m_toggle_s(0 to 2) <= c_toggle & m_toggle_s(0 to 1);
    end if;
  end process;

  process(m_rst,mclk)
  begin
    if m_rst = '1' then
      m_fvalue <= 0;
      m_fcount <= 0;
    elsif rising_edge(mclk) then
      m_fcount <= m_fcount+1;
      if m_toggle_s(1) /= m_toggle_s(2) then
        m_fvalue <= m_fcount;
        m_fcount <= 0;
      end if;
    end if;
  end process;

  process(rst,clk)
  begin
    if rst = '1' then
      c_tcount <= 0;
      c_toggle <= '0';
      c_state  <= UNLOCKED;
      c_fvalue <= 0;
    elsif rising_edge(clk) then
      if c_tcount = FM_TCOUNT_MAX then
        c_tcount <= 0;
        c_toggle <= not c_toggle;
        case c_state is
          when UNLOCKED =>
            if m_fvalue > FM_FCOUNT_MIN then
              c_fvalue <= m_fvalue;
              c_state  <= LOCKING;
            else
              c_fvalue <= 0;
            end if;
          when LOCKING =>
            if c_fdelta_abs <= FM_FDELTA_MAX then
              c_state  <= LOCKED;
            else
              c_fvalue <= 0;
              c_state  <= UNLOCKED;
            end if;
          when LOCKED =>
            if c_fdelta_abs > FM_FDELTA_MAX then
              c_fvalue <= 0;
              c_state  <= UNLOCKED;
            end if;
        end case;
      else
        c_tcount <= c_tcount+1;
      end if;
    end if;
  end process;

  c_fdelta <= c_fvalue-m_fvalue;
  c_fdelta_abs <= c_fdelta when c_fdelta >= 0 else -c_fdelta;

end architecture synth;
