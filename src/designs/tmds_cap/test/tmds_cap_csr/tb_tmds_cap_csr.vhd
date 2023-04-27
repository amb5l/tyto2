library ieee;
  use ieee.std_logic_1164.all;
--  use ieee.numeric_std.all;
--  use ieee.numeric_std_unsigned.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.Axi4Context;

library work;
  use work.axi_pkg.all;
  use work.hdmi_rx_selectio_pkg.all;
  use work.tmds_cap_csr_pkg.all;
  use work.TestCtrl_pkg.all;

entity tb_tmds_cap_csr is
end entity tb_tmds_cap_csr;

architecture sim of tb_tmds_cap_csr is

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

  signal AxiBus : Axi4RecType(
    WriteAddress(
      Addr(AXI_ADDR_WIDTH-1 downto 0),
      ID(7 downto 0),
      User(7 downto 0)
    ),
    WriteData   (
      Data(AXI_DATA_WIDTH-1 downto 0),
      Strb(AXI_STRB_WIDTH-1 downto 0),
      User(7 downto 0),
      ID(7 downto 0)
    ),
    WriteResponse(
      ID(7 downto 0),
      User(7 downto 0)
    ),
    ReadAddress (
      Addr(AXI_ADDR_WIDTH-1 downto 0),
      ID(7 downto 0),
      User(7 downto 0)
    ),
    ReadData    (
      Data(AXI_DATA_WIDTH-1 downto 0),
      ID(7 downto 0),
      User(7 downto 0)
    )
  ) ;

  signal saxi_mosi   : axi4_mosi_a32d32_t;
  signal saxi_miso   : axi4_miso_a32d32_t;

  signal cap_rst     : std_logic;
  signal cap_size    : std_logic_vector(31 downto 0);
  signal cap_go      : std_logic;
  signal cap_done    : std_logic;
  signal cap_error   : std_logic;
  signal tmds_status : hdmi_rx_selectio_status_t;

begin

  Osvvm.TbUtilPkg.CreateClock(
    Clk    => Clk,
    Period => Tperiod_Clk
  ) ;

  Osvvm.TbUtilPkg.CreateReset(
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * tperiod_Clk,
    tpd         => tpd
  );

  DUT: component tmds_cap_csr
    port map (
      axi_clk           => Clk,
      axi_rst_n         => nReset,
      saxi_mosi         => saxi_mosi,
      saxi_miso         => saxi_miso,
      tmds_status       => tmds_status,
      cap_rst           => cap_rst,
      cap_size          => cap_size,
      cap_go            => cap_go,
      cap_done          => cap_done,
      cap_error         => cap_error
    );

  saxi_mosi.awid    <= AxiBus.WriteAddress.ID;
  saxi_mosi.awaddr  <= AxiBus.WriteAddress.Addr;
  saxi_mosi.awlen   <= AxiBus.WriteAddress.Len;
  saxi_mosi.awsize  <= AxiBus.WriteAddress.Size;
  saxi_mosi.awburst <= AxiBus.WriteAddress.Burst;
  saxi_mosi.awcache <= AxiBus.WriteAddress.Cache;
  saxi_mosi.awprot  <= AxiBus.WriteAddress.Prot;
  saxi_mosi.awqos   <= AxiBus.WriteAddress.QOS;
  saxi_mosi.awvalid <= AxiBus.WriteAddress.Valid;
  saxi_mosi.wdata   <= AxiBus.WriteData.Data;
  saxi_mosi.wstrb   <= AxiBus.WriteData.Strb;
  saxi_mosi.wlast   <= AxiBus.WriteData.Last;
  saxi_mosi.wvalid  <= AxiBus.WriteData.Valid;
  saxi_mosi.bready  <= AxiBus.WriteResponse.Ready;
  saxi_mosi.arid    <= AxiBus.ReadAddress.ID;
  saxi_mosi.araddr  <= AxiBus.ReadAddress.Addr;
  saxi_mosi.arlen   <= AxiBus.ReadAddress.Len;
  saxi_mosi.arsize  <= AxiBus.ReadAddress.Size;
  saxi_mosi.arburst <= AxiBus.ReadAddress.Burst;
  saxi_mosi.arcache <= AxiBus.ReadAddress.Cache;
  saxi_mosi.arprot  <= AxiBus.ReadAddress.Prot;
  saxi_mosi.arqos   <= AxiBus.ReadAddress.QOS;
  saxi_mosi.arvalid <= AxiBus.ReadAddress.Valid;
  saxi_mosi.rready  <= AxiBus.ReadData.Ready;

  AxiBus.WriteAddress.Ready  <= saxi_miso.awready;
  AxiBus.WriteData.Ready     <= saxi_miso.wready;
  AxiBus.WriteResponse.ID    <= saxi_miso.bid;
  AxiBus.WriteResponse.Resp  <= saxi_miso.bresp;
  AxiBus.WriteResponse.Valid <= saxi_miso.bvalid;
  AxiBus.ReadAddress.Ready   <= saxi_miso.arready;
  AxiBus.ReadData.ID         <= saxi_miso.rid;
  AxiBus.ReadData.Data       <= saxi_miso.rdata;
  AxiBus.ReadData.Resp       <= saxi_miso.rresp;
  AxiBus.ReadData.Last       <= saxi_miso.rlast;
  AxiBus.ReadData.Valid      <= saxi_miso.rvalid;

  Manager_1: component Axi4Manager
    port map (
      Clk      => Clk,
      nReset   => nReset,
      AxiBus   => AxiBus,
      TransRec => ManagerRec
    );

  Monitor_1: component Axi4Monitor
    port map (
      Clk    => Clk,
      nReset => nReset,
      AxiBus => AxiBus
    );

  TestCtrl_1: component TestCtrl
    port map (
      Clk            => Clk,
      nReset         => nReset,
      ManagerRec     => ManagerRec
    );

end architecture sim;