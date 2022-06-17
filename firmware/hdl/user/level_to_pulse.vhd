-- Level-to-pulse converter

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity level_to_pulse is
port (
    clk   : in  std_logic;
    sig_i : in  std_logic;
    sig_o : out std_logic
);
end entity level_to_pulse;

architecture Behavioral of level_to_pulse is

    signal sync1 : std_logic;
    signal sync2 : std_logic;
    signal sync3 : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            sync1 <= sig_i;
            sync2 <= sync1;
            sync3 <= sync2;
        end if;
    end process;

    sig_o <= sync2 and not sync3;

end architecture Behavioral;
