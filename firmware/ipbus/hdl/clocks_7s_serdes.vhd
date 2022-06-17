-- clocks_7s_serdes
--
-- Input is a free-running 125-MHz clock (taken straight from MGT clock buffer)
--
-- Dave Newbold, April 2011 (edited by Paschalis Vichoudis, September 2014)

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

entity clocks_7s_serdes is
generic (
    powerup_delay : integer := 3125000 -- in 31.25-MHz ticks
);
port (
    clki_fr    : in  std_logic; -- input free-running clock (125 MHz)
    clki_125   : in  std_logic; -- ethernet domain clk125
    nuke       : in  std_logic; -- hard reset input
    eth_locked : in  std_logic; -- ethernet locked signal
    clko_ipb   : out std_logic; -- ipbus domain clock (31.25 MHz)
    locked     : out std_logic; -- global locked signal
    rsto_125   : out std_logic; -- clk125 domain reset (held until ethernet locked)
    rsto_ipb   : out std_logic; -- ipbus domain reset
    rsto_eth   : out std_logic; -- ethernet startup reset (required!)
    rsto       : out std_logic
);
end clocks_7s_serdes;

architecture rtl of clocks_7s_serdes is

    signal dcm_locked, sysclk, clk_ipb    : std_logic;
    signal nuke_i                         : std_logic := '0';
    signal rst, rst_ipb, rst_125, rst_eth : std_logic := '1';
    signal rst_async, rst_dbl             : std_logic; 

    attribute keep : boolean;
    attribute keep of rst     : signal is true;
    attribute keep of nuke_i  : signal is true;
    attribute keep of rst_ipb : signal is true;
    attribute keep of rst_eth : signal is true;

begin

-- -----
-- clock
-- -----

-- input mapping
sysclk <= clki_fr;

-- pll
syspll_inst: entity work.syspll
port map (
    clk_in1  => sysclk,  -- 125.00 MHz
    clk_out1 => clk_ipb, --  31.25 MHz
    locked   => dcm_locked,
    reset    => '0'
);

-- output mapping 
clko_ipb <= clk_ipb;
locked   <= dcm_locked;

-- sync inputs 
process(clk_ipb)
begin
    if rising_edge(clk_ipb) then
        nuke_i <= nuke;
    end if;
end process;

-- global async reset 
rst_async <= (not dcm_locked) or nuke_i;

-- master reset process
process(clk_ipb, rst_async)
    variable timer : integer;
begin
    if rst_async = '1' then
        rst_dbl <= '1';
        rst     <= '1';
        timer   := powerup_delay;
    elsif rising_edge(clk_ipb) then
        rst_dbl <= '0';
        if        timer = 0  then rst     <= '0';
        else
            if    timer = 12 then rst_dbl <= '1';
            elsif timer = 13 then rst_dbl <= '1';
            elsif timer = 14 then rst_dbl <= '1';
            elsif timer = 15 then rst_dbl <= '1';
            end if;
            timer := timer-1; rst <= '1';
        end if;
    end if;
end process;

-- sync outputs 
process(clki_125) begin if rising_edge(clki_125) then rst_125 <= rst or (not eth_locked); end if; end process;
process(sysclk)   begin if rising_edge(sysclk)   then rst_eth <= rst_dbl;                 end if; end process;
process(clk_ipb)  begin if rising_edge(clk_ipb)  then rst_ipb <= rst;                     end if; end process;

-- output mapping
rsto_ipb <= rst_ipb;
rsto_eth <= rst_eth;
rsto_125 <= rst_125;
rsto     <= rst;

end rtl;
