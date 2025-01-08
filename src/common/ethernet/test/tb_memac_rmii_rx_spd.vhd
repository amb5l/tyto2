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
-- type for queue package instance

library ieee;
  use ieee.std_logic_1164.all;

package tb_memac_rmii_types_pkg is

  type xrmii_t is record
    crs_dv : std_ulogic;
    er     : std_ulogic;
    d      : std_ulogic_vector(1 downto 0);
  end record xrmii_t;

  constant XRMII_U : xrmii_t := (d => "UU", others => 'U');

end package tb_memac_rmii_types_pkg;

--------------------------------------------------------------------------------
-- queue package instances

use work.tb_memac_rmii_types_pkg.all;
library memac;
package tb_memac_rmii_rx_spd_queue_xrmii_pkg is
  new memac.memac_sim_queue_pkg generic map(queue_item_t => xrmii_t, empty => XRMII_U);

library memac;
library ieee;
  use ieee.std_logic_1164.all;
package tb_memac_rmii_rx_spd_queue_xspd_pkg is
  new memac.memac_sim_queue_pkg generic map(queue_item_t => std_ulogic, empty => 'U');

--------------------------------------------------------------------------------

use work.tb_memac_rmii_types_pkg.all;

library memac;
  use memac.memac_sim_pkg.all;
  use memac.memac_rmii_rx_spd_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_memac_rmii_rx_spd is
end entity tb_memac_rmii_rx_spd;

architecture sim of tb_memac_rmii_rx_spd is

  constant CLK_PERIOD : time := 20 ns;

  constant RST_LEN_MIN  : integer := 1;
  constant RST_LEN_MAX  : integer := 2;
  constant RST_DLY_MIN  : integer := 0;
  constant RST_DLY_MAX  : integer := 2;
  constant CRS_LEN_MIN  : integer := 0;
  constant CRS_LEN_MAX  : integer := 2;
  constant PRE_LEN_LIST : integer_vector := (
    1, 2, 3, 4, 5, 6, 7, 8, 9, 27, 28, 29, 63, 64, 65 -- 28 = 7 octets * 4 dibits per octet
  );
  constant FRM_LEN_LIST: integer_vector := (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 16
  );
  constant IPG_LEN_LIST: integer_vector := (
    2, 3, 4, 5, 8, 16, 47, 48, 49 -- 48 = 12 octets * 4 dibits per octet
  );
  constant PRE_LEN_MAX : integer := maximum(PRE_LEN_LIST);
  constant SFD_LEN     : integer := 1;
  constant FRM_LEN_MAX : integer := maximum(FRM_LEN_LIST);
  constant IPG_LEN_MAX : integer := maximum(IPG_LEN_LIST);
  constant HOLD_MIN    : integer := 0;
  constant HOLD_MAX    : integer := 2;
  constant REPS        : integer := 2; -- number of frames to generate per test

  constant INTERVAL_FIRST: time := CLK_PERIOD * ( -- crs_dv rising to rising (1st to next frame)
    FRM_LEN_MAX +
    IPG_LEN_MAX +
    CRS_LEN_MAX +
    PRE_LEN_MAX +
    SFD_LEN
  );
  constant INTERVAL_LAST: time := CLK_PERIOD * ( -- crs_dv rising to rising (last to 1st frame)
    FRM_LEN_MAX +
    HOLD_MAX +
    RST_LEN_MAX +
    RST_DLY_MAX +
    CRS_LEN_MAX +
    PRE_LEN_MAX +
    SFD_LEN
  );

  -- DUT ports
  signal rst      : std_ulogic;
  signal clk      : std_ulogic;
  signal i_crs_dv : std_ulogic;
  signal i_er     : std_ulogic;
  signal i_d      : std_ulogic_vector(1 downto 0);
  signal o_crs_dv : std_ulogic;
  signal o_er     : std_ulogic;
  signal o_d      : std_ulogic_vector(1 downto 0);
  signal o_rdy    : std_ulogic;
  signal o_stb    : std_ulogic;
  signal o_spd    : std_ulogic;
  signal o_err    : std_ulogic;

  -- queues
  shared variable xrmii : work.tb_memac_rmii_rx_spd_queue_xrmii_pkg.queue_t; -- expected RMII state
  shared variable xspd  : work.tb_memac_rmii_rx_spd_queue_xspd_pkg.queue_t;  -- expected speed state

begin

  clk <= '0' when clk = 'U' else not clk after CLK_PERIOD/2; -- 50 MHz

  --------------------------------------------------------------------------------
  -- stimulate DUT inputs

  P_MAIN: process

    variable prng    : prng_t;
    variable pre_len : positive;
    variable frm_len : natural;
    variable crl_len : natural;
    variable ipg_len : positive;

    procedure do_test(
      spd     : natural;  -- speed (0 = 10 Mbps, 1 = 100 Mbps)
      rst_len : positive; -- reset duration
      rst_dly : natural;  -- delay from reset negation to crs_dv assertion
      crs_len : natural;  -- duration of crs_dv assertion before preamble
      pre_len : positive; -- length of preamble
      frm_len : natural;  -- length of frame
      crl_len : natural;  -- duration of carrier loss before end of frame
      pre_tst : natural;  -- 0 = good, 1 = random error assertion, 2 = random corrupt di-bits, 3 = both
      frm_tst : natural;  -- 0 = good, 1 = random error assertion, 2 = random corrupt di-bits, 3 = both
      ipg_len : positive; -- inter packet gap (between end of frame and next preamble)
      hold    : natural;  -- hold time after last frame
      reps    : positive  -- number of frames to generate
    ) is

      procedure wait_clk is
        variable c : positive;
      begin
        c := 10 when spd = 0 else 1;
        for i in 10 to c loop
          wait until rising_edge(clk);
        end loop;
      end procedure wait_clk;

      procedure wait_clk(n : natural) is
      begin
        if n > 0 then
          for i in 1 to n loop
            wait_clk;
          end loop;
        end if;
      end procedure wait_clk;

      procedure wait_clk_enq is
      begin
        wait_clk;
        xrmii.enq(xrmii_t'(crs_dv => i_crs_dv, er => i_er, d => i_d)); -- v4p ignore e-202 (TODO remove ignore when V4P issue is resolved)
      end procedure wait_clk_enq;

      procedure wait_clk_enq(n : natural) is
      begin
        if n > 0 then
          for i in 1 to n loop
            wait_clk_enq;
          end loop;
        end if;
      end procedure wait_clk_enq;

      variable re : natural;                       -- random error position
      variable rx : natural;                       -- random data corruption position
      variable d  : std_ulogic_vector(1 downto 0); -- data
      variable s  : std_ulogic;                    -- speed

    begin
      report
            " spd = " & integer'image(spd) &
        " rst_len = " & integer'image(rst_len) &
        " rst_dly = " & integer'image(rst_dly) &
        " crs_len = " & integer'image(crs_len) &
        " pre_len = " & integer'image(pre_len) &
        " frm_len = " & integer'image(frm_len) &
        " crl_len = " & integer'image(crl_len) &
        " pre_tst = " & integer'image(pre_tst) &
        " frm_tst = " & integer'image(frm_tst) &
        " ipg_len = " & integer'image(ipg_len) &
           " hold = " & integer'image(hold) &
           " reps = " & integer'image(reps)
        severity note;
      -- reset assertion
      rst      <= '1';
      i_crs_dv <= 'X';
      i_er     <= 'X';
      i_d      <= "XX";
      wait_clk(rst_len);
      -- delay from reset to first crs_dv assertion
      rst <= '0';
      i_crs_dv <= '0';
      i_er     <= '0';
      i_d      <= "00";
      wait_clk_enq(rst_dly);
      for rep in 1 to reps loop
        -- delay from CRS to preamble
        i_crs_dv <= '1';
        wait_clk_enq(crs_len);
        -- preamble
        re := prng.rand_int(0, maximum(0, frm_len - 1));
        rx := prng.rand_int(0, maximum(0, frm_len - 1));
        for i in 0 to pre_len - 1 loop
          i_er <= '1'  when i = re and (pre_tst = 1 or pre_tst = 3) else '0';
          i_d  <= "XX" when i = rx and (pre_tst = 2 or pre_tst = 3) else "01";
          wait_clk_enq(1);
        end loop;
        -- SFD
        i_d <= "11";
        wait_clk_enq(SFD_LEN);
        -- enqueue speed
        s :=
          '0' when pre_tst = 0 and spd = 0 else
          '1' when pre_tst = 0 and spd = 1 else
          'L' when o_spd = '0' else
          'H' when o_spd = '1' else
          'X';
        report "enqueue speed: " & std_ulogic'image(s) severity note;
        xspd.enq(s);
        -- frame
        re := prng.rand_int(0, maximum(0, frm_len - 1));
        rx := prng.rand_int(0, maximum(0, frm_len - 1));
        for i in 0 to frm_len - 1 loop
          d  := std_ulogic_vector(to_unsigned(i mod 4, 2));                          -- incrementing data
          i_crs_dv <= '0'  when i >= frm_len - crl_len - 1 and i mod 2 = 0 else '1'; -- toggle crs_dv as required
          i_er     <= '1'  when i = re and (pre_tst = 1 or pre_tst = 3) else '0';
          i_d      <= "XX" when i = rx and (pre_tst = 2 or pre_tst = 3) else d;
          wait_clk_enq(1);
        end loop;
        -- after frame
        i_crs_dv <= '0';
        i_er     <= '0';
        i_d      <= "00";
        if rep < reps then -- inter packet gap
          wait_clk_enq(ipg_len);
        else -- hold
          wait_clk_enq(hold);
        end if;
      end loop;
      -- wait for all RMII states to ripple through queue
      while xrmii.items > 0 loop
        wait until rising_edge(clk);
      end loop;
    end procedure do_test;

  begin

    prng.rand_seed(123, 456); -- seed PRNG
    xrmii.reset;
    xspd.reset;

    -- present DUT with permutations of startup (post reset) and
    -- inter frame conditions, queuing expected results
    LOOP_RST_LEN: for rst_len in RST_LEN_MIN to RST_LEN_MAX loop                        -- length of rst
      LOOP_RST_DLY: for rst_dly in RST_DLY_MIN to RST_DLY_MAX loop                      -- delay from rst deassertion to activity
        LOOP_CRS_LEN: for crs_len in CRS_LEN_MIN to CRS_LEN_MAX loop                    -- delay from crs_dv assertion to preamble
          LOOP_PRE_LEN: for pre_idx in 0 to PRE_LEN_LIST'length-1 loop   -- length of preamble
            pre_len := PRE_LEN_LIST(pre_idx);
            LOOP_FRM_LEN: for frm_idx in 0 to FRM_LEN_LIST'length-1 loop -- length of frame
              frm_len := FRM_LEN_LIST(frm_idx);
              LOOP_IPG_LEN: for ipg_idx in 0 to IPG_LEN_LIST'length-1 loop
                ipg_len := IPG_LEN_LIST(ipg_idx);
                LOOP_HOLD: for hold in HOLD_MIN to HOLD_MAX loop
                  crl_len := 0;
                  LOOP_CRL_LEN: loop
                    LOOP_PRE_TEST: for pre_test in 0 to 3 loop
                      LOOP_FRM_TEST: for frm_test in 0 to 3 loop
                        LOOP_SPD: for spd in 0 to 1 loop
                          do_test(1-spd, rst_len, rst_dly, crs_len, pre_len, frm_len, crl_len, pre_test, frm_test, ipg_len, hold, REPS);
                        end loop LOOP_SPD;
                      end loop LOOP_FRM_TEST;
                    end loop LOOP_PRE_TEST;
                    crl_len := crl_len + 1;
                    if frm_len - crl_len  < 2 then -- 1st 2 dibits must have CRS
                      exit;
                    end if;
                  end loop LOOP_CRL_LEN;
                end loop LOOP_HOLD;
              end loop LOOP_IPG_LEN;
            end loop LOOP_FRM_LEN;
          end loop LOOP_PRE_LEN;
        end loop LOOP_CRS_LEN;
      end loop LOOP_RST_DLY;
    end loop LOOP_RST_LEN;

    wait;

  end process P_MAIN;

--------------------------------------------------------------------------------
  -- compare DUT output with expected results

  P_CHECK_RMII: process(rst, clk)
  begin
    if rst then
      null;
    elsif rising_edge(clk) then
      if o_crs_dv /= 'L' then -- DUT output is valid
        if o_crs_dv = 'U' and o_er = 'U' and o_d = "UU" then
          assert xrmii.items = 0 and xspd.items = 0
            report "expected queues not empty at end of simulation:" &
            " xrmii.items = " & integer'image(xrmii.items) &
            " xspd.items = " & integer'image(xspd.items)
            severity failure;
          report "END OF SIMUALTION" severity note;
          std.env.stop;
        end if;
        assert xrmii.items > 0
          report "no expected RMII state to compare with" severity failure;
        assert o_crs_dv = xrmii.front.crs_dv and
               o_er     = xrmii.front.er     and
               o_d      = xrmii.front.d
          report "unexpected RMII value:" &
          " got: "      &
            to_string(o_crs_dv) & " " &
            to_string(o_er) & " " &
            to_string(o_d) &
          " expected: " &
            to_string(xrmii.front.crs_dv) & " " &
            to_string(xrmii.front.er) & " " &
            to_string(xrmii.front.d)
          severity failure;
        xrmii.deq;
      end if;
    end if;
  end process P_CHECK_RMII;

  P_CHECK_SPD: process
  begin
    wait on o_crs_dv until
      rising_edge(o_crs_dv) and (
        o_crs_dv'last_event = 0 ns or         -- first event
        o_crs_dv'last_event >= CLK_PERIOD * 2 -- not carrier loss at end of frame
      ) for maximum(INTERVAL_FIRST, INTERVAL_LAST) + 100 ns;
    assert o_crs_dv'event
      report "crs_dv event timeout" severity failure;
    --wait on o_crs_dv, o_crs_er, o_crs_d for CLK_PERIOD * CRS_LEN_MAX;




    assert xspd.items > 0
      report "unexpected spd transaction" severity failure;
    assert xspd.front = o_spd
      report "unexpected spd value:" &
      " got " & std_ulogic'image(o_spd) &
      " expected " & std_ulogic'image(xspd.front)
      severity failure;
  end process P_CHECK_SPD;


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
      rdy      => o_rdy,
      stb      => o_stb,
      spd      => o_spd,
      err      => o_err
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