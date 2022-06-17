library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ttc_chan_b_data_mux is
port (
    clk       : in std_logic;
    b_channel : in std_logic_vector(7 downto 0);
    TTC_data  : out std_logic_vector(15 downto 0)
);
end ttc_chan_b_data_mux;

architecture Behavioral of ttc_chan_b_data_mux is

    signal hmg : std_logic_vector(4 downto 0);
    signal d   : std_logic_vector(7 downto 0);

begin

process(clk)
begin
    if rising_edge(clk) then
        TTC_data(15 downto 14) <= "00";                  -- two start bits
        TTC_data(13 downto 6)  <= b_channel(7 downto 0); -- six bit command

        d(7 downto 0) <= b_channel(7 downto 2) & b_channel(1 downto 0);

        hmg(0) <= d(0) xor d(1) xor d(2) xor d(3);
        hmg(1) <= d(0) xor d(4) xor d(5) xor d(6);
        hmg(2) <= d(1) xor d(2) xor d(4) xor d(5) xor d(7);
        hmg(3) <= d(1) xor d(3) xor d(4) xor d(6) xor d(7);
        hmg(4) <= d(0) xor d(2) xor d(3) xor d(5) xor d(6) xor d(7);

        TTC_data(5 downto 1) <= hmg(4 downto 0); -- five-bit hamming code
        TTC_data(0 downto 0) <= "1";             -- one stop bits
    end if;
end process;

end Behavioral;
