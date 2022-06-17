-- Generic module to delay a 1-bit, 1-clock-wide pulse with a configurable delay;
-- Latches the 'delay' input upon 'pulse_in' assertion

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity trigger_length_counter is
port ( 
    clock      : in  std_logic;                             -- input clock
    reset      : in  std_logic;
    pulse_in   : in  std_logic;                             -- input pulse
    pulse_out  : out std_logic;                             -- two cycle output pulse
    internal_start : out std_logic;
    internal_stop  : out std_logic;
    missed_a6      : out std_logic
);
end entity trigger_length_counter;

architecture Behavioral of trigger_length_counter is
    type machine_state is (watch, count, evaluate, maintain);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10 11";

    signal pr_state,    nx_state   : machine_state;
    signal pr_count,    nx_count   : std_logic_vector(31 downto 0);
    signal pr_internal_strt, nx_internal_strt : std_logic;
    signal pr_internal_stop, nx_internal_stop : std_logic;
    signal pr_a6_missed,     nx_a6_missed     : std_logic;

    signal internal_strt_bdry : unsigned( 4 downto 0 );
    signal internal_stop_bdry : unsigned( 4 downto 0 );
    signal reset_cycle_bdry   : unsigned( 4 downto 0 );

--    -- debugs
--   attribute mark_debug : string;
--   attribute mark_debug of pulse_in         : signal is "true";

begin

    internal_strt_bdry <= "01101"; -- 325 ns
    internal_stop_bdry <= "10100"; -- 500 ns
    reset_cycle_bdry   <= "11100"; -- 700 ns

    process(clock)
    begin
        if reset = '1' then 
            pr_state <= watch;
            pr_count <= (others => '0');
            pr_internal_strt <= '0';
            pr_internal_stop <= '0';
            pr_a6_missed     <= '0';
        elsif rising_edge(clock) then
            pr_state <= nx_state;
            pr_count <= nx_count;
            pr_internal_strt <= nx_internal_strt;
            pr_internal_stop <= nx_internal_stop;
            pr_a6_missed     <= nx_a6_missed;
        end if;
    end process;

    process (pr_state, pr_count, pulse_in, pr_internal_strt, pr_internal_stop)
    begin
        case pr_state is
            when watch =>
                nx_count   <= ( others => '0');
                nx_internal_strt <= pr_internal_strt;
                nx_internal_stop <= pr_internal_stop;
                nx_a6_missed     <= pr_a6_missed;
                pulse_out <= '0';
                if ( pulse_in = '1' ) then
                    nx_state <= count;
                else
                    nx_state <= watch;
                end if;

            when count =>
                nx_count <= pr_count + 1;
                nx_internal_strt <= '0';
                nx_internal_stop <= '0';
                nx_a6_missed     <= '0';
                pulse_out <= '0';

                if ( pulse_in = '1' ) then
                    nx_state <= count;
                else
                    nx_state <= evaluate;
                end if;

            when evaluate => 
                pulse_out <= '1';
                nx_state <= maintain;
                nx_count <= pr_count;
                if unsigned(pr_count) < internal_strt_bdry then
                    nx_internal_strt <= '0';
                    nx_internal_stop <= '0';
                    nx_a6_missed     <= '0';
                elsif unsigned(pr_count) < internal_stop_bdry then
                    nx_internal_strt <= '1';
                    nx_internal_stop <= '0';
                    nx_a6_missed     <= '0';
                elsif unsigned(pr_count) < reset_cycle_bdry then
                    nx_internal_strt <= '0';
                    nx_internal_stop <= '1';
                    nx_a6_missed     <= '0';
                else
                    nx_internal_strt <= '0';
                    nx_internal_stop <= '0';
                    nx_a6_missed     <= '1';
                end if;

            when maintain =>
                nx_count <= pr_count;
                pulse_out <= '1';
                nx_state   <= watch;
                nx_internal_strt <= pr_internal_strt;
                nx_internal_stop <= pr_internal_stop;
                nx_a6_missed     <= pr_a6_missed;

        end case;
    end process;

    internal_start <= pr_internal_strt;
    internal_stop  <= pr_internal_stop;
    missed_a6      <= pr_a6_missed ;

end architecture Behavioral;
