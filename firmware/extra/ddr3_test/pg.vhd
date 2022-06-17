library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity pg is

port 
(	
	clk            	: in  std_logic;
	rst            	: in  std_logic;
	enable      		: in  std_logic;
	pg_out 				: out std_logic_vector(255 downto 0)
);
end pg;

architecture behavioral of pg is

begin

	process (rst, clk)

    variable word0  	: std_logic_vector(31 downto 0);
    variable word1  	: std_logic_vector(31 downto 0);
    variable word2  	: std_logic_vector(31 downto 0);
    variable word3  	: std_logic_vector(31 downto 0);
    variable word4  	: std_logic_vector(31 downto 0);
	 variable word5  	: std_logic_vector(31 downto 0);
    variable word6  	: std_logic_vector(31 downto 0);
    variable word7   : std_logic_vector(31 downto 0);
	 
  begin
    if (rst = '1') then

		word0  	:= x"0000_0000";
		word1  	:= x"0000_0001";
		word2  	:= x"0000_0002";
		word3  	:= x"0000_0003";
		word4  	:= x"0000_0004";
		word5  	:= x"0000_0005";
		word6  	:= x"0000_0006";
		word7  	:= x"0000_0007";
      pg_out	<= word7 & word6 & word5 & word4 & word3 & word2 & word1 & word0; 
		   
   elsif (rising_edge(clk)) then
			
		if enable = '1' then
			word0    := word0+8;
			word1    := word1+8;
			word2    := word2+8;
			word3    := word3+8;
			word4    := word4+8;
			word5    := word5+8;
			word6    := word6+8;
			word7    := word7+8;
		end if;
		pg_out	<= word7 & word6 & word5 & word4 & word3 & word2 & word1 & word0; 
    end if;
  end process;

 
end behavioral;