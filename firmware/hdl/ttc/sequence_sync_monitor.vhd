
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity sequence_sync_monitor is
port (
    clock         : in  std_logic;                             -- input clock
    reset         : in  std_logic;
    boc_in        : in  std_logic;                             -- begin_of_supercycle
    a6_in         : in  std_logic;                             -- a6 input
    minimum_gap   : in  std_logic_vector(31 downto 0);         -- if an A6 appears within this number of cycles after a boc, boc is oout of sync
    out_of_seq    : out std_logic
);
end entity sequence_sync_monitor;

architecture Behavioral of sequence_sync_monitor is
    type machine_state is (watch_boc, watch_a6, maintain);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";

    signal pr_state,    nx_state   : machine_state;
    signal pr_count,    nx_count   : std_logic_vector(32 downto 0);
    signal pr_oos,      nx_oos     : std_logic;

--   -- debugs
--    attribute mark_debug : string;
--    attribute mark_debug of boc_in         : signal is "true";

begin

    process(clock)
    begin
        if reset = '1' then
            pr_state <= watch_boc;
            pr_count <= '0' & minimum_gap;
            pr_oos   <= '0';
        elsif rising_edge(clock) then
            pr_state <= nx_state;
            pr_count <= nx_count;
            pr_oos   <= nx_oos;
        end if;
    end process;

    process (pr_state, pr_count, pr_oos, boc_in, a6_in)
    begin
        case pr_state is
            when watch_boc =>
                nx_count  <= '0' & minimum_gap;
                nx_oos    <= '0';
                if ( boc_in = '1' ) then
                    nx_state <= watch_a6;
                else
                    nx_state <= watch_boc;
                end if;

            when watch_a6 =>
                nx_count <= pr_count - 1;
                -- we've gone past the min gap without seeing an a6 -- all good
                if pr_count(pr_count'high) = '1' then
                   nx_oos   <= '0';
                   nx_state <= watch_boc;

                -- we see an a6 within a time that means the boc must have been issued within a cycle of 16 -> assert out_of_sequence
                elsif a6_in = '1' then
                   nx_oos   <= '1';
                   nx_state <= maintain;

                -- otherwise keep watching and counting
                else
                   nx_oos   <= '0';
                   nx_state <= watch_a6;
                end if;

           when maintain =>
                nx_oos   <= '1';
                nx_state <= watch_boc;
                nx_count <= pr_count;

        end case;
    end process;

    out_of_seq <= pr_oos;

end architecture Behavioral;
