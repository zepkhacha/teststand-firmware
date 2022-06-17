-- This module relays the input trigger signal, delayed by two input-clock cycles
-- and with a width of four input-clock cycles, for input into any module running
-- on the output-clock output

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity trigger_clock is
port (
    clk_in      : in  std_logic; -- input clock
    trigger_in  : in  std_logic;
    clk_out     : out std_logic; -- output clock, with half the input frequency
    trigger_out : out std_logic
);
end trigger_clock;

architecture Behavioral of trigger_clock is

    signal q1, q2, q3, q4, q5             : std_logic;
    signal q0_bar, q3_bar, q4_bar, q5_bar : std_logic;

begin

    -- trigger pass-through
    synced_clock: entity work.d_type
    port map (
        clk   => clk_in,
        d     => trigger_in or q0_bar,
		q     => clk_out,
		q_bar => q0_bar
    );

    trigger_sync: entity work.sync_2stage
    port map (
        clk      => clk_in,
        sig_i(0) => trigger_in and not q1,
		sig_o(0) => q1
    );

    wide_trigger_0: entity work.d_type
    port map (
        clk   => clk_in,
        d     => q1 and q3_bar,
        q     => q2,
        q_bar => open
    );

    wide_trigger_1: entity work.d_type
    port map (
        clk   => clk_in,
        d     => q2,
		q     => q3,
		q_bar => q3_bar
    );

    wide_trigger_2: entity work.d_type
    port map (
        clk   => clk_in,
        d     => q3,
		q     => q4,
		q_bar => q4_bar
    );

    wide_trigger_3: entity work.d_type
    port map (
        clk   => clk_in,
        d     => q4,
		q     => q5,
		q_bar => q5_bar
    );

    trigger_out <= q2 or q3 or q4 or q5;
            
end architecture Behavioral;
