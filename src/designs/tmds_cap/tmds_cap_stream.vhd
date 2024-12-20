--------------------------------------------------------------------------------
-- tmds_cap_stream.vhd                                                        --
-- Stream module for tmds_cap design.                                         --
--------------------------------------------------------------------------------
-- (C) Copyright 2023 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi4s_pkg.all;

package tmds_cap_stream_pkg is

  component tmds_cap_stream is
    port (

      prst        : in    std_logic;
      pclk        : in    std_logic;
      tmds_lock   : in    std_logic;
      tmds        : in    slv10_vector(0 to 2);

      cap_rst     : in    std_logic;
      cap_size    : in    std_logic_vector(31 downto 0);
      cap_en      : in    std_logic;
      cap_test    : in    std_logic;

      cap_run     : out   std_logic;
      cap_stop    : out   std_logic;
      cap_loss    : out   std_logic;
      cap_ovf     : out   std_logic;
      cap_unf     : out   std_logic;
      cap_count   : out   std_logic_vector(31 downto 0);

      axi_clk     : in    std_logic;
      axi_rst_n   : in    std_logic;
      maxi4s_mosi : out   axi4s_64_mosi_t := AXI4S_64_MOSI_DEFAULT;
      maxi4s_miso : in    axi4s_64_miso_t := AXI4S_64_MISO_DEFAULT

    );
  end component tmds_cap_stream;

end package tmds_cap_stream_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.sync_reg_pkg.all;
  use work.axi4s_pkg.all;

library unisim;
  use unisim.vcomponents.all;

entity tmds_cap_stream is
  port (

    prst        : in    std_logic;
    pclk        : in    std_logic;
    tmds_lock   : in    std_logic;
    tmds        : in    slv10_vector(0 to 2);

    cap_rst     : in    std_logic;                     -- capture reset
    cap_size    : in    std_logic_vector(31 downto 0); -- capture size (pixels)
    cap_en      : in    std_logic;                     -- capture enable
    cap_test    : in    std_logic;                     -- capture test

    cap_run     : out   std_logic;                     -- capture running
    cap_stop    : out   std_logic;                     -- capture stopped
    cap_loss    : out   std_logic;                     -- loss of TMDS lock
    cap_ovf     : out   std_logic;                     -- FIFO overflow
    cap_unf     : out   std_logic;                     -- FIFO underflow
    cap_count   : out   std_logic_vector(31 downto 0); -- capture count (pixels)

    axi_clk     : in    std_logic;
    axi_rst_n   : in    std_logic;
    maxi4s_mosi : out   axi4s_64_mosi_t := AXI4S_64_MOSI_DEFAULT;
    maxi4s_miso : in    axi4s_64_miso_t := AXI4S_64_MISO_DEFAULT

  );
end entity tmds_cap_stream;

architecture synth of tmds_cap_stream is

  signal tmds_loss     : std_logic;                        -- loss of TMDS lock
  signal cap_rst_s     : std_logic;                        -- capture reset, synchronized
  signal cap_en_s      : std_logic;                        -- capture enable, synchronized
  signal cap_en_s1     : std_logic;                        -- capture enable, synchronized, delayed by 1 clock
  signal fifo_we       : std_logic;                        -- FIFO write enable
  signal fifo_wd       : std_logic_vector( 63 downto 0 );  -- FIFO write data
  signal fifo_wx       : std_logic_vector(  7 downto 0 );  -- FIFO write extras
  signal fifo_re       : std_logic;                        -- FIFO read enable
  signal fifo_rd       : std_logic_vector( 63 downto 0 );  -- FIFO read data
  signal fifo_rx       : std_logic_vector(  7 downto 0 );  -- FIFO read extras
  signal fifo_ef       : std_logic;                        -- FIFO empty flag

  alias fifo_wd_lo   : std_logic_vector( 31 downto 0 ) is fifo_wd( 31 downto  0 );
  alias fifo_wd_hi   : std_logic_vector( 31 downto 0 ) is fifo_wd( 63 downto 32 );
  alias fifo_wx_lo   : std_logic is fifo_wx(0); -- lo 32 bits are valid
  alias fifo_wx_hi   : std_logic is fifo_wx(1); -- hi 32 bits are valid
  alias fifo_wx_last : std_logic is fifo_wx(2); -- this 64 bit word is last
  alias fifo_rx_lo   : std_logic is fifo_rx(0);
  alias fifo_rx_hi   : std_logic is fifo_rx(1);
  alias fifo_rx_last : std_logic is fifo_rx(2);

begin

  -- loss latch

  tmds_loss <= prst or not tmds_lock;

  process(cap_rst,tmds_loss)
  begin
    if cap_rst = '1' then
      cap_loss <= '0';
    elsif tmds_loss = '1' then
      cap_loss <= '1';
    end if;
  end process;

  -- synchronisers

  U_SYNC1: component sync_reg
    port map(
      rst  => prst,
      clk  => pclk,
      d(0) => cap_en,
      q(0) => cap_en_s
    );

  U_SYNC2: component sync_reg
    port map(
      rst  => prst,
      clk  => pclk,
      d(0) => cap_rst,
      q(0) => cap_rst_s
    );

  -- TMDS stream ---> FIFO

  process(cap_rst_s,pclk)
  begin
    if cap_rst_s = '1' then
      cap_en_s1    <= '0';
      cap_run      <= '0';
      cap_stop     <= '0';
      cap_count    <= (others => '0');
      fifo_we      <= '0';
      fifo_wd      <= (others => '0');
      fifo_wx_lo   <= '0';
      fifo_wx_hi   <= '0';
      fifo_wx_last <= '0';
    elsif rising_edge(pclk) then
      cap_en_s1 <= cap_en_s;
      if cap_en_s = '1' and cap_en_s1 = '0' then
        cap_run   <= '1';
        cap_stop  <= '0';
        cap_count <= (others => '0');
      end if;
      if cap_run = '1' then
        fifo_we      <= '0';
        fifo_wx_last <= '0';
        if cap_count(0) = '0' then
          fifo_wd_lo <= not cap_count when cap_test = '1' else "00" & tmds(2) & tmds(1) & tmds(0);
          fifo_wx_lo <= '1';
          fifo_wx_hi <= '0';
        else
          fifo_wd_hi <= not cap_count when cap_test = '1' else "00" & tmds(2) & tmds(1) & tmds(0);
          fifo_wx_hi <= '1';
          fifo_we    <= '1';
        end if;
        if std_logic_vector(unsigned(cap_count)+1) = cap_size then
          fifo_wx_last <= '1';
          fifo_we      <= '1';
          cap_run      <= '0';
          cap_stop     <= '1';
        end if;
        cap_count <= std_logic_vector(unsigned(cap_count)+1);
      else
        fifo_we      <= '0';
        fifo_wd      <= (others => '0');
        fifo_wx_lo   <= '0';
        fifo_wx_hi   <= '0';
        fifo_wx_last <= '0';
      end if;
    end if;
  end process;

  -- FIFO

  FIFO : fifo36e1
    generic map (
      almost_empty_offset     => x"0010",
      almost_full_offset      => x"01F0",
      data_width              => 72,
      do_reg                  => 1,
      en_ecc_read             => false,
      en_ecc_write            => false,
      en_syn                  => false,
      fifo_mode               => "FIFO36_72",
      first_word_fall_through => true,
      init                    => x"000000000000000000",
      sim_device              => "7SERIES",
      srval                   => x"000000000000000000"
    )
    port map (
      wrclk         => pclk,
      wren          => fifo_we,
      di            => fifo_wd,
      dip           => fifo_wx,
      rdclk         => axi_clk,
      rden          => fifo_re,
      regce         => '1',
      rst           => cap_rst,
      rstreg        => not axi_rst_n,
      do            => fifo_rd,
      dop           => fifo_rx,
      almostempty   => open,
      almostfull    => open,
      empty         => fifo_ef,
      full          => open,
      rdcount       => open,
      rderr         => cap_unf,
      wrcount       => open,
      wrerr         => cap_ovf,
      injectdbiterr => '0',
      injectsbiterr => '0',
      dbiterr       => open,
      eccparity     => open,
      sbiterr       => open
    );

  -- FIFO ---> AXI stream

  fifo_re <= maxi4s_mosi.tvalid and maxi4s_miso.tready;

  maxi4s_mosi.tdata             <= fifo_rd;
  maxi4s_mosi.tkeep(3 downto 0) <= (others => fifo_rx_lo);
  maxi4s_mosi.tkeep(7 downto 4) <= (others => fifo_rx_hi);
  maxi4s_mosi.tvalid            <= not fifo_ef;
  maxi4s_mosi.tlast             <= fifo_rx_last;

end architecture synth;
