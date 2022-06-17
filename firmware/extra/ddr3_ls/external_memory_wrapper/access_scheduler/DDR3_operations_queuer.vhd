-------------------------------------------------------------------------------
-- Title      : DDR3 Low level operation scheduler
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : DDR3_operations_queuer.vhd
-- Author     : 
-- Company    : 
-- Created    : 2012-12-13
-- Last update: 2014-02-07
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2012 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2012-12-13  1.0      ghibaudi        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.external_memory_interface_definitions.all;

entity DDR3_operations_queuer is
  port(rst              : in  std_logic;
        clk             : in  std_logic;
        DDR3_operation  : in  DDR3_OPERATION_TYPE;
        -- Addresses and Data in
        wr_int_info     : in  DDR3_FULL_INFO_TRIG_TYPE;
        rd_int_addr     : in  DDR3_ADDR_TRIG_TYPE;
        wr_ext_info     : in  DDR3_FULL_INFO_TRIG_TYPE;
        rd_ext_addr     : in  DDR3_ADDR_TRIG_TYPE;
        -- Request data/addresses from the different interface
        pop_fifo_wr_int : out std_logic;
        pop_fifo_rd_int : out std_logic;
        pop_fifo_wr_ext : out std_logic;
        pop_fifo_rd_ext : out std_logic;
        -- Send commands, data and addresses
        MI_cmd_out      : out UD_MEM_CMD_TRIG_TYPE;
        MI_data_out     : out DDR3_DATA_TRIG_TYPE;
        MI_addr_out     : out DDR3_ADDR_WT_SRC_TRIG_TYPE);
end entity DDR3_operations_queuer;

architecture behavioural of DDR3_operations_queuer is

begin

  -- synthesis translate_off
  debug_checks : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '0') then
        -- debug checks
        assert not (wr_int_info.trg = '1' and wr_ext_info.trg = '1')
          report "Collision on data between internal/external write!"
          severity failure;
        assert not (rd_int_addr.trg = '1' and rd_ext_addr.trg = '1')
          report "Collision on addresses between internal/external read!"
          severity failure;
      end if;
    end if;
  end process;
  -- synthesis translate_on

  gen_rqsts_p : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        pop_fifo_wr_int <= '0';
        pop_fifo_rd_int <= '0';
        pop_fifo_wr_ext <= '0';
        pop_fifo_rd_ext <= '0';
      else
        pop_fifo_wr_int <= '0';
        pop_fifo_rd_int <= '0';
        pop_fifo_wr_ext <= '0';
        pop_fifo_rd_ext <= '0';
        case DDR3_operation is
          when DDR3_READ_INT =>
            pop_fifo_rd_int <= '1';
          when DDR3_WRITE_INT =>
            pop_fifo_wr_int <= '1';
          when DDR3_READ_EXT =>
            pop_fifo_rd_ext <= '1';
          when DDR3_WRITE_EXT =>
            pop_fifo_wr_ext <= '1';
          when others =>
            null;
        end case;
      end if;
    end if;
  end process gen_rqsts_p;


  gen_signals_p : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        MI_cmd_out  <= (data => (others => '0'), trg => '0');
        MI_addr_out <= (data => (others => '0'), trg => '0');
        MI_data_out <= (data => (others => '0'), trg => '0');
      else
        -- Generation of address (expanded) and command signals (tied together)
        if (rd_int_addr.trg = '1') then
          MI_cmd_out  <= (data => DDR3_RD_CMD_CODE, trg => '1');
          MI_addr_out <= (data => EXT32_INT_ADDR_MOD & rd_int_addr.data, trg => '1');
        elsif (wr_int_info.trg = '1') then
          MI_cmd_out  <= (data => DDR3_WR_CMD_CODE, trg => '1');
          MI_addr_out <= (data => EXT32_INT_ADDR_MOD & wr_int_info.addr, trg => '1');
        elsif (rd_ext_addr.trg = '1') then
          MI_cmd_out  <= (data => DDR3_RD_CMD_CODE, trg => '1');
          MI_addr_out <= (data => EXT32_EXT_ADDR_MOD & rd_ext_addr.data, trg => '1');
        elsif (wr_ext_info.trg = '1') then
          MI_cmd_out  <= (data => DDR3_WR_CMD_CODE, trg => '1');
          MI_addr_out <= (data => EXT32_EXT_ADDR_MOD & wr_ext_info.addr, trg => '1');
        else
          MI_cmd_out  <= (data => DDR3_NOP_CMD_CODE, trg => '0');
          MI_addr_out <= (data => (others => '0'), trg => '0');
        end if;
        -- Generation of data signals
        if (wr_int_info.trg = '1') then
          MI_data_out <= (data => wr_int_info.data, trg => '1');
        elsif (wr_ext_info.trg = '1') then
          MI_data_out <= (data => wr_ext_info.data, trg => '1');
        else
          MI_data_out <= (data => (others => '0'), trg => '0');
        end if;
      end if;
    end if;
  end process gen_signals_p;
  
  
end architecture behavioural;
