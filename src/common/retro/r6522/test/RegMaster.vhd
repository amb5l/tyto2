--------------------------------------------------------------------------------

library ieee ;
  use ieee.std_logic_1164.all ;

library OSVVM_Common ;
  context OSVVM_Common.OsvvmCommonContext ;

package RegMasterPkg is

  component RegMaster is
    port (
      -- Register Bus
      RegClk   : In  std_logic ;                    -- clock
      RegClkEn : In  std_logic ;                    -- clock enable
      RegRst   : In  std_logic ;                    -- reset
      RegCs    : Out std_logic ;                    -- chip select
      RegWe    : Out std_logic ;                    -- write enable
      RegRs    : Out std_logic_vector(3 downto 0) ; -- register select
      RegDw    : Out std_logic_vector(7 downto 0) ; -- write data
      RegDr    : In  std_logic_vector(7 downto 0) ; -- read data
      RegIrq   : In  std_logic ;                    -- interrupt request
      -- Testbench Transaction Interface
      TransRec : InOut AddressBusRecType
    ) ;
  end component RegMaster ;

end package RegMasterPkg ;

--------------------------------------------------------------------------------

library ieee ;
  use ieee.std_logic_1164.all ;

library osvvm ;
  context osvvm.OsvvmContext ;

library OSVVM_Common ;
  context OSVVM_Common.OsvvmCommonContext ;

entity RegMaster is
  port (
    -- Register Bus
    RegClk   : In  std_logic ;                    -- clock
    RegClkEn : In  std_logic ;                    -- clock enable
    RegRst   : In  std_logic ;                    -- reset
    RegCs    : Out std_logic ;                    -- chip select
    RegWe    : Out std_logic ;                    -- write enable
    RegRs    : Out std_logic_vector(3 downto 0) ; -- register select
    RegDw    : Out std_logic_vector(7 downto 0) ; -- write data
    RegDr    : In  std_logic_vector(7 downto 0) ; -- read data
    RegIrq   : In  std_logic ;                    -- interrupt request
    -- Testbench Transaction Interface
    TransRec : InOut AddressBusRecType
  ) ;
end entity RegMaster ;

architecture behavioural of RegMaster is
begin

  TransactionHandler: process
  begin
    RegCs <= '0' ;
    RegWe <= '0' ;
    RegRs <= (others => 'U') ;
    RegDw <= (others => 'U') ;
    loop
      WaitForTransaction(
        Clk => RegClk,
        Rdy => TransRec.Rdy,
        Ack => TransRec.Ack
      ) ;
      case TransRec.Operation is
        when WRITE_OP =>
          RegCs <= '1' ;
          RegWe <= '1' ;
          RegRs <= std_logic_vector(TransRec.Address) ;
          RegDw <= std_logic_vector(TransRec.DataToModel) ;
          wait until rising_edge(RegClk) and RegClkEn = '1' ;
          RegCs <= '0' ;
          RegWe <= '0' ;
          RegRs <= (others => 'U') ;
          RegDw <= (others => 'U') ;
        when READ_OP =>
          RegCs <= '1' ;
          RegRs <= std_logic_vector(TransRec.Address) ;
          wait until rising_edge(RegClk) and RegClkEn = '1' ;
          RegCs <= '0' ;
          RegRs <= (others => 'U') ;
          TransRec.DataFromModel <= std_logic_vector_max_c(RegDr) ;
        when others =>
          NULL ;
      end case ;
    end loop ;
  end process TransactionHandler ;

end architecture;