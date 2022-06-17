----------------------------------------------------------------------------------
-- Company: 
-- Engineer:  
-- 
-- Create Date:    14:02:25 04/30/2012 
-- Design Name: 
-- Module Name:    ENT_I2C - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;


entity ENT_I2C is
generic(
  GEN_I2C_FREQ_SCALE:std_logic_vector(15 downto 0):=x"0140" ); --; --I2c frequency perscale
  --GEN_I2C_DEVICE_ADDR:std_logic_vector(6 downto 0):=b"1010101"); --x"55" for XOSI570 on the DAMC2 Board); --I2c Device ADDRESS
 port(
    P_I_CLK_IN  : in std_logic;
    P_I_I2C_RST :in std_logic;
    P_I_I2C_ENA : in std_logic;  
    P_I_I2C_CMD : in std_logic_vector(15 downto 0);  
    P_O_I2C_STATUS : out std_logic_vector(15 downto 0);  
    P_O_I2C_RX_REG :out std_logic_vector(7 downto 0);
    P_I_I2C_TX_REG :in std_logic_vector(7 downto 0);
	 I2C_DEVICE_ADDR : in std_logic_vector(6 downto 0);
    P_IO_SCL : inout std_logic;
    P_IO_SDA : inout std_logic
    );
    
end ENT_I2C;

architecture Behavioral of ENT_I2C is

 COMPONENT usr_cmd_decode
    PORT (
      clk                : IN     STD_LOGIC;
      rst                : IN     STD_LOGIC;
      pcie_cmd       		 : IN     STD_LOGIC_VECTOR(15 downto 0);
      reg_read_start     : OUT    STD_LOGIC;
      reg_write_start    : OUT    STD_LOGIC;
      i2c_regadr         : OUT    STD_LOGIC_VECTOR(7 downto 0);
      cmd_error      		 : OUT    STD_LOGIC
    );
  END COMPONENT;
  
 COMPONENT i2c_ctrl_top is
  PORT(sys_clk : in std_logic;
      nreset : in std_logic;
      pcie_wr_reg : in std_logic_vector(7 downto 0);
      slv_addr : in std_logic_vector(6 downto 0);
      reg_addr : in std_logic_vector(7 downto 0);
      cmd_done : in std_logic;
      reg_read_start : in std_logic;
      reg_write_start: in std_logic;
      ack_rxd  : in std_logic;
      data_rxd : in std_logic_vector(7 downto 0);
      pcie_cmd : in std_logic_vector(15 downto 0);
      ack_txd  : out std_logic;
      data_txd : out std_logic_vector(7 downto 0);
      i2c_start: out std_logic;
      i2c_stop : out std_logic;
      i2c_read : out std_logic;
      i2c_write: out std_logic;
      i2c_status : out std_logic_vector(15 downto 0);
      cmdreg_rst : out std_logic;
      pcie_rd_reg: out std_logic_vector(7 downto 0)
    );
  END COMPONENT i2c_ctrl_top;
	
  COMPONENT i2c_master_ctrl
    PORT(
      clk : IN  std_logic;
      rst : IN  std_logic;
      nReset : IN  std_logic;
      clk_cnt: IN std_logic_vector (15 downto 0);
      start : IN  std_logic;
      stop  : IN  std_logic;
      mstr_read  : IN  std_logic;
      mstr_write : IN  std_logic;
      ack_in : IN  std_logic;
      data_txd : IN  std_logic_vector(7 downto 0);
      cmd_ack  : OUT std_logic; ---
      ack_out  : OUT  std_logic;
      i2c_busy : out std_logic; ---
      data_rxd : OUT  std_logic_vector(7 downto 0);
      scl_i : IN  std_logic;
      scl_o : OUT  std_logic;
      scl_oen : OUT  std_logic;
      sda_i : IN  std_logic;
      sda_o : OUT  std_logic;
      sda_oen : OUT  std_logic
    );
  END COMPONENT; 		 
    
  
  ----------------- Pull UP ----------------
  COMPONENT PULLUP
    PORT(O: out std_logic);
  END COMPONENT;
   
    -- Clock signals   
    signal sys_clk 	 : std_logic;
    signal nReset: std_logic;
    
    ------i2c_mstr_ctrl-------------
    signal ack_txd 	: std_logic;
    signal data_txd : std_logic_vector(7 downto 0);
    signal scl_pad_i : std_logic;
    signal sda_pad_i : std_logic;
    signal ack_rxd 	: std_logic;
    signal data_rxd : std_logic_vector(7 downto 0);
    signal scl_pad_o: std_logic;
    signal scl_pad_oen : std_logic;
    signal sda_pad_o 	 : std_logic;
    signal sda_pad_oen : std_logic;
    signal i2c_busy 	 : std_logic;
    signal cmd_done 	 :std_logic;
    signal i2c_start      : std_logic;
    signal i2c_stop       : std_logic;
    signal i2c_read       : std_logic;
    signal i2c_write      : std_logic;
		
    -----from command decode ------------------
    signal reg_addr   : std_logic_vector(7 downto 0);
    signal cmd_error  : std_logic;
    signal cmdreg_rst : std_logic;
    
    ----- i2c reg/regset write/read start----------
    signal reg_read_start   	: std_logic;
    signal reg_write_start 		: std_logic;
    --signal regset_read_start 	: std_logic;
    -- signal regset_write_start : std_logic;
    
    -----pcie data regset---------
    -- signal pcie_regset_read: regset;
    -- signal pcie_regset_write_r: regset;
    signal pcie_wr_reg_r: std_logic_vector(7 downto 0);
    
    -----pcie i2c command reg---------
    signal SIG_I2C_CMD       : STD_LOGIC_VECTOR(15 downto 0);
    signal SIG_I2C_ADR       : STD_LOGIC_VECTOR(6 downto 0);
    
    
    BEGIN   
	
      sys_clk<=P_I_CLK_IN;
      nReset<=not P_I_I2C_RST;
      
      -- --		usr command decoder
      usr_cmd_decode_i : usr_cmd_decode
      PORT MAP (
        clk                => sys_clk,
        rst                => nReset,
        pcie_cmd       		 => SIG_I2C_CMD,
        reg_read_start     => reg_read_start,
        reg_write_start    => reg_write_start,
        i2c_regadr         => reg_addr,
        cmd_error					 => cmd_error
      );
      
      -- --		I2c sequence control				
      i2c_ctrl_i: i2c_ctrl_top 
      port map(
        sys_clk           => sys_clk,
        nreset 						=> nreset,
        pcie_wr_reg 			=> pcie_wr_reg_r,
        slv_addr 					=> SIG_I2C_ADR,
        reg_addr					=> reg_addr,
        cmd_done 					=> cmd_done,
        reg_read_start 		=> reg_read_start,
        reg_write_start		=> reg_write_start,
        ack_rxd 					=> ack_rxd,
        data_rxd 					=> data_rxd,
        pcie_cmd				 	=> SIG_I2C_CMD,
        ack_txd 					=> ack_txd,
        data_txd 					=> data_txd,
        i2c_start 				=> i2c_start,
        i2c_stop 					=> i2c_stop,
        i2c_read 					=> i2c_read,
        i2c_write 				=> i2c_write,
        i2c_status 				=> P_O_I2C_STATUS,
        cmdreg_rst 				=> cmdreg_rst,
        pcie_rd_reg 			=> P_O_I2C_RX_REG
      );
      
      -- --		I2C master core
      i2c_master_ctrl_i: i2c_master_ctrl        
      PORT MAP (
        clk 				=> sys_clk,
        rst					=> '0',
        nReset			=> nReset,
        clk_cnt 		=> GEN_I2C_FREQ_SCALE,
        start 			=> i2c_start,
        stop 				=> i2c_stop,
        mstr_read 	=> i2c_read,
        mstr_write 	=> i2c_write,
        ack_in 			=> ack_txd,
        data_txd 		=> data_txd,
        cmd_ack 		=> cmd_done,
        ack_out 		=> ack_rxd,
        i2c_busy		=> i2c_busy,
        data_rxd 		=> data_rxd,
        scl_i 			=> scl_pad_i,
        scl_o 			=> scl_pad_o,
        scl_oen 		=> scl_pad_oen,
        sda_i				=> sda_pad_i,
        sda_o 			=> sda_pad_o,
        sda_oen			=> sda_pad_oen
      );
      		  
  i2c_cmdreg: process(sys_clk)
  begin
     if sys_clk'event and sys_clk='1' then
        if (cmdreg_rst='1' or P_I_I2C_RST='1') then
          SIG_I2C_CMD<=(others=>'0');
        elsif P_I_I2C_ENA='1' then  ---strobe/enable signal comes from IIbus
          SIG_I2C_CMD<=P_I_I2C_CMD;                    
        end if;
     end if;
  end process;
		
  SIG_I2C_ADR<=I2C_DEVICE_ADDR;
	pcie_wrreg: process(sys_clk)
    begin
      if sys_clk'event and sys_clk='1' then 
					if P_I_I2C_RST='1' then
						pcie_wr_reg_r<=(others=>'0');
					else
						
						pcie_wr_reg_r<=P_I_I2C_TX_REG;
					
					end if;
      end if;
    end process;
    	
  IOBUF_inst_scl : IOBUF
  generic map (
      DRIVE => 12,
      IOSTANDARD => "LVCMOS25",
      SLEW => "SLOW"
    )
  port map (
      O  =>  scl_pad_i,              -- Buffer output
      IO =>  P_IO_SCL,                    -- Buffer inout port (connect directly to top-level port)
      I  =>  scl_pad_o,              -- Buffer input
      T  =>  scl_pad_oen             -- 3-state enable input, high=input, low=output
    );
    
  IOBUF_inst_sda : IOBUF
  generic map (
      DRIVE => 12,
      IOSTANDARD => "LVCMOS25",
      SLEW => "SLOW"
      )
  port map (
      O  =>  sda_pad_i,              -- Buffer output
      IO =>  P_IO_SDA,               -- Buffer inout port (connect directly to top-level port)
      I  =>  sda_pad_o,              -- Buffer input
      T  =>  sda_pad_oen             -- 3-state enable input, high=input, low=output
   );


end Behavioral;

