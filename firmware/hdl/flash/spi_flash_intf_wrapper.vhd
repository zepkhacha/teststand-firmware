-- Wrapper to instantiate spi_flash_intf.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity spi_flash_intf_wrapper is
port (
  clk      : in  std_logic;
  reset    : in  std_logic;
  spi_clk  : out std_logic;
  spi_mosi : out std_logic;
  spi_miso : in  std_logic;
  spi_ss   : out std_logic;

  flash_wr_nBytes  : in  std_logic_vector( 8 downto 0);
  flash_rd_nBytes  : in  std_logic_vector( 8 downto 0);
  flash_cmd_strobe : in  std_logic;
  rbuf_rd_en       : in  std_logic;
  rbuf_rd_addr     : in  std_logic_vector( 6 downto 0);
  rbuf_data_out    : out std_logic_vector(31 downto 0);
  wbuf_wr_en       : in  std_logic;
  wbuf_wr_addr     : in  std_logic_vector( 6 downto 0);
  wbuf_data_in     : in  std_logic_vector(31 downto 0)
);
end spi_flash_intf_wrapper;

architecture Behavioral of spi_flash_intf_wrapper is

  component spi_flash_intf is 
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    spi_clk  : out std_logic;
    spi_mosi : out std_logic;
    spi_miso : in  std_logic;
    spi_ss   : out std_logic;

    flash_wr_nBytes  : in  std_logic_vector( 8 downto 0);
    flash_rd_nBytes  : in  std_logic_vector( 8 downto 0);
    flash_cmd_strobe : in  std_logic;
    rbuf_rd_en       : in  std_logic;
    rbuf_rd_addr     : in  std_logic_vector( 6 downto 0);
    rbuf_data_out    : out std_logic_vector(31 downto 0);
    wbuf_wr_en       : in  std_logic;
    wbuf_wr_addr     : in  std_logic_vector( 6 downto 0);
    wbuf_data_in     : in  std_logic_vector(31 downto 0)
  );
  end component;

begin

  flash_intf: spi_flash_intf
  port map (
    clk      => clk,
    reset    => reset,
    spi_clk  => spi_clk,
    spi_mosi => spi_mosi,
    spi_miso => spi_miso,
    spi_ss   => spi_ss,

    flash_wr_nBytes  => flash_wr_nBytes,
    flash_rd_nBytes  => flash_rd_nBytes,
    flash_cmd_strobe => flash_cmd_strobe,
    rbuf_rd_en       => rbuf_rd_en,
    rbuf_rd_addr     => rbuf_rd_addr,
    rbuf_data_out    => rbuf_data_out,
    wbuf_wr_en       => wbuf_wr_en,
    wbuf_wr_addr     => wbuf_wr_addr,
    wbuf_data_in     => wbuf_data_in
  );

end Behavioral;
