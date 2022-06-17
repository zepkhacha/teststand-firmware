library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity dec_8b10b_wrapper is	
    port(
		reset_i 			: in 	std_logic ;							-- Global asynchronous reset (AH) 
		clk_i 			: in 	std_logic ;							-- Master synchronous receive byte clock
		data_i			: in 	std_logic_vector(9 downto 0);	-- Encoded input (LS..MS)
		k_o				: out std_logic ;							-- Control (K) character indicator (AH)
		data_o			: out std_logic_vector(7 downto 0) 	-- Decoded out (MS..LS)
	    );
end dec_8b10b_wrapper;

architecture wrap of dec_8b10b_wrapper is

	attribute keep					: boolean;
	attribute keep of data_i	: signal is true; 
	attribute keep of data_o	: signal is true; 
	attribute keep of k_o		: signal is true; 
	
--	attribute keep_hierarchy 			: string ;
-- attribute keep_hierarchy of reg : label is "true";
-- attribute keep_hierarchy of dec : label is "true";

begin
	
	dec: entity work.dec_8b10b
   port map
	(
		RESET 	=> reset_i,
		RBYTECLK => clk_i,
		AI			=> data_i(0),
		BI       => data_i(1),
		CI       => data_i(2),
		DI       => data_i(3),
		EI       => data_i(4),
		II       => data_i(5),
		FI       => data_i(6),
		GI       => data_i(7),
		HI			=> data_i(8),
		JI 	   => data_i(9),
		KO 		=> k_o,
		AO			=> data_o(0),
		BO       => data_o(1),
		CO       => data_o(2),
		DO       => data_o(3),
		EO       => data_o(4),
		FO       => data_o(5),
		GO       => data_o(6),
		HO       => data_o(7)
	);

end wrap;

