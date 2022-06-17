library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--! xilinx packages
library unisim;
use unisim.vcomponents.all;
--! system packages
use work.ipbus.all;


entity ipb_ddr3 is
generic
(
	addr_width			: positive:=  28;
	data_width			: positive:= 256
);
port
(
	reset_i				: in 	std_logic;
	------------------
	ipb_clk_i			: in 	std_logic;
	ipb_mosi_i			: in 	ipb_wbus;
	ipb_miso_o			: out ipb_rbus;
	------------------
--	ddr3_wr_rdy			: in	std_logic;
	ddr3_wr_addr		: out	std_logic_vector(addr_width-1 downto 0);
	ddr3_wr_data		: out	std_logic_vector(data_width-1 downto 0);
	ddr3_wr_req			: out	std_logic;
	--
--	ddr3_rd_rdy			: in	std_logic;
	ddr3_rd_ctrl_addr	: out	std_logic_vector(addr_width-1 downto 0);
	ddr3_rd_ctrl_req	: out	std_logic;
	ddr3_rd_valid		: in	std_logic;
	ddr3_rd_data		: in	std_logic_vector(data_width-1 downto 0);
	ddr3_rd_addr		: in	std_logic_vector(addr_width-1 downto 0)
);
	
end ipb_ddr3;		

architecture rtl of ipb_ddr3 is                              	


begin-- ARCHITECTURE



	process(ipb_clk_i, reset_i)
		
		variable prev_wr_addr	: std_logic_vector(31 downto 0);
		variable prev_rd_addr	: std_logic_vector(31 downto 0);

		variable rdata_latched	: std_logic_vector(data_width-1 downto 0);	
		variable ddr3_rdata_r	: std_logic_vector(data_width-1 downto 0);	
		variable ddr3_rd_valid_r: std_logic;	

		variable wr_req			: std_logic;
		variable rd_req			: std_logic;
		variable ipb_rd_rdy		: std_logic;
		
	begin
	if reset_i='1' then

		ipb_miso_o.ipb_ack	<='0'; 
		ddr3_wr_req 			<='0';
		ddr3_rd_ctrl_req 		<='0'; 	
		ipb_rd_rdy				:='0';
		
	elsif rising_edge(ipb_clk_i) then

		ipb_miso_o.ipb_ack	<='0'; 
		ddr3_wr_req 			<='0';
		ddr3_rd_ctrl_req 		<='0'; 	
		
		if ipb_mosi_i.ipb_strobe='1' then
			
			--==============================--
			-- WRITE TRANSACTIONS
			--==============================--
			
			if ipb_mosi_i.ipb_write='1' then
				
				ipb_rd_rdy:='0'; -- when write, clear the ipb_rd_rdy flag
		
				
				--================================--
				-- slow but can cope with any block transaction
				--================================--
--				if ddr3_wr_rdy = '1' then
					case ipb_mosi_i.ipb_addr(2 downto 0) is
						when "000"	=> ddr3_wr_data( 31 downto   0) 	<= ipb_mosi_i.ipb_wdata;
						when "001"	=> ddr3_wr_data( 63 downto  32) 	<= ipb_mosi_i.ipb_wdata; 
						when "010" 	=> ddr3_wr_data( 95 downto  64) 	<= ipb_mosi_i.ipb_wdata; 
						when "011"	=> ddr3_wr_data(127 downto  96) 	<= ipb_mosi_i.ipb_wdata; 
						when "100"	=> ddr3_wr_data(159 downto 128) 	<= ipb_mosi_i.ipb_wdata; 
						when "101"	=> ddr3_wr_data(191 downto 160) 	<= ipb_mosi_i.ipb_wdata; 
						when "110"	=> ddr3_wr_data(223 downto 192) 	<= ipb_mosi_i.ipb_wdata;  									wr_req:='1'; -- ensure one cycle wr_req
						when "111"	=> ddr3_wr_data(255 downto 224) 	<= ipb_mosi_i.ipb_wdata; 	ddr3_wr_req <= wr_req; 	wr_req:='0';			
																														ddr3_wr_addr<= ipb_mosi_i.ipb_addr(addr_width-1 downto 3) & "000"; 
						when others	=> 
						end case;
					--# ack #--
					if ipb_mosi_i.ipb_addr/=prev_wr_addr then -- in the first transaction, dont compare with the previous address
						ipb_miso_o.ipb_ack <= '1';
					end if;
--				else -- what happens when ddr3 not ready?
--				end if;
				prev_wr_addr := ipb_mosi_i.ipb_addr;			
			

			--==============================--
			-- READ TRANSACTIONS
			--==============================--
			elsif ipb_mosi_i.ipb_write='0' then

				--## read request from ddr3
				if ipb_mosi_i.ipb_addr(2 downto 0)="000" and rd_req='1' then
				
					ddr3_rd_ctrl_req  <= rd_req; rd_req:='0';
					ddr3_rd_ctrl_addr <= ipb_mosi_i.ipb_addr(addr_width-1 downto 3) & "000";				
					prev_rd_addr 		:= (others => '1');
					ipb_rd_rdy			:= '0';
				
				--## get data from ddr3
				elsif ddr3_rd_valid_r='1' then 
				
					rdata_latched	:= ddr3_rdata_r; 
					ipb_rd_rdy 		:= '1';
				
				--## split the data to chunks of 32bit
				elsif ipb_rd_rdy='1' then
				
					case ipb_mosi_i.ipb_addr(2 downto 0) is
						when "000" => ipb_miso_o.ipb_rdata <= rdata_latched( 31 downto   0);
						when "001" => ipb_miso_o.ipb_rdata <= rdata_latched( 63 downto  32);
						when "010" => ipb_miso_o.ipb_rdata <= rdata_latched( 95 downto  64);
						when "011" => ipb_miso_o.ipb_rdata <= rdata_latched(127 downto  96);
						when "100" => ipb_miso_o.ipb_rdata <= rdata_latched(159 downto 128);
						when "101" => ipb_miso_o.ipb_rdata <= rdata_latched(191 downto 160);
						when "110" => ipb_miso_o.ipb_rdata <= rdata_latched(223 downto 192);
						when "111" => ipb_miso_o.ipb_rdata <= rdata_latched(255 downto 224); rd_req:='1';
						when others=>
					end case;
				
					--# ack #--
					if ipb_mosi_i.ipb_addr/=prev_rd_addr then -- in the first transaction, dont compare with the previous address
						ipb_miso_o.ipb_ack <= '1';
					end if;
					prev_rd_addr := ipb_mosi_i.ipb_addr;			
				
				end if;	
			
				
			
			
			
			end if; -- ipb_mosi_i.ipb_write='0'
			
		elsif ipb_mosi_i.ipb_strobe='0' then	

			prev_wr_addr 			:= x"ffff_ffff";
			prev_rd_addr 			:= x"ffff_ffff";
			rd_req					:='1';

		end if;

		
		ddr3_rdata_r			:= ddr3_rd_data; 
		ddr3_rd_valid_r		:= ddr3_rd_valid;
	
	end if;
	end process;

	ipb_miso_o.ipb_err <= '0'; 


end rtl;