#set_property package_pin am17    [get_ports osc_sata_scl]
#set_property iostandard lvcmos25 [get_ports osc_sata_scl]

#set_property package_pin am18    [get_ports osc_sata_sda]
#set_property iostandard lvcmos25 [get_ports osc_sata_sda]

#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {amc_tx_n[1]}]
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {amc_tx_p[1]}]

set_property PACKAGE_PIN AF5 [get_ports {k7_amc_rx_n[1]}]
set_property PACKAGE_PIN AF6 [get_ports {k7_amc_rx_p[1]}]
set_property PACKAGE_PIN AH1 [get_ports {amc_tx_n[1]}]
set_property PACKAGE_PIN AH2 [get_ports {amc_tx_p[1]}]
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {k7_amc_rx_p[1]}]
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports {k7_amc_rx_n[1]}]


set_property PACKAGE_PIN AG17 [get_ports {amc_tx_n[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_n[12]}]
set_property PACKAGE_PIN AK21 [get_ports {amc_tx_n[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_n[13]}]
set_property PACKAGE_PIN AG21 [get_ports {amc_tx_n[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_n[14]}]
set_property PACKAGE_PIN AH23 [get_ports {amc_tx_n[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_n[15]}]

set_property PACKAGE_PIN AG16 [get_ports {amc_tx_p[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_p[12]}]
set_property PACKAGE_PIN AJ21 [get_ports {amc_tx_p[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_p[13]}]
set_property PACKAGE_PIN AG20 [get_ports {amc_tx_p[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_p[14]}]
set_property PACKAGE_PIN AG23 [get_ports {amc_tx_p[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {amc_tx_p[15]}]

set_property PACKAGE_PIN AH18 [get_ports {k7_amc_rx_n[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_n[12]}]
set_property PACKAGE_PIN AK22 [get_ports {k7_amc_rx_n[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_n[13]}]
set_property PACKAGE_PIN AJ20 [get_ports {k7_amc_rx_n[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_n[14]}]
set_property PACKAGE_PIN AH22 [get_ports {k7_amc_rx_n[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_n[15]}]

set_property PACKAGE_PIN AH17 [get_ports {k7_amc_rx_p[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_p[12]}]
set_property PACKAGE_PIN AJ22 [get_ports {k7_amc_rx_p[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_p[13]}]
set_property PACKAGE_PIN AH20 [get_ports {k7_amc_rx_p[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_p[14]}]
set_property PACKAGE_PIN AG22 [get_ports {k7_amc_rx_p[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_amc_rx_p[15]}]



set_property PACKAGE_PIN AK23 [get_ports k7_fabric_amc_rx_p03]
set_property PACKAGE_PIN AL23 [get_ports k7_fabric_amc_rx_n03]
set_property IOSTANDARD LVDS_25 [get_ports k7_fabric_amc_rx_p03]
set_property IOSTANDARD LVDS_25 [get_ports k7_fabric_amc_rx_n03]

set_property PACKAGE_PIN AN22 [get_ports k7_fabric_amc_tx_n03]
set_property IOSTANDARD LVCMOS25 [get_ports k7_fabric_amc_tx_n03]

set_property PACKAGE_PIN AM22 [get_ports k7_fabric_amc_tx_p03]
set_property IOSTANDARD LVCMOS25 [get_ports k7_fabric_amc_tx_p03]

set_property IOSTANDARD LVDS_25 [get_ports fpga_refclkout_n]

set_property PACKAGE_PIN AL20 [get_ports fpga_refclkout_p]
set_property PACKAGE_PIN AM20 [get_ports fpga_refclkout_n]
set_property IOSTANDARD LVDS_25 [get_ports fpga_refclkout_p]

#set_property PACKAGE_PIN AN24 [get_ports {fmc_l8_la_p[4]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[4]}]
#set_property PACKAGE_PIN AP24 [get_ports {fmc_l8_la_n[4]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[4]}]

#set_property PACKAGE_PIN AP26 [get_ports {fmc_l8_la_p[5]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[5]}]
#set_property PACKAGE_PIN AP27 [get_ports {fmc_l8_la_n[5]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[5]}]

#set_property PACKAGE_PIN AN25 [get_ports {fmc_l8_la_p[6]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[6]}]
#set_property PACKAGE_PIN AP25 [get_ports {fmc_l8_la_n[6]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[6]}]

#set_property PACKAGE_PIN AP29 [get_ports {fmc_l8_la_p[7]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[7]}]
#set_property PACKAGE_PIN AP30 [get_ports {fmc_l8_la_n[7]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[7]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[19]}]
set_property PACKAGE_PIN AG33 [get_ports {fmc_l8_la_p[19]}]
set_property PACKAGE_PIN AH33 [get_ports {fmc_l8_la_n[19]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l8_la_p[19]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[19]}]

#set_property PACKAGE_PIN AN27 [get_ports {fmc_l8_la_p[8]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[8]}]
#set_property PACKAGE_PIN AN28 [get_ports {fmc_l8_la_n[8]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[8]}]

#set_property PACKAGE_PIN AN29 [get_ports {fmc_l8_la_p[9]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[9]}]
#set_property PACKAGE_PIN AN30 [get_ports {fmc_l8_la_n[9]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[9]}]

#set_property PACKAGE_PIN AL29 [get_ports {fmc_l8_la_p[11]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[11]}]
#set_property PACKAGE_PIN AM30 [get_ports {fmc_l8_la_n[11]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[11]}]

#set_property PACKAGE_PIN AH34 [get_ports {fmc_l8_la_p[15]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[15]}]
#set_property PACKAGE_PIN AJ34 [get_ports {fmc_l8_la_n[15]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[15]}]

set_property PACKAGE_PIN AK26 [get_ports {fmc_l8_la_p[17]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[17]}]
set_property PACKAGE_PIN AK27 [get_ports {fmc_l8_la_n[17]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[17]}]

#set_property PACKAGE_PIN AH30 [get_ports {fmc_l8_la_p[24]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[24]}]
#set_property PACKAGE_PIN AJ30 [get_ports {fmc_l8_la_n[24]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[24]}]

#set_property PACKAGE_PIN AD31 [get_ports {fmc_l8_la_p[28]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[28]}]
#set_property PACKAGE_PIN AD32 [get_ports {fmc_l8_la_n[28]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[28]}]

#set_property PACKAGE_PIN AJ29 [get_ports {fmc_l8_la_p[29]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[29]}]
#set_property PACKAGE_PIN AK29 [get_ports {fmc_l8_la_n[29]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[29]}]

#set_property PACKAGE_PIN AC34 [get_ports {fmc_l8_la_p[30]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[30]}]
#set_property PACKAGE_PIN AD34 [get_ports {fmc_l8_la_n[30]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_n[30]}]

#set_property PACKAGE_PIN AE31 [get_ports {fmc_l8_la_p[33]}]
#set_property PACKAGE_PIN AE32 [get_ports {fmc_l8_la_n[33]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l8_la_p[33]}]

#set_property PACKAGE_PIN AM27 [get_ports {fmc_l8_la_p[20]}]
#set_property PACKAGE_PIN AM28 [get_ports {fmc_l8_la_n[20]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l8_la_p[20]}]

#set_property PACKAGE_PIN AJ32 [get_ports {fmc_l8_la_p[16]}]
#set_property PACKAGE_PIN AK32 [get_ports {fmc_l8_la_n[16]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l8_la_p[16]}]

#set_property PACKAGE_PIN AM23 [get_ports {fmc_l8_la_p[3]}]
#set_property PACKAGE_PIN AN23 [get_ports {fmc_l8_la_n[3]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l8_la_p[3]}]

#set_property PACKAGE_PIN AF31 [get_ports {fmc_l8_la_p[0]}]
#set_property PACKAGE_PIN AG31 [get_ports {fmc_l8_la_n[0]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l8_la_p[0]}]

#set_property PACKAGE_PIN AF31 [get_ports {fmc_l8_la_p[0]}]
#set_property PACKAGE_PIN AG31 [get_ports {fmc_l8_la_n[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_la_p[0]}]

#set_property PACKAGE_PIN AJ26 [get_ports {fmc_l8_clk1}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_clk1}]

set_property PACKAGE_PIN AJ31 [get_ports fmc_l8_clk0]
set_property IOSTANDARD LVCMOS25 [get_ports fmc_l8_clk0]

set_property PACKAGE_PIN E31 [get_ports {fmc_l12_la_p[18]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[18]}]
set_property PACKAGE_PIN D31 [get_ports {fmc_l12_la_n[18]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[18]}]

set_property PACKAGE_PIN B33 [get_ports {fmc_l12_la_p[19]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[19]}]
set_property PACKAGE_PIN A33 [get_ports {fmc_l12_la_n[19]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[19]}]

set_property PACKAGE_PIN E32 [get_ports {fmc_l12_la_p[17]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[17]}]

set_property PACKAGE_PIN T30 [get_ports {fmc_l12_la_p[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[2]}]
set_property PACKAGE_PIN T31 [get_ports {fmc_l12_la_n[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[2]}]

set_property PACKAGE_PIN U32 [get_ports {fmc_l12_la_p[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[4]}]
set_property PACKAGE_PIN U33 [get_ports {fmc_l12_la_n[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[4]}]


set_property PACKAGE_PIN R33 [get_ports {fmc_l12_la_p[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[6]}]
set_property PACKAGE_PIN R34 [get_ports {fmc_l12_la_n[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[6]}]

set_property PACKAGE_PIN T33 [get_ports {fmc_l12_la_p[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[8]}]
set_property PACKAGE_PIN T34 [get_ports {fmc_l12_la_n[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[8]}]

set_property PACKAGE_PIN P30 [get_ports {fmc_l12_la_p[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[10]}]
set_property PACKAGE_PIN N30 [get_ports {fmc_l12_la_n[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[10]}]

set_property PACKAGE_PIN K32 [get_ports {fmc_l12_la_p[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[12]}]
set_property PACKAGE_PIN J32 [get_ports {fmc_l12_la_n[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[12]}]

set_property PACKAGE_PIN F33 [get_ports {fmc_l12_la_p[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[14]}]
set_property PACKAGE_PIN E33 [get_ports {fmc_l12_la_n[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[14]}]

set_property PACKAGE_PIN H33 [get_ports {fmc_l12_la_p[16]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[16]}]
set_property PACKAGE_PIN G33 [get_ports {fmc_l12_la_n[16]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[16]}]

set_property PACKAGE_PIN A29 [get_ports {fmc_l12_la_p[32]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[32]}]
set_property PACKAGE_PIN A30 [get_ports {fmc_l12_la_n[32]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[32]}]

set_property PACKAGE_PIN C29 [get_ports {fmc_l12_la_p[33]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[33]}]
set_property PACKAGE_PIN C30 [get_ports {fmc_l12_la_n[33]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[33]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[1]}]
set_property PACKAGE_PIN T28 [get_ports {fmc_l12_la_p[1]}]
set_property PACKAGE_PIN T29 [get_ports {fmc_l12_la_n[1]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[1]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[3]}]
set_property PACKAGE_PIN R32 [get_ports {fmc_l12_la_p[3]}]
set_property PACKAGE_PIN P32 [get_ports {fmc_l12_la_n[3]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[3]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[5]}]
set_property PACKAGE_PIN N33 [get_ports {fmc_l12_la_p[5]}]
set_property PACKAGE_PIN M33 [get_ports {fmc_l12_la_n[5]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[5]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[7]}]
set_property PACKAGE_PIN P34 [get_ports {fmc_l12_la_p[7]}]
set_property PACKAGE_PIN N34 [get_ports {fmc_l12_la_n[7]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[7]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[9]}]
set_property PACKAGE_PIN M30 [get_ports {fmc_l12_la_p[9]}]
set_property PACKAGE_PIN M31 [get_ports {fmc_l12_la_n[9]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[9]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[9]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[11]}]
set_property PACKAGE_PIN L34 [get_ports {fmc_l12_la_p[11]}]
set_property PACKAGE_PIN K34 [get_ports {fmc_l12_la_n[11]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[11]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[11]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[13]}]
set_property PACKAGE_PIN F34 [get_ports {fmc_l12_la_p[13]}]
set_property PACKAGE_PIN E34 [get_ports {fmc_l12_la_n[13]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[13]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[13]}]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_p[15]}]
set_property PACKAGE_PIN J34 [get_ports {fmc_l12_la_p[15]}]
set_property PACKAGE_PIN H34 [get_ports {fmc_l12_la_n[15]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_la_n[15]}]
set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[15]}]

#set_property PACKAGE_PIN A29 [get_ports {fmc_l12_la_p[32]}]
#set_property PACKAGE_PIN A30 [get_ports {fmc_l12_la_n[32]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[32]}]

#set_property PACKAGE_PIN C29 [get_ports {fmc_l12_la_p[33]}]
#set_property PACKAGE_PIN C30 [get_ports {fmc_l12_la_n[33]}]
#set_property IOSTANDARD LVDS_25 [get_ports {fmc_l12_la_p[33]}]



