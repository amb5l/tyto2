library ieee;
  use ieee.std_logic_1164.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_AXI4;
    context osvvm_AXI4.AxiStreamContext;

--library work;
--  use work.OsvvmTestCommonPkg.all;

package TestCtrl_pkg is

  component TestCtrl is
    generic (
      USER_WIDTH : integer
    );
    port (
      rst_n    : in    std_logic;
      tpclk    : out   time := 10 ns;
      cap_size : out   std_logic_vector(31 downto 0);
      cap_test : out   std_logic;
      RxRec    : inout StreamRecType
    );
  end component TestCtrl;

end package TestCtrl_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library osvvm;
  context osvvm.OsvvmContext;

library osvvm_AXI4;
  context osvvm_AXI4.AxiStreamContext;
  use osvvm.ScoreboardPkg_slv.all;

library work;
  use work.OsvvmTestCommonPkg.all;

entity TestCtrl is

  generic (
    USER_WIDTH : integer
  );

  port (
    rst_n    : in    std_logic;
    tpclk    : out   time := 10 ns;
    cap_size : out   std_logic_vector(31 downto 0);
    cap_test : out   std_logic;
    RxRec    : inout StreamRecType
  );

  constant DATA_WIDTH  : integer := RxRec.DataFromModel'length;
  constant DATA_BYTES  : integer := DATA_WIDTH/8;
  constant PARAM_WIDTH : integer := RxRec.ParamFromModel'length;
  constant FirstWord   : std_logic_vector(DATA_WIDTH-1 downto 0) := x"0000000100000000";
  constant IncrWord    : std_logic_vector(DATA_WIDTH-1 downto 0) := x"0000000200000002";

end entity TestCtrl;
