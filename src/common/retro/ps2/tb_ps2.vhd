library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

library work;
use work.tyto_sim_pkg.all;

entity tb_ps2 is
end entity tb_ps2;

architecture sim of tb_ps2 is

    constant p : time := 32 us; -- PS/2 clock period (~30kHz)

    signal rst   : std_logic;
    signal sclk  : std_logic;
    signal sdata : std_logic;
    signal pdata : std_logic_vector(7 downto 0);
    signal tdata : std_logic_vector(7 downto 0);
    signal stb   : std_logic;
    signal ack   : std_logic;

begin

    stim_reset(rst, '1', 100 ns);

    process
        procedure ps2_tx_frame(
            signal   sclk    : out std_logic;
            signal   sdata   : out std_logic;
            constant pdata   : in std_logic_vector(7 downto 0);
            constant period  : in time;
            constant corrupt : in std_logic_vector(10 downto 0) := (others => '0')
        ) is
        begin
            -- start
            wait for period/2;
            sclk <= '0';
            sdata <= corrupt(0);
            wait for period/2;
            sclk <= '1';
            -- data
            for i in 0 to 7 loop
                wait for period/2;
                sclk <= '0';
                sdata <= pdata(i) xor corrupt(1+i);
                wait for period/2;
                sclk <= '1';
            end loop;
            -- parity
            wait for period/2;
            sclk <= '0';
            sdata <=
                pdata(0) xor pdata(1) xor pdata(2) xor pdata(3) xor
                pdata(4) xor pdata(5) xor pdata(6) xor pdata(7) xor
                corrupt(9);
            wait for period/2;
            sclk <= '1';
            -- stop
            wait for period/2;
            sclk <= '0';
            sdata <= not corrupt(10);
            wait for period/2;
            sclk <= '1';
            sdata <= '1'; 
        end procedure ps2_tx_frame;
    begin
        sclk <= '1';
        sdata <= '1';
        wait for p;
        for i in 0 to 255 loop
            ps2_tx_frame(sclk, sdata, std_logic_vector(to_unsigned(i,8)), p, "00000000000" );            
            tdata <= std_logic_vector(to_unsigned(i,8));
        end loop;
        wait;
    end process;

    process(rst,stb)
    begin
        if rst = '1' then
            ack <= '0';
        elsif rising_edge(stb) then
            ack <= '1' after 10 ns;
        end if;
        if falling_edge(stb) then
            if pdata /= tdata then
                report "difference!" severity FAILURE;
            end if;
            ack <= '0' after 10 ns;
        end if;
    end process;

    UUT: entity work.ps2
        port map (
            rst   => rst,
            sclk  => sclk,
            sdata => sdata,
            pdata => pdata,
            stb   => stb,
            ack   => ack
        );

end architecture sim;
