-- This module doubles the length of the ttc analog trigger width for muon fill triggers.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ttc_analog_width is
port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    ttc_valid       : in  std_logic;
    ttc_trggr       : in  std_logic;
    ttc_cmd         : in  std_logic_vector( 7 downto 2);
    width_in        : in  std_logic_vector( 7 downto 0);
    width_out       : out std_logic_vector( 9 downto 0)
);
end ttc_analog_width;

architecture Behavioral of ttc_analog_width is

    type machine_task is (watch_valid, watch_ttc_trggr, set_width );

    attribute ENUM_ENCODING                 : string;
    attribute ENUM_ENCODING of machine_task : type is "00 01 10";

    signal pr_state, nx_state     : machine_task;
    signal pr_trigB, nx_trigB     : std_logic_vector( 4 downto 0);
    signal pr_width, nx_width     : std_logic_vector( 9 downto 0);
    signal large_width            : std_logic_vector( 9 downto 0);

    -- attribute mark_debug : string;
    -- attribute mark_debug of ttc_valid : signal is "true";
    -- attribute mark_debug of ttc_trggr : signal is "true";
    -- attribute mark_debug of ttc_cmd   : signal is "true";
    -- attribute mark_debug of width_in  : signal is "true";
    -- attribute mark_debug of width_out : signal is "true";
    -- attribute mark_debug of pr_state  : signal is "true";
    -- attribute mark_debug of pr_width  : signal is "true";
    -- attribute mark_debug of pr_trigB  : signal is "true";

begin

    -- sequential logic
    pr_state_logic: process(clk)
    begin
        if ( reset = '1' ) then
            pr_state <= watch_valid;
            pr_width <= "00" & width_in;
            pr_trigB <= "00000";
        elsif rising_edge(clk) then
            pr_state <= nx_state;
            pr_width <= nx_width;
            pr_trigB <= nx_trigB;
        end if;
    end process;

    large_width <= "00" & width_in;

    -- combinational logic
    nx_state_logic: process(pr_state, pr_width, pr_trigB, ttc_valid, ttc_cmd, ttc_trggr, width_in)
    begin
        case pr_state is
            when watch_valid =>
                nx_width <= pr_width;
                if ttc_valid = '1' and ttc_cmd(2) = '1' then
                   nx_state <= watch_ttc_trggr;
                   nx_trigB <= ttc_cmd(7 downto 3);
                else
                   nx_state <= watch_valid;
                   nx_trigB <= pr_trigB;
                end if;

            when watch_ttc_trggr =>
                nx_width <= pr_width;
                nx_trigB <= pr_trigB;
                if ttc_trggr = '1' then
                   nx_state <= set_width;
                else
                   nx_state <= watch_ttc_trggr;
                end if;

            when set_width =>
                nx_state <= watch_valid;
                nx_trigB <= pr_trigB;
                if  pr_trigB = "00001" then
                    nx_width <= width_in & "11";
                else
                    nx_width <= large_width;
                end if;

        end case;
    end process;

    width_out <= pr_width;

end architecture Behavioral;
