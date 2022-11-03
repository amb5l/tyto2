--------------------------------------------------------------------------------
-- mig_hub.vhd                                                                --
-- Shared access to MIG (DDR3 IP core) user interface.                        --
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
  use work.global_pkg.all;

package mig_hub_pkg is

  component mig_hub is
    generic (
      ports       : integer
    );
    port (

      clk         : in    std_logic;
      rst         : in    std_logic;

      hub_awvalid : in    std_logic_vector(0 to ports-1);
      hub_awready : out   std_logic_vector(0 to ports-1);
      hub_r_w     : in    std_logic_vector(0 to ports-1);
      hub_addr    : in    mig_addr_t(0 to ports-1);
      hub_wdata   : in    mig_data_t(0 to ports-1);
      hub_wbe     : in    mig_be_t(0 to ports-1);
      hub_rdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
      hub_rvalid  : out   std_logic_vector(0 to ports-1);

      mig_avalid  : out   std_logic;
      mig_r_w     : out   std_logic;
      mig_addr    : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
      mig_aready  : in    std_logic;
      mig_wvalid  : out   std_logic;
      mig_wdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
      mig_wbe     : out   std_logic_vector(2**data_width_log2-1 downto 0);
      mig_wready  : in    std_logic;
      mig_rdata   : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
      mig_rvalid  : in    std_logic

    );
  end component mig_hub;

end package mig_hub_pkg;

----------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library work;
  use work.global_pkg.all;
  use work.mig_hub_pkg.all;

library xpm;
  use xpm.vcomponents.all;

entity mig_hub is
  generic (
    ports       : integer := 1
  );
  port (

    clk         : in    std_logic;
    rst         : in    std_logic;

    hub_awvalid : in    std_logic_vector(0 to ports-1);
    hub_awready : out   std_logic_vector(0 to ports-1);
    hub_r_w     : in    std_logic_vector(0 to ports-1);
    hub_addr    : in    mig_addr_t(0 to ports-1);
    hub_wdata   : in    mig_data_t(0 to ports-1);
    hub_wbe     : in    mig_be_t(0 to ports-1);
    hub_rdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    hub_rvalid  : out   std_logic_vector(0 to ports-1);

    mig_avalid  : out   std_logic;
    mig_r_w     : out   std_logic;
    mig_addr    : out   std_logic_vector(addr_width_log2+data_width_log2-1 downto data_width_log2);
    mig_aready  : in    std_logic;
    mig_wvalid  : out   std_logic;
    mig_wdata   : out   std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    mig_wbe     : out   std_logic_vector(2**data_width_log2-1 downto 0);
    mig_wready  : in    std_logic;
    mig_rdata   : in    std_logic_vector(2**(data_width_log2+3)-1 downto 0);
    mig_rvalid  : in    std_logic

  );
end entity mig_hub;

architecture synth of mig_hub is

  constant timeout        : integer   := 16;
  constant tag_depth_log2 : integer   := 6;

  constant tag_width      : integer   := integer(ceil(log2(real(ports))));
  constant tag_depth      : integer   := 2**tag_depth_log2;
  constant tag_cwidth     : integer   := 1+tag_depth_log2;

  signal   timer          : integer range 0 to timeout-1;
  signal   master         : integer range 0 to ports-1;
  signal   master_prev    : integer range 0 to ports-1;

  signal   tag            : std_logic_vector(tag_width-1 downto 0);
  signal   tag_aff        : std_logic;
  signal   tag_overflow   : std_logic;
  signal   tag_underflow  : std_logic;

begin

  -- priority arbiter
  ARBITER: process (hub_awvalid, hub_r_w, hub_addr, hub_wdata, hub_wbe, mig_aready, mig_wready, tag_aff) is
  begin
    mig_avalid  <= '0';
    mig_r_w     <= '0';
    mig_wvalid  <= '0';
    hub_awready <= (others => '0');
    for i in 0 to ports-1 loop
      if hub_awvalid(i) = '1' and mig_aready = '1' and (mig_wready = '1' or (hub_r_w(i) = '1' and tag_aff = '0')) then -- demand that MIG can accept
        mig_avalid  <= '1';
        mig_r_w     <= hub_r_w(i);
        mig_addr    <= hub_addr(i);
        mig_wvalid  <= not hub_r_w(i);
        mig_wdata   <= hub_wdata(i);
        mig_wbe     <= hub_wbe(i);
        hub_awready <= (i => '1', others => '0');
        exit;
      end if;
    end loop;
  end process ARBITER;

  -- read data path
  hub_rdata <= mig_rdata;

  DO_RVALID: process (mig_rvalid, tag) is
    variable i : integer range 0 to 2**tag_width-1;
  begin
    hub_rvalid <= (others => '0');
    if mig_rvalid = '1' then
      i := to_integer(unsigned(tag));
      if i < ports then
        hub_rvalid(i) <= '1';
      end if;
    end if;
  end process DO_RVALID;

  TAG_FIFO: component xpm_fifo_sync
    generic map (
      dout_reset_value    => "0",
      ecc_mode            => "no_ecc",
      fifo_memory_type    => "distributed",
      fifo_read_latency   => 0,
      fifo_write_depth    => tag_depth,
      full_reset_value    => 0,
      prog_empty_thresh   => 5,
      prog_full_thresh    => tag_depth-5,
      rd_data_count_width => tag_cwidth,
      read_data_width     => tag_width,
      read_mode           => "fwft",
      sim_assert_chk      => 0,      -- disable simulation messages
      use_adv_features    => "0103", -- underflow, prog_full, overflow
      wakeup_time         => 0,      -- disable sleep
      write_data_width    => tag_width,
      wr_data_count_width => tag_cwidth
    )
    port map (
      almost_empty        => open,
      almost_full         => open,
      data_valid          => open,
      dbiterr             => open,
      dout                => tag,
      empty               => open,
      full                => open,
      overflow            => tag_overflow,
      prog_empty          => open,
      prog_full           => tag_aff,
      rd_data_count       => open,
      rd_rst_busy         => open,
      sbiterr             => open,
      underflow           => tag_underflow,
      wr_ack              => open,
      wr_data_count       => open,
      wr_rst_busy         => open,
      din                 => std_logic_vector(to_unsigned(master,tag_width)),
      injectdbiterr       => '0',
      injectsbiterr       => '0',
      rd_en               => mig_rvalid,
      rst                 => rst,
      sleep               => '0',
      wr_clk              => clk,
      wr_en               => mig_aready and mig_avalid and mig_r_w
    );

end architecture synth;

