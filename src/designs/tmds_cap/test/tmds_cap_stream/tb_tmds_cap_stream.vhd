library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.AxiStreamContext;

library work;
  use work.axi4s_pkg.all;
  use work.tyto_types_pkg.all;
  use work.tmds_cap_stream_pkg.all;
  use work.TestCtrl_pkg.all;

entity tb_tmds_cap_stream is
end entity tb_tmds_cap_stream;

architecture sim of tb_tmds_cap_stream is

  signal axi_clk    : std_logic;
  signal axi_rst_n  : std_logic;
  signal axi4s_mosi : axi4s_64_mosi_t;
  signal axi4s_miso : axi4s_64_miso_t;

  signal prst       : std_logic;
  signal pclk       : std_logic := '0';
  signal tmds_lock  : std_logic;
  signal tmds       : slv10_vector(0 to 2);
  signal cap_rst    : std_logic;
  signal cap_size   : std_logic_vector(31 downto 0);
  signal cap_en     : std_logic;
  signal cap_test   : std_logic;
  signal cap_run    : std_logic;
  signal cap_stop   : std_logic;
  signal cap_loss   : std_logic;
  signal cap_ovf    : std_logic;
  signal cap_unf    : std_logic;
  signal cap_count  : std_logic_vector(31 downto 0);

  signal tmds_count : std_logic_vector(29 downto 0);

  signal tpclk      : time := 10 ns;

  constant AXI_DATA_WIDTH  : integer := axi4s_mosi.tdata'length;
  constant AXI_BYTE_WIDTH  : integer := AXI_DATA_WIDTH/8;
  constant TID_WIDTH   : integer := axi4s_mosi.tid'length;
  constant TDEST_WIDTH : integer := axi4s_mosi.tdest'length;
  constant TUSER_WIDTH : integer := axi4s_mosi.tuser'length;
  constant AXI_PARAM_WIDTH : integer := TID_WIDTH+TDEST_WIDTH+TUSER_WIDTH+1;

  signal RxRec: StreamRecType(
      DataToModel   (  AXI_DATA_WIDTH-1 downto 0 ),
      DataFromModel (  AXI_DATA_WIDTH-1 downto 0 ),
      ParamToModel  ( AXI_PARAM_WIDTH-1 downto 0 ),
      ParamFromModel( AXI_PARAM_WIDTH-1 downto 0 )
    ) ;

begin

  Osvvm.TbUtilPkg.CreateClock(
    Clk    => axi_clk,
    Period => 10 ns
  );

  Osvvm.TbUtilPkg.CreateReset(
    Reset       => axi_rst_n,
    ResetActive => '0',
    Clk         => axi_clk,
    Period      => 100 ns,
    tpd         => 1 ns
  );

  pclk <= not pclk after tpclk/2;

  Osvvm.TbUtilPkg.CreateReset(
    Reset       => prst,
    ResetActive => '1',
    Clk         => pclk,
    Period      => 100 ns,
    tpd         => 1 ns
  );

  Osvvm.TbUtilPkg.CreateReset(
    Reset       => cap_rst,
    ResetActive => '1',
    Clk         => axi_clk,
    Period      => 100 ns,
    tpd         => 1 ns
  );

  DO_TMDS: process(prst,pclk)
  begin
    if prst = '1' then
      tmds_count <= (others => '0');
    elsif rising_edge(pclk) and cap_run = '1' then
      tmds_count <= std_logic_vector(unsigned(tmds_count)+1);
    end if;
  end process DO_TMDS;
  tmds(0) <= tmds_count(  9 downto  0 );
  tmds(1) <= tmds_count( 19 downto 10 );
  tmds(2) <= tmds_count( 29 downto 20 );

  cap_test <= '0';
  DO_CAP: process
  begin
    cap_en <= '0';
    wait until prst = '1';
    wait until prst = '0';
    wait until rising_edge(pclk);
    cap_en <= '1';
    wait until cap_run = '1';
    wait until cap_run = '0';
    wait until rising_edge(pclk);
    cap_en <= '0';
    wait;
  end process;

  DUT: component tmds_cap_stream
    port map (
      prst        => prst,
      pclk        => pclk,
      tmds_lock   => tmds_lock,
      tmds        => tmds,
      cap_rst     => cap_rst,
      cap_size    => cap_size,
      cap_en      => cap_en,
      cap_test    => cap_test,
      cap_run     => cap_run,
      cap_stop    => cap_stop,
      cap_loss    => cap_loss,
      cap_ovf     => cap_ovf,
      cap_unf     => cap_unf,
      cap_count   => cap_count,
      axi_clk     => axi_clk,
      axi_rst_n   => axi_rst_n,
      maxi4s_mosi => axi4s_mosi,
      maxi4s_miso => axi4s_miso
    );

  RX: component AxiStreamReceiver
    port map (
      Clk       => axi_clk,
      nReset    => axi_rst_n,
      TValid    => axi4s_mosi.tvalid,
      TReady    => axi4s_miso.tready,
      TID       => axi4s_mosi.tid,
      TDest     => axi4s_mosi.tdest,
      TUser     => axi4s_mosi.tuser,
      TData     => axi4s_mosi.tdata,
      TStrb     => axi4s_mosi.tkeep,
      TKeep     => axi4s_mosi.tkeep,
      TLast     => axi4s_mosi.tlast,
      TransRec  => RxRec
    ) ;

  CTRL: component TestCtrl
    generic map (
      USER_WIDTH => TUSER_WIDTH
    )
    port map (
      rst_n    => axi_rst_n,
      tpclk    => tpclk,
      cap_size => cap_size,
      RxRec    => RxRec
    ) ;

end architecture sim;
