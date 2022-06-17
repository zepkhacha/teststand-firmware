library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;


entity blink is
generic
(
	freq	: integer := 40000000
);
port(
	rst		: in  std_logic;								
	clk		: in  std_logic;								
	i			: in  std_logic;	
	o     	: out std_logic
);
end blink;



architecture rtl of blink is
begin


	process(clk, rst)
		constant clock_freq	: integer:= freq ;
		constant pulse_width	: integer:= freq/20;
		variable timer			: integer;
		variable level			: std_logic;
		variable pulse_trig	: std_logic;
	begin
	if rst = '1' then
		timer 	:= pulse_width-1;
		o			<= '0';
		level 	:= '0';
	elsif rising_edge(clk) then
		
		if timer = 0 then
			o <= level and pulse_trig;		
			level    	:= not level;
			timer 		:= pulse_width-1;
			pulse_trig 	:= '0'; -- clear trigger
		else
			timer			:= timer - 1;
		end if;
		
		if i='1' then
			pulse_trig :='1';
		end if; 	
			
	end if;
	end process;



end rtl;