library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity serdes_rx is
generic
(
  	idelayctrl_gen				: boolean	:=true;
	idelaygroup					: string		:="l8_idelay_group";
	sys_w       				: integer 	:= 1;
	dev_w       				: integer 	:= 5
);
port
 (
  -- from the system into the device
  data_in_from_pins_p     : in    std_logic_vector(  sys_w-1 downto 0);
  data_in_from_pins_n     : in    std_logic_vector(  sys_w-1 downto 0);
  data_in_to_device       : out   std_logic_vector(  dev_w-1 downto 0);

-- input, output delay control signals
  in_delay_ld		        : in    std_logic_vector(  sys_w-1 downto 0);	-- load delay values
  in_delay_data_ce        : in    std_logic_vector(  sys_w-1 downto 0); -- enable signal for delay 
  in_delay_data_inc       : in    std_logic_vector(  sys_w-1 downto 0); -- delay increment (high), decrement (low) signal
  in_delay_tap_in         : in    std_logic_vector(5*sys_w-1 downto 0); -- dynamically loadable delay tap value for input delay
  in_delay_tap_out        : out   std_logic_vector(5*sys_w-1 downto 0); -- delay tap value for monitoring input delay
  delay_locked            : out   std_logic;                    			-- locked signal from idelayctrl
  ref_clock               : in    std_logic;                    			-- reference clock for idelayctrl. has to come from bufg.
  bitslip                 : in    std_logic_vector(  sys_w-1 downto 0); -- vichoudis                  -- bitslip module is enabled in networking mode
																								-- user should tie it to '0' if not needed
 
-- clock and reset signals
  clk_in                  : in    std_logic;                    			-- fast clock from pll/mmcm 
  clk_div_in              : in    std_logic;                    			-- slow clock from pll/mmcm
  clk_reset               : in    std_logic;                    			-- reset signal for clock circuit
  io_reset                : in    std_logic);                   			-- reset signal for io circuit
end serdes_rx;

architecture xilinx of serdes_rx is
  attribute core_generation_info            	: string;

  attribute core_generation_info of xilinx  	: architecture is "selectio_if_wiz_v4_1,selectio_wiz_v4_1,{component_name=selectio_if_wiz_v4_1,bus_dir=inputs,bus_sig_type=diff,bus_io_std=lvds_25,use_serialization=true,use_phase_detector=false,serialization_factor=5,enable_bitslip=false,enable_train=false,system_data_width=1,bus_in_delay=none,bus_out_delay=none,clk_sig_type=diff,clk_io_std=lvcmos18,clk_buf=bufio2,active_edge=rising,clk_delay=none,v6_bus_in_delay=var_loadable,v6_bus_out_delay=none,v6_clk_buf=mmcm,v6_active_edge=sdr,v6_ddr_alignment=same_edge_pipelined,v6_oddr_alignment=same_edge,ddr_alignment=c0,v6_interface_type=networking,interface_type=networking,v6_bus_in_tap=0,v6_bus_out_tap=0,v6_clk_io_std=lvds_25,v6_clk_sig_type=diff}";
  constant 	unused 									: std_logic := '0';
  signal data_in_from_pins_int     				: std_logic_vector(sys_w-1 downto 0);
  signal data_in_from_pins_delay   				: std_logic_vector(sys_w-1 downto 0);
  constant num_serial_bits         				: integer := dev_w/sys_w;
  type   serdarr 										is array (0 to dev_w-1) of std_logic_vector(sys_w-1 downto 0);
  signal iserdes_q                 				: serdarr := (( others => (others => '0')));
  signal clk_in_int_inv           				: std_logic;

  attribute iodelay_group 							: string;

begin


  -- we have multiple bits- step over every bit, instantiating the required elements
  pins: for j in 0 to sys_w-1 generate 
    attribute iodelay_group of idelaye2_bus: label is idelaygroup;
  begin
    -- instantiate the buffers
    ----------------------------------
    -- instantiate a buffer for every bit of the data bus
     ibufds_inst : ibufds
       generic map (
         diff_term  => false,             -- differential termination
         iostandard => "lvds_25")
       port map (
         i          => data_in_from_pins_p  (j),
         ib         => data_in_from_pins_n  (j),
         o          => data_in_from_pins_int(j));

    -- instantiate the delay primitive
    -----------------------------------

     idelaye2_bus : idelaye2
       generic map (
         cinvctrl_sel           => "false",            -- true, false
         delay_src              => "idatain",        -- idatain, datain
         high_performance_mode  => "true",             -- true, false
         idelay_type            => "var_load",          -- fixed, variable, or var_loadable
         idelay_value           => 0,       			 -- 0 to 31
         refclk_frequency       => 200.0,
         pipe_sel               => "false",
         signal_pattern         => "data"           -- clock, data
         )
         port map (
         regrst                 => io_reset,
         c                      => clk_div_in,
         datain                 => unused, 								-- data from fpga logic
         idatain                => data_in_from_pins_int  (j), 	-- driven by iob
         dataout                => data_in_from_pins_delay(j),
         ce                     => in_delay_data_ce(j), 
         inc                    => in_delay_data_inc(j), 
         ld                     => in_delay_ld(j),
         cntvaluein             => in_delay_tap_in	(5*(j+1)-1 downto 5*j),
         cntvalueout            => in_delay_tap_out(5*(j+1)-1 downto 5*j),
         ldpipeen               => '0',
         cinvctrl               => '0'
         );




     -- instantiate the serdes primitive
     ----------------------------------

		clk_in_int_inv <= not clk_in;


     -- declare the iserdes
     iserdese2_master : iserdese2
       generic map (
         data_rate         => "sdr",
         data_width        => 5,
         interface_type    => "networking", 
         dyn_clkdiv_inv_en => "false",
         dyn_clk_inv_en    => "false",
         num_ce            => 2,
         ofb_used          => "false",
         iobdelay          => "ifd",                              -- use input at ddly to output the data on q1-q6
         serdes_mode       => "master")
       port map (
         q1                => iserdes_q(0)(j),
         q2                => iserdes_q(1)(j),
         q3                => iserdes_q(2)(j),
         q4                => iserdes_q(3)(j),
         q5                => iserdes_q(4)(j),
         q6                => open,
         q7                => open,
         q8                => open,
         shiftout1         => open,               			 -- cascade connection to slave iserdes
         shiftout2         => open,               			 -- cascade connection to slave iserdes
         bitslip           => bitslip(j),                 -- 1-bit invoke bitslip. this can be used with any 
                                                          -- data_width, cascaded or not.
         ce1               => '1',               			 -- 1-bit clock enable input
         ce2               => '1',               			 -- 1-bit clock enable input
         clk               => clk_in,                     -- fast clock driven by mmcm
         clkb              => clk_in_int_inv,             -- locally inverted clock
         clkdiv            => clk_div_in,                 -- slow clock driven by mmcm
         clkdivp           => '0',
         d                 => '0',                                
         ddly              => data_in_from_pins_delay(j), -- 1-bit input signal from iodelaye1.
         rst               => io_reset,                   -- 1-bit asynchronous reset only.
         shiftin1          => '0',
         shiftin2          => '0',
        -- unused connections
         dynclkdivsel      => unused,
         dynclksel         => unused,
         ofb               => unused,
         oclk              => unused,
         oclkb             => unused,
         o                 => open);                              -- unregistered output of iserdese1

		
		concatenate: for slice_count in 0 to num_serial_bits-1 generate 
				data_in_to_device(j*num_serial_bits+slice_count) <= iserdes_q(num_serial_bits-slice_count-1)(j);
		end generate concatenate;  
	
	end generate pins;


	gen: if idelayctrl_gen=true generate
		attribute iodelay_group of delayctrl : label is idelaygroup;
	begin
		delayctrl : idelayctrl port map ( rdy => delay_locked, refclk => ref_clock, rst => io_reset );
	end generate;

end xilinx;