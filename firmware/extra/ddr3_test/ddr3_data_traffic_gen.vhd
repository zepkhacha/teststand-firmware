library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.external_memory_interface_definitions.all;

entity ddr3_data_traffic_gen is
  
	generic 
	(
		num_ops 				: integer := 1024;
		initdelay			: integer := 80000000;
		pattern_type		: string  := "prbs" -- "count" 
	);  -- ops = 2**28 / 256bits in bytes
	port 
	(
		clk            	: in  std_logic;
		rst            	: in  std_logic;
		strobe     			: in  std_logic;
		-- rd/wr ports
		wr_o 					: out ddr3_full_info_trig_type;
		rd_ctrl_o 			: out ddr3_addr_trig_type;
		rd_i    				: in  ddr3_full_info_trig_type;
		-- error checking
		exp_rd_o 			: out ddr3_full_info_trig_type;
		err_o					: out std_logic;	
		num_errors_o     	: out std_logic_vector(31 downto 0);
		num_words_o     	: out std_logic_vector(31 downto 0);
		done_o				: out std_logic
	);

end ddr3_data_traffic_gen;

architecture behavioral of ddr3_data_traffic_gen is

	attribute async_reg : string;

	-- tb process
	type fsm_status is (idle, startdelay, init, write, read, done);
	signal status : fsm_status;
	signal wr_cnt : integer range 0 to num_ops;
	signal rd_cnt : integer range 0 to num_ops;

	-- err_check process
	signal n_errors : std_logic_vector(31 downto 0);

	-- wr pattern generator
	signal wr_pg_rst		: std_logic;
	signal wr_pg_en		: std_logic;
	signal wr_pg_data		: std_logic_vector(255 downto 0);		


	-- exp pattern generator
	signal exp_pg_rst		: std_logic;
	signal exp_pg_en		: std_logic;
	signal exp_pg_data	: std_logic_vector(255 downto 0);	


begin

	-- sending write commands and then read.
	tb : process (rst, clk)
		variable addr		: std_logic_vector(ddr3_addr_width-1 downto 0);	
		variable timer		: integer;
	begin
    if (rst = '1') then
      status            <= idle;
      wr_cnt            <= 0;
      rd_cnt            <= 0;
      -- info to write
      wr_o.addr 			<= (others => '0');
      wr_o.trg  			<= '0';
      -- data to read
      rd_ctrl_o.data 	<= (others => '0');
      rd_ctrl_o.trg  	<= '0';
      -- 
 		addr 					:= (others => '0');

		wr_pg_rst			<= '1';	
		wr_pg_en				<= '0';	

		exp_pg_rst			<= '1';	
		exp_pg_en			<= '0';	
			 
		done_o				<= '0';	
		timer					:= 80000000;
		
		
   elsif (rising_edge(clk)) then
      case (status) is
        
			--========--
			when idle =>
			--========--
			
			if strobe = '1' then
				done_o	<= '0';	
				status 	<= startdelay;
				timer		:= initdelay;
			end if;
			
			--========--
			when startdelay =>
			--========--
			
			if timer = 0 then 
				status 	<= init;
			else
				timer		:= timer-1;
			end if;
			
			--========--
			when init =>
			--========--

			--				
			status 			<= write;
			addr 				:= (others => '0');
			--	
			wr_cnt 			<=  0 ;
			wr_pg_rst		<= '1';	
			wr_pg_en			<= '0';	
			--	
			rd_cnt 			<=  0 ;
			exp_pg_rst		<= '1';	
			exp_pg_en		<= '0';	
			--			

			--========--
			when write =>
         --========--
			 
			wr_pg_rst		<= '0';	
			wr_pg_en			<= '1';	
			wr_o.trg 		<= '0';
			wr_cnt 			<= wr_cnt + 1;
			
			if (wr_cnt < num_ops) then
				--			
				wr_o.trg   	<= '1';
				wr_o.addr	<= addr; -- address step defined by the app data width
				addr		 	:= addr + ddr3_data_width/data_width;			 
				--			
			else
				--			
				status 		<= read;
				wr_pg_rst	<= '0';	
				wr_pg_en		<= '0';	
				exp_pg_rst	<= '1';	
				exp_pg_en	<= '0';	
				addr 			:= (others => '0');
				--			
			end if;
			 
			--========--
			when read =>
			--========--
			
			exp_pg_rst					<= '0';	
			exp_pg_en					<= '1';	
			rd_ctrl_o.trg 		<= '0';
			rd_cnt 						<= rd_cnt + 1;
			
			if (rd_cnt < num_ops) then
				--			
				rd_ctrl_o.trg  	<= '1';
				rd_ctrl_o.data 	<= addr;
				addr		 				:= addr + ddr3_data_width/data_width;
				--			
			else
				--			
				exp_pg_en 	<= '0';	
				status 		<= done;
				--			
			end if;

			--========--
			when done =>
			--========--
			done_o <= '1'; 
			status <= idle;
			
      end case;
    end if;
  end process tb;
--=================================--



--=================================--
err_check : process (rst, clk)
--=================================--
 
	variable data_r	: std_logic_vector (255 downto 0);
	variable addr_r	: std_logic_vector (ddr3_addr_width-1 downto 0);
	variable expaddr	: std_logic_vector (ddr3_addr_width-1 downto 0);

	variable n_errors	: std_logic_vector(31 downto 0);	
	variable n_words	: std_logic_vector(31 downto 0);	


begin
if (rst = '1') then
	
	err_o		<= '0';
	n_errors := (others => '0');
	n_words 	:= (others => '0');
	expaddr 	:= (others => '0');
	
	
elsif (rising_edge(clk)) then

	data_r	:= rd_i.data;
	addr_r 	:= rd_i.addr;

	if (status=read) then
		  
		if (rd_i.trg = '1') then -- data valid
			n_words:= n_words+1;
			if (exp_pg_data /= data_r) or (addr_r /= expaddr)	then	n_errors := n_errors + 1; err_o <= '1';	else err_o <= '0';	end if;
			-- update expected addr
			expaddr	:= expaddr  + ddr3_data_width/data_width;
			--	
		end if;
	
	elsif status = init or status = startdelay or status = write then -- if done or idle do not clear
		err_o		<= '0';
		n_words	:= (others => '0');
		n_errors := (others => '0');
		expaddr 	:= (others => '0');
	end if;
	
	-- output for monitoring purposes	
	exp_rd_o.addr 	<= expaddr; 
	num_errors_o	<= n_errors;
	num_words_o		<= n_words;

end if;
end process err_check;
--=================================--



--=================================--
rnd: if (pattern_type="prbs") generate
--=================================--
begin

	wr_pg_prbs: entity work.prbs 
	generic map (ta => (31,28,0,0), tn => 2, l => 31, w => 256)  --prbs31, 256-bit wide
	port 	  map (clk => clk, rst => wr_pg_rst, enable => wr_pg_en, pdata => wr_pg_data);

	exp_pg_prbs: entity work.prbs 
	generic map (ta => (31,28,0,0), tn => 2, l => 31, w => 256)  --prbs31, 256-bit wide
	port 	  map (clk => clk, rst => exp_pg_rst, enable	=> rd_i.trg, pdata => exp_pg_data);

end generate;
--=================================--



--=================================--
cnt: if pattern_type/="prbs" generate
--=================================--
begin

	wr_pg: entity work.pg
	port map (clk => clk, rst => wr_pg_rst,	enable => wr_pg_en, pg_out => wr_pg_data);
	
	exp_pg: entity work.pg
	port map (clk => clk, rst => exp_pg_rst, enable => rd_i.trg, pg_out => exp_pg_data);

end generate;
--=================================--



--=================================--
exp_rd_o.data 	<= exp_pg_data;
wr_o.data		<= wr_pg_data;
--=================================-- 

  
end behavioral;