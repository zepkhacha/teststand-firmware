library IEEE;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity asym_spram is
  generic (
    WIDTH     : integer;
    ADDRWIDTH : integer
    );
  port (clkA  : in  std_logic;
        weA   : in  std_logic;
        enA   : in  std_logic;
        addrA : in  std_logic_vector(ADDRWIDTH-1 downto 0);
        diA   : in  std_logic_vector(WIDTH-1 downto 0);
        doutA : out std_logic_vector(WIDTH-1 downto 0);
        clkB  : in  std_logic;
        enB   : in  std_logic;
        addrB : in  std_logic_vector(ADDRWIDTH-1 downto 0);
        doutB : out std_logic_vector(WIDTH-1 downto 0)
        );
end asym_spram;

architecture behavioural of asym_spram is
  
  type ram_type is array (0 to 2**ADDRWIDTH-1) of std_logic_vector (WIDTH-1 downto 0);
  signal ram : ram_type := (others => (others => '0'));
  
begin
  process (clkA)
  begin
    if rising_edge(clkA) then
      doutA <= (others => '0');
      if enA = '1' then
        if weA = '1' then
          ram(conv_integer(addrA)) <= diA;
        else
          doutA <= ram(conv_integer(addrA));
        end if;
      end if;
    end if;
  end process;

  process (clkB)
  begin
    if rising_edge(clkB) then
      if enB = '1' then
        doutB <= ram(conv_integer(addrB));
      end if;
    end if;
  end process;
  
  
end behavioural;
