library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
--! system packages
use work.ipbus.all;
use work.system_package.all;
--! user packages
use work.system_version_package.all;

entity ipb_regs is
generic(addr_width : natural := 6);
port
(
	reset					: in 	std_logic;
	------------------
	ipbus_clk			: in 	std_logic;
	ipb_mosi_i			: in 	ipb_wbus;
	ipb_miso_o			: out ipb_rbus;
	------------------
	regs_o				: out	array_32x32bit;
	regs_i				: in	array_32x32bit
);
	
end ipb_regs;

architecture rtl of ipb_regs is

signal regs: array_32x32bit;		

	signal sel: integer range 0 to 31;
	signal ack: std_logic;
	
	attribute keep: boolean;
	attribute keep of ack: signal is true;
	attribute keep of sel: signal is true;


begin

	--=============================--
	-- read only registers
	--=============================--
	regs_o 		<= regs;
	regs(0) 		<= regs_i(0);
	regs(1) 		<= regs_i(1);
	regs(2) 		<= regs_i(2);
	regs(3) 		<= regs_i(3);
	regs(4) 		<= regs_i(4);
	regs(5) 		<= regs_i(5);
	regs(6) 		<= regs_i(6);
	regs(7) 		<= regs_i(7);
	regs(8) 		<= regs_i(8);
	regs(9) 		<= regs_i(9);
	regs(10) 	<= regs_i(10);
	regs(11) 	<= regs_i(11);
	regs(12) 	<= regs_i(12);
	regs(13) 	<= regs_i(13);
	regs(14) 	<= regs_i(14);
	regs(15) 	<= regs_i(15);
	--=============================--

		
	--=============================--
	sel <= to_integer(unsigned(ipb_mosi_i.ipb_addr(addr_width downto 0))) when addr_width>0 else 0;
	--=============================--
	

	--=============================--
	process(reset, ipbus_clk)
	--=============================--

		variable ack_ctrl 	: std_logic_vector(1 downto 0);
		variable addr_curr	: std_logic_vector(addr_width downto 0);
	
	begin
	if reset='1' then
		--regs( 0) 	<= x"00000000";	
		--regs( 1) 	<= x"00000000";	
		--regs( 2) 	<= x"00000000";	
      --regs( 3) 	<= x"00000000";	
      --regs( 4) 	<= x"00000000";	
      --regs( 5) 	<= x"00000000";	
      --regs( 6) 	<= x"00000000";	
      --regs( 7) 	<= x"00000000";	
      --regs( 8) 	<= x"00000000";	
      --regs( 9) 	<= x"00000000";	
      --regs(10) 	<= x"00000000";	
      --regs(11) 	<= x"00000000";	
      --regs(12) 	<= x"00000000";	
      --regs(13) 	<= x"00000000";	
      --regs(14) 	<= x"00000000";	
      --regs(15) 	<= x"00000000";	
      regs(16) 	<= x"00000000";	
      regs(17) 	<= x"00000000";	
      regs(18) 	<= x"00000000";	
      regs(19) 	<= x"00000000";	
      regs(20) 	<= x"00000000";	
      regs(21) 	<= x"00000000";	
      regs(22) 	<= x"00000000";	
      regs(23) 	<= x"00000000";	
      regs(24) 	<= x"00000000";	
      regs(25) 	<= x"00000000";	
      regs(26) 	<= x"00000000";	
      regs(27) 	<= x"00000000";	
      regs(28) 	<= x"00000000";	
      regs(29) 	<= x"00000000";	
      regs(30) 	<= x"00000000";	   
		regs(31) 	<= x"00000000";	
      
		ack 			<= '0';
		ack_ctrl		:= "00";
		
      
	elsif rising_edge(ipbus_clk) then
	
		--=============--
		-- write
		--=============--
		if ipb_mosi_i.ipb_strobe='1' and ipb_mosi_i.ipb_write='1' then
			case sel is
				--when 	3|4|5|8|10|11|13|14| 	=> regs(sel) <= ipb_mosi_i.ipb_wdata;
				--when 	16 to 31 					=> regs(sel) <= ipb_mosi_i.ipb_wdata;
				--when	1 		=> regs( 1)	<= ipb_mosi_i.ipb_wdata;
				--when	2 		=> regs( 2)	<= ipb_mosi_i.ipb_wdata;
				--when	3 		=> regs( 3)	<= ipb_mosi_i.ipb_wdata;
				--when	4 		=> regs( 4) <= ipb_mosi_i.ipb_wdata;			           
				--when	5 		=> regs( 5) <= ipb_mosi_i.ipb_wdata;			           
				--when	6 		=> regs( 6) <= ipb_mosi_i.ipb_wdata;			           
				--when	7 		=> regs( 7) <= ipb_mosi_i.ipb_wdata;			           
				--when	8 		=> regs( 8) <= ipb_mosi_i.ipb_wdata;			           
				--when	9 		=> regs( 9) <= ipb_mosi_i.ipb_wdata;			           
				--when	10		=> regs(10) <= ipb_mosi_i.ipb_wdata;			           
				--when	11		=> regs(11) <= ipb_mosi_i.ipb_wdata;			           
				--when	12		=> regs(12) <= ipb_mosi_i.ipb_wdata;			           
				--when	13		=> regs(13) <= ipb_mosi_i.ipb_wdata;			           
				--when	14		=> regs(14) <= ipb_mosi_i.ipb_wdata;			           
				--when	15		=> regs(15) <= ipb_mosi_i.ipb_wdata;			           
				when	16		=> regs(16) <= ipb_mosi_i.ipb_wdata;			           
				when	17		=> regs(17) <= ipb_mosi_i.ipb_wdata;			           
				when	18		=> regs(18) <= ipb_mosi_i.ipb_wdata;			           
				when	19		=> regs(19) <= ipb_mosi_i.ipb_wdata;			           
				when	20		=> regs(20) <= ipb_mosi_i.ipb_wdata;			           
				when	21		=> regs(21) <= ipb_mosi_i.ipb_wdata;
				when	22		=> regs(22) <= ipb_mosi_i.ipb_wdata;
				when	23		=> regs(23) <= ipb_mosi_i.ipb_wdata;
				when	24		=> regs(24) <= ipb_mosi_i.ipb_wdata;
				when	25		=> regs(25) <= ipb_mosi_i.ipb_wdata;
				when	26		=> regs(26) <= ipb_mosi_i.ipb_wdata;
				when	27		=> regs(27) <= ipb_mosi_i.ipb_wdata;
				when	28		=> regs(28) <= ipb_mosi_i.ipb_wdata;
				when	29		=> regs(29) <= ipb_mosi_i.ipb_wdata;
				when	30		=> regs(30) <= ipb_mosi_i.ipb_wdata;
				when	31		=> regs(31) <= ipb_mosi_i.ipb_wdata;
				when others => 
			end case;	
		end if;

		--=============--
		-- read
		--=============--
		ipb_miso_o.ipb_rdata <= regs(sel);
		
		-- write autoclear ----
--		if ipb_mosi_i.ipb_strobe='0' then
--			regs(11)(31 downto 28) <= x"0"; --autoclear
--			regs(14)(31 downto 28) <= x"0"; --autoclear
--		end if;

		-- ack ctrl -----
		if ipb_mosi_i.ipb_strobe='1' then
				case ack_ctrl is
					when "00" =>	ack <= '1'; ack_ctrl := "01"; addr_curr:= ipb_mosi_i.ipb_addr(addr_width downto 0); 
					when "01" => 	ack <= '0'; ack_ctrl := "11";
					when "11" => 	if ipb_mosi_i.ipb_addr(addr_width downto 0)/=addr_curr then 
										ack <= '1'; ack_ctrl := "01"; addr_curr:= ipb_mosi_i.ipb_addr(addr_width downto 0);
										end if; 
					when others =>
				end case;
		elsif ipb_mosi_i.ipb_strobe='0' then
			ack <= '0'; 
			ack_ctrl := "00"; 
		end if;
		
		
	end if;
	end process;
	
	ipb_miso_o.ipb_ack <= ack;
	ipb_miso_o.ipb_err <= '0';

end rtl;
