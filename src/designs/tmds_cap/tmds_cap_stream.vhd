--------------------------------------------------------------------------------
-- tmds_cap_stream.vhd                                                        --
-- Stream module for tmds_cap design.                                         --
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
  use work.axi_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;

package tmds_cap_stream_pkg is

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

  component tmds_cap_stream is
    port (

      prst        : in    std_logic;
      pclk        : in    std_logic;
      tmds        : in    slv10_vector(0 to 2);
      rx_status   : in    hdmi_rx_selectio_status_t;

      axi_clk     : in    std_logic;
      axi_rst_n   : in    std_logic;
      axi_mosi    : in    axi4_mosi_a32d32_t;
      axi_miso    : out   axi4_miso_a32d32_t;
      axis_mosi   : out   axi4s_mosi_64_t;
      axis_miso   : out   axi4s_mosi_64_t

    );
  end component tmds_cap_stream;

end package tmds_cap_stream_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;

entity tmds_cap_stream is
  port (

      prst        : in    std_logic;
      pclk        : in    std_logic;
      tmds        : in    slv10_vector(0 to 2);
      rx_status   : in    hdmi_rx_selectio_status_t;

      axi_clk     : in    std_logic;
      axi_rst_n   : in    std_logic;
      axi_mosi    : in    axi4_mosi_a32d32_t;
      axi_miso    : out   axi4_miso_a32d32_t;
      axis_mosi   : out   axi4s_mosi_64_t;
      axis_miso   : out   axi4s_mosi_64_t

  );
end entity tmds_cap_stream;

architecture synth of tmds_cap_stream is

  signal rx_status_s1 : hdmi_rx_selectio_status_t;
  signal rx_status_s2 : hdmi_rx_selectio_status_t;
  signal rstb         : std_logic;
  signal fifo_ef      : std_logic;
  signal fifo_wstb    : std_logic;
  signal fifo_rstb    : std_logic;

  alias s : hdmi_rx_selectio_status_t     is rx_status_s2;
  alias r : std_logic_vector(31 downto 0) is axi_miso.rdata;

begin

  -- should we be registering these outputs? probably...
  axi_miso.bresp   <= (others => '0');
  axi_miso.arready <= rstb;
  axi_miso.rresp   <= (others => '0');
  axi_miso.rlast   <= '1';
  axi_miso.rvalid  <= rstb;

  -- register reads
  process(axi_rst_n,axi_clk)
  begin
    if axi_rst_n = '0' then

      rx_status_s1     <= (others => '0');
      rx_status_s2     <= (others => '0');
      r                <= (others => '0');
      rstb             <= '0';
      axi_miso.awready <= '0';
      axi_miso.wready  <= '0';
      axi_miso.bvalid  <= '0';

    elsif rising_edge(axi_clk) then

      -- synchronisers
      rx_status_s1 <= rx_status;
      rx_status_s2 <= rx_status_s1;

      -- register reads and writes
      axi_miso.awready <= axi_mosi.awvalid and axi_mosi.wvalid;
      axi_miso.wready  <= axi_mosi.awvalid and axi_mosi.wvalid;
      axi_miso.bvalid  <= axi_mosi.awvalid and axi_mosi.wvalid;

      -- register reads
      r <= (others => '0'); -- default
      case axi_mosi.araddr(7 downto 0) is
        when RA_FREQ   => s.count_freq;
        when RA_ASTAT    =>
          s.skew_p(2) & s.skew_p(1) &
          s.align_p & s.align_s(2) & s.align_s(1) & s.align_s(0) &
          s.band & s.lock;
        when RA_ATAPMASK0 => r(31 downto 0) <= s.tap_mask(0);
        when RA_ATAPMASK1 => r(31 downto 0) <= s.tap_mask(1);
        when RA_ATAPMASK2 => r(31 downto 0) <= s.tap_mask(2);
        when RA_ATAP      => r(23 downto 0) <=
          "000" & s.tap(2) &
          "000" & s.tap(1) &
          "000" & s.tap(0);
        when RA_ABITSLIP  =>
          X"00000" &
          s.bitslip(2) &
          s.bitslip(1) &
          s.bitslip(0);
        when RA_ACYCLE0 => r(31 downto 0) <= s.count_acycle(0);
        when RA_ACYCLE1 => r(31 downto 0) <= s.count_acycle(1);
        when RA_ACYCLE2 => r(31 downto 0) <= s.count_acycle(2);
        when RA_TAPOK0  => r(31 downto 0) <= s.count_tap_ok(0);
        when RA_TAPOK1  => r(31 downto 0) <= s.count_tap_ok(1);
        when RA_TAPOK2  => r(31 downto 0) <= s.count_tap_ok(2);
        when RA_AGAIN0  => r(31 downto 0) <= s.count_again_s(0);
        when RA_AGAIN1  => r(31 downto 0) <= s.count_again_s(1);
        when RA_AGAIN2  => r(31 downto 0) <= s.count_again_s(2);
        when RA_AGAINP  => r(31 downto 0) <= s.count_again_p;
        when RA_ALOSS0  => r(31 downto 0) <= s.count_aloss_s(0);
        when RA_ALOSS1  => r(31 downto 0) <= s.count_aloss_s(1);
        when RA_ALOSS2  => r(31 downto 0) <= s.count_aloss_s(2);
        when RA_ALOSSP  => r(31 downto 0) <= s.count_aloss_p;
        when RA_CAPCTRL => r(31 downto 0) <= -- TODO
        when RA_CAPSTAT => r(31 downto 0) <= -- TODO
        when others => null;
      end case;
      rstb <= axi_mosi.arvalid and axi_mosi.rready;

      -- register writes
      -- TODO: create register: capture size (up to 2^24 pixels)
      -- control register (start capture)
      -- status register (pixels captured, finished yes/no)

    end if;
  end process;

  -- TMDS stream ---> FIFO
  -- TODO: implement counter, loaded from capture size register

  process(prst,pclk)
    variable d : std_logic_vector(31 downto 0);
  begin
    if prst = '1' then
      fifo_wdata <= (others <= '0');
      fifo_wstb  <= '0';
    elsif rising_edge(pclk) then
      d := "00" & tmds(2) & tmds(1) & tmds(0);
      fifo_wstb <= '0';
      if (count > 0) then -- TODO implement counter properly
        if count(0) = '0' then
          fifo_wdata( 31 downto  0 ) <= d;
        else
          fifo_wdata( 63 downto 32 ) <= d;
          fifo_wstb <= '1';
        end if;
      end if;
    end if;
  end process;

  -- FIFO

  U_FIFO: fifo_tbd -- FIFO, to be decided
    port map(
      wrst  => prst,
      wclk  => pclk,
      wstb  => fifo_wstb,
      wdata => fifo_wdata,
      ef    => fifo_ef,
      rrst  => not axi_rst_n,
      rclk  => axi_clk,
      rstb  => fifo_rstb,
      rdata => fifo_rdata
    );

  -- FIFO ---> FIFO AXI stream

  fifo_rstb        <= axis_mosi.tvalid and axis_miso.tready;
  axis_mosi.tdata  <= fifo_rdata;
  axis_mosi.tkeep  <= (others => '0');
  axis_mosi.tvalid <= not fifo_ef;
  axis_mosi.tlast  <= '0'; -- don't think we need this

end architecture synth;
