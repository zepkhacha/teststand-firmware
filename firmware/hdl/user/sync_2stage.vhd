-- Classic 2-stage synchronizer to bring asynchronous signals into a clock domain
-- for a signal of width 'nbr_bits' which defaults to 1

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sync_2stage is
generic (
    nbr_bits : positive := 1
);
port (
    clk   : in  std_logic;
    sig_i : in  std_logic_vector(nbr_bits-1 downto 0);
    sig_o : out std_logic_vector(nbr_bits-1 downto 0)
);
end entity sync_2stage;

architecture Behavioral of sync_2stage is

    signal sync1 : std_logic_vector(nbr_bits-1 downto 0);
    signal sync2 : std_logic_vector(nbr_bits-1 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            sync1 <= sig_i;
            sync2 <= sync1;
        end if;
    end process;

    sig_o <= sync2;

end architecture Behavioral;
