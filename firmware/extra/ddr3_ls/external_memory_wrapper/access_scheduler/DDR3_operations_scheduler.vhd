-------------------------------------------------------------------------------
-- Title      : DDR3 Low level operation scheduler
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : DDR3_operations_scheduler.vhd
-- Author     : 
-- Company    : 
-- Created    : 2012-12-13
-- Last update: 2014-02-07
-- Platform   : Windows 7 64bits, Modelsim 10.2a, Xilinx ISE 16.4
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

--use work.demonstrator_top_level_definitions.all;
use work.external_memory_interface_definitions.all;

--! @file DDR3_operations_scheduler.vhd
--! @brief  Select the next low level operation to be executed according to the R/W FIFOs occupancy level
entity DDR3_operations_scheduler is
  generic
    (EXT_BUS_ANTI_SVTION_THD : integer := 1;  --! # clocks before the EXT bus gets maximum priority.
     MI_NUM_MAX_QUEUED_OPS   : integer := 32;  --! every # clocks check memory is ready.
     BURST_SIZE              : integer := 32
     );
  port
    (
      rst            : in  std_logic;
      clk            : in  std_logic;
      -- FIFOs occupancy    
      int_wr_occ     : in  MI_FIFO_OCC_TYPE;
      int_rd_occ     : in  MI_FIFO_OCC_TYPE;
      ext_wr_occ     : in  MI_FIFO_OCC_TYPE;
      ext_rd_occ     : in  MI_FIFO_OCC_TYPE;
      -- Signals from DDR3_MI_interface
      MI_bsy         : in  std_logic;
      -- DDR3 operation to be scheduled next
      DDR3_operation : out DDR3_OPERATION_TYPE
      );
end entity DDR3_operations_scheduler;


architecture RTL of DDR3_operations_scheduler is

  type SCHED_STATUS is (RUNNING, IDLE);
  signal state        : SCHED_STATUS;
  constant CNT_SIZE   : integer          := 16;
  subtype CNT_TYPE is unsigned(CNT_SIZE-1 downto 0);
  constant CNT_ZERO   : CNT_TYPE         := to_unsigned(0, CNT_SIZE);
  constant QUEUED_OPS : CNT_TYPE         := to_unsigned(MI_NUM_MAX_QUEUED_OPS, CNT_SIZE);
  constant ZERO_UT    : MI_FIFO_OCC_TYPE := (others => '0');

  signal PROBE_op_cnt : integer;
begin

  status_hdlr : process (clk)
    variable clk_cnt : CNT_TYPE;
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        state   <= IDLE;
        clk_cnt := (others => '0');
      else
        if (clk_cnt > QUEUED_OPS) then
          if (MI_bsy = '0') then
            clk_cnt := (others => '0');
            state   <= RUNNING;
          else
            state <= IDLE;
          end if;
        else
          clk_cnt := clk_cnt + 1;
          state   <= RUNNING;
        end if;
      end if;
    end if;
  end process status_hdlr;

  gen_cmd_seq : process (clk)
    variable rd_ext_wait : integer;
    variable wr_ext_wait : integer;
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        DDR3_operation <= DDR3_NOP;
        rd_ext_wait    := 0;
        wr_ext_wait    := 0;
      else
        case state is
          when IDLE =>
            DDR3_operation <= DDR3_NOP;
          when RUNNING =>
            -- Counters for the external accesses
            if (ext_rd_occ /= ZERO_UT) then
              rd_ext_wait := rd_ext_wait + 1;
            else
              rd_ext_wait := 0;
            end if;
            if (ext_wr_occ /= ZERO_UT) then
              wr_ext_wait := wr_ext_wait + 1;
            else
              wr_ext_wait := 0;
            end if;
            -- Priority selection
            if (wr_ext_wait > EXT_BUS_ANTI_SVTION_THD) then
              DDR3_operation <= DDR3_WRITE_EXT;
              wr_ext_wait    := 0;
            elsif (rd_ext_wait > EXT_BUS_ANTI_SVTION_THD) then
              DDR3_operation <= DDR3_READ_EXT;
              rd_ext_wait    := 0;
            elsif (int_wr_occ /= ZERO_UT) then
              DDR3_operation <= DDR3_WRITE_INT;
            elsif (int_rd_occ /= ZERO_UT) then
              DDR3_operation <= DDR3_READ_INT;
            elsif (ext_wr_occ /= ZERO_UT) then
              DDR3_operation <= DDR3_WRITE_EXT;
            elsif (ext_rd_occ /= ZERO_UT) then
              DDR3_operation <= DDR3_READ_EXT;
            else
              DDR3_operation <= DDR3_NOP;
            end if;
          when others =>
            DDR3_operation <= DDR3_NOP;
        end case;
      end if;
    end if;
    -- Increasing the operation counter
  end process gen_cmd_seq;

end architecture RTL;
