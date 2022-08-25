--------------------------------------------------------------------------------

library ieee ;
  use ieee.std_logic_1164.all ;

library OSVVM_Common ;
  context OSVVM_Common.OsvvmCommonContext ;

package TestCtrlPkg is

  component TestCtrl is
    generic (
      TbName              : string ;
      ValidatedResultsDir : string
    ) ;
    port (
      Reset        : In    std_logic ;
      RegMasterRec : InOut AddressBusRecType
    ) ;
  end component TestCtrl ;

end package TestCtrlPkg ;

--------------------------------------------------------------------------------

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;

library osvvm ;
  context osvvm.OsvvmContext ;

library OSVVM_Common ;
  context OSVVM_Common.OsvvmCommonContext ;

library work ;
  use work.r6522_pkg.all ;

entity TestCtrl is
  generic (
    TbName              : string ;
    ValidatedResultsDir : string
  ) ;
  port (
    Reset        : In    std_logic ;
    RegMasterRec : InOut AddressBusRecType
  ) ;
end entity TestCtrl;
