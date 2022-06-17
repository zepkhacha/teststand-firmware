-- This module checks if we are now on the next to last trigger of a sequencer.
-- It must introduce before turning on the flag to ensure that the counter_sm
-- state machine has finished its transition to the monitoring state

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity sequence_limit_check is
port (
    clk               : in  std_logic;
    reset             : in  std_logic;
    boc               : in  std_logic;  -- begin of cycle
    seq_index         : in  std_logic_vector( 3 downto 0);
    max_seq_index     : in  std_logic_vector( 3 downto 0);
    assert_penu_delay : in  std_logic_vector( 3 downto 0);
    assert_cyc2_delay : in  std_logic_vector(23 downto 0);
    penultimate_seq   : out std_logic;
    second_cycle      : out std_logic;
    sequence_error    : out std_logic
);
end sequence_limit_check;

architecture Behavioral of sequence_limit_check is

    type machine_task is (idle, watch, delay, check_penult, check_2nd_cycle, big_delay );

    attribute ENUM_ENCODING                 : string;
    attribute ENUM_ENCODING of machine_task : type is "000 001 010 011 100 101";

    signal pr_state,       nx_state       : machine_task;
    signal pr_delay,       nx_delay       : std_logic_vector(3  downto 0);
    signal pr_big_delay,   nx_big_delay   : std_logic_vector(23 downto 0);
    signal pr_found_pen,   nx_found_pen   : std_logic;
    signal pr_second_cyc,  nx_second_cyc  : std_logic;
    signal pr_next_seq,    nx_next_seq    : std_logic_vector(3  downto 0);
    signal pr_curr_seq,    nx_curr_seq    : std_logic_vector(3  downto 0);
    signal error_condition                : std_logic;

--    attribute mark_debug : string;
--    attribute mark_debug of pr_state       : signal is "true";
--    attribute mark_debug of pr_delay       : signal is "true";
--    attribute mark_debug of pr_big_delay   : signal is "true";
--    attribute mark_debug of pr_next_seq    : signal is "true";
--    attribute mark_debug of pr_second_cyc  : signal is "true";
--    attribute mark_debug of pr_found_pen   : signal is "true";
--    attribute mark_debug of pr_curr_seq    : signal is "true";
--    attribute mark_debug of boc            : signal is "true";
--    attribute mark_debug of seq_index      : signal is "true";
--    attribute mark_debug of max_seq_index  : signal is "true";

begin

    -- sequential logic
    pr_state_logic: process(clk)
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state      <= idle;
                pr_delay      <= assert_penu_delay;
                pr_big_delay  <= assert_cyc2_delay;
                pr_next_seq   <= "0000";
                pr_curr_seq   <= "0000";
                pr_second_cyc <= '0';
                pr_found_pen  <= '0';
            elsif ( boc = '1') then
                pr_state      <= idle;
                pr_delay      <= assert_penu_delay;
                pr_big_delay  <= assert_cyc2_delay;
                pr_next_seq   <= "0000";
                pr_curr_seq   <= nx_curr_seq;
                pr_second_cyc <= '0';
                pr_found_pen  <= '0';
            else
                pr_state      <= nx_state;
                pr_delay      <= nx_delay;
                pr_big_delay  <= nx_big_delay;
                pr_next_seq   <= nx_next_seq;
                pr_second_cyc <= nx_second_cyc;
                pr_found_pen  <= nx_found_pen;
                pr_curr_seq   <= nx_curr_seq;
            end if;
        end if;
    end process;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_delay, pr_next_seq, pr_found_pen, pr_second_cyc, pr_big_delay, seq_index, max_seq_index )
    begin
        case pr_state is
            when idle =>
--                nx_delay      <= "111";
--                nx_big_delay  <= "0111111111111111111111";
                nx_delay      <= assert_penu_delay;
                nx_big_delay  <= assert_cyc2_delay;
                nx_next_seq   <= "0000";
                nx_found_pen  <= pr_found_pen;
                nx_second_cyc <= pr_second_cyc;
                nx_curr_seq   <= pr_curr_seq;
                if max_seq_index /= "0000" then
                    nx_state <= watch;
                else
                    nx_state <= idle;
                end if;

            when watch =>
                nx_delay      <= assert_penu_delay;
                nx_big_delay  <= assert_cyc2_delay;
                nx_found_pen  <= pr_found_pen;
                nx_second_cyc <= pr_second_cyc;
                nx_next_seq   <= seq_index + 1;
                if ( max_seq_index = "0000" ) then
                    nx_state    <= idle;
                    nx_curr_seq <= pr_curr_seq;
                else
                    if ( seq_index(2 downto 0) = pr_curr_seq(2 downto 0) ) then
                        nx_state    <= watch;
                        nx_curr_seq <= pr_curr_seq;
                    else
                        nx_state    <= delay;
                        nx_curr_seq <= seq_index;
                    end if;
                end if;

            when delay =>
                nx_delay      <= pr_delay - 1;
                nx_big_delay  <= assert_cyc2_delay;
                nx_found_pen  <= pr_found_pen;
                nx_second_cyc <= pr_second_cyc;
                nx_next_seq   <= pr_next_seq;
                nx_curr_seq   <= pr_curr_seq;
                if pr_delay = 0 then
                    nx_state <= check_penult;
                else
                    nx_state <= delay;
                end if;

            when check_penult =>
                nx_delay     <= assert_penu_delay;
                nx_big_delay <= assert_cyc2_delay;
                nx_curr_seq  <= pr_curr_seq;
                if ( pr_next_seq = max_seq_index ) then
                    nx_found_pen <= '1';
                else
                    nx_found_pen <= '0';
                end if;
                if ( max_seq_index(3) = '1' ) then
                    nx_state     <= check_2nd_cycle;
                    nx_next_seq  <= pr_next_seq;
                else
                    nx_state     <= watch;
                    if ( pr_next_seq(2 downto 0) = max_seq_index(2 downto 0) ) then
                        nx_next_seq  <= "0000";
                    else
                        nx_next_seq  <= pr_next_seq;
                    end if;
                end if;
                nx_second_cyc <= pr_second_cyc;

            when check_2nd_cycle =>
                nx_delay     <= assert_penu_delay;
                nx_next_seq  <= pr_next_seq;
                nx_curr_seq  <= pr_curr_seq;
                nx_big_delay <= assert_cyc2_delay;
                if ( seq_index(2 downto 0) = max_seq_index(2 downto 0) ) then
                    nx_state <= big_delay;
                else
                    nx_state <= watch;
                end if;
                nx_found_pen  <= pr_found_pen;
                nx_second_cyc <= pr_second_cyc;
                
            when big_delay =>
                nx_delay     <= assert_penu_delay;
                nx_next_seq  <= pr_next_seq;
                nx_curr_seq  <= pr_curr_seq;
                nx_big_delay <= pr_big_delay - 1;
                if ( pr_big_delay(pr_big_delay'high) = '1' ) then
                    nx_state      <= watch;
                    nx_second_cyc <= not pr_second_cyc;
                else
                    nx_state      <= big_delay;
                    nx_second_cyc <= pr_second_cyc;
                end if;
                nx_found_pen  <= pr_found_pen;
        end case;
    end process;

    penultimate_seq <= pr_found_pen;
    second_cycle    <= pr_second_cyc;

    -- error handling: this will take some thought given the delays
--    error_condition <= '1' when pr_second_cyc = '1' and seq_index = "0000" else '0';
    error_condition <= '0';

    process(error_condition)
    begin
        if error_condition = '1' then
            sequence_error <= '1';
        else
            sequence_error <= '0';
        end if;
    end process;



end architecture Behavioral;
