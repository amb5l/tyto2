entity hyperram is
  port (
    s_rst    : in    std_ulogic;
    s_clk_0  : in    std_ulogic;
    s_clk_90 : in    std_ulogic;
    s_

    h_rst    : out   std_ulogic;
    h_clk    : out   std_ulogic;
    h_cs_n   : out   std_ulogic;
    h_rwds   : out   std_ulogic;
    h_d      : inout std_ulogic_vector(7 downto 0)
  );
end entity hyperram;

architecture rtl of hyperram is

  type hyperram_params_t is record
    tCSHI : real;
    tRWR  : real;
    tACC  : real;
  end record hyperram_params_t;

  type state_t is (READY, CA1, CA2, CA3, ACC, RWR);

  constant hyperram_params_133 : hyperram_params_t := ( 7.5 , 37.5 , 375.0 );



  constant tCSHI_133 : real := 7.5;


  signal latency_count : integer range 0 to 7; -- corresponds to 1..8



begin


  process(s_rst,s_clk_0)
  begin
    if s_rst = '1' then

    elsif rising_edge(s_clk_0) then

      case state is

        when READY =>
        when CA1 =>
        when CA2 =>
        when CA3 =>
        when ACC => -- wait until enough of tACC



        when RWR => -- wait until enough of tRWR elapses before going back to READY
          if count = ? then
            count <= 0;
            state <= READY;
          else
            count <= count + 1;
          end if;



      end case;



    end if;
  end process;


  -- CS rise to 2nd falling clk edge = tRWR = 37.5 ns


  --------------------------------------------------------------------------------
  -- ODDR registers

  -- h_clk
  U_ODDR_CLK: component oddr
    generic map(
      ddr_clk_edge => "SAME_EDGE",
      init         => '0',
      srtype       => "ASYNC"
    )
    port map (
      r  => s_rst,
      s  => '0'
      c  => s_clk_90,
      ce => '1',
      d1 => h_clk_en,
      d2 => '0',
      q  => h_clk_u
    );
  U_OBUF_CLK: component obuf
    port map (
      i => h_clk_u,
      o => h_clk
    );

  -- h_cs_n (actually SDR)
  U_ODDR_CS: component oddr
    generic map(
      ddr_clk_edge => "SAME_EDGE",
      init         => '1',
      srtype       => "ASYNC"
    )
    port map (
      r  => s_rst,
      s  => '0'
      c  => s_clk_0,
      ce => '1',
      d1 => not h_cs_en,
      d2 => not h_cs_en,
      q  => h_cs_n_u
    );
  U_OBUF_CS: component obuf
    port map (
      i => h_cs_n_u,
      o => h_cs_n
    );


  -- h_rwds


  -- h_d
  GEN_ODDR_D: for i in 0 to 7 generate
    U_ODDR_D:

  end generate GEN_ODDR_D;


end architecture rtl;
