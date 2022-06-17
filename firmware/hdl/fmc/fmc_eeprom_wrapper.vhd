-- Wrapper to instantiate fmc_eeprom.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity fmc_eeprom_wrapper is
port (
  -- clock and reset
  clk : in std_logic;
  rst : in std_logic;

  -- status
  l12_dev_active : in  std_logic;
  l08_dev_active : in  std_logic;
  l12_dev_ext    : in  std_logic;
  l08_dev_ext    : in  std_logic;
  fmcs_ready     : in  std_logic;
  error_i2c      : out std_logic;
  error_id       : out std_logic;
  CS             : out std_logic_vector(11 downto 0);

  -- write interface
  l12_fmc_id_request : in std_logic_vector(7 downto 0);
  l08_fmc_id_request : in std_logic_vector(7 downto 0);
  write_start        : in std_logic;

  -- read interface
  l12_fmc_id    : out std_logic_vector(7 downto 0);
  l08_fmc_id    : out std_logic_vector(7 downto 0);
  fmc_ids_valid : out std_logic;

  -- I2C signals
  scl_pad_i    : in  std_logic;
  scl_pad_o    : out std_logic;
  scl_padoen_o : out std_logic;
  sda_pad_i    : in  std_logic;
  sda_pad_o    : out std_logic;
  sda_padoen_o : out std_logic
);
end fmc_eeprom_wrapper;

architecture Behavioral of fmc_eeprom_wrapper is

  component fmc_eeprom is 
  port (
    -- clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- status
    l12_dev_active : in  std_logic;
    l08_dev_active : in  std_logic;
    l12_dev_ext : in  std_logic;
    l08_dev_ext : in  std_logic;
    fmcs_ready  : in  std_logic;
    error_i2c   : out std_logic;
    error_id    : out std_logic;
    CS          : out std_logic_vector(11 downto 0);

    -- write interface
    l12_fmc_id_request : in std_logic_vector(7 downto 0);
    l08_fmc_id_request : in std_logic_vector(7 downto 0);
    write_start        : in std_logic;

    -- read interface
    l12_fmc_id    : out std_logic_vector(7 downto 0);
    l08_fmc_id    : out std_logic_vector(7 downto 0);
    fmc_ids_valid : out std_logic;

    -- I2C signals
    scl_pad_i    : in  std_logic;
    scl_pad_o    : out std_logic;
    scl_padoen_o : out std_logic;
    sda_pad_i    : in  std_logic;
    sda_pad_o    : out std_logic;
    sda_padoen_o : out std_logic
  );
  end component;

begin

  fmc_eeprom_inst: fmc_eeprom
  port map (
    -- clock and reset
    clk => clk,
    rst => rst,

    -- status
    l12_dev_active => l12_dev_active,
    l08_dev_active => l08_dev_active,
    l12_dev_ext    => l12_dev_ext,
    l08_dev_ext    => l08_dev_ext,
    fmcs_ready     => fmcs_ready,
    error_i2c      => error_i2c,
    error_id       => error_id,
    CS             => CS,

    -- write interface
    l12_fmc_id_request => l12_fmc_id_request,
    l08_fmc_id_request => l08_fmc_id_request,
    write_start        => write_start,

    -- read interface
    l12_fmc_id    => l12_fmc_id,
    l08_fmc_id    => l08_fmc_id,
    fmc_ids_valid => fmc_ids_valid,

    -- I2C signals
    scl_pad_i    => scl_pad_i,
    scl_pad_o    => scl_pad_o,
    scl_padoen_o => scl_padoen_o,
    sda_pad_i    => sda_pad_i,
    sda_pad_o    => sda_pad_o,
    sda_padoen_o => sda_padoen_o
  );

end Behavioral;
