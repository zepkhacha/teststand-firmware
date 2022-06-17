-------------------------------------------------------------------------------
-- Copyright (c) 2014 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.5
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : ddr3_ila.vhd
-- /___/   /\     Timestamp  : Fri Feb 21 17:52:24 W. Europe Standard Time 2014
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY ddr3_ila IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    TRIG0: in std_logic_vector(255 downto 0);
    TRIG1: in std_logic_vector(27 downto 0);
    TRIG2: in std_logic_vector(0 to 0);
    TRIG3: in std_logic_vector(255 downto 0);
    TRIG4: in std_logic_vector(27 downto 0);
    TRIG5: in std_logic_vector(0 to 0);
    TRIG6: in std_logic_vector(31 downto 0);
    TRIG7: in std_logic_vector(0 to 0);
    TRIG8: in std_logic_vector(255 downto 0);
    TRIG9: in std_logic_vector(27 downto 0));
END ddr3_ila;

ARCHITECTURE ddr3_ila_a OF ddr3_ila IS
BEGIN

END ddr3_ila_a;
