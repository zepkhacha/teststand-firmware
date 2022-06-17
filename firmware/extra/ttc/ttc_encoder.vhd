-- ------------------------------------------------------------------------------------------------
-- TTC FRAME (TDM of channels A and B):
-- A channel: 1=trigger, 0=no trigger. No encoding, minimum latency.
-- B channel: short broadcast or long addressed commands. Hamming check bits.

-- B Channel Content:
--
-- IDLE=111111111111
--
-- Short Broadcast, 16 bits:
-- 00TTDDDDDEBHHHHH1: T=test command, 2 bits. D=Command/Data, 4 bits. E=Event Counter Reset, 1 bit.
--                    B=Bunch Counter Reset, 1 bit. H=Hamming Code, 5 bits.
-- ttc hamming encoding for broadcast (d8/h5)
-- /* build Hamming bits */
-- hmg[0] = d[0]^d[1]^d[2]^d[3];
-- hmg[1] = d[0]^d[4]^d[5]^d[6];
-- hmg[2] = d[1]^d[2]^d[4]^d[5]^d[7];
-- hmg[3] = d[1]^d[3]^d[4]^d[6]^d[7];
-- hmg[4] = d[0]^d[2]^d[3]^d[5]^d[6]^d[7];
-- /* build Hamming word */
-- hamming = hmg[0] | (hmg[1]<<1) | (hmg[2]<<2) | (hmg[3]<<3) | (hmg[4]<<4);
		   

-- TDM/BPM coding principle:
-- 	 <  24.9501 ns   >
--	 X---A---X---B---X
-- 	 X=======X=======X	A=0, B=0 (no trigger, B=0) 
-- 	 X=======X===X===X	A=0, B=1 (no trigger, B=1). unlimited string length when IDLE 
-- 	 X===X===X=======X	A=1, B=0 (trigger, B=0). max string length =11, then switch phase
-- 	 X===X===X===X===X	A=1, B=1 (trigger, B=1)
-- ------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ttc_encoder is
port (
	-- input
	clk_160MHz      : in std_logic;
	TTC_data        : in std_logic_vector(15 downto 0);
	b_channel_valid : in std_logic;
	a_channel_in    : in std_logic;

	-- output
 	STX : out std_logic
);
end ttc_encoder;

architecture Behavioral of ttc_encoder is

	signal TTC_datashift : std_logic_vector(15 downto 0);
    signal a_channel_out : std_logic;
    signal ci_state : integer range 0 to 3;

begin

	PUT IN A PULSE SYCNHRONIZER FROM 40 MHZ TO 160 MHZ DOMAIN
	DON'T WANT TO HAVE 4 TRIGGERS GO OFF FOR EACH EACH 40 MHZ ONE FROM THE TTC DECODER


    -- bi-phase mark encoding
	ttc_out: process(clk_160MHz)
	variable ci_state : integer range 0 to 3;
	variable enc_bit  : std_logic;
    begin
        if rising_edge(clk_160MHz) then
        	-- data shifter, on every fourth clock edge
            if (ci_state = 3) then
            	-- encode trigger
               	if (a_channel_in = '1') then
                  	a_channel_out <= '1';
                  	TTC_datashift(15 downto 1) <= TTC_datashift(14 downto 0);
                   	TTC_datashift(0)           <= '1';
                -- encode command
                elsif (b_channel_valid = '1') then
                	a_channel_out <= '0';
                	TTC_datashift(15 downto 0) <= TTC_data(15 downto 0);
                -- idle
               	else
                   	a_channel_out <= '0';
                   	TTC_datashift(15 downto 1) <= TTC_datashift(14 downto 0);
                   	TTC_datashift(0)           <= '1';
                end if;
            end if;

            case ci_state is
                when 0 => ci_state := 1;  enc_bit := not enc_bit;                   -- invert always
                when 1 => ci_state := 2;  enc_bit := enc_bit xor a_channel_out;     -- invert when data = 1
                when 2 => ci_state := 3;  enc_bit := not enc_bit;                   -- invert always
                when 3 => ci_state := 0;  enc_bit := enc_bit xor TTC_datashift(15); -- invert when data = 1
            end case;

            STX <= enc_bit;
        end if;        
	end process;

end Behavioral;
