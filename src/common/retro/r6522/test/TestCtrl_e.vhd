library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  use std.textio.all ;

library OSVVM ;
  context OSVVM.OsvvmContext ;

use work.OsvvmTestCommonPkg.all ;

entity TestCtrl is
  generic (
    tperiod_Clk           : time := 1 us
  ) ;
  port (
    -- Record Interface
    UartTxRec           : InOut UartRecType ;
    UartRxRec           : InOut UartRecType ;

    -- Global Signal Interface
    Clk                 : In    std_logic ;
    nReset              : In    std_logic
  ) ;
end TestCtrl ;