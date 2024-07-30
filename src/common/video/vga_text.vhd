--------------------------------------------------------------------------------
-- vga_text.vhd                                                               --
-- Character display with VGA font and CGA colours.                           --
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

use work.video_out_timing_v2_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

package vga_text_pkg is

  constant cols_log2 : integer := 8;
  constant rows_log2 : integer := 7;

  type vga_text_params_t is record
    cols : std_ulogic_vector(cols_log2-1 downto 0);
    rows : std_ulogic_vector(rows_log2-1 downto 0);
    repx : std_ulogic;
    repy : std_ulogic;
    ox   : std_ulogic_vector(11 downto 0);
    oy   : std_ulogic_vector(11 downto 0);
    bcol : std_ulogic_vector(3 downto 0);
  end record vga_text_params_t;

  type vga_t is record
    vs : std_ulogic;
    hs : std_ulogic;
    de : std_ulogic;
    r  : std_ulogic_vector(7 downto 0);
    g  : std_ulogic_vector(7 downto 0);
    b  : std_ulogic_vector(7 downto 0);
  end record vga_t;

  component vga_text is
    port (
      rst      : in    std_ulogic;
      clk      : in    std_ulogic;
      params   : in    vga_text_params_t;
      vtg      : in    vtg_t;
      buf_en   : out   std_ulogic;
      buf_addr : out   std_ulogic_vector;
      buf_data : in    std_ulogic_vector(15 downto 0);
      vga      : out   vga_t

    );
  end component vga_text;

end package vga_text_pkg;

--------------------------------------------------------------------------------

use work.vga_text_pkg.all;
use work.video_out_timing_v2_pkg.all;
use work.tyto_utils_pkg.all;
use work.vga_text_pkg.all;
use work.char_rom_437_8x16_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity vga_text is
  port (
    rst      : in    std_ulogic;
    clk      : in    std_ulogic;
    params   : in    vga_text_params_t;
    vtg      : in    vtg_t;
    buf_en   : out   std_ulogic;
    buf_addr : out   std_ulogic_vector;
    buf_data : in    std_ulogic_vector(15 downto 0);
    vga      : out   vga_t
  );
end entity vga_text;

architecture rtl of vga_text is

  constant COLS_MAX : integer := (2**cols_log2)-1;
  constant ROWS_MAX : integer := (2**rows_log2)-1;

  signal s1_cvx           : std_ulogic;                        -- character visible area X
  signal s1_cvy           : std_ulogic;                        -- character visible area Y
  signal s1_repx          : std_ulogic;                        -- character pixel repeat X
  signal s1_repy          : std_ulogic;                        -- character pixel repeat Y
  signal s1_cpx0          : std_ulogic;                        -- character pixel X = 0
  signal s1_cpx           : integer range 0 to 7;              -- character pixel X
  signal s1_cpy           : integer range 0 to 15;             -- character pixel Y
  signal s1_ccx           : integer range 0 to COLS_MAX;       -- character cell X
  signal s1_ccy           : integer range 0 to ROWS_MAX;       -- character cell Y
  signal s1_cca           : std_ulogic_vector(buf_addr'range); -- character cell address
  signal s1_cra           : std_ulogic_vector(buf_addr'range); -- character row address
  signal s1_vs            : std_ulogic;
  signal s1_hs            : std_ulogic;
  signal s1_de            : std_ulogic;

  signal s2_cvx           : std_ulogic;
  signal s2_cvy           : std_ulogic;
  signal s2_repx          : std_ulogic;
  signal s2_cpx0          : std_ulogic;
  signal s2_vs            : std_ulogic;
  signal s2_hs            : std_ulogic;
  signal s2_de            : std_ulogic;
  signal s2_code          : std_ulogic_vector(7 downto 0);
  signal s2_attr          : std_ulogic_vector(7 downto 0);
  signal s2_rom_row       : std_ulogic_vector(3 downto 0);

  signal s3_cvx           : std_ulogic;
  signal s3_cvy           : std_ulogic;
  signal s3_repx          : std_ulogic;
  signal s3_cpx0          : std_ulogic;
  signal s3_vs            : std_ulogic;
  signal s3_hs            : std_ulogic;
  signal s3_de            : std_ulogic;
  signal s3_attr          : std_ulogic_vector(7 downto 0);
  signal s3_rom_data      : std_ulogic_vector(7 downto 0);

  signal s4_cvx           : std_ulogic;
  signal s4_cvy           : std_ulogic;
  signal s4_vs            : std_ulogic;
  signal s4_hs            : std_ulogic;
  signal s4_de            : std_ulogic;
  signal s4_sr            : std_ulogic_vector(7 downto 0);
  signal s4_attr          : std_ulogic_vector(7 downto 0);


begin

  -- 5 clock pipeline:
  --  0: VTG incl ax,ay
  --  1: buf_addr
  --  2: buf_data => ROM addr
  --  3: ROM data
  --  4: shift reg
  --  5: output

  P_COMB: process(all)
  begin

    s1_cpx0  <= '1' when s1_cpx = 0 else '0';
    buf_en   <= s1_cvx and s1_cvy;
    buf_addr <= s1_cca;
    s2_code  <= buf_data(7 downto 0);
    s2_attr  <= buf_data(15 downto 8);

  end process P_COMB;


  P_MAIN: process (clk) is

    -- CGA palette
    function cga (c : std_ulogic_vector(3 downto 0)) return std_ulogic_vector is
      variable bgr : std_ulogic_vector(23 downto 0);
    begin
      case c is
        when x"0" => bgr := std_ulogic_vector'(x"000000");
        when x"1" => bgr := std_ulogic_vector'(x"AA0000");
        when x"2" => bgr := std_ulogic_vector'(x"00AA00");
        when x"3" => bgr := std_ulogic_vector'(x"AAAA00");
        when x"4" => bgr := std_ulogic_vector'(x"0000AA");
        when x"5" => bgr := std_ulogic_vector'(x"AA00AA");
        when x"6" => bgr := std_ulogic_vector'(x"0055AA");
        when x"7" => bgr := std_ulogic_vector'(x"AAAAAA");
        when x"8" => bgr := std_ulogic_vector'(x"555555");
        when x"9" => bgr := std_ulogic_vector'(x"FF5555");
        when x"A" => bgr := std_ulogic_vector'(x"55FF55");
        when x"B" => bgr := std_ulogic_vector'(x"FFFF55");
        when x"C" => bgr := std_ulogic_vector'(x"5555FF");
        when x"D" => bgr := std_ulogic_vector'(x"FF55FF");
        when x"E" => bgr := std_ulogic_vector'(x"55FFFF");
        when x"F" => bgr := std_ulogic_vector'(x"FFFFFF");
        when others => bgr := (others => 'X');
      end case;
      return bgr;
    end function cga;

  begin
    if rst = '1' then

      s1_cvx     <= '0';
      s1_cvy     <= '0';
      s1_repx    <= '0';
      s1_repy    <= '0';
      s1_cpx     <= 0;
      s1_cpy     <= 0;
      s1_ccx     <= 0;
      s1_ccy     <= 0;
      s1_cca     <= (others => '0');
      s1_cra     <= (others => '0');
      s1_vs      <= '0';
      s1_hs      <= '0';
      s1_de      <= '0';

      s2_cvx     <= '0';
      s2_cvy     <= '0';
      s2_repx    <= '0';
      s2_cpx0    <= '0';
      s2_vs      <= '0';
      s2_hs      <= '0';
      s2_de      <= '0';
      s2_rom_row <= (others => '0');

      s3_cvx     <= '0';
      s3_cvy     <= '0';
      s3_repx    <= '0';
      s3_cpx0    <= '0';
      s3_vs      <= '0';
      s3_hs      <= '0';
      s3_de      <= '0';

      s4_cvx     <= '0';
      s4_cvy     <= '0';
      s4_vs      <= '0';
      s4_hs      <= '0';
      s4_de      <= '0';
      s4_sr      <= (others => '0');
      s4_attr    <= (others => '0');

      vga.vs     <= '0';
      vga.hs     <= '0';
      vga.de     <= '0';
      vga.r      <= (others => '0');
      vga.g      <= (others => '0');
      vga.b      <= (others => '0');

    elsif rising_edge(clk) then

      --------------------------------------------------------------------------------
      -- pipeline stage 1

      if vtg.ax = params.ox then
        s1_cvx  <= '1';
        s1_repx <= not params.repx;
        s1_cpx  <= 0;
        s1_ccx  <= 0;
        s1_cca  <= s1_cra;
      elsif s1_cvx then
        s1_repx <= s1_repx xor params.repx;
        if s1_repx then
          if s1_cpx = 7 then
            s1_cpx <= 0;
            if s1_ccx = to_integer(unsigned(params.cols))-1 then
              s1_cvx <= '0';
            end if;
            s1_ccx <= s1_ccx + 1;
            s1_cca <= incr(s1_cca);
          else
            s1_cpx <= s1_cpx + 1;
          end if;
        end if;
      end if;
      if vtg.hs = '0' and s1_hs = '1' and vtg.ay = params.oy then --  at beginning of line
        s1_cvy   <= '1';
        s1_repy  <= not params.repy;
        s1_cpy   <= 0;
        s1_ccy   <= 0;
        s1_cca   <= (others => '0');
        s1_cra   <= (others => '0');
      elsif vtg.hs = '1' and s1_hs = '0' and s1_cvy = '1' then -- at end of line
        s1_repy <= s1_repy xor params.repy;
        if s1_repy then
          if s1_cpy = 15 then
            s1_cpy <= 0;
            if s1_ccy = to_integer(unsigned(params.rows))-1 then
              s1_cvy <= '0';
            end if;
            s1_ccy <= s1_ccy + 1;
            s1_cra <= s1_cca;
          else
            s1_cpy <= s1_cpy + 1;
          end if;
        end if;
      end if;

      s1_vs <= vtg.vs;
      s1_hs <= vtg.hs;
      s1_de <= not (vtg.vblank or vtg.hblank);

      --------------------------------------------------------------------------------
      -- pipeline stage 2

      s2_cvx     <= s1_cvx;
      s2_cvy     <= s1_cvy;
      s2_repx    <= s1_repx;
      s2_cpx0    <= s1_cpx0;
      s2_vs      <= s1_vs;
      s2_hs      <= s1_hs;
      s2_de      <= s1_de;

      s2_rom_row <= std_ulogic_vector(to_unsigned(s1_cpy,s2_rom_row'length));

      --------------------------------------------------------------------------------
      -- pipeline stage 3

      s3_cvx  <= s2_cvx;
      s3_cvy  <= s2_cvy;
      s3_repx <= s2_repx;
      s3_cpx0 <= s2_cpx0;
      s3_vs   <= s2_vs;
      s3_hs   <= s2_hs;
      s3_de   <= s2_de;
      s3_attr <= s2_attr;

      --------------------------------------------------------------------------------
      -- pipeline stage 4

      s4_cvx  <= s3_cvx;
      s4_cvy  <= s3_cvy;
      s4_vs   <= s3_vs;
      s4_hs   <= s3_hs;
      s4_de   <= s3_de;
      s4_attr <= s3_attr;

      if s3_cpx0 and s3_repx then
        s4_sr <= s3_rom_data;
      elsif s3_repx then
        s4_sr <= s4_sr(6 downto 0) & '0';
      end if;

      --------------------------------------------------------------------------------
      -- pipeline stage 5

      vga.vs <= s4_vs;
      vga.hs <= s4_hs;
      vga.de <= s4_de;
      vga.r  <= (others => '0');
      vga.g  <= (others => '0');
      vga.b  <= (others => '0');
      if s4_de = '1' then
        if s4_cvx and s4_cvy then
          if s4_sr(7) = '1' then                             -- character foreground colour
            vga.r <= cga(s4_attr(3 downto 0))(7 downto 0);
            vga.g <= cga(s4_attr(3 downto 0))(15 downto 8);
            vga.b <= cga(s4_attr(3 downto 0))(23 downto 16);
          else                                               -- character background colour
            vga.r <= cga(s4_attr(7 downto 4))(7 downto 0);
            vga.g <= cga(s4_attr(7 downto 4))(15 downto 8);
            vga.b <= cga(s4_attr(7 downto 4))(23 downto 16);
          end if;
        else                                                 -- border colour
          vga.r <= cga(params.bcol)(7 downto 0);
          vga.g <= cga(params.bcol)(15 downto 8);
          vga.b <= cga(params.bcol)(23 downto 16);
        end if;
      end if;

      --------------------------------------------------------------------------------

    end if;
  end process P_MAIN;

  -- character ROM (256 patterns x 8 pixels wide x 16 rows high)

  ROM: component char_rom_437_8x16
    port map (
      clk => clk,
      r   => s2_rom_row, -- character row (scan line) (0..15)
      a   => s2_code,    -- character code (0..255)
      d   => s3_rom_data -- character row data (8 pixels)
    );

end architecture rtl;
