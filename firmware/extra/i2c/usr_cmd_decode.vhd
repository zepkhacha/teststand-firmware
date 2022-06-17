----------------------------------------------------------------------------------
-- Company: FEA DESY, Hamburg
-- Engineer: Qingqing Xia
-- 
-- Create Date:    15:11:50 10/25/2011 
-- Design Name:    I2C_Demo_Firmware_Implementation
-- Module Name:    pcie_i2c_cmd_decode - Behavioral 
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
-- pcie_cmd format(function): |reg_addr|not used  |regset_write|regset_read|reg_write|reg_read|
-- pcie_cmd format(Bits):     |15-----8|7----- -4 |     3      |      2    |     1   |   0    |
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity usr_cmd_decode is
  Port ( clk : in  STD_LOGIC;
    rst : in  STD_LOGIC;
    pcie_cmd : in  STD_LOGIC_VECTOR (15 downto 0);
    reg_read_start : out  STD_LOGIC;
    reg_write_start : out  STD_LOGIC;
    i2c_regadr : out  STD_LOGIC_VECTOR (7 downto 0);
    cmd_error: out std_logic
  );
end usr_cmd_decode;


architecture Behavioral of usr_cmd_decode is
  
  signal reg_read_start_i,reg_write_start_i: std_logic;
  signal reg_read_start_r,reg_write_start_r: std_logic;
  signal slv_select: std_logic_vector(3 downto 0);
  signal action_select: std_logic_vector(3 downto 0);
  signal pcie_cmd_r: std_logic_vector(15 downto 0);

  
begin
  process(clk)
    begin
      if clk'event and clk='1' then
        if rst='0' then
          reg_read_start_r<='0';
          reg_write_start_r<='0';

          pcie_cmd_r<=(others=>'0');
        else
          reg_read_start_r<=reg_read_start_i;
          reg_write_start_r<=reg_write_start_i;
         
          pcie_cmd_r<=pcie_cmd;
        end if;
      end if;
    end process;
    
    reg_read_start<='1' when (reg_read_start_r='0' and reg_read_start_i='1') else '0'; --generate pulse form signal
    reg_write_start<='1' when (reg_write_start_r='0' and reg_write_start_i='1') else '0'; --generate pulse form signal
    
    i2c_regadr<=pcie_cmd_r(15 downto 8);
    action_select<=pcie_cmd_r(3 downto 0);
    
    process(action_select)
    begin
        reg_read_start_i<='0';
        reg_write_start_i<='0';
        cmd_error<='0';
        case action_select is
        
        when b"0001" =>
          reg_read_start_i<='1';
					
        when b"0010" =>
          reg_write_start_i<='1';        
   
        when b"0000" =>
          reg_read_start_i<='0';
          reg_write_start_i<='0';

				when others=>
				  cmd_error<='1';
					
        end case;       
    end process;
      
  end Behavioral;
    
    