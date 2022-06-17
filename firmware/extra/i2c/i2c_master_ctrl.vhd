----------------------------------------------------------------------------------
-- Company:  
-- Engineer:  
-- 
-- Create Date:    17:28:38 10/12/2011 
-- Design Name:    I2C_Demo_Firmware_Implementation
-- Module Name:    i2c_master_top2 - Behavioral 
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
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master_ctrl is
	port (
		clk    : in std_logic;
		rst    : in std_logic; -- synchronous active high reset (WISHBONE compatible)
		nReset : in std_logic;	-- asynchornous active low reset (FPGA compatible)

		clk_cnt : in std_logic_vector(15 downto 0);	-- 4x SCL

		-- input signals
		start: in std_logic;
		stop: in std_logic;
		mstr_read: in std_logic;
		mstr_write: in std_logic;
		ack_in : in std_logic;
		data_txd    : in std_logic_vector(7 downto 0);

		-- output signals
		cmd_ack  : out std_logic; ---
		ack_out  : out std_logic;
	  i2c_busy : out std_logic; ---
		data_rxd     : out std_logic_vector(7 downto 0);

	  -- i2c lines
		scl_i   : in std_logic;  -- i2c clock line input
		scl_o   : out std_logic; -- i2c clock line output
		scl_oen : out std_logic; -- i2c clock line output enable, active low
		sda_i   : in std_logic;  -- i2c data line input
		sda_o   : out std_logic; -- i2c data line output
		sda_oen : out std_logic  -- i2c data line output enable, active low
		);
end i2c_master_ctrl;

architecture behavioral of i2c_master_ctrl is

	component i2c_master_byte_ctrl is
	port (
		clk    : in std_logic;
		rst    : in std_logic; -- synchronous active high reset (WISHBONE compatible)
		nReset : in std_logic;	-- asynchornous active low reset (FPGA compatible)
	  --	ena    : in std_logic; -- core enable signal

		clk_cnt : in std_logic_vector(15 downto 0);	-- 4x SCL

		-- input signals
		start: in std_logic;
		stop: in std_logic;
		mstr_read: in std_logic;
		mstr_write: in std_logic;
		ack_in : in std_logic;
    din    : in std_logic_vector(7 downto 0);
		-- output signals
		cmd_ack  : out std_logic; ---
		ack_out  : out std_logic;
		i2c_busy : out std_logic; ---
	--	i2c_al   : out std_logic; ---
		dout     : out std_logic_vector(7 downto 0);

	  -- i2c lines
		scl_i   : in std_logic;  -- i2c clock line input
		scl_o   : out std_logic; -- i2c clock line output
		scl_oen : out std_logic; -- i2c clock line output enable, active low
		sda_i   : in std_logic;  -- i2c data line input
		sda_o   : out std_logic; -- i2c data line output
		sda_oen : out std_logic  -- i2c data line output enable, active low
	);
 end component i2c_master_byte_ctrl;
 
begin
  

	-- hookup byte controller block
	byte_ctrl: i2c_master_byte_ctrl port map (
		clk      => clk,
		rst      => rst,
		nReset   => nReset,
	--	ena      => ena,
		clk_cnt  => clk_cnt,
		start    => start,
		stop     => stop,
		mstr_read   => mstr_read,
		mstr_write  => mstr_write,
		ack_in   => ack_in,
	  i2c_busy => i2c_busy, ---
	--	i2c_al   => open,   ---
		din      => data_txd,
		cmd_ack  => cmd_ack,     ---
		ack_out  => ack_out,
		dout     => data_rxd,
		scl_i    => scl_i,
		scl_o    => scl_o,
		scl_oen  => scl_oen,
		sda_i    => sda_i,
		sda_o    => sda_o,
		sda_oen  => sda_oen
	);

end architecture behavioral;