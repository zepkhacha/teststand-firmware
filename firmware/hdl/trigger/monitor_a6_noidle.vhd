library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity monitor_a6_noidle is 
port (
    -- ttc clock
    clk                  : in  std_logic; -- 40 MHz
    reset                : in  std_logic;


    -- A6 from accelerator
    a6                   : in  std_logic; 

    -- a6 gap that triggers missing A6 notification
    a6_missing_threshold : in  std_logic_vector(31 downto 0);

    -- status of internal trigger supercycle
    supercycle_active    : in  std_logic;

    -- trigger out
    a6_missing           : out std_logic
);
end monitor_a6_noidle;

architecture behavioral of monitor_a6_noidle is
    type machine_state is (watch_a6, warn_missing, wait_on_supercycle);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,    nx_state   : machine_state;
    signal pr_a6_gap,   nx_a6_gap  : std_logic_vector(31 downto 0);
    signal pr_missing,  nx_missing : std_logic;

    signal a6_pulse : std_logic;

begin

    -- convert input a6 signal to a 1 cycle pulse
    a6_convert: entity work.level_to_pulse port map (clk => clk, sig_i => a6, sig_o => a6_pulse );

    -- reset: zero counter and internal trigger flag, and go back to idle state waiting for a6 input,
    process(clk)
    begin
        if rising_edge(clk) then
            if ( reset = '1') then
                pr_state <= watch_a6;
                pr_a6_gap <= x"00000000";
                pr_missing <= '0';
            else
                pr_state    <= nx_state;
                pr_a6_gap   <= nx_a6_gap;
                pr_missing  <= nx_missing;
            end if;
        end if;
    end process;

    process (pr_state, pr_a6_gap, pr_missing, a6_pulse, a6_missing_threshold, supercycle_active)
    begin
        case pr_state is
            when watch_a6 =>
                nx_missing <= '0';
                -- reset the gap counter if we encounter an A6
                if a6_pulse = '1' then
                    nx_a6_gap <= x"00000000";
                    nx_state  <= watch_a6;

                -- check if we have crossed the missing A6 threshold
                elsif pr_a6_gap > a6_missing_threshold then
                    nx_a6_gap <= pr_a6_gap;
                    nx_state  <= warn_missing;

                -- keep on watching for the next A6
                else
                    nx_a6_gap <= pr_a6_gap + 1;
                    nx_state  <= watch_a6;
                end if;

            when warn_missing =>
                -- we can return to monitoring A6 when they have resumed
                nx_missing <= '1';
                if a6_pulse = '1' then
                    nx_a6_gap  <= x"00000000";
                    nx_state   <= wait_on_supercycle;
                else
                    nx_a6_gap  <= pr_a6_gap;
                    nx_state   <= warn_missing;
                end if;

            when wait_on_supercycle =>
               -- wait until an internal supercycle has finished before sending notice that the A6 signal has returned
               if supercycle_active = '1' then
                    nx_a6_gap  <= x"00000000";
                    nx_state   <= wait_on_supercycle;
                    nx_missing <= '1';
               else
                    nx_a6_gap  <= x"00000000";
                    nx_state   <= watch_a6;
                    nx_missing <= '0';
               end if;

        end case;
    end process;

    a6_missing <= pr_missing;

end architecture behavioral;
