----------------------------------------------------------------------------------
-- Company:  
-- Engineer: 
-- 
-- Create Date:    14:44:14 11/01/2011 
-- Design Name:    I2C_Demo_Firmware_Implementation
-- Module Name:    i2c_ctrl_top - Behavioral 
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
LIBRARY work;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_ctrl_top is
  port(sys_clk: in std_logic;
    nreset: in std_logic;
    pcie_wr_reg: in std_logic_vector(7 downto 0);
   -- pcie_regset_write: in regset;
    slv_addr: in std_logic_vector(6 downto 0);
    reg_addr: in std_logic_vector(7 downto 0);
    cmd_done: in std_logic;
    reg_read_start: in std_logic;
    reg_write_start: in std_logic;
    ack_rxd: in std_logic;
    data_rxd: in std_logic_vector(7 downto 0);
    pcie_cmd: in std_logic_vector(15 downto 0);
    ack_txd: out std_logic;
    data_txd: out std_logic_vector(7 downto 0);
    i2c_start: out std_logic;
    i2c_stop: out std_logic;
    i2c_read: out std_logic;
    i2c_write: out std_logic;
    i2c_status: out std_logic_vector(15 downto 0);
    cmdreg_rst: out std_logic;
    pcie_rd_reg: out std_logic_vector(7 downto 0)
   -- pcie_regset_read: out regset
  );
end entity i2c_ctrl_top;

architecture Behavioral of i2c_ctrl_top is
  COMPONENT reg_read
    GENERIC (
      WR : std_logic := '0';
      RD : std_logic := '1'
    );
    PORT (
      clk            : IN     std_logic;
      rst            : IN     std_logic;
      slv_addr       : IN     std_logic_vector(6 downto 0);
      reg_read_start   : IN     std_logic;
      ack_rxd_in     : IN     std_logic;
      data_rxd_in    : IN     std_logic_vector(7 downto 0);
      reg_addr       : IN     std_logic_vector(7 downto 0);
      cmd_done       : IN     std_logic;
      i2c_start      : OUT    std_logic;
      i2c_stop       : OUT    std_logic;
      i2c_read       : OUT    std_logic;
      i2c_write      : OUT    std_logic;
      ack_txd_o      : OUT    std_logic;
      data_txd_o     : OUT    std_logic_vector(7 downto 0);
      reg_data_rxd_o : OUT    std_logic_vector(7 downto 0);
      reg_read_done  : OUT    std_logic
    );
  END COMPONENT;	
	
  COMPONENT reg_write
    GENERIC (
      WR : std_logic := '0';
      RD : std_logic := '1'
    );
    PORT (
      clk             : IN     std_logic;
      rst             : IN     std_logic;
      slv_addr        : IN     std_logic_vector(6 downto 0);
      reg_write_start : IN     std_logic;
      ack_rxd_in      : IN     std_logic;
      reg_data_txd_in : IN     std_logic_vector(7 downto 0);
      reg_addr        : IN     std_logic_vector(7 downto 0);
      cmd_done        : IN     std_logic;
      i2c_start       : OUT    std_logic;
      i2c_stop        : OUT    std_logic;
      i2c_write       : OUT    std_logic;
      data_txd_o      : OUT    std_logic_vector(7 downto 0);
      reg_write_done  : OUT    std_logic
    );
  END COMPONENT;		
  
  -------i2c command---------
  
  SIGNAL i2c_start_i1      : std_logic;
  SIGNAL i2c_start_i2      : std_logic;
  --SIGNAL i2c_start_i3      : std_logic;
  --SIGNAL i2c_start_i4      : std_logic;
  
  SIGNAL i2c_stop_i1       : std_logic;
  SIGNAL i2c_stop_i2       : std_logic;
  
  SIGNAL i2c_read_i1       : std_logic;
  
  SIGNAL i2c_write_i1      : std_logic;
  SIGNAL i2c_write_i2      : std_logic;
  
  signal i2c_action_start: std_logic;
  
  ----- i2c reg/regset write/read finished----------
  SIGNAL reg_read_done  : std_logic;
  SIGNAL reg_write_done  : std_logic;

  
  -----from command decode ------------------
  SIGNAL cmdreg_rst_i  : std_logic;
  signal i2c_status_i: std_logic_vector(15 downto 0);
  signal i2c_status_r: std_logic_vector(15 downto 0);
 
  signal ack_txd_i1 : std_logic;

  signal data_txd_i1 : std_logic_vector(7 downto 0);
  signal data_txd_i2 : std_logic_vector(7 downto 0);

  
  
begin
  -- Instantiate the Unit Under Test (UUT)
  reg_read_i: reg_read
  GENERIC MAP (
    WR => '0',
    RD => '1'
  )
  PORT MAP (
    clk            => sys_clk,--
    rst            => nReset,--
    slv_addr       => slv_addr,--
    reg_read_start   => reg_read_start,--
    ack_rxd_in     => ack_rxd,--
    data_rxd_in    => data_rxd,--
    reg_addr       => reg_addr,
    cmd_done       => cmd_done,--
    i2c_start      => i2c_start_i1,--
    i2c_stop       => i2c_stop_i1,--
    i2c_read       => i2c_read_i1,--
    i2c_write      => i2c_write_i1,--
    ack_txd_o      => ack_txd_i1,--
    data_txd_o     => data_txd_i1,--
    reg_data_rxd_o => pcie_rd_reg,---
    reg_read_done  => reg_read_done--
  );
  
  reg_write_i : reg_write
  GENERIC MAP (
    WR => '0',
    RD => '1'
  )
  PORT MAP (
    clk             => sys_clk,---
    rst             => nReset,---
    slv_addr        => slv_addr,---
    reg_write_start => reg_write_start,--
    ack_rxd_in      => ack_rxd,---
    reg_data_txd_in => pcie_wr_reg,---
    reg_addr        => reg_addr,
    cmd_done        => cmd_done,---
    i2c_start       => i2c_start_i2,---
    i2c_stop        => i2c_stop_i2,---
    i2c_write       => i2c_write_i2,---
    data_txd_o      => data_txd_i2,---
    reg_write_done  => reg_write_done--
    );
  
  
  -- --  chip dependent ctrl
--  regset_write_i : regset_write
--  GENERIC MAP (
--    WR => '0',
--    RD => '1'
--  )
--  PORT MAP (
--    clk                => sys_clk,--
--    rst                => nReset,--
--    slv_addr           => slv_addr,--
--    regset_write_start => regset_write_start,--//////
--    ack_rxd_in         => ack_rxd,--
--    regset_data_txd_in     => pcie_regset_write,---from pcie reg, pcie_regset_write
--    cmd_done           => cmd_done,--
--    i2c_start          => i2c_start_i3,--
--    i2c_stop           => i2c_stop_i3,--
--    -- i2c_read           => i2c_read_i3,--
--    i2c_write          => i2c_write_i3,--
--    -- ack_txd_o          => ack_txd_i3,--
--    data_txd_o         => data_txd_i3,--
--    regset_write_done  => regset_write_done--//////
--  );
  
  -- --  i2c chip dependent ctrl
--  regset_read_i : regset_read
--  GENERIC MAP (
--    WR => '0',
--    RD => '1'
--  )
--  PORT MAP (
--    clk               => sys_clk,---
--    rst               => nReset,---
--    slv_addr          => slv_addr,---
--    regset_read_start => regset_read_start,--//////
--    ack_rxd_in        => ack_rxd,---
--    data_rxd_in       => data_rxd,---
--    cmd_done          => cmd_done,---
--    i2c_start         => i2c_start_i4,---
--    i2c_stop          => i2c_stop_i4,---
--    i2c_read          => i2c_read_i4,---
--    i2c_write         => i2c_write_i4,---
--    ack_txd_o         => ack_txd_i4,---
--    data_txd_o        => data_txd_i4,---
--    regset_data_rxd_o => pcie_regset_read,---to pcie reg, pcie_regset_read
--    regset_read_done  => regset_read_done--//////
--  );
--  
--  
  -- --  I2C Command Mux			
  i2c_action_start<=	reg_read_start or  reg_write_start; --
--  or regset_read_start or regset_write_start;
  i2c_start<=i2c_start_i1 or i2c_start_i2;-- or i2c_start_i3 or i2c_start_i4;
  i2c_stop<=i2c_stop_i1 or i2c_stop_i2;-- or i2c_stop_i3 or i2c_stop_i4;
  i2c_read<=i2c_read_i1;-- or i2c_read_i4;
  i2c_write<=i2c_write_i1 or i2c_write_i2;-- or i2c_write_i3 or i2c_write_i4;
  data_txd<=data_txd_i1 or data_txd_i2;-- or data_txd_i3 or data_txd_i4;		
  ack_txd<=ack_txd_i1;-- or ack_txd_i4;	
  
  -- --	Status register ctrl                  
  process(i2c_action_start,reg_read_done,reg_write_done,pcie_cmd,i2c_status_r)
    begin
      i2c_status_i<=i2c_status_r;
      if (i2c_action_start='1') then
        i2c_status_i<=pcie_cmd(15 downto 4) & b"0000";
      elsif reg_read_done='1' then
        i2c_status_i<=pcie_cmd(15 downto 4) & b"0001";
      elsif reg_write_done='1' then
        i2c_status_i<=pcie_cmd(15 downto 4) & b"0010";
      --elsif regset_read_done='1' then
       -- i2c_status_i<=pcie_cmd(15 downto 4) & b"0100";
      --elsif regset_write_done='1' then
       -- i2c_status_i<=pcie_cmd(15 downto 4) & b"1000";
      else
        null;
      end if;					
    end process;			
    
    i2c_status_reg: process(sys_clk)
    begin
      if sys_clk'event and sys_clk='1' then
        if nReset='0' then
          i2c_status_r<=(others=>'0');
        else
          i2c_status_r<=i2c_status_i;
        end if;
      end if;
    end process;
    i2c_status<=i2c_status_r;
    
    -- --  Command register reset ctrl
    cmdreg_rst_i<='1' when (reg_read_done or reg_write_done )='1' else '0';				--
    --regset_read_done or regset_write_done--

    
    cmdreg_rst_reg:process(sys_clk)
    begin
      if sys_clk'event and sys_clk='1' then
        if nReset='0' then
          cmdreg_rst<='0';
        else
          cmdreg_rst<=cmdreg_rst_i;
        end if;
      end if;
    end process;
    
end Behavioral;
  
  