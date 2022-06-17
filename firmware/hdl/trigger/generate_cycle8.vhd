library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- ------------------------------------
entity generate_cycle8 is
port (
    clk             : in  std_logic;   
    start           : in  std_logic;  
    period          : in  std_logic_vector(31 downto 0);
    asix            : out std_logic;
    active          : out std_logic
);
end generate_cycle8;
-- -----------------------------------------------------------------
architecture behavioural of generate_cycle8 is
    type machine_state is (idle, issue_asix, delay);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,  nx_state       : machine_state;
    signal pr_delay,  nx_delay       : std_logic_vector(32 downto 0);
    signal pr_asix,   nx_asix        : std_logic;
    signal pr_active, nx_active      : std_logic;
    signal pr_count,  nx_count       : unsigned(2 downto 0 );
    signal period32                  : std_logic_vector(32 downto 0);

    signal begin_cycle               : std_logic;

begin
-- -------------- sequential logic --------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            pr_state  <= nx_state;
            pr_delay  <= nx_delay;
            pr_count  <= nx_count;
            pr_asix   <= nx_asix;
            pr_active <= nx_active;
        end if;
    end process;

    period32 <= '0' & period;

    -- non-debug version
    begin_cycle <= start;
    -- debug version, introduce a delay for the $A6
--    delay_a6 : entity work.pulse_delay
--    generic map ( nbr_bits => 8 )
--    port map (
--        clock     => clk, 
--        delay     => "00010001", 
--        pulse_in  => start, 
--        pulse_out => begin_cycle 
--    );

-- -------------- combinational logic -----------------------------
    process (pr_state, pr_delay, pr_asix, pr_active, pr_count, period, begin_cycle)
    begin
        case pr_state is
            when idle =>
                nx_delay <= period32 - 3;
                nx_count  <= "000";
                nx_asix   <= '0';

                if begin_cycle = '0' then
                    nx_state  <= idle; 
                    nx_active <= '0';
                else
                    nx_state  <= issue_asix;
                    nx_active <= '1';
                end if;

            when issue_asix =>
                nx_delay <= period32 - 3;
                nx_count <= pr_count + 1;
                nx_asix  <= '1';
                nx_active <= '1';

                if pr_count = "111" then
                    nx_state <= idle;
                else
                    nx_state <= delay;
                end if;

            when delay =>
                nx_delay <= pr_delay - 1;
                nx_count <= pr_count;
                nx_asix <= '0';
                nx_active <= '1';

                if pr_delay(pr_delay'high) = '1' then
                    nx_state <= issue_asix;
                else
                    nx_state <= delay;
                end if;

        end case;
    end process;

    asix   <= pr_asix;
    active <= pr_active;

end architecture behavioural;
