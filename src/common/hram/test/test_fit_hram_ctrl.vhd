use work.mmcm_v2_pkg.all;
use work.hram_ctrl_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity test_fit_hram_ctrl is
  port (

    --------------------------------------------------------------------------------
    -- refernce clock

    ref_rst   : in    std_ulogic;
    ref_clk   : in    std_ulogic;

    --------------------------------------------------------------------------------
    -- system interface

    -- A (address) channel
    s_a_ready : out   std_ulogic;
    s_a_valid : in    std_ulogic;                        -- strobe
    s_a_r_w   : in    std_ulogic;                        -- 1 = read, 0 = write
    s_a_reg   : in    std_ulogic;                        -- space: 0 = memory, 1 = register
    s_a_wrap  : in    std_ulogic;                        -- burst: 0 = linear, 1 = wrapped/hybrid
    s_a_size  : in    std_ulogic_vector(5 downto 0);     -- burst size
    s_a_addr  : in    std_ulogic_vector(22 downto 1);    -- address

    -- W (write data) channel
    s_w_ready : out   std_ulogic;                        -- ready
    s_w_valid : in    std_ulogic;                        -- valid
    s_w_be    : in    std_ulogic_vector(1 downto 0);     -- byte enable
    s_w_data  : in    std_ulogic_vector(15 downto 0);    -- data

    -- R (read data) channel
    s_r_ready : in    std_ulogic;                        -- ready
    s_r_valid : out   std_ulogic;                        -- valid
    s_r_data  : out   std_ulogic_vector(15 downto 0);    -- data

    --------------------------------------------------------------------------------
    -- HyperRAM interface

    h_rst_n   : out   std_logic;                         -- reset
    h_cs_n    : out   std_logic;                         -- chip select
    h_clk     : out   std_logic;                         -- clock
    h_rwds    : inout std_logic;                         -- read/write data strobe
    h_dq      : inout std_logic_vector(7 downto 0)       -- data bus


  );
end entity test_fit_hram_ctrl;

architecture rtl of test_fit_hram_ctrl is

  signal clk_200m  : std_ulogic;
  signal s_rst     : std_ulogic;
  signal s_clk     : std_ulogic;
  signal s_clk_dly : std_ulogic;

begin

  -- generate IDELAYCTRL ref clock and system clock (normal and delayed)
  U_MMCM: component mmcm_v2 -- v4p ignore w-301 (missing output port associations)
    generic map (
      mul    => 10.0,
      div    => 1,
      odiv0  => 5.0,
      odiv1  => 10,
      odiv2  => 10,
      phase2 => 270.0
    )
    port map (
      rsti  => ref_rst,
      clki  => ref_clk,
      rsto  => s_rst,
      clk0  => clk_200m,
      clk1  => s_clk,
      clk2  => s_clk_dly
    );

  U_IDELAYCTRL: component idelayctrl
    port map (
      rst    => s_rst,
      refclk => clk_200m,
      rdy    => open
    );

  U_CTRL: component hram_ctrl
    generic map (
      A_MSB    => s_a_addr'high,
      B_MSB    => s_a_size'high,
      PARAMS   => HRAM_CTRL_PARAMS_133_100
    )
    port map (
      s_rst     => s_rst,
      s_clk     => s_clk,
      s_clk_dly => s_clk_dly,
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

end architecture rtl;
