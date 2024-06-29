-- based on XAPP209
--------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package crc_eth_pkg is

  component crc_eth is
    port (
      rst   : in    std_ulogic;
      clk   : in    std_ulogic;
      clken : in    std_ulogic;
      init  : in    std_ulogic;
      en    : in    std_ulogic;
      dv    : in    std_ulogic;
      d     : in    std_ulogic_vector(7 downto 0);
      q     : out   std_ulogic_vector(7 downto 0)
    );
  end component crc_eth;

end package crc_eth_pkg;

--------------------------------------------------------------------------------

use work.crc32_eth_8_pkg.all;

library ieee;
  use ieee.std_logic_1164.all;

entity crc_eth is
  port (
    rst   : in    std_ulogic;
    clk   : in    std_ulogic;
    clken : in    std_ulogic;
    init  : in    std_ulogic;
    en    : in    std_ulogic;
    dv    : in    std_ulogic;
    d     : in    std_ulogic_vector(7 downto 0);
    q     : out   std_ulogic_vector(7 downto 0)
  );
end entity crc_eth;

architecture rtl of crc_eth is

  signal crc32n : std_ulogic_vector(31 downto 0);
  signal crc32  : std_ulogic_vector(31 downto 0);

  function rev(i : std_ulogic_vector) return std_ulogic_vector is
    variable o : std_ulogic_vector(i'reverse_range);
  begin
    for n in i'range loop
      o(n) := i(n);
    end loop;
    return o;
  end function rev;

begin

  crc32n <= crc32_eth_8(rev(d),crc32);

  P_MAIN: process(rst,clk)
  begin
    if rst = '1' then
      crc32 <= (others => '1');
      q     <= (others => 'X');
    elsif rising_edge(clk) and clken = '1' then
      if init or en then
        crc32 <=
          x"FFFFFFFF" when init = '1' else
          crc32n      when dv = '1' and en = '1' else
          crc32(23 downto 0) & x"FF";
      end if;
      if en then
        if dv = '1' then
          q <= not(rev(crc32n(31 downto 24)));
        else
          q <= not(rev(crc32(23 downto 16)));
        end if;
      end if;
    end if;
  end process P_MAIN;

end architecture rtl;
