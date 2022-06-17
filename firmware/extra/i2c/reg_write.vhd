----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:34:03 10/25/2011 
-- Design Name:    I2C_Demo_Firmware_Implementation
-- Module Name:    reg_write - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions:  ISE 13.3
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- Write Command Sequence:
-- S(M)|Slave Address(M)|0(M)|A|byte address(M)|A|Data(M)|A|P(M)
-- (M): from master to slave
--  A: Acknowledge
--  N: Not Acknowledge
--  S: START condition
--  P: STOP condition
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
--use work.I2C_PCIe_Interface_PKG.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity reg_write is
  generic(--SLV_ADR:std_logic_vector(6 downto 0):=b"1010101"; --x"55"
  WR: std_logic:='0';
  RD: std_logic:='1');
  port (
    clk    : in std_logic;
    rst    : in std_logic; -- synchronous active high reset
    
    -- input signals
	  slv_addr : in std_logic_vector (6 downto 0);
    reg_write_start : in std_logic;
    ack_rxd_in : in std_logic;
    reg_data_txd_in : in std_logic_vector(7 downto 0);
    reg_addr : in std_logic_vector(7 downto 0);
    cmd_done : in std_logic;
    
    -- outputput signals
    i2c_start : out std_logic;
    i2c_stop  :out  std_logic;
    i2c_write : out  std_logic;
    data_txd_o    : out std_logic_vector(7 downto 0);
    reg_write_done: out std_logic
  );
end entity reg_write; 

architecture behavior of reg_write is
type state is (idle,start_a,start_b,start_c, reg_addr_wr_a,reg_addr_wr_b,reg_addr_wr_c, --
			   reg_wr_a, reg_wr_b, reg_wr_c,restart_a,restart_b,restart_c,NewFreq_regadr_wr_a,NewFreq_regadr_wr_b,NewFreq_regadr_wr_c,--
			   NewFreq_assert_a, NewFreq_assert_b, NewFreq_assert_c,stop_a_a,stop_a_b,stop_a,stop_b,stop_c);
signal reg_wr_state,next_state: state;
signal i2c_write_i,i2c_start_i,i2c_stop_i: std_logic;
signal reg_write_done_i,reg_write_done_r: std_logic;
signal data_txd_o_r,data_txd_o_i: std_logic_vector(7 downto 0);

begin

state_reg: process(clk)
begin
  
  if clk'event and clk='1' then
    if rst='0' then
      reg_wr_state <= state'left;
      i2c_start        <= '0';
      i2c_stop	       <= '0';
      i2c_write	   <= '0';
      data_txd_o_r   <=(others=>'0');
      reg_write_done_r <='0';	
    else
      reg_wr_state<=next_state;
      i2c_start     <= i2c_start_i;
      i2c_stop	    <= i2c_stop_i;
      i2c_write		   <= i2c_write_i;
      reg_write_done_r     <= reg_write_done_i;
      data_txd_o_r<=data_txd_o_i;
    end if;
  end if;

end process;  

data_txd_o<=data_txd_o_r;
reg_write_done<=reg_write_done_r;

reg_wr_stm: process(reg_wr_state,reg_write_start,ack_rxd_in,cmd_done,data_txd_o_r,slv_addr,reg_addr,reg_data_txd_in)

begin
  i2c_start_i<='0';
  i2c_stop_i<='0';
  i2c_write_i<='0';
  reg_write_done_i<='0';
  data_txd_o_i<=data_txd_o_r;

   
  case reg_wr_state is
    
	-- --		idle state
  when idle =>
    if  reg_write_start='1' then 
      next_state<=start_a;
    else
     
      next_state<= idle;
    end if;
	
  -- --		start and write i2c slave address
  when start_a =>
    data_txd_o_i<= slv_addr & WR;				
    i2c_start_i<='1';         --start signal generation
    i2c_write_i<='1';
    next_state<=start_b ;

    
  when start_b =>	   
    if cmd_done='1' then
      next_state<=start_c;
    else 
      next_state<=start_b;
    end if;
    
  when start_c =>
    if ack_rxd_in='0' then
      next_state<=  reg_wr_a; --reg_addr_wr_a;  -- Erdem FSM changed for the 9548A -- no reg address writes. 
    else
      next_state<=start_c;
    end if;	 
     
	 
  -- --		write register address	   
  when reg_addr_wr_a =>	
    next_state<=reg_addr_wr_b;
    data_txd_o_i<= reg_addr; --write slave memory address,89h is freeezedco register
    i2c_write_i<='1';
    
  when reg_addr_wr_b =>	
    if cmd_done='1' then
      next_state<=reg_addr_wr_c; 
    else 
      next_state<=reg_addr_wr_b;
    end if;
    
  when reg_addr_wr_c =>
    if ack_rxd_in='0' then
      next_state<=reg_wr_a;
    else
      next_state<=reg_addr_wr_c;
    end if;	

	
  -- --		write data to slave register 
  when reg_wr_a =>	
    next_state<= reg_wr_b;
    data_txd_o_i<= reg_data_txd_in; 
    i2c_write_i<='1';
    
  when reg_wr_b =>	
    if cmd_done='1' then
      next_state<=reg_wr_c;
    else 
      next_state<=reg_wr_b;
    end if;
    
  when reg_wr_c =>  --dco_unfreeze_c
    if ack_rxd_in='0' then
      next_state<=stop_a;
    else
      next_state<=reg_wr_c;
    end if;			 

	
 -- --		stop
  when stop_a =>	
    i2c_stop_i<='1';        --stop signal generation
    next_state<=stop_b;
    
  when stop_b =>	  
    if cmd_done='1' and reg_addr/=x"89" and reg_data_txd_in/=x"08"  then
      next_state<=stop_c ;
      reg_write_done_i<='1';
    elsif cmd_done='1'then
      next_state<=restart_a;      
    else 
      next_state<=stop_b ;
    end if;
	
 -- --		start
   when restart_a =>
      data_txd_o_i<= slv_addr & WR;				
      i2c_start_i<='1';         --start signal generation
      i2c_write_i<='1';
      next_state<=restart_b ;
       
   when restart_b =>	
      if cmd_done='1' then
        next_state<=restart_c;
      else 
        next_state<=restart_b;
      end if;
       
    when restart_c =>
      if ack_rxd_in='0' then
        next_state<=NewFreq_regadr_wr_a;
      else
        next_state<=restart_c;
      end if;			

      
    -- --		NewFreq Set
       -- --		Byte/Reg address
    when NewFreq_regadr_wr_a =>
      next_state<=NewFreq_regadr_wr_b;
      --data_txd_o_i<= x"06"; --SI570 NewFreq Register Address
      data_txd_o_i<= x"87"; --SI570 NewFreq Register Address
      i2c_write_i<='1'; 
      
    when NewFreq_regadr_wr_b =>	
      if cmd_done='1' then
        next_state<=NewFreq_regadr_wr_c;  
      else 
        next_state<=NewFreq_regadr_wr_b;
      end if;
      
    when NewFreq_regadr_wr_c=>
      if ack_rxd_in='0' then
        next_state<=NewFreq_assert_a;
      else
        next_state<=NewFreq_regadr_wr_c;
      end if;			 

	  
       -- --		set bit to NewFreq
    when NewFreq_assert_a =>	
      next_state<=NewFreq_assert_b;
      data_txd_o_i<= x"40"; --slave memory content,40h
      i2c_write_i<='1';
      
    when NewFreq_assert_b =>	
      if cmd_done='1' then
        next_state<=NewFreq_assert_c;  
      else 
        next_state<=NewFreq_assert_b;
      end if;
       
    when NewFreq_assert_c =>
      if ack_rxd_in='0' then
        next_state<=stop_a_a;
      else
        next_state<=NewFreq_assert_c;
      end if;	
 -- --		stop 
    when stop_a_a =>	
      i2c_stop_i<='1';        -- stop signal for si570 write command!
      next_state<=stop_a_b;	
           
    when stop_a_b =>	  
			if cmd_done='1' then
      next_state<=stop_c ;
      reg_write_done_i<='1';
    else 
      next_state<=stop_a_b ;
    end if;

	
	when stop_c=>
    next_state<=idle ; 
		data_txd_o_i<=(others=>'0');	
		
  when others =>
    next_state<=idle;
  end case;
    
end process;
end architecture behavior;
