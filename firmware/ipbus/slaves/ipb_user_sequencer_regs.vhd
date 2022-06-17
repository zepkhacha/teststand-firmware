-- IPbus slave module for FC7 sequencer registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.ipbus.all;
use work.system_package.all;

entity ipb_user_sequencer_regs is
generic (
    addr_width  : natural :=  4;
    seq_addr_lo : natural :=  8;
    seq_addr_hi : natural := 11
);
port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    run_in_progress : in  std_logic;
    ipbus_in        : in  ipb_wbus;
    ipbus_out       : out ipb_rbus;
    regs_o          : out array_16x32x32bit
);
end ipb_user_sequencer_regs;

architecture rtl of ipb_user_sequencer_regs is
    
    signal regs : array_16x32x32bit;
    signal sel  : integer range 0 to 31;
    signal seq  : integer range 0 to 31;
    signal ack  : std_logic;
    signal err  : std_logic;

    attribute keep : boolean;
    attribute keep of sel : signal is true;
    attribute keep of seq : signal is true;

begin

    -- I/O mapping
    regs_o <= regs;

    seq <= to_integer(unsigned(ipbus_in.ipb_addr(seq_addr_hi downto seq_addr_lo))) when addr_width > 0 else 0;
    sel <= to_integer(unsigned(ipbus_in.ipb_addr(addr_width  downto           0))) when addr_width > 0 else 0;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                for i in 0 to 15 loop
                    for j in 0 to 31 loop
                        regs(i,j) <= (others => '0');
                    end loop;

                    -- overwrite with default values
                    regs(i,1) <= x"0000001"; -- muon trigger type 0
                end loop;
            elsif ipbus_in.ipb_strobe = '1' and ipbus_in.ipb_write = '1' then
                if run_in_progress = '0' then
                    regs(seq,sel) <= ipbus_in.ipb_wdata;
                end if;
            end if;

            ipbus_out.ipb_rdata <= regs(seq,sel);
            ack <= ipbus_in.ipb_strobe and not ack;

            if ipbus_in.ipb_strobe = '1' and err = '0' and ipbus_in.ipb_write = '1' and run_in_progress = '1' then
                err <= '1';
            else 
                err <= '0';
            end if;
        end if;
    end process;
    
    ipbus_out.ipb_ack <= ack;
    ipbus_out.ipb_err <= err;

end rtl;
