--------------------------------------------------------------------------------
-- mmcm_drp.vhd                                                               --
-- Dynamically configured MMCM.                                               --
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

use work.tyto_types_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package mmcm_drp_pkg is

  type mmcm_drp_odiv_t   is array (1 to 6) of integer range 1 to 128;
  type mmcm_drp_oduty_t  is array (0 to 6) of real range 0.01 to 0.99;
  type mmcm_drp_ophase_t is array (0 to 6) of real range 0.0 to 360.0;

  type mmcm_drp_init_t is record
    tck    : real;
    mul    : real;
    div    : integer range 1 to 106;
    odiv0  : real range 2.0 to 128.0;
    odiv   : mmcm_drp_odiv_t;
    oduty  : mmcm_drp_oduty_t;
    ophase : mmcm_drp_ophase_t;
  end record mmcm_drp_init_t;

  constant MMCM_DRP_INIT : mmcm_drp_init_t := (
    tck    => 10.0,
    mul    => 10.0,
    div    => 1,
    odiv0  => 128.0,
    odiv   => (others => 128),
    oduty  => (others => 0.5),
    ophase => (others => 0.0)
  );

  component mmcm_drp is
    generic (
      TABLE : sulv_vector;
      INIT  : mmcm_drp_init_t;
      BW    : string := "OPTIMIZED"
    );
    port (
      rsti      : in    std_ulogic;
      clki      : in    std_ulogic;
      sel       : in    std_ulogic_vector(1 downto 0);
      rsto      : out   std_ulogic;
      clko0     : out   std_ulogic;
      clko1     : out   std_ulogic;
      clko2     : out   std_ulogic;
      clko3     : out   std_ulogic;
      clko4     : out   std_ulogic;
      clko5     : out   std_ulogic;
      clko6     : out   std_ulogic
    );
  end component mmcm_drp;

end package mmcm_drp_pkg;

----------------------------------------------------------------------

use work.tyto_types_pkg.all;
use work.tyto_utils_pkg.all;
use work.sync_pkg.all;
use work.mmcm_drp_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity mmcm_drp is
  generic (
    TABLE : sulv_vector;
    INIT  : mmcm_drp_init_t;
    BW    : string := "OPTIMIZED"
  );
  port (
    rsti      : in    std_ulogic;               -- input (reference) clock synchronous reset
    clki      : in    std_ulogic;               -- input (reference) clock
    sel       : in    std_ulogic_vector;        -- output clock select
    rsto      : out   std_ulogic;               -- output reset (asynchronous)
    clko0     : out   std_ulogic;               -- output clocks
    clko1     : out   std_ulogic;
    clko2     : out   std_ulogic;
    clko3     : out   std_ulogic;
    clko4     : out   std_ulogic;
    clko5     : out   std_ulogic;
    clko6     : out   std_ulogic
  );
end entity mmcm_drp;

architecture rtl of mmcm_drp is

  constant AMSB : integer := log2(TABLE'length)-1;

  signal sel_s        : std_ulogic_vector(1 downto 0);    -- sel, synchronised to clki

  signal rsto_req     : std_ulogic;                       -- rsto request, synchronous to clki

  signal mmcm_rst     : std_ulogic;                       -- MMCM reset
  signal locked       : std_ulogic;                       -- MMCM locked output
  signal locked_s     : std_ulogic;                       -- above, synchronised to clki

  signal sel_prev     : std_ulogic_vector(2 downto 0);    -- to detect changes
  signal clk_fb       : std_ulogic;                       -- feedback clock
  signal clku_fb      : std_ulogic;                       -- unbuffered feedback clock
  signal clko_u       : std_ulogic_vector(0 to 6);        -- unbuffered output clock

  signal cfg_tbl_addr : std_ulogic_vector(AMSB downto 0); -- table address
  signal cfg_tbl_data : std_ulogic_vector(39 downto 0);   -- table data = 8 bit address + 16 bit write data + 16 bit read mask

  signal cfg_rst      : std_ulogic;                       -- DRP reset
  signal cfg_daddr    : std_ulogic_vector(6 downto 0);    -- DRP register address
  signal cfg_den      : std_ulogic;                       -- DRP enable (pulse)
  signal cfg_dwe      : std_ulogic;                       -- DRP write enable
  signal cfg_di       : std_ulogic_vector(15 downto 0);   -- DRP write data
  signal cfg_do       : std_ulogic_vector(15 downto 0);   -- DRP read data
  signal cfg_drdy     : std_ulogic;                       -- DRP access complete

  signal clko         : std_ulogic_vector(0 to 6);        -- output clocks


  type cfg_state_t is (                                   -- state machine states
    IDLE,                                                 -- waiting for fsel change
    RESET,                                                -- put MMCM into reset
    TBL,                                                  -- get first/next table value
    RD,                                                   -- start read
    RD_WAIT,                                              -- wait for read to complete
    WR,                                                   -- start write
    WR_WAIT,                                              -- wait for write to complete
    LOCK_WAIT                                             -- wait for reconfig to complete
  );
  signal cfg_state : cfg_state_t;

begin

  MAIN: process (rsti,clki) is
  begin

    if rsti = '1' then                                                                                                           -- full reset

      sel_prev  <= (others => '1');                                                                                              -- force reconfig
      cfg_rst   <= '1';
      cfg_daddr <= (others => '0');
      cfg_den   <= '0';
      cfg_dwe   <= '0';
      cfg_di    <= (others => '0');
      cfg_state <= RESET;

      rsto_req <= '1';

    elsif rising_edge(clki) then

      -- defaults
      cfg_den <= '0';
      cfg_dwe <= '0';

      -- state machine
      case cfg_state is
        when IDLE =>
          if '0' & sel_s /= sel_prev                                                                                               -- frequency selection has changed (or initial startup)
             or locked_s = '0'                                                                                                     -- lock lost
             then
            rsto_req  <= '1';
            cfg_rst   <= '1';
            cfg_state <= RESET;
          end if;
        when RESET =>                                                                                                              -- put MMCM into reset
          sel_prev     <= '0' & sel_s;
          cfg_tbl_addr <= sel_s & "00000";
          cfg_state    <= TBL;
        when TBL =>                                                                                                                -- get table entry from sychronous ROM
          cfg_state <= RD;
        when RD =>                                                                                                                 -- read specified register
          cfg_daddr <= cfg_tbl_data(38 downto 32);
          cfg_den   <= '1';
          cfg_state <= RD_WAIT;
        when RD_WAIT =>                                                                                                            -- wait for read to complete
          if cfg_drdy = '1' then
            cfg_di    <= (cfg_do and cfg_tbl_data(15 downto 0)) or (cfg_tbl_data(31 downto 16) and not cfg_tbl_data(15 downto 0));
            cfg_den   <= '1';
            cfg_dwe   <= '1';
            cfg_state <= WR;
          end if;
        when WR =>                                                                                                                 -- write modified contents back to same register
          cfg_state <= WR_WAIT;
        when WR_WAIT =>                                                                                                            -- wait for write to complete
          if cfg_drdy = '1' then
            if cfg_tbl_data(39) = '1' then                                                                                         -- last entry in table
              cfg_tbl_addr <= (others => '0');
              cfg_state    <= LOCK_WAIT;
            else                                                                                                                   -- do next entry in table
              cfg_tbl_addr(4 downto 0) <= std_ulogic_vector(unsigned(cfg_tbl_addr(4 downto 0)) + 1);
              cfg_state                <= TBL;
            end if;
          end if;
        when LOCK_WAIT =>                                                                                                          -- wait for MMCM to lock
          cfg_rst <= '0';
          if locked_s = '1' then                                                                                                   -- all done
            cfg_state <= IDLE;
            rsto_req  <= '0';
          end if;
      end case;

    end if;

    if rising_edge(clki) then
      cfg_tbl_data <= TABLE(to_integer(unsigned(cfg_tbl_addr)));                                                                   -- synchronous ROM
    end if;

  end process MAIN;

  -- clock domain crossing

  CDC : component sync
    generic map (
      WIDTH => 3
    )
    port map (
      rst   => rsti,
      clk   => clki,
      i(0)  => locked,
      i(1)  => sel(0),
      i(2)  => sel(1),
      o(0)  => locked_s,
      o(1)  => sel_s(0),
      o(2)  => sel_s(1)
    );

  mmcm_rst <= cfg_rst or rsti;
  rsto <= rsto_req or not locked or mmcm_rst;

  MMCM: component mmcme2_adv
    generic map (
      bandwidth            => BW,
      clkfbout_mult_f      => INIT.mul,
      clkfbout_phase       => 0.0,
      clkfbout_use_fine_ps => false,
      clkin1_period        => INIT.tck,
      clkin2_period        => 0.0,
      clkout0_divide_f     => INIT.odiv0,
      clkout0_duty_cycle   => INIT.oduty(0),
      clkout0_phase        => INIT.ophase(0),
      clkout0_use_fine_ps  => false,
      clkout1_divide       => INIT.odiv(1),
      clkout1_duty_cycle   => INIT.oduty(1),
      clkout1_phase        => INIT.ophase(1),
      clkout1_use_fine_ps  => false,
      clkout2_divide       => INIT.odiv(2),
      clkout2_duty_cycle   => INIT.oduty(2),
      clkout2_phase        => INIT.ophase(2),
      clkout2_use_fine_ps  => false,
      clkout3_divide       => INIT.odiv(3),
      clkout3_duty_cycle   => INIT.oduty(3),
      clkout3_phase        => INIT.ophase(3),
      clkout3_use_fine_ps  => false,
      clkout4_cascade      => false,
      clkout4_divide       => INIT.odiv(4),
      clkout4_duty_cycle   => INIT.oduty(4),
      clkout4_phase        => INIT.ophase(4),
      clkout4_use_fine_ps  => false,
      clkout5_divide       => INIT.odiv(5),
      clkout5_duty_cycle   => INIT.oduty(5),
      clkout5_phase        => INIT.ophase(5),
      clkout5_use_fine_ps  => false,
      clkout6_divide       => INIT.odiv(6),
      clkout6_duty_cycle   => INIT.oduty(6),
      clkout6_phase        => INIT.ophase(6),
      clkout6_use_fine_ps  => false,
      compensation         => "ZHOLD",
      divclk_divide        => INIT.div,
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
      locked               => locked,
      clkin1               => clki,
      clkin2               => '0',
      clkinsel             => '1',
      clkinstopped         => open,
      clkfbin              => clk_fb,
      clkfbout             => clku_fb,
      clkfboutb            => open,
      clkfbstopped         => open,
      clkout0              => clko_u(0),
      clkout0b             => open,
      clkout1              => clko_u(1),
      clkout1b             => open,
      clkout2              => clko_u(2),
      clkout2b             => open,
      clkout3              => clko_u(3),
      clkout3b             => open,
      clkout4              => clko_u(4),
      clkout5              => clko_u(5),
      clkout6              => clko_u(6),
      dclk                 => clki,
      daddr                => cfg_daddr,
      den                  => cfg_den,
      dwe                  => cfg_dwe,
      di                   => cfg_di,
      do                   => cfg_do,
      drdy                 => cfg_drdy,
      psclk                => '0',
      psdone               => open,
      psen                 => '0',
      psincdec             => '0'
    );

  U_BUFG_F: component bufg
    port map (
      i => clku_fb,
      o => clk_fb
    );

  GEN_O: for i in 0 to 6 generate
    U_BUFG_0: component bufg
      port map (
        i => clko_u(i),
        o => clko(i)
      );
  end generate GEN_O;

  clko0 <= clko(0);
  clko1 <= clko(1);
  clko2 <= clko(2);
  clko3 <= clko(3);
  clko4 <= clko(4);
  clko5 <= clko(5);
  clko6 <= clko(6);

end architecture rtl;
