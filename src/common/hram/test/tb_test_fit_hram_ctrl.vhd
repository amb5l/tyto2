library ieee;
  use ieee.std_logic_1164.all;

entity tb_test_fit_hram_ctrl is
end entity tb_test_fit_hram_ctrl;

architecture sim of tb_test_fit_hram_ctrl is

  signal ref_rst   : std_ulogic;
  signal ref_clk   : std_ulogic;
  signal s_a_ready : std_ulogic;
  signal s_a_valid : std_ulogic;
  signal s_a_r_w   : std_ulogic;
  signal s_a_reg   : std_ulogic;
  signal s_a_wrap  : std_ulogic;
  signal s_a_size  : std_ulogic_vector(5 downto 0);
  signal s_a_addr  : std_ulogic_vector(22 downto 1);
  signal s_w_ready : std_ulogic;
  signal s_w_valid : std_ulogic;
  signal s_w_be    : std_ulogic_vector(1 downto 0);
  signal s_w_data  : std_ulogic_vector(15 downto 0);
  signal s_r_ready : std_ulogic;
  signal s_r_valid : std_ulogic;
  signal s_r_data  : std_ulogic_vector(15 downto 0);
  signal h_rst_n   : std_logic;
  signal h_cs_n    : std_logic;
  signal h_clk     : std_logic;
  signal h_rwds    : std_logic;
  signal h_dq      : std_logic_vector(7 downto 0);

begin

  ref_rst <= '1', '0' after 100 ns;
  ref_clk <= '0' when 'U' else not ref_clk after 5 ns;

  P_MAIN: process
  begin
  end process P_MAIN;

  DUT: entity work.test_fit_hram_ctrl
    port map (
      ref_rst   => ref_rst,
      ref_clk   => ref_clk,
      s_a_ready => s_a_ready,
      s_a_valid => s_a_valid,
      s_a_r_w   => s_a_r_w,
      s_a_reg   => s_a_reg,
      s_a_wrap  => s_a_wrap,
      s_a_size  => s_a_size,
      s_a_addr  => s_a_addr,
      s_w_ready => s_w_ready,
      s_w_valid => s_w_valid,
      s_w_be    => s_w_be,
      s_w_data  => s_w_data,
      s_r_ready => s_r_ready,
      s_r_valid => s_r_valid,
      s_r_data  => s_r_data,
      h_rst_n   => h_rst_n,
      h_cs_n    => h_cs_n,
      h_clk     => h_clk,
      h_rwds    => h_rwds,
      h_dq      => h_dq
    );

end architecture sim;