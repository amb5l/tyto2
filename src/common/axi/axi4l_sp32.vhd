--------------------------------------------------------------------------------
-- axi4l_sp32.vhd                                                             --
-- Bridge from AXI4-Lite (32 bit address & data) to simple/single port.       --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or(at your option) any later version.    --
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

package axi4l_sp32_pkg is

  component axi4l_sp32 is
    port (

      clk      : in  std_logic;
      rst_n    : in  std_logic;

      axi4l_si : in  axi4l_a32d32_mosi_t := AXI4L_A32D32_MOSI_DEFAULT;
      axi4l_so : out axi4l_a32d32_miso_t := AXI4L_A32D32_MISO_DEFAULT;

      sp_en    : out std_logic;
      sp_r_w   : out std_logic;
      sp_wbe   : out std_logic_vector(3 downto 0);
      sp_addr  : out std_logic_vector(31 downto 0);
      sp_wdata : out std_logic_vector(31 downto 0);
      sp_rdata : in  std_logic_vector(31 downto 0);
      sp_rdy   : in  std_logic

    );
  end component axi4l_sp32;

end package axi4l_sp32_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.axi_pkg.all;

entity axi4l_sp32 is
  port (

    clk         : in  std_logic;                                        -- clock
    rst_n       : in  std_logic;                                        -- reset (active low

    axi4l_si    : in  axi4l_a32d32_mosi_t := AXI4L_A32D32_MOSI_DEFAULT; -- AXI4-Lite slave inputs
    axi4l_so    : out axi4l_a32d32_miso_t := AXI4L_A32D32_MISO_DEFAULT; -- AXI4-Lite slave output

    sp_en       : out std_logic;                                        -- simple port write enable
    sp_r_w      : out std_logic;                                        -- simple port write address
    sp_wbe      : out std_logic_vector(3 downto 0);                     -- simple port write byte enables
    sp_addr     : out std_logic_vector(31 downto 0);                    -- simple port address
    sp_wdata    : out std_logic_vector(31 downto 0);                    -- simple port write data
    sp_rdata    : in  std_logic_vector(31 downto 0);                    -- simple port read data
    sp_rdy      : in  std_logic                                         -- simple port ready

  );
end entity axi4l_sp32;

architecture rtl of axi4l_sp32 is

  -- optional AXI4Lite inputs that are ignored:
  -- awcache, awprot, arcache, arprot

  -- aliases to tidy code
  alias awaddr  is axi4l_si.awaddr;
  alias awvalid is axi4l_si.awvalid;
  alias awready is axi4l_so.awready;
  alias wdata   is axi4l_si.wdata;
  alias wstrb   is axi4l_si.wstrb;
  alias wvalid  is axi4l_si.wvalid;
  alias wready  is axi4l_so.wready;
  alias bresp   is axi4l_so.bresp;
  alias bvalid  is axi4l_so.bvalid;
  alias bready  is axi4l_si.bready;
  alias araddr  is axi4l_si.araddr;
  alias arvalid is axi4l_si.arvalid;
  alias arready is axi4l_so.arready;
  alias rdata   is axi4l_so.rdata;
  alias rresp   is axi4l_so.rresp;
  alias rvalid  is axi4l_so.rvalid;
  alias rready  is axi4l_si.rready;

  type state_t is (IDLE, W_ADDR, W_DATA, W_ACCESS, W_READY, R_ACCESS, R_READY);
  signal state : state_t;

  -- simulation/debug
  signal sim_axi4l : axi4l_a32d32_t; -- v4p ignore w-303

begin

  --------------------------------------------------------------------------------

  bresp          <= (others => '0'); -- } response is always OK
  rresp          <= (others => '0'); -- }

  --------------------------------------------------------------------------------

  process(rst_n,clk)
  begin
    if rst_n = '0' then

      state    <= IDLE;

      sp_en    <= '0';
      sp_r_w   <= 'X';
      sp_wbe   <= (others => 'X');
      sp_addr  <= (others => 'X');
      sp_wdata <= (others => 'X');

      awready  <= '1';
      wready   <= '1';
      bvalid   <= '0';
      arready  <= '1';
      rdata    <= (others => 'X');
      rvalid   <= '0';

    elsif rising_edge(clk) then

      awready <= '0';
      wready  <= '0';
      arready <= '0';

      case state is
        when IDLE =>
          if awvalid and wvalid then
            awready  <= '1';
            wready   <= '1';
            sp_en    <= '1';
            sp_r_w   <= '0';
            sp_wbe   <= wstrb;
            sp_addr  <= awaddr;
            sp_wdata <= wdata;
            state    <= W_ACCESS;
          elsif awvalid then
            awready  <= '1';
            sp_r_w   <= '0';
            sp_addr  <= awaddr;
            state    <= W_ADDR;
          elsif wvalid then
            wready   <= '1';
            sp_r_w   <= '0';
            sp_wbe   <= wstrb;
            sp_wdata <= wdata;
            state    <= W_DATA;
          elsif arvalid then
            arready  <= '1';
            sp_en    <= '1';
            sp_r_w   <= '1';
            sp_addr  <= araddr;
            state    <= R_ACCESS;
          end if;
        when W_ADDR =>
          if wvalid then
            wready   <= '1';
            sp_en    <= '1';
            sp_wbe   <= wstrb;
            sp_wdata <= wdata;
            state    <= W_ACCESS;
          end if;
        when W_DATA =>
          if awvalid then
            awready  <= '1';
            sp_en    <= '1';
            sp_addr  <= awaddr;
            state    <= W_ACCESS;
          end if;
        when W_ACCESS =>
          if sp_rdy then
            bvalid   <= '1';
            sp_en    <= '0';
            sp_r_w   <= 'X';
            sp_wbe   <= (others => 'X');
            sp_addr  <= (others => 'X');
            sp_wdata <= (others => 'X');
            state <= W_READY;
          end if;
        when W_READY =>
          if bready then
            bvalid <= '0';
            state  <= IDLE;
          end if;
        when R_ACCESS =>
          if sp_rdy then
            rdata    <= sp_rdata;
            rvalid   <= '1';
            sp_en    <= '0';
            sp_r_w   <= 'X';
            sp_addr  <= (others => 'X');
            state    <= R_READY;
          end if;
        when R_READY =>
          if rready then
            rvalid   <= '0';
            state    <= IDLE;
          end if;
      end case;

    end if;

  end process;

  --------------------------------------------------------------------------------

  sim_axi4l.awaddr  <= axi4l_si.awaddr;
  sim_axi4l.awprot  <= axi4l_si.awprot;
  sim_axi4l.awvalid <= axi4l_si.awvalid;
  sim_axi4l.awready <= axi4l_so.awready;
  sim_axi4l.wdata   <= axi4l_si.wdata;
  sim_axi4l.wstrb   <= axi4l_si.wstrb;
  sim_axi4l.wvalid  <= axi4l_si.wvalid;
  sim_axi4l.wready  <= axi4l_so.wready;
  sim_axi4l.bvalid  <= axi4l_so.bvalid;
  sim_axi4l.bready  <= axi4l_si.bready;
  sim_axi4l.araddr  <= axi4l_si.araddr;
  sim_axi4l.arprot  <= axi4l_si.arprot;
  sim_axi4l.arvalid <= axi4l_si.arvalid;
  sim_axi4l.arready <= axi4l_so.arready;
  sim_axi4l.rdata   <= axi4l_so.rdata;
  sim_axi4l.rresp   <= axi4l_so.rresp;
  sim_axi4l.rvalid  <= axi4l_so.rvalid;
  sim_axi4l.rready  <= axi4l_si.rready;

  --------------------------------------------------------------------------------

end architecture rtl;
