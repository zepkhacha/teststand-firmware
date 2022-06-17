library ieee;
use ieee.std_logic_1164.all;

package system_package is

    -- 1-dimensional arrays
    type array_8x128bit  is array (0 to   7) of std_logic_vector(127 downto 0);
    type array_8x64bit   is array (0 to   7) of std_logic_vector( 63 downto 0);
--    type array_209x32bit is array (0 to 208) of std_logic_vector( 31 downto 0);
--    type array_50x32bit  is array (0 to  49) of std_logic_vector( 31 downto 0);
    type array_32x32bit  is array (0 to  31) of std_logic_vector( 31 downto 0);
    type array_30x32bit  is array (0 to  29) of std_logic_vector( 31 downto 0);
    type array_3x32bit   is array (0 to   2) of std_logic_vector( 31 downto 0);
    type array_8x32bit   is array (0 to   7) of std_logic_vector( 31 downto 0);
    type array_32x24bit  is array (0 to  31) of std_logic_vector( 23 downto 0);
    type array_16x24bit  is array (0 to  15) of std_logic_vector( 23 downto 0);
    type array_16x16bit  is array (0 to  15) of std_logic_vector( 15 downto 0);
    type array_16x12bit  is array (0 to  15) of std_logic_vector( 11 downto 0);
    type array_4x16bit   is array (0 to   3) of std_logic_vector( 15 downto 0);
    type array_8x8bit    is array (0 to   7) of std_logic_vector(  7 downto 0);
    type array_6x8bit    is array (0 to   5) of std_logic_vector(  7 downto 0);
    type array_64x8bit   is array (0 to  63) of std_logic_vector(  7 downto 0);
    type array_16x8bit   is array (0 to  15) of std_logic_vector(  7 downto 0);
    type array_16x5bit   is array (0 to  15) of std_logic_vector(  4 downto 0);
    type array_16x4bit   is array (0 to  15) of std_logic_vector(  3 downto 0);
    type array_8x4bit    is array (0 to   7) of std_logic_vector(  3 downto 0);
    type array_7x4bit    is array (0 to 6) of std_logic_vector(3 downto 0);
    type array_16x2bit   is array (0 to  15) of std_logic_vector(  1 downto 0);
    type array_4x7bit    is array (0 to   3) of std_logic_vector(  6 downto 0);
    type array_4x5bit    is array (0 to   3) of std_logic_vector(  4 downto 0);
    type array_2x4bit    is array (0 to   1) of std_logic_vector(  3 downto 0);

    -- 2-dimensional arrays
    type array_16x32x32bit is array (0 to 15, 0 to 31) of std_logic_vector(31 downto 0);
    type array_16x16x32bit is array (0 to 15, 0 to 15) of std_logic_vector(31 downto 0);
    type array_16x16x5bit  is array (0 to 15, 0 to 15) of std_logic_vector( 4 downto 0);
    type array_2x16x24bit  is array (0 to  1, 0 to 15) of std_logic_vector(23 downto 0);

        -- ipbus trigger parameter arrays
    type array_4_16x24bit    is array (0 to  3) of array_16x24bit;
    type array_4_16x8bit     is array (0 to  3) of array_16x8bit;
    type array_12_4_16x24bit is array (0 to 11) of array_4_16x24bit;
    type array_12_4_16x8bit  is array (0 to 11) of array_4_16x8bit;
    type array_7_4_16x24bit  is array (0 to 6)  of array_4_16x24bit;
    type array_7_4_16x8bit   is array (0 to 6)  of array_4_16x8bit;

    -- make the control and status registers easier to extend by defining a central type here
    constant ctrl_reg_max : positive := 49;
    type ctrl_reg_t  is array (0 to  ctrl_reg_max) of std_logic_vector( 31 downto 0);
    type stat_reg_t  is array (0 to           208) of std_logic_vector( 31 downto 0);

    -- --------------------------------------------------------------------
    -- arrays for the analog trigger parameters
    -- -- add the 4 (delay) or 2 (width) subcounter indices
    type array_4_4x7bit    is array (0 to 3) of array_4x7bit;
    type array_2_4x5bit    is array (0 to 1) of array_4x5bit;
    type array_10_4x7bit   is array (0 to 9) of array_4x7bit;
    type array_10_2x5bit   is array (0 to 9) of array_4x5bit;

    -- -- now add the  eight sequence (fill triggers) index
    type array_8_4_4x7bit  is array (0 to 7) of array_4_4x7bit;
    type array_8_2_4x5bit  is array (0 to 7) of array_2_4x5bit;

    -- -- now add the channel number index
    type array_7_8_4_4x7bit is  array (0 to  6) of array_8_4_4x7bit;
    type array_7_8_2_4x5bit is  array (0 to  6) of array_8_2_4x5bit;
--    type array_3_8_4_4x7bit is  array (7 to  9) of array_8_4_4x7bit;
--    type array_3_8_2_4x5bit is  array (7 to  9) of array_8_2_4x5bit;
--    type array_5_8_4_4x7bit is  array (7 to  11) of array_8_4_4x7bit;
--    type array_5_8_2_4x5bit is  array (7 to  11) of array_8_2_4x5bit;
    type array_7u_8_4_4x7bit is  array (7 to  13) of array_8_4_4x7bit;
    type array_7u_8_2_4x5bit is  array (7 to  13) of array_8_2_4x5bit;

    -- -- finally, the cycle number
    type fast_delay_reg_t is  array (0 to 1) of array_7_8_4_4x7bit;
    type fast_width_reg_t is  array (0 to 1) of array_7_8_2_4x5bit;
--    type slow_delay_reg_t is  array (0 to 1) of array_3_8_4_4x7bit;
--    type slow_width_reg_t is  array (0 to 1) of array_3_8_2_4x5bit;
--    type slow_delay_reg_t is  array (0 to 1) of array_5_8_4_4x7bit;
--    type slow_width_reg_t is  array (0 to 1) of array_5_8_2_4x5bit;
    type slow_delay_reg_t is  array (0 to 1) of array_7u_8_4_4x7bit;
    type slow_width_reg_t is  array (0 to 1) of array_7u_8_2_4x5bit;

    -- -- the enabled arrays
    type array_7_8x4bit     is array (0 to  6) of array_8x4bit;
--    type array_3_8x4bit     is array (7 to  9) of array_8x4bit;
--    type array_5_8x4bit     is array (7 to 11) of array_8x4bit;
    type array_7u_8x4bit     is array (7 to 13) of array_8x4bit;
    type fast_enabled_reg_t   is array (0 to  1) of array_7_8x4bit;
--    type slow_enabled_reg_t   is array (0 to  1) of array_3_8x4bit;
--    type slow_enabled_reg_t   is array (0 to  1) of array_5_8x4bit;
    type slow_enabled_reg_t   is array (0 to  1) of array_7u_8x4bit;

    type array_2_8x32bit    is array (0 to  1) of array_8x32bit;
    type array_4_2_8x32bit  is array (0 to  3) of array_2_8x32bit;

    -- --------------------------------------------------------------------
    -- nested trigger arrays before re-ordering.  With some work, we reduce to
    -- only the above set of parameters

    type array_4_2x16x24bit    is array (0 to  3) of array_2x16x24bit;
    type array_16_4_2x16x24bit is array (0 to 15) of array_4_2x16x24bit;
    
    -- IPbus system slaves
    constant nbr_sys_slaves     : positive := 1;
    constant sys_ipb_flash_regs : integer  := 0;

end system_package;

package body system_package is
end system_package;
