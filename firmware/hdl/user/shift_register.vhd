-- Generic shift register to delay a 1-bit signal with a configurable delay

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity shift_register is
generic (
    delay_width : positive := 8
);
port (
    clock    : in  std_logic;                                -- input clock
    delay    : in  std_logic_vector(delay_width-1 downto 0); -- input delay, in units of clock cycles
    data_in  : in  std_logic;                                -- input signal
    data_out : out std_logic                                 -- output signal
);
end entity shift_register;

architecture Behavioral of shift_register is

    signal shift_reg : std_logic_vector(2**delay_width-1 downto 0); -- shift register

begin

    process(clock)
    begin
        if rising_edge(clock) then
            shift_reg(2**delay_width-1 downto 1) <= shift_reg(2**delay_width-2 downto 0); -- bit-shift left by one
            shift_reg(0)                         <= data_in;                              -- put signal of interest in LSB
        end if;
    end process;

    data_out <= shift_reg(to_integer(unsigned(delay))); -- output the desired bit

end architecture Behavioral;
