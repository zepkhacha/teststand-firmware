-- This module outputs one pulse with a variable width and delay for every 'trigger_in' input pulse

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.system_package.all;

entity all_pulse_delay_sm is
port (
    clk            : in  std_logic;
    enabled        : in  std_logic_vector(3 downto 0);
    trigger_in     : in  std_logic;
    trig_delay_i   : in  array_4x7bit;
    trig_delay_m   : in  array_4x7bit;
    trig_delay_m2  : in  array_4x7bit;
    trig_delay_o   : in  array_4x7bit;
    pulse_hold     : in  std_logic_vector(3 downto 0);
    trigger_out    : out std_logic;
    pulse_out      : out std_logic_vector(1 downto 0)
);
end all_pulse_delay_sm;

architecture Behavioral of all_pulse_delay_sm is

    type machine_state is (idle, monitor, transitionToDelay, ensure_pulse_latch, delayCountInner, delayCountMiddle, delayCountMiddle2, delayCountOuter, transitionToSend, checkPulse);

    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "0000 0001 0010 0011 0100 0101 0110 0111 1000 1001";

    signal pr_state,        nx_state         : machine_state;
    signal pr_delay_cnt_i,  nx_delay_cnt_i   : std_logic_vector(6 downto 0);
    signal pr_delay_cnt_m,  nx_delay_cnt_m   : std_logic_vector(6 downto 0);
    signal pr_delay_cnt_m2, nx_delay_cnt_m2  : std_logic_vector(6 downto 0);
    signal pr_delay_cnt_o,  nx_delay_cnt_o   : std_logic_vector(6 downto 0);
    signal pr_latch_delay,  nx_latch_delay   : std_logic_vector(3 downto 0);
    -- careful: **_width_cnt is a **signed** counter.  It counts down from 8, and we test when it goes negative to end the loop
    signal pr_width_cnt,    nx_width_cnt     : std_logic_vector(4 downto 0);
    signal pr_pulse_queued, nx_pulse_queued  : std_logic_vector(1 downto 0);
    signal pr_trigger_out,  nx_trigger_out   : std_logic;
    signal second_cycle_index                : std_logic_vector(0 downto 0);
--    attribute mark_debug : string;
--    attribute mark_debug of enabled : signal is "true";
--    attribute mark_debug of trigger_in : signal is "true";
--    attribute mark_debug of trigger_out : signal is "true";
--    attribute mark_debug of pulse_out : signal is "true";
--    attribute mark_debug of pr_state : signal is "true";
--    attribute mark_debug of pr_delay_cnt_i : signal is "true";
--    attribute mark_debug of pr_delay_cnt_m : signal is "true";
--    attribute mark_debug of pr_delay_cnt_m2 : signal is "true";
--    attribute mark_debug of pr_delay_cnt_o : signal is "true";
--    attribute mark_debug of pr_pulse_queued : signal is "true";
--    attribute mark_debug of pr_width_cnt : signal is "true";
--    attribute mark_debug of pr_trigger_out : signal is "true";
--    attribute mark_debug of trig_delay_i : signal is "true";
--    attribute mark_debug of trig_delay_m : signal is "true";


begin

    -- sequential logic
    pr_state_logic: process(clk)
    begin
        if rising_edge(clk) then
            pr_state        <= nx_state;
            pr_pulse_queued <= nx_pulse_queued;

            pr_delay_cnt_i  <= nx_delay_cnt_i;
            pr_delay_cnt_m  <= nx_delay_cnt_m;
            pr_delay_cnt_m2 <= nx_delay_cnt_m2;
            pr_delay_cnt_o  <= nx_delay_cnt_o;

            pr_latch_delay  <= nx_latch_delay;
            pr_width_cnt    <= nx_width_cnt;
            
            pr_trigger_out  <= nx_trigger_out;
        end if;
    end process;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_delay_cnt_i, pr_delay_cnt_m, pr_delay_cnt_m2, pr_delay_cnt_o, pr_width_cnt,
                             enabled,     trigger_in,   trig_delay_i,    trig_delay_m,  trig_delay_m2, trig_delay_o,
                             pr_pulse_queued,  pr_trigger_out, pr_latch_delay)
    begin
        case pr_state is
            when idle =>

            	nx_pulse_queued  <= (others => '0');

                nx_delay_cnt_i   <= (others => '0');
                nx_delay_cnt_m   <= (others => '0');
                nx_delay_cnt_m2  <= (others => '0');
                nx_delay_cnt_o   <= (others => '0');

                nx_width_cnt     <= '0' & pulse_hold;
                nx_latch_delay   <= "1000";
                nx_trigger_out   <= '0';

             	-- the first pulse must be enabled for anything to happen
                if enabled(0) = '1' then
                    nx_state <= monitor;
                else
                    nx_state <= idle;
                end if;

            when monitor =>

            	nx_pulse_queued  <= pr_pulse_queued;

                nx_delay_cnt_i   <= (others => '0');
                nx_delay_cnt_m   <= (others => '0');
                nx_delay_cnt_m2  <= (others => '0');
                nx_delay_cnt_o   <= (others => '0');

                nx_width_cnt     <= '0' & pulse_hold;
                nx_latch_delay   <= "1000";

                nx_trigger_out <= '0';
                if trigger_in = '1' then
                    nx_state <= transitionToDelay;
                else
                    nx_state <= monitor;
                end if;

            -- In principle, we count from N-2 to -1.  In practice, we adjust for these extra transition / check cycles
            when transitionToDelay =>
            	nx_pulse_queued <= pr_pulse_queued;

                nx_delay_cnt_i  <=  trig_delay_i(to_integer(unsigned(pr_pulse_queued)));
                nx_delay_cnt_m  <=  trig_delay_m(to_integer(unsigned(pr_pulse_queued)));
                nx_delay_cnt_m2 <= trig_delay_m2(to_integer(unsigned(pr_pulse_queued)));
                nx_delay_cnt_o  <=  trig_delay_o(to_integer(unsigned(pr_pulse_queued)));

                nx_width_cnt    <= '0' & pulse_hold;
                nx_latch_delay   <= "1000";

                nx_trigger_out  <= '0';
                if  enabled(to_integer(unsigned(pr_pulse_queued))) = '1' then
 	           		nx_state    <= ensure_pulse_latch;
 	           	else
 	           		nx_state    <= checkPulse;
 	           	end if;

            when ensure_pulse_latch =>
                nx_pulse_queued <= pr_pulse_queued;

                nx_delay_cnt_i  <=  trig_delay_i(to_integer(unsigned(pr_pulse_queued)));
                nx_delay_cnt_m  <=  trig_delay_m(to_integer(unsigned(pr_pulse_queued)));
                nx_delay_cnt_m2 <= trig_delay_m2(to_integer(unsigned(pr_pulse_queued)));
                nx_delay_cnt_o  <=  trig_delay_o(to_integer(unsigned(pr_pulse_queued)));
                nx_width_cnt    <= '0' & pulse_hold;
                nx_latch_delay  <= "0" & pr_latch_delay(3 downto 1);

                nx_trigger_out <= '0';
                if pr_latch_delay(0) = '1' then
                    nx_state    <= delayCountInner;
                else
                    nx_state    <= ensure_pulse_latch;
                end if;

            when delayCountInner =>
            	nx_pulse_queued <= pr_pulse_queued;

                nx_delay_cnt_i  <= pr_delay_cnt_i - 1;
                nx_delay_cnt_m  <= pr_delay_cnt_m;   
                nx_delay_cnt_m2 <= pr_delay_cnt_m2;   
                nx_delay_cnt_o  <= pr_delay_cnt_o;

                nx_latch_delay   <= "1000";
                nx_width_cnt     <= '0' & pulse_hold;

                nx_trigger_out <= '0';
                if pr_delay_cnt_i(pr_delay_cnt_i'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    nx_state <= delayCountMiddle;
                else
                    nx_state <= delayCountInner;
                end if;

            when delayCountMiddle =>
            	nx_pulse_queued <= pr_pulse_queued;

                -- - inner loop gets reset to 0x3D, for N-1 counting and one extra state per middle counter
                nx_delay_cnt_i  <= "0111101";
                nx_delay_cnt_m  <= pr_delay_cnt_m - 1;   
                nx_delay_cnt_m2 <= pr_delay_cnt_m2;   
                nx_delay_cnt_o  <= pr_delay_cnt_o;

                nx_latch_delay   <= "1000";
                nx_width_cnt     <= '0' & pulse_hold;
                
                nx_trigger_out <= '0';
                if pr_delay_cnt_m(pr_delay_cnt_m'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    nx_state <= delayCountMiddle2;
                else
                    nx_state <= delayCountInner;
                end if;

            when delayCountMiddle2 =>
            	nx_pulse_queued <= pr_pulse_queued;

                -- - inner loop gets reset to 0x3D, for N-1 counting and two extra states per 2nd middle counter
                -- - middle loop gets set to 0x3E,  for N-1 counting
                nx_delay_cnt_i  <= "0111100";
                nx_delay_cnt_m  <= "0111110";   
                nx_delay_cnt_m2 <= pr_delay_cnt_m2 - 1;   
                nx_delay_cnt_o  <= pr_delay_cnt_o;

                nx_latch_delay   <= "1000";
                nx_width_cnt     <= '0' & pulse_hold;
                
                nx_trigger_out <= '0';
                if pr_delay_cnt_m2(pr_delay_cnt_m2'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    nx_state <= delayCountOuter;
                else
                    nx_state <= delayCountInner;
                end if;

            when delayCountOuter =>
            	nx_pulse_queued <= pr_pulse_queued;

                nx_delay_cnt_i  <= "0111011";
                nx_delay_cnt_m  <= "0111110";   
                nx_delay_cnt_m2 <= "0111110";   
                nx_delay_cnt_o  <= pr_delay_cnt_o - 1;

                nx_latch_delay   <= "1000";
                nx_width_cnt     <= '0' & pulse_hold;

                nx_trigger_out <= '0';
                if pr_delay_cnt_o(pr_delay_cnt_o'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    nx_state <= transitionToSend;
                else
                    nx_state <= delayCountInner;
                end if;                                  -- and consume 1 tick in this state every outer loop

            when transitionToSend =>
            	nx_pulse_queued <= pr_pulse_queued;

                nx_latch_delay   <= "1000";
                nx_width_cnt    <= pr_width_cnt - 1;   

                nx_delay_cnt_i  <= (others => '0');
                nx_delay_cnt_m  <= (others => '0');
                nx_delay_cnt_m2 <= (others => '0');
                nx_delay_cnt_o  <= (others => '0');


                nx_trigger_out <= '1';
                if pr_width_cnt(pr_width_cnt'high) = '1' then    -- this looks for the sign bit to turn on, so the comparison only monitors one bit
                    nx_state <= checkPulse;
                else
                    nx_state <= transitionToSend;
                end if;

            when checkPulse =>
            	nx_pulse_queued <= pr_pulse_queued + 1;

                nx_delay_cnt_i  <= (others => '0');
                nx_delay_cnt_m  <= (others => '0');
                nx_delay_cnt_m2 <= (others => '0');
                nx_delay_cnt_o  <= (others => '0');

                nx_latch_delay   <= "1000";
                nx_width_cnt     <= '0' & pulse_hold;

                nx_trigger_out <= pr_trigger_out;
                if pr_pulse_queued = "11" then
	                nx_state <= idle;
	            else
	            	nx_state <= transitionToDelay;
	            end if;


        end case;
    end process;
    
    trigger_out <= pr_trigger_out;
    pulse_out   <= pr_pulse_queued;

end architecture Behavioral;
