--------------------------------------------------------------------------------
-- tmds_cap_csr.vhd                                                           --
-- Control and status registers for the tmds_cap design.                      --
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

library work;
  --use work.tyto_types_pkg.all;
  use work.axi4_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;

package tmds_cap_csr_pkg is

  constant RA_SIGNATURE : std_logic_vector(7 downto 0) := x"00"; -- signature value
  constant RA_FREQ      : std_logic_vector(7 downto 0) := x"04"; -- pixel clock frequency count
  constant RA_ASTAT     : std_logic_vector(7 downto 0) := x"08"; -- alignment status
  constant RA_ATAPMASK0 : std_logic_vector(7 downto 0) := x"10"; -- alignment tap mask (channel 0)
  constant RA_ATAPMASK1 : std_logic_vector(7 downto 0) := x"14"; -- alignment tap mask (channel 1)
  constant RA_ATAPMASK2 : std_logic_vector(7 downto 0) := x"18"; -- alignment tap mask (channel 2)
  constant RA_ATAP      : std_logic_vector(7 downto 0) := x"20"; -- alignment: chosen taps
  constant RA_ABITSLIP  : std_logic_vector(7 downto 0) := x"24"; -- alignment: bit slip positions
  constant RA_ACYCLE0   : std_logic_vector(7 downto 0) := x"30"; -- alignment cycle count (channel 0)
  constant RA_ACYCLE1   : std_logic_vector(7 downto 0) := x"34"; -- alignment cycle count (channel 1)
  constant RA_ACYCLE2   : std_logic_vector(7 downto 0) := x"38"; -- alignment cycle count (channel 2)
  constant RA_ATAPOK0   : std_logic_vector(7 downto 0) := x"40"; -- alignment tap OK count (channel 0)
  constant RA_ATAPOK1   : std_logic_vector(7 downto 0) := x"44"; -- alignment tap OK count (channel 1)
  constant RA_ATAPOK2   : std_logic_vector(7 downto 0) := x"48"; -- alignment tap OK count (channel 2)
  constant RA_AGAIN0    : std_logic_vector(7 downto 0) := x"50"; -- serial alignment gain count (channel 0)
  constant RA_AGAIN1    : std_logic_vector(7 downto 0) := x"54"; -- serial alignment gain count (channel 1)
  constant RA_AGAIN2    : std_logic_vector(7 downto 0) := x"58"; -- serial alignment gain count (channel 2)
  constant RA_AGAINP    : std_logic_vector(7 downto 0) := x"5C"; -- parallel alignment gain count
  constant RA_ALOSS0    : std_logic_vector(7 downto 0) := x"60"; -- serial alignment loss count (channel 0)
  constant RA_ALOSS1    : std_logic_vector(7 downto 0) := x"64"; -- serial alignment loss count (channel 1)
  constant RA_ALOSS2    : std_logic_vector(7 downto 0) := x"68"; -- serial alignment loss count (channel 2)
  constant RA_ALOSSP    : std_logic_vector(7 downto 0) := x"6C"; -- parallel alignment loss count

  constant RA_CAPCTRL   : std_logic_vector(7 downto 0) := x"80"; -- capture control (reset, go)
  constant RA_CAPSIZE   : std_logic_vector(7 downto 0) := x"84"; -- capture size (pixels)
  constant RA_CAPSTAT   : std_logic_vector(7 downto 0) := x"88"; -- capture status (run, loss, ovf, unf)
  constant RA_CAPCOUNT  : std_logic_vector(7 downto 0) := x"8C"; -- capture count (pixels)

  constant RA_SCRATCH   : std_logic_vector(7 downto 0) := x"FC"; -- scratch register

  component tmds_cap_csr is
    port (

      axi_clk     : in    std_logic;
      axi_rst_n   : in    std_logic;
      saxi_mosi   : in    axi4_a32d32_h_mosi_t := AXI4_A32D32_H_MOSI_DEFAULT;
      saxi_miso   : out   axi4_a32d32_h_miso_t := AXI4_A32D32_H_MISO_DEFAULT;

      tmds_status : in    hdmi_rx_selectio_status_t;

      cap_rst     : out   std_logic;
      cap_size    : out   std_logic_vector(31 downto 0);
      cap_en      : out   std_logic;
      cap_test    : out   std_logic;
      cap_run     : in    std_logic;
      cap_loss    : in    std_logic;
      cap_ovf     : in    std_logic;
      cap_unf     : in    std_logic;
      cap_count   : in    std_logic_vector(31 downto 0)

    );
  end component tmds_cap_csr;

end package tmds_cap_csr_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi4_pkg.all;
  use work.axi4_a32d32_srw32_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.tmds_cap_csr_pkg.all;

entity tmds_cap_csr is
  port (

    axi_clk     : in    std_logic;                                          -- AXI clock
    axi_rst_n   : in    std_logic;                                          -- AXI reset (active low)
    saxi_mosi   : in    axi4_a32d32_h_mosi_t := AXI4_A32D32_H_MOSI_DEFAULT; -- AXI4 subordinate inputs
    saxi_miso   : out   axi4_a32d32_h_miso_t := AXI4_A32D32_H_MISO_DEFAULT; -- AXI4 subordinate outputs

    tmds_status : in    hdmi_rx_selectio_status_t;                          -- TMDS receive (alignment) status

    cap_rst     : out   std_logic;                                          -- capture reset
    cap_size    : out   std_logic_vector(31 downto 0);                      -- capture size (pixels)
    cap_en      : out   std_logic;                                          -- capture enable
    cap_test    : out   std_logic;                                          -- capture test
    cap_run     : in    std_logic;                                          -- capture running
    cap_loss    : in    std_logic;                                          -- capture loss of TMDS lock
    cap_ovf     : in    std_logic;                                          -- capture FIFO overflow
    cap_unf     : in    std_logic;                                          -- capture FIFO underflow
    cap_count   : in    std_logic_vector(31 downto 0)                       -- capture count (pixels)

  );
end entity tmds_cap_csr;

architecture synth of tmds_cap_csr is

  constant addr_width: integer := 8;

  signal sw_en   : std_logic;
  signal sw_addr : std_logic_vector(addr_width-1 downto 0);
  signal sw_be   : std_logic_vector(3 downto 0);
  signal sw_data : std_logic_vector(31 downto 0);
  signal sw_rdy  : std_logic;
  signal sr_en   : std_logic;
  signal sr_addr : std_logic_vector(addr_width-1 downto 0);
  signal sr_data : std_logic_vector(31 downto 0);
  signal sr_rdy  : std_logic;

  signal tmds_status_s1 : hdmi_rx_selectio_status_t;      -- tmds_status synchroniser registers (first level)
  signal tmds_status_s2 : hdmi_rx_selectio_status_t;      -- tmds_status synchroniser registers (second level)
  alias  s : hdmi_rx_selectio_status_t is tmds_status_s2;

  signal scratch : std_logic_vector(31 downto 0);        -- scratch register

begin

  -- AXI4 to simple read/write bridge
  U_BRIDGE: component axi4_a32d32_srw32
    generic map (
      addr_width => addr_width
    )
    port map (
      clk     => axi_clk,
      rst_n   => axi_rst_n,
      axi4_si => saxi_mosi,
      axi4_so => saxi_miso,
      sw_en   => sw_en,
      sw_addr => sw_addr,
      sw_be   => sw_be,
      sw_data => sw_data,
      sw_rdy  => sw_rdy,
      sr_en   => sr_en,
      sr_addr => sr_addr,
      sr_data => sr_data,
      sr_rdy  => sr_rdy
    );

  -- synchronisers
  process(axi_clk)
  begin
    if rising_edge(axi_clk) then
      tmds_status_s1 <= tmds_status;
      tmds_status_s2 <= tmds_status_s1;
    end if;
  end process;

  -- register read/write

  sw_rdy <= '1';

  process(axi_rst_n,axi_clk)
  begin
    if axi_rst_n = '0' then

      cap_rst  <= '1';
      cap_en   <= '0';
      cap_size <= (others => '0');
      scratch  <= (others => '0');
      sr_data  <= (others => '0');

    elsif rising_edge(axi_clk) then

      -- write
      if sw_en = '1' then
        case sw_addr is
          when RA_CAPCTRL =>
            cap_en   <= sw_data(0)  when sw_be(0) = '1';
            cap_test <= sw_data(1)  when sw_be(0) = '1';
            cap_rst  <= sw_data(31) when sw_be(3) = '1';
          when RA_CAPSIZE =>
            cap_size(  7 downto  0 ) <= sw_data(  7 downto  0 ) when sw_be(0) = '1';
            cap_size( 15 downto  7 ) <= sw_data( 15 downto  7 ) when sw_be(1) = '1';
            cap_size( 23 downto 16 ) <= sw_data( 23 downto 16 ) when sw_be(2) = '1';
            cap_size( 31 downto 24 ) <= sw_data( 31 downto 24 ) when sw_be(3) = '1';
          when RA_SCRATCH =>
            scratch(  7 downto  0 ) <= sw_data(  7 downto  0 ) when sw_be(0) = '1';
            scratch( 15 downto  7 ) <= sw_data( 15 downto  7 ) when sw_be(1) = '1';
            scratch( 23 downto 16 ) <= sw_data( 23 downto 16 ) when sw_be(2) = '1';
            scratch( 31 downto 24 ) <= sw_data( 31 downto 24 ) when sw_be(3) = '1';
          when others =>
            null;
        end case;
      end if;

      -- read
      if sr_en = '1' and sr_rdy = '0' then
        sr_rdy <= '1';
        with sr_addr select sr_data <=
          x"53444D54"                                                    when RA_SIGNATURE,
          s.count_freq                                                   when RA_FREQ,
          x"00000" & '0' &
          s.skew_p(2) & s.skew_p(1) &
          s.align_p & s.align_s(2) & s.align_s(1) & s.align_s(0) &
          s.band & s.lock                                                when RA_ASTAT,
          s.tap_mask(0)                                                  when RA_ATAPMASK0,
          s.tap_mask(1)                                                  when RA_ATAPMASK1,
          s.tap_mask(2)                                                  when RA_ATAPMASK2,
          x"00" & "000" & s.tap(2) & "000" & s.tap(1) & "000" & s.tap(0) when RA_ATAP,
          x"00000" & s.bitslip(2) & s.bitslip(1) & s.bitslip(0)          when RA_ABITSLIP,
          s.count_acycle(0)                                              when RA_ACYCLE0,
          s.count_acycle(1)                                              when RA_ACYCLE1,
          s.count_acycle(2)                                              when RA_ACYCLE2,
          s.count_tap_ok(0)                                              when RA_ATAPOK0,
          s.count_tap_ok(1)                                              when RA_ATAPOK1,
          s.count_tap_ok(2)                                              when RA_ATAPOK2,
          s.count_again_s(0)                                             when RA_AGAIN0,
          s.count_again_s(1)                                             when RA_AGAIN1,
          s.count_again_s(2)                                             when RA_AGAIN2,
          s.count_again_p                                                when RA_AGAINP,
          s.count_aloss_s(0)                                             when RA_ALOSS0,
          s.count_aloss_s(1)                                             when RA_ALOSS1,
          s.count_aloss_s(2)                                             when RA_ALOSS2,
          s.count_aloss_p                                                when RA_ALOSSP,
          cap_rst & "000" & x"000000" & "000" & cap_en                   when RA_CAPCTRL,
          cap_size                                                       when RA_CAPSIZE,
          x"0000000" & cap_unf & cap_ovf & cap_loss & cap_run            when RA_CAPSTAT,
          cap_count                                                      when RA_CAPCOUNT,
          scratch                                                        when RA_SCRATCH,
          (others => '0')                                                when others;
      else
        sr_rdy  <= '0';
        sr_data <= (others => '0');
      end if;

      -- saxi_miso.rid     <= saxi_mosi.arid;
      -- saxi_miso.rvalid  <= saxi_mosi.arvalid and saxi_mosi.rready and not saxi_miso.rvalid;
      -- case saxi_mosi.araddr(7 downto 0) is
        -- when RA_SIGNATURE => rd <= x"53444D54"; -- "TMDS" (little endian)
        -- when RA_FREQ      => rd <= s.count_freq;
        -- when RA_ASTAT     => rd <= x"00000" & '0' &
                                  -- s.skew_p(2) & s.skew_p(1) &
                                  -- s.align_p & s.align_s(2) & s.align_s(1) & s.align_s(0) &
                                  -- s.band & s.lock;
        -- when RA_ATAPMASK0 => rd <= s.tap_mask(0);
        -- when RA_ATAPMASK1 => rd <= s.tap_mask(1);
        -- when RA_ATAPMASK2 => rd <= s.tap_mask(2);
        -- when RA_ATAP      => rd <= x"00" & "000" & s.tap(2) & "000" & s.tap(1) & "000" & s.tap(0);
        -- when RA_ABITSLIP  => rd <= x"00000" & s.bitslip(2) & s.bitslip(1) & s.bitslip(0);
        -- when RA_ACYCLE0   => rd <= s.count_acycle(0);
        -- when RA_ACYCLE1   => rd <= s.count_acycle(1);
        -- when RA_ACYCLE2   => rd <= s.count_acycle(2);
        -- when RA_ATAPOK0   => rd <= s.count_tap_ok(0);
        -- when RA_ATAPOK1   => rd <= s.count_tap_ok(1);
        -- when RA_ATAPOK2   => rd <= s.count_tap_ok(2);
        -- when RA_AGAIN0    => rd <= s.count_again_s(0);
        -- when RA_AGAIN1    => rd <= s.count_again_s(1);
        -- when RA_AGAIN2    => rd <= s.count_again_s(2);
        -- when RA_AGAINP    => rd <= s.count_again_p;
        -- when RA_ALOSS0    => rd <= s.count_aloss_s(0);
        -- when RA_ALOSS1    => rd <= s.count_aloss_s(1);
        -- when RA_ALOSS2    => rd <= s.count_aloss_s(2);
        -- when RA_ALOSSP    => rd <= s.count_aloss_p;
        -- when RA_CAPCTRL   => rd <= reg_cap_ctrl;
        -- when RA_CAPSTAT   => rd <= reg_cap_stat;
        -- when RA_CAPSIZE   => rd <= reg_cap_size;
        -- when RA_SCRATCH   => rd <= reg_scratch;
        -- when others       => rd <= (others => '0');
      -- end case;

    end if;
  end process;

end architecture synth;
