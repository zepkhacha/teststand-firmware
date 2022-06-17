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
set_property IOSTANDARD LVCMOS25 [get_ports i2c_l8_scl]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_l8_sda]
set_property IOSTANDARD LVCMOS25 [get_ports i2c_l8_rst]

set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led1[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led1[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led2[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led2[1]}]

set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_led[8]}]

# ##################
# L8 Pin Assignments
# ##################

set_property PACKAGE_PIN AK26 [get_ports aux_lemo_a]
set_property PACKAGE_PIN AK27 [get_ports aux_lemo_b]
set_property PACKAGE_PIN AJ31 [get_ports fmc_l8_clk0]
set_property PACKAGE_PIN AG33 [get_ports tr0_lemo_p]
set_property PACKAGE_PIN AH33 [get_ports tr0_lemo_n]
set_property PACKAGE_PIN AM27 [get_ports tr1_lemo_p]
set_property PACKAGE_PIN AM28 [get_ports tr1_lemo_n]
set_property PACKAGE_PIN AC32 [get_ports i2c_l8_scl]
set_property PACKAGE_PIN AC33 [get_ports i2c_l8_sda]
set_property PACKAGE_PIN AE31 [get_ports i2c_l8_rst]

set_property PACKAGE_PIN AF30 [get_ports {fmc_l8_led1[0]}]
set_property PACKAGE_PIN AG30 [get_ports {fmc_l8_led1[1]}]
set_property PACKAGE_PIN AM33 [get_ports {fmc_l8_led2[0]}]
set_property PACKAGE_PIN AN34 [get_ports {fmc_l8_led2[1]}]

set_property PACKAGE_PIN AL31 [get_ports {fmc_l8_led[3]}]
set_property PACKAGE_PIN AL30 [get_ports {fmc_l8_led[4]}]
set_property PACKAGE_PIN AL33 [get_ports {fmc_l8_led[5]}]
set_property PACKAGE_PIN AK33 [get_ports {fmc_l8_led[6]}]
set_property PACKAGE_PIN AF34 [get_ports {fmc_l8_led[7]}]
set_property PACKAGE_PIN AE34 [get_ports {fmc_l8_led[8]}]

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
