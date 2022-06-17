library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- ------------------------------------
entity generic_counter is
port (
    clk         : in  std_logic;   
    rst         : in  std_logic;  
    start_value : in  std_logic_vector(31 downto 0);
    notify  : out std_logic
);
end generic_counter;
-- -----------------------------------------------------------------
architecture behavioural of generic_counter is
    type machine_state is (starting, counting, notifying);
    attribute ENUM_ENCODING                  : string;
    attribute ENUM_ENCODING of machine_state : type is "00 01 10";
    signal pr_state, nx_state                : machine_state;
    signal pr_counter, nx_counter            : std_logic_vector(32 downto 0);
    signal pr_notify, nx_notify              : std_logic;
begin
-- -------------- sequential logic --------------------------------
   process (clk)
   begin
       if rising_edge(clk) then
          pr_state   <= nx_state;
          pr_counter <= nx_counter;
          pr_notify  <= nx_notify;
       end if;
   end process;

   -------------- combinational logic -----------------------------
    process (pr_state, pr_counter, pr_notify, rst, start_value)
    begin
        case pr_state is
            when starting => 
                nx_notify <= '0';
                nx_counter(31 downto 0) <= start_value;
                nx_counter(32) <= '0';
                if (rst = '1') then
                    nx_state <= counting;
                else
                    nx_state <= starting;
                end if;

            when counting =>
                nx_notify   <= '0';
                nx_counter <= pr_counter - 1;
                if pr_counter(pr_counter'high) = '1' then
                    nx_state <= notifying;
                else
                    nx_state <= counting;
                end if;

            when notifying =>
                nx_notify   <= '1';
                nx_counter <= pr_counter;
                nx_state   <= starting;

        end case;	      
   end process;

   notify <= pr_notify;

end architecture behavioural;

