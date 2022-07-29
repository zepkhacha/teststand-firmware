# ################
# L8 I/O Standards
# ################

set_property IOSTANDARD LVCMOS25 [get_ports aux_lemo_a]
set_property IOSTANDARD LVCMOS25 [get_ports aux_lemo_b]
set_property IOSTANDARD LVCMOS25 [get_ports fmc_l8_clk0]
set_property IOSTANDARD LVDS_25  [get_ports tr0_lemo_p]
set_property IOSTANDARD LVDS_25  [get_ports tr0_lemo_n]
set_property IOSTANDARD LVDS_25  [get_ports tr1_lemo_p]
set_property IOSTANDARD LVDS_25  [get_ports tr1_lemo_n]
#set_property IOSTANDARD LVCMOS25 [get_ports i2c_l8_scl]
#set_property IOSTANDARD LVCMOS25 [get_ports i2c_l8_sda]
#set_property IOSTANDARD LVCMOS25 [get_ports i2c_l8_rst]

#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led1[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led1[1]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led2[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led2[1]}]
#
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[3]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[4]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[5]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[6]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[7]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[8]}]

# ##################
# L8 Pin Assignments
# ##################

# OLD ASSIGNMENTS
#set_property PACKAGE_PIN AK26 [get_ports aux_lemo_a]
#set_property PACKAGE_PIN AK27 [get_ports aux_lemo_b]
#set_property PACKAGE_PIN AJ31 [get_ports fmc_l8_clk0]
#set_property PACKAGE_PIN AG33 [get_ports tr0_lemo_p]
#set_property PACKAGE_PIN AH33 [get_ports tr0_lemo_n]
#set_property PACKAGE_PIN AM27 [get_ports tr1_lemo_p]
#set_property PACKAGE_PIN AM28 [get_ports tr1_lemo_n]
#set_property PACKAGE_PIN AC32 [get_ports i2c_l8_scl]
#set_property PACKAGE_PIN AC33 [get_ports i2c_l8_sda]
#set_property PACKAGE_PIN AE31 [get_ports i2c_l8_rst]
#
#set_property PACKAGE_PIN AF30 [get_ports {fmc_l8_led1[0]}]
#set_property PACKAGE_PIN AG30 [get_ports {fmc_l8_led1[1]}]
#set_property PACKAGE_PIN AM33 [get_ports {fmc_l8_led2[0]}]
#set_property PACKAGE_PIN AN34 [get_ports {fmc_l8_led2[1]}]
#
#set_property PACKAGE_PIN AL31 [get_ports {fmc_l8_led[3]}]
#set_property PACKAGE_PIN AL30 [get_ports {fmc_l8_led[4]}]
#set_property PACKAGE_PIN AL33 [get_ports {fmc_l8_led[5]}]
#set_property PACKAGE_PIN AK33 [get_ports {fmc_l8_led[6]}]
#set_property PACKAGE_PIN AF34 [get_ports {fmc_l8_led[7]}]
#set_property PACKAGE_PIN AE34 [get_ports {fmc_l8_led[8]}]

# NEW ASSIGNMENTS
# OUTPUT BANK A
set_property PACKAGE_PIN AE33 [get_ports {fmc_header_p[31]}] #B30
set_property PACKAGE_PIN AL30 [get_ports {fmc_header_p[27]}] #H32
set_property PACKAGE_PIN AK28 [get_ports {fmc_header_p[23]}] #L33
set_property PACKAGE_PIN AG33 [get_ports {fmc_header_p[19]}] #B33
set_property PACKAGE_PIN AH34 [get_ports {fmc_header_p[15]}] #J34
set_property PACKAGE_PIN AL29 [get_ports {fmc_header_p[11]}] #L34
set_property PACKAGE_PIN AP29 [get_ports {fmc_header_p[7]}]  #P34
set_property PACKAGE_PIN AM23 [get_ports {fmc_header_p[3]}]  #R32

# OUTPUT BANK B
set_property PACKAGE_PIN AC34 [get_ports {fmc_header_p[30]}] #D29
set_property PACKAGE_PIN AK33 [get_ports {fmc_header_p[26]}] #H29
set_property PACKAGE_PIN AF30 [get_ports {fmc_header_p[22]}] #N32
set_property PACKAGE_PIN AL25 [get_ports {fmc_header_p[18]}] #E31
set_property PACKAGE_PIN AN32 [get_ports {fmc_header_p[14]}] #F33
set_property PACKAGE_PIN AP31 [get_ports {fmc_header_p[10]}] #P30
set_property PACKAGE_PIN AN25 [get_ports {fmc_header_p[6]}]  #R33
set_property PACKAGE_PIN AK24 [get_ports {fmc_header_p[2]}]  #T30

# OUTPUT BANK C
set_property PACKAGE_PIN AJ29 [get_ports {fmc_header_p[29]}] #B31
set_property PACKAGE_PIN AE34 [get_ports {fmc_header_p[25]}] #C32
set_property PACKAGE_PIN AM33 [get_ports {fmc_header_p[21]}] #L31
set_property PACKAGE_PIN AK26 [get_ports {fmc_header_p[17]}] #E32
set_property PACKAGE_PIN AK34 [get_ports {fmc_header_p[13]}] #F34
set_property PACKAGE_PIN AN29 [get_ports {fmc_header_p[9]}]  #M30
set_property PACKAGE_PIN AP26 [get_ports {fmc_header_p[5]}]  #N33
set_property PACKAGE_PIN AG32 [get_ports {fmc_header_p[1]}]  #T28

# OUTPUT BANK D
set_property PACKAGE_PIN AD31 [get_ports {fmc_header_p[28]}] #F29
set_property PACKAGE_PIN AH30 [get_ports {fmc_header_p[24]}] #G31
set_property PACKAGE_PIN AM27 [get_ports {fmc_header_p[20]}] #D34
set_property PACKAGE_PIN AJ32 [get_ports {fmc_header_p[16]}] #H33
set_property PACKAGE_PIN AM25 [get_ports {fmc_header_p[12]}] #K32
set_property PACKAGE_PIN AN27 [get_ports {fmc_header_p[8]}]  #T33
set_property PACKAGE_PIN AN24 [get_ports {fmc_header_p[4]}]  #U32
set_property PACKAGE_PIN AF31 [get_ports {fmc_header_p[0]}]  #R28

# INPUT BANK A
set_property PACKAGE_PIN AF33 [get_ports {fmc_header_n[31]}] #A31
set_property PACKAGE_PIN AL31 [get_ports {fmc_header_n[27]}] #G32
set_property PACKAGE_PIN AL28 [get_ports {fmc_header_n[23]}] #K33
set_property PACKAGE_PIN AH33 [get_ports {fmc_header_n[19]}] #A33
set_property PACKAGE_PIN AJ34 [get_ports {fmc_header_n[15]}] #H34
set_property PACKAGE_PIN AM30 [get_ports {fmc_header_n[11]}] #K34
set_property PACKAGE_PIN AP30 [get_ports {fmc_header_n[7]}]  #N34
set_property PACKAGE_PIN AN23 [get_ports {fmc_header_n[3]}]  #P32

# INPUT BANK B
set_property PACKAGE_PIN AD34 [get_ports {fmc_header_n[30]}]
set_property PACKAGE_PIN AL33 [get_ports {fmc_header_n[26]}]
set_property PACKAGE_PIN AG30 [get_ports {fmc_header_n[22]}]
set_property PACKAGE_PIN AL26 [get_ports {fmc_header_n[18]}]
set_property PACKAGE_PIN AP33 [get_ports {fmc_header_n[14]}]
set_property PACKAGE_PIN AP32 [get_ports {fmc_header_n[10]}]
set_property PACKAGE_PIN AP25 [get_ports {fmc_header_n[6]}]
set_property PACKAGE_PIN AL24 [get_ports {fmc_header_n[2]}]

# INPUT BANK C
set_property PACKAGE_PIN AK29 [get_ports {fmc_header_n[29]}]
set_property PACKAGE_PIN AF34 [get_ports {fmc_header_n[25]}]
set_property PACKAGE_PIN AN34 [get_ports {fmc_header_n[21]}]
set_property PACKAGE_PIN AK27 [get_ports {fmc_header_n[17]}]
set_property PACKAGE_PIN AL34 [get_ports {fmc_header_n[13]}]
set_property PACKAGE_PIN AN30 [get_ports {fmc_header_n[9]}]
set_property PACKAGE_PIN AP27 [get_ports {fmc_header_n[5]}]
set_property PACKAGE_PIN AH32 [get_ports {fmc_header_n[1]}]

# INPUT BANK D
set_property PACKAGE_PIN AD32 [get_ports {fmc_header_n[28]}]
set_property PACKAGE_PIN AJ30 [get_ports {fmc_header_n[24]}]
set_property PACKAGE_PIN AM28 [get_ports {fmc_header_n[20]}]
set_property PACKAGE_PIN AK32 [get_ports {fmc_header_n[16]}]
set_property PACKAGE_PIN AM26 [get_ports {fmc_header_n[12]}]
set_property PACKAGE_PIN AN28 [get_ports {fmc_header_n[8]}]
set_property PACKAGE_PIN AP24 [get_ports {fmc_header_n[4]}]
set_property PACKAGE_PIN AG31 [get_ports {fmc_header_n[0]}]

# #################
# L12 I/O Standards
# #################

set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_p[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_rx_n[7]}]

set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_p[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {sfp_l12_tx_n[7]}]

set_property IOSTANDARD LVCMOS25 [get_ports i2c_l12_scl]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_l12_sda]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_l12_rst]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_l12_int]

# #########################
# L12 Additional Properties
# #########################

# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[0]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[0]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[1]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[1]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[2]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[2]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[3]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[3]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[4]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[4]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[5]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[5]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[6]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[6]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_p[7]}]
# set_property DIFF_TERM TRUE [get_ports {sfp_l12_rx_n[7]}]

# ###################
# L12 Pin Assignments
# ###################

set_property PACKAGE_PIN T28 [get_ports {sfp_l12_rx_p[0]}]
set_property PACKAGE_PIN T29 [get_ports {sfp_l12_rx_n[0]}]
set_property PACKAGE_PIN R32 [get_ports {sfp_l12_rx_p[1]}]
set_property PACKAGE_PIN P32 [get_ports {sfp_l12_rx_n[1]}]
set_property PACKAGE_PIN N33 [get_ports {sfp_l12_rx_p[2]}]
set_property PACKAGE_PIN M33 [get_ports {sfp_l12_rx_n[2]}]
set_property PACKAGE_PIN P34 [get_ports {sfp_l12_rx_p[3]}]
set_property PACKAGE_PIN N34 [get_ports {sfp_l12_rx_n[3]}]
set_property PACKAGE_PIN M30 [get_ports {sfp_l12_rx_p[4]}]
set_property PACKAGE_PIN M31 [get_ports {sfp_l12_rx_n[4]}]
set_property PACKAGE_PIN L34 [get_ports {sfp_l12_rx_p[5]}]
set_property PACKAGE_PIN K34 [get_ports {sfp_l12_rx_n[5]}]
set_property PACKAGE_PIN F34 [get_ports {sfp_l12_rx_p[6]}]
set_property PACKAGE_PIN E34 [get_ports {sfp_l12_rx_n[6]}]
set_property PACKAGE_PIN J34 [get_ports {sfp_l12_rx_p[7]}]
set_property PACKAGE_PIN H34 [get_ports {sfp_l12_rx_n[7]}]

set_property PACKAGE_PIN T30 [get_ports {sfp_l12_tx_p[0]}]
set_property PACKAGE_PIN T31 [get_ports {sfp_l12_tx_n[0]}]
set_property PACKAGE_PIN U32 [get_ports {sfp_l12_tx_p[1]}]
set_property PACKAGE_PIN U33 [get_ports {sfp_l12_tx_n[1]}]
set_property PACKAGE_PIN R33 [get_ports {sfp_l12_tx_p[2]}]
set_property PACKAGE_PIN R34 [get_ports {sfp_l12_tx_n[2]}]
set_property PACKAGE_PIN T33 [get_ports {sfp_l12_tx_p[3]}]
set_property PACKAGE_PIN T34 [get_ports {sfp_l12_tx_n[3]}]
set_property PACKAGE_PIN P30 [get_ports {sfp_l12_tx_p[4]}]
set_property PACKAGE_PIN N30 [get_ports {sfp_l12_tx_n[4]}]
set_property PACKAGE_PIN K32 [get_ports {sfp_l12_tx_p[5]}]
set_property PACKAGE_PIN J32 [get_ports {sfp_l12_tx_n[5]}]
set_property PACKAGE_PIN F33 [get_ports {sfp_l12_tx_p[6]}]
set_property PACKAGE_PIN E33 [get_ports {sfp_l12_tx_n[6]}]
set_property PACKAGE_PIN H33 [get_ports {sfp_l12_tx_p[7]}]
set_property PACKAGE_PIN G33 [get_ports {sfp_l12_tx_n[7]}]

set_property PACKAGE_PIN A29 [get_ports i2c_l12_scl]
set_property PACKAGE_PIN A30 [get_ports i2c_l12_sda]
set_property PACKAGE_PIN C29 [get_ports i2c_l12_rst]
set_property PACKAGE_PIN C30 [get_ports i2c_l12_int]
