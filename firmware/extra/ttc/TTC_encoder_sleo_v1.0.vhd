--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                UIUC                                                          
-- Physicist:              Sabato Leo (sleo@illinois.edu)
--                                                                                                 
-- Project Name:           CCC system g-2                                                            
-- Module Name:            TTC encoder                                         
--                                                                                                 
-- Language:               VHDL'93                                                                  
--                                                                                                   
-- Target Device:          Kintex7 - KC705                                                         
-- Tool version:           Vivado 2015.2                                                                
--                                                                                                   
-- Version:                0.1                                                                      
--
-- Description:            
--
-- Versions history:       DATE         VERSION   AUTHOR            DESCRIPTION
--
--                         02/10/2016   1.0       Sabato Leo        - First .vhd module definition           
--
--=================================================================================================--
--=================================================================================================--

--=================================================================================================--
--==================================== Additional Comments ========================================--
--=================================================================================================-- 
	--
	-- TTC FRAME (TDM of channels A and B):
	-- A channel: 1=trigger, 0=no trigger. No encoding, minimum latency.
	-- B channel: short broadcast or long addressed commands. Hamming check bits

	-- B Channel Content:
	--
	-- IDLE=111111111111
	--
	-- Short Broadcast, 16 bits:
	-- 00TTDDDDDEBHHHHH1: T=test command, 2 bits. D=Command/Data, 4 bits. E=Event Counter Reset, 1 bit. B=Bunch Counter Reset, 1 bit. H=Hamming Code, 5 bits.
	--
	-- ttc hamming encoding for broadcast (d8/h5)
	-- /* build Hamming bits */
	-- hmg[0] = d[0]^d[1]^d[2]^d[3];
	-- hmg[1] = d[0]^d[4]^d[5]^d[6];
	-- hmg[2] = d[1]^d[2]^d[4]^d[5]^d[7];
	-- hmg[3] = d[1]^d[3]^d[4]^d[6]^d[7];
	-- hmg[4] = d[0]^d[2]^d[3]^d[5]^d[6]^d[7];--
	-- /* build Hamming word */
	-- hamming = hmg[0] | (hmg[1]<<1) |(hmg[2]<<2) |(hmg[3]<<3) |(hmg[4]<<4);
			   
	--
	-- TDM/BPM coding principle:
	-- 	<  24.9501 ns   >
	--	X---A---X---B---X
	-- 	X=======X=======X	A=0, B=0 (no trigger, B=0) 
	-- 	X=======X===X===X	A=0, B=1 (no trigger, B=1). unlimited string length when IDLE 
	-- 	X===X===X=======X	A=1, B=0 (trigger, B=0). max string length =11, then switch phase
	-- 	X===X===X===X===X	A=1, B=1 (trigger, B=1)
	--

--=================================================================================================--
--=================================================================================================--

-- IEEE VHDL standard library:
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Xilinx devices library:
library unisim;
use unisim.vcomponents.all;

-- Custom libraries and packages:
--use work.<package_name>.all;


--=================================================================================================--
--======================================= Module Body =============================================-- 
--=================================================================================================--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

-- uncomment the following library declaration if using
-- arithmetic functions with signed or unsigned values
-- use ieee.numeric_std.all;

-- uncomment the following library declaration if instantiating
-- any xilinx primitives in this code.
library unisim;
use unisim.vcomponents.all;

entity TTC_encoder_sleo is
--generic (<>: integer:= 100000);
port 
(
	--===============--
      -- General reset --
      --===============--      
     
      RESET               				: in  std_logic;
      
      --=======================--
      -- TTC inputs --
      --=======================--
      
      -- Clock:
      -------------------------------     
      
      TTC_CLOCK40                      	: in std_logic;
      SERIAL_CLOCK160					: in std_logic;
      
      -- Trigger, maximum 40MHz rate, 11 consecutive pulses:
      --------------------------------------------------------
      
      L1A	                       		: in  std_logic;      
      
      -- Broadcast frame:
	  -- a '1' either in ECNTRST, BCNTRST or BRDCST_STROBE triggers a broadcast command 
      ---------------------------------------------------------------------------------
      
      BRDCST_TEST           			: in std_logic_vector(1 downto 0); 
      BRDCST_DATA           			: in std_logic_vector(3 downto 0); 
      ECNTRST           			: in std_logic;  
      BCNTRST                   		: in std_logic;  
      BRDCST_STROBE           			: in std_logic; 
      
	  
      --====================--
      -- TTC outputs --
      --====================--
	  
      TTC_ENC							: out std_logic
);
end TTC_encoder_sleo;

architecture rtl_enc_sleo of TTC_encoder_sleo is

 --============================= Attributes ===============================--   
   
   -- Comment: The "keep" constant is used to avoid that ISE changes the name of 
   --          the signals to be analysed with Chipscope.
   
   attribute keep                         : string;   
  
   --========================================================================--       
   
   --========================= Signal Declarations ==========================--

   --===============--
   -- General reset --
   --===============--
   
   signal reset_from_rst                  : std_logic;         
   
   --=======================--
   -- GLIB control & status --
   --=======================--      
   
   signal locked_from_cdceSync            : std_logic;          
   
   --===============--
   -- Clocks scheme --
   --===============--
   
   signal <>                       : std_logic;
   

   --==========--
   -- blabla --
   --==========--
   
   
   --========================================================================--   

--===========================================================================--
-----        --===================================================--
begin      --================== Architecture Body ==================-- 
-----        --===================================================--
--===========================================================================--
   
   
   --==============--
   -- xfjsxjzxsd --
   --==============--
   
   -- gchzsdjxdtgjz:
   -------------------
   
   -- Comment: at each TTC_clock40 cycle, upon strobe request, creates a 16 bits broadcast frame as defined below, together with a FIFO wr request 
   -- 00TTDDDDDEBHHHHH1: T=test command, 2 bits. D=Command/Data, 4 bits. E=Event Counter Reset, 1 bit. B=Bunch Counter Reset, 1 bit. H=Hamming Code, 5 bits.
   
   broadcast_frame_maker: entity work.broadcast_frame_maker
      port map (
        RESET                          	=> RESET, 
        ---------------------------------                         		
        TTC_CLOCK40                    	=> TTC_CLOCK40,            		
        SERIAL_CLOCK160                	=> SERIAL_CLOCK160,      		
        -------------------------------                              		-- Comment:
        BRDCST_TEST           			=> std_logic_vector(1 downto 0); 	-- TT
		BRDCST_DATA           			=> std_logic_vector(3 downto 0); 	-- DDDD
		ECNTRST           				=> std_logic;  						-- E
		BCNTRST           				=> std_logic;  						-- B
		BRDCST_STROBE           		=> std_logic; 
		-------------------------------                              		-- Comment:
        BRDCST_FRAME           			=> std_logic_vector(15 downto 0); 	-- 00TTDDDDDEBHHHHH1
		BRDCST_FIFO_WR					=> std_logic
      );       
        
		
	-- gchzsdjxdtgjz:
   -------------------
   
   -- Comment: at each TTC_clock40 cycle, upon strobe request, creates a 42 bits broadcast frame as defined below, together with a FIFO wr request 
   -- 01AAAAAAAAAAAAAAE1SSSSSSSSDDDDDDDDHHHHHHH1: A= TTCrx address, 14 bits. E= internal(0)/External(1), 1 bit. S=SubAddress, 8 bits. D=Data, 8 bits. H=Hamming Code, 7 bits. 
   

   -- Comment: The clock synthesizer CDCE62005 is reset and synchronized with PRI_CLK after power up.
   
--========================================================================--  --========================================================================-- 
--========================================================================--  --========================================================================-- 
--========================================================================--  --========================================================================-- 
--========================================================================--  --========================================================================--  
--========================================================================--  --========================================================================--  
--========================================================================--  --========================================================================-- 
 
signal cdr_bad : std_logic := '0';
--signal cdrclk_in : std_logic := '0';
signal cdrclk_dcm : std_logic := '0';
signal cdrclk : std_logic := '0';
signal cdr_lock : std_logic := '0';
--signal cdrdata_in : std_logic := '0';
signal cdrdata_q : std_logic_vector(1 downto 0) := (others =>'0');
signal div8 : std_logic_vector(2 downto 0) := (others =>'0');
signal toggle_cnt : std_logic_vector(1 downto 0) := (others =>'0');
signal toggle_channel : std_logic := '1';
signal a_channel : std_logic := '1';
signal l1a : std_logic := '0';
signal strng_length : std_logic_vector(3 downto 0) := (others =>'0');
signal div_rst_cnt : std_logic_vector(4 downto 0) := (others =>'0');
signal ttc_str : std_logic := '0';
signal sr : std_logic_vector(12 downto 0) := (others => '0');
signal rec_cntr : std_logic_vector(5 downto 0) := (others => '0');
signal rec_frame : std_logic := '0';
signal fmt : std_logic := '0';
signal ttc_data : std_logic_vector(2 downto 0) := (others => '0');
signal brcst_str : std_logic_vector(3 downto 0) := (others => '0');
signal brcst_data : std_logic_vector(7 downto 0) := (others => '0'); -- hamming data bits
signal brcst_syn : std_logic_vector(4 downto 0) := (others => '0'); -- hamming checking bits
signal frame_err : std_logic := '0';
signal single_err : std_logic := '0';
signal double_err : std_logic := '0';
signal evcntreset : std_logic := '0';
signal bcntreset : std_logic := '0';
signal brcst_i : std_logic_vector(7 downto 2) := (others => '0');

signal cdr_pll_lock: std_logic;
begin

cdrclk_out <= cdrclk; -- Paschalis
-----
brcst <= brcst_i;
cdr_bad <= ttc_lol or ttc_los;


i_dcm_cdrclk: entity work.dcm_replacement
port map
 (-- clock in ports
  clk_in1           	=> cdrclk_in,
  clk_out1          	=> cdrclk,
  reset             	=> cdr_bad,
  locked            	=> cdr_pll_lock
 );
	cdrclk_locked	<= cdr_pll_lock;
	

process(cdrclk, cdr_pll_lock)
	variable timer: integer;
begin
if cdr_pll_lock='0' then
	timer		:= pll_locked_delay;
	cdr_lock <= '0';
elsif cdrclk'event and cdrclk='1' then
	if timer=0 then
		cdr_lock <= '1';
	else
		timer:=timer-1;
	end if;	
end if;	
end process;

div4 <= '1';
process(cdrclk)
begin
	if(cdrclk'event and cdrclk = '1')then
		cdrdata_q <= cdrdata_q(0) & cdrdata_in;
		if(toggle_channel = '0')then
			div8 <= div8 + 1;
		end if;
		if(div8 = "111" or toggle_cnt = "11")then
			toggle_cnt <= (others => '0');
-- ttc signal should always toggle at a/b channel crossing, otherwise toggle_channel is at wrong position. toggle_cnt counts these errors.
		elsif(cdrdata_q(1) = cdrdata_q(0) and toggle_channel = '0')then
			toggle_cnt <= toggle_cnt + 1;
		end if;
		if(toggle_cnt /= "11")then
			toggle_channel <= not toggle_channel;
		end if;
--  if illegal l1a='1'/data = '0' sequence reaches 11, resync the phase
		if(toggle_channel = '1' and (a_channel = '1' or strng_length /= x"b"))then
			a_channel <= not a_channel;
		end if;
		if(a_channel = '1' and toggle_channel = '1')then
			if(cdrdata_q(1) /= cdrdata_q(0))then
				l1a <= '1';
			else
				l1a <= '0';
			end if;
		end if;
		if(a_channel = '0' and toggle_channel = '1')then
--	l1a = '1' and b_channel data = '0' can not repeat 11 times. strng_length counts the repeat length of this data pattern
			if(l1a = '0' or (cdrdata_q(1) /= cdrdata_q(0)) or strng_length = x"b")then
				strng_length <= (others => '0');
			else
				strng_length <= strng_length + 1;
			end if;
		end if;
	end if;
end process;
process(cdrclk,cdr_lock)
begin
	if(cdr_lock = '0')then
		div_nrst <= '0';
		div_rst_cnt <= (others => '0');
	elsif(cdrclk'event and cdrclk = '1')then
-- whenever phase adjustment occurs, reset ttc clock divider
		if(toggle_cnt = "11" or strng_length = x"b")then
			div_nrst <= '0';
			div_rst_cnt <= (others => '0');
		elsif(ttc_str = '1')then
-- release the ttc clock divider reset if no more phase error for at least 16 ttc clock cycles
			div_nrst <= div_rst_cnt(4);
			if(div_rst_cnt(4) = '0')then
				div_rst_cnt <= div_rst_cnt + 1;
			end if;
		end if;
	end if;
end process;
process(cdrclk)
begin
	if(cdrclk'event and cdrclk = '1')then
		if(toggle_channel = '1')then
			ttcclk <= not a_channel;
		end if;
		if(toggle_channel = '1' and a_channel = '0')then
-- b channel data, command frames
			ttc_data(2) <= cdrdata_q(1) xor cdrdata_q(0);
		end if;
-- ttc_str selects b-channel data
		ttc_str <= not toggle_channel and a_channel;
		if(ttc_str = '1')then
-- b channel data, command frames
			ttc_data(1) <= ttc_data(2) or not div_rst_cnt(4);		
-- a channel data, l1accept
			ttc_data(0) <= (cdrdata_q(1) xor cdrdata_q(0)) and div_rst_cnt(4);
			if(rec_frame = '0')then
				rec_cntr <= (others => '0');
			else
-- rec_cntr counts frame length
				rec_cntr <= rec_cntr + 1;
			end if;
-- terminates frame receiving at specified frame length
			if(div_rst_cnt(4) = '0' or rec_cntr(5 downto 3) = "101" or (fmt = '0' and rec_cntr(3 downto 0) = x"d"))then
				rec_frame <= '0';
-- starts frame receiving when start bit encountered
			elsif(ttc_data(1) = '0')then
				rec_frame <= '1';
			end if;
-- fmt = 0 for broadcast data
			if(or_reduce(rec_cntr) = '0')then
				fmt <= ttc_data(1);
			end if;
			sr <= sr(11 downto 0) & ttc_data(1);
			if(fmt = '0' and rec_cntr(3 downto 0) = x"e")then
-- hamming data
				brcst_data <= sr(12 downto 5);
-- hamming checking bits
				brcst_syn(0) <= sr(0) xor sr(5) xor sr(6) xor sr(7) xor sr(8);
				brcst_syn(1) <= sr(1) xor sr(5) xor sr(9) xor sr(10) xor sr(11);
				brcst_syn(2) <= sr(2) xor sr(6) xor sr(7) xor sr(9) xor sr(10) xor sr(12);
				brcst_syn(3) <= sr(3) xor sr(6) xor sr(8) xor sr(9) xor sr(11) xor sr(12);
				brcst_syn(4) <= xor_reduce(sr);
-- checks for frame stop bit
				frame_err <= not ttc_data(1);
				brcst_str(0) <= '1';
			else
				brcst_str(0) <= '0';
			end if;
			single_err <= xor_reduce(brcst_syn) and not frame_err;
			if((or_reduce(brcst_syn) = '1' and xor_reduce(brcst_syn) = '0') or frame_err = '1')then
				double_err <= '1';
			else
				double_err <= '0';
			end if;
			sinerrstr <= single_err and brcst_str(1);
			dberrstr <= double_err and brcst_str(1);
			brcst_str(2) <= brcst_str(1) and not double_err;
-- correct data if correctable
			if(brcst_syn(3 downto 0) = x"c")then
				brcst_i(7) <= not brcst_data(7);
			else
				brcst_i(7) <= brcst_data(7);
			end if;
			if(brcst_syn(3 downto 0) = x"a")then
				brcst_i(6) <= not brcst_data(6);
			else
				brcst_i(6) <= brcst_data(6);
			end if;
			if(brcst_syn(3 downto 0) = x"6")then
				brcst_i(5) <= not brcst_data(5);
			else
				brcst_i(5) <= brcst_data(5);
			end if;
			if(brcst_syn(3 downto 0) = x"e")then
				brcst_i(4) <= not brcst_data(4);
			else
				brcst_i(4) <= brcst_data(4);
			end if;
			if(brcst_syn(3 downto 0) = x"9")then
				brcst_i(3) <= not brcst_data(3);
			else
				brcst_i(3) <= brcst_data(3);
			end if;
			if(brcst_syn(3 downto 0) = x"5")then
				brcst_i(2) <= not brcst_data(2);
			else
				brcst_i(2) <= brcst_data(2);
			end if;
			if(brcst_syn(3 downto 0) = x"d")then
				evcntreset <= not brcst_data(1);
			else
				evcntreset <= brcst_data(1);
			end if;
			if(brcst_syn(3 downto 0) = x"3")then
				bcntreset <= not brcst_data(0);
			else
				bcntreset <= brcst_data(0);
			end if;
			bcntres <= brcst_str(3) and bcntreset;
			evcntres <= brcst_str(3) and evcntreset;
			brcststr <= brcst_str(3) and or_reduce(brcst_i);
		end if;
	end if;
end process;

end rtl_enc_sleo;

