--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package MEGAtest_pkg is

  component MEGAtest is
    generic (
      BOARD_REV  : bit_vector( 3 downto 0) := "0000";
      GIT_COMMIT : bit_vector(31 downto 0) := (others => '0')
    );
    port (
      ref_rst     : in    std_ulogic;
      ref_clk     : in    std_ulogic;
      hram_rst_n  : out   std_logic;
      hram_cs_n   : out   std_logic;
      hram_clk    : out   std_logic;
      hram_rwds   : inout std_logic;
      hram_dq     : inout std_logic_vector(7 downto 0);
      hdmi_clk_p  : out   std_ulogic;
      hdmi_clk_n  : out   std_ulogic;
      hdmi_data_p : out   std_ulogic_vector(0 to 2);
      hdmi_data_n : out   std_ulogic_vector(0 to 2)
    );
  end component MEGAtest;

end package MEGAtest_pkg;

--------------------------------------------------------------------------------

use work.clk_rst_pkg.all;
use work.cpu_pkg.all;
use work.temp_sense_pkg.all;
use work.hram_test_pkg.all;
use work.display_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity MEGAtest is
  generic (
    BOARD_REV  : bit_vector( 3 downto 0) := "0000";
    GIT_COMMIT : bit_vector(31 downto 0) := (others => '0')
  );
  port (

    ref_rst     : in    std_ulogic;
    ref_clk     : in    std_ulogic;

    hram_rst_n  : out   std_logic;
    hram_cs_n   : out   std_logic;
    hram_clk    : out   std_logic;
    hram_rwds   : inout std_logic;
    hram_dq     : inout std_logic_vector(7 downto 0);

    hdmi_clk_p  : out   std_ulogic;
    hdmi_clk_n  : out   std_ulogic;
    hdmi_data_p : out   std_ulogic_vector(0 to 2);
    hdmi_data_n : out   std_ulogic_vector(0 to 2)
  );
end entity MEGAtest;

architecture rtl of MEGAtest is

  signal s_rst      : std_ulogic;
  signal s_clk      : std_ulogic;

  signal vid_params : display_params_t;
  signal vid_en     : std_ulogic;
  signal vid_we     : std_ulogic_vector(3 downto 0);
  signal vid_addr   : std_ulogic_vector(14 downto 2);
  signal vid_dout   : std_ulogic_vector(31 downto 0);
  signal vid_din    : std_ulogic_vector(31 downto 0);

  signal ts_en      : std_ulogic;
  signal ts_we      : std_ulogic;
  signal ts_addr    : std_ulogic_vector(6 downto 0);
  signal ts_dout    : std_ulogic_vector(15 downto 0);
  signal ts_din     : std_ulogic_vector(15 downto 0);
  signal ts_rdy     : std_ulogic;
  signal ts_bsy     : std_ulogic;

  signal ht_en      : std_ulogic;
  signal ht_we      : std_ulogic_vector(3 downto 0);
  signal ht_addr    : std_ulogic_vector(7 downto 2);
  signal ht_din     : std_ulogic_vector(31 downto 0);
  signal ht_dout    : std_ulogic_vector(31 downto 0);

begin

  U_CLK_RST: component clk_rst
    port map (
      ref_rst     => ref_rst,
      ref_clk     => ref_clk,
      s_rst       => s_rst,
      s_clk       => s_clk,
      s_clk_dly   => open
    );

  U_CPU: component cpu
    generic map (
      BOARD_REV  => BOARD_REV,
      GIT_COMMIT => GIT_COMMIT
    )
    port map (
      rst        => s_rst,
      clk        => s_clk,
      vtg_mode   => vid_params.mode,
      txt_params => vid_params.txt_params,
      buf_en     => vid_en,
      buf_we     => vid_we,
      buf_addr   => vid_addr,
      buf_dout   => vid_dout,
      buf_din    => vid_din,
      ts_en      => ts_en,
      ts_we      => ts_we,
      ts_addr    => ts_addr,
      ts_dout    => ts_dout,
      ts_din     => ts_din,
      ts_rdy     => ts_rdy,
      ts_bsy     => ts_bsy,
      ht_en      => ht_en,
      ht_we      => ht_we,
      ht_addr    => ht_addr,
      ht_dout    => ht_dout,
      ht_din     => ht_din
    );

  U_DISPLAY: component display
    port map (
      cpu_params  => vid_params,
      cpu_clk     => s_clk,
      cpu_en      => vid_en,
      cpu_we      => vid_we,
      cpu_addr    => vid_addr,
      cpu_din     => vid_dout,
      cpu_dout    => vid_din,
      ref_rst     => ref_rst,
      ref_clk     => ref_clk,
      hdmi_clk_p  => hdmi_clk_p,
      hdmi_clk_n  => hdmi_clk_n,
      hdmi_data_p => hdmi_data_p,
      hdmi_data_n => hdmi_data_n
    );

  U_TEMP: component temp_sense
    port map (
      rst  => s_rst,
      clk  => s_clk,
      en   => ts_en,
      we   => ts_we,
      addr => ts_addr,
      din  => ts_dout,
      dout => ts_din,
      rdy  => ts_rdy,
      bsy  => ts_bsy
    );

  U_HRAM_TEST: component hram_test
    generic map (
      ROWS_LOG2 => 13,
      COLS_LOG2 => 9
    )
    port map (
      x_rst   => ref_rst,
      x_clk   => ref_clk,
      s_rst   => s_rst,
      s_clk   => s_clk,
      s_en    => ht_en,
      s_we    => ht_we,
      s_addr  => ht_addr,
      s_din   => ht_dout,
      s_dout  => ht_din,
      h_rst_n => hram_rst_n,
      h_cs_n  => hram_cs_n,
      h_clk   => hram_clk,
      h_rwds  => hram_rwds,
      h_dq    => hram_dq
    );

end architecture rtl;

--------------------------------------------------------------------------------
