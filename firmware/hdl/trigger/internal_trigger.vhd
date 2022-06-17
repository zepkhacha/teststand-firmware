library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- ------------------------------------
entity internal_trigger is
port (
    clk                    : in  std_logic;   
    enable                 : in  std_logic;  
    two_cycles             : in  std_logic;
    supercycle_period      : in  std_logic_vector(31 downto 0); -- the period of the 16 fill supercycle (~1.2s)
    cycle8_period          : in  std_logic_vector(31 downto 0); -- the fill-to-fill period within a cycle of 8 fills
    cycle8_delay           : in  std_logic_vector(31 downto 0); -- the delay between the T93 (or T94) signal and the start of the A6 triggers
    scnd_cycle8_gap        : in  std_logic_vector(31 downto 0); -- the gap from the last A6 in the first cycle of 8 and the T94 signal of the next
    t9_signal              : out std_logic;
    a_six_signal           : out std_logic;
    supercycle_in_progress : out std_logic;
    cycle8_active          : out std_logic;
    internal_trigger_boc   : out std_logic
);
end internal_trigger;
-- -----------------------------------------------------------------
architecture behavioural of internal_trigger is
    type machine_state is (idle, issue_t9, cycle_delay, launch_cycle, watch_cycle_start, monitor_cycle, cycle_gap);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "000 001 010 011 100 101 110";

    signal pr_state,         nx_state           : machine_state;
    signal pr_delay,         nx_delay           : std_logic_vector(32 downto 0);
    signal pr_cycle_trig,    nx_cycle_trig      : std_logic;
    signal pr_t9,            nx_t9              : std_logic;
    signal pr_another_cycle, nx_another_cycle   : std_logic;

    signal pr_supercycle_active, nx_supercycle_active : std_logic;

    signal trigger_supercycle : std_logic;
    signal cycle_active       : std_logic;
    signal delay32, gap32     : std_logic_vector(32 downto 0);
    signal supercycle_inactive, supercycle_end_pulse : std_logic;
    signal mark_supercycle    : std_logic;

--    attribute mark_debug of pr_state             : signal is "true";
--    attribute mark_debug of pr_delay             : signal is "true";
--    attribute mark_debug of pr_t9                : signal is "true";
--    attribute mark_debug of pr_cycle_trig        : signal is "true";
--    attribute mark_debug of pr_another_cycle     : signal is "true";
--    attribute mark_debug of pr_supercycle_active : signal is "true";
--    attribute mark_debug of trigger_supercycle   : signal is "true";
--    attribute mark_debug of cycle_active         : signal is "true";
--    attribute mark_debug of delay32              : signal is "true";
--    attribute mark_debug of gap32                : signal is "true";
--    attribute mark_debug of enable               : signal is "true";
--    attribute mark_debug of two_cycles           : signal is "true";
--    attribute mark_debug of supercycle_inactive  : signal is "true";
--    attribute mark_debug of supercycle_end_pulse : signal is "true";
--    attribute mark_debug of mark_supercycle      : signal is "true";

begin
-- -------------- sequential logic --------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            pr_state              <= nx_state;
            pr_delay              <= nx_delay;
            pr_t9                 <= nx_t9;
            pr_cycle_trig         <= nx_cycle_trig;
            pr_supercycle_active  <= nx_supercycle_active;
            pr_another_cycle      <= nx_another_cycle;
        end if;
    end process;

    delay32 <= '0' & cycle8_delay;
    gap32   <= '0' & scnd_cycle8_gap;

    supercycle_triggering : entity work.generic_counter
    port map (
        clk         => clk,
        rst         => enable,
        start_value => supercycle_period,
        notify      => trigger_supercycle
    );

    cycle_of_8 : entity work.generate_cycle8
    port map (
        clk    => clk,
        start  => pr_cycle_trig,
        period => cycle8_period,
        asix   => a_six_signal,
        active => cycle_active
    );

    supercycle_inactive <= not pr_supercycle_active;
    supercycle_end: entity work.level_to_pulse
    port map (
        clk => clk,
        sig_i => supercycle_inactive,
        sig_o => supercycle_end_pulse
    );

    -- wait a bit after the supercyle ends before issuing the BOC pulse
    boc_delay: entity work.pulse_delay
    generic map ( nbr_bits => 8)
    port map (
        clock     => clk,
        delay     => x"c8", -- 200 25 ns clock ticks = 5 microseconds
        pulse_in  => supercycle_end_pulse,
        pulse_out => mark_supercycle
    );

-- -------------- combinational logic -----------------------------
    process (pr_state, pr_delay, pr_t9, pr_cycle_trig, pr_another_cycle, trigger_supercycle, cycle_active, two_cycles)
    begin
        case pr_state is
            when idle =>
                nx_delay              <= delay32 - 5;
                nx_t9                 <= '0';
                nx_cycle_trig         <= '0';
                nx_supercycle_active  <= '0';
                nx_another_cycle      <= two_cycles;

                if trigger_supercycle = '0' then
                    nx_state <= idle; 
                else
                    nx_state <= issue_t9;
                end if;

            when issue_t9 =>
                nx_delay              <= delay32 - 5;
                nx_t9                 <= '1';
                nx_cycle_trig         <= '0';
                nx_supercycle_active  <= '1';
                nx_another_cycle      <= pr_another_cycle;

                nx_state <= cycle_delay;

            when cycle_delay =>
                nx_delay             <= pr_delay - 1;
                nx_t9                <= '0';
                nx_cycle_trig        <= '0';
                nx_supercycle_active <= '1';
                nx_another_cycle     <= pr_another_cycle;

                if pr_delay(pr_delay'high) = '1' then
                    nx_state <= launch_cycle;
                else
                    nx_state <= cycle_delay;
                end if;

            when launch_cycle =>
                nx_delay             <= pr_delay;
                nx_t9                <= '0';
                nx_cycle_trig        <= '1';
                nx_supercycle_active <= '1';
                nx_another_cycle     <= pr_another_cycle;

                nx_state <= watch_cycle_start;

            when watch_cycle_start =>
                nx_delay              <= gap32 - 5;
                nx_t9                 <= '0';
                nx_cycle_trig         <= '0';
                nx_supercycle_active  <= '1';
                nx_another_cycle      <= pr_another_cycle;

                if cycle_active = '1' then
                    nx_state <= monitor_cycle;
                else
                    nx_state <= watch_cycle_start;
                end if;

            when monitor_cycle =>
                nx_delay              <= pr_delay;
                nx_t9                 <= '0';
                nx_cycle_trig         <= '0';
                nx_supercycle_active  <= '1';
                nx_another_cycle      <= pr_another_cycle;

                if cycle_active = '1' then
                    nx_state <= monitor_cycle;
                elsif pr_another_cycle = '1' then
                    nx_state <= cycle_gap;
                else
                    nx_state <= idle;
                end if;

            when cycle_gap =>
                nx_delay             <= pr_delay - 1;
                nx_cycle_trig        <= '0';
                nx_supercycle_active <= '1';
                nx_another_cycle     <= '0';
                nx_t9                <= '0';

                if pr_delay(pr_delay'high) = '1' then
                    nx_state <= issue_t9;
                else
                    nx_state <= cycle_gap;
                end if;

        end case;
    end process;

    t9_signal              <= pr_t9;
    supercycle_in_progress <= pr_supercycle_active;
    cycle8_active          <= cycle_active;
    internal_trigger_boc   <= mark_supercycle;

end architecture behavioural;
