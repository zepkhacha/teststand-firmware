library ieee;
use ieee.std_logic_1164.all;

entity gearbox_xb_2xb is
generic(x: integer:=4);
port
(
reset_i       		: in  std_logic;
wrclk_i	    		: in  std_logic;
wrdata_i      		: in  std_logic_vector(x-1 downto 0);
inv_assembly_i		: in  std_logic;
rdclk_i	    		: in  std_logic;
rddata_o      		: out std_logic_vector(2*x-1 downto 0)
);
end gearbox_xb_2xb;

architecture rtl of gearbox_xb_2xb is

	signal reg1 	: std_logic_vector (  x-1 downto 0) := (others => '0');
	signal reg2 	: std_logic_vector (2*x-1 downto 0) := (others => '0');
	signal reg3		: std_logic_vector (2*x-1 downto 0) := (others => '0');
	signal wraddr	: std_logic;	

begin

  --==========================--
  din: process (reset_i, wrclk_i)
  --==========================--
	begin
	if reset_i = '1' then
		wraddr <= '0';	
		reg1 <= (others => '0');
		reg2 <= (others => '0');
	elsif rising_edge(wrclk_i) then
		case wraddr is
			when '0' => reg1 <= wrdata_i;
			when '1' => reg2 <= wrdata_i & reg1;
			when others => null;
		end case;	
		wraddr <= not wraddr;
	end if;
	end process din;
	--==========================--
  
	
	
	--==========================--
	dout : process (reset_i, rdclk_i)
	--==========================--
		variable prev : std_logic_vector(2*x-1 downto 0);
	begin
	if reset_i = '1' then
		reg3 <= (others => '0');	
	elsif rising_edge(rdclk_i) then
		if inv_assembly_i = '0' then
			reg3 <= reg2;
		else
			reg3 <= reg2(x-1 downto 0) & prev(2*x-1 downto x);	
		end if;
		prev:= reg2;	
	end if;
	end process dout;
	--==========================--

	rddata_o <= reg3;
	
end rtl;
