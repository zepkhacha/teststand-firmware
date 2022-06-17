-- IPbus slave module for FC7 status registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.ipbus.all;
use work.system_package.all;

entity ipb_user_status_regs is
generic (
    addr_width : natural := 7
);
port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    ipbus_in  : in  ipb_wbus;
    ipbus_out : out ipb_rbus;
    regs_i    : in  stat_reg_t
);

end ipb_user_status_regs;

architecture rtl of ipb_user_status_regs is

    signal regs  : stat_reg_t;
    signal sync1 : stat_reg_t;
    signal sync2 : stat_reg_t;
    signal sel   : integer range 0 to 208;
    signal ack   : std_logic;

    attribute keep : boolean;
    attribute keep of sel : signal is true;

begin

    -- two-stage synchronization
    process(clk)
    begin
        if rising_edge(clk) then
            sync1 <= regs_i;
            sync2 <= sync1;
        end if;
    end process;
    
    -- I/O mapping
    regs <= sync2;

    sel <= to_integer(unsigned(ipbus_in.ipb_addr(addr_width downto 0))) when addr_width > 0 else 0;
    
    process(reset, clk)
    begin
        if reset = '1' then
            ack <= '0';
        elsif rising_edge(clk) then
            ipbus_out.ipb_rdata <= regs(sel);       -- read
            ack <= ipbus_in.ipb_strobe and not ack; -- ack
        end if;
    end process;
    
    ipbus_out.ipb_ack <= ack;
    ipbus_out.ipb_err <= '0';

end rtl;
