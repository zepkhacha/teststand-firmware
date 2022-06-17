library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

use work.ipbus.all;

--=================================================================================================--
--======================================= module body =============================================-- 
--=================================================================================================--
entity k7_icap_fsm is
	port (	
		-- control:
		reset_i					: in  std_logic; -- active high
		clk_i						: in  std_logic; -- 31.25MHz
		reg_read_i				: in  std_logic; -- trigger an icap read 
		reg_addr_i				: in  std_logic_vector (4 downto 0);		
		ipbus_i					: in 	ipb_wbus;
		ipbus_o					: out ipb_rbus			
	);
end k7_icap_fsm;


architecture structural of k7_icap_fsm is

--=== readback command sequences  ===--
--see ug470, p.106, table 6-1


-----------------------------------------------------------------
-- 1  write ffffffff dummy word
-- 2  write 000000bb bus width sync word
-- 3  write 11220044 bus width detect
--------------------
-- 4  write ffffffff dummy word
-- 5  write aa995566 sync word
-- 6  write 20000000 noop
-- 7  write 2800e001 write type1 packet header to read stat register
-- 8  write 20000000 noop
-- 9  write 20000000 noop
-- 10 read  ssssssss device writes one word from the stat register to the configuration interface
--------------------
-- 11 write 30008001 type 1 write 1 word to cmd
-- 12 write 0000000d desync command
-- 13 write 20000000 noop
-- 14 write 20000000 noop
-----------------------------------------------------------------


--see ug470, p.87, table 5-17

-----------------------------------------------------------------
-- type1 packet header: 001 xx 000000000yyyyy 00 zzzzzzzzzzz
-----------------------------------------------------------------
-- x: opcode (00: nop, 01: read, 10: write)
-- y: reg address
-- z: wordcount
-----------------------------------------------------------------


--see ug470, p.88, table 5-20
---------+-------------+---------+-------------------------------
--name 	|	read/write | address |	description
---------+-------------+---------+-------------------------------
-- crc 		read/write 	 	00000 	crc register
-- far 		read/write 	 	00001 	frame address register
-- fdri 		write 		 	00010		frame data register, input register (write configuration data)
-- fdro 		read 			 	00011		frame data register, output register (read configuration data)
-- cmd 		read/write 		00100 	command register
-- ctl0 		read/write 		00101 	control register 0
-- mask 		read/write 		00110 	masking register for ctl0 and ctl1
-- stat 		read 				00111 	status register
-- lout 		write 			01000 	legacy output register for daisy chain
-- cor0 		read/write 		01001 	configuration option register 0
-- mfwr 		write 			01010 	multiple frame write register
-- cbc 		write 			01011 	initial cbc value register
-- idcode 	read/write 		01100 	device id register
-- axss 		read/write 		01101 	user bitstream access register
-- cor1 		read/write 		01110 	configuration option register 1
-- wbstar 	read/write 		10000 	warm boot start address register
-- timer 	read/write 		10001 	watchdog timer register
-- bootsts	read 				10110 	boot history status register
-- ctl1 		read/write 		11000 	control register 1
---------+-------------+---------+-------------------------------


-- see "Parallel Bus Bit Order" section ug470, p.70

--=============================--
function bit_ordering (word_i	:  std_logic_vector(31 downto 0)) return std_logic_vector is	
--=============================--
	variable word_o					:	std_logic_vector(31 downto 0);
begin
	for i in 0 to 7 loop --reverse data bytes
			word_o(7-i)		:=	word_i(i);
			word_o(15-i)	:=	word_i(8+i);
			word_o(23-i)	:=	word_i(16+i);
			word_o(31-i)	:=	word_i(24+i);
		end loop;			
return word_o;
end bit_ordering;
--=============================--



type fsm_state 				is (	state_00, state_01, state_02, state_03, state_04, state_05, state_06, state_07, 
											state_08, state_09, state_10, state_11, state_12, state_13, state_14, state_15,
											state_16, state_17, state_18, state_19, state_20, state_21, state_22, state_23,
											state_24, state_25, state_26, state_27, state_28, state_29, state_30, state_31
											);
signal next_state 			: fsm_state;

constant dummy_word			: std_logic_vector(31 downto 0):= x"ff_ff_ff_ff";
constant sync_word			: std_logic_vector(31 downto 0):= x"aa_99_55_66";
constant noop					: std_logic_vector(31 downto 0):= x"20_00_00_00";
constant t1_wr_cmd			: std_logic_vector(31 downto 0):= x"30_00_80_01";
constant desync				: std_logic_vector(31 downto 0):= x"00_00_00_0d";
constant zeros					: std_logic_vector(31 downto 0):= x"00_00_00_00";

constant opcode_rd			: std_logic_vector( 1 downto 0):="01";
constant opcode_wr			: std_logic_vector( 1 downto 0):="10";

signal 	icap_i				: std_logic_vector(31 downto 0);
signal 	icap_o				: std_logic_vector(31 downto 0);
signal 	icap_csib			: std_logic;
signal 	icap_rdwrb			: std_logic;

signal t1ph_reg_rd			: std_logic_vector(31 downto 0);

signal ack						: std_logic;
signal response				: std_logic_vector(31 downto 0);

attribute keep : boolean;
attribute keep of icap_i 		: signal is true;
attribute keep of icap_o 		: signal is true;
attribute keep of icap_csib	: signal is true;
attribute keep of icap_rdwrb	: signal is true;



type commands_array is array (0 to 31) of std_logic_vector (35 downto 0); 



begin		


	--=============================--
  	icape2_inst : icape2
   --=============================--
	generic 	map ( icap_width => "x32", sim_cfg_file_name => "none", device_id => x"23752093") -- see ug470 table 1-1
   port 		map ( o  => icap_o, clk => clk_i, csib  => icap_csib, i  => icap_i, rdwrb => icap_rdwrb);
	--=============================--

	
	t1ph_reg_rd <= "001" & opcode_rd & "000000000" & reg_addr_i & "00" & "00000000001";

	
	
	--=============================--
	process(clk_i)
	--=============================--
		variable icap_out : std_logic_vector(31 downto 0);
	begin
   if reset_i='1' then
		next_state <= state_00;
		icap_i <= x"aaaabbbb";
	elsif (rising_edge(clk_i)) then
      if (reg_read_i = '1') then
        case next_state is
          when state_00 => icap_csib <= '1';	icap_rdwrb <= '1';   icap_i <= bit_ordering(dummy_word);			next_state <= state_01;
          when state_01 => icap_csib <= '1';	icap_rdwrb <= '0';	icap_i <= bit_ordering(dummy_word);	      next_state <= state_02;
          when state_02 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_03;
          when state_03 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_04;
          when state_04 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_05;
          when state_05 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_06;
          when state_06 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_07;
          when state_07 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_08;
          when state_08 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(dummy_word);			next_state <= state_09;
          when state_09 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(sync_word);     	next_state <= state_10;
          when state_10 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(noop);          	next_state <= state_11;
          when state_11 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(noop);          	next_state <= state_12;
          when state_12 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(noop);          	next_state <= state_13;
          when state_13 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(t1ph_reg_rd);		next_state <= state_14;
          when state_14 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(noop);          	next_state <= state_15;
          when state_15 => icap_csib <= '0';	icap_rdwrb <= '0';   icap_i <= bit_ordering(noop);          	next_state <= state_16;
          when state_16 => icap_csib <= '1';	icap_rdwrb <= '0';	icap_i <= bit_ordering(zeros);				next_state <= state_17;
          when state_17 => icap_csib <= '1';	icap_rdwrb <= '0';	icap_i <= bit_ordering(zeros);				next_state <= state_18;
          when state_18 => icap_csib <= '1';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_19;
          when state_19 => icap_csib <= '1';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_20;
          when state_20 => icap_csib <= '0';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_21;
          when state_21 => icap_csib <= '0';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_22;
          when state_22 => icap_csib <= '0';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_23;
          when state_23 => icap_csib <= '0';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_24;
          when state_24 => icap_csib <= '0';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_25;
          when state_25 => icap_csib <= '0';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_26;
			 when state_26 => icap_csib <= '1';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_27; response <= bit_ordering(icap_out);
			 when state_27 => icap_csib <= '1';	icap_rdwrb <= '1';	icap_i <= bit_ordering(zeros);				next_state <= state_28;
			 when state_28 => icap_csib <= '1';	icap_rdwrb <= '0';	icap_i <= bit_ordering(zeros);				next_state <= state_29;
			 when state_29 => icap_csib <= '0';	icap_rdwrb <= '0';	icap_i <= bit_ordering(t1_wr_cmd);			next_state <= state_30;
			 when state_30 => icap_csib <= '0';	icap_rdwrb <= '0';	icap_i <= bit_ordering(desync);				next_state <= state_31;
			 when state_31 => icap_csib <= '0';	icap_rdwrb <= '0';	icap_i <= bit_ordering(noop);					next_state <= state_31;
		end case;	 
      else						icap_csib <= '1';	icap_rdwrb <= '1';   icap_i <= bit_ordering(zeros);    			next_state <= state_00;			
      end if;
	icap_out := icap_o;
	 
	
	end if;
	end process;
	--=============================--



	--=============================--
	process(reset_i, clk_i)
	--=============================--
	begin
	if reset_i='1' then
		ack 		<= '0';
	elsif rising_edge(clk_i) then
		--== write ==--
		if ipbus_i.ipb_strobe='1' and ipbus_i.ipb_write='1' then 
		end if;
		--== read  ==-- 
		ipbus_o.ipb_rdata <= response;
		--==  ack  ==--
		ack <= ipbus_i.ipb_strobe and not ack;
		--
	end if;
	end process;
	
	ipbus_o.ipb_ack <= ack;
	ipbus_o.ipb_err <= '0';
	--=============================--	
	

end structural;