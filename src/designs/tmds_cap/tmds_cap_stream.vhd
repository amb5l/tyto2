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
  axi_miso.awready <= axi_mosi.awvalid and axi_mosi.wvalid;
  axi_miso.wready  <= axi_mosi.awvalid and axi_mosi.wvalid;
  axi_miso.bresp   <= (others => '0');
  axi_miso.bvalid  <= axi_mosi.awvalid and axi_mosi.wvalid;
  axi_miso.arready <= rstb;
  axi_miso.rresp   <= (others => '0');
  axi_miso.rlast   <= '1';
  axi_miso.rvalid  <= rstb;

  -- register reads
  process(axi_rst_n,axi_clk)
  begin
    if axi_rst_n = '0' then
      rx_status_s1 <= (others => '0');
      rx_status_s2 <= (others => '0');
      r            <= (others => '0');
      rstb         <= '0';
    elsif rising_edge(axi_clk) then

      -- synchronisers
      rx_status_s1 <= rx_status;
      rx_status_s2 <= rx_status_s1;

      -- register reads
      r <= (others => '0'); -- default
      case axi_mosi.araddr(7 downto 0) is
        when x"00" => r(31 downto 0) <= s.count_freq;
        when x"04" => r( 2 downto 0) <= s.band & s.lock;
        when x"08" => r( 7 downto 0) <=
                        s.skew_p(2)(1) & s.skew_p(2)(0) &
                        s.skew_p(1)(1) & s.skew_p(1)(0) &
                        s.align_p &
                        s.align_s(2) & s.align_s(1) & s.align_s(0);
        when x"10" => r(31 downto 0) <= s.tap_mask(0);
        when x"14" => r(31 downto 0) <= s.tap_mask(1);
        when x"18" => r(31 downto 0) <= s.tap_mask(2);
        when x"20" => r( 4 downto 0) <= s.tap(0);
        when x"24" => r( 4 downto 0) <= s.tap(1);
        when x"28" => r( 4 downto 0) <= s.tap(2);
        when x"30" => r( 3 downto 0) <= s.bitslip(0);
        when x"34" => r( 3 downto 0) <= s.bitslip(1);
        when x"38" => r( 3 downto 0) <= s.bitslip(2);
        when x"40" => r(31 downto 0) <= s.count_acycle(0);
        when x"44" => r(31 downto 0) <= s.count_acycle(1);
        when x"48" => r(31 downto 0) <= s.count_acycle(2);
        when x"50" => r(31 downto 0) <= s.count_tap_ok(0);
        when x"54" => r(31 downto 0) <= s.count_tap_ok(1);
        when x"58" => r(31 downto 0) <= s.count_tap_ok(2);
        when x"60" => r(31 downto 0) <= s.count_again_s(0);
        when x"64" => r(31 downto 0) <= s.count_again_s(1);
        when x"68" => r(31 downto 0) <= s.count_again_s(2);
        when x"6C" => r(31 downto 0) <= s.count_again_p;
        when x"70" => r(31 downto 0) <= s.count_aloss_s(0);
        when x"74" => r(31 downto 0) <= s.count_aloss_s(1);
        when x"78" => r(31 downto 0) <= s.count_aloss_s(2);
        when x"7C" => r(31 downto 0) <= s.count_aloss_p;
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
