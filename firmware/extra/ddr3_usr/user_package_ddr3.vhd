library ieee;
use ieee.std_logic_1164.all;
 
package user_package is

   constant sys_phase_mon_freq      : string   := "160MHz"; -- valid options only "160MHz" or "240MHz"    
	--=== ipb slaves =============--
	constant nbr_usr_slaves				: positive := 3 ;
   
	constant user_ipb_stat_regs		: integer  := 0 ;
	constant user_ipb_ctrl_regs		: integer  := 1 ;
	constant user_ddr3					: integer  := 2 ;

	
end user_package;
   
package body user_package is
end user_package;