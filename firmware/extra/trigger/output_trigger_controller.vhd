-- Controller of the output begin-of-cycle trigger

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.system_package.all;

entity output_trigger_controller is
port (
    clk                : in  std_logic;                     -- input 40-MHz external clock
    trigger_in         : in  std_logic;                     -- input trigger
    trig_type_sel_a    : in  std_logic;                     -- input type select
    trig_type_sel_b    : in  std_logic;                     -- input type select
    trig_out_disable_a : in  std_logic_vector(31 downto 0); -- input laser output trigger disable
    trig_out_disable_b : in  std_logic_vector(31 downto 0); -- input auxilary output trigger disable
    var_width_short_a  : in  std_logic_vector( 7 downto 0); -- input laser short pulse width
    var_width_short_b  : in  std_logic_vector( 7 downto 0); -- input auxilary long pulse width
    var_width_long_a   : in  std_logic_vector( 7 downto 0); -- input laser short pulse width
    var_width_long_b   : in  std_logic_vector( 7 downto 0); -- input auxilary long pulse width
    trigger_delay_a    : in  array_32x32bit;                -- input delays, to laser system
    trigger_delay_b    : in  array_32x32bit;                -- input delay, to auxilary systems
    trigger_out_a      : out std_logic;                     -- output trigger, to laser system
    trigger_out_b      : out std_logic                      -- output trigger, to auxilary systems
);
end entity output_trigger_controller;

architecture Behavioral of output_trigger_controller is

    signal trigger_in_sync       : std_logic;
    signal trigger_disable_a     : std_logic;
    signal trigger_disable_b     : std_logic;
    signal trigger_delay_a_sel   : std_logic_vector(31 downto 0);
    signal trigger_delay_b_sel   : std_logic_vector(31 downto 0);
    signal trigger_in_delay_a    : std_logic;
    signal trigger_in_delay_b    : std_logic;
    signal trig_type_sel_delay_a : std_logic;
    signal trig_type_sel_delay_b : std_logic;
    signal counter_a             : std_logic_vector( 7 downto 0);
    signal counter_b             : std_logic_vector( 7 downto 0);

begin

    trigger_in_sync     <= trigger_in;
    trigger_disable_a   <= trig_out_disable_a( to_integer(unsigned(trigger_type)) );
    trigger_disable_b   <= trig_out_disable_b( to_integer(unsigned(trigger_type)) );
    trigger_delay_a_sel <= trigger_delay_a( to_integer(unsigned(trigger_type)) );
    trigger_delay_b_sel <= trigger_delay_b( to_integer(unsigned(trigger_type)) );

    -- delay output triggers
    trigger_in_delay_a_inst: entity work.pulse_delay
    port map (
        clock     => clk,                 -- run off the input clock
        delay     => trigger_delay_a_sel, -- delay set via IPbus register
        pulse_in  => trigger_in_sync,     -- trigger encoded in TTC
        pulse_out => trigger_in_delay_a   -- delayed trigger to front panel
    );

    trigger_in_delay_b_inst: entity work.pulse_delay
    port map (
        clock     => clk,                 -- run off the input clock
        delay     => trigger_delay_b_sel, -- delay set via IPbus register
        pulse_in  => trigger_in_sync,     -- trigger encoded in TTC
        pulse_out => trigger_in_delay_b   -- delayed trigger to front panel
    );

    -- delay output trigger type, for laser system spec
    trig_type_sel_a_delay_inst: entity work.pulse_delay
    port map (
        clock     => clk,                  -- run off the input clock
        delay     => trigger_delay_a_sel,  -- delay set via IPbus register
        pulse_in  => trig_type_sel_a,      -- trigger type select for laser system
        pulse_out => trig_type_sel_delay_a -- delayed trigger type select
    );

    -- delay output trigger type, for auxilary system spec
    trig_type_sel_b_delay_inst: entity work.pulse_delay
    port map (
        clock     => clk,                  -- run off the input clock
        delay     => trigger_delay_b_sel,  -- delay set via IPbus register
        pulse_in  => trig_type_sel_b,      -- trigger type select for auxilary system
        pulse_out => trig_type_sel_delay_b -- delayed trigger type select
    );

    -- Channel A
    process(clk)
    begin
        if rising_edge(clk) then
            -- trigger arrived
            if trigger_in_delay_a = '1' and trigger_disable_a = '0' then
                if trig_type_sel_delay_a = '1' then
                    counter_a <= var_width_long_a;
                else
                    counter_a <= var_width_short_a;
                end if;
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
                if trig_type_sel_delay_b = '1' then
                    counter_b <= var_width_long_b;
                else
                    counter_b <= var_width_short_b;
                end if;
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
