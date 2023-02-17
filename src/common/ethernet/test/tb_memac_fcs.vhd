library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.memac_fcs_pkg.all;

entity tb_memac_fcs is
end entity tb_memac_fcs;

architecture sim of tb_memac_fcs is

  signal rst  : std_logic;
  signal clk  : std_logic := '0';
  signal eni1 : std_logic;
  signal eni2 : std_logic;
  signal di1  : std_logic_vector(7 downto 0);
  signal di2  : std_logic_vector(7 downto 0);
  signal eno  : std_logic;
  signal do   : std_logic_vector(7 downto 0);
  signal ok1  : std_logic;
  signal ok   : std_logic;

begin

  rst <= '1', '0' after 100 ns;

  clk <= not clk after 5 ns;

  process(rst,clk)
  begin
    if rst = '1' then
      di1 <= (others => '0');
      eni1 <= '0';
    elsif rising_edge(clk) then
      di1  <= std_logic_vector(unsigned(di1)+1);
      if unsigned(di1) >= x"08" then
        eni1 <= '0';
      else
        eni1 <= '1';
      end if;
    end if;
  end process;

  DUT1: component memac_fcs
    port map (
      rst => rst,
      clk => clk,
      eni => eni1,
      di  => di1,
      eno => eni2,
      do  => di2,
      ok  => ok1
    );

  DUT2: component memac_fcs
    port map (
      rst => rst,
      clk => clk,
      eni => eni2,
      di  => di2,
      eno => eno,
      do  => do,
      ok  => ok
    );

end architecture sim;
