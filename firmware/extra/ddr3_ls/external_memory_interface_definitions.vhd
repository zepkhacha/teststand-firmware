-------------------------------------------------------------------------------
-- Title      : Main constants and types for the external memory interface
-- Project    : CTPCore+ 
-------------------------------------------------------------------------------
-- File       : external_memory_interface_definitions.vhd
-- Author     : 
-- Company    : 
-- Created    : 2013-08-06
-- Last update: 2014-02-07
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2013-08-06  1.0      ghibaudi        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package external_memory_interface_definitions is
---------------------------------------------------
-- Memory specific constants.
---------------------------------------------------

  -- These values must be manually updated in a case of a change on the memory adopted.
  constant DQ_WIDTH       : integer := 32;
  constant DQS_WIDTH      : integer := 4;
  constant ROW_WIDTH      : integer := 14;
  constant BANK_WIDTH     : integer := 3;
  constant CK_WIDTH       : integer := 1;
  constant CKE_WIDTH      : integer := 1;
  constant CS_WIDTH       : integer := 1;
  constant nCS_PER_RANK   : integer := 1;
  constant DM_WIDTH       : integer := 4;
  constant ODT_WIDTH      : integer := 1;
  constant ADDR_WIDTH     : integer := 28;
  constant nCK_PER_CLK    : integer := 4;
  constant DATA_WIDTH     : integer := 32;
  constant PAYLOAD_WIDTH  : integer := DATA_WIDTH;
  constant APP_DATA_WIDTH : integer := 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
  constant APP_MASK_WIDTH : integer := APP_DATA_WIDTH / 8;


---------------------------------------------------
-- Memory Data and Addresses constants and types 
---------------------------------------------------
  constant DDR3_DATA_WIDTH        : integer := 256;
  constant DDR3_ADDR_WIDTH        : integer := 28;
  constant DDR3_MASK_WIDTH        : integer := DDR3_DATA_WIDTH/ 8;
  constant DDR3_ADDR_WT_SRC_WIDTH : integer := DDR3_ADDR_WIDTH + 1;
  subtype DDR3_DATA_TYPE is std_logic_vector (DDR3_DATA_WIDTH-1 downto 0);
  subtype DDR3_ADDR_TYPE is std_logic_vector (DDR3_ADDR_WIDTH-1 downto 0);

  --! For specifying the source, internal (Highes_bit = '0') or external (Highes_bit = '1')
  subtype DDR3_ADDR_WT_SRC_TYPE is std_logic_vector (DDR3_ADDR_WT_SRC_WIDTH-1 downto 0);
  --! For addressing 32 bits word  
  subtype DDR3_HALF_WORD_ADDR_TYPE is std_logic_vector (DDR3_ADDR_WIDTH downto 0);

  -- For incrementing the address
  constant DDR3_WORD_SIZE : integer := 8;

  -- Controller constants 
  constant UD_MEM_CMD_WIDTH  : integer         := 3;
  subtype UD_MEM_CMD_TYPE is std_logic_vector (UD_MEM_CMD_WIDTH-1 downto 0);
  constant DDR3_WR_CMD_CODE  : UD_MEM_CMD_TYPE := "000";
  constant DDR3_RD_CMD_CODE  : UD_MEM_CMD_TYPE := "001";
  constant DDR3_NOP_CMD_CODE : UD_MEM_CMD_TYPE := "111";

  -- Implementation specific constants
  constant INTERNAL_WRITE_BURST_LENGTH : integer := 32;  --! The length of the internal write burst operation.
  constant INTERNAL_READ_BURST_LENGTH  : integer := 32;  --! The length of the internal read burst operation.

  constant ADDRESS_32BITS_PADDING : std_logic_vector (32-DDR3_ADDR_WIDTH-1 downto 0) := (others => '0');
  
  
  type DDR3_OPERATION_TYPE is (DDR3_NOP, DDR3_WRITE_INT, DDR3_READ_INT,
                               DDR3_WRITE_EXT, DDR3_READ_EXT);

  type DDR3_WRITE_SRC_TYPE is (WR_ADDR_GEN, BUFFERED_ADDRESSES);

  constant NUM_OPERATION_COUNTER_DIGITS : integer := 32;
  subtype NUM_OPERATION_COUNTER_TYPE is unsigned (NUM_OPERATION_COUNTER_DIGITS-1 downto 0);

  -- Size of the input buffers.
  constant INPUT_BUFFS_ADD_WIDTH : integer := 9;  -- 512 words
  subtype MI_FIFO_OCC_TYPE is std_logic_vector (INPUT_BUFFS_ADD_WIDTH-1 downto 0);

  -- Position of the bit used for discerning between internal and external
  -- memory access.
  constant EXT32_ADDR_MOD_POS : integer   := DDR3_ADDR_WIDTH;
  constant EXT32_EXT_ADDR_MOD : std_logic := '1';
  constant EXT32_INT_ADDR_MOD : std_logic := '0';

  -- Functional buses
  type DDR3_DATA_TRIG_TYPE is
  record
    data : DDR3_DATA_TYPE;
    trg  : std_logic;
  end record;

  type DDR3_ADDR_TRIG_TYPE is
  record
    data : DDR3_ADDR_TYPE;
    trg  : std_logic;
  end record;

  type DDR3_ADDR_WT_SRC_TRIG_TYPE is
  record
    data : DDR3_ADDR_WT_SRC_TYPE;
    trg  : std_logic;
  end record;

  type DDR3_FULL_INFO_TRIG_TYPE is
  record
    addr : DDR3_ADDR_TYPE;
    data : DDR3_DATA_TYPE;
    trg  : std_logic;
  end record;


  type UD_MEM_CMD_TRIG_TYPE is
  record
    data : UD_MEM_CMD_TYPE;
    trg  : std_logic;
  end record;
  
  
end external_memory_interface_definitions;
