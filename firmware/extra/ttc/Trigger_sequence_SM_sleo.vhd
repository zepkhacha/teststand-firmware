--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                UIUC                                                          
-- Physicist:              Sabato Leo (sleo@illinois.edu)
--                                                                                                 
-- Project Name:           CCC system g-2                                                            
-- Module Name:            Run Type Sequence                                         
--                                                                                                 
-- Language:               VHDL'93                                                                  
--                                                                                                   
-- Target Device:          Kintex7                                                          
-- Tool version:           Vivado 2015.2                                                                
--                                                                                                   
-- Version:                1.0                                                                      
--
-- Description:            
--
-- Versions history:       DATE         VERSION   AUTHOR                           DESCRIPTION
--
--                         05/17/2016   1.0       Sabato Leo, David Sweigart       - First .vhd module definition           
--
--=================================================================================================--
--=================================================================================================--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

--=================================================================================================--
--======================================= Module Body =============================================-- 
--=================================================================================================--

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Trigger_sequence_SM_sleo is
    Port ( CLK       : in STD_LOGIC;
           BOS       : in STD_LOGIC;
           T_GAP0    : in std_logic_vector (31 downto 0); -- Start time trigger0
           T_GAP1    : in std_logic_vector (31 downto 0); -- Start time trigger1
           T_GAP2    : in std_logic_vector (31 downto 0); -- Start time trigger2
           T_GAP3    : in std_logic_vector (31 downto 0); -- Start time trigger3
           TRIGGER_SEQ : in STD_LOGIC_VECTOR (31 downto 0);
           A_CHANNEL : out STD_LOGIC;
           B_CHANNEL : out STD_LOGIC_VECTOR (7 downto 2);
           CNT_S     : out STD_LOGIC
         );
end Trigger_sequence_SM_sleo;

architecture Behavioral of Trigger_sequence_SM_sleo is

type state_type is (IDLE, RUNNING, HOLD);  --type of state machine.
signal current_s,next_s: state_type;  --current and next state declaration.

signal clocked_bos          : std_logic;
signal clocked_bos1q        : std_logic;
signal clocked_bos1qq       : std_logic;


signal n_seq : std_logic_vector (2 downto 0);
signal tr0   : std_logic_vector (2 downto 0);
signal tr1   : std_logic_vector (2 downto 0);
signal tr2   : std_logic_vector (2 downto 0);
signal tr3   : std_logic_vector (2 downto 0);

signal cnt  : std_logic_vector(31 downto 0);
signal cnt2 : std_logic_vector(31 downto 0);
signal cnt_a  : std_logic_vector(31 downto 0);

signal cnt_trig : std_logic_vector(31 downto 0);
signal cnt_hold : std_logic_vector(31 downto 0);


begin

n_seq(2 downto 0)<=TRIGGER_SEQ(2 downto 0);
tr0(2 downto 0)<=TRIGGER_SEQ(5 downto 3);
tr1(2 downto 0)<=TRIGGER_SEQ(8 downto 6);
tr2(2 downto 0)<=TRIGGER_SEQ(11 downto 9);
tr3(2 downto 0)<=TRIGGER_SEQ(14 downto 12);
  
-- synchronize BOS signal
process(CLK)
begin
    if rising_edge(CLK) then
       clocked_bos <=BOS;
       clocked_bos1q <= clocked_bos;

       if (clocked_bos='1') and (clocked_bos1q='0') then
           clocked_bos1qq <= '1';
       else
           clocked_bos1qq <= '0';
       end if;            
    end if;
end process;

-- Start time counter from BOS
    process (CLK)
    begin
       if (rising_edge(CLK)) then
         if (clocked_bos1qq='1') then
          cnt <= (others => '0');
         else
          cnt <= cnt+1;
         end if;
     end if;
    end process;
    CNT_S<=cnt(27);


 
process (CLK)
begin
 if (clocked_bos1qq='1') then
  current_s <= IDLE;  --default state on reset.
elsif (rising_edge(CLK)) then
    current_s <= next_s;   --state change.
end if;
end process;

--Implement State
process (current_s)
begin
  case current_s is

     when IDLE =>
        A_CHANNEL <= '0'; B_CHANNEL <= "000001";
        next_s <= RUNNING;

     when RUNNING =>
        
        if (cnt = T_GAP0 ) then 
            A_CHANNEL <= '1'; B_CHANNEL (7 downto 5) <= tr0 (2 downto 0); B_CHANNEL (4 downto 2) <= "000"; -- trigger 0
            next_s <= HOLD;
        elsif (cnt = T_GAP1) then 
            A_CHANNEL <= '1'; B_CHANNEL (7 downto 5) <= tr1 (2 downto 0); B_CHANNEL (4 downto 2) <= "000"; -- trigger 1
            next_s <= HOLD;
        elsif (cnt = T_GAP2) then 
            A_CHANNEL <= '1'; B_CHANNEL (7 downto 5) <= tr2 (2 downto 0); B_CHANNEL (4 downto 2) <= "000"; -- trigger 2
            next_s <= HOLD;
        elsif (cnt = T_GAP3) then 
            A_CHANNEL <= '1'; B_CHANNEL (7 downto 5) <= tr3 (2 downto 0); B_CHANNEL (4 downto 2) <= "000"; -- trigger 3
            next_s <= HOLD;
        else
            next_s <=IDLE;
        end if;

    when HOLD => 
        if(cnt_hold > 16) then
            next_s <= RUNNING;
            cnt_hold <= (others =>'0');
        end if;
        cnt_hold <= cnt_hold +1;

  end case;
end process;


end Behavioral;
