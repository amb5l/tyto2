--------------------------------------------------------------------------------
-- model_mdio.vhd                                                             --
-- Simple MDIO slave model.                                                   --
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

package model_mdio_pkg is

  component model_mdio is
    generic (
      PHYID1 : std_ulogic_vector(15 downto 0);
      PHYID2 : std_ulogic_vector(15 downto 0)
    );
    port (
      rst  : in    std_ulogic;
      mdc  : in    std_ulogic;
      mdio : inout std_ulogic
    );
  end component model_mdio;

end package model_mdio_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity model_mdio is
  generic (
    PHYID1 : std_ulogic_vector(15 downto 0);
    PHYID2 : std_ulogic_vector(15 downto 0)
  );
  port (
    rst  : in    std_ulogic;
    mdc  : in    std_ulogic;
    mdio : inout std_ulogic
  );
end entity model_mdio;

architecture model of model_mdio is

  constant RA_PHYID1 : std_ulogic_vector(4 downto 0) := "00010";
  constant RA_PHYID2 : std_ulogic_vector(4 downto 0) := "00011";

  type state_t is (PREAMBLE,ADDRCTRL,DATA);

  signal mdi   : std_ulogic;
  signal mdo   : std_ulogic;
  signal mdoe  : std_ulogic;
  signal state : state_t;
  signal count : integer;

  signal r_w   : std_ulogic;
  signal pa    : std_ulogic_vector(4 downto 0);
  signal ra    : std_ulogic_vector(4 downto 0);
  signal wd    : std_ulogic_vector(15 downto 0);
  signal rd    : std_ulogic_vector(15 downto 0);

begin

  mdio <= mdo when mdoe = '1' else 'Z';
  mdi  <= mdio;

  P_MAIN: process(rst,mdc)
  begin
    if rst = '1' then
      state <= PREAMBLE;
      count <= 0;
    elsif rising_edge(mdc) then
      case state is
        when PREAMBLE =>
          assert mdi = '1' report "expected '1' during preamble" severity failure;
          if count = 31 then
            state <= ADDRCTRL;
            count <= 0;
          else
            count <= count + 1;
          end if;
        when ADDRCTRL =>
          case count is
            when 0 => assert mdi = '0' report "transaction bit 0: expected 0" severity failure;
            when 1 => assert mdi = '1' report "transaction bit 1: expected 1" severity failure;
            when 2 => r_w <= mdi;
            when 3 => assert mdi = not r_w report "transaction bit 3: bad R/W" severity failure;
            when 4 | 5 | 6 | 7 | 8 =>
              pa <= pa(3 downto 0) & mdi;
            when 9 | 10 | 11 | 12 | 13 =>
              ra <= ra(3 downto 0) & mdi;
            when 14 => assert mdi = 'Z' report "transaction bit 14: expected Z" severity failure;
            when 15 => assert mdi = '0' report "transaction bit 15: expected 0" severity failure;
            when others => report "unexpected count" severity failure;
          end case;
          if count = 15 then
            if r_w = '1' then
              if unsigned(pa) = 0 then
                case ra is
                  when RA_PHYID1 => rd <= PHYID1;
                  when RA_PHYID2 => rd <= PHYID2;
                  when others =>    rd <= (others => 'X');
                end case;
              else
                rd <= (others => 'X');
              end if;
            else
              rd <= (others => 'X');
            end if;
            state <= DATA;
            count <= 0;
          else
            count <= count + 1;
          end if;
        when DATA =>
          if count = 15 then
            state <= PREAMBLE;
            count <= 0;
          else
            count <= count + 1;
          end if;
      end case;
    end if;
    if rst = '1' then
      mdoe  <= '0';
      mdo   <= 'X';
    elsif falling_edge(mdc) then
      if state = ADDRCTRL then
        if count = 14 then
          if unsigned(pa) = 0 and r_w = '1' then
            case ra is
              when RA_PHYID1 => rd <= PHYID1;
              when RA_PHYID2 => rd <= PHYID2;
              when others =>    rd <= (others => 'X');
            end case;
          else
            rd <= (others => 'X');
          end if;
        elsif count = 15 then
          if unsigned(pa) = 0 and r_w = '1' then
            mdoe <= '1';
            mdo  <= '0';
          end if;
        end if;
      elsif state = DATA then
        mdo  <= rd(15);
        rd   <= rd(14 downto 0) & 'X';
      elsif state = PREAMBLE then
        mdoe <= '0';
        mdo  <= 'X';
      end if;
    end if;
  end process P_MAIN;

end architecture model;
