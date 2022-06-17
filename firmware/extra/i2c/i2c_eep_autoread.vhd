library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- user packages
use work.system_package.all;

entity i2c_eep_autoread is
port (
    reset         : in  std_logic;
    clk           : in  std_logic;
    bypass_i      : in  std_logic;
    settings_i    : in  std_logic_vector(23 downto 0);
    settings_o    : out std_logic_vector(23 downto 0);
    command_i     : in  std_logic_vector(31 downto 0);
    command_o     : out std_logic_vector(31 downto 0);
    reply_i       : in  std_logic_vector(31 downto 0);
    reply_o       : out std_logic_vector(31 downto 0);
    done_i        : in  std_logic;
    done_o        : out std_logic;
    mac_ip_regs_o : out array_16x8bit;
    eui48_regs_o  : out array_6x8bit
);
end i2c_eep_autoread;

architecture rtl of i2c_eep_autoread is

    constant lastaddr : integer := 43;

    signal player_enable : std_logic;
    signal player_txdata : array_64x32bit;
    signal player_rxdata : array_64x8bit;

    signal settings : std_logic_vector(23 downto 0);
    signal command  : std_logic_vector(31 downto 0);
    signal strobe   : std_logic;
    signal txdata   : std_logic_vector(31 downto 0); -- captured data

begin
    player_txdata( 0) <= x"80d00000"; -- slave 0x50 wr 0x00
    player_txdata( 1) <= x"80500000"; -- slave 0x50 rd
    player_txdata( 2) <= x"80d00001"; -- slave 0x50 wr 0x01
    player_txdata( 3) <= x"80500000"; -- slave 0x50 rd
    player_txdata( 4) <= x"80d00002"; -- slave 0x50 wr 0x02
    player_txdata( 5) <= x"80500000"; -- slave 0x50 rd
    player_txdata( 6) <= x"80d00003"; -- slave 0x50 wr 0x03
    player_txdata( 7) <= x"80500000"; -- slave 0x50 rd
    player_txdata( 8) <= x"80d00004"; -- slave 0x50 wr 0x04
    player_txdata( 9) <= x"80500000"; -- slave 0x50 rd
    player_txdata(10) <= x"80d00005"; -- slave 0x50 wr 0x05
    player_txdata(11) <= x"80500000"; -- slave 0x50 rd
    player_txdata(12) <= x"80d00006"; -- slave 0x50 wr 0x06
    player_txdata(13) <= x"80500000"; -- slave 0x50 rd
    player_txdata(14) <= x"80d00007"; -- slave 0x50 wr 0x07
    player_txdata(15) <= x"80500000"; -- slave 0x50 rd
    player_txdata(16) <= x"80d00008"; -- slave 0x50 wr 0x08
    player_txdata(17) <= x"80500000"; -- slave 0x50 rd
    player_txdata(18) <= x"80d00009"; -- slave 0x50 wr 0x09
    player_txdata(19) <= x"80500000"; -- slave 0x50 rd
    player_txdata(20) <= x"80d0000a"; -- slave 0x50 wr 0x0a
    player_txdata(21) <= x"80500000"; -- slave 0x50 rd
    player_txdata(22) <= x"80d0000b"; -- slave 0x50 wr 0x0b
    player_txdata(23) <= x"80500000"; -- slave 0x50 rd
    player_txdata(24) <= x"80d0000c"; -- slave 0x50 wr 0x0c
    player_txdata(25) <= x"80500000"; -- slave 0x50 rd
    player_txdata(26) <= x"80d0000d"; -- slave 0x50 wr 0x0d
    player_txdata(27) <= x"80500000"; -- slave 0x50 rd
    player_txdata(28) <= x"80d0000e"; -- slave 0x50 wr 0x0e
    player_txdata(29) <= x"80500000"; -- slave 0x50 rd
    player_txdata(30) <= x"80d0000f"; -- slave 0x50 wr 0x0f
    player_txdata(31) <= x"80500000"; -- slave 0x50 rd
    player_txdata(32) <= x"80d000fa"; -- slave 0x50 wr 0xfa
    player_txdata(33) <= x"80500000"; -- slave 0x50 rd
    player_txdata(34) <= x"80d000fb"; -- slave 0x50 wr 0xfb
    player_txdata(35) <= x"80500000"; -- slave 0x50 rd
    player_txdata(36) <= x"80d000fc"; -- slave 0x50 wr 0xfc
    player_txdata(37) <= x"80500000"; -- slave 0x50 rd
    player_txdata(38) <= x"80d000fd"; -- slave 0x50 wr 0xfd
    player_txdata(39) <= x"80500000"; -- slave 0x50 rd
    player_txdata(40) <= x"80d000fe"; -- slave 0x50 wr 0xfe
    player_txdata(41) <= x"80500000"; -- slave 0x50 rd
    player_txdata(42) <= x"80d000ff"; -- slave 0x50 wr 0xff
    player_txdata(43) <= x"80500000"; -- slave 0x50 rd
    player_txdata(44) <= x"00000000"; -- null
    player_txdata(45) <= x"00000000"; -- null
    player_txdata(46) <= x"00000000"; -- null
    player_txdata(47) <= x"00000000"; -- null
    player_txdata(48) <= x"00000000"; -- null
    player_txdata(49) <= x"00000000"; -- null
    player_txdata(50) <= x"00000000"; -- null
    player_txdata(51) <= x"00000000"; -- null
    player_txdata(52) <= x"00000000"; -- null
    player_txdata(53) <= x"00000000"; -- null
    player_txdata(54) <= x"00000000"; -- null
    player_txdata(55) <= x"00000000"; -- null
    player_txdata(56) <= x"00000000"; -- null
    player_txdata(57) <= x"00000000"; -- null
    player_txdata(58) <= x"00000000"; -- null
    player_txdata(59) <= x"00000000"; -- null
    player_txdata(60) <= x"00000000"; -- null
    player_txdata(61) <= x"00000000"; -- null
    player_txdata(62) <= x"00000000"; -- null
    player_txdata(63) <= x"00000000"; -- null

    player_rxdata(44) <= x"00"; -- null
    player_rxdata(45) <= x"00"; -- null
    player_rxdata(46) <= x"00"; -- null
    player_rxdata(47) <= x"00"; -- null
    player_rxdata(48) <= x"00"; -- null
    player_rxdata(49) <= x"00"; -- null
    player_rxdata(50) <= x"00"; -- null
    player_rxdata(51) <= x"00"; -- null
    player_rxdata(52) <= x"00"; -- null
    player_rxdata(53) <= x"00"; -- null
    player_rxdata(54) <= x"00"; -- null
    player_rxdata(55) <= x"00"; -- null
    player_rxdata(56) <= x"00"; -- null
    player_rxdata(57) <= x"00"; -- null
    player_rxdata(58) <= x"00"; -- null
    player_rxdata(59) <= x"00"; -- null
    player_rxdata(60) <= x"00"; -- null
    player_rxdata(61) <= x"00"; -- null
    player_rxdata(62) <= x"00"; -- null
    player_rxdata(63) <= x"00"; -- null

    mac_ip_regs_o( 0) <= player_rxdata( 1);
    mac_ip_regs_o( 1) <= player_rxdata( 3);
    mac_ip_regs_o( 2) <= player_rxdata( 5);
    mac_ip_regs_o( 3) <= player_rxdata( 7);
    mac_ip_regs_o( 4) <= player_rxdata( 9);
    mac_ip_regs_o( 5) <= player_rxdata(11);
    mac_ip_regs_o( 6) <= player_rxdata(13);
    mac_ip_regs_o( 7) <= player_rxdata(15);
    mac_ip_regs_o( 8) <= player_rxdata(17);
    mac_ip_regs_o( 9) <= player_rxdata(19);
    mac_ip_regs_o(10) <= player_rxdata(21);
    mac_ip_regs_o(11) <= player_rxdata(23);
    mac_ip_regs_o(12) <= player_rxdata(25);
    mac_ip_regs_o(13) <= player_rxdata(27);
    mac_ip_regs_o(14) <= player_rxdata(29);
    mac_ip_regs_o(15) <= player_rxdata(31);

    eui48_regs_o(0) <= player_rxdata(33);
    eui48_regs_o(1) <= player_rxdata(35);
    eui48_regs_o(2) <= player_rxdata(37);
    eui48_regs_o(3) <= player_rxdata(39);
    eui48_regs_o(4) <= player_rxdata(41);
    eui48_regs_o(5) <= player_rxdata(43);

ctrl: process(clk, reset)
    variable fsm     : integer range 0 to 4;
    variable addrcnt : integer range 0 to lastaddr;
begin
    if reset = '1' then
        fsm           :=  0;
        addrcnt       :=  0;
        player_enable <= '1';
        done_o        <= '0';
        txdata        <= (others =>'0');
    elsif rising_edge(clk) then
        case fsm is
            when 0 => fsm := 1;
            when 1 => txdata <= player_txdata(addrcnt);
                      fsm := 2;
            when 2 => if done_i = '0' then
                          fsm := 3;
                      end if;
            when 3 => if done_i = '1' then 
                          player_rxdata(addrcnt) <= reply_i(7 downto 0);
                          if addrcnt = lastaddr then 
                              fsm := 4;
                          else
                              addrcnt := addrcnt+1; 
                              fsm := 0;
                          end if;
                      end if;
            when 4 => done_o <= '1';
                      player_enable <= '0';
        end case;
    end if;
end process;

cmd_wr: process(clk, reset)
    variable str      : std_logic;
    variable str_prev : std_logic;
    variable cmd      : std_logic_vector(30 downto 0);
    variable cmd_prev : std_logic_vector(30 downto 0);
    variable adr      : integer range 0 to lastaddr;
    variable adr_prev : integer range 0 to lastaddr;
begin
    if reset = '1' then
        cmd_prev := (others => '0');
        cmd      := (others => '0');
        strobe   <= '0';
    elsif rising_edge(clk) then
        if bypass_i = '1' or player_enable = '0' then
            command  <= command_i;
            settings <= settings_i;
            cmd_prev := (others => '0');
            cmd      := (others => '0');
        elsif player_enable = '1' then
            settings <= x"008300";
            command  <= strobe & cmd;
            strobe   <= '0';

            if cmd_prev /= cmd then
                strobe <= '1';
            end if;

            cmd_prev := cmd;
            cmd      := txdata(30 downto 0);
        end if;
    end if;
end process cmd_wr;

reply_o    <= reply_i;
command_o  <= command;
settings_o <= settings;

end rtl;
