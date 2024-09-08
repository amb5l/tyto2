 --------------------------------------------------------------------------------
-- hram_ctrl.vhd                                                              --
-- HyperRAM controller for Xilinx 7 Series FPGAs.                             --
--------------------------------------------------------------------------------
-- (C) Copyright 2024 Adam Barnes <ambarnes@gmail.com>                        --
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
-- TODO
--  allow variable tLAT and tRWR
--  support single write bug workaround

library ieee;
  use ieee.std_logic_1164.all;

package hram_ctrl_pkg is

  -- controller parameter bundle type
  -- integers correspond to clock cycles
  type hram_ctrl_params_t is record
    tRP  : positive;  -- reset pulse width
    tRPH : positive;  -- reset assertion to chip select assertion
    tRWR : positive;  -- read-write recovery
    tLAT : positive;  -- latency
  end record hram_ctrl_params_t;

  -- parameters for: 100MHz HyperRAM, 100MHz clock
  constant HRAM_CTRL_PARAMS_100_100 : hram_ctrl_params_t := (
    tRP      => 20, -- 200 ns
    tRPH     => 40, -- 400 ns
    tRWR     => 4,  -- 40 ns (marginal)
    tLAT     => 4   -- 40 ns (marginal)
  );

  component hram_ctrl is
    generic (
      PARAMS   : hram_ctrl_params_t
    );
    port (
      s_rst     : in    std_ulogic;
      s_clk     : in    std_ulogic;
      s_clk_dly : in    std_ulogic;
      s_a_ready : out   std_ulogic;
      s_a_valid : in    std_ulogic;
      s_a_r_w   : in    std_ulogic;
      s_a_reg   : in    std_ulogic;
      s_a_wrap  : in    std_ulogic;
      s_a_len   : in    std_ulogic_vector;
      s_a_addr  : in    std_ulogic_vector;
      s_w_ready : out   std_ulogic;
      s_w_valid : in    std_ulogic;
      s_w_last  : out   std_ulogic;
      s_w_be    : in    std_ulogic_vector(1 downto 0);
      s_w_data  : in    std_ulogic_vector(15 downto 0);
      s_r_ready : in    std_ulogic;
      s_r_valid : out   std_ulogic;
      s_r_ref   : out   std_ulogic;
      s_r_last  : out   std_ulogic;
      s_r_data  : out   std_ulogic_vector(15 downto 0);
      h_rst_n   : out   std_logic;
      h_cs_n    : out   std_logic;
      h_clk     : out   std_logic;
      h_rwds    : inout std_logic;
      h_dq      : inout std_logic_vector(7 downto 0)
    );
  end component hram_ctrl;

end package hram_ctrl_pkg;

--------------------------------------------------------------------------------

use work.tyto_utils_pkg.all;
use work.hram_ctrl_pkg.all;
use work.ram_sdp_32x6_pkg.all;
use work.mux2_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity hram_ctrl is
  generic (
    PARAMS   : hram_ctrl_params_t
  );
  port (

    --------------------------------------------------------------------------------
    -- system interface

    -- reset and clock
    s_rst     : in    std_ulogic;                     -- reset (asynchronous)
    s_clk     : in    std_ulogic;                     -- clock
    s_clk_dly : in    std_ulogic;                     -- delayed clock (=> h_clk) (nominally 270 degrees)

    -- A (address) channel
    s_a_ready : out   std_ulogic;
    s_a_valid : in    std_ulogic;                     -- strobe
    s_a_r_w   : in    std_ulogic;                     -- 1 = read, 0 = write
    s_a_reg   : in    std_ulogic;                     -- space: 0 = memory, 1 = register
    s_a_wrap  : in    std_ulogic;                     -- burst: 0 = linear, 1 = wrapped/hybrid
    s_a_len   : in    std_ulogic_vector;              -- burst length in 16 bit words (MSB downto 0)
    s_a_addr  : in    std_ulogic_vector;              -- address (MSB downto 1)

    -- W (write data) channel
    s_w_ready : out   std_ulogic;                     -- ready
    s_w_valid : in    std_ulogic;                     -- valid
    s_w_last  : out   std_ulogic;                     -- last word of burst
    s_w_be    : in    std_ulogic_vector(1 downto 0);  -- byte enable
    s_w_data  : in    std_ulogic_vector(15 downto 0); -- data

    -- R (read data) channel
    s_r_ready : in    std_ulogic;                     -- ready
    s_r_valid : out   std_ulogic;                     -- valid
    s_r_ref   : out   std_ulogic;                     -- refresh collision occurred on this cycle (additional latency)
    s_r_last  : out   std_ulogic;                     -- last word of burst
    s_r_data  : out   std_ulogic_vector(15 downto 0); -- data

    --------------------------------------------------------------------------------
    -- HyperRAM interface

    h_rst_n   : out   std_logic;                      -- reset
    h_cs_n    : out   std_logic;                      -- chip select
    h_clk     : out   std_logic;                      -- clock
    h_rwds    : inout std_logic;                      -- read/write data strobe
    h_dq      : inout std_logic_vector(7 downto 0)    -- command/address/data bus

    --------------------------------------------------------------------------------

  );
end entity hram_ctrl;

architecture rtl of hram_ctrl is

  --------------------------------------------------------------------------------
  -- constants and types

  -- break parameter bundle out to discrete signals (better for linting)
  constant tRP  : positive := PARAMS.tRP  ;
  constant tRPH : positive := PARAMS.tRPH ;
  constant tRWR : positive := PARAMS.tRWR ;
  constant tLAT : positive := PARAMS.tLAT ;

  type state_t is (
    RESET, -- reset
    IDLE,  -- idle/ready
    CA,    -- command/address
    ALAT,  -- additional latency
    LAT,   -- latency
    WR,    -- write
    RBSY1, -- (previous) read busy 1
    RBSY2, -- (previous) read busy 2
    RD,    -- read
    CSHR,  -- hold for final RWDS pulse
    CSH,   -- hold before negating chip select to meet tCSH
    RWR    -- read-write recovery
  );

  type burst_t is record
    r_w  : std_ulogic;
    reg  : std_ulogic;
    wrap : std_ulogic;
    len  : std_ulogic_vector(s_a_len'range);
    trk  : std_ulogic_vector(s_a_len'range);  -- tracking down-counter
    addr : std_ulogic_vector(s_a_addr'range);
    ref  : std_ulogic;                        -- refresh collision occurred
  end record;

  -- read data fifo, data type, matches 3x ram_sdp_32x6
  type r_dfifo_d_t is array(0 to 2) of std_ulogic_vector(5 downto 0);

  constant IDDR_RS : std_ulogic_vector(7 downto 0) := x"AA"; -- telltale pattern for read failure detection

  --------------------------------------------------------------------------------
  -- signals

  -- delayed system interface signals
  signal s_w_be_1      : std_ulogic_vector(1 downto 0);   -- write byte enable delayed by 1 clock
  signal s_w_data_1    : std_ulogic_vector(15 downto 0);  -- write data  delayed by 1 clock
  signal s_w_ready_1   : std_ulogic;                      -- write ready delayed by 1 clock

  -- main control
  signal burst         : burst_t;                         -- details of current burst
  signal state         : state_t;                         -- state machine state
  signal phase         : std_ulogic;                      -- access phase: 0 = CA and latency, 1 = data
  signal count_rst     : integer range 0 to tRP+tRPH;     -- reset counter
  signal count         : integer range 0 to 7;            -- general purpose counter
  signal en_clk        : std_ulogic;                      -- enable h_clk pulse
  signal en_cs         : std_ulogic;                      -- enable h_cs_n assertion
  signal en_cs_next    : std_ulogic;                      -- enable h_cs_n assertion for next cycle

  -- read data path
  signal r_rst         : std_ulogic;                       -- reset FIFO pointers, reset/set IDDRs
  signal r_bsy         : std_ulogic;                       -- read data path busy (to hold off next cycle)
  signal r_cfifo_we    : std_ulogic;                       -- read control FIFO, write enable
  signal r_cfifo_wa    : std_ulogic_vector(2 downto 0);    -- read control FIFO, write address
  signal r_cfifo_wd    : std_ulogic;                       -- read control FIFO, write data (0 = not last, 1 = last)
  signal r_cfifo_ra    : std_ulogic_vector(2 downto 0);    -- read control FIFO, read address
  signal r_cfifo_rd    : std_ulogic;                       -- read control FIFO, read data (0 = not last, 1 = last)
  signal r_dfifo_we    : std_ulogic;                       -- read data FIFO, write enable
  signal r_dfifo_wa    : std_ulogic_vector(2 downto 0);    -- read data FIFO, write address
  signal r_dfifo_wd    : r_dfifo_d_t;                      -- read data FIFO, write data
  signal r_dfifo_ra    : std_ulogic_vector(2 downto 0);    -- read data FIFO, read address
  signal r_dfifo_rd    : r_dfifo_d_t;                      -- read data FIFO, read data
  signal r_mux_i0      : std_ulogic_vector(15 downto 0);   -- read mux input 0
  signal r_mux_i1      : std_ulogic_vector(15 downto 0);   -- read mux input 1

  -- HyperRAM I/O related
  signal h_rst_n_o     : std_logic;
  signal h_cs_n_o      : std_logic;
  signal h_clk_o       : std_logic;                        -- clock ODDR Q output to OBUF
  signal h_rwds_i      : std_ulogic;                       -- RWDS input from IOBUF to IDELAY
  signal h_rwds_i_d    : std_ulogic;                       -- RWDS IDELAY output
  signal h_rwds_i_b    : std_ulogic;                       -- RWDS BUFR output
  signal h_rwds_i_c    : std_ulogic;                       -- RWDS BUFR output with delay for functional simulation
  signal h_rwds_o_d1_f : std_ulogic;                       -- RWDS ODDR D1 for sampling on falling clock edge (half clock early)
  signal h_rwds_o_d1_r : std_ulogic;                       -- RWDS ODDR D1 for sampling on rising clock edge
  signal h_rwds_o_d2_f : std_ulogic;                       -- RWDS ODDR D2 for sampling on falling clock edge
  signal h_rwds_o      : std_ulogic;                       -- RWDS ODDR Q output to IOBUF
  signal h_rwds_t      : std_ulogic;                       -- RWDS IOBUF tristate control
  signal h_dq_i        : std_ulogic_vector(7 downto 0);    -- DQ input from IOBUF to IDDR
  signal h_dq_i_ce     : std_ulogic;                       -- DQ IDDR clock enable
  signal h_dq_i_r      : std_ulogic_vector(15 downto 0);   -- DQ IDDR Q
  signal h_dq_o_d1_f   : std_ulogic_vector(7 downto 0);    -- DQ ODDR D1 for sampling on falling clock edge (half clock early)
  signal h_dq_o_d1_r   : std_ulogic_vector(7 downto 0);    -- DQ ODDR D1 for sampling on rising clock edge
  signal h_dq_o_d2_f   : std_ulogic_vector(7 downto 0);    -- DQ ODDR D2 for sampling on falling clock edge
  signal h_dq_o        : std_ulogic_vector(7 downto 0);    -- DQ ODDR Q output to IOBUF
  signal h_dq_o_ce     : std_ulogic;                       -- DQ ODDR clock enable
  signal h_dq_t        : std_ulogic;                       -- DQ IOBUF tristate control

  --------------------------------------------------------------------------------

  attribute dont_touch : string;
  attribute dont_touch of U_MUX2 : label is "TRUE";

  --------------------------------------------------------------------------------

begin

  P_COMB: process(all)
    type ca_t is array(5 downto 0) of std_ulogic_vector(7 downto 0);
    variable a32 : std_ulogic_vector(31 downto 0);
    variable ca  : ca_t;
  begin

    en_cs <= (bool2sl(state = IDLE) and s_a_valid and s_a_ready) or en_cs_next;

    a32 := (others => '0');
    a32(s_a_addr'length downto 1) := burst.addr;
    ca(0) := s_a_r_w & s_a_reg & not s_a_wrap & "00000";
    ca(1) := a32(27 downto 20);
    ca(2) := a32(19 downto 12);
    ca(3) := a32(11 downto 4);
    ca(4) := x"00";
    ca(5) := "00000" & a32(3 downto 1);

    h_rwds_o_d1_f <= not s_w_be_1(0);

    h_rwds_o_d2_f <= not s_w_be_1(1);

    h_dq_o_d1_r <=
      ca(1) when phase = '0' and (count mod 4) = 1 else
      ca(3) when phase = '0' and (count mod 4) = 2 else
      ca(5) when phase = '0' and (count mod 4) = 3 else
      s_w_data_1(7 downto 0) when ((burst.reg = '1' and burst.r_w = '0') or (s_w_ready_1 = '1')) else
      (others => 'X');

    h_dq_o_d2_f <=
      burst.r_w & burst.reg & not burst.wrap & "00000"
            when phase = '0' and (count mod 4) = 1 else
      ca(2) when phase = '0' and (count mod 4) = 2 else
      ca(4) when phase = '0' and (count mod 4) = 3 else
      s_w_data_1(15 downto 8) when ((burst.reg = '1' and burst.r_w = '0') or (s_w_ready_1 = '1')) else
      (others => 'X');

  end process;

  P_MAIN: process(s_rst,s_clk)
  begin

    if s_rst = '1' then
      h_rwds_o_d1_r <= '0';
      h_dq_o_d1_f   <= (others => 'X');
    elsif falling_edge(s_clk) then
      h_rwds_o_d1_r <= h_rwds_o_d1_f;
      h_dq_o_d1_f   <= h_dq_o_d1_r;
    end if;

    if s_rst = '1' then

      s_a_ready   <= '0';
      s_w_ready   <= '0';
      s_w_last    <= '0';
      s_w_be_1    <= (others => '0');
      s_r_valid   <= '0';
      s_r_ref     <= '0';
      s_r_last    <= '0';
      h_rst_n_o   <= '0';
      h_rwds_t    <= '1';
      h_dq_o_ce   <= '0';
      h_dq_i_ce   <= '0';
      h_dq_t      <= '1';
      s_w_data_1  <= (others => '0');
      s_w_ready_1 <= '0';
      burst.r_w   <= 'X';
      burst.reg   <= 'X';
      burst.wrap  <= 'X';
      burst.len   <= (others => 'X');
      burst.trk   <= (others => 'X');
      burst.addr  <= (others => 'X');
      burst.ref   <= '0';
      state       <= RESET;
      phase       <= '0';
      count_rst   <= 0;
      count       <= 0;
      en_clk      <= '0';
      en_cs_next  <= '0';
      r_rst       <= '0';
      r_bsy       <= '0';
      r_cfifo_we  <= '0';
      r_cfifo_wd  <= '0';
      r_cfifo_wa  <= (others => '0');
      r_cfifo_wd  <= '0';
      r_cfifo_ra  <= (others => '0');
      r_dfifo_ra  <= (others => '0');

    elsif rising_edge(s_clk) then

      s_w_ready_1 <= s_w_ready;
      s_w_be_1    <= s_w_be;
      s_w_data_1  <= s_w_data;
      r_rst       <= '0';
      r_cfifo_we  <= '0';
      r_cfifo_wd  <= '0';

      case state is

        when RESET =>
          if count_rst = tRP-1 then
            h_rst_n_o <= '1';
          elsif count_rst = tRP+tRPH-1 then
            s_a_ready <= '1';
            state     <= IDLE;
          end if;
          count_rst <= count_rst + 1;

        when IDLE =>
          h_dq_t <= '0';
          if s_a_valid and s_a_ready then
            burst.r_w  <= s_a_r_w;
            burst.reg  <= s_a_reg;
            burst.wrap <= s_a_wrap;
            burst.len  <= s_a_len;
            burst.trk  <= s_a_len;
            burst.addr <= s_a_addr;
            burst.ref  <= '0';
            s_a_ready  <= '0';
            en_cs_next <= '1';
            en_clk     <= '1';
            h_dq_o_ce  <= '1';
            count      <= 1;
            state      <= CA;
          end if;

        when CA =>
          count <= count + 1;
          if count = 2 then
            s_w_ready <= burst.reg and not burst.r_w;
            s_w_last  <= not burst.r_w when unsigned(burst.trk) = 1 else '0';
          elsif count = 3 then
            phase <= '1';
            if burst.reg and not burst.r_w then -- register write
              if s_w_valid then
                if s_w_last then
                  s_w_ready <= '0';
                  s_w_last  <= '0';
                else
                  s_w_last <= '1' when unsigned(burst.trk) = 2 else '0';
                end if;
                burst.trk <= decr(burst.trk);
                en_clk    <= '1';
              end if;
              state <= WR;
            else
              h_dq_o_ce <= '0';
              count     <= 1;
              state     <= ALAT when h_rwds_i_d = '1' else LAT;
            end if;
          end if;

        when ALAT =>
          burst.ref <= '1';
          count <= count + 1;
          if count = tLAT-1 then
            count <= 0;
            state <= LAT;
          end if;

        when LAT =>
          count <= count + 1;
          if count = 1 then -- tristate DQ for read
            h_dq_t <= burst.r_w;
          elsif count = 2 then -- drive RWDS for write
            h_rwds_t <= burst.r_w;
          end if;
          if count = tLAT-2 then -- ready for write data / read reset
            s_w_ready <= not burst.r_w;
            s_w_last  <= not burst.r_w when unsigned(burst.trk) = 1 else '0';
            r_rst     <= burst.r_w and not r_bsy;
          elsif count = tLAT-1 then -- data transfer (or stall)
            count <= 0;
            if burst.r_w then
              if r_bsy then
                state <= RBSY1;
              elsif not r_rst then
                r_rst <= '1';
                state <= RBSY2;
              else
                en_clk    <= s_r_ready;
                h_dq_i_ce <= '1';
                r_bsy     <= '1';
                state     <= RD;
              end if;
            else
              if s_w_valid then
                if s_w_last then
                  s_w_ready <= '0';
                  s_w_last  <= '0';
                else
                  s_w_last <= '1' when unsigned(burst.trk) = 2 else '0';
                end if;
                burst.trk <= decr(burst.trk);
                en_clk <= '1';
              end if;
              h_dq_o_ce <= '1';
              state  <= WR;
            end if;
          end if;

        when WR =>
          en_clk <= s_w_valid and s_w_ready;
          if s_w_valid then
            if s_w_last then
              s_w_ready <= '0';
              s_w_last  <= '0';
            else
              s_w_last <= '1' when unsigned(burst.trk) = 2 else '0';
            end if;
            burst.trk <= decr(burst.trk);
            en_clk <= '1';
          end if;
          if en_clk = '1' then
            if unsigned(burst.trk) = 0 then -- end of burst
              en_clk     <= '0';
              en_cs_next <= '0';
              h_dq_o_ce  <= '0';
              state      <= CSH;
            end if;
          end if;

        when RBSY1 =>
          if not r_bsy then
            r_rst <= '1';
            state <= RBSY2;
          end if;

        when RBSY2 =>
          en_clk    <= s_r_ready;
          h_dq_i_ce <= '1';
          r_bsy     <= '1';
          state     <= RD;

        when RD =>
          r_cfifo_we <= '1';
          r_cfifo_wd <= '0';
          en_clk <= s_r_ready;
          if unsigned(burst.trk) = 1 then -- end of burst
            r_cfifo_wd <= '1';
            en_clk     <= '0';
            state      <= CSHR;
          end if;
          if en_clk = '1' then
            burst.trk <= decr(burst.trk);
          end if;

        when CSHR =>
          en_cs_next <= '0';
          state   <= CSH;

        when CSH =>
          h_rwds_t   <= '1';
          h_dq_i_ce  <= '0';
          en_cs_next <= '0';
          count      <= 0;
          if tRWR >= 4 then
            state <= RWR;
          else
            s_a_ready <= '1';
            phase     <= '0';
            state     <= IDLE;
          end if;

        when RWR =>
          h_dq_t <= '0';
          count  <= count + 1;
          if count = tRWR-4 then
            s_a_ready <= '1';
            phase     <= '0';
            count     <= 0;
            state     <= IDLE;
          end if;

      end case;

      -- read data path
      if r_cfifo_we then
        r_cfifo_wa <= incr(r_cfifo_wa);
      end if;
      if s_r_valid and s_r_ready then
        r_dfifo_ra <= incr(r_dfifo_ra) when s_r_last = '0' else r_dfifo_ra;
        if s_r_last then
          r_bsy   <= '0';
          s_r_ref <= '0';
        end if;
        s_r_valid <= '0';
        s_r_last  <= '0';
      end if;
      if r_cfifo_wa /= r_cfifo_ra then
        s_r_valid  <= '1';
        s_r_ref    <= burst.ref;
        s_r_last   <= r_cfifo_rd;
        r_cfifo_ra <= incr(r_cfifo_ra);
      end if;
      if r_rst then
        r_cfifo_wa <= (others => '0');
        r_cfifo_ra <= (others => '0');
        r_dfifo_ra <= (others => '0');
      end if;

    end if;
  end process P_MAIN;

  --------------------------------------------------------------------------------
  -- I/O primitives

  U_OBUF_RST: component obuf
    port map (
      i => h_rst_n_o,
      o => h_rst_n
    );

  U_ODDR_CLK: component oddr
    generic map(
      DDR_CLK_EDGE => "SAME_EDGE",
      SRTYPE       => "ASYNC"
    )
    port map (
      r  => s_rst,
      s  => '0',
      c  => s_clk_dly,
      ce => '1',
      d1 => en_clk,
      d2 => '0',
      q  => h_clk_o
    );

  U_OBUF_CLK: component obuf
    port map (
      i => h_clk_o,
      o => h_clk
    );

  U_ODDR_CS: component oddr
    generic map(
      DDR_CLK_EDGE => "SAME_EDGE",
      INIT         => '1',
      SRTYPE       => "ASYNC"
    )
    port map (
      r  => '0',
      s  => s_rst,
      c  => s_clk,
      ce => '1',
      d1 => not en_cs,
      d2 => not en_cs,
      q  => h_cs_n_o
    );

  U_OBUF_CS: component obuf
    port map (
      i => h_cs_n_o,
      o => h_cs_n
    );

  U_ODDR_RWDS: component oddr
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        SRTYPE       => "ASYNC"
      )
      port map (
        r  => s_rst,
        s  => '0',
        c  => s_clk,
        ce => h_dq_o_ce,
        d1 => h_rwds_o_d1_r,
        d2 => h_rwds_o_d2_f,
        q  => h_rwds_o
      );

  U_IDELAY_RWDS: component idelaye2
    generic map (
      DELAY_SRC             => "IDATAIN",
      IDELAY_TYPE           => "FIXED",
      PIPE_SEL              => "FALSE",
      IDELAY_VALUE          => 6,
      SIGNAL_PATTERN        => "DATA",
      REFCLK_FREQUENCY      => 200.0,
      HIGH_PERFORMANCE_MODE => "TRUE",
      CINVCTRL_SEL          => "FALSE"
    )
    port map (
      regrst      => '0',
      cinvctrl    => '0',
      c           => '0',
      ce          => '0',
      inc         => '0',
      ld          => '0',
      ldpipeen    => '0',
      cntvaluein  => (others => '0'),
      cntvalueout => open,
      idatain     => h_rwds_i,
      datain      => '0',
      dataout     => h_rwds_i_d
    );

  U_BUFR_RWDS: component bufr
    port map (
      clr => '0',
      ce  => '1',
      i => h_rwds_i_d,
      o => h_rwds_i_b
    );
  h_rwds_i_c <= h_rwds_i_b after 2 ns;

  U_IOBUF_RWDS: component iobuf
    port map (
      O  => h_rwds_i,
      I  => h_rwds_o,
      T  => h_rwds_t,
      IO => h_rwds
    );

  GEN_DQ: for i in 0 to 7 generate

    U_ODDR: component oddr
      generic map(
        DDR_CLK_EDGE => "OPPOSITE_EDGE",
        SRTYPE       => "ASYNC"
      )
      port map (
        r  => s_rst,
        s  => '0',
        c  => s_clk,
        ce => h_dq_o_ce,
        d1 => h_dq_o_d1_f(i),
        d2 => h_dq_o_d2_f(i),
        q  => h_dq_o(i)
      );

    U_IOBUF: component iobuf
      port map (
        O  => h_dq_i(i),
        I  => h_dq_o(i),
        T  => h_dq_t,
        IO => h_dq(i)
      );

    U_IDDR: component iddr
      generic map (
        IS_C_INVERTED => '1',
        DDR_CLK_EDGE  => "SAME_EDGE",
        SRTYPE        => "ASYNC"
      )
      port map (
        r  => (s_rst or r_rst) and not IDDR_RS(i),
        s  => (s_rst or r_rst) and     IDDR_RS(i),
        c  => h_rwds_i_c,
        ce => h_dq_i_ce,
        d  => h_dq_i(i),
        q1 => h_dq_i_r(0+i),
        q2 => h_dq_i_r(8+i)
      );

  end generate GEN_DQ;

  --------------------------------------------------------------------------------
  -- read data path

  -- start writing to FIFO on 2nd RWDS pulse to allow for IDDR latency
  P_R_FIFO_WE: process(h_dq_i_ce,h_rwds_i_c)
  begin
    if h_dq_i_ce = '0' then
      r_dfifo_we <= '0';
    elsif rising_edge(h_rwds_i_c) then
      r_dfifo_we <= '1';
    end if;
  end process P_R_FIFO_WE;

  P_R_FIFO_WA: process(h_dq_i_ce,h_rwds_i_c)
  begin
    if h_dq_i_ce = '0' then
      r_dfifo_wa <= (others => '0');
    elsif rising_edge(h_rwds_i_c) and r_dfifo_we = '1' then
      r_dfifo_wa <= incr(r_dfifo_wa);
    end if;
  end process P_R_FIFO_WA;

  r_dfifo_wd(0) <=        h_dq_i_r( 5 downto  0);
  r_dfifo_wd(1) <=        h_dq_i_r(11 downto  6);
  r_dfifo_wd(2) <= "00" & h_dq_i_r(15 downto 12);

  -- read control FIFO (8 deep x 1 bit)
  CFIFO_RAM: ram32x1d
    port map (
      wclk  => s_clk,
      we    => r_cfifo_we,
      a0    => r_cfifo_wa(0),
      a1    => r_cfifo_wa(1),
      a2    => r_cfifo_wa(2),
      a3    => '0',
      a4    => '0',
      d     => r_cfifo_wd,
      spo   => open,
      dpra0 => r_cfifo_ra(0),
      dpra1 => r_cfifo_ra(1),
      dpra2 => r_cfifo_ra(2),
      dpra3 => '0',
      dpra4 => '0',
      dpo  => r_cfifo_rd
    );

  -- read data fifo (8 deep x 18 bits)
  GEN_DFIFO: for i in 0 to 2 generate
    RAM: component ram_sdp_32x6
      port map (
        clk => h_rwds_i_c,
        we  => r_dfifo_we,
        wa  => "00" & r_dfifo_wa,
        wd  => r_dfifo_wd(i),
        ra  => "00" & r_dfifo_ra,
        rd  => r_dfifo_rd(i)
      );
  end generate GEN_DFIFO;

  -- read mux (to bypass data FIFO for last word)
  r_mux_i0 <= r_dfifo_rd(2)(3 downto 0) & r_dfifo_rd(1)(5 downto 0) & r_dfifo_rd(0)(5 downto 0);
  r_mux_i1 <= r_dfifo_wd(2)(3 downto 0) & r_dfifo_wd(1)(5 downto 0) & r_dfifo_wd(0)(5 downto 0);
  U_MUX2: component mux2
    port map (
      s  => s_r_last,
      i0 => r_mux_i0,
      i1 => r_mux_i1,
      o  => s_r_data
    );

  --------------------------------------------------------------------------------

end architecture rtl;
