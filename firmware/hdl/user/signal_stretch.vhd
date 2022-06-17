-- This module stretches the input signal so that it can later be synchronized into a slower clock domain
-- When the input signal is asserted, it will be kept high for 'n_cycles' additional clock cycles

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity signal_stretch is
generic (
    nbr_bits : positive := 8
);
port (
    clk      : in  std_logic;
    n_cycles : in  std_logic_vector(nbr_bits-1 downto 0);
    sig_i    : in  std_logic;
    sig_o    : out std_logic
);
end entity signal_stretch;

architecture Behavioral of signal_stretch is

    signal counter : std_logic_vector(nbr_bits-1 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if sig_i = '1' then
                counter <= n_cycles;
                sig_o   <= '1';
            elsif counter > 0 then
                counter <= counter-1;
                sig_o   <= '1';
            else
                counter <= (others => '0');
                sig_o   <= '0';
            end if;
        end if;
    end process;

end architecture Behavioral;
