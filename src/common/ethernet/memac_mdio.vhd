--------------------------------------------------------------------------------
-- memac_mdio.vhd                                                             --
-- Modular Ethernet MAC: MDIO interface.                                      --
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

package memac_mdio_pkg is

  component memac_mdio is
    generic (
      DIV5M : integer -- e.g. 100/20 = 5 MHz
    );
    port (
      rst  : in    std_ulogic;
      clk  : in    std_ulogic;
      stb  : in    std_ulogic;
      pre  : in    std_ulogic;
      r_w  : in    std_ulogic;
      pa   : in    std_ulogic_vector(4 downto 0);
      ra   : in    std_ulogic_vector(4 downto 0);
      wd   : in    std_ulogic_vector(15 downto 0);
      rd   : out   std_ulogic_vector(15 downto 0);
      rdy  : out   std_ulogic;
      mdc  : out   std_ulogic;
      mdo  : out   std_ulogic;
      mdoe : out   std_ulogic;
      mdi  : in    std_ulogic
    );
  end component memac_mdio;

end package memac_mdio_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity memac_mdio is
  generic (
    DIV5M : integer -- e.g. 100 MHz / 20 -> 5 MHz
  );
  port (
    rst  : in    std_ulogic;                      -- PHY reset
    clk  : in    std_ulogic;                      -- system clock e.g. 100 MHz
    stb  : in    std_ulogic;
    pre  : in    std_ulogic;                      -- enable preamble
    r_w  : in    std_ulogic;
    pa   : in    std_ulogic_vector(4 downto 0);
    ra   : in    std_ulogic_vector(4 downto 0);
    wd   : in    std_ulogic_vector(15 downto 0);
    rd   : out   std_ulogic_vector(15 downto 0);
    rdy  : out   std_ulogic;
    mdc  : out   std_ulogic;
    mdo  : out   std_ulogic;
    mdoe : out   std_ulogic;
    mdi  : in    std_ulogic
  );
end entity memac_mdio;

architecture rtl of memac_mdio is

  type state_t is (IDLE,SKIP,PREAMBLE,TRANSACTION);

  signal state     : state_t;
  signal count_div : integer range 0 to DIV5M-1;
  signal count_bit : integer range 0 to 31;
  signal r_w_l     : std_ulogic;
  signal sro       : std_ulogic_vector(31 downto 0); -- output shift register
  signal sri       : std_ulogic_vector(15 downto 0); -- input shift register

begin

  P_MAIN: process(rst,clk)
  begin
    if rst = '1' then

      state     <= IDLE;
      count_div <= 0;
      count_bit <= 0;
      r_w_l     <= '0';
      sro        <= (others => '0');
      sri        <= (others => '0');
      rdy       <= '0';
      mdc       <= '0';
      mdo       <= '0';
      mdoe      <= '0';

    elsif rising_edge(clk) then

      rdy  <= '0';

      case state is

        when IDLE =>
          count_div <= 0;
          count_bit <= 0;
          r_w_l     <= '0';
          sro        <= (others => '0');
          sri        <= (others => '0');
          mdc       <= '0';
          mdo       <= '0';
          mdoe      <= '0';
          if stb = '1' then
            r_w_l <= r_w;
            sro(31 downto 30) <= "01";
            sro(29 downto 28) <= "01" when r_w = '0' else "10";
            sro(27 downto 23) <= pa;
            sro(22 downto 18) <= ra;
            sro(17 downto 16) <= "10" when r_w = '0' else "00";
            sro(15 downto  0) <= wd;
            sri <= (others => 'X');
            if pre = '1' then
              mdo  <= '1';
              mdoe <= '1';
              state <= PREAMBLE;
            else
              state <= SKIP;
            end if;
          end if;

        when SKIP =>
          mdo  <= sro(31);
          mdoe <= '1';
          sro  <= sro(30 downto 0) & 'X';
          state <= TRANSACTION;

        -- 32 cycle preamble
        when PREAMBLE  =>
          if count_div = DIV5M-1 then
            if mdc = '1' then
              if count_bit = 31 then
                mdo  <= sro(31);
                sro  <= sro(30 downto 0) & 'X';
                state <= TRANSACTION;
              end if;
              count_bit <= (count_bit + 1) mod 32;
            end if;
            mdc <= not mdc;
          end if;
          count_div <= (count_div + 1) mod DIV5M;

        when TRANSACTION =>
          if count_div = DIV5M-1 then
            if mdc = '1' then
              mdo <= sro(31);
              sro  <= sro(30 downto 0) & 'X';
              if count_bit = 13 and r_w_l = '1' then -- tristate for read
                mdo  <= '0';
                mdoe <= '0';
              end if;
              if count_bit = 31 then
                rdy  <= '1';
                mdo  <= '0';
                mdoe <= '0';
                rd <= sri;
                state <= IDLE;
              end if;
              count_bit <= (count_bit + 1) mod 32;
            else
              sri <= sri(14 downto 0) & mdi;
            end if;
            mdc <= not mdc;
          end if;
          count_div <= (count_div + 1) mod DIV5M;

        when others =>
          state <= IDLE;

      end case;

    end if;
  end process P_MAIN;


end architecture rtl;