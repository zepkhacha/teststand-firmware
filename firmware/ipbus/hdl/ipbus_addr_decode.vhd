-- Address decode logic for ipbus fabric

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.system_package.all;
use work.ipbus.all;

package ipbus_addr_decode is

    function ipbus_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer;

end ipbus_addr_decode;

package body ipbus_addr_decode is

    function ipbus_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer is
        variable sel : integer;
    begin
        if    std_match(addr, "00----------------00------------") then sel := sys_ipb_flash_regs;
        else                                                           sel := 99;
        end if;
        return sel;
    end ipbus_addr_sel;

end ipbus_addr_decode;
