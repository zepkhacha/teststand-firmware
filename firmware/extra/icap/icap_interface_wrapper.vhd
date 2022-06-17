-- Company : CERN (PH-ESE-BE)
-- Engineer: Manoel Barros Marin (manoel.barros.marin@cern.ch) (m.barros@ieee.org)
-- Date    : 12/01/2012

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-- user packages
use work.ipbus.all;

entity icap_interface_wrapper is
port (
    -- control
    RESET_I         : in  std_logic;
    CONF_TRIGG_I    : in  std_logic;
    FSM_CONF_PAGE_I : in  std_logic_vector(1 downto 0);
    -- IPbus inteface
    IPBUS_CLK_I     : in  std_logic;
    IPBUS_I         : in  ipb_wbus;
    IPBUS_O         : out ipb_rbus  
);
end icap_interface_wrapper;

architecture structural of icap_interface_wrapper is
    -- Internal Configuration Access Port (ICAP) interface
    signal icapCs_from_ioControl    : std_logic;
    signal icapWrite_from_ioControl : std_logic;
    signal icapData_from_ioControl  : std_logic_vector(31 downto 0);
    signal data_from_icapInterface  : std_logic_vector(31 downto 0);
    signal ack_from_icapInterface   : std_logic;

    -- FPGA Configuration Finite State Machine
    signal select_from_fsm       : std_logic;
    signal cs_from_fsm           : std_logic;
    signal write_from_fsm        : std_logic;
    signal data_from_fsm         : std_logic_vector(31 downto 0);
    signal fsmAck_from_ioControl : std_logic;

begin
    -- I/O control
    ioControl: entity work.flashIcap_ioControl
    port map (
        -- control
        FSM_SELECT_I => select_from_fsm,
        -- logic fabric
        IPBUS_I      => IPBUS_I,
        IPBUS_O      => IPBUS_O,
        -- FSM
        FSM_CS_I     => cs_from_fsm,
        FSM_WRITE_I  => write_from_fsm,
        FSM_DATA_I   => data_from_fsm,
        FSM_ACK_O    => fsmAck_from_ioControl,
        -- ICAP
        ICAP_CS_O    => icapCs_from_ioControl,
        ICAP_WRITE_O => icapWrite_from_ioControl,
        ICAP_DATA_O  => icapData_from_ioControl,
        ICAP_DATA_I  => data_from_icapInterface,
        ICAP_ACK_I   => ack_from_icapInterface
    );

    -- Internal Configuration Access Port (ICAP) interface
    icapInterface: entity work.icap_interface
    port map (
        RESET_I => RESET_I,
        CLK_I   => IPBUS_CLK_I,
        CS_I    => icapCs_from_ioControl,
        WRITE_I => icapWrite_from_ioControl,
        DATA_I  => icapData_from_ioControl,
        DATA_O  => data_from_icapInterface,
        ACK_O   => ack_from_icapInterface
    );

    -- FPGA Configuration Finite State Machine
    confFsm: entity work.icap_interface_fsm
    port map (  
        RESET_I         => RESET_I,
        CLK_I           => IPBUS_CLK_I,
        CONF_TRIGG_I    => CONF_TRIGG_I,
        FSM_CONF_PAGE_I => FSM_CONF_PAGE_I,
        FMS_SELECT_O    => select_from_fsm,
        CS_O            => cs_from_fsm,
        WRITE_O         => write_from_fsm,
        DATA_O          => data_from_fsm,
        ACK_I           => fsmAck_from_ioControl
    );
   
end structural;
