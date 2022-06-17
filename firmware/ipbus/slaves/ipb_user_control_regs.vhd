-- IPbus slave module for FC7 control registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith;

-- system packages
use work.ipbus.all;
use work.system_package.all;

entity ipb_user_control_regs is
generic (
    addr_width : natural := 7
);
port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    run_in_progress : in  std_logic;
    ipbus_in        : in  ipb_wbus;
    ipbus_out       : out ipb_rbus;
    regs_o          : out ctrl_reg_t
);
end ipb_user_control_regs;

architecture rtl of ipb_user_control_regs is
    
    signal regs : ctrl_reg_t;
    signal sel  : integer range 0 to ctrl_reg_max;
    signal ack  : std_logic;
    signal err  : std_logic;
    signal write_lock : std_logic;
    signal ovfl_reg   : integer range 0 to ctrl_reg_max;
    signal dbgl_reg   : integer range 0 to ctrl_reg_max;


    attribute keep : boolean;
    attribute keep of sel : signal is true;

begin
    
    -- I/O mapping
    regs_o <= regs;

    sel <= to_integer(unsigned(ipbus_in.ipb_addr(addr_width downto 0))) when addr_width > 0 else 0;

    -- writing is OK when run is not in progress or for software trigger throttling request or for debug line request
    ovfl_reg <= 44;
    dbgl_reg <= 46;
    write_lock <= '0' when sel = ovfl_reg OR sel = dbgl_reg else run_in_progress;


    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                regs <= (others => (others => '0'));

                -- overwrite with default values
                regs( 3)( 7 downto 0) <= x"01";       -- 50-ns TTC trigger output pulse width
                regs( 4)(23 downto 0) <= x"000010";   -- 16-trigger overflow warning watchdog threshold
                regs( 5)              <= x"00009C40"; -- super-cycle start wait threshold
                regs( 6)              <= x"00000010"; -- minimum TTS state lock threshold
                regs( 9)(18)          <= '1';         -- active-low I2C L12 reset
                regs( 9)(19)          <= '1';         -- active-low I2C L8 reset
                regs(17)( 7 downto 0) <= x"01";       -- 50-ns begin-of-cycle trigger pulse width
                regs(17)(15 downto 8) <= x"03";       -- 50-ns begin-of-cycle trigger pulse width
                regs(19)( 0)          <= '1';         -- enable WFD5 asynchronous storage in run
                regs(20)              <= x"02625A00"; -- 1-s wait at end-of-run procedure
                regs(25)              <= x"00000010"; -- 16 clock cycle minimum post-event count reset
                regs(26)              <= x"00000010"; -- 16 clock cycle minimum post-timestamp reset
                -- internal trigger-related
                -- regs(30)              <= x"000586D8"; -- 9.055 ms delay (25 ns ticks) from T93/T94 to first A6 of cycle
                -- regs(30)              <= x"00054837"; -- as close to  as we can get to 8.654184 ms delay (25 ns ticks) from T93/T94 to first A6 of cycle
                regs(30)              <= x"001DB237"; -- 48,654,175 ns delay (25 ns ticks) from T93/T94 to first A6 of cycle
                regs(31)              <= x"00061A80"; -- 10 ms period for 8-fill cycle (25 ns ticks)
                regs(32)              <= x"007222C0"; -- 187 ms gap (25 ns ticks) from last A6 of 1st cycle to the T4 of second (=> 197 ms to 1s2 A6 of 2nd)
                regs(33)              <= x"03567E00"; -- 1.4 s supercycle period (25 ns ticks)
                regs(34)              <= x"10B07600"; -- threshold for declaring a6 missing.
                regs(35)              <= x"000007C5"; -- fall back to internal trigger and gap correction are enabled by default; max default ttc data tap delay
                regs(36)              <= x"00724200"; -- 187.2 ms limit for a measured T9 to A6 transition to be used in the running average
                regs(37)              <= x"0" & x"7" & x"1FFFFF"; -- fine tuning for asserting cycle change timing
                regs(38)              <= x"007AAE40"; -- 8040000 clock cycles = 201 ms min time between boc signal and 
                regs(39)              <= x"000927C0"; -- 600000 40 MHz clock cycles = 15 ms -> default safety discharge timing
                regs(40)              <= x"00057E40"; -- 360000 40 MHz clock cycles =  9 ms -> default kicker discharge deadtime
                regs(41)              <= x"00057E40"; -- 360000 40 MHz clock cycles =  9 ms -> default kicker recharge deadtime
                regs(46)              <= x"00018820"; -- the default debug lines output to the D bank are 0 -- 3 (5 bits per address)

            elsif ipbus_in.ipb_strobe = '1' and ipbus_in.ipb_write = '1' then
                if sel = 0 or write_lock = '0' then
                    regs(sel) <= ipbus_in.ipb_wdata;
                end if;
            end if;

            ipbus_out.ipb_rdata <= regs(sel);
            ack <= ipbus_in.ipb_strobe and not ack;

            if ipbus_in.ipb_strobe = '1' and err = '0' and ipbus_in.ipb_write = '1' and write_lock = '1' and sel /= 0 then
                err <= '1';
            else 
                err <= '0';
            end if;
        end if;
    end process;
    
    ipbus_out.ipb_ack <= ack;
    ipbus_out.ipb_err <= err;

end rtl;
