library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

use work.external_memory_interface_definitions.all;

entity top_entity is
    port (
        fabric_clk_n   	: in    std_logic; 
        fabric_clk_p   	: in    std_logic;
		  sysled1_r			: out   std_logic;
		  sysled1_b			: out   std_logic;
		  sysled2_g			: out   std_logic;
        -- ddr3 memory signals
        ddr3_dqs_p     	: inout std_logic_vector (3 downto 0);
        ddr3_dqs_n     	: inout std_logic_vector (3 downto 0);
        ddr3_dq        	: inout std_logic_vector (31 downto 0);
        ddr3_event_n   	: inout std_logic;
        ddr3_ck_p     	: out   std_logic_vector (0 downto 0);
        ddr3_ck_n     	: out   std_logic_vector (0 downto 0);
        ddr3_cke       	: out   std_logic_vector (0 downto 0);
        ddr3_ba        	: out   std_logic_vector (2 downto 0);
        ddr3_addr      	: out   std_logic_vector (14 downto 0);
        ddr3_ras_n     	: out   std_logic;
        ddr3_cas_n     	: out   std_logic;
        ddr3_we_n      	: out   std_logic;
        ddr3_dm        	: out   std_logic_vector (3 downto 0);
        ddr3_odt       	: out   std_logic_vector (0 downto 0);
        ddr3_cs_n       : out   std_logic_vector (0 downto 0);
        ddr3_reset_n   	: out   std_logic
    );
end top_entity;

architecture behavioral of top_entity is
    
attribute keep     							: string;  
   
signal init_calib_complete            	: std_logic;
attribute keep of init_calib_complete 	: signal is "true";
signal ddr3_rst_n                      : std_logic := '0';
attribute keep of ddr3_rst_n           : signal is "true";

signal port_a_wr                 		: ddr3_full_info_trig_type;
signal port_a_wr_rdy                   : std_logic;
signal port_a_rd_ctrl                 	: ddr3_addr_trig_type;
signal port_a_rd_rdy                   : std_logic;
signal port_a_rd                    	: ddr3_full_info_trig_type;

signal port_b_wr                			: ddr3_full_info_trig_type;
signal port_b_wr_rdy                   : std_logic;
signal port_b_rd_ctrl                 	: ddr3_addr_trig_type;
signal port_b_rd_rdy                   : std_logic;
signal port_b_rd                    	: ddr3_full_info_trig_type;
				
signal clk_240mhz 							: std_logic;
signal clk_200mhz 							: std_logic;
signal clk_40mhz 								: std_logic;
signal pll_lock  								: std_logic;
signal rst_40mhz 								: std_logic;
				
signal rst_fabric								: std_logic := '0';

-- test signals
signal ddr3_traffic_str 						: std_logic; 
signal p_ddr3_num_errors 					: std_logic_vector (31 downto 0);
signal p_ddr3_err								: std_logic;
signal exp_port_a_rd               	: ddr3_full_info_trig_type;


				
-- chipscope				
				
signal vio_ddr3_rst_n      				: std_logic := '0';
signal vio_rst_ddr3_gen_n  				: std_logic := '0';
signal control_vio 							: std_logic_vector (35 downto 0);
signal control_ila 							: std_logic_vector (35 downto 0);

    
begin

	--
	sysled1_r	<= not rst_40mhz; 				-- on when reset asserted
	sysled1_b	<= not init_calib_complete; 	-- on when init completed
	
	blink: 		entity work.hb port map(rst => not pll_lock, i => clk_40mhz, o => sysled2_g);
	--	


  u_fabric_pll : entity work.fabric_pll
  port map
   (-- clock in ports
    clk_in1_p => fabric_clk_p,
    clk_in1_n => fabric_clk_n,
    -- clock out ports
    clk_ox6 => clk_240mhz,
    clk_ox4 => clk_200mhz,
    clk_ox1 => clk_40mhz,
    -- status and control signals
    reset  	=> '0',
    locked 	=> pll_lock);

    process (clk_40mhz)
    begin
        if (rising_edge(clk_40mhz)) then
            rst_40mhz <= not pll_lock;
        end if;
    end process;
    
		u_external_memory_interface_wrapper : entity work.external_memory_interface_wrapper
      port map (------- layer 0, physical interface ---------         
        sys_clk      	=> clk_240mhz,
        clk_ref      	=> clk_200mhz,
        sys_rst        	=> vio_ddr3_rst_n, -- negative logic
        -- inouts -----
        ddr3_dq        	=> ddr3_dq,
        ddr3_dqs_n    	=> ddr3_dqs_n,
        ddr3_dqs_p     	=> ddr3_dqs_p,
        -- outputs -----
        ddr3_addr      	=> ddr3_addr(row_width-1 downto 0),
        ddr3_ba        	=> ddr3_ba,
        ddr3_ras_n     	=> ddr3_ras_n,
        ddr3_cas_n     	=> ddr3_cas_n,
        ddr3_we_n      	=> ddr3_we_n,
        ddr3_reset_n   	=> ddr3_reset_n,
        ddr3_ck_p(0)   	=> ddr3_ck_p(0),
        ddr3_ck_n(0)   	=> ddr3_ck_n(0),
        ddr3_cke(0)    	=> ddr3_cke(0),
        ddr3_cs_n(0)   	=> ddr3_cs_n(0),
        ddr3_dm        	=> ddr3_dm,
        ddr3_odt(0)    	=> ddr3_odt(0),
        -- clock out and control signals
        mem_clk_out    	=> open,
        calib_done     	=> init_calib_complete,
        --------- layer 1, user interface  ---------      
        -- port a
        port_a_rst    	=> rst_40mhz,
        port_a_clk      => clk_40mhz,
        port_a_wr_rdy   => port_a_wr_rdy,
        port_a_wr 		=> port_a_wr,
        port_a_rd_rdy   => port_a_rd_rdy,
        port_a_rd_ctrl	=> port_a_rd_ctrl,
        port_a_rd    	=> port_a_rd,
        --== port b: 
        port_b_rst    	=> rst_40mhz,
        port_b_clk      => clk_40mhz,
        port_b_wr_rdy   => port_b_wr_rdy,
        port_b_wr 		=> port_b_wr,
        port_b_rd_rdy   => port_b_rd_rdy,
        port_b_rd_ctrl	=> port_b_rd_ctrl,
        port_b_rd    	=> port_b_rd);  

   -- u_pattern_generator : entity work.pattern_generator
	u_testbench : entity work.ddr3_data_traffic_gen
   generic map 
	(
		num_ops 				=> (2**ddr3_addr_width)/(ddr3_data_width/8), --  ops = 2**28 / 256bits in bytes
		pattern_type		=> "prbs"
	) 
	port map 
	( 
		clk             	=> clk_40mhz,
		rst            	=> rst_40mhz,
		strobe      		=> ddr3_traffic_str,
		wr_o 					=> port_a_wr,
		rd_ctrl_o		 	=> port_a_rd_ctrl,
		rd_i	    			=> port_a_rd,
		exp_rd_o				=> exp_port_a_rd,
		num_errors_o   	=> p_ddr3_num_errors,
		err_o    			=> p_ddr3_err
		);

	 ddr3_traffic_str <= (not vio_rst_ddr3_gen_n) and init_calib_complete;


    u_ddr3_cntrl_vio : entity work.ddr3_cntrl_vio
    port map (
        control 		=> control_vio,
        async_in(0) 	=> init_calib_complete,
        async_out(0) => vio_ddr3_rst_n,
        async_out(1) => vio_rst_ddr3_gen_n);


    u_vio_cntrl : entity work.vio_cntrl
      port map (
        control0 		=> control_vio,
        control1 		=> control_ila);


    u_ddr3_ila : entity work.ddr3_ila
      port map (
        control 		=> control_ila,
        clk 			=> clk_40mhz,
        trig0 			=> port_a_rd.data,
        trig1 			=> port_a_rd.addr,
        trig2(0) 		=> port_a_rd.trg,
		  trig3 			=> port_a_wr.data,
        trig4 			=> port_a_wr.addr,
        trig5(0) 		=> port_a_wr.trg,
		  trig6 			=> p_ddr3_num_errors,
        trig7(0) 		=> p_ddr3_err,
		  trig8 			=> exp_port_a_rd.data,
        trig9 			=> exp_port_a_rd.addr
        );

end behavioral;
