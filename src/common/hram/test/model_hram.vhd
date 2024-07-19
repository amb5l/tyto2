--------------------------------------------------------------------------------
-- model_hram.vhd                                                             --
-- Simulation model of a HyperRAM device.                                     --
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
-- assumption: simulator time resolution is 1 ps
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package model_hram_pkg is

  subtype hram_cr_t is std_ulogic_vector(15 downto 0);

  -- HyperRAM parameter bundle type
  -- reals correspond to nanoseconds
  type hram_params_t is record
    size     : integer;       -- size in bytes
    rows     : integer;       -- memory array rows
    tREF     : real;          -- refresh interval
    tVCS     : real;          -- power on and reset high to first access
    tRP      : real;          -- reset pulse width, min
    tRH      : real;          -- reset negation to chip select assertion, min
    tRPH     : real;          -- reset assertion to chip select assertion, min
    tCK      : real;          -- clock period, min
    tCKHPmin : real;          -- half clock period, min
    tCKHPmax : real;          -- half clock period, min
    tCSHI    : real;          -- chip select high, min
    tRWR     : real;          -- read-write recovery time, min
    tCSS     : real;          -- chip select setup
    tDSV     : real;          -- data strobe valid, max
    tIS      : real;          -- input setup, min
    tIH      : real;          -- input hold, min
    tACC     : real;          -- access, max
    tDQLZ    : real;          -- clock to DQ low Z, min
    tCKDmin  : real;          -- clock to DQ valid, min
    tCKDmax  : real;          -- clock to DQ valid, max
    tCKDImin : real;          -- clock to DQ invalid, min
    tCKDImax : real;          -- clock to DQ invalid, max
    tCKDSmin : real;          -- clock to RDWS valid, min
    tCKDSmax : real;          -- clock to RDWS valid, max
    tDSSmin  : real;          -- RDWS to DQ valid, min
    tDSSmax  : real;          -- RDWS to DQ valid, max
    tDSHmin  : real;          -- RDWS to DQ hold, min
    tDSHmax  : real;          -- RDWS to DQ hold, max
    tCSH     : real;          -- chip select hold, min
    tDSZ     : real;          -- chip select inactive to RWDS hi Z, max
    tOZ      : real;          -- chip select inactive to DQ hi Z, max
    tCSM     : real;          -- chip select, max
    tRFH     : real;          -- refresh
    IDREG0   : hram_cr_t;     -- default IDREG0 value
    IDREG1   : hram_cr_t;     -- default IDREG1 value
    CFGREG0  : hram_cr_t;     -- default CFGREG0 value
    CFGREG1  : hram_cr_t;     -- default CFGREG1 value
  end record hram_params_t;

  -- timing violation severity bundle type
  type hram_sev_t is record
    tVCS     : severity_level;
    tRP      : severity_level;
    tRH      : severity_level;
    tRPH     : severity_level;
    tCK      : severity_level;
    tCKHPmin : severity_level;
    tCKHPmax : severity_level;
    tCSHI    : severity_level;
    tRWR     : severity_level;
    tCSS     : severity_level;
    tDSV     : severity_level;
    tIS      : severity_level;
    tIH      : severity_level;
    tACC     : severity_level;
    tDQLZ    : severity_level;
    tCKDmin  : severity_level;
    tCKDmax  : severity_level;
    tCKDImin : severity_level;
    tCKDImax : severity_level;
    tCKDSmin : severity_level;
    tCKDSmax : severity_level;
    tDSSmin  : severity_level;
    tDSSmax  : severity_level;
    tDSHmin  : severity_level;
    tDSHmax  : severity_level;
    tCSH     : severity_level;
    tDSZ     : severity_level;
    tOZ      : severity_level;
    tCSM     : severity_level;
  end record hram_sev_t;

  constant HRAM_PARAMS_NULL : hram_params_t := (
    size     => 0,
    rows     => 0,
    tREF     => 0.0,
    tVCS     => 0.0,
    tRP      => 0.0,
    tRH      => 0.0,
    tRPH     => 0.0,
    tCK      => 0.0,
    tCKHPmin => 0.0,
    tCKHPmax => 0.0,
    tCSHI    => 0.0,
    tRWR     => 0.0,
    tCSS     => 0.0,
    tDSV     => 0.0,
    tIS      => 0.0,
    tIH      => 0.0,
    tACC     => 0.0,
    tDQLZ    => 0.0,
    tCKDmin  => 0.0,
    tCKDmax  => 0.0,
    tCKDImin => 0.0,
    tCKDImax => 0.0,
    tCKDSmin => 0.0,
    tCKDSmax => 0.0,
    tDSSmin  => 0.0,
    tDSSmax  => 0.0,
    tDSHmin  => 0.0,
    tDSHmax  => 0.0,
    tCSH     => 0.0,
    tDSZ     => 0.0,
    tOZ      => 0.0,
    tCSM     => 0.0,
    tRFH     => 0.0,
    IDREG0   => (others => 'X'),
    IDREG1   => (others => 'X'),
    CFGREG0  => (others => 'X'),
    CFGREG1  => (others => 'X')
  );

  -- parameter bundle for 8Mx8 133MHz 3.0V e.g. IS66WVH8M8DBLL-133B1LI
  constant HRAM_8Mx8_133_3V0 : hram_params_t := (
    size     => 8 * 1024 * 1024,    -- size in bytes
    rows     => 8192,               -- memory array rows
    tREF     => 64000000.0,         -- refresh interval
    tVCS     => 150000.0,           -- power on and reset high to first access
    tRP      => 200.0,              -- reset pulse width, min
    tRH      => 200.0,              -- reset negation to chip select assertion, min
    tRPH     => 400.0,              -- reset assertion to chip select assertion, min
    tCK      => 7.5,                -- clock period, min
    tCKHPmin => 0.45*7.5,           -- half clock period, min
    tCKHPmax => 0.55*7.5,           -- half clock period, min
    tCSHI    => 7.5,                -- chip select high, min
    tRWR     => 37.5,               -- read-write recovery time, min
    tCSS     => 3.0,                -- chip select setup
    tDSV     => 12.0,               -- data strobe valid, max
    tIS      => 0.8,                -- input setup, min
    tIH      => 0.8,                -- input hold, min
    tACC     => 37.5,               -- access, max
    tDQLZ    => 0.0,                -- clock to DQ low Z, min
    tCKDmin  => 1.0,                -- clock to DQ valid, min
    tCKDmax  => 7.0,                -- clock to DQ valid, max
    tCKDImin => 0.5,                -- clock to DQ invalid, min
    tCKDImax => 5.6,                -- clock to DQ invalid, max
    tCKDSmin => 1.0,                -- clock to RDWS valid, min
    tCKDSmax => 7.0,                -- clock to RDWS valid, max
    tDSSmin  => -0.6,               -- RDWS to DQ valid, min
    tDSSmax  => +0.6,               -- RDWS to DQ valid, max
    tDSHmin  => -0.6,               -- RDWS to DQ hold, min
    tDSHmax  => +0.6,               -- RDWS to DQ hold, max
    tCSH     => 3.0,                -- chip select hold, min
    tDSZ     => 6.0,                -- chip select inactive to RWDS hi Z, max
    tOZ      => 6.0,                -- chip select inactive to DQ hi Z, max
    tCSM     => 4000.0,             -- chip select, max
    tRFH     => 37.5,               -- refresh
    IDREG0   => "0000110010000011", -- default IDREG0 value
    IDREG1   => x"0000",            -- default IDREG1 value
    CFGREG0  => "1000111100011111", -- default CFGREG0 value
    CFGREG1  => "0000000000000010"  -- default CFGREG1 value
  );

  -- default severity bundle
  constant HRAM_SEV_DEFAULT : hram_sev_t := (
    tVCS     => failure,
    tRP      => failure,
    tRH      => failure,
    tRPH     => failure,
    tCK      => failure,
    tCKHPmin => failure,
    tCKHPmax => failure,
    tCSHI    => failure,
    tRWR     => failure,
    tCSS     => failure,
    tDSV     => failure,
    tIS      => failure,
    tIH      => failure,
    tACC     => failure,
    tDQLZ    => failure,
    tCKDmin  => failure,
    tCKDmax  => failure,
    tCKDImin => failure,
    tCKDImax => failure,
    tCKDSmin => failure,
    tCKDSmax => failure,
    tDSSmin  => failure,
    tDSSmax  => failure,
    tDSHmin  => failure,
    tDSHmax  => failure,
    tCSH     => failure,
    tDSZ     => failure,
    tOZ      => failure,
    tCSM     => failure
  );

  component model_hram is
    generic (
      SIM_MEM : integer;
      PARAMS  : hram_params_t := HRAM_PARAMS_NULL;
      SEV     : hram_sev_t    := HRAM_SEV_DEFAULT;
      PREFIX  : string := "model_hram: "
    );
    port (
      rst_n : inout std_logic;
      clk   : in    std_logic;
      cs_n  : in    std_logic;
      rwds  : inout std_logic;
      dq    : inout std_logic_vector(7 downto 0)
    );
  end component model_hram;

end package model_hram_pkg;

--------------------------------------------------------------------------------

use work.model_hram_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

entity model_hram is
  generic (
    SIM_MEM : integer;
    PARAMS  : hram_params_t := HRAM_PARAMS_NULL;
    SEV     : hram_sev_t    := HRAM_SEV_DEFAULT;
    PREFIX  : string := "model_hram: "
  );
  port (
    rst_n : inout std_logic;
    clk   : in    std_logic;
    cs_n  : in    std_logic;
    rwds  : inout std_logic;
    dq    : inout std_logic_vector(7 downto 0)
  );
end entity model_hram;

architecture model of model_hram is

  function real_to_ns(r : real) return time is
  begin
    if r < 1000000.0 then
      return r * 1000.0 * 1 ps;
    else
      return r * 1 ns;
    end if;
  end function real_to_ns;

  function res01x(x : std_ulogic) return std_ulogic is
  begin
    if    x = 'H' or x = '1' then return '1';
    elsif x = 'L' or x = '0' then return '0';
    else  return 'X';
    end if;
  end function res01x;

  function res01x(x : std_ulogic_vector) return std_ulogic_vector is
    variable r : std_ulogic_vector(x'range);
  begin
    for i in x'range loop
      r(i) := res01x(x(i));
    end loop;
    return r;
  end function res01x;

  --------------------------------------------------------------------------------
  -- build discrete constants from generics (better for linting)

  constant tREF         : time := real_to_ns( PARAMS.tREF     );
  constant tVCS         : time := real_to_ns( PARAMS.tVCS     );
  constant tRP          : time := real_to_ns( PARAMS.tRP      );
  constant tRH          : time := real_to_ns( PARAMS.tRH      );
  constant tRPH         : time := real_to_ns( PARAMS.tRPH     );
  constant tCK          : time := real_to_ns( PARAMS.tCK      );
  constant tCKHPmin     : time := real_to_ns( PARAMS.tCKHPmin );
  constant tCKHPmax     : time := real_to_ns( PARAMS.tCKHPmax );
  constant tCSHI        : time := real_to_ns( PARAMS.tCSHI    );
  constant tRWR         : time := real_to_ns( PARAMS.tRWR     );
  constant tCSS         : time := real_to_ns( PARAMS.tCSS     );
  constant tDSV         : time := real_to_ns( PARAMS.tDSV     );
  constant tIS          : time := real_to_ns( PARAMS.tIS      );
  constant tIH          : time := real_to_ns( PARAMS.tIH      );
  constant tACC         : time := real_to_ns( PARAMS.tACC     );
  constant tDQLZ        : time := real_to_ns( PARAMS.tDQLZ    );
  constant tCKDmin      : time := real_to_ns( PARAMS.tCKDmin  );
  constant tCKDmax      : time := real_to_ns( PARAMS.tCKDmax  );
  constant tCKDImin     : time := real_to_ns( PARAMS.tCKDImin );
  constant tCKDImax     : time := real_to_ns( PARAMS.tCKDImax );
  constant tCKDSmin     : time := real_to_ns( PARAMS.tCKDSmin );
  constant tCKDSmax     : time := real_to_ns( PARAMS.tCKDSmax );
  constant tDSSmin      : time := real_to_ns( PARAMS.tDSSmin  );
  constant tDSSmax      : time := real_to_ns( PARAMS.tDSSmax  );
  constant tDSHmin      : time := real_to_ns( PARAMS.tDSHmin  );
  constant tDSHmax      : time := real_to_ns( PARAMS.tDSHmax  );
  constant tCSH         : time := real_to_ns( PARAMS.tCSH     );
  constant tDSZ         : time := real_to_ns( PARAMS.tDSZ     );
  constant tOZ          : time := real_to_ns( PARAMS.tOZ      );
  constant tCSM         : time := real_to_ns( PARAMS.tCSM     );
  constant tRFH         : time := real_to_ns( PARAMS.tRFH     );
  constant IDREG0       : hram_cr_t := PARAMS.IDREG0;
  constant IDREG1       : hram_cr_t := PARAMS.IDREG1;
  constant C_CFGREG0    : hram_cr_t := PARAMS.CFGREG0;
  constant C_CFGREG1    : hram_cr_t := PARAMS.CFGREG1;

  constant SEV_tVCS     : severity_level := SEV.tVCS     ;
  constant SEV_tRP      : severity_level := SEV.tRP      ;
  constant SEV_tRH      : severity_level := SEV.tRH      ;
  constant SEV_tRPH     : severity_level := SEV.tRPH     ;
  constant SEV_tCK      : severity_level := SEV.tCK      ;
  constant SEV_tCKHPmin : severity_level := SEV.tCKHPmin ;
  constant SEV_tCKHPmax : severity_level := SEV.tCKHPmax ;
  constant SEV_tCSHI    : severity_level := SEV.tCSHI    ;
  constant SEV_tCSS     : severity_level := SEV.tCSS     ;
  constant SEV_tDSV     : severity_level := SEV.tDSV     ;
  constant SEV_tIS      : severity_level := SEV.tIS      ;
  constant SEV_tIH      : severity_level := SEV.tIH      ;
  constant SEV_tACC     : severity_level := SEV.tACC     ;
  constant SEV_tDQLZ    : severity_level := SEV.tDQLZ    ;
  constant SEV_tCKDmin  : severity_level := SEV.tCKDmin  ;
  constant SEV_tCKDmax  : severity_level := SEV.tCKDmax  ;
  constant SEV_tCKDImin : severity_level := SEV.tCKDImin ;
  constant SEV_tCKDImax : severity_level := SEV.tCKDImax ;
  constant SEV_tCKDSmin : severity_level := SEV.tCKDSmin ;
  constant SEV_tCKDSmax : severity_level := SEV.tCKDSmax ;
  constant SEV_tDSSmin  : severity_level := SEV.tDSSmin  ;
  constant SEV_tDSSmax  : severity_level := SEV.tDSSmax  ;
  constant SEV_tDSHmin  : severity_level := SEV.tDSHmin  ;
  constant SEV_tDSHmax  : severity_level := SEV.tDSHmax  ;
  constant SEV_tCSH     : severity_level := SEV.tCSH     ;
  constant SEV_tDSZ     : severity_level := SEV.tDSZ     ;
  constant SEV_tOZ      : severity_level := SEV.tOZ      ;
  constant SEV_tCSM     : severity_level := SEV.tCSM     ;

  --------------------------------------------------------------------------------

  type state_por_t is (POR_STD, POR_EXT, POR_DONE);

  type state_t is (
    READY,  -- ready for access
    RESET,  -- reset (waiting for tRP)
    RPH,    -- post reset (waiting for tRPH/tRH)
    UNDEF   -- undefined state
  );

  type mem_t is array(0 to SIM_MEM-1) of std_ulogic_vector(7 downto 0);

  --------------------------------------------------------------------------------

  -- external signals resolved to 0/1/X
  signal rst_n_i : std_logic := 'X';
  signal clk_i   : std_logic := 'X';
  signal cs_n_i  : std_logic := 'X';
  signal rwds_i  : std_logic := 'X';
  signal dq_i    : std_logic_vector(7 downto 0) := (others => 'X');

  signal state_por : state_por_t := POR_STD;
  signal cycle_counter : integer := 0;
  signal write_active  : boolean := false; -- true for write data clock cycles
  signal state : state_t;

  signal cfgreg0 : hram_cr_t := PARAMS.CFGREG0;
  signal cfgreg1 : hram_cr_t := PARAMS.CFGREG1;

begin

  -- reset pullup
  rst_n <= 'H';


  --------------------------------------------------------------------------------
  -- basic checks

  P_CHECK_BASIC: process
  begin
    assert PARAMS.size /= 0 report PREFIX & "hram size must be non-zero" severity failure;
    wait;
  end process P_CHECK_BASIC;

  --------------------------------------------------------------------------------
  -- resolve external signals to 0/1/X

  rst_n_i <= res01x(rst_n);
  clk_i   <= res01x(clk);
  cs_n_i  <= res01x(cs_n);
  rwds_i  <= res01x(rwds);
  dq_i    <= res01x(dq);

  --------------------------------------------------------------------------------
  -- POR timing

  P_POR: process
  begin
    if rst_n_i = '0' then
      state_por <= POR_EXT;
      wait until rst_n_i = '1';
      state_por <= POR_STD;
    end if;
    wait for tVCS;
    state_por <= POR_DONE;
    wait;
  end process P_POR;

  --------------------------------------------------------------------------------
  -- timing checks

  P_CHECK: process(all)
    procedure proc_check(
      signal rst_n : in    std_ulogic;
      signal clk   : in    std_ulogic;
      signal cs_n  : in    std_ulogic;
      signal rwds  : inout std_ulogic;
      signal dq    : inout std_ulogic_vector(7 downto 0)
    ) is
    begin
      --------------------------------------------------------------------------------

      -- check tRP (reset pulse width)

      -- check tRH (reset negation to chip select assertion)

      -- check tRPH (reset assertion to chip select assertion)

      -- check tCSHI (CS high time)
      if falling_edge(cs_n) then
        if (now-cs_n'last_event < tCSHI) then
          report PREFIX & "tCSHI violation - chip select high time not met" severity SEV_tCSHI;
        end if;
      end if;

      -- check tCSM (CS active time)
      if rising_edge(cs_n) then
        if (now-cs_n'last_event >= tCSM) then
          report PREFIX & "tCSM violation - chip select active time exceeded" severity SEV_tCSM;
        end if;
      end if;

      -- check tIS and tIH (CA and write data setup and hold)
      if (cycle_counter < 6) or write_active then
        if clk'event then
          if (tIS > 0 ps and dq'event)
          or (dq'event or (now-dq'last_event < tIS))
          then
            report PREFIX & "tIS violation - input setup time not met" severity SEV_tIS;
          end if;
        end if;
        if dq'event then
          if (tIH > 0 ps and clk'event)
          or (now-clk'last_event < tIH)
          then
            report PREFIX & "tIH violation - input hold time not met" severity SEV_tIH;
          end if;
        end if;
      end if;
      --------------------------------------------------------------------------------
    end procedure proc_check;
  begin
    proc_check(rst_n_i, clk_i, cs_n_i, rwds_i, dq_i);
  end process P_CHECK;

  --

  -- background refresh runs from ring oscillator
  -- TODO: handle tolerance on ring osc frequency


  --------------------------------------------------------------------------------

  P_MAIN: process(all)
    variable mem : mem_t;
    procedure handle_event(
        signal rst_n : in    std_ulogic;
        signal clk   : in    std_ulogic;
        signal cs_n  : in    std_ulogic;
        signal rwds  : inout std_ulogic;
        signal dq    : inout std_ulogic_vector(7 downto 0)
     ) is
    begin
      --------------------------------------------------------------------------------





      --------------------------------------------------------------------------------
    end procedure handle_event;
  begin
    handle_event(rst_n_i, clk_i, cs_n_i, rwds_i, dq_i);
  end process P_MAIN;

  --------------------------------------------------------------------------------
  -- registers, with reset states

end architecture model;
