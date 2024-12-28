--------------------------------------------------------------------------------
-- tb_axi4l_sp32.vhd                                                          --
-- OSVVM based testbench for axi4l_sp32.vhd                                   --
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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.Axi4LiteContext;

library work;
  use work.axi_pkg.all;
  use work.axi4l_sp32_pkg.all;
  use work.TestCtrl_pkg.all;

entity tb_axi4l_sp32 is
end entity tb_axi4l_sp32;

architecture sim of tb_axi4l_sp32 is

  constant AXI_ADDR_WIDTH: integer:= 32;
  constant AXI_DATA_WIDTH: integer:= 32;
  constant AXI_STRB_WIDTH: integer:= AXI_DATA_WIDTH/8;

  constant tperiod_Clk: time:= 10 ns;
  constant tpd        : time:= 2 ns;

  signal Clk   : std_logic;
  signal nReset: std_logic;

  signal ManagerRec : AddressBusRecType(
    Address(AXI_ADDR_WIDTH-1 downto 0),
    DataToModel(AXI_DATA_WIDTH-1 downto 0),
    DataFromModel(AXI_DATA_WIDTH-1 downto 0)
  );

  signal AxiBus : Axi4LiteRecType(
    WriteAddress(
      Addr(AXI_ADDR_WIDTH-1 downto 0)
    ),
    WriteData   (
      Data(AXI_DATA_WIDTH-1 downto 0),
      Strb(AXI_STRB_WIDTH-1 downto 0)
    ),
    ReadAddress (
      Addr(AXI_ADDR_WIDTH-1 downto 0)
    ),
    ReadData    (
      Data(AXI_DATA_WIDTH-1 downto 0)
    )
  ) ;

  -- DUT
  constant addr_width : integer := 8; -- simple slave address width c.w. 256 bytes
  signal axi4l_si : axi4l_a32d32_mosi_t;
  signal axi4l_so : axi4l_a32d32_miso_t;
  signal sp_en    : std_logic;
  signal sp_r_w   : std_logic;
  signal sp_wbe   : std_logic_vector(3 downto 0);
  signal sp_addr  : std_logic_vector(31 downto 0);
  signal sp_wdata : std_logic_vector(31 downto 0);
  signal sp_rdata : std_logic_vector(31 downto 0);
  signal sp_rdy   : std_logic;
  signal sp_rdy_r : std_logic;

  -- simple slave memory
  constant s_depth : integer := 2**addr_width;
  type s_t is array(0 to s_depth-1) of std_logic_vector(31 downto 0);
  signal s : s_t;

begin

  Osvvm.ClockResetPkg.CreateClock(
    Clk    => Clk,
    Period => Tperiod_Clk
  ) ;

  Osvvm.ClockResetPkg.CreateReset(
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * tperiod_Clk,
    tpd         => tpd
  );

  DUT: component axi4l_sp32
    port map (
      clk      => Clk,
      rst_n    => nReset,
      axi4l_si => axi4l_si,
      axi4l_so => axi4l_so,
      sp_en    => sp_en,
      sp_r_w   => sp_r_w,
      sp_wbe   => sp_wbe,
      sp_addr  => sp_addr,
      sp_wdata => sp_wdata,
      sp_rdata => sp_rdata,
      sp_rdy   => sp_rdy
    );

  -- model simple slave (zero wait state write, 1 wait state read)

  sp_rdy <= (sp_en and not sp_r_w) or sp_rdy_r;
  process(nReset,Clk)
    variable addr : integer;
  begin
    addr := to_integer(unsigned(sp_addr(addr_width-1 downto 0)));
    if nReset = '0' then
      s       <= (others => (others => '0'));
      sp_rdata <= (others => '0');
      sp_rdy_r  <= '0';
    elsif rising_edge(Clk) then
      if sp_en and not sp_r_w then
        for i in 0 to 3 loop
          s(addr)((i*8)+7 downto i*8) <= sp_wdata((i*8)+7 downto i*8) when sp_wbe(i) = '1';
        end loop;
      end if;
      sp_rdy_r <= sp_en and not sp_rdy_r;
      sp_rdata <= s(addr) when sp_en and sp_r_w else (others => 'X');
    end if;
  end process;

  -- connect OSVVM AXI master outputs to DUT AXI slave inputs
  axi4l_si.awaddr            <= AxiBus.WriteAddress.Addr;
  axi4l_si.awprot            <= AxiBus.WriteAddress.Prot;
  axi4l_si.awvalid           <= AxiBus.WriteAddress.Valid;
  axi4l_si.wdata             <= AxiBus.WriteData.Data;
  axi4l_si.wstrb             <= AxiBus.WriteData.Strb;
  axi4l_si.wvalid            <= AxiBus.WriteData.Valid;
  axi4l_si.bready            <= AxiBus.WriteResponse.Ready;
  axi4l_si.araddr            <= AxiBus.ReadAddress.Addr;
  axi4l_si.arprot            <= AxiBus.ReadAddress.Prot;
  axi4l_si.arvalid           <= AxiBus.ReadAddress.Valid;
  axi4l_si.rready            <= AxiBus.ReadData.Ready;

  -- connect OSVVM AXI master inputs to DUT AXI slave outputs
  AxiBus.WriteAddress.Ready  <= axi4l_so.awready;
  AxiBus.WriteData.Ready     <= axi4l_so.wready;
  AxiBus.WriteResponse.Resp  <= axi4l_so.bresp;
  AxiBus.WriteResponse.Valid <= axi4l_so.bvalid;
  AxiBus.ReadAddress.Ready   <= axi4l_so.arready;
  AxiBus.ReadData.Data       <= axi4l_so.rdata;
  AxiBus.ReadData.Resp       <= axi4l_so.rresp;
  AxiBus.ReadData.Valid      <= axi4l_so.rvalid;

  Manager_1: component Axi4LiteManager
    port map (
      Clk      => Clk,
      nReset   => nReset,
      AxiBus   => AxiBus,
      TransRec => ManagerRec
    );

  Monitor_1: component Axi4LiteMonitor
    port map (
      Clk    => Clk,
      nReset => nReset,
      AxiBus => AxiBus
    );

  TestCtrl_1: component TestCtrl
    generic map (
      addr_width => addr_width
    )
    port map (
      Clk        => Clk,
      nReset     => nReset,
      ManagerRec => ManagerRec
    );

end architecture sim;