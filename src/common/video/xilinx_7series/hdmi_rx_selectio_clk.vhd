--------------------------------------------------------------------------------
-- hdmi_rx_selectio_clk.vhd                                                   --
-- HDMI sink front end built on Xilinx 7 Series SelectIO primitives -         --
--  clock generation module.                                                  --
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

package hdmi_rx_selectio_clk_pkg is

  type hdmi_rx_selectio_clk_status_t is record
      count_freq : std_logic_vector(31 downto 0);
      band       : std_logic_vector(1 downto 0);
      lock       : std_logic;
  end record hdmi_rx_selectio_clk_status_t;

  component hdmi_rx_selectio_clk is
    generic (
      fclk    : real
    );
    port (
      rst     : in    std_logic;
      clk     : in    std_logic;
      pclki   : in    std_logic;
      prsto   : out   std_logic;
      pclko   : out   std_logic;
      sclko   : out   std_logic;
      status  : out   hdmi_rx_selectio_clk_status_t
    );
  end component hdmi_rx_selectio_clk;

end package hdmi_rx_selectio_clk_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.hdmi_rx_selectio_clk_pkg.all;
  use work.hdmi_rx_selectio_fm_pkg.all;

entity hdmi_rx_selectio_clk is
  generic (
    fclk    : real
  );
  port (
    rst     : in    std_logic;
    clk     : in    std_logic;
    pclki   : in    std_logic;
    prsto   : out   std_logic;
    pclko   : out   std_logic;
    sclko   : out   std_logic;
    status  : out   hdmi_rx_selectio_clk_status_t
  );
end entity hdmi_rx_selectio_clk;

architecture synth of hdmi_rx_selectio_clk is

  type drp_state_t is (
    DRP_LOCKED,    -- wait for loss of lock or frequency change
    DRP_UNLOCKING, -- wait for frequency change
    DRP_UNLOCKED,  -- wait for frequency change
    DRP_RESET,     -- put MMCM into reset
    DRP_TBL,       -- get first/next table value
    DRP_RD,        -- start read
    DRP_RD_WAIT,   -- wait for read to complete
    DRP_WR,        -- start write
    DRP_WR_WAIT,   -- wait for write to complete
    DRP_LOCK_WAIT  -- wait for reconfig to complete
  );

  -- frequency measurement
  signal fm_f    : integer range 0 to FM_FCOUNT_MAX;
  signal fm_ok   : std_logic;

  -- MMCM (DRP = Dynamic Reconfiguration Port)
  signal mmcm_rst       : std_logic;                        -- reset
  signal mmcm_clkout0   : std_logic;                        -- clkout0
  signal mmcm_clkout1   : std_logic;                        -- clkout1
  signal mmcm_fbo       : std_logic;                        -- feedback clock out
  signal mmcm_fbi       : std_logic;                        -- feedback clock in
  signal mmcm_lock_a    : std_logic;                        -- lock (asynchronous)
  signal mmcm_lock_s    : std_logic_vector(0 to 1);         -- lock synchroniser
  alias  mmcm_lock      : std_logic is mmcm_lock_s(1);
  signal drp_daddr      : std_logic_vector(6 downto 0);     -- DRP register address
  signal drp_den        : std_logic;                        -- DRP enable (pulse)
  signal drp_dwe        : std_logic;                        -- DRP write enable
  signal drp_di         : std_logic_vector(15 downto 0);    -- DRP write data
  signal drp_do         : std_logic_vector(15 downto 0);    -- DRP read data
  signal drp_drdy       : std_logic;                        -- DRP access complete
  signal drp_tbl_a      : std_logic_vector(6 downto 0);     -- DRP table address (4 x 32 = 128 entries)
  signal drp_tbl_d      : std_logic_vector(39 downto 0);    -- DRP data: 8 bit register address + 16 bit write data + 16 bit read mask
  signal drp_state      : drp_state_t;                      -- DRP state machine
  signal prst_a         : std_logic;                        -- pclk domain reset before synchronisation
  signal prst_s         : std_logic_vector(0 to 1);         -- pclk domain reset synchroniser
  signal pclk           : std_logic;

  attribute async_reg : string;
  attribute async_reg of mmcm_lock_s : signal is "TRUE";
  attribute async_reg of prst_s      : signal is "TRUE";

begin

  pclko <= pclk;
  status.count_freq <= std_logic_vector(to_unsigned(fm_f,32));

  -- frequency measurement
  U_FM: component hdmi_rx_selectio_fm
    generic map (
      fclk => fclk
    )
    port map (
      rst  => rst,
      clk  => clk,
      mclk => pclki,
      mf   => fm_f,
      mok  => fm_ok
    );

  -- reconfigure MMCM when after loss of lock or changes in frequency
  process (rst,clk) is
    -- contents of synchronous ROM table
    function drp_tbl (addr : std_logic_vector) return std_logic_vector is
      -- bits 39..32 = drp_daddr (MSB = 1 for last entry)
      -- bits 31..16 = cfg write data
      -- bits 15..0 = cfg read mask
      variable data : std_logic_vector(39 downto 0);
    begin
      data := x"0000000000";
      -- values below pasted in from video_out_clk.xls
      case '0' & addr is
        when x"00" => data := x"06" & x"1145" & x"1000";
        when x"01" => data := x"07" & x"0000" & x"8000";
        when x"02" => data := x"08" & x"130D" & x"1000";
        when x"03" => data := x"09" & x"0080" & x"8000";
        when x"04" => data := x"0A" & x"1083" & x"1000";
        when x"05" => data := x"0B" & x"0080" & x"8000";
        when x"06" => data := x"0C" & x"1145" & x"1000";
        when x"07" => data := x"0D" & x"0000" & x"8000";
        when x"08" => data := x"0E" & x"1145" & x"1000";
        when x"09" => data := x"0F" & x"0000" & x"8000";
        when x"0A" => data := x"10" & x"1145" & x"1000";
        when x"0B" => data := x"11" & x"0000" & x"8000";
        when x"0C" => data := x"12" & x"1145" & x"1000";
        when x"0D" => data := x"13" & x"0000" & x"8000";
        when x"0E" => data := x"14" & x"130D" & x"1000";
        when x"0F" => data := x"15" & x"0080" & x"8000";
        when x"10" => data := x"16" & x"1041" & x"C000";
        when x"11" => data := x"18" & x"0090" & x"FC00";
        when x"12" => data := x"19" & x"7C01" & x"8000";
        when x"13" => data := x"1A" & x"7DE9" & x"8000";
        when x"14" => data := x"28" & x"FFFF" & x"0000";
        when x"15" => data := x"4E" & x"1100" & x"66FF";
        when x"16" => data := x"CF" & x"9000" & x"666F";
        when x"20" => data := x"06" & x"1145" & x"1000";
        when x"21" => data := x"07" & x"0000" & x"8000";
        when x"22" => data := x"08" & x"11C8" & x"1000";
        when x"23" => data := x"09" & x"0080" & x"8000";
        when x"24" => data := x"0A" & x"1042" & x"1000";
        when x"25" => data := x"0B" & x"0080" & x"8000";
        when x"26" => data := x"0C" & x"1145" & x"1000";
        when x"27" => data := x"0D" & x"0000" & x"8000";
        when x"28" => data := x"0E" & x"1145" & x"1000";
        when x"29" => data := x"0F" & x"0000" & x"8000";
        when x"2A" => data := x"10" & x"1145" & x"1000";
        when x"2B" => data := x"11" & x"0000" & x"8000";
        when x"2C" => data := x"12" & x"1145" & x"1000";
        when x"2D" => data := x"13" & x"0000" & x"8000";
        when x"2E" => data := x"14" & x"11C8" & x"1000";
        when x"2F" => data := x"15" & x"0080" & x"8000";
        when x"30" => data := x"16" & x"1041" & x"C000";
        when x"31" => data := x"18" & x"018A" & x"FC00";
        when x"32" => data := x"19" & x"7C01" & x"8000";
        when x"33" => data := x"1A" & x"7DE9" & x"8000";
        when x"34" => data := x"28" & x"FFFF" & x"0000";
        when x"35" => data := x"4E" & x"9900" & x"66FF";
        when x"36" => data := x"CF" & x"8100" & x"666F";
        when x"40" => data := x"06" & x"1145" & x"1000";
        when x"41" => data := x"07" & x"0000" & x"8000";
        when x"42" => data := x"08" & x"1145" & x"1000";
        when x"43" => data := x"09" & x"0000" & x"8000";
        when x"44" => data := x"0A" & x"1041" & x"1000";
        when x"45" => data := x"0B" & x"0000" & x"8000";
        when x"46" => data := x"0C" & x"1145" & x"1000";
        when x"47" => data := x"0D" & x"0000" & x"8000";
        when x"48" => data := x"0E" & x"1145" & x"1000";
        when x"49" => data := x"0F" & x"0000" & x"8000";
        when x"4A" => data := x"10" & x"1145" & x"1000";
        when x"4B" => data := x"11" & x"0000" & x"8000";
        when x"4C" => data := x"12" & x"1145" & x"1000";
        when x"4D" => data := x"13" & x"0000" & x"8000";
        when x"4E" => data := x"14" & x"1145" & x"1000";
        when x"4F" => data := x"15" & x"0000" & x"8000";
        when x"50" => data := x"16" & x"1041" & x"C000";
        when x"51" => data := x"18" & x"01E8" & x"FC00";
        when x"52" => data := x"19" & x"7001" & x"8000";
        when x"53" => data := x"1A" & x"71E9" & x"8000";
        when x"54" => data := x"28" & x"FFFF" & x"0000";
        when x"55" => data := x"4E" & x"9900" & x"66FF";
        when x"56" => data := x"CF" & x"1100" & x"666F";
        when x"60" => data := x"06" & x"1145" & x"1000";
        when x"61" => data := x"07" & x"0000" & x"8000";
        when x"62" => data := x"08" & x"1083" & x"1000";
        when x"63" => data := x"09" & x"0080" & x"8000";
        when x"64" => data := x"0A" & x"1041" & x"1000";
        when x"65" => data := x"0B" & x"00C0" & x"8000";
        when x"66" => data := x"0C" & x"1145" & x"1000";
        when x"67" => data := x"0D" & x"0000" & x"8000";
        when x"68" => data := x"0E" & x"1145" & x"1000";
        when x"69" => data := x"0F" & x"0000" & x"8000";
        when x"6A" => data := x"10" & x"1145" & x"1000";
        when x"6B" => data := x"11" & x"0000" & x"8000";
        when x"6C" => data := x"12" & x"1145" & x"1000";
        when x"6D" => data := x"13" & x"0000" & x"8000";
        when x"6E" => data := x"14" & x"1083" & x"1000";
        when x"6F" => data := x"15" & x"0080" & x"8000";
        when x"70" => data := x"16" & x"1041" & x"C000";
        when x"71" => data := x"18" & x"01E8" & x"FC00";
        when x"72" => data := x"19" & x"3801" & x"8000";
        when x"73" => data := x"1A" & x"39E9" & x"8000";
        when x"74" => data := x"28" & x"FFFF" & x"0000";
        when x"75" => data := x"4E" & x"9100" & x"66FF";
        when x"76" => data := x"CF" & x"1900" & x"666F";
        when others => data := (others => '0');
      end case;
      return data;
    end function drp_tbl;
  begin
    if rst = '1' then -- full reset
        mmcm_lock_s <= (others => '0');
        mmcm_rst    <= '1';
        drp_daddr   <= (others => '0');
        drp_den     <= '0';
        drp_dwe     <= '0';
        drp_di      <= (others => '0');
        drp_state   <= DRP_UNLOCKED;
        status.lock <= '0';
        status.band <= (others => '0');
    elsif rising_edge(clk) then
      drp_tbl_d <= drp_tbl(drp_tbl_a); -- synchronous ROM
      mmcm_lock_s(0 to 1) <= mmcm_lock_a & mmcm_lock_s(0); -- synchroniser
      -- defaults
      drp_den <= '0';
      drp_dwe <= '0';
      -- state machine
      case drp_state is
        when DRP_LOCKED =>
          if fm_ok = '0' then
            mmcm_rst    <= '1';
            status.lock <= '0';
            drp_state   <= DRP_UNLOCKED;
          elsif mmcm_lock = '0' then
            mmcm_rst    <= '1';
            status.lock <= '0';
            drp_state   <= DRP_UNLOCKING;
          end if;
        when DRP_UNLOCKING =>
          if fm_ok = '0' then
            drp_state <= DRP_UNLOCKED;
          end if;
        when DRP_UNLOCKED =>
          if fm_ok = '1' then
            drp_state <= DRP_RESET;
          end if;
        when DRP_RESET =>
          -- program for correct frequency range
          drp_tbl_a <= (others => '0');
          if fm_f > FM_FCOUNT_120M then
            drp_tbl_a(6 downto 5) <= "11";
          elsif fm_f > FM_FCOUNT_70M then
            drp_tbl_a(6 downto 5) <= "10";
          elsif fm_f > FM_FCOUNT_44M then
            drp_tbl_a(6 downto 5) <= "01";
          end if;
          if fm_f >= FM_FCOUNT_24M then -- catch low frequencies
            drp_state <= DRP_TBL;
          end if;
        when DRP_TBL => -- get table entry from sychronous ROM
          status.band <= drp_tbl_a(6 downto 5);
          drp_state   <= DRP_RD;
        when DRP_RD => -- read specified register
          drp_daddr <= drp_tbl_d(38 downto 32);
          drp_den   <= '1';
          drp_state <= DRP_RD_WAIT;
        when DRP_RD_WAIT => -- wait for read to complete
          if drp_drdy = '1' then
            drp_di   <= (drp_do and drp_tbl_d(15 downto 0)) or (drp_tbl_d(31 downto 16) and not drp_tbl_d(15 downto 0));
            drp_den  <= '1';
            drp_dwe  <= '1';
            drp_state <= DRP_WR;
          end if;
        when DRP_WR => -- write modified contents back to same register
          drp_state <= DRP_WR_WAIT;
        when DRP_WR_WAIT => -- wait for write to complete
          if drp_drdy = '1' then
            if drp_tbl_d(39) = '1' then -- last entry in table
              drp_tbl_a <= (others => '0');
              drp_state <= DRP_LOCK_WAIT;
            else -- do next entry in table
              drp_tbl_a(4 downto 0) <= std_logic_vector(unsigned(drp_tbl_a(4 downto 0)) + 1);
              drp_state                <= DRP_TBL;
            end if;
          end if;
        when DRP_LOCK_WAIT => -- wait for MMCM to lock
          mmcm_rst <= '0';
          if mmcm_lock = '1' then -- all done
            status.lock <= '1';
            drp_state   <= DRP_LOCKED;
          end if;
      end case;
    end if;
  end process;

  -- pclk domain reset
  prst_a <= '1' when rst = '1' or drp_state /= DRP_LOCKED or mmcm_lock_a = '0' else '0';
  process(prst_a,pclk)
  begin
    if prst_a = '1' then
      prst_s <= (others => '1');
      prsto  <= '1';
    elsif rising_edge(pclk) then
      prst_s <= prst_a & prst_s(0);
      prsto  <= prst_s(1);
    end if;
  end process;

  -- MMCM
  -- The 7 series LVDS serdes is rated at as follows for DDR outputs:
  --  1200Mbps max for -2 speed grade
  --  950Mbps max for -1 speed grade
  -- 1485Mbps (full HD) overclocks these, so we use a fictional static
  -- recipe for the MMCM to achieve timing closure:
  --  clkin1_period = 10ns (100MHz)
  --  m = 8.5, d = 1, outdiv0 = 5.6125, outdiv1 = 2
  --  => VCO = 850MHz, pclk = 151.11MHz, sclk_p/n = 425MHz
  U_MMCM: component mmcme2_adv
    generic map (
      bandwidth            => "OPTIMIZED",
      clkfbout_mult_f      => 8.5,
      clkfbout_phase       => 0.0,
      clkfbout_use_fine_ps => false,
      clkin1_period        => 10.0,
      clkin2_period        => 0.0,
      clkout0_divide_f     => 5.625,
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
      clkout1              => mmcm_clkout1,
      clkout1b             => open,
      clkout2              => open,
      clkout2b             => open,
      clkout3              => open,
      clkout3b             => open,
      clkout4              => open,
      clkout5              => open,
      clkout6              => open,
      dclk                 => clk,
      daddr                => drp_daddr,
      den                  => drp_den,
      dwe                  => drp_dwe,
      di                   => drp_di,
      do                   => drp_do,
      drdy                 => drp_drdy,
      psclk                => '0',
      psdone               => open,
      psen                 => '0',
      psincdec             => '0'
    );

  -- buffers
  U_BUFG_0: component bufg
    port map (
      i => mmcm_clkout0,
      o => pclk
    );
  U_BUFG_1: component bufg
    port map (
      i => mmcm_clkout1,
      o => sclko
    );
  U_BUFG_FB: component bufg
    port map (
      i => mmcm_fbo,
      o => mmcm_fbi
    );

end architecture synth;
