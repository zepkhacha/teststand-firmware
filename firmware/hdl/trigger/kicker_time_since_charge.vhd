library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity kicker_time_since_charge is 
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz ttc clock
    reset                : in  std_logic; -- this should be a reset synchronized with the ttc clock

    -- charge/discharge signals
    charge_cap         : in  std_logic;   -- trigger pulse for charging the capacitor
    fire_kicker        : in  std_logic;   -- trigger pulse for firing a given kicker

    -- number of triggers per t9 (aka, number of sequences for the other triggers), delay and width spec's
    time_since_charge    : out  std_logic_vector(31 downto 0)
);
end kicker_time_since_charge;

architecture behavioral of kicker_time_since_charge is
    type machine_state is (wait_for_charge, wait_for_fire, latchDelayCount);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";


    signal pr_state,        nx_state        : machine_state;
    signal pr_count,        nx_count        : std_logic_vector(31 downto 0);
    signal pr_latch,        nx_latch        : std_logic;

    signal latched_count : std_logic_vector(31 downto 0);

    signal charge_pulse : std_logic;
    signal fire_pulse   : std_logic;

begin


    -- create 1-cycle-wide pulses
    charge_conv: entity work.level_to_pulse port map (clk => clk,   sig_i => charge_cap,  sig_o => charge_pulse);
    fire_conv:   entity work.level_to_pulse port map (clk => clk,   sig_i => fire_kicker, sig_o => fire_pulse);


    update_state: process( clk )
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state      <= wait_for_charge;
                pr_latch      <= '1';
                pr_count      <= x"00000000";
            else
                pr_state      <= nx_state;
                pr_latch      <= nx_latch;
                pr_count      <= nx_count;
            end if;
        end if;
    end process;

    nx_state_logic: process( pr_state, pr_count, pr_latch, charge_pulse, fire_pulse )
    begin
        case pr_state is
            when wait_for_charge =>
                nx_latch <= '0';
                nx_count <= x"00000000";

                if charge_pulse = '1' then
                    nx_state <= wait_for_fire;
                else
                    nx_state <= wait_for_charge;
                end if;

            when wait_for_fire =>
                nx_latch <= '0';
                nx_count <= pr_count + '1';

                if fire_pulse = '1' then
                    nx_state <= latchDelayCount;
                else
                    nx_state <= wait_for_fire;
                end if;

            when latchDelayCount =>
                nx_latch <= '1';
                nx_count <= pr_count;
                nx_state <= wait_for_charge;
        end case;
    end process;

    latch_count: process( clk, pr_latch)
    begin
        if rising_edge(clk) then
            if pr_latch = '1' then
                latched_count <= pr_count;
            end if;
        end if;
    end process;

   time_since_charge <= latched_count;

end architecture behavioral;
