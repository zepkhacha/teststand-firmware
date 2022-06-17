-- This module generates clocks and reset signals that will be asserted when the chip is
-- initially configured. After some time, the reset signals will be negated
-- synchronously with the appropriate clock. A clock must be present to negate the output.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity startup_reset is
port (
    clk   : in  std_logic;
    reset : out std_logic;
    hold  : in  std_logic
);
end entity startup_reset;

architecture Behavioral of startup_reset is

    signal cnt          : std_logic_vector(19 downto 0) := x"00000";
    signal at_max       : std_logic;
    signal at_max_sync1 : std_logic;
    signal at_max_sync2 : std_logic;

begin

	-- Connect a counter that will count up once the chip comes out of reset, until it reaches its maximum value.
	-- At that time, disable counting. Use the output as a reset signal. This counter is clocked from the input pin.
	process(clk)
    begin
        if rising_edge(clk) then
            if at_max = '0' and hold = '0' then
            	cnt <= cnt + 1; -- only count after hold is removed
        	else
        		cnt <= cnt;
        	end if;
        end if;
    end process;

    at_max <= '1' when cnt = x"fffff" else '0';

    -- Make a synchronous 'reset' signal
	-- Pass the 'at_max' signal thru a two-stage synchronizer that is clocked by 'clk'
    process(clk)
    begin
        if rising_edge(clk) then
            at_max_sync1 <= at_max;
			at_max_sync2 <= at_max_sync1;
        end if;
    end process;

	-- Invert the synchronizer output so the 'reset' is asserted when the counter is not 'at_max'
    reset <= not at_max_sync2;

end architecture Behavioral;
