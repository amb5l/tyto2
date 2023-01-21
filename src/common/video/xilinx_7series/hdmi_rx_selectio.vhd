--------------------------------------------------------------------------------
-- hdmi_rx_selectio.vhd                                                       --
-- HDMI sink front end built on Xilinx 7 Series SelectIO primitives.          --
-- Supports pixel clocks in the range 25..148.5MHz. Note that -1 parts are    --
-- rated at 950Mbps (95MHz) max, and -2 parts are rated at 1200Mbps max.      --
-- Higher frequencies may not work!                                           --
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

library work;
  use work.tyto_types_pkg.all;

package hdmi_rx_selectio_pkg is

  component hdmi_rx_selectio is
    generic (
      fclk    : real
    );
    port (
      rst     : in    std_logic;
      clk     : in    std_logic;
      pclki   : in    std_logic;
      si      : in    std_logic_vector(0 to 2);
      pclko   : out   std_logic;
      po      : out   slv_9_0_t(0 to 2)
    );
  end component hdmi_rx_selectio;

end package hdmi_rx_selectio_pkg;

----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;

entity hdmi_rx_selectio is
  generic (
    fclk    : real                            -- clk frequency (MHz)
  );
  port (
    rst     : in    std_logic;                -- reset (sychronous to clk)
    clk     : in    std_logic;                -- clock (measurement and control)
    pclki   : in    std_logic;                -- pixel/character clock in
    si      : in    std_logic_vector(0 to 2); -- serial TMDS in
    pclko   : out   std_logic;                -- pixel/character clock out
    po      : out   slv_9_0_t(0 to 2)         -- parallel TMDS out
  );
end entity hdmi_rx_selectio;

architecture synth of hdmi_rx_selectio is

  --------------------------------------------------------------------------------
  -- constants

  constant FM_FMIN_MHZ    : real    := 24.0;  -- frequency measurement - min frequency
  constant FM_FMAX_MHZ    : real    := 150.0; -- frequency measurement - max frequency
  constant FM_INTERVAL_US : integer := 100;   -- frequency measurement - interval
  constant FM_FTOL_MHZ    : real    := 0.5;   -- frequency measurement - tolerance

  constant FM_FCOUNT_MIN : integer := integer(FM_INTERVAL_US*FM_FMIN_MHZ)-1;
  constant FM_FCOUNT_MAX : integer := integer(FM_INTERVAL_US*FM_FMAX_MHZ)-1;
  constant FM_TCOUNT_MAX : integer := integer(FM_INTERVAL_US*fclk)-1;
  constant FM_FDELTA_MAX : integer := integer(FM_INTERVAL_US*FM_FTOL_MHZ);

  -- boundaries between different MMCM recipes
  constant FM_FCOUNT_44M  : integer := integer(FM_INTERVAL_US*44);
  constant FM_FCOUNT_70M  : integer := integer(FM_INTERVAL_US*70);
  constant FM_FCOUNT_120M : integer := integer(FM_INTERVAL_US*120);

  --------------------------------------------------------------------------------
  -- types

  type fmo_state_t is (FM_UNLOCKED,FM_LOCKING,FM_LOCKED);

  type mmcm_state_t is (                              -- state machine states
    idle,                                              -- waiting for fsel change
    reset,                                             -- put MMCM into reset
    tbl,                                               -- get first/next table value
    rd,                                                -- start read
    rd_wait,                                           -- wait for read to complete
    wr,                                                -- start write
    wr_wait,                                           -- wait for write to complete
    lock_wait                                          -- wait for reconfig to complete
  );

  --------------------------------------------------------------------------------
  -- signals

  -- frequency measurement (fmi_ = pclki domain, fmo_ = clk domain)
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

  -- MMCM
  signal mmcm_rst      : std_logic;
  signal mmcm_clkout0  : std_logic;
  signal mmcm_clkout1p : std_logic;
  signal mmcm_clkout1n : std_logic;
  signal mmcm_fbo      : std_logic;
  signal mmcm_fbi      : std_logic;
  signal mmcm_lock_a   : std_logic;
  signal mmcm_lock_s   : std_logic_vector(0 to 1);
  alias  mmcm_lock     : std_logic is mmcm_lock_s(1);
  signal mmcm_tbl_a    : std_logic_vector(6 downto 0);  -- 4 x 32 entries
  signal mmcm_tbl_d    : std_logic_vector(39 downto 0); -- 8 bit address + 16 bit write data + 16 bit read mask
  signal mmcm_daddr    : std_logic_vector(6 downto 0);  -- DRP register address
  signal mmcm_den      : std_logic;                     -- DRP enable (pulse)
  signal mmcm_dwe      : std_logic;                     -- DRP write enable
  signal mmcm_di       : std_logic_vector(15 downto 0); -- DRP write data
  signal mmcm_do       : std_logic_vector(15 downto 0); -- DRP read data
  signal mmcm_drdy     : std_logic;                     -- DRP access complete
  signal mmcm_state    : mmcm_state_t;
  signal prst_a        : std_logic;
  signal prst_s        : std_logic_vector(0 to 1);
  alias  prst          : std_logic is prst_s(1);
  signal pclk          : std_logic;
  signal sclk_p        : std_logic;
  signal sclk_n        : std_logic;

  -- IDELAYE2
  signal sid           : std_logic_vector(0 to 2);      -- si, delayed by IDELAYE2
  signal idelay_ld     : std_logic;
  signal idelay_tap    : std_logic_vector(4 downto 0);
  signal idelay_slip   : std_logic;

  -- ISERDESE2
  signal pi            : slv_9_0_t(0 to 2);             -- parallel input
  signal shift1        : std_logic_vector(0 to 2);      -- master-slave cascade
  signal shift2        : std_logic_vector(0 to 2);      -- "

begin


  ----------------------------------------------------------------------
  -- pclki frequency measurement

  -- symchronise to pclki domain
  process(rst,pclki)
  begin
    if rst = '1' then
      fmi_rst_s <= (others => '1');
      fmi_toggle_s <= (others => '0');
    elsif rising_edge(pclki) then
      fmi_rst_s(0 to 1) <= rst & fmi_rst_s(0);
      fmi_toggle_s(0 to 2) <= fmo_toggle & fmi_toggle_s(0 to 1);
    end if;
  end process;

  process(fmi_rst,pclki)
  begin
    if fmi_rst = '1' then
      fmi_fvalue <= 0;
      fmi_fcount <= 0;
    elsif rising_edge(pclki) then
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

  ----------------------------------------------------------------------
  -- reconfigure MMCM when required by loss of lock or changes in pclki

  process (rst,clk) is

    -- contents of synchronous ROM table
    function mmcm_tbl (addr : std_logic_vector) return std_logic_vector is
      -- bits 39..32 = mmcm_daddr (MSB = 1 for last entry)
      -- bits 31..16 = cfg write data
      -- bits 15..0 = cfg read mask
      variable data : std_logic_vector(39 downto 0);
    begin
      data := x"0000000000";
      -- values below pasted in from video_out_clk.xls
      case '0' & addr is
        when x"00" => data := x"06" & x"1145" & x"1000";
        when x"01" => data := x"07" & x"0000" & x"8000";
        when x"02" => data := x"08" & x"1083" & x"1000";
        when x"03" => data := x"09" & x"0080" & x"8000";
        when x"04" => data := x"0A" & x"130d" & x"1000";
        when x"05" => data := x"0B" & x"0080" & x"8000";
        when x"06" => data := x"0C" & x"1145" & x"1000";
        when x"07" => data := x"0D" & x"0000" & x"8000";
        when x"08" => data := x"0E" & x"1145" & x"1000";
        when x"09" => data := x"0F" & x"0000" & x"8000";
        when x"0A" => data := x"10" & x"1145" & x"1000";
        when x"0B" => data := x"11" & x"0000" & x"8000";
        when x"0C" => data := x"12" & x"1145" & x"1000";
        when x"0D" => data := x"13" & x"3000" & x"8000";
        when x"0E" => data := x"14" & x"13CF" & x"1000";
        when x"0F" => data := x"15" & x"4800" & x"8000";
        when x"10" => data := x"16" & x"0083" & x"C000";
        when x"11" => data := x"18" & x"002C" & x"FC00";
        when x"12" => data := x"19" & x"7C01" & x"8000";
        when x"13" => data := x"1A" & x"7DE9" & x"8000";
        when x"14" => data := x"28" & x"FFFF" & x"0000";
        when x"15" => data := x"4E" & x"0900" & x"66FF";
        when x"16" => data := x"CF" & x"1000" & x"666F";
        when x"20" => data := x"06" & x"1145" & x"1000";
        when x"21" => data := x"07" & x"0000" & x"8000";
        when x"22" => data := x"08" & x"10C4" & x"1000";
        when x"23" => data := x"09" & x"0080" & x"8000";
        when x"24" => data := x"0A" & x"1452" & x"1000";
        when x"25" => data := x"0B" & x"0080" & x"8000";
        when x"26" => data := x"0C" & x"1145" & x"1000";
        when x"27" => data := x"0D" & x"0000" & x"8000";
        when x"28" => data := x"0E" & x"1145" & x"1000";
        when x"29" => data := x"0F" & x"0000" & x"8000";
        when x"2A" => data := x"10" & x"1145" & x"1000";
        when x"2B" => data := x"11" & x"0000" & x"8000";
        when x"2C" => data := x"12" & x"1145" & x"1000";
        when x"2D" => data := x"13" & x"2800" & x"8000";
        when x"2E" => data := x"14" & x"15D7" & x"1000";
        when x"2F" => data := x"15" & x"2800" & x"8000";
        when x"30" => data := x"16" & x"0083" & x"C000";
        when x"31" => data := x"18" & x"00FA" & x"FC00";
        when x"32" => data := x"19" & x"7C01" & x"8000";
        when x"33" => data := x"1A" & x"7DE9" & x"8000";
        when x"34" => data := x"28" & x"FFFF" & x"0000";
        when x"35" => data := x"4E" & x"1900" & x"66FF";
        when x"36" => data := x"CF" & x"0100" & x"666F";
        when x"40" => data := x"06" & x"1145" & x"1000";
        when x"41" => data := x"07" & x"0000" & x"8000";
        when x"42" => data := x"08" & x"1041" & x"1000";
        when x"43" => data := x"09" & x"0000" & x"8000";
        when x"44" => data := x"0A" & x"1145" & x"1000";
        when x"45" => data := x"0B" & x"0000" & x"8000";
        when x"46" => data := x"0C" & x"1145" & x"1000";
        when x"47" => data := x"0D" & x"0000" & x"8000";
        when x"48" => data := x"0E" & x"1145" & x"1000";
        when x"49" => data := x"0F" & x"0000" & x"8000";
        when x"4A" => data := x"10" & x"1145" & x"1000";
        when x"4B" => data := x"11" & x"0000" & x"8000";
        when x"4C" => data := x"12" & x"1145" & x"1000";
        when x"4D" => data := x"13" & x"2400" & x"8000";
        when x"4E" => data := x"14" & x"1491" & x"1000";
        when x"4F" => data := x"15" & x"1800" & x"8000";
        when x"50" => data := x"16" & x"0083" & x"C000";
        when x"51" => data := x"18" & x"00FA" & x"FC00";
        when x"52" => data := x"19" & x"7C01" & x"8000";
        when x"53" => data := x"1A" & x"7DE9" & x"8000";
        when x"54" => data := x"28" & x"FFFF" & x"0000";
        when x"55" => data := x"4E" & x"0900" & x"66FF";
        when x"56" => data := x"CF" & x"1000" & x"666F";
        when x"60" => data := x"06" & x"1145" & x"1000";
        when x"61" => data := x"07" & x"0000" & x"8000";
        when x"62" => data := x"08" & x"1041" & x"1000";
        when x"63" => data := x"09" & x"00C0" & x"8000";
        when x"64" => data := x"0A" & x"1083" & x"1000";
        when x"65" => data := x"0B" & x"0080" & x"8000";
        when x"66" => data := x"0C" & x"1145" & x"1000";
        when x"67" => data := x"0D" & x"0000" & x"8000";
        when x"68" => data := x"0E" & x"1145" & x"1000";
        when x"69" => data := x"0F" & x"0000" & x"8000";
        when x"6A" => data := x"10" & x"1145" & x"1000";
        when x"6B" => data := x"11" & x"0000" & x"8000";
        when x"6C" => data := x"12" & x"1145" & x"1000";
        when x"6D" => data := x"13" & x"2400" & x"8000";
        when x"6E" => data := x"14" & x"1491" & x"1000";
        when x"6F" => data := x"15" & x"1800" & x"8000";
        when x"70" => data := x"16" & x"0083" & x"C000";
        when x"71" => data := x"18" & x"00FA" & x"FC00";
        when x"72" => data := x"19" & x"7C01" & x"8000";
        when x"73" => data := x"1A" & x"7DE9" & x"8000";
        when x"74" => data := x"28" & x"FFFF" & x"0000";
        when x"75" => data := x"4E" & x"0900" & x"66FF";
        when x"76" => data := x"CF" & x"1000" & x"666F";
        when others => data := (others => '0');
      end case;
      return data;
    end function mmcm_tbl;

  begin

    if rst = '1' then                                                                                                           -- full reset

        mmcm_lock_s <= (others => '0');
        mmcm_rst    <= '1';
        mmcm_daddr  <= (others => '0');
        mmcm_den    <= '0';
        mmcm_dwe    <= '0';
        mmcm_di     <= (others => '0');
        mmcm_state  <= RESET;

    elsif rising_edge(clk) then

      mmcm_tbl_d <= mmcm_tbl(mmcm_tbl_a); -- synchronous ROM

      mmcm_lock_s(0 to 1) <= mmcm_lock_a & mmcm_lock_s(0);

      -- defaults
      fmo_ack  <= '0';
      mmcm_den <= '0';
      mmcm_dwe <= '0';

      -- state machine
      case mmcm_state is
        when IDLE =>
          if mmcm_lock = '0' or fmo_chg = '1' then
            fmo_ack    <= '1';
            mmcm_rst   <= '1';
            mmcm_state <= RESET;
          end if;
        when RESET =>
          -- program for correct frequency range
          mmcm_tbl_a <= (others => '0');
          if fmo_fvalue > FM_FCOUNT_44M then
            mmcm_tbl_a(6 downto 5) <= "01";
          elsif fmo_fvalue > FM_FCOUNT_70M then
            mmcm_tbl_a(6 downto 5) <= "10";
          elsif fmo_fvalue > FM_FCOUNT_120M then
            mmcm_tbl_a(6 downto 5) <= "11";
          end if;
          mmcm_state <= TBL;
        when TBL =>                                                                                                                -- get table entry from sychronous ROM
          mmcm_state <= RD;
        when RD =>                                                                                                                 -- read specified register
          mmcm_daddr <= mmcm_tbl_d(38 downto 32);
          mmcm_den   <= '1';
          mmcm_state <= RD_WAIT;
        when RD_WAIT =>                                                                                                            -- wait for read to complete
          if mmcm_drdy = '1' then
            mmcm_di    <= (mmcm_do and mmcm_tbl_d(15 downto 0)) or (mmcm_tbl_d(31 downto 16) and not mmcm_tbl_d(15 downto 0));
            mmcm_den   <= '1';
            mmcm_dwe   <= '1';
            mmcm_state <= WR;
          end if;
        when WR =>                                                                                                                 -- write modified contents back to same register
          mmcm_state <= WR_WAIT;
        when WR_WAIT =>                                                                                                            -- wait for write to complete
          if mmcm_drdy = '1' then
            if mmcm_tbl_d(39) = '1' then                                                                                         -- last entry in table
              mmcm_tbl_a <= (others => '0');
              mmcm_state <= LOCK_WAIT;
            else                                                                                                                   -- do next entry in table
              mmcm_tbl_a(4 downto 0) <= std_logic_vector(unsigned(mmcm_tbl_a(4 downto 0)) + 1);
              mmcm_state                <= TBL;
            end if;
          end if;
        when LOCK_WAIT =>                                                                                                          -- wait for MMCM to lock
          mmcm_rst <= '0';
          if mmcm_lock = '1' then                                                                                                   -- all done
            mmcm_state <= IDLE;
          end if;
      end case;

    end if;
  end process;

  -- pclk domain reset
  prst_a <= '1' when mmcm_state /= IDLE or mmcm_lock = '0' else '0';
  process(prst_a,pclk)
  begin
    if prst_a = '1' then
      prst_s <= (others => '1');
    elsif rising_edge(pclk) then
      prst_s(0 to 1) <= prst_a & prst_s(0);
    end if;
  end process;

  ----------------------------------------------------------------------
  -- input lock - channel by channel

  ----------------------------------------------------------------------
  -- MMCM

  -- The 7 series LVDS serdes is rated at as follows for DDR outputs:
  --  1200Mbps max for -2 speed grade
  --  950Mbps max for -1 speed grade
  -- 1485Mbps (full HD) overclocks these, so we use a fictional static
  -- recipe for the MMCM to achieve timing closure:
  --  clkin1_period = 10ns (100MHz)
  --  m = 9.5, d = 1, outdiv0 = 6.25, outdiv1 = 2
  --  => VCO = 950MHz, pclk = 152MHz, sclk_p/n = 425MHz
  U_MMCM: component mmcme2_adv
    generic map (
      bandwidth            => "OPTIMIZED",
      clkfbout_mult_f      => 9.5,
      clkfbout_phase       => 0.0,
      clkfbout_use_fine_ps => false,
      clkin1_period        => 10.0,
      clkin2_period        => 0.0,
      clkout0_divide_f     => 6.25,
      clkout0_duty_cycle   => 0.5,
      clkout0_phase        => 0.0,
      clkout0_use_fine_ps  => false,
      clkout1_divide       => 2,
      clkout1_duty_cycle   => 0.5,
      clkout1_phase        => 0.0,
      clkout1_use_fine_ps  => false,
      clkout2_divide       => 10,
      clkout2_duty_cycle   => 0.5,
      clkout2_phase        => 0.0,
      clkout2_use_fine_ps  => false,
      clkout3_divide       => 10,
      clkout3_duty_cycle   => 0.5,
      clkout3_phase        => 0.0,
      clkout3_use_fine_ps  => false,
      clkout4_cascade      => false,
      clkout4_divide       => 10,
      clkout4_duty_cycle   => 0.5,
      clkout4_phase        => 0.0,
      clkout4_use_fine_ps  => false,
      clkout5_divide       => 10,
      clkout5_duty_cycle   => 0.5,
      clkout5_phase        => 0.0,
      clkout5_use_fine_ps  => false,
      clkout6_divide       => 10,
      clkout6_duty_cycle   => 0.5,
      clkout6_phase        => 0.0,
      clkout6_use_fine_ps  => false,
      compensation         => "ZHOLD",
      divclk_divide        => 1,
      is_clkinsel_inverted => '0',
      is_psen_inverted     => '0',
      is_psincdec_inverted => '0',
      is_pwrdwn_inverted   => '0',
      is_rst_inverted      => '0',
      ref_jitter1          => 0.01,
      ref_jitter2          => 0.01,
      ss_en                => "FALSE",
      ss_mode              => "CENTER_HIGH",
      ss_mod_period        => 10000,
      startup_wait         => false
    )
    port map (
      pwrdwn               => '0',
      rst                  => mmcm_rst,
      locked               => mmcm_lock_a,
      clkin1               => pclki,
      clkin2               => '0',
      clkinsel             => '1',
      clkinstopped         => open,
      clkfbin              => mmcm_fbi,
      clkfbout             => mmcm_fbo,
      clkfboutb            => open,
      clkfbstopped         => open,
      clkout0              => mmcm_clkout0,
      clkout0b             => open,
      clkout1              => mmcm_clkout1p,
      clkout1b             => mmcm_clkout1n,
      clkout2              => open,
      clkout2b             => open,
      clkout3              => open,
      clkout3b             => open,
      clkout4              => open,
      clkout5              => open,
      clkout6              => open,
      dclk                 => clk,
      daddr                => mmcm_daddr,
      den                  => mmcm_den,
      dwe                  => mmcm_dwe,
      di                   => mmcm_di,
      do                   => mmcm_do,
      drdy                 => mmcm_drdy,
      psclk                => '0',
      psdone               => open,
      psen                 => '0',
      psincdec             => '0'
    );

  U_BUFG_0: component bufg
    port map (
      i => mmcm_clkout0,
      o => pclk
    );

  U_BUFG_1P: component bufg
    port map (
      i => mmcm_clkout1p,
      o => sclk_p
    );

  U_BUFG_1N: component bufg
    port map (
      i => mmcm_clkout1n,
      o => sclk_n
    );

  U_BUFG_FB: component bufg
    port map (
      i => mmcm_fbo,
      o => mmcm_fbi
    );

  pclko <= pclk;

  ----------------------------------------------------------------------
  -- SelectIO input primitives

  GEN_CH: for i in 0 to 2 generate

    U_IDELAY: component idelaye2
      generic map (
        delay_src             => "IDATAIN",   -- Delay input (IDATAIN, DATAIN)
        idelay_type           => "VAR_LOAD",  -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        pipe_sel              => "FALSE",     -- Select pipelined mode, FALSE, TRUE
        idelay_value          => 0,           -- Input delay tap setting (0-31)
        signal_pattern        => "DATA",      -- DATA, CLOCK input signal
        refclk_frequency      => 200.0,       -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        high_performance_mode => "TRUE",      -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
        cinvctrl_sel          => "FALSE"      -- Enable dynamic clock inversion (FALSE, TRUE)
      )
      port map (
        regrst      => '0',                   -- 1-bit input: Active-high reset tap-delay input
        cinvctrl    => '0',                   -- 1-bit input: Dynamic clock inversion input
        c           => clk,                   -- 1-bit input: Clock input
        ce          => '0',                   -- 1-bit input: Active high enable increment/decrement input
        inc         => '0',                   -- 1-bit input: Increment / Decrement tap delay input
        ld          => idelay_ld,             -- 1-bit input: Load IDELAY_VALUE input
        ldpipeen    => '0',                   -- 1-bit input: Enable PIPELINE register to load data input
        cntvaluein  => idelay_tap,            -- 5-bit input: Counter value input
        cntvalueout => open,                  -- 5-bit output: Counter value output
        idatain     => si(i),                 -- 1-bit input: Data input from the I/O
        datain      => '0',                   -- 1-bit input: Internal delay data input
        dataout     => sid(i)                 -- 1-bit output: Delayed data output
      );

    U_ISERDESE2_M: component iserdese2
      generic map (
        serdes_mode       => "MASTER",
        interface_type    => "NETWORKING",
        iobdelay          => "BOTH",
        data_width        => 10,
        data_rate         => "DDR",
        ofb_used          => "FALSE",
        dyn_clkdiv_inv_en => "FALSE",
        dyn_clk_inv_en    => "FALSE",
        num_ce            => 2,
        init_q1           => '0',
        init_q2           => '0',
        init_q3           => '0',
        init_q4           => '0',
        srval_q1          => '0',
        srval_q2          => '0',
        srval_q3          => '0',
        srval_q4          => '0'
      )
      port map (
        rst               => rst,
        dynclksel         => '0',
        clk               => sclk_p,
        clkb              => sclk_n,
        ce1               => '1',
        ce2               => '1',
        dynclkdivsel      => '0',
        clkdiv            => pclk,
        clkdivp           => '0',
        oclk              => '0',
        oclkb             => '1',
        d                 => '0',
        ddly              => sid(i),
        ofb               => '0',
        o                 => open,
        q1                => pi(i)(9),
        q2                => pi(i)(8),
        q3                => pi(i)(7),
        q4                => pi(i)(6),
        q5                => pi(i)(5),
        q6                => pi(i)(4),
        q7                => pi(i)(3),
        q8                => pi(i)(2),
        bitslip           => idelay_slip,
        shiftin1          => '0',
        shiftin2          => '0',
        shiftout1         => shift1(i),
        shiftout2         => shift2(i)
      );

    U_ISERDESE2_S: component iserdese2
      generic map (
        serdes_mode       => "SLAVE",
        interface_type    => "NETWORKING",
        iobdelay          => "BOTH",
        data_width        => 10,
        data_rate         => "DDR",
        ofb_used          => "FALSE",
        dyn_clkdiv_inv_en => "FALSE",
        dyn_clk_inv_en    => "FALSE",
        num_ce            => 2,
        init_q1           => '0',
        init_q2           => '0',
        init_q3           => '0',
        init_q4           => '0',
        srval_q1          => '0',
        srval_q2          => '0',
        srval_q3          => '0',
        srval_q4          => '0'
      )
      port map (
        rst               => rst,
        dynclksel         => '0',
        clk               => sclk_p,
        clkb              => sclk_n,
        ce1               => '1',
        ce2               => '1',
        dynclkdivsel      => '0',
        clkdiv            => pclk,
        clkdivp           => '0',
        oclk              => '0',
        oclkb             => '1',
        d                 => '0',
        ddly              => '0',
        ofb               => '0',
        o                 => open,
        q1                => open,
        q2                => open,
        q3                => pi(i)(1),
        q4                => pi(i)(0),
        q5                => open,
        q6                => open,
        q7                => open,
        q8                => open,
        bitslip           => open,
        shiftin1          => shift1(i),
        shiftin2          => shift2(i),
        shiftout1         => open,
        shiftout2         => open
      );

  end generate GEN_CH;

  ----------------------------------------------------------------------

end architecture synth;

