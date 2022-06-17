library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


use work.ipbus.all;
use work.system_package.all;
use work.external_memory_interface_definitions.all;

--! user packages
use work.user_package.all;
use work.user_version_package.all;

library unisim;
use unisim.vcomponents.all;

entity user_logic is 
port
(

	--## pcie clk
	pcie_clk_p							: in		std_logic;
	pcie_clk_n							: in		std_logic;
	
	fabric_coax_or_osc_p 			: in 		std_logic;
	fabric_coax_or_osc_n 			: in 		std_logic;

	--## osc mgt clk
	osc_xpoint_a_p						: in		std_logic;
	osc_xpoint_a_n						: in		std_logic;
	osc_xpoint_b_p						: in		std_logic;
	osc_xpoint_b_n						: in		std_logic;
	osc_xpoint_c_p						: in		std_logic;
	osc_xpoint_c_n						: in		std_logic;
	osc_xpoint_d_p						: in		std_logic;
	osc_xpoint_d_n						: in		std_logic;
			
	--## cdce mgt clk		
	ttc_mgt_xpoint_a_p				: in		std_logic;
	ttc_mgt_xpoint_a_n				: in		std_logic;
	ttc_mgt_xpoint_b_p				: in		std_logic;
	ttc_mgt_xpoint_b_n				: in		std_logic;
	ttc_mgt_xpoint_c_p				: in		std_logic;
	ttc_mgt_xpoint_c_n				: in		std_logic;
			
	--# fmc mgt clk		
	fmc_l12_gbtclk0_a_p				: in		std_logic; 
	fmc_l12_gbtclk0_a_n				: in		std_logic; 
	fmc_l12_gbtclk1_a_p				: in		std_logic; 
	fmc_l12_gbtclk1_a_n				: in		std_logic; 
		
	fmc_l12_gbtclk0_b_p				: in		std_logic; 
	fmc_l12_gbtclk0_b_n				: in		std_logic; 
	fmc_l12_gbtclk1_b_p				: in		std_logic; 
	fmc_l12_gbtclk1_b_n				: in		std_logic; 
		
	fmc_l8_gbtclk0_p					: in		std_logic; 
	fmc_l8_gbtclk0_n					: in		std_logic; 
	fmc_l8_gbtclk1_p					: in		std_logic; 
	fmc_l8_gbtclk1_n					: in		std_logic; 
	
	--		
	fmc_i2c_scl							: inout	std_logic;
	fmc_i2c_sda							: inout	std_logic;

	--# gpio			
	usrled1_r							: out		std_logic; -- fmc_l12_spare[8]
	usrled1_g							: out		std_logic; -- fmc_l12_spare[9]
	usrled1_b							: out		std_logic; -- fmc_l12_spare[10]
	usrled2_r							: out		std_logic; -- fmc_l12_spare[11]
	usrled2_g							: out		std_logic; -- fmc_l12_spare[12]
	usrled2_b							: out		std_logic; -- fmc_l12_spare[13]
--	fmc_l12_spare						: inout	std_logic_vector(21 downto 0);
	--
	fmc_l12_dp_c2m_p					: out		std_logic_vector(11 downto 0);
	fmc_l12_dp_c2m_n					: out		std_logic_vector(11 downto 0);
	fmc_l12_dp_m2c_p					: in		std_logic_vector(11 downto 0);
	fmc_l12_dp_m2c_n					: in		std_logic_vector(11 downto 0);
	--
	fmc_l8_dp_c2m_p					: out		std_logic_vector( 7 downto 0);
	fmc_l8_dp_c2m_n					: out		std_logic_vector( 7 downto 0);
	fmc_l8_dp_m2c_p					: in		std_logic_vector( 7 downto 0);
	fmc_l8_dp_m2c_n					: in		std_logic_vector( 7 downto 0);
	--		
	fmc_l8_la_p							: inout	std_logic_vector(33 downto 0);
	fmc_l8_la_n							: inout	std_logic_vector(33 downto 0);
	fmc_l12_la_p						: inout	std_logic_vector(33 downto 0);
	fmc_l12_la_n						: inout	std_logic_vector(33 downto 0);
	--		
	fmc_l8_clk0							: in		std_logic; 
	fmc_l8_clk1             		: in		std_logic;
	fmc_l12_clk0            		: in		std_logic;
	fmc_l12_clk1            		: in		std_logic;	
	--		
	k7_amc_rx_p							: in		std_logic_vector(15 downto 1);
	k7_amc_rx_n							: in		std_logic_vector(15 downto 1);
	amc_tx_p								: out		std_logic_vector(15 downto 1);
	amc_tx_n								: out		std_logic_vector(15 downto 1);
	--		
	k7_fabric_amc_rx_p03				: in		std_logic;
	k7_fabric_amc_rx_n03    		: in		std_logic;
	k7_fabric_amc_tx_p03    		: out		std_logic;
	k7_fabric_amc_tx_n03    		: out		std_logic;
	--		
	fpga_refclkout_p 					: out 	std_logic;
	fpga_refclkout_n 		   		: out 	std_logic;
	--
	ddr3_sys_clk_p 					: in		std_logic;
	ddr3_sys_clk_n 					: in		std_logic;
	ddr3_dq                 		: inout 	std_logic_vector( 31 downto 0);
	ddr3_dqs_p              		: inout 	std_logic_vector(  3 downto 0);
	ddr3_dqs_n              		: inout 	std_logic_vector(  3 downto 0);
	ddr3_addr               		: out   	std_logic_vector( 13 downto 0);
	ddr3_ba                 		: out   	std_logic_vector(  2 downto 0);
	ddr3_ras_n              		: out   	std_logic;
	ddr3_cas_n              		: out   	std_logic;
	ddr3_we_n               		: out   	std_logic;
	ddr3_reset_n            		: out   	std_logic;
	ddr3_ck_p               		: out   	std_logic_vector(  0 downto 0);
	ddr3_ck_n               		: out   	std_logic_vector(  0 downto 0);
	ddr3_cke                		: out   	std_logic_vector(  0 downto 0);
	ddr3_cs_n               		: out   	std_logic_vector(  0 downto 0);
	ddr3_dm                 		: out   	std_logic_vector(  3 downto 0);
	ddr3_odt                		: out   	std_logic_vector(  0 downto 0);
	--==========================--		
	-- system_core interface		
	--==========================--		
	ip_addr_o							: out		std_logic_vector(31 downto 0);
	mac_addr_o							: out		std_logic_vector(47 downto 0);
	rarp_en_o							: out		std_logic;
	use_i2c_eeprom_o					: out		std_logic;
	
	
	fabric_clk_bufg_i					: in	 	std_logic;
	osc125_a_bufg_i					: in	 	std_logic;
	osc125_a_mgtrefclk_i				: in		std_logic;
	osc125_b_bufg_i					: in	 	std_logic;
	osc125_b_mgtrefclk_i				: in		std_logic;

	ipb_rst_i				         : in	  std_logic;
	ipb_clk_i				         : in	  std_logic;
	ipb_clk_o				         : out	  std_logic;
	ipb_miso_o			            : out	  ipb_rbus_array(0 to nbr_usr_slaves-1);
	ipb_mosi_i			            : in	  ipb_wbus_array(0 to nbr_usr_slaves-1)	
);
end user_logic;

architecture usr of user_logic is

	signal ipb_clk									: std_logic;
	--			
	signal ctrl_reg		         			: array_32x32bit;
	signal stat_reg		         			: array_32x32bit;
			
	signal ddr3_sys_clk_prebuf					: std_logic;
	signal ddr3_sys_clk_bufg					: std_logic;
	signal ddr3_hb									: std_logic;
	signal ddr3_num_errors						: std_logic_vector(31 downto 0);
	signal ddr3_err								: std_logic;
	signal ddr3_traffic_str						: std_logic;
	signal ddr3_sys_rst_n						: std_logic;
	signal ddr3_done								: std_logic;
	
	signal ddr3_clk_ref                    : std_logic;
	signal ddr3_pll_clkfb_in               : std_logic;
	signal ddr3_pll_clkfb_out					: std_logic;
	signal init_calib_complete            	: std_logic;

	-- usr access port
	signal usr_ddr3_clk		               : std_logic;
	signal usr_ddr3_rst		               : std_logic;
	signal usr_ddr3_wr			           	: ddr3_full_info_trig_type;
	signal usr_ddr3_wr_rdy                 : std_logic;
	signal usr_ddr3_rd_ctrl	               : ddr3_addr_trig_type;
	signal usr_ddr3_rd		               : ddr3_full_info_trig_type;
	signal usr_ddr3_rd_rdy                 : std_logic;
	signal usr_ddr3_rd_exp						: ddr3_full_info_trig_type;
	
	-- ipb access port
	signal ipb_ddr3_wr			            : ddr3_full_info_trig_type;
	signal ipb_ddr3_wr_rdy                 : std_logic;
	signal ipb_ddr3_rd_ctrl	               : ddr3_addr_trig_type;
	signal ipb_ddr3_rd		               : ddr3_full_info_trig_type;
	signal ipb_ddr3_rd_rdy                 : std_logic;
	
	signal fabric_coax_or_osc_pre_buf		: std_logic;
	signal fabric_coax_or_osc					: std_logic;

	attribute keep     							: string;  
 	attribute keep of init_calib_complete 	: signal is "true";
	attribute keep of ddr3_sys_rst_n       : signal is "true";

	attribute keep of usr_ddr3_clk       	: signal is "true";
	attribute keep of usr_ddr3_wr       	: signal is "true";
	attribute keep of usr_ddr3_wr_rdy      : signal is "true";
	attribute keep of usr_ddr3_rd_ctrl     : signal is "true";
	attribute keep of usr_ddr3_rd       	: signal is "true";
	attribute keep of usr_ddr3_rd_rdy      : signal is "true";
	attribute keep of usr_ddr3_rd_exp      : signal is "true";


begin


	--===========================================--
	-- clk management
	--===========================================--
	ipb_clk 		<= ipb_clk_i; 				-- option A: use 31.25MHz as ipb_clk
--	ipb_clk 		<= fabric_clk_bufg_i; 	-- option B: use LHC clk  as ipb_clk
	ipb_clk_o 	<= ipb_clk;					-- always forward the selected ipb_clk to system core


	ddr3_clk_ibuf : ibufgds port map(i => ddr3_sys_clk_p, ib => ddr3_sys_clk_n, 	o => ddr3_sys_clk_prebuf);
	ddr3_clk_bufg : bufg 	port map(i => ddr3_sys_clk_prebuf, 						o => ddr3_sys_clk_bufg);

	osc_ibuf: ibufgds port map (i => fabric_coax_or_osc_p, ib => fabric_coax_or_osc_n, 	o => fabric_coax_or_osc_pre_buf);
	osc_bufg: bufg 	port map (i => fabric_coax_or_osc_pre_buf, 								o => fabric_coax_or_osc);
	--===========================================--	



	--===========================================--	
	ddr3_led:entity work.hb generic map(freq	=> 240_000_000) port map( rst => '0', i => ddr3_sys_clk_bufg, o => ddr3_hb);
	--===========================================--	

	

	--===========================================--
	-- ip & mac
	--===========================================--
	ip_addr_o 			<= x"c0_a8_00_50";			
	mac_addr_o			<= x"aa_bb_cc_dd_ee_50";	
	rarp_en_o 			<= '0';
	use_i2c_eeprom_o	<= '0'; 
	--===========================================--


	
	--===========================================--
	stat_regs_inst: entity work.ipb_user_status_regs
	--===========================================--
	port map
	(
		reset					=> ipb_rst_i,
		clk					=> ipb_clk,
		ipb_mosi_i			=> ipb_mosi_i(user_ipb_stat_regs),
		ipb_miso_o			=> ipb_miso_o(user_ipb_stat_regs),
		regs_i				=> stat_reg
	);
	--===========================================--



	--===========================================--
	ctrl_regs_inst: entity work.ipb_user_control_regs
	--===========================================--
	port map
	(
		reset					=> ipb_rst_i,
		clk					=> ipb_clk,
		ipb_mosi_i			=> ipb_mosi_i(user_ipb_ctrl_regs),
		ipb_miso_o			=> ipb_miso_o(user_ipb_ctrl_regs),
		regs_o				=> ctrl_reg
	);
	--===========================================--
		


	--===========================================--
	u_ipb_ddr3: entity work.ipb_ddr3
	--===========================================--
	port map
	(
		reset_i				=> ipb_rst_i,
		------------------
		ipb_clk_i			=> ipb_clk,
		ipb_mosi_i			=> ipb_mosi_i(user_ddr3),
		ipb_miso_o			=> ipb_miso_o(user_ddr3),
		------------------
--		ddr3_wr_rdy			=> ipb_ddr3_wr_rdy,
		ddr3_wr_addr		=> ipb_ddr3_wr.addr,
		ddr3_wr_data		=> ipb_ddr3_wr.data,
		ddr3_wr_req			=> ipb_ddr3_wr.trg,
		--
--		ddr3_rd_rdy			=> ipb_ddr3_rd_rdy,
		ddr3_rd_ctrl_addr	=> ipb_ddr3_rd_ctrl.data,
		ddr3_rd_ctrl_req	=> ipb_ddr3_rd_ctrl.trg,
		ddr3_rd_valid		=> ipb_ddr3_rd.trg,
		ddr3_rd_data		=> ipb_ddr3_rd.data,
		ddr3_rd_addr		=> ipb_ddr3_rd.addr
	);
	--===========================================--

	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--

	--===========================================--
	pll: entity work.ddr3_pll
	--===========================================--
	port map
	(
		reset => '0',
		clk_in1 => fabric_coax_or_osc,
		clk_out1 => ddr3_clk_ref,
--		clkfb_in => ddr3_pll_clkfb_in,
--		clkfb_out => ddr3_pll_clkfb_out,
		locked => open
	);
	--===========================================--



	--===========================================--
	ddr3 : entity work.external_memory_interface_wrapper
	--===========================================--
	port map 
	(
		------- layer 0, physical interface ---------         
		sys_rst        	=> (ddr3_sys_rst_n and (not ipb_rst_i)), -- negative logic
		sys_clk      		=> ddr3_sys_clk_bufg,
		clk_ref      		=> ddr3_clk_ref,
		-- ddr3 pins -----
		ddr3_dq        	=> ddr3_dq,
		ddr3_dqs_n    		=> ddr3_dqs_n,
		ddr3_dqs_p     	=> ddr3_dqs_p,
		ddr3_addr      	=> ddr3_addr(row_width-1 downto 0),
		ddr3_ba        	=> ddr3_ba,
		ddr3_ras_n     	=> ddr3_ras_n,
		ddr3_cas_n     	=> ddr3_cas_n,
		ddr3_we_n      	=> ddr3_we_n,
		ddr3_reset_n   	=> ddr3_reset_n,
		ddr3_ck_p   		=> ddr3_ck_p,
		ddr3_ck_n   		=> ddr3_ck_n,
		ddr3_cke    		=> ddr3_cke,
		ddr3_cs_n   		=> ddr3_cs_n,
		ddr3_dm        	=> ddr3_dm,
		ddr3_odt    		=> ddr3_odt,
		-- clock out and control signals
		mem_clk_out    	=> open,
		calib_done     	=> init_calib_complete,

		--------- layer 1, user interface  ---------      

		--== port a: usr_logic ======--
		port_a_rst    		=> usr_ddr3_rst,
		port_a_clk       	=> usr_ddr3_clk,
		port_a_wr_rdy    	=> usr_ddr3_wr_rdy,
		port_a_wr 			=> usr_ddr3_wr,
		port_a_rd_rdy    	=> usr_ddr3_rd_rdy,
		port_a_rd_ctrl	 	=> usr_ddr3_rd_ctrl,
		port_a_rd    		=> usr_ddr3_rd,
		--== port b: ipbus ======--
		port_b_rst    		=> ipb_rst_i,
		port_b_clk       	=> ipb_clk,
		port_b_wr_rdy    	=> ipb_ddr3_wr_rdy,
		port_b_wr 			=> ipb_ddr3_wr,
		port_b_rd_rdy    	=> ipb_ddr3_rd_rdy,
		port_b_rd_ctrl	 	=> ipb_ddr3_rd_ctrl,
		port_b_rd    		=> ipb_ddr3_rd
	);  
	--===========================================--



	--===========================================--
		usr_ddr3_rst 		<= ipb_rst_i;	
		usr_ddr3_clk 		<= fabric_clk_bufg_i;
	--===========================================--



	--===========================================--
	traffic_gen : entity work.ddr3_data_traffic_gen
   --===========================================--
	generic map 
	(
		num_ops 				=> (2**ddr3_addr_width)/(ddr3_data_width/8), --  ops = 2**28 / 256bits in bytes
		pattern_type		=> "prbs" --"cnt8"
	) 
   port map 
	(
		rst            	=> usr_ddr3_rst,
		clk             	=> usr_ddr3_clk,
		strobe      		=> ddr3_traffic_str,
		
		wr_o 					=> usr_ddr3_wr, 			
		rd_ctrl_o 			=> usr_ddr3_rd_ctrl,	
		rd_i    				=> usr_ddr3_rd,			
		exp_rd_o				=> usr_ddr3_rd_exp,
		-- error checking
		num_errors_o     	=> ddr3_num_errors,
		err_o   				=> ddr3_err,
		done_o				=> ddr3_done
	);
	--===========================================--

	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--
	--###########################################--

   --===========================================--
	-- register mapping
	--===========================================--
									stat_reg(0)		<= usr_id_0;
									stat_reg(1)(0)	<= init_calib_complete;
									stat_reg(1)(4)	<= ddr3_err ; -- not really useful
									stat_reg(1)(8)	<= ddr3_done; 
									stat_reg(2)		<= firmware_id;
									stat_reg(3)		<= ddr3_num_errors;
																		
	ddr3_sys_rst_n			<= ctrl_reg(0)(0);
	ddr3_traffic_str		<= ctrl_reg(0)(4);
	--===========================================--
	


   --===========================================--
	-- IO mapping
	--===========================================--

	usrled1_r				<= init_calib_complete;
	usrled1_g				<= not init_calib_complete;
	usrled1_b				<= '1';
	
	usrled2_r				<= not ddr3_hb;
	usrled2_g				<= '1';
	usrled2_b				<= not ddr3_hb;
	
	amc_tx_p(15)			<= '0' when usr_ddr3_rd_exp.data=0 else '1'; -- for debugging only
	--===========================================--
	

end usr;