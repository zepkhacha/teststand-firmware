----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:34:03 10/25/2011 
-- Design Name:    I2C_Demo_Firmware_Implementation
-- Module Name:    reg_read - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: ISE 13.3
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- Read Command Sequence:
-- S(M)|Slave Address(M)|0(M)|A|byte address(M)|A|S(M)|Slave Address(M)|1(M)|A|data|N(M)|P(M)
-- (M): from master to slave
-- A: Acknowledge
-- N: Not Acknowledge
-- S: START condition
-- P: STOP condition
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


entity reg_read is
  generic(--SLV_ADR:std_logic_vector(6 downto 0):=b"1010101"; --x"55"
  WR: std_logic:='0';
  RD: std_logic:='1');
  port (
    clk    : in std_logic;
    rst    : in std_logic; -- synchronous active high reset
    
    -- input signals
	  slv_addr: in std_logic_vector (6 downto 0);
    reg_read_start: in std_logic;
    ack_rxd_in  : in std_logic;
    data_rxd_in  : in std_logic_vector(7 downto 0);
    reg_addr     : in std_logic_vector(7 downto 0);
    cmd_done: in std_logic;
    
    -- outputput signals
    i2c_start: out std_logic;
    i2c_stop:out  std_logic;
    i2c_read:out  std_logic;
    i2c_write: out  std_logic;
    ack_txd_o :out  std_logic;
    data_txd_o   : out std_logic_vector(7 downto 0);
    reg_data_rxd_o   : out std_logic_vector(7 downto 0);
    reg_read_done: out std_logic
  );
end entity reg_read; 


architecture behavior of reg_read is

type state is (idle,start_a,start_b,start_c, --
							restart_a,restart_b,restart_c,
               reg_addr_wr_a,reg_addr_wr_b,reg_addr_wr_c, --
							 reg_rd_a, reg_rd_b, reg_rd_c,stop_a,stop_b,stop_c);
signal reg_rd_state,next_state: state;
signal i2c_read_i,i2c_write_i,i2c_start_i,i2c_stop_i: std_logic;
signal data_txd_o_r,data_txd_o_i: std_logic_vector(7 downto 0);
signal ack_txd_o_i:std_logic;
signal reg_read_done_r,reg_read_done_i:std_logic;
signal reg_data_rxd_o_i,reg_data_rxd_o_r:std_logic_vector(7 downto 0);
begin

state_reg: process(clk)
begin
  
  if clk'event and clk='1' then
    if rst='0' then
      reg_rd_state <= state'left;
      i2c_start        <= '0';
      i2c_stop	       <= '0';
      i2c_read	   <= '0';
      i2c_write	   <= '0';
      ack_txd_o	   <= '0';
      reg_read_done_r   <= '0';
      reg_data_rxd_o_r   <=(others=>'0');
      data_txd_o_r   <=(others=>'0');
    
    else
      reg_rd_state<=next_state;
      i2c_start     <= i2c_start_i;
      i2c_stop	    <= i2c_stop_i;
      i2c_read	   <= i2c_read_i;
      i2c_write		   <= i2c_write_i;
      ack_txd_o	   <=	ack_txd_o_i;
      data_txd_o_r<=data_txd_o_i;
      reg_data_rxd_o_r<=reg_data_rxd_o_i;
      reg_read_done_r<=reg_read_done_i;
    end if;
  end if;
  
end process;

  reg_data_rxd_o<=reg_data_rxd_o_r;
  data_txd_o<=data_txd_o_r;
  reg_read_done<=reg_read_done_r;

  reg_read_stm:process(reg_rd_state,reg_read_start,ack_rxd_in,cmd_done,data_rxd_in,data_txd_o_r,reg_read_done_r,reg_addr,slv_addr,reg_data_rxd_o_r)
  begin

  i2c_start_i<='0';
  i2c_stop_i<='0';
  i2c_read_i<='0';
  i2c_write_i<='0';
  ack_txd_o_i<='0';
  reg_read_done_i<='0';
  data_txd_o_i<=data_txd_o_r;
  reg_data_rxd_o_i<=reg_data_rxd_o_r;

  case reg_rd_state is
    
  -- --  idle state
  when idle =>  
    --if reg_read_start'event and reg_read_start='1' then 
    if reg_read_start='1' then 
      next_state<= restart_a; --start_a;   -- Erdem --start the FSM from restart_a		  	
    else 
      next_state<=idle;
    end if;


   -- --	start and write i2c slave address
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
      next_state<=reg_addr_wr_a;
    else
      next_state<=start_c;
    end if;			

    
  -- --		write register address 
  when reg_addr_wr_a=>
    next_state<=reg_addr_wr_b;
    data_txd_o_i<= reg_addr; --beginning/first slave memory read address/byte address
    i2c_write_i<='1';
    
  when reg_addr_wr_b =>	
    if cmd_done='1' then
      next_state<=reg_addr_wr_c;     
    else 
      next_state<=reg_addr_wr_b;
    end if;
    
  when reg_addr_wr_c =>
    if ack_rxd_in='0' then
      next_state<=restart_a;
    else
      next_state<=reg_addr_wr_c;
    end if;			 

-- Erdem -- Start the FSM from restart_a ---
    
  -- --		write slave address and indicate reading data from slave to master after this    
  when restart_a =>      ---slave address again
    data_txd_o_i<= slv_addr & RD;				
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
      next_state<=reg_rd_a;
    else
      next_state<=restart_c;
    end if;	

    
  -- --  read register from slave
  when reg_rd_a =>	  
    next_state<=reg_rd_b;
    ack_txd_o_i<='1';        -- register read finished because only one register to be read! NACK+Stop
    i2c_read_i<='1';         
    
  when reg_rd_b =>	  
    if cmd_done='1' then
      next_state<=reg_rd_c;  
    else 
      next_state<=reg_rd_b;
      ack_txd_o_i<='1';      -- fixed bug at 06.10 2013
    end if;
    
  when reg_rd_c =>  
    reg_data_rxd_o_i<=data_rxd_in;
    next_state<=stop_a;


  -- --  stop		  
  when stop_a =>	  
    i2c_stop_i<='1';        --stop signal generation
    next_state<=stop_b;
    i2c_write_i<='1';
    
  when stop_b =>	  
    if cmd_done='1' then
      next_state<=stop_c ;
      reg_read_done_i<='1';
    else 
      next_state<=stop_b ;
    end if;
    
  when stop_c=>
    next_state<=idle ;
    data_txd_o_i<=(others=>'0');
       
  when others =>
    next_state<=idle;
  end case;       

  end process;
end architecture behavior;
