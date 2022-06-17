-- Generate 16-bit TTC Channel B broadcast data from 8-bit command

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ttc_chan_b_data_mux is
port (
    clk       : in     std_logic;
    b_channel : in     std_logic_vector( 7 downto 0);
    ttc_data  : buffer std_logic_vector(15 downto 0)
);
end ttc_chan_b_data_mux;

architecture Behavioral of ttc_chan_b_data_mux is

    -- attribute mark_debug : string;
    -- attribute mark_debug of b_channel : signal is "true";
    -- attribute mark_debug of ttc_data  : signal is "true";

begin

process(clk)
begin
    if rising_edge(clk) then
        ttc_data(15 downto 14) <= "00";                  -- two start bits
        ttc_data(13 downto  6) <= b_channel(7 downto 0); -- six bit command

        -- hamming encoding calculation
        ttc_data(5) <= b_channel(0) xor b_channel(2) xor b_channel(3) xor b_channel(5) xor b_channel(6) xor b_channel(7);
        ttc_data(4) <= b_channel(1) xor b_channel(3) xor b_channel(4) xor b_channel(6) xor b_channel(7);
        ttc_data(3) <= b_channel(1) xor b_channel(2) xor b_channel(4) xor b_channel(5) xor b_channel(7);
        ttc_data(2) <= b_channel(0) xor b_channel(4) xor b_channel(5) xor b_channel(6);
        ttc_data(1) <= b_channel(0) xor b_channel(1) xor b_channel(2) xor b_channel(3);

        ttc_data(0) <= '1'; -- one stop bit
    end if;
end process;

end Behavioral;
