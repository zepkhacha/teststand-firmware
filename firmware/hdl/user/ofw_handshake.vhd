
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ofw_handshake is
port (
   clock         : in  std_logic;                             -- input clock
   reset         : in  std_logic;
   overflow      : in  std_logic;                             -- overflow has been detected
   basic_width   : in  std_logic_vector(7 downto 0);          -- width of the boc
   ofw_hshake    : out std_logic;
   ofw_latch     : out std_logic
);
end entity ofw_handshake;

architecture Behavioral of ofw_handshake is
   type machine_state is (watch_ofw, trig_strt, watch_clr, trig_stop);
   attribute ENUM_ENCODING                  : string;
   attribute ENUM_ENCODING of machine_state : type is "00 01 10 11";

   signal pr_state,    nx_state   : machine_state;
   signal pr_width,    nx_width   : std_logic_vector(10 downto 0);
   signal pr_trig,     nx_trig    : std_logic;
   signal pr_latch,    nx_latch   : std_logic;

   signal ofw_strt,    ofw_stop   : std_logic_vector(10 downto 0);

--   -- debugs
--   attribute mark_debug : string;
--   attribute mark_debug of pulse_in         : signal is "true";

begin

    ofw_strt <= '0' & basic_width(7 downto 0) & "00";
    ofw_stop <=       basic_width(7 downto 0) & "000";

    process(clock)
    begin
        if reset = '1' then
            pr_state <= watch_ofw;
            pr_width <= ofw_strt;
            pr_trig  <= '0';
            pr_latch <= '0';
        elsif rising_edge(clock) then
            pr_state <= nx_state;
            pr_width <= nx_width;
            pr_trig  <= nx_trig;
            pr_latch <= nx_latch;
        end if;
    end process;

    generate_handshake: entity work.signal_stretch
    generic map (nbr_bits => 11)
    port map (
        clk      => clock,
        n_cycles => pr_width,
        sig_i    => pr_trig,
        sig_o    => ofw_hshake
    );
    ofw_latch <= pr_latch;

    process (pr_state, pr_width, pr_trig, overflow)
    begin
        case pr_state is
            when watch_ofw =>
                nx_width  <= pr_width;
                nx_trig   <= '0';
                if ( overflow = '1' ) then
                    nx_state <= trig_strt;
                    nx_latch <= '1';
                else
                    nx_state <= watch_ofw;
                    nx_latch <= pr_latch;
                end if;

            when trig_strt =>
                nx_width  <= ofw_strt;
                nx_trig   <= '1';
                nx_state <= watch_clr;
                nx_latch <= pr_latch;

           when watch_clr =>
                nx_width  <= pr_width;
                nx_trig   <= '0';
                nx_latch <= pr_latch;
                if ( overflow = '0' ) then
                    nx_state <= trig_stop;
                else
                    nx_state <= watch_clr;
                end if;

            when trig_stop =>
                nx_width  <= ofw_stop;
                nx_trig   <= '1';
                nx_state <= watch_ofw;
                nx_latch <= pr_latch;

        end case;
    end process;

end architecture Behavioral;
