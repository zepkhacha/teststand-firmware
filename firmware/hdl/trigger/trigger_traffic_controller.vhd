library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity trigger_traffic_controller is 
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz
    reset                : in  std_logic;
    fallback_enabled     : in  std_logic;
    force_internal       : in  std_logic;

    -- A6 has been detected missing (high) or re-appeared (low)
    a6_missing           : in  std_logic; 

    -- trigger out
    transition_trigger   : out std_logic;

    -- internal triggering
    use_internal_trigger : out std_logic
);
end trigger_traffic_controller;

architecture behavioral of trigger_traffic_controller is
    type machine_state is (watch_transitions, issue_notice, watch_notice_start, watch_notice_stop, toggle_state);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "000 001 010 011 100";

    signal pr_state,       nx_state       : machine_state;
    signal pr_a6_lost,     nx_a6_lost     : std_logic;
    signal pr_transition,  nx_transition  : std_logic;
    signal pr_enable_int,  nx_enable_int  : std_logic;
    signal pr_trans_width, nx_trans_width : std_logic_vector(3 downto 0);
    signal pr_force_intrn, nx_force_intrn : std_logic;

    signal stop_int_trig_width : std_logic_vector(3 downto 0);
    signal strt_int_trig_width : std_logic_vector(3 downto 0);
    signal transition_pulse    : std_logic;

--    attribute mark_debug : string;
--    attribute mark_debug of pr_state             : signal is "true";
--    attribute mark_debug of pr_a6_lost           : signal is "true";
--    attribute mark_debug of pr_transition        : signal is "true";
--    attribute mark_debug of pr_enable_int        : signal is "true";
--    attribute mark_debug of pr_trans_width       : signal is "true";
--    attribute mark_debug of pr_force_intrn       : signal is "true";
--    attribute mark_debug of transition_pulse         : signal is "true";
--    attribute mark_debug of fallback_enabled         : signal is "true";
--    attribute mark_debug of force_internal       : signal is "true";
--    attribute mark_debug of a6_missing           : signal is "true";
--    attribute mark_debug of use_internal_trigger : signal is "true";

begin

    signal_transition: entity work.fast_variable_pulse -- 100 ns / "length bit"
    port map (
        clk      => clk,
        trigger  => pr_transition,
        length   => pr_trans_width,
        pulse    => transition_pulse
    );

    transition_trigger   <= transition_pulse;
    use_internal_trigger <= pr_enable_int;

    -- strt_int_trig_width <= "0011"; -- 300 ns
    -- stop_int_trig_width <= "0100"; -- 400 ns
    strt_int_trig_width <= "0100"; -- 400 ns
    stop_int_trig_width <= "0110"; -- 600 ns

    transition_mon: process( clk, reset )
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pr_state       <= watch_transitions;
                pr_a6_lost     <= '0'; -- if we are being reset, assume that by default we have accelerator trigger.  We will transition to internal trigger eventually if not
                pr_force_intrn <= '0';
                pr_transition  <= '0'; -- consistent with above, we will look for loss of A6
                pr_enable_int  <= '0';
                pr_trans_width <= strt_int_trig_width; -- if we see a transition, then consistent with above it will be a lost a6 that we should signal
            else
                pr_state       <= nx_state      ;
                pr_a6_lost     <= nx_a6_lost    ;
                pr_force_intrn <= nx_force_intrn;
                pr_transition  <= nx_transition ;
                pr_trans_width <= nx_trans_width;
                pr_enable_int  <= nx_enable_int;
            end if;
        end if;
    end process;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_a6_lost, pr_force_intrn, pr_transition, pr_trans_width, a6_missing, force_internal, transition_pulse)
    begin
        case pr_state is
            when watch_transitions =>
                nx_a6_lost     <= pr_a6_lost;
                nx_force_intrn <= pr_force_intrn;
                nx_transition  <= '0';
                nx_trans_width <= pr_trans_width;
                nx_enable_int  <= pr_enable_int;
                if pr_a6_lost = a6_missing and pr_force_intrn = force_internal then
                    nx_state   <= watch_transitions;
                else
                    nx_state   <= issue_notice;
                end if;

            -- a transition has occurred that can change the state of the internal / external triggering
            -- generate an extra long "A6" signal for the encoder, but wait for that signal to complete before
            -- toggling the internal triggering state
            when issue_notice =>
                nx_transition  <= '1';
                nx_a6_lost     <= a6_missing;
                nx_force_intrn <= force_internal;
                nx_enable_int  <= pr_enable_int;

                if a6_missing = '0' and force_internal = '0' then
                    nx_trans_width <= stop_int_trig_width;
                else
                    nx_trans_width <= strt_int_trig_width;
                end if;
                nx_state <= watch_notice_start;

            when watch_notice_start =>
                nx_trans_width <= pr_trans_width;
                nx_transition  <= '0';
                nx_a6_lost     <= pr_a6_lost;
                nx_force_intrn <= pr_force_intrn;
                nx_enable_int  <= pr_enable_int;
                if transition_pulse = '1' then
                    nx_state   <= watch_notice_stop;
                else
                    nx_state   <= watch_notice_start;
                end if;

            when watch_notice_stop =>
                nx_trans_width <= pr_trans_width;
                nx_transition  <= '0';
                nx_a6_lost     <= pr_a6_lost;
                nx_force_intrn <= pr_force_intrn;
                nx_enable_int  <= pr_enable_int;
                if transition_pulse = '0' then
                    nx_state   <= toggle_state;
                else
                    nx_state   <= watch_notice_stop;
                end if;

            -- encoder has now received full length pulse, and will go back to syncronizing to gap.  Transition the trigger source now
            when toggle_state =>
                nx_trans_width <= pr_trans_width;
                nx_transition  <= '0';
                nx_a6_lost     <= pr_a6_lost;
                nx_force_intrn <= pr_force_intrn;
                nx_state       <= watch_transitions;
                nx_enable_int  <= (fallback_enabled and pr_a6_lost) or pr_force_intrn;


        end case;
    end process;

end architecture behavioral;
