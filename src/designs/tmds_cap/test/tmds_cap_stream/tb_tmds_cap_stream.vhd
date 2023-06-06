library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.Axi4Context;

library work;
  use work.axi4s_pkg.all;
  use work.tyto_types_pkg.all;
  use work.tmds_cap_stream_pkg.all;
  use work.TestCtrl_pkg.all;

entity tb_tmds_cap_stream is
end entity tb_tmds_cap_stream;

architecture sim of tb_tmds_cap_stream is

  signal Clk    : std_logic;
  signal nReset : std_logic;

  signal prst       : std_logic;
  signal pclk       : std_logic;
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
  signal axi_clk    : std_logic;
  signal axi_rst_n  : std_logic;
  signal axi4s_mosi : axi4s_64_mosi_t;
  signal axi4s_miso : axi4s_64_miso_t;

begin

  Osvvm.TbUtilPkg.CreateClock(
    Clk    => Clk,
    Period => 10 ns
  );

  Osvvm.TbUtilPkg.CreateReset(
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * tperiod_Clk,
    tpd         => 1 ns
  );

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

  -- connect DUT AXI4 Stream transmitter to OSVVM AXI4 Stream transmitter signals


  Receiver_1 : AxiStreamReceiver
    port map (
      Clk       => Clk,
      nReset    => nReset,
      TValid    => axi4s_mosi.tvalid,
      TReady    => axi4s_miso.tready,
      TID       => x"00",
      TDest     => x"00",
      TUser     => x"00",
      TData     => axi4s_mosi.tdata,
      TStrb     => axi4s_mosi.tkeep,
      TKeep     => axi4s_mosi.tkeep,
      TLast     => axi4s_mosi.TxTLast ,

      -- Testbench Transaction Interface
      TransRec  => StreamRxRec
    ) ;


  TestCtrl_1 : TestCtrl
  generic map (
    ID_LEN       => TxTID'length,
    DEST_LEN     => TxTDest'length,
    USER_LEN     => TxTUser'length
  )
  port map (
    -- Globals
    nReset       => nReset,

    -- Testbench Transaction Interfaces
    StreamTxRec  => StreamTxRec,
    StreamRxRec  => StreamRxRec
  ) ;

end architecture sim;