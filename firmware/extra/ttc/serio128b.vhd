--
-- hello_world.vhd
--
-- The ’Hello World’ example for FPGA programming.
--
-- Author: Martin Schoeberl (martin@jopdesign.com)
--
-- 2006-08-04 created
--
library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity SerIO128b is
port (
	CK200T : in std_logic;
	PD128in : in STD_LOGIC_VECTOR(127 downto 0);
	PD128LD : in std_logic;
 	STX : out std_logic;	
	CK400R : in std_logic;
	OKSample : in std_logic;
	DBit : in std_logic;
	CK200R : in std_logic;
	PQ128D : out STD_LOGIC_VECTOR(127 downto 0);
 	PQ128V : out std_logic;
	CmpQ : out std_logic;
	LEDCmpQchng : out std_logic
);
end SerIO128b;

architecture rtl of SerIO128b is
	constant CK_FREQ : integer := 50000000;
	constant BLINK_FREQ : integer := 1;
	constant CNT_MAX : integer := CK_FREQ/BLINK_FREQ/2-1;
	signal PD128shift : std_logic_vector(127 downto 0);
	signal SDinQ : std_logic_vector(127 downto 0);
	signal SDin2Q : std_logic_vector(127 downto 0);
	signal PDtestQ : std_logic_vector(127 downto 0);
	signal PDtestQb : std_logic_vector(127 downto 0);
	signal BitCnt : std_logic_vector(7 downto 0);
	signal BitCnt7Q : std_logic;
	signal BitCnt7QQ : std_logic;
	signal SDin2QV : std_logic;
	signal PQ128Vb : std_logic;
	signal TimeOutD : std_logic;
	signal TimeOutP : std_logic;
	signal TimeOutCnt : std_logic_vector(3 downto 0);	
	signal CmpD : std_logic;
	signal  LEDCnt : std_logic_vector(27 downto 0);
begin

	process(CK200T)
	begin
		if rising_edge(CK200T) then
			if PD128LD='1' then
				PD128shift(127) <= '1';
				PD128shift(126 downto 0) <= PD128in(126 downto 0);				
			else
				PD128shift(127 downto 1) <= PD128shift(126 downto 0);				
				PD128shift(0) <= '0';
			end if;
		end if;
	end process;
	STX <= PD128shift(127);

	process(CK400R)
	begin
		if rising_edge(CK400R) then
			if OKSample='1' and BitCnt(7)='1' then
				SDinQ(0) <= DBit;
				SDinQ(127 downto 1) <= SDinQ(126 downto 0);
				BitCnt <= BitCnt + 1;
			else
				if TimeOutP='1' then
					BitCnt <= "10000000";
				else
					BitCnt <= BitCnt;
				end if;
				SDinQ <= SDinQ;
			end if;
			BitCnt7Q <= BitCnt(6);
			BitCnt7QQ <= BitCnt7Q;
			if BitCnt(6)='0' and BitCnt7QQ='1' then
				SDin2Q <= SDinQ;
				SDin2QV <= '1';
			else
				SDin2Q <= SDin2Q;
				SDin2QV <= '0';				
			end if;		
		end if;
	end process;
	
	process(CK400R)
	begin
		if rising_edge(CK400R) then
			if OKSample='1' then
				TimeOutCnt <= "1000";
			else
				if TimeOutCnt(3)='1' then
					TimeOutCnt <= TimeOutCnt+1;
				else
					TimeOutCnt <= TimeOutCnt;
				end if;
			end if;
			TimeOutP <= TimeOutD;
		end if;
	end process;
	TimeOutD <= '1' when TimeOutCnt = "1111" else '0';
	
	process(CK200R)
	begin
		if rising_edge(CK200R) then
		PDtestQb <= SDin2Q;
		PQ128Vb <= SDin2QV;
		end if;
	end process;
	PQ128D <= PDtestQb;
	PQ128V <= PQ128Vb;
	
	process(CK200R)
	begin
		if rising_edge(CK200R) then
		PDtestQ <= PD128in;
			if (PDtestQ = PDtestQb) and PQ128Vb ='1' then
				CmpD <= '1';
			else
				CmpD <= '0';
			end if;
		end if;
	end process;
CmpQ <= CmpD;

PROCESS(CK200R)
BEGIN
IF (RISING_EDGE(CK200R)) THEN
	if (PQ128Vb ='1') and (not(PDtestQ = PDtestQb)) then
		LEDCnt <= "1000000000000000000000000000";
	else
		if (LEDCnt(27) = '1') then
			LEDCnt <= LEDCnt + 1;
		else
			LEDCnt <= LEDCnt;
		end if;
	end if;
END IF;
END PROCESS;
LEDCmpQchng <= LEDCnt(27);

end rtl;
