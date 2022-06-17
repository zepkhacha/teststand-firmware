--
-- hello_world.vhd
--
-- The ’Hello World’ example for FPGA programming.
--
-- Author: Martin Schoeberl (martin@jopdesign.com)
--
-- 2006-08-04 created
--
library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity SerIO128b_sleo is
port (
	CK200R     : in std_logic;
	TTC_data   : in STD_LOGIC_VECTOR(15 downto 0);
	fake_bos : in std_logic;
 	STX : out std_logic;	
 	STX1 : out std_logic;	
 	STX2 : out std_logic	
);
end SerIO128b_sleo;

architecture rtl_sleo of SerIO128b_sleo is
	constant CK_FREQ : integer := 125000000;
	constant BLINK_FREQ : integer := 1;
	constant CNT_MAX : integer := CK_FREQ/BLINK_FREQ/2-1;
	constant CNT_MAX1 : integer := 1;
	signal TTC_datashift : std_logic_vector(15 downto 0);
	signal cnt2 : std_logic_vector(32 downto 0);
	signal blink : std_logic;
	signal ci_out : std_logic;
	signal clk_out_40Mhz, clk_out_160Mhz : std_logic;
	signal Locked_40Mhz  : std_logic;
	signal clocked_bos  : std_logic;
	signal clocked_bos1q  : std_logic;
	signal clocked_bos1qq  : std_logic;
    signal channel_a      : std_logic;
    signal channel_b      : std_logic;

begin

    --===================================--
    clk_40Mhz_out: entity work.clk_wiz_40Mhz
    --===================================--
       port map
      (
        clk_in1        =>   CK200R,
        clk_out1       =>   clk_out_40Mhz,
        clk_out2       =>   clk_out_160Mhz
--        locked         =>   Locked_40Mhz
      );
    --===================================--

--    STX2<= (clk_out_160Mhz and Locked_40Mhz);

    process(CK200R)
    begin
	     if rising_edge(CK200R) then
              cnt2 <= cnt2 + 1;
	     end if;
    end process;
    blink<=cnt2(27);
    STX1 <= not blink;

    process(clk_out_40Mhz)
    begin
	    if rising_edge(clk_out_40Mhz) then
	       clocked_bos <=fake_bos; 
           clocked_bos1q <= clocked_bos;
           if (clocked_bos='1') and (clocked_bos1q='0') then
               clocked_bos1qq <= '1';
           else
               clocked_bos1qq <= '0';
           end if;            
        end if;
    end process;
   STX2 <= clocked_bos1qq;


	--================================--
	ttc_out: process (Locked_40Mhz, clk_out_160Mhz)--xpoint1_clk3_x4)
	--================================--
	variable ci_state		: integer range 0 to 3;
    variable enc_bit        : std_logic;
    constant clk_tick       : integer := 16;
    variable tick_cnt       : integer;

    begin
        if rising_edge(clk_out_160Mhz) then
            if (ci_state = 3) then
               if (clocked_bos1qq='1') then
                  TTC_datashift(15 downto 0) <= TTC_data(15 downto 0);                
                  channel_a      <= '1';
               else
                   TTC_datashift(15 downto 1) <= TTC_datashift(14 downto 0);                
                   TTC_datashift(0) <= '1';
                   channel_a      <= '0';
                end if;
            end if;            
        end if;        
channel_b      <= TTC_datashift(15);                                                                       

        if Locked_40Mhz = '0' then 

            ci_state     := 0 ;
            enc_bit         :='0';                    
            channel_a     <= '0';
            channel_b     <= '1';
            
        elsif rising_edge(clk_out_160Mhz) then --xpoint1_clk3_x4) then 

                -- bi-phase mark encoding --                
                case ci_state is
                    when 0         => ci_state := 1;    enc_bit := not enc_bit;              -- invert always
                    when 1         => ci_state := 2;    enc_bit := enc_bit xor channel_a; -- invert when data = 1    
                    when 2         => ci_state := 3;    enc_bit := not enc_bit;              -- invert always            
                    when 3         => ci_state := 0;    enc_bit := enc_bit xor channel_b; -- invert when data = 1    
                    when others => 
                end case;
                ci_out  <= enc_bit;

        end if;        
	end process; 
    STX<=ci_out;


end rtl_sleo;