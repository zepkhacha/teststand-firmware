library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity kicker_safety_trig is
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz
    reset                : in  std_logic;
    -- kicker blumlein charging and discarge triggers
    charging_trigger     : in  std_logic;
    discharge_trigger    : in  std_logic;

    -- time after which a safety discharge should fire
    safety_dischrge_time : in  std_logic_vector(31 downto 0);

    -- safety trigger output
    safety_trigger       : out std_logic
);
end kicker_safety_trig;

architecture behavioral of kicker_safety_trig is
    type machine_state is (watch_for_charging, monitor_discharge, fire_safety);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,    nx_state : machine_state;
    signal pr_tsc,      nx_tsc   : std_logic_vector(32 downto 0);

    signal charging_pulse,  discharge_pulse : std_logic;
    signal safety_state,    safety_stretch  : std_logic;
begin

    -- convert input signals to  1 cycle pulses
    charge_convert: entity work.level_to_pulse port map (clk => clk, sig_i => charging_trigger,  sig_o => charging_pulse );
    dischg_convert: entity work.level_to_pulse port map (clk => clk, sig_i => discharge_trigger, sig_o => discharge_pulse );


    -- reset: resert counter and got to state waiting for a charging trigger
    process(clk)
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state <= watch_for_charging;
                pr_tsc   <= '0' & safety_dischrge_time;
            else
                pr_state <= nx_state;
                pr_tsc   <= nx_tsc;
            end if;
        end if;
    end process;

    process (pr_state, pr_tsc, charging_pulse, discharge_pulse )
    begin
        case pr_state is
            when watch_for_charging =>
                nx_tsc <= '0' & safety_dischrge_time;
                if charging_pulse = '1' then
                    nx_state  <= monitor_discharge;
                else
                    nx_state  <= watch_for_charging;
                end if;

            when monitor_discharge =>
                nx_tsc <= pr_tsc - 1;
                if discharge_pulse = '1' then
                    nx_state   <= watch_for_charging;
                elsif pr_tsc(pr_tsc'high) = '1' then
                    nx_state   <= fire_safety;
                else
                    nx_state   <= monitor_discharge;
                end if;

            when fire_safety =>
                nx_tsc   <= '0' & safety_dischrge_time;
                nx_state <= watch_for_charging;

        end case;
    end process;

    safety_state <= '1' when pr_state = fire_safety else '0';
    stretch_safety: entity work.signal_stretch port map (clk => clk, n_cycles => x"05", sig_i => safety_state, sig_o => safety_stretch );
    safety_trigger <= safety_stretch;

end architecture behavioral;

