--------------------------------------------------------------------------------
-- model_dvi_decoder.vhd                                                      --
-- Simple DVI (serial TMDS) to parallel video decoder.                        --
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

library work;
  use work.tyto_types_pkg.all;

package model_dvi_decoder_pkg is

  component model_dvi_decoder is
    port (

      dvi_clk : in    std_logic;
      dvi_d   : in    std_logic_vector(0 to 2);

      vga_clk : out   std_logic;
      vga_vs  : out   std_logic;
      vga_hs  : out   std_logic;
      vga_de  : out   std_logic;
      vga_p   : out   slv_7_0_t(0 to 2)

    );
  end component model_dvi_decoder;

end package model_dvi_decoder_pkg;

--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.tyto_types_pkg.all;
  use work.model_tmds_cdr_des_pkg.all;

entity model_dvi_decoder is
  port (

    dvi_clk : in    std_logic;
    dvi_d   : in    std_logic_vector(0 to 2); -- 3x TMDS channels

    vga_clk : out   std_logic;
    vga_vs  : out   std_logic;                -- vertical sync
    vga_hs  : out   std_logic;                -- horizontal sync
    vga_de  : out   std_logic;                -- pixel data enable
    vga_p   : out   slv_7_0_t(0 to 2)         -- pixel data components

  );
end entity model_dvi_decoder;

architecture model of model_dvi_decoder is

  signal tmds_data   : slv_9_0_t(0 to 2);
  signal tmds_clk    : std_logic_vector(0 to 2);
  signal tmds_locked : std_logic_vector(0 to 2);
  signal tmds_c      : slv_1_0_t(0 to 2);        -- decoded control bits
  signal tmds_de     : std_logic_vector(0 to 2);

begin

  -- CDR, deserialise

  gen_tmds_cdr_des: for i in 0 to 2 generate

    TMDS_CDR_DES: component model_tmds_cdr_des
      port map (
        refclk   => dvi_clk,
        serial   => dvi_d(i),
        parallel => tmds_data(i),
        clk      => tmds_clk(i),
        locked   => tmds_locked(i)
      );

  end generate gen_tmds_cdr_des;

  -- assumption: channel to channel skew is small (less than half a pixel clock)
  vga_clk <= tmds_clk(0);

  -- decode
  DECODE: process (tmds_data) is
    variable s : std_logic_vector(9 downto 0);
  begin
    for i in 0 to 2 loop
      s           := tmds_data(i);
      tmds_de(i)  <= tmds_locked(i);
      vga_p(i)(0) <= s(0) xor s(9);
      for j in 1 to 7 loop
        vga_p(i)(j) <= (s(j) xor s(9)) xor ((s(j-1) xor s(9)) xnor s(8));
      end loop;
      case s is
        when "1101010100" => tmds_c(i) <= "00"; tmds_de(i) <= '0';
        when "0010101011" => tmds_c(i) <= "01"; tmds_de(i) <= '0';
        when "0101010100" => tmds_c(i) <= "10"; tmds_de(i) <= '0';
        when "1010101011" => tmds_c(i) <= "11"; tmds_de(i) <= '0';
        when others => null;
      end case;
    end loop;
  end process DECODE;

  vga_de <= tmds_de(0) and tmds_de(1) and tmds_de(2);
  vga_vs <= tmds_c(0)(1);
  vga_hs <= tmds_c(0)(0);

end architecture model;
