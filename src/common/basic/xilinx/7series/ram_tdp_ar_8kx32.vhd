--------------------------------------------------------------------------------
-- ram_tdp_ar_8kx32.vhd                                                       --
-- True dual port RAM, separate clocks, synchronous reset.                    --
--------------------------------------------------------------------------------
-- (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        --
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

package ram_tdp_ar_8kx32_pkg is

  component ram_tdp_ar_8kx32 is
    port (
      clk_a  : in    std_logic;
      clr_a  : in    std_logic;
      en_a   : in    std_logic;
      we_a   : in    std_logic_vector(3 downto 0);
      addr_a : in    std_logic_vector(14 downto 2);
      din_a  : in    std_logic_vector(31 downto 0);
      dout_a : out   std_logic_vector(31 downto 0);
      clk_b  : in    std_logic;
      clr_b  : in    std_logic;
      en_b   : in    std_logic;
      we_b   : in    std_logic_vector(3 downto 0);
      addr_b : in    std_logic_vector(14 downto 2);
      din_b  : in    std_logic_vector(31 downto 0);
      dout_b : out   std_logic_vector(31 downto 0)
    );
  end component ram_tdp_ar_8kx32;

end package ram_tdp_ar_8kx32_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

library unisim;
  use unisim.vcomponents.all;

library work;
  use work.tyto_types_pkg.all;

entity ram_tdp_ar_8kx32 is
  port (
    clk_a  : in    std_logic;
    clr_a  : in    std_logic;
    en_a   : in    std_logic;
    we_a   : in    std_logic_vector(3 downto 0);
    addr_a : in    std_logic_vector(14 downto 2);
    din_a  : in    std_logic_vector(31 downto 0);
    dout_a : out   std_logic_vector(31 downto 0);
    clk_b  : in    std_logic;
    clr_b  : in    std_logic;
    en_b   : in    std_logic;
    we_b   : in    std_logic_vector(3 downto 0);
    addr_b : in    std_logic_vector(14 downto 2);
    din_b  : in    std_logic_vector(31 downto 0);
    dout_b : out   std_logic_vector(31 downto 0)
  );
end entity ram_tdp_ar_8kx32;

architecture synth of ram_tdp_ar_8kx32 is

  signal bwe_a : std_logic_vector(0 to 7);
  signal bwe_b : std_logic_vector(0 to 7);
  signal doado : sulv_vector(0 to 7)(31 downto 0);
  signal dobdo : sulv_vector(0 to 7)(31 downto 0);

begin

  bwe_a <= we_a(0) & we_a(0) & we_a(1) & we_a(1) & we_a(2) & we_a(2) & we_a(3) & we_a(3);
  bwe_b <= we_b(0) & we_b(0) & we_b(1) & we_b(1) & we_b(2) & we_b(2) & we_b(3) & we_b(3);

  GEN: for i in 0 to 7 generate
  begin

    dout_a(3+(i*4) downto i*4) <= doado(i)(3 downto 0);
    dout_b(3+(i*4) downto i*4) <= dobdo(i)(3 downto 0);

    RAM: component ramb36e1
      generic map (
        rdaddr_collision_hwconfig => "DELAYED_WRITE",           -- Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
        sim_collision_check       => "ALL",                     -- "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
        doa_reg                   => 0,                         -- optional output register (0 or 1)
        dob_reg                   => 0,                         -- optional output register (0 or 1)
        en_ecc_read               => FALSE,                     -- Enable ECC decoder (FALSE, TRUE)
        en_ecc_write              => FALSE,                     -- Enable ECC encoder (FALSE, TRUE)
        init_a                    => X"000000000",              -- initial values on output port A
        init_b                    => X"000000000",              -- initial values on output port B
        init_file                 => "NONE",                    -- Initialization File: RAM initialization file
        ram_mode                  => "TDP",                     -- RAM Mode: "SDP" or "TDP"
        ram_extension_a           => "NONE",                    -- cascade mode ("UPPER", "LOWER", or "NONE")
        ram_extension_b           => "NONE",                    -- cascade mode ("UPPER", "LOWER", or "NONE")
        read_width_a              => 4,                         -- port width, 0-72
        read_width_b              => 4,                         -- port width, 0-36
        write_width_a             => 4,                         -- port width, 0-36
        write_width_b             => 4,                         -- port width, 0-72
        rstreg_priority_a         => "RSTREG",                  -- port A reset or enable priority ("RSTREG" or "REGCE")
        rstreg_priority_b         => "RSTREG",                  -- port B reset or enable priority ("RSTREG" or "REGCE")
        srval_a                   => X"000000000",              -- set/reset value for output
        srval_b                   => X"000000000",              -- set/reset value for output
        sim_device                => "7SERIES",                 -- must be set to "7SERIES" for simulation behavior
        write_mode_a              => "READ_FIRST",              -- port A mode (WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        write_mode_b              => "READ_FIRST"               -- port B mode (WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
      )
      port map (
        cascadeouta               => open,                      -- 1 bit output: A port cascade (to create 64kx1)
        cascadeoutb               => open,                      -- 1 bit output: B port cascade (to create 64kx1)
        dbiterr                   => open,                      -- 1 bit output: ECC - double bit error status
        eccparity                 => open,                      -- 8-bit output: Generated error correction parity
        rdaddrecc                 => open,                      -- 9-bit output: ECC read address
        sbiterr                   => open,                      -- 1-bit output: Single bit error status
        doado                     => doado(i),                  -- 32-bit output: A port data/LSB data
        dopadop                   => open,                      -- 4-bit output: A port parity/LSB parity
        dobdo                     => dobdo(i),                  -- 32-bit output: B port data/MSB data
        dopbdop                   => open,                      -- 4-bit output: B port parity/MSB parity
        cascadeina                => '0',                       -- 1-bit input: A port cascade
        cascadeinb                => '0',                       -- 1-bit input: B port cascade
        injectdbiterr             => '0',                       -- 1-bit input: Inject a double bit error
        injectsbiterr             => '0',                       -- 1-bit input: Inject a single bit error
        addrardaddr(14 downto 2)  => addr_a,                    -- 16-bit input: A port address/Read address
        addrardaddr(1 downto 0)   => (others => '1'),
        addrardaddr(15)           => '1',
        clkardclk                 => clk_a,                     -- 1-bit input: A port clock/Read clock
        enarden                   => en_a,                      -- 1-bit input: A port enable/Read enable
        regcearegce               => '0',                       -- 1-bit input: A port register enable/Register enable
        rstramarstram             => clr_a,                     -- 1-bit input: A port set/reset
        rstregarstreg             => '0',                       -- 1-bit input: A port register set/reset
        wea(0)                    => bwe_a(i),                  -- 4-bit input: A port write enable
        wea(3 downto 1)           => (others => '0'),
        diadi(3 downto 0)         => din_a(3+(i*4) downto i*4), -- 32-bit input: A port data/MSB data
        diadi(31 downto 4)        => (others => '0'),
        dipadip                   => (others => '0'),           -- 4-bit input: A port parity/LSB parity
        addrbwraddr(14 downto 2)  => addr_b,                    -- 16-bit input: B port address/Write address
        addrbwraddr(1 downto 0)   => (others => '1'),
        addrbwraddr(15)           => '1',
        clkbwrclk                 => clk_b,                     -- 1-bit input: B port clock/Write clock
        enbwren                   => en_b,                      -- 1-bit input: B port enable/Write enable
        regceb                    => '0',                       -- 1-bit input: B port register enable
        rstramb                   => clr_b,                     -- 1-bit input: B port set/reset
        rstregb                   => '0',                       -- 1-bit input: B port register set/reset
        webwe(0)                  => bwe_b(i),                  -- 8-bit input: B port write enable/Write enable
        webwe(7 downto 1)         => (others => '0'),
        dibdi(3 downto 0)         => din_b(3+(i*4) downto i*4), -- 32-bit input: B port data/LSB data
        dibdi(31 downto 4)        => (others => '0'),
        dipbdip                   => (others => '0')            -- 4-bit input: B port parity/MSB parity
      );

  end generate GEN;

end architecture synth;
