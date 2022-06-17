library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

--! xilinx packages
library unisim;
use unisim.vcomponents.all;

entity tts_rx is
generic 
(
	idelayctrl_gen								: boolean :=true;
	idelaygroup									: string	 :="l8_idelay_group";
	nbr_channels								: integer range 0 to 16	:= 2;  -- maximum 16
	bitslip_delay								: integer := 1024;
	consecutive_valid_chars_to_lock     : integer := 1024;
	misaligned_state_code 					: std_logic_vector(7 downto 0); 
	allow_all_0000xxxx                  : boolean 
); 
port
(
	reset_i				: in 	std_logic;
	clk_i					: in 	std_logic;
	pclk_i				: in 	std_logic;	-- parallel clock
	sclk_i				: in 	std_logic;	-- serial clock			
	------------------
	align_str_i			: in 	std_logic_vector(   nbr_channels-1 downto 0);   -- when 0, in alignment cycle, to realign 0->1->0
	aligned_o			: out	std_logic_vector(   nbr_channels-1 downto 0);	-- when 1, bitslip is successful
	------------------
	idelay_manual_i	: in  std_logic;
	idelay_ld_i	   	: in  std_logic_vector(   nbr_channels-1 downto 0);	-- strobe for loading input delay values
	idelay_tap_i   	: in  std_logic_vector( 5*nbr_channels-1 downto 0); -- dynamically loadable delay tap value for input delay
	idelay_tap_o      : out std_logic_vector( 5*nbr_channels-1 downto 0); -- delay tap value for monitoring input delay
	idelay_locked_o	: out	std_logic;												-- idelay ctrl locked
	idelay_clk_i		: in	std_logic;												-- reference clock for idelayctrl. has to come from bufg.
	------------------
	stats_clr			: in  std_logic_vector(   nbr_channels-1 downto 0):=(others =>'0');
	stats_cnt			: out std_logic_vector(32*nbr_channels-1 downto 0); -- delay tap value for monitoring input delay
	------------------
	i						: in	std_logic_vector(   nbr_channels-1 downto 0);
	ib						: in	std_logic_vector(   nbr_channels-1 downto 0);
	o						: out std_logic_vector( 8*nbr_channels-1 downto 0);
	dv_o					: out	std_logic_vector(   nbr_channels-1 downto 0)
);
	
end tts_rx;

architecture rtl of tts_rx is



	type array_16x10bit is array(0 to 15) of std_logic_vector(9 downto 0);


	signal rxbyte						: std_logic_vector( 8*nbr_channels-1 downto 0);
	signal rxnibble					: std_logic_vector( 5*nbr_channels-1 downto 0);
	signal rxword						: std_logic_vector(10*nbr_channels-1 downto 0);
	signal rxcharisk					: std_logic_vector(   nbr_channels-1 downto 0);
	signal rx_bitslip					: std_logic_vector(   nbr_channels-1 downto 0);
	signal aligned						: std_logic_vector(   nbr_channels-1 downto 0);
		
	signal idelay_tap					: std_logic_vector(5*nbr_channels-1 downto 0);
	signal idelay_ld					: std_logic_vector(  nbr_channels-1 downto 0);
	signal idelay_load				: std_logic_vector(  nbr_channels-1 downto 0);
	signal idelay_ctrl				: std_logic_vector(  nbr_channels-1 downto 0);
	
	signal gearbox_ctrl				: std_logic_vector(  nbr_channels-1 downto 0);
	
begin


	--==========================--
	serdes: entity work.serdes_rx -- custom
	--==========================--
	generic map (idelayctrl_gen => idelayctrl_gen, idelaygroup => idelaygroup, sys_w => nbr_channels, dev_w => 5*nbr_channels)	
	port map
	(
		clk_reset            	=> reset_i,
		io_reset             	=> reset_i,
		clk_div_in           	=> pclk_i, 
		clk_in               	=> sclk_i,
	--		------------------

		-- from the system into the device
		data_in_from_pins_p     => i,
		data_in_from_pins_n     => ib,
		data_in_to_device       => rxnibble,

		-- input, output delay control signals
		in_delay_ld           	=> idelay_ld, --idelay_ld_i,
		in_delay_data_ce        => (others => '0'),
		in_delay_data_inc       => (others => '0'),
		in_delay_tap_in         => idelay_tap, --idelay_tap_i,
		in_delay_tap_out        => idelay_tap_o,
		delay_locked            => idelay_locked_o,
		ref_clock               => idelay_clk_i,                    				
		bitslip                 => rx_bitslip
	);
	--==========================--
	
	
	
	
	
	gen: for j in 0 to nbr_channels-1 generate
	begin
		
		
		--==========================--
		idelay_ld(j)			 			<= idelay_ld_i(j) 						when idelay_manual_i='1' else idelay_load (j);
		idelay_tap(5*j+4) 				<= idelay_tap_i(5*j+4) 					when idelay_manual_i='1' else idelay_ctrl (j);
		idelay_tap(5*j+3 downto 5*j)  <= idelay_tap_i(5*j+3 downto 5*j); -- currently tap[3:0] not controlled automatically
		--==========================--
				
				
		
		--==========================--
		gb: entity work.gearbox_xb_2xb -- from width = x to width = 2*x	
		--==========================--
		generic map (x => 5)
		port map
		(
			reset_i 			=> reset_i,	
			wrclk_i 			=> pclk_i,	
			wrdata_i			=> rxnibble(5*j+4 downto  5*j), 
			inv_assembly_i => gearbox_ctrl(j),
			rdclk_i			=> clk_i,
			rddata_o			=> rxword (10*j+9 downto 10*j) 
		);
		--==========================--	

			
		
		--==========================--
		dec: entity work.dec_8b10b_wrapper	
		--==========================--
		port map
		(
			reset_i 			=> reset_i,	
			clk_i 			=> clk_i,	
			data_i			=> rxword(10*j+9 downto 10*j), 
			data_o			=> rxbyte( 8*j+7 downto  8*j),
			k_o				=> rxcharisk(j) 
		);
		--==========================--	
		
		
		
		--==========================--
		ctrl: entity work.tts_rx_ctrl
		--==========================--
		generic map 
		(
			bitslip_delay							=> bitslip_delay,								
			consecutive_valid_chars_to_lock  => consecutive_valid_chars_to_lock,
			misaligned_state_code            => misaligned_state_code,
			allow_all_0000xxxx               => allow_all_0000xxxx
		)
		port map
		(
			reset_i					=> reset_i,
			clk_i						=> clk_i,
			-- ctrl i/f--	
			align_str_i				=> align_str_i(j),
			aligned_o				=> aligned(j),
			-- serdes i/f --	
			rxbyte_i					=> rxbyte(8*j+7 downto 8*j),
			rxcharisk_i				=> rxcharisk(j),
			rx_bitslip_o			=> rx_bitslip(j),
			-- idelay i/f --
			idelay_ctrl_o			=> idelay_ctrl(j),
			idelay_load_o			=> idelay_load(j),
			--
			gearbox_ctrl_o			=> gearbox_ctrl(j),
			-- results --	
			o							=> o(8*j+7 downto 8*j),
			dv_o						=> dv_o(j)
		);
			--aligned_o(j) <= aligned(j);	
		--==========================--	


	
		--==========================--	
		stats: process (reset_i, clk_i)
		--==========================--	
			variable lock_cnt			: integer;
			constant lock_threshold	: integer:=2000000; -- 50ms
			variable locked			: std_logic;
			variable locked_prev		: std_logic;
			
			variable unlock_cnt		: std_logic_vector(31 downto 0);

		begin
		if reset_i = '1' then
			
			locked_prev		:='0';			
			locked			:='0';
			lock_cnt			:= 0 ;

			unlock_cnt 								:= (others => '0');	
			stats_cnt(32*j+31 downto 32*j) 	<= (others => '0');	
			
			aligned_o (j) 	<= '0';
			
			
		elsif rising_edge(clk_i) then
			
			
			aligned_o (j) 	<= locked;
			stats_cnt(32*j+31 downto 32*j) 	<= unlock_cnt;
			
			--=== unlock counter ===--
			if stats_clr(j) = '1' then
				unlock_cnt := (others => '0');
			elsif	locked ='0' and locked_prev='1' then -- count
				unlock_cnt:= unlock_cnt+1;
			end if;
			locked_prev := locked;
			
			
			--=== "debounce" of the aligned signal from the ctrl ===--
			if aligned(j)='1' then
				if lock_cnt /= lock_threshold then
					lock_cnt		:=lock_cnt+1;
				else --
					locked		:='1';  -- we consider to be locked when stable for 1 second
				end if;		
			else
				locked		:='0';
				lock_cnt		:= 0 ;
			end if;
			
		end if;
		end process;
		--==========================--
	
	
	end generate;
	

end rtl;