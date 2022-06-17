-------------------------------------------------------------------------------
-- Title      : Synchronous Fifo
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : syncfifo.vhd
-- Author     : 
-- Company    : CERN
-- Created    : xxxx-xx-xx
-- Last update: 2013-09-18
-- Platform   : Windows 7, Modelsim 12.0a
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) xxx 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- xxxx-xx-xx  1.0                      Created
-- 2012-12-13  2.0      ghibaudi        Removed aclr and renamed signals
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity syncfifo is
  generic (width   : integer;
           widthad : integer);
  port (clk      : in  std_logic;
        rst      : in  std_logic;
        data_in  : in  std_logic_vector (width-1 downto 0);
        wrreq    : in  std_logic;
        rdreq    : in  std_logic;
        data_out : out std_logic_vector (width-1 downto 0);
        empty    : out std_logic;
        full     : out std_logic;
        valid    : out std_logic;
        usedw    : out std_logic_vector (widthad-1 downto 0));
end syncfifo;


architecture rtl of syncfifo is

  -- convert boolean to std_logic
  type bool2std_array is array (boolean) of std_logic;
  constant bool2std : bool2std_array := (false => '0', true => '1');

  constant numwords : integer := 2 ** widthad;

  subtype address_t is unsigned(widthad-1 downto 0);
  constant zero : address_t := to_unsigned(0, address_t'length);
  constant one  : address_t := to_unsigned(1, address_t'length);

  signal empty_flag    : std_logic;
  signal full_flag     : std_logic;
  signal rd_ptr        : address_t;
  signal usedw_counter : address_t;
  signal wr_ptr        : address_t;
  signal read_addr     : address_t;
  signal usedw_is_0    : std_logic;
  signal usedw_is_1    : std_logic;
  signal valid_rreq    : std_logic;
  signal valid_wreq    : std_logic;

  -- Simple dual port ram. Size configurable.
  component asym_spram is
    generic (
      WIDTH     : integer;
      ADDRWIDTH : integer
      );
    port (clkA  : in  std_logic;
          weA   : in  std_logic;
          enA   : in  std_logic;
          addrA : in  std_logic_vector(ADDRWIDTH-1 downto 0);
          diA   : in  std_logic_vector(WIDTH-1 downto 0);
          doutA : out std_logic_vector(WIDTH-1 downto 0);
          clkB  : in  std_logic;
          enB   : in  std_logic;
          addrB : in  std_logic_vector(ADDRWIDTH-1 downto 0);
          doutB : out std_logic_vector(WIDTH-1 downto 0)
          );
  end component asym_spram;

begin  -- architecture rtl

  fiforam : asym_spram
    generic map (
      WIDTH     => width,
      ADDRWIDTH => widthad
      )
    port map (
      clkA  => clk,
      weA   => valid_wreq,
      enA   => valid_wreq,
      addrA => std_logic_vector(wr_ptr),
      diA   => data_in,
      doutA => open,
      clkB  => clk,
      enB   => valid_rreq,
      addrB => std_logic_vector(rd_ptr),
      doutB => data_out
      );


  write_pointer : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        wr_ptr <= zero;
      elsif (valid_wreq = '1') then
        wr_ptr <= wr_ptr + 1;
      end if;
    end if;
  end process;

  used_words_counter : process (clk)
    variable sel : std_logic_vector(0 to 1);
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        usedw_counter <= zero;
      else
        sel := valid_wreq & valid_rreq;
        case sel is
          when "10"   => usedw_counter <= usedw_counter + 1;
          when "01"   => usedw_counter <= usedw_counter - 1;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  read_pointer : process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        rd_ptr <= zero;
      elsif (valid_rreq = '1') then
        rd_ptr <= rd_ptr + 1;
      end if;
    end if;
  end process;


  fifo_flags : process (clk)
    variable usedw_will_be_0 : std_logic;
    variable usedw_will_be_1 : std_logic;
    variable usedw_is_2      : std_logic;
    variable almost_full     : std_logic;
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        empty_flag <= '1';
        full_flag  <= '0';
        usedw_is_0 <= '1';
        usedw_is_1 <= '0';
        valid      <= '0'; 
      else
        usedw_is_2      := bool2std(usedw_counter = 2);
        almost_full     := bool2std(usedw_counter = numwords-2);
        usedw_will_be_0 := (usedw_is_1 and valid_rreq and (not valid_wreq)) or
                           (usedw_is_0 and not (valid_wreq xor valid_rreq));
        usedw_will_be_1 := (usedw_is_2 and (not valid_wreq) and valid_rreq) or
                           (usedw_is_1 and not (valid_wreq xor valid_rreq)) or
                           (usedw_is_0 and valid_wreq and (not valid_rreq));
        empty_flag <= usedw_will_be_0 or (usedw_will_be_1 and valid_wreq);
        full_flag  <= (valid_wreq and (not valid_rreq) and almost_full) or
                      (full_flag and (not (valid_wreq xor valid_rreq)));
        usedw_is_0 <= usedw_will_be_0;
        usedw_is_1 <= usedw_will_be_1;
        valid      <= valid_rreq; 
      end if;
    end if;
    
  end process;

  empty <= empty_flag;
  full  <= full_flag;

  usedw <= std_logic_vector(usedw_counter);

  valid_rreq <= rdreq and not empty_flag;
  valid_wreq <= wrreq and not full_flag;
  
end rtl;
