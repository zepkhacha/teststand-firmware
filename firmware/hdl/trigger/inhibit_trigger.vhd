library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity inhibit_trigger is
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz
    reset                : in  std_logic;

    -- kicker blumlein charging and discarge triggers
    charging_trigger     : in  std_logic;

    -- time after which a safety discharge should fire
    inhibit_time : in  std_logic_vector(31 downto 0);

    -- safety trigger output
    trigger_with_inhibit  : out std_logic
);
end inhibit_trigger;

architecture behavioral of inhibit_trigger is
    type machine_state is (watch_for_charging, send_charge_pulse, enforce_inhibit);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,    nx_state   : machine_state;
    signal pr_inhibit,  nx_inhibit : std_logic_vector(32 downto 0);
    signal pr_trigger,  nx_trigger : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state   <= watch_for_charging;
                pr_inhibit <= '0' & inhibit_time;
                pr_trigger <= '0';
            else
                pr_state   <= nx_state;
                pr_inhibit <= nx_inhibit;
                pr_trigger <= nx_trigger;
            end if;
        end if;
    end process;

    process (pr_state, pr_inhibit, pr_trigger, charging_trigger )
    begin
        case pr_state is
            when watch_for_charging =>
                nx_inhibit <= '0' & inhibit_time;
                nx_trigger <= charging_trigger;
                if charging_trigger = '1' then
                    nx_state  <= send_charge_pulse;
                else
                    nx_state  <= watch_for_charging;
                end if;

            when send_charge_pulse =>
                nx_trigger <= charging_trigger;
                nx_inhibit <= '0' & inhibit_time;
                if charging_trigger = '1' then
                    nx_state  <= send_charge_pulse;
                else
                    nx_state  <= enforce_inhibit;
                end if;

            when enforce_inhibit =>
                nx_inhibit <= pr_inhibit - 1;
                nx_trigger <= '0';
                if pr_inhibit(pr_inhibit'high) = '1' then
                    nx_state   <= watch_for_charging;
                else
                    nx_state   <= enforce_inhibit;
                end if;

        end case;
    end process;

    trigger_with_inhibit <= pr_trigger;

end architecture behavioral;


