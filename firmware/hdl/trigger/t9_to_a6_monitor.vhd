library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity t9_to_a6_monitor is 
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz
    reset                : in  std_logic; -- recommend that this be the ttc reset at start of run?


    -- signals from accelerator
    t9                   : in  std_logic;   -- from nim-logic-level lemo input on EDA-02708
    a6                   : in  std_logic; 

    -- ideal gap that we would like between t9 and a6 for inclusion in average
    ideal_t9_to_a6_gap   : in  std_logic_vector(31 downto 0);

    -- maximum gap that we allow between t9 and a6 for inclusion in average
    max_t9_to_a6_gap     : in  std_logic_vector(31 downto 0);

    -- trigger out
    t9_correction        : out std_logic_vector(31 downto 0);
    correction_valid     : out std_logic
);
end t9_to_a6_monitor;

architecture behavioral of t9_to_a6_monitor is
    type machine_state is (idle, watch_t9, watch_a6, update_sum, round_sum, update);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "000 001 010 011 100 101";

    signal pr_state,     nx_state     : machine_state;
    signal pr_t9_a6_gap, nx_t9_a6_gap : std_logic_vector(31 downto 0);
    signal pr_sum,       nx_sum       : std_logic_vector(31 downto 0);
    signal pr_buffered,  nx_buffered  : integer range 0 to  4;
    signal pr_valid,     nx_valid     : std_logic;
    signal pr_average,   nx_average   : std_logic_vector(31 downto 0);
    signal pr_shiftbuf,  nx_shiftbuf  : std_logic_vector(127 downto 0);

    -- type miniBuffer is array (0 to 3) of std_logic_vector(31 downto 0);
    -- signal pr_gapBuffer, nx_gapbuffer : miniBuffer;

    signal a6_pulse, t9_pulse         : std_logic;
    signal correction                 : std_logic_vector( 31 downto 0);
    signal correction_offset          : std_logic_vector( 31 downto 0);
    signal obsoleteGap                : std_logic_vector( 31 downto 0);

--    attribute mark_debug : string;
--    attribute mark_debug of pr_state       : signal is "true";
--    attribute mark_debug of pr_t9_a6_gap   : signal is "true";
--    attribute mark_debug of pr_sum         : signal is "true";
--    attribute mark_debug of pr_buffered    : signal is "true";
--    attribute mark_debug of pr_valid       : signal is "true";
--    attribute mark_debug of pr_average     : signal is "true";
--    attribute mark_debug of correction     : signal is "true";
--    attribute mark_debug of obsoleteGap    : signal is "true";


begin

    -- convert input t9 and a6 signals to 1 cycle pulses
    a6_convert: entity work.level_to_pulse port map (clk => clk, sig_i => a6, sig_o => a6_pulse );
    t9_convert: entity work.level_to_pulse port map (clk => clk, sig_i => t9, sig_o => t9_pulse );

    -- this is the oldest contribution to the running gap sum that we want to subtract
    obsoleteGap <= pr_shiftbuf(31 downto 0);

    -- extra cycles in the delay logic and gap counting lead overall to a correction that is off by one.
    -- the corrections to the ideal gap corrects for that factor
    correction_offset <= ideal_t9_to_a6_gap + 1;

    process( clk )
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state     <= idle;
                pr_sum       <= x"00000000";
                pr_t9_a6_gap <= x"00000000";
                pr_buffered  <= 0;
                pr_valid     <= '0';
                pr_average   <= x"00000000";
                pr_shiftbuf  <= (others => '0');
            else
                pr_state     <= nx_state;
                pr_sum       <= nx_sum;
                pr_t9_a6_gap <= nx_t9_a6_gap;
                pr_buffered  <= nx_buffered;
                pr_average   <= nx_average;
                pr_valid     <= nx_valid;
                pr_shiftbuf  <= nx_shiftbuf;
            end if;
        end if;
    end process;

    process( pr_state, pr_t9_a6_gap, pr_sum, pr_buffered, pr_valid, pr_shiftbuf, pr_average, t9_pulse, a6_pulse, max_t9_to_a6_gap )
    begin
        case pr_state is
            when idle =>
                nx_sum       <= pr_sum;
                nx_t9_a6_gap <= x"00000000";
                nx_buffered  <= pr_buffered;
                nx_valid     <= pr_valid;
                nx_average   <= pr_average;
                nx_shiftbuf  <= pr_shiftbuf;
                -- watch for an a6 from the accelerator complex so that we know we are alive before we start processing gaps
                if a6_pulse = '1' then
                    nx_state <= watch_t9;
                else
                    nx_state <= idle;
                end if;

            when watch_t9 =>
                nx_sum       <= pr_sum;
                nx_t9_a6_gap <= x"00000000";
                nx_buffered  <= pr_buffered;
                nx_valid     <= pr_valid;
                nx_average   <= pr_average;
                nx_shiftbuf  <= pr_shiftbuf;
                -- watch for an t9 from the accelerator complex, and then we will start measuring the gap to the first a6
                if t9_pulse = '1' then
                    nx_state <= watch_a6;
                else
                    nx_state <= watch_t9;
                end if;

            when watch_a6 =>
                nx_sum       <= pr_sum;
                nx_buffered  <= pr_buffered;
                nx_valid     <= pr_valid;
                nx_average   <= pr_average;
                nx_shiftbuf  <= pr_shiftbuf;

                -- check that we haven't waited too long for the first a6 to arrive.  If we have, go back to watching for a t9
                if ( pr_t9_a6_gap > max_t9_to_a6_gap ) then
                    nx_t9_a6_gap <= x"00000000";
                    nx_state     <= watch_t9;

                -- if we've found an a6 pulse, start processing this gap
                elsif a6_pulse = '1' then
                    nx_t9_a6_gap <= pr_t9_a6_gap;
                    nx_state     <= update_sum;

                -- otherwise, update counter and continue watching
                else
                    nx_t9_a6_gap <= pr_t9_a6_gap + 1;
                    nx_state <= watch_a6;
                end if;

            when update_sum =>
                nx_t9_a6_gap <= pr_t9_a6_gap ;
                nx_sum       <= pr_sum + pr_t9_a6_gap - obsoleteGap; -- this logic requires that gapBuffer be suitably initialized to zero before accumulating data
                nx_buffered  <= pr_buffered;
                nx_valid     <= pr_valid;
                nx_state     <= round_sum;
                nx_average   <= pr_average;
                nx_shiftbuf  <= pr_t9_a6_gap & pr_shiftbuf(127 downto 32);  -- this will push pr_t9_a6_gap onto the buffer next cycle

            when round_sum =>
                nx_t9_a6_gap <= pr_t9_a6_gap;
                nx_sum       <= pr_sum + "11"; -- round rather than truncate in the update state
                nx_valid     <= pr_valid;
                nx_state     <= update;
                nx_average   <= pr_average;
                nx_shiftbuf  <= pr_shiftbuf;
                if ( pr_buffered < 4 ) then
                    nx_buffered <= pr_buffered + 1;
                else
                    nx_buffered <= pr_buffered;
                end if;

            when update =>
                nx_t9_a6_gap <= pr_t9_a6_gap;
                nx_sum       <= pr_sum - "11"; -- undo the rounding so that we don't accumulate this offset
                nx_buffered  <= pr_buffered;
                nx_state     <= watch_t9;
                nx_shiftbuf  <= pr_shiftbuf;

                -- check that we have enough samples for a valid average
                if ( pr_buffered < 4 ) then
                    nx_valid <= '0';
                else
                    nx_valid <= '1';
                end if;

                -- shift the sum to calculate the average, adding the "11" so that we round rather than truncate
--                nx_average   <= (pr_sum + "11") srl 2;
                nx_average   <= "00" & pr_sum(31 downto 2); -- try truncation and see if that synthesizes
        end case;
    end process;

    process( pr_average, ideal_t9_to_a6_gap )
    begin
        if pr_average > ideal_t9_to_a6_gap then
            correction <= pr_average - correction_offset;
        else
            correction <= x"00000000";
        end if;
    end process;

    t9_correction     <= correction;
    correction_valid  <= pr_valid;

end architecture behavioral;
