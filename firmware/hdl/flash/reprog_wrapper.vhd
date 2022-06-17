-- Wrapper to instantiate reprog.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity reprog_wrapper is
port (
  clk     : in std_logic;
  reset   : in std_logic;
  trigger : in std_logic
);
end reprog_wrapper;

architecture Behavioral of reprog_wrapper is

  component reprog is 
  port (
    clk     : in std_logic;
    reset   : in std_logic;
    trigger : in std_logic
  );
  end component;

begin

  rep: reprog
  port map (
    clk     => clk,
    reset   => reset,
    trigger => trigger
  );

end Behavioral;
