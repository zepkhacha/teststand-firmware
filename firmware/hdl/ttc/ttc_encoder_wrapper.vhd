-- Wrapper to instantiate ttc_encoder.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ttc_encoder_wrapper is
port (
  -- clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- input data
    a_channel      : in std_logic;
    ttc_data       : in std_logic_vector(15 downto 0);
    ttc_data_valid : in std_logic;

    -- output bit
    ttc_bit_out : out std_logic
);
end ttc_encoder_wrapper;

architecture Behavioral of ttc_encoder_wrapper is

  component ttc_encoder is 
  port (
    -- clock and reset
    clk : in std_logic;
    rst : in std_logic;

    -- input data
    a_channel      : in std_logic;
    ttc_data       : in std_logic_vector(15 downto 0);
    ttc_data_valid : in std_logic;
    
    -- output bit
    ttc_bit_out : out std_logic
  );
  end component;

begin

  encoder: ttc_encoder
  port map (
    -- clock and reset
    clk => clk,
    rst => rst,

    -- input data
    a_channel      => a_channel,
    ttc_data       => ttc_data,
    ttc_data_valid => ttc_data_valid,

    -- output bit
    ttc_bit_out => ttc_bit_out
  );

end Behavioral;
