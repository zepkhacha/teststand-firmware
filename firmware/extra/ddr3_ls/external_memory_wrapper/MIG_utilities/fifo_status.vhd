-------------------------------------------------------------------------------
-- Title      : FIFOs ready signals generation
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : fifo_status.vhd
-- Author     : 
-- Company    : 
-- Created    : 2013-09-18
-- Last update: 2014-02-07
-- Platform   : Windows 7 - Modelsim 12.0a
-- Standard   : VHDL'02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-09-18  1.0      ghibaudi        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.external_memory_interface_definitions.all;

entity fifo_status is
  generic (
    CRITICAL_THRESHOLD : integer
    );
  port
    (
      clk             : in  std_logic;
      rst             : in  std_logic;
      -- Fifos utilization
      fifo_wr_int_occ : in  MI_FIFO_OCC_TYPE;
      fifo_rd_int_occ : in  MI_FIFO_OCC_TYPE;
      fifo_wr_ext_occ : in  MI_FIFO_OCC_TYPE;
      fifo_rd_ext_occ : in  MI_FIFO_OCC_TYPE;
      -- Status of the FIFOs
      fifo_wr_int_rdy : out std_logic;
      fifo_rd_int_rdy : out std_logic;
      fifo_wr_ext_rdy : out std_logic;
      fifo_rd_ext_rdy : out std_logic
      );
end fifo_status;

architecture behavioural of fifo_status is

  constant CRIT_THR : MI_FIFO_OCC_TYPE :=
    std_logic_vector(to_unsigned(CRITICAL_THRESHOLD, MI_FIFO_OCC_TYPE'length));

begin

  rdy_gen_p : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        fifo_wr_int_rdy <= '0';
        fifo_rd_int_rdy <= '0';
        fifo_wr_ext_rdy <= '0';
        fifo_rd_ext_rdy <= '0';
      else
        -- Generation of rdy signals
        if fifo_wr_int_occ > CRIT_THR then
          fifo_wr_int_rdy <= '0';
        else
          fifo_wr_int_rdy <= '1';
        end if;

        if fifo_rd_int_occ > CRIT_THR then
          fifo_rd_int_rdy <= '0';
        else
          fifo_rd_int_rdy <= '1';
        end if;

        if fifo_wr_ext_occ > CRIT_THR then
          fifo_wr_ext_rdy <= '0';
        else
          fifo_wr_ext_rdy <= '1';
        end if;

        if fifo_rd_ext_occ > CRIT_THR then
          fifo_rd_ext_rdy <= '0';
        else
          fifo_rd_ext_rdy <= '1';
        end if;

      end if;
    end if;
  end process rdy_gen_p;

end architecture;
