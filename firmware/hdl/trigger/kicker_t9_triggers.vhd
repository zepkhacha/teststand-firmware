library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity kicker_t9_triggers is 
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz ttc clock
    reset                : in  std_logic; -- this should be a reset synchronized with the ttc clock

    -- signals from accelerator
    t9                   : in  std_logic;   -- from nim-logic-level lemo input on EDA-02708
    a6                   : in  std_logic;   -- from LVCMOS lemo input on EDA-02708

    -- number of triggers per t9 (aka, number of sequences for the other triggers), delay and width spec's
    enabled              : in  std_logic;
    number_triggers      : in  integer range 0 to 8;
    t9_to_trigger_delays : in  array_2_8x32bit;
    t9_trigger_width     : in  std_logic_vector(8 downto 0);
    iSecondCycle         : in  integer range 0 to 1;

    trigger_armed        : out std_logic;
    trigger_out          : out std_logic;
    a6_trigger_missing   : out std_logic;
    debug_trigger_out    : out std_logic;
      
    -- make sure we clear after the subset of 8 triggers in a supercyle.  Use the kicker safety signal
    safety_clear         : in std_logic
);
end kicker_t9_triggers;

architecture behavioral of kicker_t9_triggers is
    type machine_state is (idle, monitor_t9, transitionToDelay, delayCount, transitionToSend, t9ArmedCheck, sendHold);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "000 001 010 011 100 101 110";

    signal pr_state,            nx_state            : machine_state;
    signal pr_delay_cnt,        nx_delay_cnt        : std_logic_vector(31 downto 0);
    signal pr_width_cnt,        nx_width_cnt        : std_logic_vector( 8 downto 0);
    signal pr_seq_cnt,          nx_seq_cnt          : integer range 0 to 8;
    signal pr_kicker_trigger,   nx_kicker_trigger   : std_logic;
    signal pr_debug_trigger,    nx_debug_trigger    : std_logic;

    signal a6_pulse, t9_pulse         : std_logic;
    signal a6_pulse_stretch           : std_logic;
    signal t9_trigger_stretch         : std_logic;
    signal latch_t9_armed_state       : std_logic;
    signal t9_armed                   : std_logic;
    signal reset_fifo                 : std_logic;
    signal a6_missed                  : std_logic;
    signal safety_clear_stretch       : std_logic;
    signal rearm                      : std_logic;

    -- debugs
--  attribute mark_debug : string;
--  attribute mark_debug of pr_state          : signal is "true";
--  attribute mark_debug of pr_delay_cnt      : signal is "true";
--  attribute mark_debug of pr_width_cnt      : signal is "true";
--  attribute mark_debug of pr_seq_cnt        : signal is "true";
--  attribute mark_debug of pr_kicker_trigger : signal is "true";
--  attribute mark_debug of trigger_out : signal is "true";
--  attribute mark_debug of t9_armed       : signal is "true";
--  attribute mark_debug of a6_pulse      : signal is "true";
--  attribute mark_debug of t9_pulse      : signal is "true";
--  attribute mark_debug of a6_missed      : signal is "true";
--  attribute mark_debug of a6_trigger_missing      : signal is "true";
--  attribute mark_debug of iSecondCycle   : signal is "true";


begin

    -- this flip-flop holds the information that an A6 trigger has been received.  If it has, then we can send the next charging pulse
    -- for the kickers.  When timing is set correctly, the issued T9 triggers and the A6 are never within a few clock cycles.  Hence 
    -- the stretched A6_pulse_stretch signal always has the correct set or clear state that we want the flipflop to hold.  We simply need
    -- to latch the state of that signal with an enable that is the OR of the a6 and t9 stretched pulses
    t9_arm_inst: work.fdse
    port map (
        Q  => t9_armed,
        C  => clk,
        CE => latch_t9_armed_state,
        S  => reset_fifo, -- should set this to high
        D  => rearm
    );

    trigger_armed      <= t9_armed;
    a6_missed          <= not t9_armed when pr_state = t9ArmedCheck else '0';
    a6_trigger_missing <= a6_missed;

    -- convert input t9 and a6 signals to 1 cycle pulses
    t9_convert: entity work.level_to_pulse port map (clk => clk, sig_i => t9, sig_o => t9_pulse );
    a6_convert: entity work.level_to_pulse port map (clk => clk, sig_i => a6, sig_o => a6_pulse );

    -- stretch pulse to two cycles
    a6_stretch: entity work.signal_stretch
    port map (
        clk      => clk,
        n_cycles => x"02",
        sig_i    => a6_pulse,
        sig_o    => a6_pulse_stretch
    );

    t9_stretch: entity work.signal_stretch
    port map (
        clk      => clk,
        n_cycles => x"02",
        sig_i    => pr_kicker_trigger,
        sig_o    => t9_trigger_stretch
    );
   
    safety_stretch: entity work.signal_stretch
    port map (
       clk      => clk,
       n_cycles => x"02",
       sig_i    => safety_clear,
       sig_o    => safety_clear_stretch
    );

    -- this combined signal triggers the flip flop to latch the current state of a6_pulse_stretch, which will be high
    -- if an A6 signal has been received, and will be low for when a T9-based trigger is sent.
    -- the safety_clear signal will arrive when there is no a6_pulse, and can be used re-arm the trigger
    -- in between the 8 subcycles to make sure trigger is always rearmed at beginning of cycle of 8
    latch_t9_armed_state <= a6_pulse_stretch OR t9_trigger_stretch OR safety_clear;
    rearm <= a6_pulse_stretch OR safety_clear_stretch;

    issue_t9: process( clk )
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                reset_fifo          <= '1';
                pr_state            <= idle;
                pr_kicker_trigger   <= '0';
                pr_debug_trigger    <= '0';
                pr_delay_cnt        <= x"00000000";
                pr_width_cnt        <= (others => '0');
                pr_seq_cnt          <= 0;
            else
                reset_fifo          <= '0';
                pr_kicker_trigger   <= nx_kicker_trigger;
                pr_debug_trigger    <= nx_debug_trigger;
                pr_state            <= nx_state;
                pr_delay_cnt        <= nx_delay_cnt;
                pr_width_cnt        <= nx_width_cnt;
                pr_seq_cnt          <= nx_seq_cnt;
            end if;
        end if;
    end process;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_kicker_trigger, pr_delay_cnt, pr_width_cnt, pr_seq_cnt, t9_pulse, t9_armed, enabled, a6_pulse)
    begin
        case pr_state is
            when idle =>
                -- watch for an a6 so that we know we are alive
                nx_seq_cnt          <= 0;
                nx_delay_cnt        <= t9_to_trigger_delays(iSecondCycle)(0) - 5;
                nx_width_cnt        <= t9_trigger_width;
                nx_kicker_trigger   <= '0';
                nx_debug_trigger    <= '0';

                if a6_pulse = '1' and enabled = '1' then
                    nx_state <= monitor_t9;
                else
                    nx_state <= idle;
                end if;

            when monitor_t9 =>
                -- watch for the T93 || T94 signal
                nx_seq_cnt          <=  0;
                nx_delay_cnt        <= t9_to_trigger_delays(iSecondCycle)(0) - 5;
                nx_width_cnt        <= t9_trigger_width;
                nx_kicker_trigger   <= '0';
                nx_debug_trigger    <= '0';

                if enabled = '0' then
                    nx_state <= idle;
                elsif t9_pulse = '1' then
                    nx_state <= transitionToDelay;
                else
                    nx_state <= monitor_t9;
                end if;

            when transitionToDelay =>
                -- if no delay has been set for this sequence, abort and wait for the next T9x signal.  Because we subtract
                -- off the extra cycles in the count, a delay of zero will give a pr_delay_cnt that's negative.  Just need to
                -- check for the status of the highest bit 
                if pr_delay_cnt(pr_delay_cnt'high) = '1' then
                    nx_seq_cnt          <=  0;
                    nx_delay_cnt        <= t9_to_trigger_delays(iSecondCycle)(0) - 5;
                    nx_width_cnt        <= t9_trigger_width;
                    nx_kicker_trigger   <= '0';
                    nx_debug_trigger    <= '0';
                    nx_state            <= monitor_t9;
                else
                -- do the delay count for this sequence
                    nx_seq_cnt          <= pr_seq_cnt + 1;
                    nx_delay_cnt        <= pr_delay_cnt - 1;
                    nx_width_cnt        <= t9_trigger_width;
                    nx_debug_trigger    <= '0';
                    nx_kicker_trigger   <= '0';
                    nx_state            <= delayCount;
                end if;

            when delayCount =>
                -- just count until the time to send this trigger
                nx_seq_cnt          <= pr_seq_cnt;
                nx_width_cnt        <= t9_trigger_width;
                nx_kicker_trigger   <= '0';
                nx_debug_trigger    <= '0';
                if pr_delay_cnt(pr_delay_cnt'high) = '1' then
                    nx_delay_cnt    <= pr_delay_cnt;
                    nx_state        <= transitionToSend;
                else
                    nx_delay_cnt    <= pr_delay_cnt - 1;
                    nx_state        <= delayCount;
                end if;

            when transitionToSend =>
                -- note that we will also start counting the time to the next trigger
                nx_seq_cnt          <= pr_seq_cnt;
                nx_width_cnt        <= pr_width_cnt - 1;  -- this will help get the width correct given that we count to "-1"
                nx_kicker_trigger   <= '0';
                nx_debug_trigger    <= '0';

                if ( pr_seq_cnt < number_triggers) then
                    nx_delay_cnt    <= t9_to_trigger_delays(iSecondCycle)(pr_seq_cnt) - 3;
                else
                    nx_delay_cnt    <= x"1FFFFFFF"; -- this is just a dummy value to avoid errors since we are about to trigger the last cycle
                end if;

                nx_state            <= t9ArmedCheck;


            when t9ArmedCheck =>
                nx_seq_cnt          <= pr_seq_cnt;
                nx_width_cnt        <= pr_width_cnt - 1;  
                nx_kicker_trigger   <= t9_armed;
                nx_debug_trigger    <= '1';
                nx_delay_cnt        <= pr_delay_cnt - 1;
                nx_state            <= sendHold;

            when sendHold =>
                nx_seq_cnt          <= pr_seq_cnt;
                nx_width_cnt        <= pr_width_cnt - 1;  
                nx_kicker_trigger   <= pr_kicker_trigger;
                nx_debug_trigger    <= '1';
                nx_delay_cnt        <= pr_delay_cnt - 1;

                if pr_width_cnt(pr_width_cnt'high) = '1' then
                    if ( pr_seq_cnt < number_triggers) then
                        nx_state    <=  transitionToDelay;
                    else
                        nx_state    <= monitor_t9;
                    end if;
                else
                    nx_state        <= sendHold;
                end if;
        end case;

    end process;

    trigger_out       <= pr_kicker_trigger;
    debug_trigger_out <= pr_debug_trigger;

end architecture behavioral;
