--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package model_rgmii_rx_pkg is

  component model_rgmii_rx is
  port (
      i_clk : in    std_ulogic;
      i_ctl : in    std_ulogic;
      i_d   : in    std_ulogic_vector(3 downto 0);
      o_en  : out   std_ulogic;
      o_er  : out   std_ulogic;
      o_d   : out   std_ulogic_vector(7 downto 0)
  );
  end component model_rgmii_rx;

end package model_rgmii_rx_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity model_rgmii_rx is
  port (
    i_clk : in    std_ulogic;
    i_ctl : in    std_ulogic;
    i_d   : in    std_ulogic_vector(3 downto 0);
    o_en  : out   std_ulogic;
    o_er  : out   std_ulogic;
    o_d   : out   std_ulogic_vector(7 downto 0)
  );
end entity model_rgmii_rx;

architecture model of model_rgmii_rx is

    signal ctl_r : std_ulogic;
    signal ctl_f : std_ulogic;
    signal d_r   : std_ulogic_vector(3 downto 0);
    signal d_f   : std_ulogic_vector(3 downto 0);

begin

  -- TODO detect speed, handle 10/100 differently

  P_MAIN: process(i_clk)
  begin
    if rising_edge(i_clk) then
      ctl_r <= i_ctl;
      d_r   <= i_d;
      o_en  <= ctl_r;
      o_er  <= ctl_f;
      o_d   <= d_f & d_r;
    elsif falling_edge(i_clk) then
      ctl_f <= i_ctl;
      d_f   <= i_d;
    end if;
  end process;

end architecture model;
