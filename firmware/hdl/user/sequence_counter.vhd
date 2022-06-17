
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- ------------------------------------
entity sequence_counter is
port (
    clk                    : in  std_logic;
    reset                  : in  std_logic;
    input_pulse            : in  std_logic;
    pulse_count            : out std_logic_vector(4 downto 0)
);
end sequence_counter;
-- -----------------------------------------------------------------
architecture behavioural of sequence_counter is
    type machine_state is (watch, count);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "0 1";

    signal pr_state,         nx_state           : machine_state;
    signal pr_count,         nx_count           : std_logic_vector(4 downto 0);

begin
-- -------------- sequential logic --------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pr_state       <= watch;
                pr_count       <= (others => '0');
            else
                pr_state              <= nx_state;
                pr_count              <= nx_count;
            end if;
        end if;
    end process;

-- -------------- combinational logic -----------------------------
    process (pr_state, pr_count, input_pulse)
    begin
        case pr_state is
            when watch =>
                nx_count <= pr_count;
                if input_pulse = '1' then
                    nx_state <= count;
                else
                    nx_state <= watch;
                end if;

            when count =>
                if pr_count(4) = '1' then
                   nx_count <= (others => '0');
                else
                   nx_count <= pr_count + 1;
                end if;
                nx_state <= watch;
        end case;
    end process;

    pulse_count <= pr_count;
    
end architecture behavioural;
