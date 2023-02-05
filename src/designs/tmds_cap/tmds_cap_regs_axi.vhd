--------------------------------------------------------------------------------
-- tmds_cap_regs_axi.vhd                                                      --
-- AXI registers for tmds_cap design.                                         --
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

package tmds_cap_regs_axi_pkg is

  component tmds_cap_regs_axi is
    port (
      rst         : in    std_logic;
      clk         : in    std_logic;
      rx_status   : in    hdmi_rx_selectio_status_t;
      axi_mosi    : in    axi_mosi_t;
      axi_miso    : out   axi_miso_t
    );
  end component tmds_cap_regs_axi;

end package tmds_cap_regs_axi_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.axi_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;

entity tmds_cap_regs_axi is
  port (
    rst         : in    std_logic;
    clk         : in    std_logic;
    rx_status   : in    hdmi_rx_selectio_status_t;
    axi_mosi    : in    axi_mosi_t;
    axi_miso    : out   axi_miso_t
  );
end entity tmds_cap_regs_axi;

architecture synth of tmds_cap_regs_axi is

  alias s : hdmi_rx_selectio_status_t is rx_status;
  alias r : std_logic_vector(31 downto 0) is axi_miso.rdata;

  signal rstb : std_logic;

begin

  axi_miso.awready <= axi_mosi.awvalid and axi_mosi.wvalid;
  axi_miso.wready  <= axi_mosi.awvalid and axi_mosi.wvalid;
  axi_miso.bresp   <= (others => '0');
  axi_miso.bvalid  <= axi_mosi.awvalid and axi_mosi.wvalid;
  axi_miso.arready <= rstb;
  axi_miso.rresp   <= (others => '0');
  axi_miso.rvalid  <= rstb;

  process(rst,clk)
  begin
    if rst = '1' then
      r    <= (others => '0');
      rstb <= '0';
    elsif rising_edge(clk) then
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
        when x"40" => r(31 downto 0) <= s.count_attempt(0);
        when x"44" => r(31 downto 0) <= s.count_attempt(1);
        when x"48" => r(31 downto 0) <= s.count_attempt(2);
        when x"50" => r(31 downto 0) <= s.count_align(0);
        when x"54" => r(31 downto 0) <= s.count_align(1);
        when x"58" => r(31 downto 0) <= s.count_align(2);
        when x"60" => r(31 downto 0) <= s.count_retain(0);
        when x"64" => r(31 downto 0) <= s.count_retain(1);
        when x"68" => r(31 downto 0) <= s.count_retain(2);
        when x"70" => r(31 downto 0) <= s.count_unalign(0);
        when x"74" => r(31 downto 0) <= s.count_unalign(1);
        when x"78" => r(31 downto 0) <= s.count_unalign(2);
        when others => null;
      end case;
      rstb <= axi_mosi.arvalid and axi_mosi.rready;
    end if;
  end process;

end architecture synth;
