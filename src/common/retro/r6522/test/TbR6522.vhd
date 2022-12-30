library ieee ;
  use ieee.std_logic_1164.all ;

library osvvm ;
  context osvvm.OsvvmContext ;

library work;
  use work.R6522_pkg.all ;

entity TbR6522 is
end TbR6522 ;

architecture TestHarness of TbR6522 is

  constant tperiod_Clk      : time := 1 us ;
  signal Clk                : std_logic := '0' ;
  signal nReset             : std_logic ;

  signal dut_cpu_clk        : std_logic;
  signal dut_cpu_clken      : std_logic;
  signal dut_cpu_rst        : std_logic;
  signal dut_cpu_cs         : std_logic;
  signal dut_cpu_we         : std_logic;
  signal dut_cpu_rs         : std_logic_vector(3 downto 0);
  signal dut_cpu_dw         : std_logic_vector(7 downto 0);
  signal dut_cpu_dr         : std_logic_vector(7 downto 0);
  signal dut_cpu_irq        : std_logic;
  signal dut_io_clk         : std_logic;
  signal dut_io_clken       : std_logic;
  signal dut_io_rst         : std_logic;
  signal dut_io_pa_i        : std_logic_vector(7 downto 0);
  signal dut_io_pa_o        : std_logic_vector(7 downto 0);
  signal dut_io_pa_dir      : std_logic_vector(7 downto 0);
  signal dut_io_ca1         : std_logic;
  signal dut_io_ca2_i       : std_logic;
  signal dut_io_ca2_o       : std_logic;
  signal dut_io_ca2_dir     : std_logic;
  signal dut_io_pb_i        : std_logic_vector(7 downto 0);
  signal dut_io_pb_o        : std_logic_vector(7 downto 0);
  signal dut_io_pb_dir      : std_logic_vector(7 downto 0);
  signal dut_io_cb1_i       : std_logic;
  signal dut_io_cb1_o       : std_logic;
  signal dut_io_cb1_dir     : std_logic;
  signal dut_io_cb2_i       : std_logic;
  signal dut_io_cb2_o       : std_logic;
  signal dut_io_cb2_dir     : std_logic

  signal dut_reg_irb   : std_logic_vector(7 downto 0);
  signal dut_reg_ira   : std_logic_vector(7 downto 0);
  signal dut_reg_orb   : std_logic_vector(7 downto 0);
  signal dut_reg_ora   : std_logic_vector(7 downto 0);
  signal dut_reg_ddrb  : std_logic_vector(7 downto 0);
  signal dut_reg_ddra  : std_logic_vector(7 downto 0);
  signal dut_reg_t1c   : std_logic_vector(15 downto 0);
  signal dut_reg_t1l   : std_logic_vector(15 downto 0);
  signal dut_reg_t2c   : std_logic_vector(15 downto 0);
  signal dut_reg_t2l_l : std_logic_vector(7 downto 0);
  signal dut_reg_sr    : std_logic_vector(7 downto 0);
  signal dut_reg_acr   : std_logic_vector(7 downto 0);
  signal dut_reg_pcr   : std_logic_vector(7 downto 0);
  signal dut_reg_ifr   : std_logic_vector(7 downto 0);
  signal dut_reg_ier   : std_logic_vector(7 downto 0);

  signal dut_reg       : slv_vector(0 to 14)(7 downto 0);



  component TestCtrl
  generic (
    tperiod_Clk           : time := 10 ns
  ) ;
  port (
    UartTxRec          : InOut UartRecType ;
    UartRxRec          : InOut UartRecType ;

    Clk                : In    std_logic ;
    nReset             : In    std_logic
  ) ;
  end component ;

  signal UartTxRec           : UartRecType ;
  signal UartRxRec           : UartRecType ;

begin

  Osvvm.TbUtilPkg.CreateClock (
    Clk        => Clk,
    Period     => tperiod_Clk
  )  ;

  Osvvm.TbUtilPkg.CreateReset (
    Reset       => nReset,
    ResetActive => '0',
    Clk         => Clk,
    Period      => 7 * tperiod_Clk,
    tpd         => tpd
  ) ;

  DUT : component R6522
  port map (
    cpu_clk    => dut_cpu_clk,
    cpu_clken  => dut_cpu_clken,
    cpu_rst    => dut_cpu_rst,
    cpu_cs     => dut_cpu_cs,
    cpu_we     => dut_cpu_we,
    cpu_rs     => dut_cpu_rs,
    cpu_dw     => dut_cpu_dw,
    cpu_dr     => dut_cpu_dr,
    cpu_irq    => dut_cpu_irq,
    io_clk     => dut_io_clk,
    io_clken   => dut_io_clken,
    io_rst     => dut_io_rst,
    io_pa_i    => dut_io_pa_i,
    io_pa_o    => dut_io_pa_o,
    io_pa_dir  => dut_io_pa_dir,
    io_ca1     => dut_io_ca1,
    io_ca2_i   => dut_io_ca2_i,
    io_ca2_o   => dut_io_ca2_o,
    io_ca2_dir => dut_io_ca2_dir,
    io_pb_i    => dut_io_pb_i,
    io_pb_o    => dut_io_pb_o,
    io_pb_dir  => dut_io_pb_dir,
    io_cb1_i   => dut_io_cb1_i,
    io_cb1_o   => dut_io_cb1_o,
    io_cb1_dir => dut_io_cb1_dir,
    io_cb2_i   => dut_io_cb2_i,
    io_cb2_o   => dut_io_cb2_o,
    io_cb2_dir => dut_io_cb2_dir
  )

  dut_reg_irb   <= << TbR6522.DUT.irb   : std_logic_vector(7 downto 0)  >>;
  dut_reg_ira   <= << TbR6522.DUT.ira   : std_logic_vector(7 downto 0)  >>;
  dut_reg_orb   <= << TbR6522.DUT.orb   : std_logic_vector(7 downto 0)  >>;
  dut_reg_ora   <= << TbR6522.DUT.ora   : std_logic_vector(7 downto 0)  >>;
  dut_reg_ddrb  <= << TbR6522.DUT.ddrb  : std_logic_vector(7 downto 0)  >>;
  dut_reg_ddra  <= << TbR6522.DUT.ddra  : std_logic_vector(7 downto 0)  >>;
  dut_reg_t1c   <= << TbR6522.DUT.t1c   : std_logic_vector(15 downto 0) >>;
  dut_reg_t1l   <= << TbR6522.DUT.t1l   : std_logic_vector(15 downto 0) >>;
  dut_reg_t2c   <= << TbR6522.DUT.t2c   : std_logic_vector(15 downto 0) >>;
  dut_reg_t2l_l <= << TbR6522.DUT.t2l_l : std_logic_vector(7 downto 0)  >>;
  dut_reg_sr    <= << TbR6522.DUT.sr    : std_logic_vector(7 downto 0)  >>;
  dut_reg_acr   <= << TbR6522.DUT.acr   : std_logic_vector(7 downto 0)  >>;
  dut_reg_pcr   <= << TbR6522.DUT.pcr   : std_logic_vector(7 downto 0)  >>;
  dut_reg_ifr   <= << TbR6522.DUT.ifr   : std_logic_vector(7 downto 0)  >>;
  dut_reg_ier   <= << TbR6522.DUT.ier   : std_logic_vector(7 downto 0)  >>;

  dut_reg(0)  <= dut_reg_orb;
  dut_reg(1)  <= dut_reg_ora;
  dut_reg(2)  <= dut_reg_ddrb;
  dut_reg(3)  <= dut_reg_ddra;
  dut_reg(4)  <= dut_reg_t1c(7 downto 0);
  dut_reg(5)  <= dut_reg_t1c(15 downto 8);
  dut_reg(6)  <= dut_reg_t1l(7 downto 0);
  dut_reg(7)  <= dut_reg_t1l(15 downto 8);
  dut_reg(8)  <= dut_reg_t2c(7 downto 0);
  dut_reg(9)  <= dut_reg_t2c(15 downto 8);
  dut_reg(10) <= dut_reg_sr;
  dut_reg(11) <= dut_reg_acr;
  dut_reg(12) <= dut_reg_pcr;
  dut_reg(13) <= dut_reg_ifr;
  dut_reg(14) <= dut_reg_ier;

  Sbi_1: component Sbi
  port map (
    clk      => dut_cpu_clk
    clken    => dut_cpu_clken
    cs       => dut_cpu_cs,
    we       => dut_cpu_we,
    a(0)     => dut_cpu_rs,
    dw       => dut_cpu_dw,
    dr       => dut_cpu_dr,
    TransRec => SbiRec
  );

  TestCtrl_1 : component TestCtrl
  generic map (
    tperiod_Clk  => tperiod_Clk
  )
  port map (
    UartTxRec    => UartTxRec,
    UartRxRec    => UartRxRec,

    Clk          => Clk,
    nReset       => nReset
  ) ;

end TestHarness ;

  -- initialise registers, check pin states


-- write assorted values to each register
-- toggle all bits, verify that no other register changes value

  for v = 0 to 1 loop
    for b = 0 to 7 loop
      x 
    end loop;
  end loop;
  
  -- walking bit
  reg_write(R6522_RA_ORB,value);
  
