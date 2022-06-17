-- Controller of the output begin-of-cycle trigger

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.system_package.all;

entity boc_controller is
port (
    clk               : in  std_logic;                     -- input 40-MHz external clock
    trigger_in        : in  std_logic;                     -- input trigger
    trigger_disable_a : in  std_logic;                     -- input output trigger A disable
    trigger_disable_b : in  std_logic;                     -- input output trigger B disable
    var_width_a       : in  std_logic_vector( 7 downto 0); -- input output trigger A pulse width
    var_width_b       : in  std_logic_vector( 7 downto 0); -- input output trigger B pulse width
    trigger_delay_a   : in  std_logic_vector(31 downto 0); -- input output trigger A delay
    trigger_delay_b   : in  std_logic_vector(31 downto 0); -- input output trigger B delay
    trigger_out_a     : out std_logic;                     -- output trigger A
    trigger_out_b     : out std_logic                      -- output trigger B
);
end entity boc_controller;

architecture Behavioral of boc_controller is

    signal trigger_in_delay_a : std_logic;
    signal trigger_in_delay_b : std_logic;
    signal counter_a          : std_logic_vector(7 downto 0);
    signal counter_b          : std_logic_vector(7 downto 0);

begin

    -- delay output triggers
    trigger_in_delay_a_inst: entity work.pulse_delay
    port map (
        clock     => clk,               -- run off the input clock
        delay     => trigger_delay_a,   -- delay set via IPbus register
        pulse_in  => trigger_in,        -- trigger encoded in TTC
        pulse_out => trigger_in_delay_a -- delayed trigger to front panel
    );

    trigger_in_delay_b_inst: entity work.pulse_delay
    port map (
        clock     => clk,               -- run off the input clock
        delay     => trigger_delay_b,   -- delay set via IPbus register
        pulse_in  => trigger_in,        -- trigger encoded in TTC
        pulse_out => trigger_in_delay_b -- delayed trigger to front panel
    );

    -- Channel A
    process(clk)
    begin
        if rising_edge(clk) then
            -- trigger arrived
            if trigger_in_delay_a = '1' and trigger_disable_a = '0' then
                counter_a     <= var_width_a;
                trigger_out_a <= '1';

            -- stretching output trigger
            elsif counter_a > 0 then
                counter_a     <= counter_a - 1; -- decrement
                trigger_out_a <= '1';

            -- idle
            else
                counter_a     <= (others => '0');
                trigger_out_a <= '0';
            end if;
        end if;
    end process;

    -- Channel B
    process(clk)
    begin
        if rising_edge(clk) then
            -- trigger arrived
            if trigger_in_delay_b = '1' and trigger_disable_b = '0' then
                counter_b     <= var_width_b;
                trigger_out_b <= '1';

            -- stretching output trigger
            elsif counter_b > 0 then
                counter_b     <= counter_b - 1; -- decrement
                trigger_out_b <= '1';

            -- idle
            else
                counter_b     <= (others => '0');
                trigger_out_b <= '0';
            end if;
        end if;
    end process;

end architecture Behavioral;
