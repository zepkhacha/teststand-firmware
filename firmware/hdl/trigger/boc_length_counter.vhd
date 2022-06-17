
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity boc_length_counter is
port (
    clock           : in  std_logic;                             -- input clock
    reset           : in  std_logic;
    pulse_in        : in  std_logic;                             -- input pulse
    base_boc_length : in  std_logic_vector(7 downto 0);
    boc_out         : out std_logic;                             -- real boc output pulse
    throttle        : out std_logic
);
end entity boc_length_counter;

architecture Behavioral of boc_length_counter is
    type machine_state is (watch, count, evaluate);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,    nx_state    : machine_state;
    signal pr_count,    nx_count    : std_logic_vector(31 downto 0);
    signal pr_throttle, nx_throttle : std_logic;
    signal pr_boc,      nx_boc      : std_logic;

    signal throttle_strt_bdry : std_logic_vector( 10 downto 0 );
    signal throttle_stop_bdry : std_logic_vector( 10 downto 0 );

--    -- debugs
--   attribute mark_debug : string;
--   attribute mark_debug of pulse_in         : signal is "true";

begin

    throttle_strt_bdry <= '0' & base_boc_length(7 downto 0) & "00";
    throttle_stop_bdry <=       base_boc_length(7 downto 0) & "000" ;

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                pr_state    <= watch;
                pr_count    <= (others => '0');
                pr_throttle <= '0';
                pr_boc      <= '0';
            else
                pr_state    <= nx_state;
                pr_count    <= nx_count;
                pr_throttle <= nx_throttle;
                pr_boc      <= nx_boc;
            end if;
        end if;
    end process;

    process (pr_state, pr_count, pulse_in, throttle_strt_bdry, throttle_stop_bdry)
    begin
        case pr_state is
            when watch =>
                nx_count    <= ( others => '0');
                nx_throttle <= pr_throttle;
                nx_boc      <= '0';
                if pulse_in = '1' then
                    nx_state <= count;
                else
                    nx_state <= watch;
                end if;

            when count =>
                nx_count    <= pr_count + 1;
                nx_throttle <= pr_throttle;
                nx_boc      <= '0';

                if pulse_in = '1' then
                    nx_state <= count;
                else
                    nx_state <= evaluate;
                end if;

            when evaluate =>
                nx_count <= pr_count;
                nx_state <= watch;
                if unsigned(pr_count) < unsigned(throttle_strt_bdry) then
                    nx_throttle <= pr_throttle;
                    nx_boc      <= '1';
                elsif unsigned(pr_count) < unsigned(throttle_stop_bdry) then
                    nx_throttle <= '1';
                    nx_boc      <= '0';
                else
                    nx_throttle <= '0';
                    nx_boc      <= '0';
                end if;

        end case;
    end process;

    generate_boc: entity work.signal_stretch
    generic map (nbr_bits => 8)
    port map (
        clk      => clock,
        n_cycles => base_boc_length,
        sig_i    => pr_boc,
        sig_o    => boc_out
    );
    throttle <= pr_throttle;

end architecture Behavioral;
