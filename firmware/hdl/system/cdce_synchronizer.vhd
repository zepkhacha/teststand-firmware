-- Company : CERN (PH-ESE-BE)
-- Engineer: Paschalis Vichoudis (paschalis.vichoudis@cern.ch)
--           Manoel Barros Marin (manoel.barros.marin@cern.ch) (m.barros@ieee.org)
-- Date    : 20/10/2011

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity cdce_synchronizer is
generic (   
    pwrdown_delay : natural := 1000;
    sync_delay    : natural := 1000000    
);  
port (
    reset_i         : in  std_logic;
    ipbus_ctrl_i    : in  std_logic:='1'; -- ipb controlled 
    ipbus_sel_i     : in  std_logic:='0'; -- select secondary clock
    ipbus_pwrdown_i : in  std_logic:='1'; -- power up
    ipbus_sync_i    : in  std_logic:='1'; -- disable sync mode, rising edge needed to resync
    user_sel_i      : in  std_logic:='1'; -- select primary clock [effective only when ipbus_ctrl_i ='1'] 
    user_sync_i     : in  std_logic:='1'; -- power up             [effective only when ipbus_ctrl_i ='1'] 
    user_pwrdown_i  : in  std_logic:='1'; -- disable sync mode    [effective only when ipbus_ctrl_i ='1'] 
    pri_clk_i       : in  std_logic;
    sec_clk_i       : in  std_logic;
    pwrdown_o       : out std_logic;
    sync_o          : out std_logic;
    ref_sel_o       : out std_logic;
    sync_clk_o      : out std_logic;
    sync_cmd_o      : out std_logic;
    sync_busy_o     : out std_logic;
    sync_done_o     : out std_logic
);
end cdce_synchronizer;

architecture structural of cdce_synchronizer is 

    signal clk_from_bufg_mux    : std_logic;    
    signal reset                : std_logic;
    signal sel                  : std_logic;
    signal pwrdown, fsm_pwrdown : std_logic;
    signal fsm_sync             : std_logic;
    signal sync_cmd             : std_logic;
    signal reset_dpr            : std_logic;
    signal pwrdown_dpr          : std_logic;

begin       

    reset <= '1' when reset_i  = '1' else
             '1' when sync_cmd = '1' else '0';
    
    sync_cmd <= '1' when (ipbus_ctrl_i = '1' and ipbus_sync_i = '0') else
                '1' when (ipbus_ctrl_i = '0' and user_sync_i  = '0') else '0';
    
    sel <= '0' when (ipbus_ctrl_i = '1' and ipbus_sel_i = '1') else
           '1' when (ipbus_ctrl_i = '1' and ipbus_sel_i = '0') else
           '0' when (ipbus_ctrl_i = '0' and user_sel_i  = '1') else
           '1' when (ipbus_ctrl_i = '0' and user_sel_i  = '0') else '0';
    
    pwrdown <= '0' when (ipbus_ctrl_i = '1' and ipbus_pwrdown_i = '0') else
               '1' when (ipbus_ctrl_i = '1' and ipbus_pwrdown_i = '1') else
               '0' when (ipbus_ctrl_i = '0' and user_pwrdown_i  = '0') else
               '1' when (ipbus_ctrl_i = '0' and user_pwrdown_i  = '1') else '1';
    

    ref_sel_o  <= not sel;
    sync_cmd_o <= sync_cmd;
    pwrdown_o  <= pwrdown and fsm_pwrdown;
    

    sync_inv: process(reset, clk_from_bufg_mux)
    begin
        if reset = '1' then 
            sync_o <= '1';
        elsif rising_edge(clk_from_bufg_mux) then
            sync_o <= fsm_sync;
        end if;
    end process;

    
    cdce_control: process(reset, clk_from_bufg_mux)
        variable state : std_logic_vector(1 downto 0); 
        variable timer : natural range 0 to sync_delay;            
    begin
        if reset = '1' then
            timer       := pwrdown_delay;
            state       := "00";
            fsm_pwrdown <= '1';
            fsm_sync    <= '1';
            sync_done_o <= '0';
            sync_busy_o <= '0';
            
        elsif rising_edge(clk_from_bufg_mux) then
            case state is
                when "00" =>    
                    fsm_pwrdown <= '0'; -- assert pwr_down
                    fsm_sync    <= '0'; -- assert sync
                    sync_busy_o <= '1';
                    sync_done_o <= '0';
                    if timer = 0 then 
                        state := "01"; 
                        timer := sync_delay; 
                    else 
                        timer := timer-1; 
                    end if;
                
                when "01" =>
                    fsm_pwrdown <= '1'; -- deassert pwr_down
                    fsm_sync    <= '0'; -- assert sync
                    if timer = 0 then 
                        state := "10"; 
                    else 
                        timer := timer-1; 
                    end if; 
                
                when "10" =>
                    fsm_pwrdown <= '1'; -- deassert pwr_down
                    fsm_sync    <= '1'; -- deassert sync                    
                    state := "11";

                when "11" =>
                    sync_busy_o <= '0';
                    sync_done_o <= '1';             

                when others =>
                
            end case;       
        end if;
    end process;        

sync_clk_o <= clk_from_bufg_mux;
bufg_mux: bufgmux port map (o => clk_from_bufg_mux, i0 => pri_clk_i, i1 => sec_clk_i, s => sel);

end structural;
