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
  use work.tyto_types_pkg.all;
  use work.axi_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;

package tmds_cap_csr_pkg is

  constant RA_FREQ      : std_logic_vector(7 downto 0) := x"00"; -- pixel clock frequency count
  constant RA_ASTAT     : std_logic_vector(7 downto 0) := x"04"; -- alignment status
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
  constant RA_CAPCTRL   : std_logic_vector(7 downto 0) := x"70"; -- capture control
  constant RA_CAPSTAT   : std_logic_vector(7 downto 0) := x"74"; -- capture status
  constant RA_CAPSIZE   : std_logic_vector(7 downto 0) := x"78"; -- capture size
  constant RA_SCRATCH   : std_logic_vector(7 downto 0) := x"7C"; -- scratch register

  component tmds_cap_csr is
    port (
      axi_clk     : in    std_logic;
      axi_rst_n   : in    std_logic;
      saxi_mosi   : in    axi4_mosi_a32d32_t;
      saxi_miso   : out   axi4_miso_a32d32_t;
      tmds_status : in    hdmi_rx_selectio_status_t;
      cap_rst     : out   std_logic;
      cap_size    : out   std_logic_vector(31 downto 0);
      cap_go      : out   std_logic;
      cap_done    : in    std_logic;
      cap_error   : in    std_logic
    );
  end component tmds_cap_csr;

end package tmds_cap_csr_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.tmds_cap_csr_pkg.all;

entity tmds_cap_csr is
  port (

    axi_clk     : in    std_logic;                     -- AXI clock
    axi_rst_n   : in    std_logic;                     -- AXI reset (active low)
    saxi_mosi   : in    axi4_mosi_a32d32_t;            -- AXI slave interface (inputs)
    saxi_miso   : out   axi4_miso_a32d32_t;            -- AXI slave interface (outputs)

    tmds_status : in    hdmi_rx_selectio_status_t;     -- TMDS receive (alignment) status

    cap_rst     : out    std_logic;                    -- capture reset
    cap_size    : out   std_logic_vector(31 downto 0); -- capture size (pixels)
    cap_go      : out   std_logic;                     -- capture start
    cap_done    : in    std_logic;                     -- capture done
    cap_error   : in    std_logic                      -- capture error

  );
end entity tmds_cap_csr;

architecture synth of tmds_cap_csr is

  signal tmds_status_s1 : hdmi_rx_selectio_status_t;        -- tmds_status synchroniser registers (first level)
  signal tmds_status_s2 : hdmi_rx_selectio_status_t;        -- tmds_status synchroniser registers (second level)

  signal reg_cap_ctrl   : std_logic_vector(31 downto 0);   -- capture control register
  signal reg_cap_stat   : std_logic_vector(31 downto 0);   -- capture status register
  signal reg_cap_size   : std_logic_vector(31 downto 0);   -- capture status register
  signal reg_scratch    : std_logic_vector(31 downto 0);   -- scratch register

  alias s  : hdmi_rx_selectio_status_t     is tmds_status_s2;
  alias rd : std_logic_vector(31 downto 0) is saxi_miso.rdata;
  alias wd : std_logic_vector(31 downto 0) is saxi_mosi.wdata;

begin

  saxi_miso.bresp   <= (others => '0');
  saxi_miso.rresp   <= (others => '0');
  saxi_miso.rlast   <= '1';

  process(axi_clk) -- synchronisers
  begin
    if rising_edge(axi_clk) then
      tmds_status_s1 <= tmds_status;
      tmds_status_s2 <= tmds_status_s1;
    end if;
  end process;

  process(axi_rst_n,axi_clk)
  begin
    if axi_rst_n = '0' then

      rd                <= (others => '0');
      saxi_miso.awready <= '0';
      saxi_miso.wready  <= '0';
      saxi_miso.bvalid  <= '0';
      saxi_miso.arready <= '0';
      saxi_miso.rvalid  <= '0';
      reg_cap_ctrl      <= (31 => '1', others => '0');
      reg_cap_size      <= (others => '0');
      reg_scratch       <= (others => '0');

    elsif rising_edge(axi_clk) then

      -- reads
      saxi_miso.arready <= saxi_mosi.arvalid and saxi_mosi.rready;
      saxi_miso.rvalid  <= saxi_mosi.arvalid and saxi_mosi.rready;
      case saxi_mosi.araddr(7 downto 0) is
        when RA_FREQ      => rd <= s.count_freq;
        when RA_ASTAT     => rd <= x"00000" & '0' &
                                  s.skew_p(2) & s.skew_p(1) &
                                  s.align_p & s.align_s(2) & s.align_s(1) & s.align_s(0) &
                                  s.band & s.lock;
        when RA_ATAPMASK0 => rd <= s.tap_mask(0);
        when RA_ATAPMASK1 => rd <= s.tap_mask(1);
        when RA_ATAPMASK2 => rd <= s.tap_mask(2);
        when RA_ATAP      => rd <= x"00" & "000" & s.tap(2) & "000" & s.tap(1) & "000" & s.tap(0);
        when RA_ABITSLIP  => rd <= x"00000" & s.bitslip(2) & s.bitslip(1) & s.bitslip(0);
        when RA_ACYCLE0   => rd <= s.count_acycle(0);
        when RA_ACYCLE1   => rd <= s.count_acycle(1);
        when RA_ACYCLE2   => rd <= s.count_acycle(2);
        when RA_ATAPOK0   => rd <= s.count_tap_ok(0);
        when RA_ATAPOK1   => rd <= s.count_tap_ok(1);
        when RA_ATAPOK2   => rd <= s.count_tap_ok(2);
        when RA_AGAIN0    => rd <= s.count_again_s(0);
        when RA_AGAIN1    => rd <= s.count_again_s(1);
        when RA_AGAIN2    => rd <= s.count_again_s(2);
        when RA_AGAINP    => rd <= s.count_again_p;
        when RA_ALOSS0    => rd <= s.count_aloss_s(0);
        when RA_ALOSS1    => rd <= s.count_aloss_s(1);
        when RA_ALOSS2    => rd <= s.count_aloss_s(2);
        when RA_ALOSSP    => rd <= s.count_aloss_p;
        when RA_CAPCTRL   => rd <= reg_cap_ctrl;
        when RA_CAPSTAT   => rd <= reg_cap_stat;
        when RA_CAPSIZE   => rd <= reg_cap_size;
        when RA_SCRATCH   => rd <= reg_scratch;
        when others       => rd <= (others => '0');
      end case;

      -- writes
      saxi_miso.awready <= saxi_mosi.awvalid and saxi_mosi.wvalid;
      saxi_miso.wready  <= saxi_mosi.awvalid and saxi_mosi.wvalid;
      saxi_miso.bvalid  <= saxi_mosi.awvalid and saxi_mosi.wvalid;
      if saxi_mosi.awvalid = '1' and saxi_mosi.wvalid = '1' then
        case saxi_mosi.awaddr(7 downto 0) is
          when RA_CAPCTRL => reg_cap_ctrl <= (31 => wd(31), 0 => wd(0), others => '0');
          when RA_CAPSIZE => reg_cap_size <= wd;
          when RA_SCRATCH => reg_scratch  <= wd;
          when others     => null;
        end case;
      end if;

    end if;
  end process;

  cap_rst      <= reg_cap_ctrl(31);
  cap_go       <= reg_cap_ctrl(0);
  reg_cap_stat <= (0 => cap_done, 1 => cap_error, others => '0');
  cap_size     <= reg_cap_size;

end architecture synth;
