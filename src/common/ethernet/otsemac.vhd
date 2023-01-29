package otsemac_pkg is

  -- registers
  constant OTSEMAC_REG_CTRL : std_logic_vector(7 downto 0) := x"00";


end package otsemac_pkg;

entity otsemac is
  port (

    -- host reset and clock
    rst     : in    std_logic;
    clk     : in    std_logic;

    -- host register port

    -- host transmit data port

    -- host receive data port

    -- GMII (convert to RGMII externally)
    gtxclk  : out   std_logic;                    -- 1000BaseT clock (125MHz)
    txclk   : out   std_logic;                    -- 100/10BaseT clock (25/2.5MHz)
    txen    : out   std_logic;                    -- transmit enable
    txer    : out   std_logic;                    -- transmit error
    txd     : out   std_logic_vector(7 downto 0); -- transmit data
    rxclk   : in    std_logic;                    -- receive clock
    rxdv    : in    std_logic;                    -- receive data valid
    rxer    : in    std_logic;                    -- receive error
    rxd     : in    std_logic_vector(7 downto 0); -- receive data

    -- MDIO
    mdc     : out   std_logic;
    mdio    : inout std_logic

  );
end entity otsemac;

architecture synth of otsemac is
begin
end architecture synth;
