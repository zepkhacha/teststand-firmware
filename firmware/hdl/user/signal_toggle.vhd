library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity signal_toggle is
port (
    clk   : in  std_logic;
    sig_o : out std_logic
);
end signal_toggle;

architecture Behavioral of signal_toggle is

    signal counter : std_logic_vector(24 downto 0);
    signal toggle  : std_logic;

begin

    -- Make a counter to flash an LED
    process(clk)
    begin
        if rising_edge(clk) then
            counter <= counter + 1;

            if counter = std_logic_vector(to_unsigned(0, counter'length)) then
                toggle <= not toggle;
            end if;
        end if;
    end process;

    sig_o <= toggle;

end architecture Behavioral;
