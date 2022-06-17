-- configurable pseudo random bit sequence
-- serial / parallel (configurable width)
-- prbs type configurable (select taps from xilinx xapp052, table 3
-- starts from input seed
-- paschalis vichoudis, cern

library ieee;
use ieee.std_logic_1164.all;
use work.prbs_package.all;

entity prbs is -- prbs7 parallel, width 21bit
generic 
(
	ta	: tap_array	:=(31,28, 0, 0);--tap array - max fixed size: 4
	tn	: integer  	:= 2 ;			--number of taps to take into account (max:4)
	l	: integer	:= 31; 			--prbs type e.g. for prbs7 -> l=7
	w	: integer	:= 256  			--serializer data width
);

--======= lfsr tap examples (from xapp052) ========--
-- prbs31: 31th, 28th				-> tn=2, ta=(31,28, 0, 0)
-- prbs23: 23th, 18th				-> tn=2, ta=(23,18, 0, 0)
-- prbs15: 15th, 14th				-> tn=2, ta=(15,14, 0, 0)
-- prbs10: 10th, 7th 				-> tn=2, ta=(10, 7, 0, 0)
-- prbs9 :  9th, 5th 				-> tn=2, ta=( 9, 5, 0, 0)
-- prbs8 :  8th, 6th, 5th, 4th 	-> tn=4, ta=( 8, 6, 5, 4)
-- prbs7 :  7th, 6th 				-> tn=2, ta=( 7, 6, 0, 0) # alternatively ta=( 7, 1, 0, 0)
-- prbs6 :  6th, 5th 				-> tn=2, ta=( 6, 5, 0, 0)
-- prbs5 :  5th, 3rd 				-> tn=2, ta=( 5, 3, 0, 0)
--=================================================--
port
(
	clk		: in	std_logic;
	rst		: in	std_logic;
	enable	: in	std_logic;
	seed		: in	std_logic_vector(l-1 downto 0):=(others => '0');
	sdv		: out	std_logic;
	sdata		: out	std_logic;
	pdv		: out	std_logic;
	pdata		: out	std_logic_vector(w-1 downto 0)
);
end prbs;

architecture rtl of prbs is


begin
--===========================--
serial: process (rst, clk)
--===========================--
variable pattern		: std_logic_vector(l-1 downto 0);
variable feedback		: std_logic;
variable sdv_reg		: std_logic;
variable sdata_reg	: std_logic;
begin

if rst='1' then
		pattern  	:= seed;
		sdv		 	<= '0';
		sdata			<= '0';
		sdv_reg		:= '0';
		sdata_reg	:= '0';
elsif clk'event and clk='1' then

	if enable='1' then	
		--==== main ====--
		sdv_reg		:='1';
		sdata_reg	:= pattern(l-1);
		feedback:= pattern(ta(0)-1);
		for j in 1 to tn-1 loop
			feedback:=feedback xnor pattern(ta(j)-1);
		end loop;
		pattern (l-1 downto 1):= pattern(l-2 downto 0);
		pattern(0):=feedback;
	end if;

	--==== out =====--
	sdata	<= sdata_reg;
	sdv	<= sdv_reg;

end if;
end process; 


--===========================--
parallel: process (rst, clk)
--===========================--
variable pattern	: std_logic_vector(l-1 downto 0);
variable feedback	: std_logic;
variable pdv_reg	: std_logic;
variable pdata_reg	: std_logic_vector(w-1 downto 0);
	
begin
if rst='1' then

	pattern  	:= seed;
	pdv		 	<= '0';
	pdata			<= (others=>'1');
	pdv_reg		:= '0';
	pdata_reg	:= (others=>'1');

elsif clk'event and clk='1' then

	if enable='1' then	
		--==== main ====--
		pdv_reg	:='1';
		for i in 0 to w-1 loop
			--==============--
			pdata_reg(i):= pattern(l-1);
			--==============--
			feedback:= pattern(ta(0)-1);
			for j in 1 to tn-1 loop
				feedback:=feedback xnor pattern(ta(j)-1);
			end loop;
			pattern (l-1 downto 1):= pattern(l-2 downto 0);
			pattern(0):=feedback;
		end loop;	
	end if;
	--==== out =====--
	pdata	<= pdata_reg;
	pdv	<= pdv_reg;

end if;
end process;

end rtl;