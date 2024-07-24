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

library ieee;
  use ieee.std_logic_1164.all;

package hram_ctrl_pkg is

  -- controller parameter bundle type
  -- integers correspond to clock cycles
  type hram_ctrl_params_t is record
    tRP      : positive;  -- reset pulse width
    tRPH     : positive;  -- reset assertion to chip select assertion
    tRWR     : positive;  -- read-write recovery
    tLAT     : positive;  -- latency
    tCSM     : positive;  -- chip select, max
  end record hram_ctrl_params_t;

  -- parameters for: 133MHz HyperRAM, 100MHz clock
  constant HRAM_CTRL_PARAMS_133_100 : hram_ctrl_params_t := (
    tRP      => 20,    -- 200 ns
    tRPH     => 40,    -- 400 ns
    tRWR     => 4,     -- 40 ns
    tLAT     => 4,     -- 40 ns
    tCSM     => 400    -- 4 us
  );

  component hram_ctrl is
    generic (
      A_MSB    : integer range 19 to 29;
      B_MSB    : integer range 0 to 19;
      CLK_FREE : boolean;
      W_DEPTH  : positive;
      R_DEPTH  : positive;
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
      s_a_size  : in    std_ulogic_vector(B_MSB downto 0);
      s_a_addr  : in    std_ulogic_vector(A_MSB downto 1);
      s_w_ready : out   std_ulogic;
      s_w_valid : in    std_ulogic;
      s_w_be    : in    std_ulogic_vector(1 downto 0);
      s_w_data  : in    std_ulogic_vector(15 downto 0);
      s_r_ready : in    std_ulogic;
      s_r_valid : out   std_ulogic;
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

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library unisim;
  use unisim.vcomponents.all;

entity hram_ctrl is
  generic (
    A_MSB    : integer range 19 to 27; -- 8..2048Mbits (1..256MBytes)
    B_MSB    : integer range 0 to 19;  -- 1..1024 words
    CLK_FREE : boolean;
    W_DEPTH  : positive;
    R_DEPTH  : positive;
    PARAMS   : hram_ctrl_params_t
  );
  port (

    --------------------------------------------------------------------------------
    -- system interface

    -- reset and clock
    s_rst     : in    std_ulogic;                        -- reset (asynchronous)
    s_clk     : in    std_ulogic;                        -- clock
    s_clk_dly : in    std_ulogic;                        -- delayed clock (=> h_clk) (nominally 270 degrees)

    -- A (address) channel
    s_a_ready : out   std_ulogic;
    s_a_valid : in    std_ulogic;                        -- strobe
    s_a_r_w   : in    std_ulogic;                        -- 1 = read, 0 = write
    s_a_reg   : in    std_ulogic;                        -- space: 0 = memory, 1 = register
    s_a_wrap  : in    std_ulogic;                        -- burst: 0 = linear, 1 = wrapped/hybrid
    s_a_size  : in    std_ulogic_vector(B_MSB downto 0); -- burst size
    s_a_addr  : in    std_ulogic_vector(A_MSB downto 1); -- address

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

    --------------------------------------------------------------------------------

  );
end entity hram_ctrl;

architecture rtl of hram_ctrl is

  --------------------------------------------------------------------------------
  -- break parameter bundle out to discrete signals (better for linting)

  constant tRP      : positive := PARAMS.tRP      ;
  constant tRPH     : positive := PARAMS.tRPH     ;
  constant tRWR     : positive := PARAMS.tRWR     ;
  constant tLAT     : positive := PARAMS.tLAT     ;
  constant tCSM     : positive := PARAMS.tCSM     ;

  --------------------------------------------------------------------------------

  type state_t is (
    RESET,  -- reset
    IDLE,   -- idle/ready
    CA,     -- command/address
    ALAT,   -- additional latency
    LAT,    -- latency
    STALL,  -- stall for data
    WR,     -- write
    RD,     -- read
    RDX,    -- extra read (to clock final read data)
    CSHR,   -- hold for final RWDS pulse
    CSH,    -- hold before negating chip select to meet tCSH
    RWR     -- read-write recovery
  );

  type burst_t is record
    r_w  : std_ulogic;
    reg  : std_ulogic;
    wrap : std_ulogic;
    size : std_ulogic_vector(s_a_size'range);
    addr : std_ulogic_vector(s_a_addr'range);
  end record;

  signal a32        : std_ulogic_vector(31 downto 0);

  signal burst      : burst_t;                           -- details of current burst
  signal state      : state_t;                           -- state machine state
  signal phase      : std_ulogic;                        -- 0 = CA and latency, 1 = data

  signal count_rst  : integer range 0 to tRP+tRPH;
  signal count      : integer range 0 to 7;
  signal count_rd   : integer range 0 to (2**s_a_size'length)-1; -- read data tracking

  signal pause      : std_ulogic;
  signal s_w_data_1 : std_ulogic_vector(7 downto 0);

  signal busy_cs    : std_ulogic;
  signal busy_clk   : std_ulogic;
  signal busy_wr    : std_ulogic;
  signal busy_rd    : std_ulogic;
  signal strobe_wr  : std_ulogic_vector(1 to 2);
  signal strobe_rd  : std_ulogic_vector(1 to 2);

  signal h_clk_u    : std_ulogic;
  signal h_cs_n_u   : std_ulogic;
  signal h_rwds_i_u : std_logic;                        -- RWDS IBUF output
  signal h_rwds_i_d : std_logic;                        -- RWDS IDELAY output
  signal h_rwds_i_c : std_logic;                        -- RWDS BUFR output
  signal h_rwds_o_1 : std_logic;
  signal h_rwds_o_2 : std_logic;
  signal h_rwds_o   : std_logic;
  signal h_rwds_t   : std_logic;
  signal h_dq_i_u   : std_ulogic_vector(7 downto 0);  -- DQ IBUF output
  signal h_dq_i_d   : std_ulogic_vector(7 downto 0);  -- DQ IDELAY output
  signal h_dq_i_r   : std_ulogic_vector(15 downto 0); -- DQ IDDR output
  signal h_dq_o_1   : std_ulogic_vector(7 downto 0);
  signal h_dq_o_2   : std_ulogic_vector(7 downto 0);
  signal h_dq_o     : std_ulogic_vector(7 downto 0);
  signal h_dq_t     : std_ulogic;

  -- conditions used in state machine and elsewhere
  signal c_resume   : std_ulogic;
  signal c_start    : std_ulogic;
  signal c_cs       : std_ulogic;

  -- read FIFO
  type r_fifo_d_t is array(0 to 2) of std_ulogic_vector(5 downto 0);
  signal r_fifo_we  : std_ulogic;
  signal r_fifo_wa  : std_ulogic_vector(4 downto 0); -- write address
  signal r_fifo_wd  : r_fifo_d_t;
  signal r_fifo_ra  : std_ulogic_vector(4 downto 0); -- read address
  signal r_fifo_rd  : r_fifo_d_t;



  --------------------------------------------------------------------------------

begin

  P_COMB: process(all)
    type ca_t is array(5 downto 0) of std_ulogic_vector(7 downto 0);
    variable ca : ca_t;
  begin
    c_resume <= pause and ((s_w_valid and not burst.r_w) or (burst.r_w and s_r_ready));
    c_start  <= c_resume or (s_a_valid and s_a_ready);
    c_cs     <= (bool2sl(state = IDLE) and c_start) or busy_cs;

    a32 <= (A_MSB downto 1 => burst.addr, others =>'0');
    ca(0) :=
      s_a_r_w & s_a_reg & not s_a_wrap & "00000" when pause = '0' else
      burst.r_w & burst.reg & not burst.wrap & "00000";
    ca(1) := a32(27 downto 20);
    ca(2) := a32(19 downto 12);
    ca(3) := a32(11 downto 4);
    ca(4) := x"00";
    ca(5) := "00000" & a32(3 downto 1);

    h_dq_o_1 <=
      ca(0) when phase = '0' and (count mod 4) = 0 else
      ca(1) when phase = '0' and (count mod 4) = 1 else
      ca(3) when phase = '0' and (count mod 4) = 2 else
      ca(5) when phase = '0' and (count mod 4) = 3 else
      s_w_data_1(7 downto 0) when ((burst.reg = '1' and burst.r_w = '0') or (strobe_wr(2) = '1')) else
      (others => 'X');

    h_dq_o_2 <=
      ca(0) when phase = '0' and (count mod 4) = 0 else
      ca(2) when phase = '0' and (count mod 4) = 1 else
      ca(4) when phase = '0' and (count mod 4) = 2 else
      s_w_data(15 downto 8) when ((burst.reg = '1' and burst.r_w = '0') or (strobe_wr(1) = '1')) else
      (others => 'X');

  end process;

  P_MAIN: process(s_rst,s_clk)
  begin
    if s_rst = '1' then

      s_a_ready <= '0';
      s_w_ready <= '0';
      s_r_valid <= '0';
      h_rst_n   <= '0';
      h_rwds_t  <= '1';
      h_dq_t    <= '1';

      phase      <= '0';
      pause      <= '0';
      burst.r_w  <= 'X';
      burst.reg  <= 'X';
      burst.wrap <= 'X';
      burst.size <= (others => 'X');
      burst.addr <= (others => 'X');
      count_rst <= 0;
      count     <= 0;
      count_rd   <= 0;
      busy_cs   <= '0';
      busy_clk  <= '0';
      busy_wr   <= '0';
      busy_rd   <= '0';
      r_fifo_ra <= (others => '0');
      strobe_rd <= (others => '0');
      strobe_wr <= (others => '0');
      state     <= RESET;

    elsif rising_edge(s_clk) then

      s_w_ready <= '0';
      s_w_data_1(7 downto 0) <= s_w_data(7 downto 0);

      case state is

        when RESET =>
          if count_rst = tRP-1 then
            h_rst_n <= '1';
          elsif count_rst = tRP+tRPH-1 then
            s_a_ready <= '1';
            state     <= IDLE;
          end if;
          count_rst <= count_rst + 1;

        when IDLE =>
          if c_start then
            if not pause then -- new burst
              burst.r_w  <= s_a_r_w;
              burst.reg  <= s_a_reg;
              burst.wrap <= s_a_wrap;
              burst.size <= s_a_size;
              burst.addr <= s_a_addr;
            end if;
            s_a_ready <= '0';
            h_dq_t    <= '0';
            busy_cs  <= '1';
            busy_clk <= '1';
            count    <= 1;
            state    <= CA;
          end if;

        when CA =>
          count <= count + 1;
          if count = 2 then
            s_w_ready    <= burst.reg and not burst.r_w;
            strobe_wr(1) <= burst.reg and not burst.r_w;
          elsif count = 3 then
            if burst.r_w = '0' and burst.reg = '1' then -- register write
              phase    <= '1';
              busy_clk <= '1';
              state    <= WR;
            else
              phase <= '1';
              count <= 1;
              state <= ALAT when h_rwds_i_d = '1' else LAT;
            end if;
          end if;

        when ALAT =>
          count <= count + 1;
          if count = tLAT-1 then
            count <= 0;
            state <= LAT;
          end if;

        -- TODO merge s_w_ready and strobe_wr(1)
        when LAT =>
          count <= count + 1;
          if count = 1 and burst.r_w = '1' then -- tristate DQ for read
            h_dq_t <= '1';
          elsif count = tLAT-2 then -- ready for write data
            s_w_ready    <= not burst.r_w;
            strobe_wr(1) <= not burst.r_w;
          elsif count = tLAT-1 then -- data transfer (or stall)
            count <= 0;
            if burst.r_w = '1' then
              if s_r_ready = '1' then
                busy_rd <= '1';
                state   <= RD;
              else
                busy_clk <= '0';
                state    <= STALL;
              end if;
            else
              if s_w_valid = '1'  then
                h_rwds_t  <= '0';
                s_w_ready <= '1';
                state     <= WR;
              else
                busy_clk <= '0';
                state    <= STALL;
              end if;
            end if;
          end if;

        when STALL =>
          if burst.r_w = '1' then
            if s_r_ready = '1' then
              busy_clk <= '1';
              busy_rd  <= '1';
              state    <= RD;
            end if;
          else
            if s_w_valid = '1' then
              h_rwds_t  <= '0';
              s_w_ready <= '1';
              busy_clk  <= '1';
              state     <= WR;
            end if;
          end if;

        when WR =>
          if unsigned(burst.size) = 1 then -- end of burst
            pause <= '0';
            busy_clk <= '0';
            busy_cs <= '0';
            state <= CSH;
          elsif not s_w_ready then
            pause <= '1';
            busy_clk <= '0';
            busy_cs <= '0';
            state <= CSH;
          else
            s_w_ready <= '1';
          end if;
          burst.addr(s_a_addr'range) <= incr(burst.addr(s_a_addr'range));
          burst.size <= decr(burst.size);

        when RD =>
          if unsigned(burst.size) = 1 then -- end of burst
            pause <= '0';
            state <= RDX;
          elsif not s_w_ready then
            pause <= '1';
            state <= RDX;
          end if;
          burst.addr(s_a_addr'range) <= incr(burst.addr(s_a_addr'range));
          burst.size <= decr(burst.size);

        when RDX =>
          busy_clk <= '0';
          state    <= CSHR;

        when CSHR =>
          busy_cs <= '0';
          state   <= CSH;

        when CSH =>
          count     <= 0;
          if tLAT >= 4 then
            h_rwds_t <= '1';
            h_dq_t   <= '1';
            busy_cs  <= '0';
            busy_rd  <= '0';
            state    <= RWR;
          else
            s_a_ready <= not pause;
            h_rwds_t  <= '1';
            h_dq_t    <= '1';
            phase     <= '0';
            busy_cs   <= '0';
            busy_rd   <= '0';
            state     <= IDLE;
          end if;

        when RWR =>
          count <= count + 1;
          if count = tLAT-4 then
            s_a_ready <= not pause;
            h_dq_t    <= '1';
            phase     <= '0';
            count     <= 0;
            state     <= IDLE;
          end if;

      end case;

      -- write tracking
      strobe_wr(2) <= strobe_wr(1);

      -- read tracking
      strobe_rd(1) <= '1' when state = RD else '0';
      strobe_rd(2 to strobe_rd'high) <= strobe_rd(1 to strobe_rd'high-1);
      if strobe_rd(strobe_rd'high) and not (s_r_valid and s_r_ready) then
        s_r_valid <= '1';
        count_rd  <= (count_rd + 1) mod (2**s_a_size'length);
      elsif (s_r_valid and s_r_ready) and not strobe_rd(strobe_rd'high) then
        if count_rd = 1 then
          s_r_valid <= '0';
        end if;
        count_rd <= count_rd - 1;
      end if;
      r_fifo_ra <= incr(r_fifo_ra) when s_r_valid and s_r_ready else r_fifo_ra;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- output registers and buffers

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
      d1 => busy_clk,
      d2 => '0',
      q  => h_clk_u
    );

  U_OBUF_CLK: component obuf
    port map (
      i => h_clk_u,
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
      d1 => not c_cs,
      d2 => not c_cs,
      q  => h_cs_n_u
    );

  U_OBUF_CS: component obuf
    port map (
      i => h_cs_n_u,
      o => h_cs_n
    );

  U_ODDR_RWDS: component oddr
      generic map(
        DDR_CLK_EDGE => "SAME_EDGE",
        SRTYPE       => "ASYNC"
      )
      port map (
        r  => s_rst,
        s  => '0',
        c  => s_clk,
        ce => '1',
        d1 => h_rwds_o_1,
        d2 => h_rwds_o_2,
        q  => h_rwds_o
      );

  U_OBUFT_RWDS: component obuft
    port map (
      i => h_rwds_o,
      o => h_rwds,
      t => h_rwds_t
    );

  GEN_DQ_O: for i in 0 to 7 generate

    U_ODDR: component oddr
      generic map(
        DDR_CLK_EDGE => "SAME_EDGE",
        SRTYPE       => "ASYNC"
      )
      port map (
        r  => s_rst,
        s  => '0',
        c  => s_clk,
        ce => '1',
        d1 => h_dq_o_1(i),
        d2 => h_dq_o_2(i),
        q  => h_dq_o(i)
      );

    U_OBUFT: component obuft
      port map (
        i => h_dq_o(i),
        o => h_dq(i),
        t => h_dq_t
      );

  end generate GEN_DQ_O;

  --------------------------------------------------------------------------------
  -- input buffers, delay elements and registers

  U_IBUF_RWDS: component ibuf
    port map (
      i => h_rwds,
      o => h_rwds_i_u
    );

  U_IDELAY_RWDS: component idelaye2
    generic map (
      DELAY_SRC             => "IDATAIN",
      IDELAY_TYPE           => "FIXED",
      PIPE_SEL              => "FALSE",
      IDELAY_VALUE          => 31,
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
      idatain     => h_rwds_i_u,
      datain      => '0',
      dataout     => h_rwds_i_d
    );

  U_BUFR_RWDS: component bufr
    port map (
      clr => '0',
      ce  => '1',
      i => h_rwds_i_d,
      o => h_rwds_i_c
    );

  GEN_DQ_I: for i in 0 to 7 generate

    U_IBUF: component ibuf
      port map (
        i => h_dq(i),
        o => h_dq_i_u(i)
      );

    U_IDELAY: component idelaye2
      generic map (
        DELAY_SRC             => "IDATAIN",
        IDELAY_TYPE           => "FIXED",
        PIPE_SEL              => "FALSE",
        IDELAY_VALUE          => 0,
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
        idatain     => h_dq_i_u(i),
        datain      => '0',
        dataout     => h_dq_i_d(i)
      );

    U_IDDR: component iddr
      generic map (
        IS_C_INVERTED => '1',
        DDR_CLK_EDGE  => "SAME_EDGE",
        SRTYPE        => "ASYNC"
      )
      port map (
        r  => s_rst,
        s  => '0',
        c  => h_rwds_i_c,
        ce => busy_rd,
        d  => h_dq_i_d(i),
        q1 => h_dq_i_r(0+i),
        q2 => h_dq_i_r(8+i)
      );

  end generate GEN_DQ_I;

  --------------------------------------------------------------------------------
  -- read FIFO: accepts data in h_rwds_i_c domain, forwards to system read port
  -- clocked by falling edge so that a single additional RWDS pulse is enough

  P_R_FIFO_WE: process(h_cs_n,h_rwds_i_c)
  begin
    if h_cs_n = '1' then
      r_fifo_we <= '0';
    elsif falling_edge(h_rwds_i_c) then
      r_fifo_we <= busy_rd;
    end if;
  end process P_R_FIFO_WE;

  P_R_FIFO_WA: process(s_rst,h_rwds_i_c)
  begin
    if s_rst = '1' then
      r_fifo_wa <= (others => '0');
    elsif falling_edge(h_rwds_i_c) and r_fifo_we = '1' then
      r_fifo_wa <= incr(r_fifo_wa);
    end if;
  end process P_R_FIFO_WA;

  r_fifo_wd(0) <= '0' & h_dq_i_r( 4 downto  0);
  r_fifo_wd(1) <= '0' & h_dq_i_r( 9 downto  5);
  r_fifo_wd(2) <= h_dq_i_r(15 downto 10);

  GEN_RAM: for i in 0 to 2 generate
    RAM: component ram_sdp_32x6
      generic map (
        CLK_EDGE =>"falling"
      )
      port map (
        clk => h_rwds_i_c,
        we  => r_fifo_we,
        wa  => r_fifo_wa,
        wd  => r_fifo_wd(i),
        ra  => r_fifo_ra,
        rd  => r_fifo_rd(i)
      );
  end generate GEN_RAM;

  s_r_data( 4 downto  0) <= r_fifo_rd(0)(4 downto 0);
  s_r_data( 9 downto  5) <= r_fifo_rd(1)(4 downto 0);
  s_r_data(15 downto 10) <= r_fifo_rd(2)(5 downto 0);

  --------------------------------------------------------------------------------

end architecture rtl;
