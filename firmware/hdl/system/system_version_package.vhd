library ieee;
use ieee.std_logic_1164.all;
package system_version_package is
	
	constant sys_ver_major : integer range 0 to  15 := 5;
	constant sys_ver_minor : integer range 0 to  15 := 0;
	constant sys_ver_build : integer range 0 to 255 := 1;


	constant sys_ver_year  : integer range 0 to 99 := 15;
	constant sys_ver_month : integer range 0 to 12 := 08;
	constant sys_ver_day   : integer range 0 to 31 := 31;
  
	constant rev_id		   : std_logic_vector(31 downto 0) := x"616c6c20";
  
end system_version_package;

package body system_version_package is
end system_version_package;
