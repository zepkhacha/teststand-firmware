-------------------------------------------------------------------------------
-- File       : RAM_read_data_handler.vhd
-- Author     : 
-- Company    : 
-- Created    : 2013-08-13
-- Last update: 2014-02-07
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-08-13  1.0      ghibaudi        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--use work.demonstrator_top_level_definitions.all;
use work.external_memory_interface_definitions.all;
--use work.external_32bits_bus_interface_definitions.all;

-------------------------------------------------------
--! @author Marco Ghibaudi, CERN.
--! @file RAM_read_data_handler.vhdl
--! @brief  Used for configuring the address generators
entity RAM_read_data_handler is
  port
    (
      clk             : in  std_logic;
      rst             : in  std_logic;
      data_in         : in  DDR3_DATA_TRIG_TYPE;
      addr_in         : in  DDR3_ADDR_WT_SRC_TRIG_TYPE;
      int_rd_info_out : out DDR3_FULL_INFO_TRIG_TYPE;
      ext_rd_info_out : out DDR3_FULL_INFO_TRIG_TYPE
      );
end entity RAM_read_data_handler;

architecture RTL of RAM_read_data_handler is
  
  signal addr_fifo_rden  : std_logic;
  signal addr_fifo_dout  : DDR3_ADDR_WT_SRC_TYPE;
  signal addr_fifo_empty : std_logic;
  signal addr_fifo_full  : std_logic;
  signal addr_fifo_valid : std_logic;

  signal data_fifo_rden  : std_logic;
  signal data_fifo_dout  : DDR3_DATA_TYPE;
  signal data_fifo_empty : std_logic;
  signal data_fifo_full  : std_logic;
  signal data_fifo_valid : std_logic;

  signal overflow                 : std_logic;
  constant ADDR_BUFFER_ADDR_WIDTH : integer := 9;
  constant DATA_BUFFER_ADDR_WIDTH : integer := 4;
  
begin


  -- Temporary FIFO for addresses
  addr_FIFO : entity work.syncfifo
    generic map (width   => DDR3_ADDR_WIDTH+1,
                 widthad => ADDR_BUFFER_ADDR_WIDTH)
    port map (
      clk      => clk,
      rst      => rst,
      data_in  => addr_in.data,
      wrreq    => addr_in.trg,
      rdreq    => addr_fifo_rden,
      data_out => addr_fifo_dout,
      full     => addr_fifo_full,
      empty    => addr_fifo_empty,
      valid    => addr_fifo_valid,
      usedw    => open); 
  addr_fifo_rden <= not (data_fifo_empty or addr_fifo_empty);

  -- Temporary FIFO for data, small depth
  data_FIFO : entity work.syncfifo
    generic map (width   => DDR3_DATA_WIDTH,
                 widthad => DATA_BUFFER_ADDR_WIDTH)
    port map (
      clk      => clk,
      rst      => rst,
      data_in  => data_in.data,
      wrreq    => data_in.trg,
      rdreq    => data_fifo_rden,
      data_out => data_fifo_dout,
      full     => data_fifo_full,
      empty    => data_fifo_empty,
      valid    => data_fifo_valid,
      usedw    => open); 
  data_fifo_rden <= not (data_fifo_empty or addr_fifo_empty);

  -- Overflow Signal
  overflow <= data_fifo_full or addr_fifo_full;

  gen_outputs : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        int_rd_info_out <= (addr => (others => '0'), data => (others => '0'), trg => '0');
        ext_rd_info_out <= (addr => (others => '0'), data => (others => '0'), trg => '0');
      else
        ext_rd_info_out <= (addr => addr_fifo_dout(DDR3_ADDR_WIDTH-1 downto 0),
                            data => data_fifo_dout, trg => '0');
        int_rd_info_out <= (addr => addr_fifo_dout(DDR3_ADDR_WIDTH-1 downto 0),
                            data => data_fifo_dout, trg => '0');  
        if ((data_fifo_valid and addr_fifo_valid) = '1') then
          ext_rd_info_out.trg <= addr_fifo_dout(EXT32_ADDR_MOD_POS);
          int_rd_info_out.trg <= not addr_fifo_dout(EXT32_ADDR_MOD_POS);
        else
          ext_rd_info_out.trg <= '0';
          int_rd_info_out.trg <= '0';
        end if;
      end if;
    end if;
  end process gen_outputs;

  
end architecture RTL;
