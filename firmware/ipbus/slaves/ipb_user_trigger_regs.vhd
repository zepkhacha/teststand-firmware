-- IPbus slave module for FC7 A6-based trigger registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.ipbus.all;
use work.system_package.all;

entity ipb_user_trigger_regs is
port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    run_in_progress    : in  std_logic;
    ipbus_in           : in  ipb_wbus;
    ipbus_out          : out ipb_rbus;
    regs_delay_fast    : out fast_delay_reg_t;
    regs_width_fast    : out fast_width_reg_t;
    regs_delay_slow    : out slow_delay_reg_t;
    regs_width_slow    : out slow_width_reg_t;
    pulse_enabled_fast : out fast_enabled_reg_t;
    pulse_enabled_slow : out slow_enabled_reg_t
);
end ipb_user_trigger_regs;
--    regs_o_delay       : out array_12_4_16x24bit;
--    regs_o_width       : out array_12_4_16x8bit;

architecture rtl of ipb_user_trigger_regs is
    
--   signal regs_delay : array_12_4_16x24bit;
--   signal regs_width : array_12_4_16x8bit;
    -- register buffers
    signal regs_delay_fast_buf  : fast_delay_reg_t;
    signal regs_width_fast_buf  : fast_width_reg_t;
    signal regs_delay_slow_buf  : slow_delay_reg_t;
    signal regs_width_slow_buf  : slow_width_reg_t;

    signal pulse_enabled_fast_buf : fast_enabled_reg_t;
    signal pulse_enabled_slow_buf : slow_enabled_reg_t;

    signal iChannel : integer range 0 to 13;
--    signal iSeq16   : integer range 0 to 15;
    signal iSeq08   : integer range 0 to 7;
    signal k        : integer range 0 to 1;
    signal iPulse   : integer range 0 to 3;
    signal iLoop    : integer range 0 to 3;
    signal iSecondCycle : integer range 0 to 1;
    signal ack, err : std_logic;
    signal buf_dat  : std_logic_vector(31 downto 0);
    signal buf_ack  : std_logic;
    signal buf_err  : std_logic;

    signal dCountLow:  std_logic_vector(6 downto 0);
    signal dCountMid1: std_logic_vector(6 downto 0);
    signal dCountMid2: std_logic_vector(6 downto 0);
    signal dCountHigh: std_logic_vector(6 downto 0);

    signal wCountLow:  std_logic_vector(4 downto 0);
    signal wCountHigh: std_logic_vector(4 downto 0);

    attribute keep      : boolean;
    attribute keep of iChannel : signal is true;
    attribute keep of iSeq08 : signal is true;
    attribute keep of k      : signal is true;
    attribute keep of iPulse : signal is true;
    attribute keep of iLoop  : signal is true;
    attribute keep of iSecondCycle : signal is true;

    -- debugs
--    attribute mark_debug : string;
--    attribute mark_debug of iChannel : signal is "true";
--    attribute mark_debug of iSeq08 : signal is "true";
--    attribute mark_debug of k : signal is "true";
--    attribute mark_debug of iPulse : signal is "true";
--    attribute mark_debug of iLoop  : signal is "true";
--    attribute mark_debug of iSecondCycle : signal is "true";
--    attribute mark_debug of regs_delay_slow_buf : signal is "true";
--    attribute mark_debug of regs_width_slow_buf : signal is "true";
--    attribute mark_debug of pulse_enabled_slow_buf : signal is "true";
--    attribute mark_debug of dCountLow  : signal is "true";
--    attribute mark_debug of dCountMid1 : signal is "true";
--    attribute mark_debug of dCountMid2 : signal is "true";
--    attribute mark_debug of dCountHigh : signal is "true";
--    attribute mark_debug of wCountLow  : signal is "true";
--    attribute mark_debug of wCountHigh : signal is "true";
--    attribute mark_debug of ipbus_in : signal is "true";
--    attribute mark_debug of ipbus_out : signal is "true";


begin

    -- I/O mapping
--    regs_o_delay <= regs_delay;
--    regs_o_width <= regs_width;
    regs_delay_fast    <= regs_delay_fast_buf;
    regs_width_fast    <= regs_width_fast_buf;
    regs_delay_slow    <= regs_delay_slow_buf;
    regs_width_slow    <= regs_width_slow_buf;
    pulse_enabled_fast <= pulse_enabled_fast_buf;
    pulse_enabled_slow <= pulse_enabled_slow_buf;
 
    k            <= 0 when ipbus_in.ipb_addr(16) = '0' else 1;            -- delay/width
    iChannel     <= to_integer(unsigned(ipbus_in.ipb_addr(11 downto  8))); -- channel
    iSecondCycle <= 0 when ipbus_in.ipb_addr(7) = '0' else 1;
    iSeq08       <= to_integer(unsigned(ipbus_in.ipb_addr( 6 downto  4)));
    iLoop        <= to_integer(unsigned(ipbus_in.ipb_addr( 3 downto  2))); -- sub-loop (4 for delay, 2 for width)
    iPulse       <= to_integer(unsigned(ipbus_in.ipb_addr( 1 downto  0))); -- pulse
    
    -- implement shifting at time of register setting
    -- pulse_delay_parameters(0)(iChannel)(kSequence)(subcd)(pulse)

    process(clk)
    begin
        if rising_edge(clk) then
            -- loops for the counters all stop at a value of -1, so that only the most significant bit transitioning to '1' need be monitored.
            -- this means that a value of zero for the delay or width corresponds to having all the counters initialized to "-1".  The signed
            -- arithmetic below will take care of conversion between these "-1"'s and zero
            if reset = '1' then
                -- default values
--                for m in 0 to 11 loop
                for p in 0 to 7 loop
                    for q in 0 to 1 loop
                        for n in 0 to 3 loop
                            for r in 0 to 3 loop
                                for m in 0 to 6 loop
                                    regs_delay_fast_buf(q)(m)(p)(r)(n) <= "1111111";
                                end loop;
--                                for m in 7 to 9 loop
--                                for m in 7 to 11 loop
                                for m in 7 to 13 loop
                                    regs_delay_slow_buf(q)(m)(p)(r)(n) <= "1111111";
                                end loop;
                            end loop;
                            for r in 0 to 1 loop
                                for m in 0 to 6 loop
                                    regs_width_fast_buf(q)(m)(p)(r)(n) <= "11111";
                                end loop;
--                                for m in 7 to 9 loop
--                                for m in 7 to 11 loop
                                for m in 7 to 13 loop
                                    regs_width_slow_buf(q)(m)(p)(r)(n) <= "11111";
                                end loop;
                            end loop;
                        end loop;
                    end loop;
                end loop;
                for p in 0 to 7 loop
                    for q in 0 to 1 loop
                        for n in 0 to 3 loop
                            for m in 0 to 6 loop
                                pulse_enabled_fast_buf(q)(m)(p)(n) <= '0';
                            end loop;
--                            for m in 7 to 9 loop
--                            for m in 7 to 11 loop
                            for m in 7 to 13 loop
                                pulse_enabled_slow_buf(q)(m)(p)(n) <= '0';
                            end loop;
                        end loop;
                    end loop;
                end loop;

            elsif ipbus_in.ipb_strobe = '1' and ipbus_in.ipb_write = '1' then
                if run_in_progress = '0' then
                    if ipbus_in.ipb_addr(16) = '0' then
                        if ( iChannel < 7 ) then
                            regs_delay_fast_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse) <= std_logic_vector(to_signed(to_integer(signed('0' & ipbus_in.ipb_wdata( 5 downto  0))) - 1,7));
                        else
                            regs_delay_slow_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse) <= std_logic_vector(to_signed(to_integer(signed('0' & ipbus_in.ipb_wdata( 5 downto  0))) - 1,7));
                        end if;
                    elsif iLoop = 2 then
                        if ( iChannel < 7 ) then
                            pulse_enabled_fast_buf(iSecondCycle)(iChannel)(iSeq08)(iPulse) <= ipbus_in.ipb_wdata(0);
                        else
                            pulse_enabled_slow_buf(iSecondCycle)(iChannel)(iSeq08)(iPulse) <= ipbus_in.ipb_wdata(0);
                        end if;
                    else
                        if ( iChannel < 7 ) then
                            regs_width_fast_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse) <= std_logic_vector(to_signed(to_integer(signed('0' & ipbus_in.ipb_wdata( 3 downto  0))) - 1,5));
                        else
                            regs_width_slow_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse) <= std_logic_vector(to_signed(to_integer(signed('0' & ipbus_in.ipb_wdata( 3 downto  0))) - 1,5));
                        end if;
                    end if; 
                end if;
            end if;
            
            if ( ipbus_in.ipb_addr(16) = '0' ) then
                if ( iChannel < 7 ) then
                    buf_dat( 6 downto  0) <= std_logic_vector(to_signed(to_integer(signed(regs_delay_fast_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse))) + 1,7));
                    buf_dat(31 downto  7) <= (others => '0');
                else
                    buf_dat( 6 downto  0) <= std_logic_vector(to_signed(to_integer(signed(regs_delay_slow_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse))) + 1,7));
                    buf_dat(31 downto  7) <= (others => '0');
                end if;
            elsif iLoop = 2 then
                if ( iChannel < 7 ) then
                    buf_dat(0) <= pulse_enabled_fast_buf(iSecondCycle)(iChannel)(iSeq08)(iPulse);
                    buf_dat(31 downto  1) <= (others => '0');
                else
                    buf_dat(0) <= pulse_enabled_slow_buf(iSecondCycle)(iChannel)(iSeq08)(iPulse);
                    buf_dat(31 downto  1) <= (others => '0');
                end if;
            else
                if ( iChannel < 7 ) then
                    buf_dat( 4 downto  0) <= std_logic_vector(to_signed(to_integer(signed(regs_width_fast_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse))) + 1,5));
                    buf_dat(31 downto 5) <= (others => '0');
                else
                    buf_dat( 4 downto  0) <= std_logic_vector(to_signed(to_integer(signed(regs_width_slow_buf(iSecondCycle)(iChannel)(iSeq08)(iLoop)(iPulse))) + 1,5));
                    buf_dat(31 downto 5) <= (others => '0');
                end if;
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
