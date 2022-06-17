-- This module counts the trigger sequencer index.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity counter_sm is
generic (
    n : positive := 3
);
port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    trigger_in      : in  std_logic;
    cycle_start     : in  std_logic;
    penultimate_seq : in  std_logic;
    seq_index       : out std_logic_vector(n-1 downto 0)
);
end counter_sm;

architecture Behavioral of counter_sm is

    type machine_task is (idle, clear, monitor, count, check);

    attribute ENUM_ENCODING                 : string;
    attribute ENUM_ENCODING of machine_task : type is "000 001 010 011 100";

    signal pr_state,       nx_state       : machine_task;
    signal pr_cycle_latch, nx_cycle_latch : std_logic;
    signal pr_queued_seq,  nx_queued_seq  : std_logic_vector(n-1 downto 0);
    signal pr_seq_index,   nx_seq_index   : std_logic_vector(n-1 downto 0);

    -- debugs
--    attribute keep : boolean;
--    attribute keep of pr_state       : signal is true;
--    attribute keep of pr_queued_seq  : signal is true;
--    attribute keep of pr_seq_index   : signal is true;
--    attribute keep of pr_cycle_latch : signal is true;
--    attribute keep of trigger_in     : signal is true;
--    attribute keep of cycle_start    : signal is true;
--    attribute keep of reset          : signal is true;
--
--    attribute mark_debug : string;
--    attribute mark_debug of pr_state       : signal is "true";
--    attribute mark_debug of pr_queued_seq  : signal is "true";
--    attribute mark_debug of pr_seq_index   : signal is "true";
--    attribute mark_debug of pr_cycle_latch : signal is "true";
--    attribute mark_debug of trigger_in     : signal is "true";
--    attribute mark_debug of cycle_start    : signal is "true";
--    attribute mark_debug of reset          : signal is "true";

begin

    -- sequential logic
    pr_state_logic: process(clk)
    begin
        if rising_edge(clk) then
            if ( reset = '1' ) then
                pr_state       <= idle;
                pr_seq_index   <= (others => '0');
                pr_queued_seq  <= (others => '0');
                pr_cycle_latch <= '0';
            else
                pr_state       <= nx_state;
                pr_queued_seq  <= nx_queued_seq;
                pr_seq_index   <= nx_seq_index;
                pr_cycle_latch <= nx_cycle_latch;
            end if;
        end if;
    end process;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_seq_index, pr_cycle_latch, pr_queued_seq, trigger_in, cycle_start, penultimate_seq)
    begin
        case pr_state is
            when idle =>
                nx_seq_index   <= pr_seq_index;
                nx_queued_seq  <= (others => '0');
                nx_cycle_latch <= pr_cycle_latch or cycle_start;
                if pr_cycle_latch = '1' then
                    nx_state <= clear;
                else
                    nx_state <= idle;
                end if;

            when clear =>
                nx_seq_index   <= pr_seq_index;
                nx_queued_seq  <= (others => '0');
                nx_cycle_latch <= '0';
                nx_state       <= monitor;

            when monitor =>
                nx_queued_seq  <= pr_queued_seq;
                nx_cycle_latch <= pr_cycle_latch or cycle_start;
                if trigger_in = '1' then
                    nx_state <= count;
                    nx_seq_index <= pr_queued_seq;
                else
                    nx_state <= monitor;
                    nx_seq_index   <= pr_seq_index;
                end if;

            when count =>
                nx_seq_index   <= pr_seq_index;
                nx_queued_seq  <= pr_queued_seq  + 1;
                nx_cycle_latch <= pr_cycle_latch or cycle_start;
                nx_state       <= check;

            when check =>
                nx_seq_index   <= pr_seq_index;
                nx_queued_seq  <= pr_queued_seq;
                nx_cycle_latch <= pr_cycle_latch or cycle_start;
                -- the penultimate flag appears a few cycles of delay after the penultimate trigger has been received
                -- and will be cleared a few cycles after the last trigger in the cycle is received.  That means that
                -- the flag should be high when the last trigger of the cycle is received, but at no other time.
                if penultimate_seq = '1' then
                    nx_state <= idle;
                else
                    nx_state <= monitor;
                end if;
        end case;
    end process;

    seq_index <= pr_seq_index;

end architecture Behavioral;
