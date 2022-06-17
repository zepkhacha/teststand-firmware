-- the ipbus bus fabric, address select logic, data multiplexers
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.ipbus.all;

use work.ipbus_addr_decode.all;
use work.user_addr_decode.all;


entity ipbus_sys_fabric is
  generic(
    n_sys_slv				: positive;
    n_usr_slv				: positive;
	 usr_base_addr			: std_logic_vector(31 downto 0):= x"4000_0000";
    strobe_gap				: boolean := false);
  port(
    ipb_clk, rst			: in 	std_logic;
    ipb_in					: in 	ipb_wbus;
    ipb_out					: out ipb_rbus;
    ipb_to_slaves			: out ipb_wbus_array(0 to n_sys_slv+n_usr_slv-1);
    ipb_from_slaves		: in 	ipb_rbus_array(0 to n_sys_slv+n_usr_slv-1));

end ipbus_sys_fabric;

architecture rtl of ipbus_sys_fabric is

	signal sel						: integer;
	type mux_rdata_t 				is array(0 to n_sys_slv+n_usr_slv) of std_logic_vector(31 downto 0);
	signal mux_rdata				: mux_rdata_t;
	signal ored_ack, ored_err	: std_logic_vector(0 to n_sys_slv+n_usr_slv);
	signal qstrobe					: std_logic;

begin

	process(ipb_in.ipb_addr)
	begin
		if unsigned(ipb_in.ipb_addr) < unsigned(usr_base_addr) then
			sel <=    ipbus_addr_sel(ipb_in.ipb_addr);			 else
			sel <= user_ipb_addr_sel(ipb_in.ipb_addr) + n_sys_slv;
		end if;
	end process;

	mux_rdata(n_sys_slv+n_usr_slv) <= (others => '0');
	ored_ack	(n_sys_slv+n_usr_slv) <= '0';
	ored_err	(n_sys_slv+n_usr_slv) <= '0';
	
	qstrobe <= ipb_in.ipb_strobe when strobe_gap = false else
	 ipb_in.ipb_strobe and not (ored_ack(0) or ored_err(0));

	busgen: for i in n_sys_slv+n_usr_slv-1 downto 0 generate
		signal qual_rdata: std_logic_vector(31 downto 0);
	begin

		ipb_to_slaves(i).ipb_addr 		<= ipb_in.ipb_addr;
		ipb_to_slaves(i).ipb_wdata 	<= ipb_in.ipb_wdata;
		ipb_to_slaves(i).ipb_strobe 	<= qstrobe when sel=i else '0';
		ipb_to_slaves(i).ipb_write 	<= ipb_in.ipb_write;

		qual_rdata 		<= ipb_from_slaves(i).ipb_rdata when sel=i else (others => '0');
		mux_rdata(i) 	<= qual_rdata 		or mux_rdata(i+1);
		ored_ack(i) 	<= ored_ack(i+1) 	or ipb_from_slaves(i).ipb_ack;
		ored_err(i) 	<= ored_err(i+1) 	or ipb_from_slaves(i).ipb_err;		

	end generate;

  ipb_out.ipb_rdata 	<= mux_rdata(0);
  ipb_out.ipb_ack 	<= ored_ack(0);
  ipb_out.ipb_err 	<= ored_err(0);
  
end rtl;

