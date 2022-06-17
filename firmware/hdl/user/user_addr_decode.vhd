library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.ipbus.all;
use work.user_package.all;

package user_addr_decode is

    function user_ipb_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer;

end user_addr_decode;

package body user_addr_decode is

    function user_ipb_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer is
        variable sel : integer;
    begin
        --             (addr, "00----------------00------------") is reserved
        if    std_match(addr, "01--------------0000------------") then sel := user_ipb_stat_regs;
        elsif std_match(addr, "01--------------0001------------") then sel := user_ipb_ctrl_regs;
        elsif std_match(addr, "01--------------0010------------") then sel := user_ipb_seqr_regs;
        elsif std_match(addr, "01--------------0011------------") then sel := user_ipb_trig_regs;
        elsif std_match(addr, "01--------------0100------------") then sel := user_ipb_trig_t9_regs;
        else                                                           sel := 99;
        end if;
        return sel;
    end user_ipb_addr_sel;

end user_addr_decode;
