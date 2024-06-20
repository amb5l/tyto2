--------------------------------------------------------------------------------

use work.tyto_types_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package model_rgmii_tx_pkg is

  constant MODEL_RGMII_TX_MTU : integer := 1530;

  type model_rgmii_tx_pkt_data_t is array(0 to MODEL_RGMII_TX_MTU-1) of uint8_t;

  type model_rgmii_tx_pkt_t is record
    len  : integer range 1 to MODEL_RGMII_TX_MTU;
    data : model_rgmii_tx_pkt_data_t;
  end record;

  component model_rgmii_tx is
    generic (
      ALIGN : string
    );
    port (
      spd     : in    std_ulogic_vector(1 downto 0);
      i_pkt   : in    model_rgmii_tx_pkt_t;
      i_ack   : out   bit;
      o_clk   : out   std_ulogic;
      o_ctl   : out   std_ulogic;
      o_d     : out   std_ulogic_vector(3 downto 0)
    );
  end component model_rgmii_tx;

end package model_rgmii_tx_pkg;

--------------------------------------------------------------------------------

use work.model_rgmii_tx_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity model_rgmii_tx is
  generic (
    ALIGN : string
  );
  port (
    spd     : in    std_ulogic_vector(1 downto 0);
    i_pkt   : in    model_rgmii_tx_pkt_t;
    i_ack   : out   bit;
    o_clk   : out   std_ulogic;
    o_ctl   : out   std_ulogic;
    o_d     : out   std_ulogic_vector(3 downto 0)
  );
end entity model_rgmii_tx;

architecture model of model_rgmii_tx is

  signal clk   : std_ulogic := '0';
  signal mult : integer range 0 to 25;

begin

  P_CHECK: process
  begin
    assert ALIGN = "EDGE" or ALIGN = "CENTER" report "ALIGN must be EDGE or CENTER" severity failure;
    wait;
  end process P_CHECK;

  with spd select mult <=
    1  when "00",
    5  when "01",
    25 when "10",
    0  when others;

  clk   <= not clk after mult * 4 ns;
  o_clk <= clk;

  P_OUT: process
    variable v : std_ulogic_vector(7 downto 0);
    procedure align_start is
    begin
      if ALIGN = "CENTER" then
        wait until falling_edge(clk);
        wait for mult * 2 ns;
      else
        wait until rising_edge(clk);
      end if;
    end procedure align_start;
    procedure align_next is
    begin
      if spd = "10" then
        wait until clk'event;
      else
        wait until rising_edge(clk);
      end if;
      if ALIGN = "CENTER" then
        wait for mult * 2 ns;
      end if;
    end procedure align_next;
  begin
    o_ctl <= '0';
    o_d   <= (others => 'X');
    wait until i_pkt'transaction;
    if spd = "00" or spd = "01" or spd = "10" then
      align_start;
      o_ctl <= '1';
      for i in 0 to i_pkt.len-1 loop
        v := std_ulogic_vector(to_unsigned(i_pkt.data(i),8));
        o_d <= v(3 downto 0);
        align_next;
        o_d <= v(7 downto 4);
        align_next;
      end loop;
      o_ctl <= '0';
      o_d   <= (others => 'X');
      i_ack <= '0';
    end if;
  end process P_OUT;

end architecture model;
