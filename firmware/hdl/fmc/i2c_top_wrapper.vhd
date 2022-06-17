-- Wrapper to instantiate i2c_top.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.system_package.all;

entity i2c_top_wrapper is
port (
  -- clock and reset
  clk   : in std_logic;
  reset : in std_logic;

  -- control signals
  fmc_loc               : in std_logic_vector(1 downto 0);
  fmc_mod_type          : in std_logic_vector(7 downto 0);
  fmc_absent            : in std_logic;
  sfp_requested_ports_i : in std_logic_vector(7 downto 0);
  i2c_en_start          : in std_logic;
  i2c_rd_start          : in std_logic;

  -- generic read interface
  channel_sel_in       : in  std_logic_vector(  7 downto 0);
  eeprom_map_sel_in    : in  std_logic;
  eeprom_start_adr_in  : in  std_logic_vector(  7 downto 0);
  eeprom_num_regs_in   : in  std_logic_vector(  5 downto 0);
  eeprom_reg_out       : out std_logic_vector(127 downto 0);
  eeprom_reg_out_valid : out std_logic;

  -- status signals
  sfp_enabled_ports : out std_logic_vector(7 downto 0);
  sfp_sn            : out array_8x128bit;
  sfp_mod_abs       : out std_logic_vector(7 downto 0);
  sfp_tx_fault      : out std_logic_vector(7 downto 0);
  sfp_rx_los        : out std_logic_vector(7 downto 0);

  change_mod_abs  : out std_logic_vector(7 downto 0);
  change_tx_fault : out std_logic_vector(7 downto 0);
  change_rx_los   : out std_logic_vector(7 downto 0);

  fs_state  : out std_logic_vector(27 downto 0);
  st_state  : out std_logic_vector(32 downto 0);
  ssc_state : out std_logic_vector(10 downto 0);
  sgr_state : out std_logic_vector( 6 downto 0);

  -- warning signals
  change_error_mod_abs  : out std_logic_vector(7 downto 0);
  change_error_tx_fault : out std_logic_vector(7 downto 0);
  change_error_rx_los   : out std_logic_vector(7 downto 0);
  
  -- error signals
  error_fmc_absent   : out std_logic;
  error_fmc_mod_type : out std_logic;
  error_fmc_int_n    : out std_logic;
  error_startup_i2c  : out std_logic;

  sfp_en_error_mod_abs    : out std_logic_vector(7 downto 0);
  sfp_en_error_sfp_type   : out std_logic_vector(1 downto 0);
  sfp_en_error_tx_fault   : out std_logic_vector(7 downto 0);
  sfp_en_error_sfp_alarms : out std_logic;
  sfp_en_error_i2c_chip   : out std_logic;

  -- SFP alarm flags
  sfp_alarm_temp_high     : out std_logic_vector(7 downto 0);
  sfp_alarm_temp_low      : out std_logic_vector(7 downto 0);
  sfp_alarm_vcc_high      : out std_logic_vector(7 downto 0);
  sfp_alarm_vcc_low       : out std_logic_vector(7 downto 0);
  sfp_alarm_tx_bias_high  : out std_logic_vector(7 downto 0);
  sfp_alarm_tx_bias_low   : out std_logic_vector(7 downto 0);
  sfp_alarm_tx_power_high : out std_logic_vector(7 downto 0);
  sfp_alarm_tx_power_low  : out std_logic_vector(7 downto 0);
  sfp_alarm_rx_power_high : out std_logic_vector(7 downto 0);
  sfp_alarm_rx_power_low  : out std_logic_vector(7 downto 0);
    
  -- SFP warning flags
  sfp_warning_temp_high     : out std_logic_vector(7 downto 0);
  sfp_warning_temp_low      : out std_logic_vector(7 downto 0);
  sfp_warning_vcc_high      : out std_logic_vector(7 downto 0);
  sfp_warning_vcc_low       : out std_logic_vector(7 downto 0);
  sfp_warning_tx_bias_high  : out std_logic_vector(7 downto 0);
  sfp_warning_tx_bias_low   : out std_logic_vector(7 downto 0);
  sfp_warning_tx_power_high : out std_logic_vector(7 downto 0);
  sfp_warning_tx_power_low  : out std_logic_vector(7 downto 0);
  sfp_warning_rx_power_high : out std_logic_vector(7 downto 0);
  sfp_warning_rx_power_low  : out std_logic_vector(7 downto 0);

  -- I2C signals
  i2c_int_n_i  : in  std_logic;
  scl_pad_i    : in  std_logic; -- 'clock' input from external pin
  scl_pad_o    : out std_logic; -- 'clock' output to tri-state driver
  scl_padoen_o : out std_logic; -- 'clock' enable signal for tri-state driver
  sda_pad_i    : in  std_logic; -- 'data' input from external pin
  sda_pad_o    : out std_logic; -- 'data' output to tri-state driver
  sda_padoen_o : out std_logic  -- 'data' enable signal for tri-state driver
);
end i2c_top_wrapper;

architecture Behavioral of i2c_top_wrapper is

  component i2c_top is 
  port (
    -- clock and reset
    clk   : in std_logic;
    reset : in std_logic;

    -- control signals
    fmc_loc               : in std_logic_vector(1 downto 0);
    fmc_mod_type          : in std_logic_vector(7 downto 0);
    fmc_absent            : in std_logic;
    sfp_requested_ports_i : in std_logic_vector(7 downto 0);
    i2c_en_start          : in std_logic;
    i2c_rd_start          : in std_logic;

    -- generic read interface
    channel_sel_in       : in  std_logic_vector(  7 downto 0);
    eeprom_map_sel_in    : in  std_logic;
    eeprom_start_adr_in  : in  std_logic_vector(  7 downto 0);
    eeprom_num_regs_in   : in  std_logic_vector(  5 downto 0);
    eeprom_reg_out       : out std_logic_vector(127 downto 0);
    eeprom_reg_out_valid : out std_logic;

    -- status signals
    sfp_enabled_ports : out std_logic_vector(   7 downto 0);
    sfp_sn_vec        : out std_logic_vector(1023 downto 0);
    sfp_mod_abs       : out std_logic_vector(   7 downto 0);
    sfp_tx_fault      : out std_logic_vector(   7 downto 0);
    sfp_rx_los        : out std_logic_vector(   7 downto 0);

    change_mod_abs  : out std_logic_vector(7 downto 0);
    change_tx_fault : out std_logic_vector(7 downto 0);
    change_rx_los   : out std_logic_vector(7 downto 0);

    fs_state  : out std_logic_vector(27 downto 0);
    st_state  : out std_logic_vector(32 downto 0);
    ssc_state : out std_logic_vector(10 downto 0);
    sgr_state : out std_logic_vector( 6 downto 0);

    -- warning signals
    change_error_mod_abs  : out std_logic_vector(7 downto 0);
    change_error_tx_fault : out std_logic_vector(7 downto 0);
    change_error_rx_los   : out std_logic_vector(7 downto 0);
    
    -- error signals
    error_fmc_absent   : out std_logic;
    error_fmc_mod_type : out std_logic;
    error_fmc_int_n    : out std_logic;
    error_startup_i2c  : out std_logic;

    sfp_en_error_mod_abs    : out std_logic_vector(7 downto 0);
    sfp_en_error_sfp_type   : out std_logic_vector(1 downto 0);
    sfp_en_error_tx_fault   : out std_logic_vector(7 downto 0);
    sfp_en_error_sfp_alarms : out std_logic;
    sfp_en_error_i2c_chip   : out std_logic;

    -- SFP alarm flags
    sfp_alarm_temp_high     : out std_logic_vector(7 downto 0);
    sfp_alarm_temp_low      : out std_logic_vector(7 downto 0);
    sfp_alarm_vcc_high      : out std_logic_vector(7 downto 0);
    sfp_alarm_vcc_low       : out std_logic_vector(7 downto 0);
    sfp_alarm_tx_bias_high  : out std_logic_vector(7 downto 0);
    sfp_alarm_tx_bias_low   : out std_logic_vector(7 downto 0);
    sfp_alarm_tx_power_high : out std_logic_vector(7 downto 0);
    sfp_alarm_tx_power_low  : out std_logic_vector(7 downto 0);
    sfp_alarm_rx_power_high : out std_logic_vector(7 downto 0);
    sfp_alarm_rx_power_low  : out std_logic_vector(7 downto 0);
      
    -- SFP warning flags
    sfp_warning_temp_high     : out std_logic_vector(7 downto 0);
    sfp_warning_temp_low      : out std_logic_vector(7 downto 0);
    sfp_warning_vcc_high      : out std_logic_vector(7 downto 0);
    sfp_warning_vcc_low       : out std_logic_vector(7 downto 0);
    sfp_warning_tx_bias_high  : out std_logic_vector(7 downto 0);
    sfp_warning_tx_bias_low   : out std_logic_vector(7 downto 0);
    sfp_warning_tx_power_high : out std_logic_vector(7 downto 0);
    sfp_warning_tx_power_low  : out std_logic_vector(7 downto 0);
    sfp_warning_rx_power_high : out std_logic_vector(7 downto 0);
    sfp_warning_rx_power_low  : out std_logic_vector(7 downto 0);

    -- I2C signals
    i2c_int_n_i  : in  std_logic;
    scl_pad_i    : in  std_logic; -- 'clock' input from external pin
    scl_pad_o    : out std_logic; -- 'clock' output to tri-state driver
    scl_padoen_o : out std_logic; -- 'clock' enable signal for tri-state driver
    sda_pad_i    : in  std_logic; -- 'data' input from external pin
    sda_pad_o    : out std_logic; -- 'data' output to tri-state driver
    sda_padoen_o : out std_logic  -- 'data' enable signal for tri-state driver
  );
  end component;

  signal sfp_sn_vec : std_logic_vector(1023 downto 0);

begin

  -- fill in serial number matrix
  sfp_sn_gen: for i in 0 to 7 generate
  begin
    sfp_sn(i) <= sfp_sn_vec((128*i + 127) downto (128*i));
  end generate;

  -- instantiate i2c_top
  i2c_top_inst: i2c_top
  port map (
    -- clock and reset
    clk   => clk,
    reset => reset,

    -- control signals
    fmc_loc               => fmc_loc,
    fmc_mod_type          => fmc_mod_type,
    fmc_absent            => fmc_absent,
    sfp_requested_ports_i => sfp_requested_ports_i,
    i2c_en_start          => i2c_en_start,
    i2c_rd_start          => i2c_rd_start,

    -- generic read interface
    channel_sel_in       => channel_sel_in,
    eeprom_map_sel_in    => eeprom_map_sel_in,
    eeprom_start_adr_in  => eeprom_start_adr_in,
    eeprom_num_regs_in   => eeprom_num_regs_in,
    eeprom_reg_out       => eeprom_reg_out,
    eeprom_reg_out_valid => eeprom_reg_out_valid,

    -- status signals
    sfp_enabled_ports => sfp_enabled_ports,
    sfp_sn_vec        => sfp_sn_vec,
    sfp_mod_abs       => sfp_mod_abs,
    sfp_tx_fault      => sfp_tx_fault,
    sfp_rx_los        => sfp_rx_los,

    change_mod_abs  => change_mod_abs,
    change_tx_fault => change_tx_fault,
    change_rx_los   => change_rx_los,

    fs_state  => fs_state,
    st_state  => st_state,
    ssc_state => ssc_state,
    sgr_state => sgr_state,

    -- warning signals
    change_error_mod_abs  => change_error_mod_abs,
    change_error_tx_fault => change_error_tx_fault,
    change_error_rx_los   => change_error_rx_los,
    
    -- error signals
    error_fmc_absent   => error_fmc_absent,
    error_fmc_mod_type => error_fmc_mod_type,
    error_fmc_int_n    => error_fmc_int_n,
    error_startup_i2c  => error_startup_i2c,

    sfp_en_error_mod_abs    => sfp_en_error_mod_abs,
    sfp_en_error_sfp_type   => sfp_en_error_sfp_type,
    sfp_en_error_tx_fault   => sfp_en_error_tx_fault,
    sfp_en_error_sfp_alarms => sfp_en_error_sfp_alarms,
    sfp_en_error_i2c_chip   => sfp_en_error_i2c_chip,

    -- SFP alarm flags
    sfp_alarm_temp_high     => sfp_alarm_temp_high,
    sfp_alarm_temp_low      => sfp_alarm_temp_low,
    sfp_alarm_vcc_high      => sfp_alarm_vcc_high,
    sfp_alarm_vcc_low       => sfp_alarm_vcc_low,
    sfp_alarm_tx_bias_high  => sfp_alarm_tx_bias_high,
    sfp_alarm_tx_bias_low   => sfp_alarm_tx_bias_low,
    sfp_alarm_tx_power_high => sfp_alarm_tx_power_high,
    sfp_alarm_tx_power_low  => sfp_alarm_tx_power_low,
    sfp_alarm_rx_power_high => sfp_alarm_rx_power_high,
    sfp_alarm_rx_power_low  => sfp_alarm_rx_power_low,
      
    -- SFP warning flags
    sfp_warning_temp_high     => sfp_warning_temp_high,
    sfp_warning_temp_low      => sfp_warning_temp_low,
    sfp_warning_vcc_high      => sfp_warning_vcc_high,
    sfp_warning_vcc_low       => sfp_warning_vcc_low,
    sfp_warning_tx_bias_high  => sfp_warning_tx_bias_high,
    sfp_warning_tx_bias_low   => sfp_warning_tx_bias_low,
    sfp_warning_tx_power_high => sfp_warning_tx_power_high,
    sfp_warning_tx_power_low  => sfp_warning_tx_power_low,
    sfp_warning_rx_power_high => sfp_warning_rx_power_high,
    sfp_warning_rx_power_low  => sfp_warning_rx_power_low,

    -- I2C signals
    i2c_int_n_i  => i2c_int_n_i,
    scl_pad_i    => scl_pad_i,    -- input from external pin
    scl_pad_o    => scl_pad_o,    -- output to tri-state driver
    scl_padoen_o => scl_padoen_o, -- enable signal for tri-state driver
    sda_pad_i    => sda_pad_i,    -- input from external pin
    sda_pad_o    => sda_pad_o,    -- output to tri-state driver
    sda_padoen_o => sda_padoen_o  -- enable signal for tri-state driver
  );

end Behavioral;
