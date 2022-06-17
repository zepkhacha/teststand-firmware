library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;


entity hb is
generic
(
	freq	: integer := 40000000
);
port(
	rst		: in  std_logic;								
	i		: in  std_logic;	
	o     	: out std_logic
);
end hb;



architecture rtl of hb is
begin


process(i, rst)
	variable timer : integer;
	variable hb_r	: std_logic;
begin
if (rst = '1') then
	
	o 	   <= '0';
	hb_r  := '0';
	timer := freq/2 -1;  

elsif (i = '1' and i'event) then
  
	o <= hb_r;
	if timer=0 then
		hb_r  := not hb_r;
		timer := freq/2 -1;  
	else
		timer	:= timer - 1;
	end if;

end if;
end process;



end rtl;