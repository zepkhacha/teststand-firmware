-- Wrapper for everything associated with MMC interface to IPbus.
-- Now only using 125-MHz free running clock (MP)
-- Dave Newbold, June 2013

library ieee;
use ieee.std_logic_1164.all;

-- system packages
use work.ipbus.all;
use work.ipbus_trans_decl.all;

entity uc_if is
port (
    clk125      : in  std_logic;
    rst125      : in  std_logic;
    uc_spi_miso : out std_logic;
    uc_spi_mosi : in  std_logic;
    uc_spi_sck  : in  std_logic;
    uc_spi_cs_b : in  std_logic;
    clk_ipb     : in  std_logic; -- IPbus clock (nominally ~30-MHz) & reset
    oob_in      : in  ipbus_trans_out;
    oob_out     : out ipbus_trans_in
);
end uc_if;

architecture rtl of uc_if is

    signal mmc_wdata, mmc_rdata : std_logic_vector(15 downto 0);
    signal mmc_we,    mmc_re    : std_logic;
    signal mmc_req,   mmc_done  : std_logic;

begin

uc_trans: entity work.trans_buffer
port map (
    clk_m   => clk125,
    rst_m   => rst125,
    m_wdata => mmc_wdata,
    m_we    => mmc_we,
    m_rdata => mmc_rdata,
    m_re    => mmc_re,
    m_req   => mmc_req,
    m_done  => mmc_done,
    clk_ipb => clk_ipb,
    t_out   => oob_out,
    t_in    => oob_in
);

spi: entity work.spi_interface
generic map (width => 16)
port map (
    clk       => clk125,
    rst       => rst125,
    spi_miso  => uc_spi_miso,
    spi_mosi  => uc_spi_mosi,
    spi_sck   => uc_spi_sck,
    spi_cs_b  => uc_spi_cs_b,
    buf_wdata => mmc_wdata,
    buf_we    => mmc_we,
    buf_rdata => mmc_rdata,
    buf_re    => mmc_re,
    buf_req   => mmc_req,
    buf_done  => mmc_done
);

end rtl;
