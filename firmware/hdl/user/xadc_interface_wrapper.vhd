-- Wrapper to instantiate xadc_interface.v in VHDL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity xadc_interface_wrapper is
port (
    -- clock and reset
    dclk  : in std_logic;
    reset : in std_logic;

    -- measurements
    measured_temp    : out std_logic_vector(15 downto 0);
    measured_vccint  : out std_logic_vector(15 downto 0);
    measured_vccaux  : out std_logic_vector(15 downto 0);
    measured_vccbram : out std_logic_vector(15 downto 0);

    -- alarms
    over_temp     : out std_logic;
    alarm_temp    : out std_logic;
    alarm_vccint  : out std_logic;
    alarm_vccaux  : out std_logic;
    alarm_vccbram : out std_logic
);
end xadc_interface_wrapper;

architecture Behavioral of xadc_interface_wrapper is

    component xadc_interface is 
    port (
        -- clock and reset
        dclk  : in std_logic;
        reset : in std_logic;

        -- measurements
        measured_temp    : out std_logic_vector(15 downto 0);
        measured_vccint  : out std_logic_vector(15 downto 0);
        measured_vccaux  : out std_logic_vector(15 downto 0);
        measured_vccbram : out std_logic_vector(15 downto 0);

        -- alarms
        over_temp     : out std_logic;
        alarm_temp    : out std_logic;
        alarm_vccint  : out std_logic;
        alarm_vccaux  : out std_logic;
        alarm_vccbram : out std_logic
    );
    end component;

begin

    xadc_interface_inst: xadc_interface
    port map (
        -- clock and reset
        dclk  => dclk,
        reset => reset,

        -- measurements
        measured_temp    => measured_temp,
        measured_vccint  => measured_vccint,
        measured_vccaux  => measured_vccaux,
        measured_vccbram => measured_vccbram,

        -- alarms
        over_temp     => over_temp,
        alarm_temp    => alarm_temp,
        alarm_vccint  => alarm_vccint,
        alarm_vccaux  => alarm_vccaux,
        alarm_vccbram => alarm_vccbram
    );

end Behavioral;
