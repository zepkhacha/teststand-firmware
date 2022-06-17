library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.ipbus.all;
use work.system_package.all;
use work.system_version_package.all;

entity ipb_system_regs is
generic (addr_width : natural := 6);
port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    ipbus_in  : in  ipb_wbus;
    ipbus_out : out ipb_rbus;
    regs_o    : out array_8x32bit
);
end ipb_system_regs;

architecture rtl of ipb_system_regs is

    signal regs : array_8x32bit;
    signal sel  : integer range 0 to 7;
    signal ack  : std_logic;
    
    attribute keep : boolean;
    attribute keep of sel : signal is true;

begin

    -- -------------------
    -- read only registers
    -- -------------------

    regs_o <= regs;

    regs(0) <= x"46433720"; -- board_id = 'F' 'C' '7' ' '
    regs(1) <= rev_id;
    regs(2) <= std_logic_vector(to_unsigned(sys_ver_major, 4)) &
               std_logic_vector(to_unsigned(sys_ver_minor, 4)) &
               std_logic_vector(to_unsigned(sys_ver_build, 8)) &
               std_logic_vector(to_unsigned(sys_ver_year,  7)) &
               std_logic_vector(to_unsigned(sys_ver_month, 4)) &
               std_logic_vector(to_unsigned(sys_ver_day,   5));
    
    sel <= to_integer(unsigned(ipbus_in.ipb_addr(addr_width downto 0))) when addr_width > 0 else 0;
    
    -- ---------------------
    ipb: process(reset, clk)
    begin
        if reset = '1' then
            regs(3) <= x"ff7cffd8"; -- reg ctrl
            regs(4) <= x"00ff0000"; -- reg ctrl 2
            regs(5) <= x"00000000"; -- reg spi txdata
            regs(6) <= x"00000000"; -- reg spi command [31:28] auto-clear

        elsif rising_edge(clk) then
            if ipbus_in.ipb_strobe = '1' and ipbus_in.ipb_write = '1' then
                case sel is
                    when 3      => regs(3) <= ipbus_in.ipb_wdata;
                    when 4      => regs(4) <= ipbus_in.ipb_wdata;
                    when 5      => regs(5) <= ipbus_in.ipb_wdata;
                    when 6      => regs(6) <= ipbus_in.ipb_wdata;
                    when 7      => regs(7) <= ipbus_in.ipb_wdata;
                    when others => 
                end case;
            end if;

            -- auto-clear
            if ipbus_in.ipb_strobe = '0' then
                regs(7)(31 downto 28) <= x"0";
            end if;

            ipbus_out.ipb_rdata <= regs(sel);       -- read
            ack <= ipbus_in.ipb_strobe and not ack; -- ack
        end if;
    end process;
    
    ipbus_out.ipb_ack <= ack;
    ipbus_out.ipb_err <= '0';

end rtl;
