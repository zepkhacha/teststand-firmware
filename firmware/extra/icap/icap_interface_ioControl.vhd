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

entity flashIcap_ioControl is
port (
    -- control
    FSM_SELECT_I : in  std_logic;
    -- logic fabric
    IPBUS_I      : in  ipb_wbus;
    IPBUS_O      : out ipb_rbus;
    -- flash
    FSM_CS_I     : in  std_logic;
    FSM_WRITE_I  : in  std_logic;
    FSM_DATA_I   : in  std_logic_vector(31 downto 0);
    FSM_ACK_O    : out std_logic;
    -- ICAP
    ICAP_CS_O    : out std_logic;
    ICAP_WRITE_O : out std_logic;
    ICAP_DATA_O  : out std_logic_vector(31 downto 0);
    ICAP_DATA_I  : in  std_logic_vector(31 downto 0);
    ICAP_ACK_I   : in  std_logic
);
end flashIcap_ioControl;

architecture structural of flashIcap_ioControl is
begin

    IPBUS_O.ipb_err   <= '0';
    IPBUS_O.ipb_rdata <= ICAP_DATA_I;

    -- CS
    ICAP_CS_O       <= FSM_CS_I    when FSM_SELECT_I = '1' else IPBUS_I.ipb_strobe;
    -- WRITE
    ICAP_WRITE_O    <= FSM_WRITE_I when FSM_SELECT_I = '1' else IPBUS_I.ipb_write;
    -- DATA to ICAP
    ICAP_DATA_O     <= FSM_DATA_I  when FSM_SELECT_I = '1' else IPBUS_I.ipb_wdata;
    -- IPbus ACK
    IPBUS_O.ipb_ack <= '0'         when FSM_SELECT_I = '1' else ICAP_ACK_I;
    -- FSM ACK
    FSM_ACK_O       <= ICAP_ACK_I  when FSM_SELECT_I = '1' else '0';

end structural;
