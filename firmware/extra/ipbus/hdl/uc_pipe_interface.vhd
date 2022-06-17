
----------------------------------------------------------------------------------
--
-- description: 	ipbus slave for the microcontroller 16bit pipe dma interface
--						-> includes fpga to mmc fifo: 		host writes 	[ipbus], mmc reads  [dma pipe]
--						-> includes mmc to fpga fifo: 		host reads  	[ipbus], mmc writes [dma pipe]
--						-> includes fifo counter access: 	host/mmc reads [ipbus]
--
-- revision : 1.0  	-- intial design (AWR)
--							-- based on cactus: components/ipbus/firmware/slaves/hdl/uc_pipe_interface.vhd [rev 27199]
--							-- modified so that uc_pipe is no longer clocked (f/w loading fails on fc7)
-- revision : 2.0  	-- modified to include counter resets over ipbus (MP)
--							-- added comments, tested both fifos successfully with mmc
-- revision : 3.0  	-- modified to use 125MHz free running clock & to clock data at IOBs for stability (MP)
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ipbus.all;
use work.ipbus_trans_decl.all;

library unisim;
use unisim.vcomponents.all;


entity uc_pipe_interface is
port(
	clk			: in 		std_logic;
	rst			: in 		std_logic;
	ipbus_in		: in 		ipb_wbus;
	ipbus_out	: out 	ipb_rbus;
	clk125		: in 		std_logic;
	uc_pipe_nrd	: in 		std_logic;
	uc_pipe_nwe	: in 		std_logic;
	uc_pipe		: inout 	std_logic_vector(15 downto 0)
);
  
end uc_pipe_interface;


architecture rtl of uc_pipe_interface is

	signal samp_nwe 		: std_logic_vector(1 downto 0) 	:= (others => '1');
	signal samp_nrd 		: std_logic_vector(1 downto 0) 	:= (others => '1');

	signal ack				: std_logic;

	signal we_pipe 		: std_logic_vector(0 downto 0);
	signal w_addr_pipe 	: unsigned(9 downto 0) 				:= (others=>'1');
	signal w_data_pipe 	: std_logic_vector(15 downto 0);
	signal r_addr_ipbus 	: unsigned(8 downto 0) 				:= (others=>'0');
	signal r_data_ipbus 	: std_logic_vector(31 downto 0);
	
	signal we_ipbus 		: std_logic_vector(0 downto 0);
	signal w_addr_ipbus 	: unsigned(8 downto 0) 				:= (others=>'1');
	signal w_data_ipbus 	: std_logic_vector(31 downto 0);
	signal r_addr_pipe 	: unsigned(9 downto 0) 				:= (others=>'0');
	signal r_data_pipe 	: std_logic_vector(15 downto 0);
	
	signal uc_pipe_clkd 	: std_logic_vector(15 downto 0);
	signal we_pipe_clkd	: std_logic_vector(0 downto 0);
	
	signal reset_ipbus_to_pipe : std_logic;
	signal reset_pipe_to_ipbus : std_logic;


	component sdpram_16x10_32x9
	 port (
		clka 	: in 	std_logic;
		wea 	: in 	std_logic_vector(0 downto 0);
		addra : in 	std_logic_vector(9 downto 0);
		dina 	: in 	std_logic_vector(15 downto 0);
		clkb 	: in 	std_logic;
		addrb : in 	std_logic_vector(8 downto 0);
		doutb : out std_logic_vector(31 downto 0)
	 );
	end component;

	component sdpram_32x9_16x10
	 port (
		clka 	: in 	std_logic;
		wea 	: in 	std_logic_vector(0 downto 0);
		addra : in 	std_logic_vector(8 downto 0);
		dina 	: in 	std_logic_vector(31 downto 0);
		clkb 	: in 	std_logic;
		addrb : in 	std_logic_vector(9 downto 0);
		doutb : out std_logic_vector(15 downto 0)
	 );
	end component;

begin




  -- synchronise bus to/from mmc to 125mhz domain
  -- all incoming/outgoing data now latched at IOB using 125mhz clock
  -- which should provide more stability with resource intensive designs
  
  -- latch onto falling read/write strobe & increment fifo
  -- addresses (1 clk after registered falling edge)
  -- [for write operations] write latched data from bus
  --   into fifo (2 clks after registered falling edge)
  -- [for read operations] read data available on bus
  --   into mmc already (4 clks after previous registered
  --   falling edge)
  

  process( clk125 )
  begin
    if rising_edge( clk125 ) then

      samp_nwe( 1 downto 0 ) <= samp_nwe(0) & uc_pipe_nwe;
      samp_nrd( 1 downto 0 ) <= samp_nrd(0) & uc_pipe_nrd;

      we_pipe <= "0";

		if( reset_ipbus_to_pipe = '1') then
		  r_addr_pipe <= (others => '0');
      elsif( samp_nrd = "10" ) then
        r_addr_pipe <= r_addr_pipe + 1;
      end if;

		if( reset_pipe_to_ipbus = '1') then
		  w_addr_pipe <= (others => '1');
      elsif( samp_nwe = "10" ) then
        w_addr_pipe <= w_addr_pipe + 1;
        we_pipe <= "1";
      end if;

      if( uc_pipe_nwe = '1' ) then
        uc_pipe <= r_data_pipe;
      else
        uc_pipe <= (OTHERS => 'Z');
      end if;

		uc_pipe_clkd <= uc_pipe;
		we_pipe_clkd <= we_pipe;

    end if;
  end process; 
  

  

  ipbus_out.ipb_err <= '0'; 
  ipbus_out.ipb_ack <= ack;



  process(clk)
  begin
    if rising_edge( clk ) then 

      ack <= ipbus_in.ipb_strobe and not ack;


      -- fifo pointer status/configuration register
      if ipbus_in.ipb_strobe='1' and ack='0' then
		
		  if ipbus_in.ipb_write='0' then
		    -- read fifo pointers		  
		    if ipbus_in.ipb_addr(1 downto 0)="00" then
			   ipbus_out.ipb_rdata <= "0000000" & std_logic_vector( w_addr_ipbus ) & "000000" & std_logic_vector( r_addr_pipe );
		    elsif ipbus_in.ipb_addr(1 downto 0)="01" then
		      ipbus_out.ipb_rdata <= "0000000" & std_logic_vector( r_addr_ipbus ) & "000000" & std_logic_vector( w_addr_pipe );
	       end if;
		  else
		    -- reset fifo pointers
			 if ipbus_in.ipb_addr(1 downto 0)="00" then
				reset_ipbus_to_pipe <= ipbus_in.ipb_wdata(0);
				w_addr_ipbus <= (others => '1');
			 elsif ipbus_in.ipb_addr(1 downto 0)="01" then
				reset_pipe_to_ipbus <= ipbus_in.ipb_wdata(0);
				r_addr_ipbus <= (others => '0');
			 end if;		  
		  end if;
		  
      end if;


      we_ipbus <= "0";
      
		
      -- fifo access
      if ipbus_in.ipb_strobe='1' and ack='0' and ipbus_in.ipb_addr(1 downto 0)="10" then
      
        if ipbus_in.ipb_write='1' then
          -- write to fpga-to-mmc fifo
			 w_data_ipbus <= ipbus_in.ipb_wdata( 15 downto 0 ) & ipbus_in.ipb_wdata( 31 downto 16 );
          w_addr_ipbus <= w_addr_ipbus + 1;
          we_ipbus <= "1";
        else
		    -- read from mmc-to-fpga fifo 
          ipbus_out.ipb_rdata <= r_data_ipbus( 15 downto 0 ) & r_data_ipbus( 31 downto 16 ) ;
          r_addr_ipbus <= r_addr_ipbus + 1;
        end if;
		  
      end if;
		
    end if;
  end process;



  -- mmc to fpga fifo 
  ram_pipe_to_ipbus: sdpram_16x10_32x9
    port map(
      clka 		=> clk125,
      wea 		=> we_pipe_clkd,
      addra 	=> std_logic_vector( w_addr_pipe ),
      dina 		=> uc_pipe_clkd,
      clkb 		=> clk,
      addrb 	=> std_logic_vector( r_addr_ipbus ),
      doutb 	=> r_data_ipbus
    );


  -- fpga to mmc fifo 
   ram_ipbus_to_pipe: sdpram_32x9_16x10
    port map(
      clka 		=> clk,
      wea 		=> we_ipbus,
      addra 	=> std_logic_vector( w_addr_ipbus ),
      dina 		=> w_data_ipbus,
      clkb 		=> clk125,
      addrb 	=> std_logic_vector( r_addr_pipe ),
      doutb 	=> r_data_pipe
    );

end rtl;
