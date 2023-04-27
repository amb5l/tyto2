library ieee;
  use ieee.std_logic_1164.all;

library osvvm_common;
  context osvvm_common.OsvvmCommonContext;

package TestCtrl_pkg is

  component TestCtrl is
    port (
      Clk        : in    std_logic;
      nReset     : in    std_logic;
      ManagerRec : inout AddressBusRecType
    );
  end component TestCtrl;

end package TestCtrl_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_Axi4;
  context osvvm_Axi4.Axi4Context;

library work;
  use work.OsvvmTestCommonPkg.all;

entity TestCtrl is
  port (
    Clk        : in    std_logic;
    nReset     : in    std_logic;
    ManagerRec : inout AddressBusRecType
  );
  constant AXI_ADDR_WIDTH : integer := ManagerRec.Address'length;
  constant AXI_DATA_WIDTH : integer := ManagerRec.DataToModel'length;
end entity TestCtrl;
