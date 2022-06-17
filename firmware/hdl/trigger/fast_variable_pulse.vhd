library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- ------------------------------------
entity fast_variable_pulse is
generic (
    strtbit : positive := 1
);
port (
    clk                    : in  std_logic;   
    trigger                : in  std_logic;  
    length                 : in  std_logic_vector(3 downto 0);
    pulse                  : out std_logic
);
end fast_variable_pulse;
-- -----------------------------------------------------------------
architecture behavioural of fast_variable_pulse is
    type machine_state is (idle, setup, hold_signal, check);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10 11";

    signal pr_state,         nx_state           : machine_state;
    signal pr_shiftreg,      nx_shiftreg        : std_logic_vector(22 downto 0);
    signal pr_count,         nx_count           : std_logic_vector( 3 downto 0);
    signal pr_signal,        nx_signal          : std_logic;

begin
-- -------------- sequential logic --------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            pr_state              <= nx_state;
            pr_shiftreg           <= nx_shiftreg;
            pr_count              <= nx_count;
            pr_signal             <= nx_signal;
        end if;
    end process;

-- -------------- combinational logic -----------------------------
    process (pr_state, pr_shiftreg, pr_count, pr_signal, trigger, length)
    begin
        case pr_state is
            when idle =>
                nx_shiftreg       <= (strtbit => '1', others => '0');
                nx_count          <= "0000";
                nx_signal         <= '0';

                if trigger = '0' then
                    nx_state <= idle; 
                else
                    nx_state <= setup;
                end if;

            when setup =>
                nx_shiftreg       <= (strtbit => '1', others => '0');
                nx_count          <= pr_count + 1;
                nx_signal         <= '1';

                nx_state <= hold_signal;

            when hold_signal =>
                nx_shiftreg          <= '0' & pr_shiftreg(22 downto 1);
                nx_count             <= pr_count;
                nx_signal            <= '1';

                if pr_shiftreg(0) = '1' then
                    nx_state <= check;
                else
                    nx_state <= hold_signal;
                end if;

            when check =>
                nx_shiftreg       <= (strtbit => '1', others => '0');
                nx_count          <= pr_count;
                nx_signal         <= '1';

                if pr_count = length then
                    nx_state <= idle;
                else
                    nx_state <= setup;
                end if;

        end case;
    end process;

    pulse <= pr_signal;
    
end architecture behavioural;
