--------------------------------------------------------------------------------
-- muart_tx.vhd                                                               --
-- Modular UART: TX side.                                                     --
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

package muart_fifo_pkg is

  component muart_fifo is
    generic (
      DEPTH_LOG2 : integer
    );
    port (
      rst     : in    std_ulogic;
      clk     : in    std_ulogic;
      i_ready : out   std_ulogic;
      i_valid : in    std_ulogic;
      i_d     : in    std_logic_vector(7 downto 0);
      o_ready : in    std_ulogic;
      o_valid : out   std_ulogic;
      o_d     : out   std_logic_vector(7 downto 0)
    );
  end component muart_fifo;

end package muart_fifo_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

entity muart_fifo is
  generic (
    DEPTH_LOG2 : integer -- log2(FIFO depth) e.g. 11 => 2048 bytes
  );
  port (
    rst     : in    std_ulogic;
    clk     : in    std_ulogic;
    i_ready : out   std_ulogic;
    i_valid : in    std_ulogic;
    i_d     : in    std_logic_vector(7 downto 0);
    o_ready : in    std_ulogic;
    o_valid : out   std_ulogic;
    o_d     : out   std_logic_vector(7 downto 0)
  );
end entity muart_fifo;

architecture rtl of muart_fifo is

  constant D_WIDTH : integer := 2**(DEPTH_LOG2-6);

  signal ef : std_ulogic;
  signal ff : std_ulogic;

  signal we : std_ulogic;
  signal re : std_ulogic;

  signal di : std_ulogic_vector(D_WIDTH-1 downto 0);
  signal do : std_ulogic_vector(D_WIDTH-1 downto 0);

begin

  i_ready <= not ff;
  we <= i_valid and i_ready;
  di <= (7 downto 0 => i_d, others => '0');

  o_valid <= not ef;
  re <= o_valid and o_ready;
  o_d <= do(7 downto 0);

  GEN: if DEPTH_LOG2 = 11 generate

    FIFO18E1_inst : FIFO18E1
      generic map (
        ALMOST_EMPTY_OFFSET     => x"0080",      -- Sets the almost empty threshold
        ALMOST_FULL_OFFSET      => x"0080",      -- Sets almost full threshold
        DATA_WIDTH              => 9,            -- Sets data width to 4-36
        DO_REG                  => 1,            -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
        EN_SYN                  => FALSE,        -- Specifies FIFO as dual-clock (FALSE) or Synchronous (TRUE)
        FIFO_MODE               => "FIFO18",     -- Sets mode to FIFO18 or FIFO18_36
        FIRST_WORD_FALL_THROUGH => TRUE,         -- Sets the FIFO FWFT to FALSE, TRUE
        INIT                    => x"000000000", -- Initial values on output port
        SIM_DEVICE              => "7SERIES",    -- Must be set to "7SERIES" for simulation behavior
        SRVAL                   => x"000000000"  -- Set/Reset value for output port
      )
      port map (
                                                   -- Read Data: 32-bit (each) output: Read output data
        do                      => do,             -- 32-bit output: Data output
        dop                     => open,           -- 4-bit output: Parity data output
                                                   -- Status: 1-bit (each) output: Flags and other FIFO status outputs
        almostempty             => open,           -- 1-bit output: Almost empty flag
        almostfull              => open,           -- 1-bit output: Almost full flag
        empty                   => ef,             -- 1-bit output: Empty flag
        full                    => ff,             -- 1-bit output: Full flag
        rdcount                 => open,           -- 12-bit output: Read count
        rderr                   => open,           -- 1-bit output: Read error
        wrcount                 => open,           -- 12-bit output: Write count
        wrerr                   => open,           -- 1-bit output: Write error
                                                   -- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
        rdclk                   => clk,            -- 1-bit input: Read clock
        rden                    => re,             -- 1-bit input: Read enable
        regce                   => '1',            -- 1-bit input: Clock enable
        rst                     => rst,            -- 1-bit input: Asynchronous Reset
        rstreg                  => rst,            -- 1-bit input: Output register set/reset
                                                   -- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
        wrclk                   => clk,            -- 1-bit input: Write clock
        wren                    => we,             -- 1-bit input: Write enable
                                                   -- Write Data: 32-bit (each) input: Write input data
        di                      => di,             -- 32-bit input: Data input
        dip                     => (others => '0') -- 4-bit input: Parity input
      );

  elsif DEPTH_LOG2 = 12 generate

    FIFO36E1_inst : FIFO36E1
      generic map (
        ALMOST_EMPTY_OFFSET     => x"0080",               -- Sets the almost empty threshold
        ALMOST_FULL_OFFSET      => x"0080",               -- Sets almost full threshold
        DATA_WIDTH              => 9,                     -- Sets data width to 4-72
        DO_REG                  => 1,                     -- Enable output register (1-0) Must be 1 if EN_SYN = FALSE
        EN_ECC_READ             => FALSE,                 -- Enable ECC decoder, FALSE, TRUE
        EN_ECC_WRITE            => FALSE,                 -- Enable ECC encoder, FALSE, TRUE
        EN_SYN                  => FALSE,                 -- Specifies FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
        FIFO_MODE               => "FIFO36",              -- Sets mode to "FIFO36" or "FIFO36_72"
        FIRST_WORD_FALL_THROUGH => TRUE,                  -- Sets the FIFO FWFT to FALSE, TRUE
        INIT                    => x"000000000000000000", -- Initial values on output port
        SIM_DEVICE              => "7SERIES",             -- Must be set to "7SERIES" for simulation behavior
        SRVAL                   => x"000000000000000000"  -- Set/Reset value for output port
      )
      port map (
                                                          -- ECC Signals: 1-bit (each) output: Error Correction Circuitry ports
        dbiterr                 => open,                  -- 1-bit output: Double bit error status
        eccparity               => open,                  -- 8-bit output: Generated error correction parity
        sbiterr                 => open,                  -- 1-bit output: Single bit error status
                                                          -- Read Data: 64-bit (each) output: Read output data
        do                      => do,                    -- 64-bit output: Data output
        dop                     => open,                  -- 8-bit output: Parity data output
                                                          -- Status: 1-bit (each) output: Flags and other FIFO status outputs
        almostempty             => open,                  -- 1-bit output: Almost empty flag
        almostfull              => open,                  -- 1-bit output: Almost full flag
        empty                   => ef,                    -- 1-bit output: Empty flag
        full                    => ff,                    -- 1-bit output: Full flag
        rdcount                 => open,                  -- 13-bit output: Read count
        rderr                   => open,                  -- 1-bit output: Read error
        wrcount                 => open,                  -- 13-bit output: Write count
        wrerr                   => open,                  -- 1-bit output: Write error
                                                          -- ECC Signals: 1-bit (each) input: Error Correction Circuitry ports
        injectdbiterr           => '0',                   -- 1-bit input: Inject a double bit error input
        injectsbiterr           => '0',
                                                          -- Read Control Signals: 1-bit (each) input: Read clock, enable and reset input signals
        rdclk                   => clk,                   -- 1-bit input: Read clock
        rden                    => re,                    -- 1-bit input: Read enable
        regce                   => '1',                   -- 1-bit input: Clock enable
        rst                     => rst,                   -- 1-bit input: Reset
        rstreg                  => rst,                   -- 1-bit input: Output register set/reset
                                                          -- Write Control Signals: 1-bit (each) input: Write clock and enable input signals
        wrclk                   => clk,                   -- 1-bit input: Rising edge write clock.
        wren                    => we,                    -- 1-bit input: Write enable
                                                          -- Write Data: 64-bit (each) input: Write input data
        di                      => di,                    -- 64-bit input: Data input
        dip                     => (others => '0')        -- 8-bit input: Parity input
      );

  else generate

    P_ERROR: process(all)
    begin
      report "DEPTH_LOG2 must be 11 or 12" severity failure;
    end process P_ERROR;

  end generate GEN;

end architecture rtl;
