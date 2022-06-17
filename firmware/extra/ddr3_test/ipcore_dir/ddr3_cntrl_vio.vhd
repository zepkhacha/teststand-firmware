-------------------------------------------------------------------------------
-- Copyright (c) 2014 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.5
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : ddr3_cntrl_vio.vhd
-- /___/   /\     Timestamp  : Fri Feb 28 15:01:35 W. Europe Standard Time 2014
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY ddr3_cntrl_vio IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    ASYNC_IN: in std_logic_vector(0 to 0);
    ASYNC_OUT: out std_logic_vector(1 downto 0));
END ddr3_cntrl_vio;

ARCHITECTURE ddr3_cntrl_vio_a OF ddr3_cntrl_vio IS
BEGIN

END ddr3_cntrl_vio_a;
