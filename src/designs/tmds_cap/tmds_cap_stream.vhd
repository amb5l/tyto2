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
  use work.axi_pkg.all;


package tmds_cap_stream_pkg is

  component tmds_cap_stream is
    port (

      prst       : in    std_logic;
      pclk       : in    std_logic;
      tmds       : in    slv10_vector(0 to 2);

      cap_rst    : in    std_logic;
      cap_size   : in    std_logic_vector(31 downto 0);
      cap_go     : in    std_logic;
      cap_done   : out   std_logic;
      cap_error  : out   std_logic;

      axi_clk    : in    std_logic;
      axi_rst_n  : in    std_logic;
      maxis_mosi : out   axi4s_mosi_64_t;
      maxis_miso : in    axi4s_miso_64_t

    );
  end component tmds_cap_stream;

end package tmds_cap_stream_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.axi_pkg.all;

library unisim;
  use unisim.vcomponents.all;

entity tmds_cap_stream is
  port (

    prst       : in    std_logic;
    pclk       : in    std_logic;
    tmds       : in    slv10_vector(0 to 2);

    cap_rst    : in    std_logic;
    cap_size   : in    std_logic_vector(31 downto 0);
    cap_go     : in    std_logic;
    cap_done   : out   std_logic;
    cap_error  : out   std_logic;

    axi_clk    : in    std_logic;
    axi_rst_n  : in    std_logic;
    maxis_mosi : out   axi4s_mosi_64_t;
    maxis_miso : in    axi4s_miso_64_t

  );
end entity tmds_cap_stream;

architecture synth of tmds_cap_stream is

  constant PAUSE_COUNT : integer := 4; -- cycles to pause after reading FIFO when almost empty

  signal fifo_we       : std_logic;                        -- FIFO write enable
  signal fifo_wd       : std_logic_vector( 63 downto 0 );  -- FIFO write data
  signal fifo_wx       : std_logic_vector(  7 downto 0 );  -- FIFO write extras
  signal fifo_re       : std_logic;                        -- FIFO read enable
  signal fifo_rd       : std_logic_vector( 63 downto 0 );  -- FIFO read data
  signal fifo_rx       : std_logic_vector(  7 downto 0 );  -- FIFO read extras
  signal fifo_ef       : std_logic;                        -- FIFO empty flag
  signal fifo_aef      : std_logic;                        -- FIFO almost empty flag
  signal fifo_werr     : std_logic;                        -- FIFO write error
  signal fifo_rerr     : std_logic;                        -- FIFO read error

  signal cap_counter   : std_logic_vector( 31 downto 0 );  -- transfer count

  signal cap_go_s      : std_logic_vector( 0 to 1 );       -- capture go, synchronized
  signal fifo_werr_s   : std_logic_vector( 0 to 1 );       -- fifo write error, synchronized

  signal cap_run_i     : std_logic;                        -- capture running
  signal cap_done_i    : std_logic;                        -- capture done, internal
  signal fifo_wsel     : std_logic;                        -- fifo write select (lo/hi)

  signal pause_counter : integer range 0 to PAUSE_COUNT-1;

  type state_t is (IDLE, PREFETCH, VALID, PAUSE);
  signal state : state_t;

  alias fifo_wd_lo   : std_logic_vector( 31 downto 0 ) is fifo_wd( 31 downto  0 );
  alias fifo_wd_hi   : std_logic_vector( 31 downto 0 ) is fifo_wd( 63 downto 32 );
  alias fifo_wx_lo   : std_logic is fifo_wx(0);
  alias fifo_wx_hi   : std_logic is fifo_wx(1);
  alias fifo_wx_last : std_logic is fifo_wx(2);
  alias fifo_rx_lo   : std_logic is fifo_rx(0);
  alias fifo_rx_hi   : std_logic is fifo_rx(1);
  alias fifo_rx_last : std_logic is fifo_rx(2);

begin

  -- TODO handle loss of HDMI signal

  cap_done <= cap_done_i;
  cap_error <= fifo_werr_s(1) or fifo_rerr; -- TODO improve error handling

  -- TMDS stream ---> FIFO
  process(prst,pclk)
    variable d : std_logic_vector(31 downto 0);
  begin
    if prst = '1' then
      cap_go_s    <= (others => '0');
      cap_run_i   <= '0';
      cap_done_i  <= '0';
      fifo_we     <= '0';
      fifo_wd     <= (others => '0');
      cap_counter <= (others => '0');
    elsif rising_edge(pclk) then
      d := "00" & tmds(2) & tmds(1) & tmds(0);
      cap_go_s <= cap_go & cap_go_s(0 to cap_go_s'right-1);
      fifo_we  <= '0';
      fifo_wd  <= (others => '0');
      fifo_wx  <= (others => '0');
      if cap_run_i = '1' and cap_done_i = '0' then
        fifo_wx_last <= '0';
        if fifo_wsel = '0' then
          fifo_wd_lo <= d;
          fifo_wx_lo <= '1';
          fifo_wx_hi <= '0';
          fifo_wsel  <= '1';
        else
          fifo_wd_hi <= d;
          fifo_wx_hi <= '1';
          fifo_wsel  <= '0';
          fifo_we    <= '1';
        end if;
        if unsigned(cap_counter) = 1 or cap_go_s(1) = '0' then
          cap_run_i    <= '0';
          cap_done_i   <= '1';
          fifo_wx_last <= '1';
          fifo_we      <= '1'; -- in case of odd number of pixels
        end if;
        cap_counter <= std_logic_vector(unsigned(cap_counter)-1);
      elsif cap_run_i = '0' and cap_done_i = '1' and cap_go_s(1) = '0' then
        cap_done_i <= '0';
      elsif cap_run_i = '0' and cap_done_i = '0' and cap_go_s(1) = '1' then
        cap_counter <= cap_size;
        cap_run_i <= '1';
        fifo_wsel   <= '0';
      end if;
    end if;
  end process;

  -- FIFO
  FIFO : fifo36e1
    generic map (
      almost_empty_offset     => to_bitvector(std_logic_vector(to_unsigned(PAUSE_COUNT,16))),
      almost_full_offset      => x"01FC",
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
      almostempty   => fifo_aef,
      almostfull    => open,
      empty         => fifo_ef,
      full          => open,
      rdcount       => open,
      rderr         => fifo_rerr,
      wrcount       => open,
      wrerr         => fifo_werr,
      injectdbiterr => '0',
      injectsbiterr => '0',
      dbiterr       => open,
      eccparity     => open,
      sbiterr       => open
    );

  -- FIFO ---> AXI stream
  process(axi_rst_n,axi_clk)
  begin
    if axi_rst_n = '0' then
      fifo_werr_s <= (others => '0');
    elsif rising_edge(axi_clk) then
      fifo_werr_s <= fifo_werr & fifo_werr_s(0 to fifo_werr_s'right-1);
      pause_counter <= 0;
      case state is
        when IDLE =>
          if fifo_ef = '0' then
            state <= PREFETCH;
          end if;
        when PREFETCH =>
          state <= VALID;
        when VALID =>
          if fifo_aef = '1' and maxis_miso.tready = '1' then
            state <= PAUSE;
          end if;
        when PAUSE => -- pause to allow empty flag to update
          pause_counter <= pause_counter + 1;
          if pause_counter = PAUSE_COUNT-1 then
            state <= IDLE;
          end if;
        when others => -- should never happen
          state <= IDLE;
      end case;

    end if;
  end process;

  fifo_re <= '1' when (state = PREFETCH) or (state = VALID and maxis_miso.tready = '1') else '0';

  maxis_mosi.tdata             <= fifo_rd;
  maxis_mosi.tkeep(3 downto 0) <= (others => fifo_rx_lo);
  maxis_mosi.tkeep(7 downto 4) <= (others => fifo_rx_hi);
  maxis_mosi.tvalid            <= '1' when state = VALID else '0';
  maxis_mosi.tlast             <= fifo_rx_last;

end architecture synth;
