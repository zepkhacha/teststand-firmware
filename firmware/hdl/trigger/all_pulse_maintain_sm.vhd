-- This module outputs one pulse with a variable width and delay for every 'trigger_in' input pulse

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.system_package.all;

entity all_pulse_maintain_sm is
port (
    clk            : in  std_logic;
    enabled        : in  std_logic;
    trigger_in     : in  std_logic;
    pulse          : in  std_logic_vector(1 downto 0);
    trig_width_i   : in  array_4x5bit;
    trig_width_o   : in  array_4x5bit;
    trigger_out    : out std_logic
);
end all_pulse_maintain_sm;

architecture Behavioral of all_pulse_maintain_sm is

    type machine_state is (idle, monitor, transitionToSend,   sendCountInner,  sendCountOuter);
    type machine_pulse_state is (wait_for_trigger, wait_for_trigger_done);

    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "000 001 010 011 100";
    attribute ENUM_ENCODING of machine_pulse_state : type is "0 1";

    signal pr_state,        nx_state         : machine_state;
    signal pr_width_cnt_i,  nx_width_cnt_i   : std_logic_vector(4 downto 0);
    signal pr_width_cnt_o,  nx_width_cnt_o   : std_logic_vector(4 downto 0);
    signal pr_trigger_out,  nx_trigger_out   : std_logic;
    signal pr_pulse_state,  nx_pulse_state   : machine_pulse_state;
    signal pr_use_trigger,  nx_use_trigger   : std_logic;
    signal second_cycle_index                : std_logic_vector(0 downto 0);

--    attribute mark_debug : string;
--    attribute mark_debug of pr_state : signal is "true";
--    attribute mark_debug of pr_width_cnt_i : signal is "true";
--    attribute mark_debug of pr_width_cnt_o : signal is "true";
--    attribute mark_debug of enabled : signal is "true";
--    attribute mark_debug of pulse : signal is "true";
--    attribute mark_debug of pr_trigger_out : signal is "true";

begin

    -- sequential logic
    pr_state_logic: process(clk)
    begin
        if rising_edge(clk) then

            -- level to pulse logic
            pr_pulse_state  <= nx_pulse_state;
            pr_use_trigger  <= nx_use_trigger;

            -- pulse maintaining logic
            pr_state        <= nx_state;

            pr_width_cnt_i  <= nx_width_cnt_i;
            pr_width_cnt_o  <= nx_width_cnt_o;
            
            pr_trigger_out  <= nx_trigger_out;
        end if;
    end process;

    -- combinational logic

    effective_pulse: process( pr_pulse_state, trigger_in )
    begin
        case pr_pulse_state is
            when wait_for_trigger =>
                nx_use_trigger <= '1';
                if trigger_in = '1' then
                    nx_pulse_state <= wait_for_trigger_done;
                else
                    nx_pulse_state <= wait_for_trigger;
                end if;

            when wait_for_trigger_done =>
                nx_use_trigger <= '0';
                if trigger_in = '0' then
                    nx_pulse_state <= wait_for_trigger;
                else
                    nx_pulse_state <= wait_for_trigger_done;
                end if;
        end case;
    end process;

    nx_state_logic: process(pr_state, pr_width_cnt_i, pr_width_cnt_o, enabled, pr_use_trigger,
                          trigger_in,   trig_width_i,   trig_width_o, pulse )
    begin
        case pr_state is
            when idle =>
                nx_width_cnt_i   <= (others => '0');
                nx_width_cnt_o   <= (others => '0');
                nx_trigger_out <= '0';

                if enabled = '1' then
                    nx_state <= monitor;
                else
                    nx_state <= idle;
                end if;

            when monitor =>

                nx_width_cnt_i   <= (others => '0');
                nx_width_cnt_o   <= (others => '0');

                nx_trigger_out <= '0';
                if trigger_in = '1' and pr_use_trigger = '1' then
                    nx_state <= transitionToSend;
                else
                    nx_state <= monitor;
                end if;

            when transitionToSend =>
                nx_width_cnt_i  <= trig_width_i(to_integer(unsigned(pulse))) - 1;
                nx_width_cnt_o  <= trig_width_o(to_integer(unsigned(pulse)));

                nx_trigger_out <= '1';
                nx_state       <= sendCountInner;

            when sendCountInner =>
                nx_width_cnt_i  <= pr_width_cnt_i - 1;
                nx_width_cnt_o  <= pr_width_cnt_o;

                nx_trigger_out <= '1';
                if pr_width_cnt_i(pr_width_cnt_i'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    if pr_width_cnt_o(pr_width_cnt_o'high) = '1' then
                        nx_state <= idle;
                    else
                    nx_state <= sendCountOuter;
                    end if;
                else
                    nx_state <= sendCountInner;
                end if;

            when sendCountOuter =>
                nx_width_cnt_i  <= "01110";   
                nx_width_cnt_o  <= pr_width_cnt_o - 1;

                nx_trigger_out <= '1';
                if pr_width_cnt_o(pr_width_cnt_o'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    nx_state <= idle;
                else
                    nx_state <= sendCountInner;
                end if;
        end case;
    end process;
    
    trigger_out <= pr_trigger_out;

end architecture Behavioral;
