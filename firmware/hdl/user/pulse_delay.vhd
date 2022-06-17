-- Generic module to delay a 1-bit, 1-clock-wide pulse with a configurable delay;
-- Latches the 'delay' input upon 'pulse_in' assertion

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity pulse_delay is
generic (
    nbr_bits : positive := 32
);
port (
    clock     : in  std_logic;                             -- input clock
    delay     : in  std_logic_vector(nbr_bits-1 downto 0); -- input delay, in units of clock cycles
    pulse_in  : in  std_logic;                             -- input pulse
    pulse_out : out std_logic                              -- output pulse
);
end entity pulse_delay;

architecture Behavioral of pulse_delay is

    signal enable : std_logic;
    signal count  : std_logic_vector(nbr_bits-1 downto 0);

begin

    process(clock)
    begin
        if rising_edge(clock) then
            -- pulse received
            if pulse_in = '1' then
                pulse_out <= '0';
                enable    <= '1';
                count     <= delay; -- initialize count

            -- no pulse received
            else

                -- pulse was previously received
                if enable = '1' then

                    -- delay reached
                    if count = std_logic_vector(to_unsigned(0, count'length)) then
                        pulse_out <= '1'; -- send pulse
                        enable    <= '0';
                        count     <= (others => '0'); -- reset count

                    -- not ready yet, keep counting down
                    else
                        pulse_out <= '0';
                        enable    <= '1';
                        count     <= count - 1; -- decrement count
                    end if;

                -- idle
                else
                    pulse_out <= '0';
                    enable    <= '0';
                    count     <= (others => '0'); -- reset count
                end if;

            end if;
        end if;
    end process;

end architecture Behavioral;
