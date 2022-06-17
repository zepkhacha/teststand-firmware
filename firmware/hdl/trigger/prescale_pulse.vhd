-- This module counts the trigger sequencer index.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity prescale_pulse is
generic (
    n : positive := 4
);
port (
    clk             : in  std_logic;
    prescale_factor : in  std_logic_vector(n-1 downto 0);
    active          : in  std_logic;
    pulse_in        : in  std_logic;
    prescale_seen   : out std_logic
);
end prescale_pulse;

architecture Behavioral of prescale_pulse is

    type machine_task is (idle, restart_sequence, watch_for_pulse, check_count);

    attribute ENUM_ENCODING                 : string;
    attribute ENUM_ENCODING of machine_task : type is "00 01 10 11";

    signal pr_state,         nx_state         : machine_task;
    signal pr_prescale_seen, nx_prescale_seen : std_logic;
    signal pr_pulse_count,   nx_pulse_count   : std_logic_vector(n-1 downto 0);

begin

    -- sequential logic
    pr_state_logic: process(clk)
    begin
        if rising_edge(clk) then
            pr_state         <= nx_state;
            pr_prescale_seen <= nx_prescale_seen;
            pr_pulse_count   <= nx_pulse_count;
        end if;
    end process;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_prescale_seen, pr_pulse_count, pulse_in, prescale_factor, active )
    begin
        case pr_state is
            when idle =>
                nx_pulse_count   <= (others => '0');
                if prescale_factor /= 1 then
                   nx_prescale_seen <= '0';
                else
                   nx_prescale_seen <= '1';
                end if;
                if active = '1' and prescale_factor /= 0 then
                    nx_state <= restart_sequence;
                else
                    nx_state <= idle;
                end if;

            when restart_sequence =>
                nx_pulse_count   <= prescale_factor;
                nx_prescale_seen <= pr_prescale_seen;
                nx_state         <= watch_for_pulse;

            when watch_for_pulse =>
                nx_prescale_seen <= pr_prescale_seen;
                if active = '0' then
                    nx_pulse_count <= pr_pulse_count;
                    nx_state       <= idle;
                elsif pulse_in = '1' then
                    nx_pulse_count <= pr_pulse_count - 1;
                    nx_state       <= check_count;
                else
                    nx_pulse_count <= pr_pulse_count;
                    nx_state       <= watch_for_pulse;
                end if;

            when check_count =>
                nx_pulse_count <= pr_pulse_count;
                if active = '0' then
                    nx_pulse_count <= pr_pulse_count;
                    nx_state       <= idle;
                elsif ( pr_pulse_count = 0 ) then
                    nx_state         <= restart_sequence;
                    nx_prescale_seen <= '1';
                else
                    nx_state         <= watch_for_pulse;
                    nx_prescale_seen <= '0';
                end if;

        end case;
    end process;

    prescale_seen <= pr_prescale_seen;

end architecture Behavioral;
