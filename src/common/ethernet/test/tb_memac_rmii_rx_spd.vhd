--------------------------------------------------------------------------------
-- tb_memac_rmi_rx_spd.vhd                                                    --
-- Modular Ethernet MAC: testbench for memac_rmi_rx_spd.                      --
--------------------------------------------------------------------------------
-- (C) Copyright 2025 Adam Barnes <ambarnes@gmail.com>                        --
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
library memac;
  use memac.memac_util_pkg.all;
  use memac.memac_sim_pkg.all;
  use memac.memac_rmii_rx_spd_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_memac_rmii_rx_spd is
end entity tb_memac_rmii_rx_spd;

architecture sim of tb_memac_rmii_rx_spd is

  constant CLK_PERIOD : time := 20 ns;

  constant CRS_LEN_MIN  : integer := 0;
  constant CRS_LEN_MAX  : integer := 2;
  constant PRE_LEN_MIN  : integer := 7;  -- c.w. single octet of preamble then SFD
  constant PRE_LEN_MAX  : integer := 63;
  constant FRM_LEN_MIN  : integer := 0;
  constant FRM_LEN_MAX  : integer := 80; -- out of spec (too short) but plenty for this test
  constant CRL_LEN_MIN  : integer := 0;
  constant IPG_LEN_MIN  : integer := 2;
  constant IPG_LEN_MAX  : integer := 64;

  constant PROB_PRE_LEN_BAD  : real := 0.02; -- probability of preamble + SFD length not being a multiple of 4 di-bits (octets)
  constant PROB_PRE_ERROR    : real := 0.02; -- probability of error assertion in preamble
  constant PROB_PRE_DATA_BAD : real := 0.02; -- probability of bad data in preamble
  constant PROB_PRE_ABORT    : real := 0.02; -- probability of aborting preamble before SFD
  constant PROB_FRM_ERROR    : real := 0.02; -- probability of error assertion in frame

  -- DUT ports and related signals
  signal rst      : std_ulogic;
  signal clk      : std_ulogic;
  signal i_xspd   : std_ulogic;
  signal i_crs_dv : std_ulogic;
  signal i_er     : std_ulogic;
  signal i_d      : std_ulogic_vector(1 downto 0);
  signal o_crs_dv : std_ulogic;                     -- v4p ignore w-303 | checked in assert below
  signal o_er     : std_ulogic;                     -- v4p ignore w-303 | checked in assert below
  signal o_d      : std_ulogic_vector(1 downto 0);  -- v4p ignore w-303 | checked in assert below
  signal spd      : std_ulogic;

  -- shift register to delay input to align with DUT output
  type sr_stage_t is record
    spd    : std_ulogic;
    crs_dv : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
  end record sr_stage_t;
  type sr_t is array(1 to 65) of sr_stage_t;
  signal sr : sr_t := (others => (spd => '0', crs_dv => '0', er => '0', d => "00"));

begin

  clk <= '0' when clk = 'U' else not clk after CLK_PERIOD/2; -- 50 MHz

  --------------------------------------------------------------------------------
  -- stop when done

  P_MAIN: process(spd)
    variable count : integer := 0;
  begin
    if spd'event and (spd = '0' or spd = '1') then
      count := count + 1;
      if count = 1000 then
        report "done" severity note;
        std.env.stop;
      end if;
    end if;
  end process P_MAIN;

  --------------------------------------------------------------------------------
  -- create stimulus and expected result

  P_STIM: process

    variable prng    : prng_t;

    variable spd     : bit;        -- speed (0 = 10 Mbps, 1 = 100 Mbps)
    variable crs_len : natural;    -- duration of crs_dv assertion before preamble
    variable pre_len : positive;   -- duration of preamble
    variable pre_er  : boolean;    -- assert error during preamble
    variable pre_bad : boolean;    -- corrupt data during preamble
    variable pre_abt : boolean;    -- abort preamble before SFD if
    variable frm_len : natural;    -- duration of frame
    variable frm_er  : boolean;    -- assert error during frame
    variable crl_len : natural;    -- duration of carrier loss before end of frame
    variable xspd    : std_ulogic; -- expected speed from DUT
    variable re      : natural;    -- random error position
    variable rx      : natural;    -- random data corruption position

    procedure wait_clk(spd : bit) is
      variable c : positive;
    begin
      c := 10 when spd = '0' else 1;
      for i in 1 to c loop
        wait until rising_edge(clk);
      end loop;
      wait for CLK_PERIOD/4; -- allow for clock buffer propagation delta cycles in PSF netlist
    end procedure wait_clk;

    procedure wait_clk(spd : bit; n : natural) is
    begin
      if n > 0 then
        for i in 1 to n loop
          wait_clk(spd);
        end loop;
      end if;
    end procedure wait_clk;

  begin

    prng.rand_seed(123, 456);

    -- reset
    rst      <= '1';
    i_xspd   <= '0';
    i_crs_dv <= '0';
    i_er     <= '0';
    i_d      <= "00";
    wait_clk('1');
    rst <= '0';
    wait_clk('1', 64);

    -- generate frames and IPGs until done
    loop

      -- preamble and frame
      spd := prng.rand_bit;
      crs_len := prng.rand_int(CRS_LEN_MIN, CRS_LEN_MAX);
      pre_len := prng.rand_int(PRE_LEN_MIN, PRE_LEN_MAX);
      if prng.rand_real < PROB_PRE_LEN_BAD then
        if pre_len mod 4 = 3 then
          pre_len := pre_len - 1 when pre_len > PRE_LEN_MIN else pre_len + 1;
        end if;
      else
        pre_len := ((pre_len / 4) * 4) + 3;
      end if;
      pre_er  := prng.rand_real < PROB_PRE_ERROR;
      pre_bad := prng.rand_real < PROB_PRE_DATA_BAD;
      pre_abt := prng.rand_real < PROB_PRE_ABORT;
      frm_len := prng.rand_int(FRM_LEN_MIN, FRM_LEN_MAX);
      frm_er  := prng.rand_real < PROB_FRM_ERROR;
      crl_len := maximum(0, prng.rand_int(CRL_LEN_MIN, frm_len - 2));
      xspd := 'X' when
        ((pre_len + 1) mod 4) /= 0 or -- preamble + SFD not a multiple of 4 di-bits (octets)
        pre_er or                     -- error in preamble
        pre_bad or                    -- bad data in preamble
        pre_abt                       -- preamble abort before SFD
        else '1' when spd else '0';   -- OK
      report
            " spd = " & bit'image(spd) &
        " crs_len = " & integer'image(crs_len) &
        " pre_len = " & integer'image(pre_len) &
         " pre_er = " & boolean'image(pre_er) &
        " pre_bad = " & boolean'image(pre_bad) &
        " pre_abt = " & boolean'image(pre_abt) &
        " frm_len = " & integer'image(frm_len) &
         " frm_er = " & boolean'image(frm_er) &
        " crl_len = " & integer'image(crl_len) &
          "  xspd = " & std_ulogic'image(xspd)
        severity note;
      -- delay from CRS to preamble
      i_crs_dv <= '1';
      wait_clk(spd, crs_len);
      -- preamble
      i_xspd <= xspd;
      re := prng.rand_int(0, maximum(0, pre_len - 1));
      rx := prng.rand_int(0, maximum(0, pre_len - 1));
      for i in 0 to pre_len - 1 loop
        i_er <= '1'  when pre_er  and i = re else '0';
        if pre_bad and i = rx then
          case prng.rand_int(1, 3) is
            when 1      => i_d <= "00";
            when 2      => i_d <= "10";
            when 3      => i_d <= "11";
            when others => i_d <= "XX";
          end case;
        else
          i_d <= "01";
        end if;
        wait_clk(spd);
      end loop;
      if not pre_abt then
        -- SFD
        i_d <= "11";
        wait_clk(spd);
        -- frame
        re := prng.rand_int(0, maximum(0, frm_len - 1));
        rx := prng.rand_int(0, maximum(0, frm_len - 1));
        for i in 0 to frm_len - 1 loop
          i_crs_dv <= '0'  when (i >= frm_len - crl_len - 1) and ((i mod 2) = 0) else '1'; -- toggle crs_dv as required
          i_er     <= '1'  when frm_er  and i = re else '0';
          i_d      <= prng.rand_slv(0, 3, 2);
          wait_clk(spd);
        end loop;
      end if;
      -- IPG
      i_crs_dv <= '0';
      i_er     <= '0';
      i_d      <= "00";
      wait_clk(spd, prng.rand_int(IPG_LEN_MIN, IPG_LEN_MAX));

    end loop;

  end process P_STIM;

  --------------------------------------------------------------------------------
  -- shift register to delay stimulus and expected result to align with DUT output

  P_SR: process(clk)
  begin
    if rising_edge(clk) then
      sr(sr'left) <= (
        spd    => i_xspd,
        crs_dv => i_crs_dv,
        er     => i_er,
        d      => i_d
      );
      sr(sr'left + 1 to sr'right) <= sr(sr'left to sr'right - 1);
    end if;
  end process P_SR;

  --------------------------------------------------------------------------------
  -- compare SR and DUT outputs
  -- note that DUT spd output is valid 1 cycle before other outputs

  P_COMP: process(clk)
  begin
    if rising_edge(clk) and rst = '0' then
      if sr(sr'right - 1).spd /= 'X' then
        assert sr(sr'right - 1).spd = spd
          report "spd: expected " & to_string(sr(sr'right - 1).spd) & " got " & to_string(spd) severity failure;
      end if;
      assert sr(sr'right).crs_dv = o_crs_dv
        report "crs_dv: expected " & to_string(sr(sr'right - 0).crs_dv) & " got " & to_string(o_crs_dv) severity failure;
      assert sr(sr'right).er = o_er
        report "er: expected " & to_string(sr(sr'right - 0).er) & " got " & to_string(o_er) severity failure;
      assert sr(sr'right).d = o_d
        report "d: expected " & to_string(sr(sr'right - 0).d) & " got " & to_string(o_d) severity failure;
    end if;
  end process P_COMP;

  --------------------------------------------------------------------------------
  -- DUT instance

  DUT: component memac_rmii_rx_spd
    port map (
      rst      => rst,
      clk      => clk,
      i_crs_dv => i_crs_dv,
      i_er     => i_er,
      i_d      => i_d,
      o_crs_dv => o_crs_dv,
      o_er     => o_er,
      o_d      => o_d,
      spd      => spd
    );

end architecture sim;

--------------------------------------------------------------------------------
-- configurations

configuration cfg_tb_memac_rmii_rx_spd_behavioural of tb_memac_rmii_rx_spd is
  for sim
    for DUT: memac_rmii_rx_spd
      use entity memac.memac_rmii_rx_spd(rtl);
    end for;
  end for;
end configuration cfg_tb_memac_rmii_rx_spd_behavioural;

library memac_psf;

configuration cfg_tb_memac_rmii_rx_spd_post_syn_func of tb_memac_rmii_rx_spd is
  for sim
    for DUT: memac_rmii_rx_spd
      use entity memac_psf.memac_rmii_rx_spd(STRUCTURE);
    end for;
  end for;
end configuration cfg_tb_memac_rmii_rx_spd_post_syn_func;


--------------------------------------------------------------------------------