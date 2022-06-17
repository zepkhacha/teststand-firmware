library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top is
	generic (ports: integer := 4);
	port (
		reset_switch			: in		std_logic; 
		cpld_por					: in		std_logic;
		led						: out		std_logic_vector(2 downto 0);
      cpld_clk_100mhz		: in		std_logic;		
		-- amc jtag interface
		tcka						: in		std_logic;
		tmsa						: in		std_logic;
		tdia						: in		std_logic;
		tdoa						: out		std_logic;
		-- local jtag header
		tckb						: in		std_logic;
		tmsb						: in		std_logic;
		tdib						: in		std_logic;
		tdob						: out		std_logic;
		-- device ports (fpga, atmel, fmc_l8, fmc_l12)
		tcko						: out		std_logic_vector(ports-1 downto 0);
		tmso						: out		std_logic_vector(ports-1 downto 0);
		tdio						: out		std_logic_vector(ports-1 downto 0);
		tdoo						: in		std_logic_vector(ports-1 downto 0);
      -- cpld configuration switch
		sel						: in		std_logic_vector(7 downto 0);
		fmc_l8_prsnt_l			: in		std_logic;
		fmc_l12_prsnt_l		: in		std_logic;
		-- spi prom reference signals
		spi_sclk					: out		std_logic;
		spi_cs_b					: out		std_logic;
		spi_dq					: inout	std_logic_vector(3 downto 0) := "ZZZZ";
		-- fpga data signals
		cpld2fpga_d				: inout	std_logic_vector(15 downto 0) := (OTHERS => 'Z');
		cpld2fpga_gpio			: inout	std_logic_vector( 3 downto 0);
		cpld2fpga_ebi_nwe_0	: out		std_logic;
		cpld2fpga_ebi_nrd		: out		std_logic;
		cpld2fpga_ebi_nwe_1	: out		std_logic;
		cpld2fpga_ebi_ncs_1	: in		std_logic;
		-- fpga status / programming
		fpga_mode				: out		std_logic_vector(2 downto 0);
		fpga_prog_b 			: inout	std_logic := 'Z';
		fpga_init_b 			: in		std_logic;
		fpga_done				: in		std_logic;
		fpga_rdwr_b 			: out		std_logic;
		fpga_csi_b				: out 	std_logic;
		fpga_cclk				: inout 	std_logic;
		fpga_fcs_b				: in		std_logic;
		fpga_emc_clk			: out		std_logic;
		fpga_cpld_clk			: out		std_logic;
		-- atmel interfaces
		atmel_ebi_d				: inout	std_logic_vector(15 downto 0) := (OTHERS => 'Z');
		atmel_ebi_a				: inout	std_logic_vector(19 downto 0) := (OTHERS => 'Z');
		atmel_ebi_nwe_0		: in		std_logic;
		atmel_ebi_nwe_1		: in		std_logic;
		atmel_ebi_ncs_1		: in		std_logic;
		atmel_ebi_nrd			: in		std_logic;
		atmel_uc					: inout	std_logic_vector( 4 downto 0) := "ZZZZZ"
     );
end top;


architecture behave of top is

  attribute schmitt_trigger: string;
  attribute schmitt_trigger of reset_switch: signal is "true";

  signal tcki							: std_logic;
  signal tmsi							: std_logic;
  signal tdii							: std_logic;
  signal tdoi							: std_logic;
  signal xfer							: std_logic_vector(ports-1 downto -1);
  signal life							: std_logic := '0';
  signal atmel_control				: std_logic;
  signal fpga_prog_atmel			: std_logic;
  signal fpga_prog_pb				: std_logic;
  signal local_jtag_header 		: std_logic;
  signal spi_direct_programming	: std_logic;
  signal sel_int						: std_logic_vector(3 downto 0);
  signal spi_clk_in					: std_logic;
  signal spi_in						: std_logic;
  signal spi_csb_in					: std_logic;
  signal spi_out						: std_logic;

 
begin



  --===================================--
  flasher : process(cpld_clk_100mhz)
  --===================================--
    variable count : unsigned(23 downto 0) := x"000000";
  begin
  
  if rising_edge(cpld_clk_100mhz) then
    if count 	= x"000000" then
       count 	:= to_unsigned(25000000, 24);
       life 	<= not(life);
    else
       count 	:= count - 1;
    end if;
  end if;
	 
  end process flasher;
  
  
  
  
  --===================================--
  -- fpga configuration setup
  --===================================--


  -- cpld config dip switch: up/disabled = '1', down/enabled = '0'
  -- sel(4)			= atmel control enable
  -- sel(5)			= reserved
  -- sel(6)			= spi direct programming enable

  spi_direct_programming 	<= not sel(6);
  atmel_control				<= not sel(4);


  -- atmel_uc(0)	= receive prog_b from uc
  -- atmel_uc(1)	= forward fpga init_b to uc
  -- atmel_uc(2)	= forward fpga done to uc
  -- atmel_uc(3)	= reserved
  -- atmel_uc(4)	= reserved
  
  atmel_uc(1)		<= fpga_init_b;
  atmel_uc(2)		<= fpga_done;
  atmel_uc(3)		<= 'Z';
  atmel_uc(4)		<= 'Z';


  -- cpld reset switch
  
  fpga_prog_pb		<= not reset_switch ;


  -- fpga prog_b
  -- controlled by atmel when atmel_control enabled
  -- can be pulled low by cpld reset at any time
  
  fpga_prog_atmel	<= atmel_control and not atmel_uc(0);

  fpga_prog_b		<= '0' 					when (fpga_prog_pb = '1' or fpga_prog_atmel = '1') else
							'Z';  


  -- status leds (signals inverted)
  -- cpld led		= red,					when fpga in reset
  -- cpld led		= green,					when 100mhz clock or fpga configured
  -- cpld led		= blue,					when atmel_control enabled
  
  led(0)				<= fpga_init_b;
  led(1)				<= not(life or fpga_done);
  led(2)				<= atmel_control;




  --===================================--
  -- fpga configuration options
  --===================================--


  -- fpga_mode  	= master spi x1,		when atmel_control is disabled
  -- fpga_mode		= slave selectmap,	when atmel_control is enabled

  fpga_mode 		<= "001"					when atmel_control = '0' else "110";


  ------------------------------------------------------------
  -- slave select map mode
  --
  -- 	atmel controls loading of data from usd card 
  --	into fpga on a 16bit data bus, after an fpga reset
  --
  -- 	atmel_ebi_d[0:15]		=> cpld2fpga_d[0:15]	: ->d[0:15]
  -- 	atmel_ebi_nwe_0		=> fpga_cclk			: ->cclk
  -- 	'0'						=> fpga_csi_b			: ->csi_b
  -- 	'0'						=> fpga_rdwr_b			: ->rdwr_b
  ------------------------------------------------------------
  
  ------------------------------------------------------------
  -- master spi mode
  --
  -- 	fpga controls loading of configuration data from spi
  --	flash into fpga (single lane), after an fpga reset
  --
  -- 	cpld2fpga_d(0)			=> spi_in				: <-mosi
  -- 	spi_out					=> cpld2fpga_d(1)		: ->din
  -- 	fpga_cclk				=> spi_clk_in			: <-cclk
  -- 	fpga_fcs_b				=> spi_csb_in			: <-fcs_b
  ------------------------------------------------------------
  
  
  -----------------------------
  -- cpld <-> fpga interface --
  -----------------------------
  
  
  cpld2fpga_d(0) 				<= 	atmel_ebi_d(0) 				when (atmel_control = '1' and atmel_ebi_nwe_0 = '0') 	else
											'Z';

  cpld2fpga_d(1) 				<=		atmel_ebi_d(1) 				when (atmel_control = '1' and atmel_ebi_nwe_0 = '0') 	else
											spi_out	 						when (atmel_control = '0')										else
											'Z';

  cpld2fpga_d(15 downto 2) <= 	atmel_ebi_d(15 downto 2)	when (atmel_control = '1' and atmel_ebi_nwe_0 = '0') 	else
											(others => 'Z');

  fpga_rdwr_b					<= 	'0' 								when (atmel_control = '1') else 'Z';
  fpga_csi_b					<= 	'0' 								when (atmel_control = '1') else 'Z';
  fpga_cclk 					<= 	atmel_ebi_nwe_0 				when (atmel_control = '1') else 'Z';
  
  
  ----------------------------------
  -- cpld <-> spi flash interface --
  ----------------------------------
  
  spi_clk_in 					<= 	fpga_cclk 						when (atmel_control = '0') else '1';
  spi_in 						<= 	cpld2fpga_d(0);
  spi_csb_in 					<= 	fpga_fcs_b;



 
  --===================================--
  -- additional cpld interfaces
  --===================================--


  -- clocks

  fpga_cpld_clk <= 'Z';
  fpga_emc_clk <= cpld_clk_100mhz;
  
 
  ------------------------------------------------------------
  -- direct spi programming
  --
  -- 	direct writing to spi flash using jtag chain
  --
  -- 	tdi						=> spi_in
  -- 	spi_out					=> tdo
  -- 	tclk						=> spi_clk_in
  -- 	tms						=> spi_csb_in
  ------------------------------------------------------------ 

  spi_dq(0)						<= spi_in			when spi_direct_programming = '0' else tdib;
  spi_sclk						<= spi_clk_in		when spi_direct_programming = '0' else tckb;
  spi_cs_b						<= spi_csb_in		when spi_direct_programming = '0' else tmsb;
  spi_out						<= spi_dq(1)		when spi_direct_programming = '0' else 'Z';


  ------------------------------------------------------------
  -- atmel <-> fpga dma interface
  --
  -- 	atmel controls reading and writing to block rams on the fpga
  --  using the selectmap bidirectional 16bit data bus; write_bus
  --  is shared with selectmap/spi interface as defined above  
  --
  -- 	atmel_ebi_d[0:15]		=> cpld2fpga_d[0:15]		: ->ram write_bus
  -- 	cpld2fpga_d[0:15]		=> atmel_ebi_d[0:15] 	: <-ram read_bus
  -- 	atmel_ebi_nwe_0		=> cpld2fpga_ebi_nwe_0	: ->ram write
  -- 	atmel_ebi_nrd			=> cpld2fpga_ebi_nrd		: ->ram read
  ------------------------------------------------------------ 

  atmel_ebi_d 					<= cpld2fpga_d		when atmel_ebi_nrd = '0' else (others => 'Z');
  
  cpld2fpga_ebi_nwe_0		<= atmel_ebi_nwe_0;
  cpld2fpga_ebi_nrd			<= atmel_ebi_nrd;
  
  
  ------------------------------------------------------------
  -- atmel <-> fpga spi interface for ipbus
  --
  -- 	atmel acts as spi master to the fpga over a single lane bus
  --  spi slave is implemented in fpga as part of ipbus
  --
  -- 	atmel_ebi_a(4)			=> cpld2fpga_gpio(3)		: spi_cs
  -- 	atmel_ebi_a(5)			=> cpld2fpga_gpio(0) 	: spi_clk
  -- 	atmel_ebi_a(6)			=> cpld2fpga_gpio(1)		: spi_mosi
  -- 	cpld2fpga_gpio(2)		=> atmel_ebi_a(7)			: spi_miso
  ------------------------------------------------------------   
  
  cpld2fpga_gpio(3)			<= atmel_ebi_a(4);
  cpld2fpga_gpio(0)			<= atmel_ebi_a(5);
  cpld2fpga_gpio(1)			<= atmel_ebi_a(6);
  atmel_ebi_a(7)				<= cpld2fpga_gpio(2);




  --===================================--
  -- jtag switching
  --===================================--


  -- cpld config dip switch: up/disabled = '1', down/enabled = '0'
  -- sel(0) 		= fpga jtag enable
  -- sel(1)			= atmel jtag enable
  -- sel(2)			= fmc_l8 jtag enable if mezzanine present
  -- sel(3)			= fmc_l12 jtag enable if mezzanine present
  -- sel(7)			= amc connector jtag enable
  
  -- when sel(7) 	= '1', select on-board header, amc bypassed
  -- when sel(7)	= '0', select amc connector

  local_jtag_header	<= sel(7);

  sel_int(0)			<= sel(0);
  sel_int(1)			<= sel(1);
  sel_int(2)			<= sel(2) or fmc_l8_prsnt_l;
  sel_int(3)			<= sel(3) or fmc_l12_prsnt_l;


  tcki					<= tckb 				when (local_jtag_header = '1') 		else tcka;
  tmsi					<= tmsb 				when (local_jtag_header = '1') 		else tmsa;
  tdii					<= tdib 				when (local_jtag_header = '1') 		else tdia;

  tdoa					<= tdoi				when (local_jtag_header = '0') 		else tdia;
  
  tdob					<= spi_dq(1)		when (spi_direct_programming = '1')	else
								tdoi				when (local_jtag_header = '1') 		else
								'Z';


  --===================================--
  tck_switching: process (tcki, sel_int)
  --===================================--  
  begin
  
  for i in 0 to ports-1 loop
    if sel_int(i) = '0' then
       tcko(i) <= tcki;
    else
       tcko(i) <= '0';
    end if;
  end loop;
  
  end process;


  --===================================--
  tms_switching: process (tmsi, sel_int)
  --===================================--
  begin
  
  for i in 0 to ports-1 loop
    if sel_int(i) = '0' then
       tmso(i) <= tmsi;
    else
       tmso(i) <= '1';
    end if;
  end loop;

  end process;


  --===================================--
  tdi_tdo_switching: process (tdii, sel_int, tdoo, xfer)
  --===================================--
  begin
    
  for i in 0 to ports-1 loop
    if sel_int(i) = '0' then
       xfer(i) <= tdoo(i); -- loop through chain
       tdio(i) <= xfer(i-1); 
    else
       xfer(i) <= xfer(i-1); -- bypass
       tdio(i) <= '1'; 
    end if;
  end loop;
  tdoi <= xfer(ports-1);
  
  end process;
	
  xfer(-1) <= tdii; 
  
  

end behave;
