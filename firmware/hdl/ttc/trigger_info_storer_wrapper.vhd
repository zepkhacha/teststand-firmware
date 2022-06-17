-- Wrapper to instantiate trigger_info_storer.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- system packages
use work.system_package.all;

entity trigger_info_storer_wrapper is
port (
  -- clock and reset
  clk : in std_logic;
  rst : in std_logic;

  -- TTC information
  trigger           : in std_logic;
  broadcast         : in std_logic_vector(5 downto 0);
  broadcast_valid   : in std_logic;
  event_count_reset : in std_logic;

  -- FIFO interface
  fifo_ready : in  std_logic;
  fifo_data  : out std_logic_vector(127 downto 0);
  fifo_valid : out std_logic;

  -- trigger interface
  trig_timestamp : out std_logic_vector(43 downto 0);
  trig_num       : out std_logic_vector(23 downto 0);
  trig_type_num  : out array_32x24bit;
  trig_type      : out std_logic_vector( 4 downto 0);

  -- status
  state : out std_logic_vector(1 downto 0)
);
end trigger_info_storer_wrapper;

architecture Behavioral of trigger_info_storer_wrapper is

  component trigger_info_storer is 
  port (
    -- clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- TTC information
    trigger           : in std_logic;
    broadcast         : in std_logic_vector(5 downto 0);
    broadcast_valid   : in std_logic;
    event_count_reset : in std_logic;

    -- FIFO interface
    fifo_ready : in  std_logic;
    fifo_data  : out std_logic_vector(127 downto 0);
    fifo_valid : out std_logic;

    -- trigger interface
    trig_timestamp    : out std_logic_vector( 43 downto 0);
    trig_num          : out std_logic_vector( 23 downto 0);
    trig_type_num_vec : out std_logic_vector(767 downto 0);
    trig_type         : out std_logic_vector(  4 downto 0);

    -- status
    state : out std_logic_vector(1 downto 0)
  );
  end component;

  -- trigger type numbers
  signal trig_type_num_vec : std_logic_vector(767 downto 0);

begin

  -- fill in trigger type number matrix
  trig_num_gen: for i in 0 to 31 generate
  begin
    trig_type_num(i) <= trig_type_num_vec((24*i + 23) downto (24*i));
  end generate;

  storer: trigger_info_storer
  port map (
    -- clock and reset
    clk => clk,
    rst => rst,

    -- TTC information
    trigger           => trigger,
    broadcast         => broadcast,
    broadcast_valid   => broadcast_valid,
    event_count_reset => event_count_reset,

    -- FIFO interface
    fifo_ready => fifo_ready,
    fifo_data  => fifo_data,
    fifo_valid => fifo_valid,

    -- trigger interface
    trig_timestamp    => trig_timestamp,
    trig_num          => trig_num,
    trig_type_num_vec => trig_type_num_vec,
    trig_type         => trig_type,

    -- status
    state => state
  );

end Behavioral;
