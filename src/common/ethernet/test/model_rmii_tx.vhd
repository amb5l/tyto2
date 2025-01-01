--------------------------------------------------------------------------------

use work.memac_sim_type_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package model_rmii_tx_pkg is

  component model_rmii_tx is
    port (
      seq_req  : in    mii4_seq_ptr_t;
      seq_lvl  : out   integer;
      rmii_clk : in    std_ulogic;
      rmii_crs : out   std_ulogic;
      rmii_dv  : out   std_ulogic;
      rmii_er  : out   std_ulogic;
      rmii_d   : out   std_ulogic_vector(1 downto 0)
    );
  end component model_rmii_tx;

end package model_rmii_tx_pkg;

--------------------------------------------------------------------------------

use work.memac_sim_type_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity model_rmii_tx is
  generic (
    ALIGN : string
  );
  port (
    spd     : in    std_ulogic_vector(1 downto 0);
    i_pkt   : in    mii4_seq_ptr_t;
    i_ack   : out   bit;
    o_clk   : out   std_ulogic;
    o_ctl   : out   std_ulogic;
    o_d     : out   std_ulogic_vector(3 downto 0)
  );
end entity model_rmii_tx;

architecture model of model_rmii_tx is

  signal div : integer range 0 to 10;

begin



  div <= 10 when spd = '0' else 1 when spd = '1' else 0;


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
