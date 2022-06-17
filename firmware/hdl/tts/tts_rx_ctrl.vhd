library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity tts_rx_ctrl is
generic 
(
	misaligned_state_code 					: std_logic_vector(7 downto 0):=x"ff"; 
	allow_all_0000xxxx                  : boolean:= false; 
	bitslip_delay								: integer:= 4;
	consecutive_valid_chars_to_lock     : integer:= 8;
	consecutive_invalid_chars_to_unlock : integer:= 2 -- it should remain unchanged
);
port
(
	reset_i				: in 	std_logic;
	clk_i					: in 	std_logic;				
	-- ctrl i/f--
	align_str_i			: in 	std_logic;   	-- when 0, in alignment cycle, to force realign 0->1->0
	aligned_o			: out	std_logic;		-- when 1, bitslip is successful
	-- serdes i/f --
	rxbyte_i				: in	std_logic_vector(7 downto 0);
	rxcharisk_i			: in	std_logic;
	rx_bitslip_o		: out	std_logic;
	-- idelay i/f --
	idelay_ctrl_o		: out	std_logic; -- only the msb of ctrl[4:0] is used
	idelay_load_o		: out	std_logic;
	-- idelay i/f --
	gearbox_ctrl_o		: out	std_logic;
	-- results --
	o						: out	std_logic_vector(7 downto 0);
	dv_o					: out	std_logic
	
);
	
end tts_rx_ctrl;

architecture rtl of tts_rx_ctrl is

	type 	byte_align_fsm_type 			is (monitor, bitslip_1, bitslip_2);
	signal 	byte_align_fsm				: byte_align_fsm_type;	
	attribute keep							: boolean;
	attribute keep of byte_align_fsm	: signal is true; 
	attribute keep of rxbyte_i			: signal is true; 
	attribute keep of rxcharisk_i		: signal is true; 
	attribute keep of o					: signal is true; 
	attribute keep of dv_o				: signal is true; 
	attribute keep of aligned_o		: signal is true; 

begin


	--==========================--
	autobitslip: process (reset_i, clk_i)
	--==========================--
		variable rxbyte_prev			: std_logic_vector(7 downto 0);	
		variable valid_chars_cnt	: integer;
		variable invalid_chars_cnt	: integer;
		variable delay_cnt			: integer;
		variable aligned				: std_logic;
		variable bitslip_cnt			: integer;	
		variable idelay_ctrl			: std_logic;
		variable idelay_load			: std_logic;
		variable autofix_state		: std_logic_vector(1 downto 0);
	
	begin
	if reset_i = '1' then

		byte_align_fsm 	<= monitor;
		
		valid_chars_cnt	:= 0;
		invalid_chars_cnt	:= 0;
		
		dv_o					<= '0';
		o 						<= x"00"; 
		
		rxbyte_prev			:= x"00";
		aligned				:= '0'; 
		aligned_o			<= '0'; 
		
		bitslip_cnt			:=  0 ;
		idelay_ctrl			:= '0';
		idelay_ctrl_o		<= '0';
		idelay_load			:= '0';
		idelay_load_o		<= '0';
		autofix_state		:= "00";
		gearbox_ctrl_o		<= '0';
		
	elsif rising_edge(clk_i) then

	   
		--===============-- when valid char, present the char as is
		-- output mapping   when comma present the previous valid char
		--===============-- else present the misaligned state code
		
		aligned_o <= aligned;

		if aligned = '0' then
			dv_o	<= '0';
			o     <= misaligned_state_code; -- 2014.08.14
			
		else
			if 	(rxcharisk_i='0' and rxbyte_i= misaligned_state_code) or -- PV 2015.06.29
					(rxcharisk_i='0' and rxbyte_i(7 downto 4)=x"0" and allow_all_0000xxxx = true)	or
			 	   (rxcharisk_i='0' and rxbyte_i=x"00") or
					(rxcharisk_i='0' and rxbyte_i=x"01") or
					(rxcharisk_i='0' and rxbyte_i=x"02") or
					(rxcharisk_i='0' and rxbyte_i=x"04") or
					(rxcharisk_i='0' and rxbyte_i=x"08") or
					(rxcharisk_i='0' and rxbyte_i=x"0C") or
					(rxcharisk_i='0' and rxbyte_i=x"0F") then dv_o <= '1'; o <= rxbyte_i;    rxbyte_prev := rxbyte_i; 	
			elsif	(rxcharisk_i='1' and rxbyte_i=x"BC") then              o <= rxbyte_prev; 
			else                                            dv_o <= '0';
			end if;
		end if;
		--===============--
		
		
		
		
		
		--===============--
		-- alignment state machine
		--===============--
		if align_str_i = '0' then
			case byte_align_fsm is
				
				--=========--
				when monitor =>	
				--=========--

					aligned := '1'; -- start with the assumption that aligned is 1 in order to propagate invalid tts states
					
					if (rxcharisk_i='0' and rxbyte_i=misaligned_state_code) or  -- PV 2015.06.29
					   --(rxcharisk_i='0' and rxbyte_i(7 downto 4)=x"0" and allow_all_0000xxxx = true)	or -- PV 2015.06.30
					   (rxcharisk_i='1' and rxbyte_i=x"BC") or
						(rxcharisk_i='0' and rxbyte_i=x"00") or
						(rxcharisk_i='0' and rxbyte_i=x"01") or
						(rxcharisk_i='0' and rxbyte_i=x"02") or
						(rxcharisk_i='0' and rxbyte_i=x"04") or
						(rxcharisk_i='0' and rxbyte_i=x"08") or
						(rxcharisk_i='0' and rxbyte_i=x"0C") or
						(rxcharisk_i='0' and rxbyte_i=x"0F") then
						
						invalid_chars_cnt		:= 0;
						
						if valid_chars_cnt /= consecutive_valid_chars_to_lock then valid_chars_cnt	:= valid_chars_cnt+1;
						end if;
					
					elsif (rxcharisk_i='0' and rxbyte_i(7 downto 4)=x"0" and allow_all_0000xxxx = true)	then
					   null;
					
					else
						valid_chars_cnt		:= 0;
						if invalid_chars_cnt = consecutive_invalid_chars_to_unlock then
							byte_align_fsm 	<= bitslip_1;
							aligned				:= '0';
						else
							invalid_chars_cnt	:= invalid_chars_cnt+1;
						end if;	
					end if;	
				
				--=========--
				when bitslip_1 =>	
				--=========--
								
					valid_chars_cnt	:= 0;
					invalid_chars_cnt	:= 0;
					--
					rx_bitslip_o 		<= '1'; 
					delay_cnt			:= bitslip_delay-1;	
					byte_align_fsm 	<= bitslip_2;
					--
					if bitslip_cnt = 19 then
						
						bitslip_cnt		:=  0 ;
						idelay_load   	:= '1'; 
						idelay_ctrl_o 	<= idelay_ctrl;		-- autofix state 00 -> idelay_ctrl_o -> 0, gearbox_ctrl_o -> 0
						idelay_ctrl	  	:= not idelay_ctrl;  -- autofix state 01 -> idelay_ctrl_o -> 1, gearbox_ctrl_o -> 0
						gearbox_ctrl_o <= autofix_state(1); -- autofix state 10 -> idelay_ctrl_o -> 0, gearbox_ctrl_o -> 1
						autofix_state	:= autofix_state+1;	-- autofix state 11 -> idelay_ctrl_o -> 1, gearbox_ctrl_o -> 1
					
					else															
						bitslip_cnt:= bitslip_cnt+1;			
					end if;	
					
				--=========--
				when bitslip_2 =>	
				--=========--
				
					rx_bitslip_o  		<='0';
					if delay_cnt = 0 then 
						byte_align_fsm	<= monitor;
					else
						delay_cnt:=delay_cnt-1;
					end if;
					--		
					idelay_load_o <= idelay_load; idelay_load:= '0'; 
					

			end case;
	
		elsif align_str_i = '1' then 
		
			byte_align_fsm 	<= monitor;
			
			valid_chars_cnt	:= 0;
			invalid_chars_cnt	:= 0;
			
			dv_o					<= '0';
			o 						<= x"00"; 
			
			rxbyte_prev			:= x"00";
			aligned				:= '0'; 
			aligned_o			<= '0'; 
		
			bitslip_cnt			:=  0 ;
			idelay_ctrl			:= '0';
			idelay_ctrl_o		<= '0';
			idelay_load			:= '0';
			idelay_load_o		<= '0';
			autofix_state		:= "00";
			gearbox_ctrl_o		<= '0';			
		
		end if;	
			
	end if;
	end process;
	--==========================--


	
end rtl;