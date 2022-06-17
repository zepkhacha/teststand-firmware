-- IPbus slave module for FC7 trigger registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.ipbus.all;
use work.system_package.all;

entity ipb_user_t9_trigger_regs is
port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    run_in_progress    : in  std_logic;
    ipbus_in           : in  ipb_wbus;
    ipbus_out          : out ipb_rbus;
    regs_t9_delay      : out array_4_2_8x32bit;
    reg_t9_ctrl        : out array_8x32bit
);
end ipb_user_t9_trigger_regs;

architecture rtl of ipb_user_t9_trigger_regs is
    
    -- register buffers
    signal regs_t9_delay_buf : array_4_2_8x32bit;
    signal reg_t9_ctrl_buf   : array_8x32bit;

    signal iChannel      : integer range 0 to 3; -- 0 is for charging cap, 1 - 3 for charging K1 - K3 blumleins
    signal iSeq08        : integer range 0 to 7;
    signal iSecondCycle  : integer range 0 to 1;
    signal ctrlAddr      : integer range 0 to 7;
    signal ctrlBufAccess : std_logic;

    signal ack, err : std_logic;
    signal buf_dat  : std_logic_vector(31 downto 0);
    signal buf_ack  : std_logic;
    signal buf_err  : std_logic;

begin

    -- I/O mapping
    regs_t9_delay  <= regs_t9_delay_buf;
    reg_t9_ctrl    <= reg_t9_ctrl_buf;
 
    -- addressing if we are accessing the control buffer for the kicker pulses
    ctrlBufAccess <= ipbus_in.ipb_addr(16);
    ctrlAddr      <= to_integer(unsigned(ipbus_in.ipb_addr(2 downto 0)));

    -- addressing if we are accessing the delays themselves
    iChannel     <= to_integer(unsigned(ipbus_in.ipb_addr(5 downto 4))); -- channel
    iSecondCycle <= 0 when ipbus_in.ipb_addr(3) = '0' else 1;
    iSeq08       <= to_integer(unsigned(ipbus_in.ipb_addr(2 downto 0)));
        
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- default values
--                for m in 0 to 11 loop
                for kChannel in 0 to 3 loop
                    for kCycle in 0 to 1 loop
                        for kSeq in 0 to 7 loop
                            regs_t9_delay_buf(kChannel)(kCycle)(kSeq) <= x"00000000";
                        end loop;
                    end loop;
                end loop;
                reg_t9_ctrl_buf(0) <= x"00000001";
                reg_t9_ctrl_buf(1) <= x"00000002";
                for kCtrl in 2 to 7 loop
                    reg_t9_ctrl_buf(kCtrl) <= x"00000000"; -- probably want better defaults than this; later...
                end loop;
            elsif ipbus_in.ipb_strobe = '1' and ipbus_in.ipb_write = '1' then
                if run_in_progress = '0' then

                    -- setting kicker control buffer
                    if ctrlBufAccess = '1' then
                        reg_t9_ctrl_buf(ctrlAddr) <= ipbus_in.ipb_wdata;
                    -- setting kicker delay parameters
                    else
                        regs_t9_delay_buf(iChannel)(iSecondCycle)(iSeq08) <= ipbus_in.ipb_wdata;
                    end if; 
                end if;
            end if;
            
            if ctrlBufAccess = '1' then
                buf_dat <= reg_t9_ctrl_buf(ctrlAddr);
            else 
                buf_dat <= regs_t9_delay_buf(iChannel)(iSecondCycle)(iSeq08);
            end if;


            ipbus_out.ipb_rdata <= buf_dat;
            buf_ack <= ipbus_in.ipb_strobe and not ack;
            ack <= buf_ack;

            if ipbus_in.ipb_strobe = '1' and buf_err = '0' and ipbus_in.ipb_write = '1' and run_in_progress = '1' then
                buf_err <= '1';
            else 
                buf_err <= '0';
            end if;
            err <= buf_err;
        end if;
    end process;
    
    ipbus_out.ipb_ack <= ack;
    ipbus_out.ipb_err <= err;

end rtl;