library ieee;
use ieee.std_logic_1164.all;
 
package user_package is

    constant nbr_usr_enc_slaves    : positive := 3;
    constant nbr_usr_fan_slaves    : positive := 2;
    constant nbr_usr_trg_slaves    : positive := 5;
   
    constant user_ipb_stat_regs    : integer := 0;
    constant user_ipb_ctrl_regs    : integer := 1;
    constant user_ipb_seqr_regs    : integer := 2;
    constant user_ipb_trig_regs    : integer := 2;
    constant user_ipb_trig_t9_regs : integer := 3;

end user_package;
   
package body user_package is
end user_package;
