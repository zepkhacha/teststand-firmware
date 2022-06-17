-- IPbus slave for communication with SPI Flash memory
-- (see also the spi_flash_intf.v module)
--
-- FLASH.WBUF: write 32-bit words to this address to store data for transfer to Flash
--             (the MSB will be sent to the Flash first)
--
-- FLASH.RBUF: read 32-bit words from this address to see the Flash response
--             (the MSB is the first bit of the Flash response)
--
-- FLASH.CMD: write a 32-bit command to this address to initiate a transaction with the Flash
--            The format of the 32-bit command is 0x0NNN0MMM
--            "NNN" is the number of bytes that will be sent from WBUF to the Flash
--            "MMM" is the number of response bytes to store in RBUF from the Flash
--            both NNN and MMM are limited to 9 bits

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- system packages
use work.ipbus.all;
use work.system_package.all;

entity ipbus_flash_regs is
generic (addr_width : positive := 9);
port (
    clk       : in std_logic;
    reset     : in std_logic;
    ipbus_in  : in  ipb_wbus;
    ipbus_out : out ipb_rbus;
    -- Flash ports
    flash_wr_nBytes  : out std_logic_vector( 8 downto 0);
    flash_rd_nBytes  : out std_logic_vector( 8 downto 0);
    flash_cmd_strobe : out std_logic;
    flash_rbuf_en    : out std_logic;
    flash_rbuf_addr  : out std_logic_vector( 6 downto 0);
    flash_rbuf_data  : in  std_logic_vector(31 downto 0);
    flash_wbuf_en    : out std_logic;
    flash_wbuf_addr  : out std_logic_vector( 6 downto 0);
    flash_wbuf_data  : out std_logic_vector(31 downto 0)
);
end ipbus_flash_regs;

architecture rtl of ipbus_flash_regs is

    signal ack         : std_logic;
    signal ack_delay   : std_logic_vector(1 downto 0);
    signal strobe      : std_logic;
    signal prev_strobe : std_logic;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            prev_strobe <= strobe;
            strobe <= ipbus_in.ipb_strobe;

            -- FLASH.CMD
            if ipbus_in.ipb_addr(8) = '1' then

                -- capture the command when the strobe turns on
                -- (there will only ever be one command per strobe)
                if (prev_strobe = '0' and strobe = '1') then
                    flash_wr_nBytes <= ipbus_in.ipb_wdata(24 downto 16);
                    flash_rd_nBytes <= ipbus_in.ipb_wdata( 8 downto  0);
                end if;
                
                flash_cmd_strobe <= ipbus_in.ipb_strobe and ipbus_in.ipb_write;
                flash_rbuf_en    <= '0';
                flash_wbuf_en    <= '0';

            -- FLASH.RBUF
            elsif ipbus_in.ipb_addr(7) = '1' then
            
                flash_rbuf_en       <= ipbus_in.ipb_strobe;
                flash_rbuf_addr     <= ipbus_in.ipb_addr(6 downto 0);
                ipbus_out.ipb_rdata <= flash_rbuf_data;
                flash_wbuf_en       <= '0';
                flash_cmd_strobe    <= '0';

            -- FLASH.WBUF
            else

                flash_wbuf_en       <= ipbus_in.ipb_strobe and ipbus_in.ipb_write;
                flash_wbuf_addr     <= ipbus_in.ipb_addr(6 downto 0);
                flash_wbuf_data     <= ipbus_in.ipb_wdata;
                ipbus_out.ipb_rdata <= ipbus_in.ipb_wdata;
                flash_rbuf_en       <= '0';
                flash_cmd_strobe    <= '0';

            end if;

            ack_delay(0) <= ipbus_in.ipb_strobe and not ack;
            ack_delay(1) <= ack_delay(0) and not ack;
            ack          <= ack_delay(1) and not ack;
        end if;
    end process;

    ipbus_out.ipb_ack <= ack;
    ipbus_out.ipb_err <= '0';

end rtl;
