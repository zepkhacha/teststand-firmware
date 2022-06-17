-- The data part of the i2c master

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity i2c_bitwise is
port (
    clk            : in  std_logic;
    reset          : in  std_logic;
    enable         : in  std_logic;
    prescaler      : in  std_logic_vector(9 downto 0);
    startclk       : in  std_logic;
    execstart      : in  std_logic;
    execstop       : in  std_logic;
    execwr         : in  std_logic;
    execgetack     : in  std_logic;
    execrd         : in  std_logic;
    execsendack    : in  std_logic;
    execsendnak    : in  std_logic;
    bytetowrite    : in  std_logic_vector(7 downto 0);
    byteread       : out std_logic_vector(7 downto 0);
    bytereaddv     : out std_logic;
    i2c_bus_select : in  std_logic_vector(2 downto 0);
    completed      : out std_logic;
    failed         : out std_logic;
    scl_i          : in  std_logic_vector(7 downto 0);
    scl_o          : out std_logic_vector(7 downto 0);
    sda_i          : in  std_logic_vector(7 downto 0);
    sda_o          : out std_logic_vector(7 downto 0)
);

end i2c_bitwise;

architecture behave of i2c_bitwise is

    type datafsm_type is (idle, start, stop, writebyte, getack, readbyte, sendack, sendnak);

    signal wrbit  : std_logic;
    signal rdbit  : std_logic;
    signal sclbit : std_logic;

    signal datafsm  : datafsm_type;
    signal enable_d : std_logic;
    signal clkmask  : std_logic;
    signal timer    : std_logic_vector(9 downto 0);

    signal presc_75 : std_logic_vector(9 downto 0);
    signal presc_50 : std_logic_vector(9 downto 0);
    signal presc_25 : std_logic_vector(9 downto 0);

    attribute keep: boolean;
    attribute keep of rdbit  : signal is true;
    attribute keep of wrbit  : signal is true;
    attribute keep of sclbit : signal is true;
    attribute keep of timer  : signal is true;

begin

i2cscl: process(clk, reset)
    variable clkhasstarted : std_logic;
begin
    if reset = '1' then
        sclbit        <= '1';
        clkhasstarted := '0';
    elsif clk'event and clk='1' then
        if    timer = prescaler then sclbit <= '1'; -- clk_hi
        elsif timer = presc_50  then sclbit <= '0'; -- clk_lo
        end if;

        if enable = '1' then
            if clkhasstarted = '1' then
                if timer = 1 then 
                    timer <= prescaler;
                else
                    timer <= timer-1;
                end if;
            elsif startclk = '1' then
                timer         <= presc_50;
                clkhasstarted :='1';
            end if;
        else
            clkhasstarted := '0';
        end if;

        presc_75 <= presc_50 + presc_25;          -- 3/4 of prescaler value, clk_hi mid-time
        presc_50 <= "0"  & prescaler(9 downto 1); -- 1/2 of prescaler value, clk falling edge
        presc_25 <= "00" & prescaler(9 downto 2); -- 1/4 of prescaler value, clk_lo mid-time
    end if;
end process;

i2csda: process(clk, reset)
    variable wrbyte   : std_logic_vector(7 downto 0);
    variable rdbyte   : std_logic_vector(7 downto 0);
    variable cnt      : integer range 0 to 15;
    variable time_set : std_logic_vector(9 downto 0);
    variable dv       : std_logic;
    variable ff       : std_logic;
begin
    if reset = '1' then
        dv      := '0';
        wrbit   <= '1';  -- read
        datafsm <= idle;
        clkmask <= '1';
    elsif clk'event and clk = '1' then
        bytereaddv  <= dv;
        if dv='1' then byteread <= rdbyte; end if;

        case datafsm is
            when idle =>
                completed <= '0'; failed <= '0'; dv := '0';

                if    execstart   = '1' then datafsm <= start;
                elsif execstop    = '1' then datafsm <= stop;
                elsif execwr      = '1' then datafsm <= writebyte; cnt := 8; wrbyte := bytetowrite;
                elsif execrd      = '1' then datafsm <= readbyte;  cnt := 8; rdbyte := x"00";
                elsif execgetack  = '1' then datafsm <= getack;
                elsif execsendack = '1' then datafsm <= sendack;
                elsif execsendnak = '1' then datafsm <= sendnak;
                end if;

            when start =>
                wrbit <= '1';
                if timer = presc_75 then datafsm <= idle; wrbit <= '0'; clkmask <= '0'; end if;

            when stop =>
                if timer = presc_25 then wrbit <= '0'; end if;
                if timer = presc_75 then wrbit <= '1'; datafsm <= idle; clkmask <= '1'; end if;

            when writebyte =>
                if cnt = 0 then datafsm <= idle; ff := wrbit; end if;
                if timer = presc_25 then
                    wrbit <= wrbyte(7); wrbyte := wrbyte(6 downto 0) & '0';
                    if cnt /= 0 then cnt := cnt-1; end if;
                end if;

            when getack =>
                wrbit     <= ff; ff := '1';
                completed <= '0';
                failed    <= '0';
                if timer = presc_75 then 
                    datafsm <= idle;
                    if    rdbit = '0' then completed <= '1';
                    elsif rdbit = '1' then failed    <= '1';
                    end if;
                end if;

            when readbyte =>
                wrbit <= '1'; -- read
                if cnt = 0 then dv := '1'; datafsm <= idle; end if;

                if timer = presc_75 then
                    rdbyte := rdbyte(6 downto 0) & rdbit;
                    if cnt /= 0 then cnt := cnt-1; end if;
                end if;

            when sendack =>
                if timer = presc_25 then
                    wrbit   <= '0';
                    datafsm <= idle;
                end if; 

            when sendnak =>
                if timer = presc_25 then
                    wrbit   <= '1';
                    datafsm <= idle;
                end if;
        end case;
    end if;
end process;

-- clk vs timer value (as percentage of the prescaler value)
--
--     75%  50%  25%  100% 75%  50%  25%  100% 75%  50%  25%
--      x    x    x    x    x    x    x    x    x    x    x
--  ---------+         +---------+         +---------+
--           |         |         |         |         |
--           +---------+         +---------+         +-------

rdbit <= sda_i(0) when (i2c_bus_select = "000") else 
         sda_i(1) when (i2c_bus_select = "001") else 
         sda_i(2) when (i2c_bus_select = "010") else 
         sda_i(3) when (i2c_bus_select = "011") else 
         sda_i(4) when (i2c_bus_select = "100") else 
         sda_i(5) when (i2c_bus_select = "101") else 
         sda_i(6) when (i2c_bus_select = "110") else 
         sda_i(7) when (i2c_bus_select = "111") else '1';

sda_o(0) <= '0' when (i2c_bus_select = "000" and wrbit = '0' and enable = '1') else '1';
sda_o(1) <= '0' when (i2c_bus_select = "001" and wrbit = '0' and enable = '1') else '1';
sda_o(2) <= '0' when (i2c_bus_select = "010" and wrbit = '0' and enable = '1') else '1';
sda_o(3) <= '0' when (i2c_bus_select = "011" and wrbit = '0' and enable = '1') else '1';
sda_o(4) <= '0' when (i2c_bus_select = "100" and wrbit = '0' and enable = '1') else '1';
sda_o(5) <= '0' when (i2c_bus_select = "101" and wrbit = '0' and enable = '1') else '1';
sda_o(6) <= '0' when (i2c_bus_select = "110" and wrbit = '0' and enable = '1') else '1';
sda_o(7) <= '0' when (i2c_bus_select = "111" and wrbit = '0' and enable = '1') else '1';

scl_o(0) <= '0' when (i2c_bus_select = "000" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(1) <= '0' when (i2c_bus_select = "001" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(2) <= '0' when (i2c_bus_select = "010" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(3) <= '0' when (i2c_bus_select = "011" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(4) <= '0' when (i2c_bus_select = "100" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(5) <= '0' when (i2c_bus_select = "101" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(6) <= '0' when (i2c_bus_select = "110" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';
scl_o(7) <= '0' when (i2c_bus_select = "111" and sclbit = '0' and enable = '1' and clkmask = '0') else '1';

end behave;
