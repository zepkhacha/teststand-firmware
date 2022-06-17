library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity generate_inhibit is
port (
    -- ttc clock
    clk                  : in  std_logic;
    reset                : in  std_logic;

    -- input trigger to start inhibit signal
    trigger_in     : in  std_logic;

    -- length of time to generate inhibit
    inhibit_time   : in  std_logic_vector(31 downto 0);

    -- inhibit signal output
    inhibit_out    : out std_logic
);
end generate_inhibit;

architecture behavioral of generate_inhibit is
    type machine_state is (watch_for_trigger, wait_for_trigger, generate_inhibit);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,    nx_state   : machine_state;
    signal pr_inhibit,  nx_inhibit : std_logic_vector(32 downto 0);
    signal pr_inhibiting, nx_inhibiting : std_logic;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state      <= watch_for_trigger;
                pr_inhibit    <= '0' & inhibit_time;
                pr_inhibiting <= '0';
            else
                pr_state      <= nx_state;
                pr_inhibit    <= nx_inhibit;
                pr_inhibiting <= nx_inhibiting;
            end if;
        end if;
    end process;

    process (pr_state, pr_inhibit, trigger_in )
    begin
        case pr_state is
            when watch_for_trigger =>
                nx_inhibit <= '0' & inhibit_time;
                nx_inhibiting <= '0';
                if trigger_in = '1' then
                    nx_state  <= wait_for_trigger;
                else
                    nx_state  <= watch_for_trigger;
                end if;

            when wait_for_trigger =>
                nx_inhibit <= '0' & inhibit_time;
                nx_inhibiting <= '0';
                if trigger_in = '1' then
                    nx_state  <= wait_for_trigger;
                else
                    nx_state  <= generate_inhibit;
                end if;

            when generate_inhibit =>
                nx_inhibit <= pr_inhibit - 1;
                nx_inhibiting <= '1';
                if pr_inhibit(pr_inhibit'high) = '1' then
                    nx_state   <= watch_for_trigger;
                else
                    nx_state   <= generate_inhibit;
                end if;

        end case;
    end process;

    inhibit_out <= pr_inhibiting;

end architecture behavioral;



