library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.Axi4Context;

library work;
  use work.axi4_pkg.all;
  use work.axi4_a32d32_srw32_pkg.all;
  use work.TestCtrl_pkg.all;

entity tb_axi4_a32d32_srw32 is
end entity tb_axi4_a32d32_srw32;

architecture sim of tb_axi4_a32d32_srw32 is

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

  -- DUT
  constant addr_width : integer := 10; -- 256 x 32 bits
  signal axi4_si : axi4_a32d32_h_mosi_t;
  signal axi4_so : axi4_a32d32_h_miso_t;
  signal sw_en   : std_logic;
  signal sw_addr : std_logic_vector(addr_width-1 downto 0);
  signal sw_be   : std_logic_vector(3 downto 0);
  signal sw_data : std_logic_vector(31 downto 0);
  signal sw_rdy  : std_logic;
  signal sr_en   : std_logic;
  signal sr_addr : std_logic_vector(addr_width-1 downto 0);
  signal sr_data : std_logic_vector(31 downto 0);
  signal sr_rdy  : std_logic;

  -- simple slave memory
  constant s_depth : integer := 2**addr_width;
  type s_t is array(0 to s_depth-1) of std_logic_vector(31 downto 0);
  signal s : s_t;

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

  DUT: component axi4_a32d32_srw32
    generic map (
      addr_width => 10
    )
    port map (
      clk     => Clk,
      rst_n   => nReset,
      axi4_si => axi4_si,
      axi4_so => axi4_so,
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

  -- model simple slave (zero wait state write, 1 wait state read)

  sw_rdy <= '1';
  process(nReset,Clk)
    variable waddr : integer;
    variable raddr : integer;
  begin
    waddr := to_integer(unsigned(sw_addr));
    raddr := to_integer(unsigned(sr_addr));
    if nReset = '0' then
      s       <= (others => (others => '0'));
      sr_data <= (others => '0');
      sr_rdy  <= '0';
    elsif rising_edge(Clk) then
      if sw_en = '1' then
        for i in 0 to 3 loop
          s(waddr)((i*8)+7 downto i*8) <= sw_data((i*8)+7 downto i*8) when sw_be(i) = '1';
        end loop;
      end if;
      sr_rdy <= sr_en;
      sr_data <= s(raddr) when sr_en = '1' else (others => '0');
    end if;
  end process;

  -- connect OSVVM AXI master outputs to DUT AXI slave inputs
  axi4_si.aw.id              <= AxiBus.WriteAddress.ID;
  axi4_si.aw.addr            <= AxiBus.WriteAddress.Addr;
  axi4_si.aw.len             <= AxiBus.WriteAddress.Len;
  axi4_si.aw.size            <= AxiBus.WriteAddress.Size;
  axi4_si.aw.burst           <= AxiBus.WriteAddress.Burst;
  axi4_si.aw.cache           <= AxiBus.WriteAddress.Cache;
  axi4_si.aw.prot            <= AxiBus.WriteAddress.Prot;
  axi4_si.aw.qos             <= AxiBus.WriteAddress.QOS;
  axi4_si.aw.valid           <= AxiBus.WriteAddress.Valid;
  axi4_si.w.data             <= AxiBus.WriteData.Data;
  axi4_si.w.strb             <= AxiBus.WriteData.Strb;
  axi4_si.w.last             <= AxiBus.WriteData.Last;
  axi4_si.w.valid            <= AxiBus.WriteData.Valid;
  axi4_si.b.ready            <= AxiBus.WriteResponse.Ready;
  axi4_si.ar.id              <= AxiBus.ReadAddress.ID;
  axi4_si.ar.addr            <= AxiBus.ReadAddress.Addr;
  axi4_si.ar.len             <= AxiBus.ReadAddress.Len;
  axi4_si.ar.size            <= AxiBus.ReadAddress.Size;
  axi4_si.ar.burst           <= AxiBus.ReadAddress.Burst;
  axi4_si.ar.cache           <= AxiBus.ReadAddress.Cache;
  axi4_si.ar.prot            <= AxiBus.ReadAddress.Prot;
  axi4_si.ar.qos             <= AxiBus.ReadAddress.QOS;
  axi4_si.ar.valid           <= AxiBus.ReadAddress.Valid;
  axi4_si.r.ready            <= AxiBus.ReadData.Ready;

  -- connect OSVVM AXI master inputs to DUT AXI slave outputs
  AxiBus.WriteAddress.Ready  <= axi4_so.aw.ready;
  AxiBus.WriteData.Ready     <= axi4_so.w.ready;
  AxiBus.WriteResponse.ID    <= axi4_so.b.id;
  AxiBus.WriteResponse.Resp  <= axi4_so.b.resp;
  AxiBus.WriteResponse.Valid <= axi4_so.b.valid;
  AxiBus.ReadAddress.Ready   <= axi4_so.ar.ready;
  AxiBus.ReadData.ID         <= axi4_so.r.id;
  AxiBus.ReadData.Data       <= axi4_so.r.data;
  AxiBus.ReadData.Resp       <= axi4_so.r.resp;
  AxiBus.ReadData.Last       <= axi4_so.r.last;
  AxiBus.ReadData.Valid      <= axi4_so.r.valid;

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