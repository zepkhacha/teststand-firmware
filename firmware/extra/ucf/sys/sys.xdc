##############################
# clocks
##############################

create_clock -period 16.000 -name eth_txoutclk [get_pins sys/eth/bufg_tx/O]
#
set_property PACKAGE_PIN AD6 [get_ports osc125_a_p]
create_clock -period 8.000 -name osc125_a [get_ports osc125_a_p]
#
set_property PACKAGE_PIN U8 [get_ports osc125_b_p]
create_clock -period 8.000 -name osc125_b [get_ports osc125_b_p]


###### SWEIGART - addition - START #####
# DAQ_Link_7S (README said to include this line)
#create_clock -period 4.000 -name DAQ_usrclk [get_pins daq/i_UsrClk/O]
# TTC clock
#create_clock -period 25.000 -name fabric_clk [get_ports fabric_clk_p]
# Separate asynchronous clock domains
#set_clock_groups -name async_clks -asynchronous -group [get_clocks -include_generated_clocks osc125_a_bufg_i] -group [get_clocks -include_generated_clocks fabric_clk]
###### SWEIGART - addition - END #####

#
#set_clock_groups -asynchronous #    -group [get_clocks -include_generated_clocks eth_txoutclk] #    -group [get_clocks -include_generated_clocks osc125_a] #    -group [get_clocks -include_generated_clocks osc125_b]
##############################
# resets / timing ignore
##############################
#
set_false_path -through [get_ports sw3]
set_false_path -through [get_cells sys/clocks/rst_reg]
set_false_path -through [get_cells sys/clocks/nuke_i_reg]
set_false_path -through [get_cells sys/clocks/rst_ipb_reg]
set_false_path -through [get_cells sys/clocks/rst_eth_reg]
set_false_path -through [get_cells sys/uc_if/uc_pipe_if/reset_ipbus_to_pipe_reg]
set_false_path -through [get_cells sys/uc_if/uc_pipe_if/reset_pipe_to_ipbus_reg]

##############################
# cdce phase monitoring
##############################
#
# set_property BEL AFF [get_cells usr/cdce_synch/sync_o_reg]
# set_property LOC SLICE_X93Y139 [get_cells usr/cdce_synch/sync_o_reg]

##############################
# mgt
##############################
#
set_property PACKAGE_PIN AG3 [get_ports amc_rx_n0]
#
##############################
# i/o
##############################
#
set_property PACKAGE_PIN AN18 [get_ports {k7_master_xpoint_ctrl[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[0]}]

set_property PACKAGE_PIN AN17 [get_ports {k7_master_xpoint_ctrl[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[1]}]

set_property PACKAGE_PIN AM21 [get_ports {k7_master_xpoint_ctrl[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[2]}]

set_property PACKAGE_PIN AL21 [get_ports {k7_master_xpoint_ctrl[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[3]}]

set_property PACKAGE_PIN AP19 [get_ports {k7_master_xpoint_ctrl[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[4]}]

set_property PACKAGE_PIN AN19 [get_ports {k7_master_xpoint_ctrl[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[5]}]

set_property PACKAGE_PIN AP20 [get_ports {k7_master_xpoint_ctrl[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[6]}]

set_property PACKAGE_PIN AN20 [get_ports {k7_master_xpoint_ctrl[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[7]}]

set_property PACKAGE_PIN AP22 [get_ports {k7_master_xpoint_ctrl[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[8]}]

set_property PACKAGE_PIN AP21 [get_ports {k7_master_xpoint_ctrl[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[9]}]

set_property PACKAGE_PIN AL16 [get_ports {k7_pcie_clk_ctrl[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[0]}]

set_property PACKAGE_PIN AM16 [get_ports {k7_pcie_clk_ctrl[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[1]}]

set_property PACKAGE_PIN AJ16 [get_ports {k7_pcie_clk_ctrl[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[2]}]

set_property PACKAGE_PIN AJ17 [get_ports {k7_pcie_clk_ctrl[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[3]}]

set_property PACKAGE_PIN AP16 [get_ports k7_tclkb_en]
set_property IOSTANDARD LVCMOS25 [get_ports k7_tclkb_en]

set_property PACKAGE_PIN AP17 [get_ports k7_tclkd_en]
set_property IOSTANDARD LVCMOS25 [get_ports k7_tclkd_en]


set_property PACKAGE_PIN AC24 [get_ports cdce_sync_r1]
set_property IOSTANDARD LVCMOS33 [get_ports cdce_sync_r1]

set_property PACKAGE_PIN AJ27 [get_ports cdce_ctrla4_r1]
set_property IOSTANDARD LVCMOS25 [get_ports cdce_ctrla4_r1]

###### external phase mon #######
#set_property IOSTANDARD LVDS_25 [get_ports phase_mon_flag_p]
#set_property DIFF_TERM TRUE [get_ports phase_mon_flag_p]
#
#set_property PACKAGE_PIN AK17 [get_ports phase_mon_flag_n]
#set_property IOSTANDARD LVDS_25 [get_ports phase_mon_flag_n]
#set_property DIFF_TERM TRUE [get_ports phase_mon_flag_n]
#
#set_property IOSTANDARD LVDS_25 [get_ports monitoring_refclk_n]
#
#set_property PACKAGE_PIN AH19 [get_ports monitoring_refclk_p]
#set_property IOSTANDARD LVDS_25 [get_ports monitoring_refclk_p]

###### header & dipsw ###########
#
#set_property PACKAGE_PIN N28 [get_ports {fmc_l12_spare[0]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[0]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[0]}]
#
#set_property PACKAGE_PIN M28 [get_ports {fmc_l12_spare[1]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[1]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[1]}]
#
#set_property PACKAGE_PIN P29 [get_ports {fmc_l12_spare[2]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[2]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[2]}]
#
#set_property PACKAGE_PIN N29 [get_ports {fmc_l12_spare[3]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[3]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[3]}]
#
#set_property PACKAGE_PIN P27 [get_ports {fmc_l12_spare[4]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[4]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[4]}]
#
#set_property PACKAGE_PIN N27 [get_ports {fmc_l12_spare[5]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[5]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[5]}]
#
#set_property PACKAGE_PIN N24 [get_ports {fmc_l12_spare[6]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[6]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[6]}]
#
#set_property PACKAGE_PIN N25 [get_ports {fmc_l12_spare[7]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[7]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[7]}]
#


set_property PACKAGE_PIN P25 [get_ports {fmc_l12_spare[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[8]}]

set_property PACKAGE_PIN P26 [get_ports {fmc_l12_spare[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[9]}]

set_property PACKAGE_PIN R24 [get_ports {fmc_l12_spare[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[10]}]

set_property PACKAGE_PIN P24 [get_ports {fmc_l12_spare[11]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[11]}]

set_property PACKAGE_PIN R26 [get_ports {fmc_l12_spare[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[12]}]

set_property PACKAGE_PIN R27 [get_ports {fmc_l12_spare[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[13]}]
#
#set_property PACKAGE_PIN T25 [get_ports {fmc_l12_spare[14]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[14]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[14]}]
#
#set_property PACKAGE_PIN T26 [get_ports {fmc_l12_spare[15]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[15]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[15]}]
#
#set_property PACKAGE_PIN U25 [get_ports {fmc_l12_spare[16]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[16]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[16]}]
#
#set_property PACKAGE_PIN U26 [get_ports {fmc_l12_spare[17]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[17]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[17]}]
#
#set_property PACKAGE_PIN U27 [get_ports {fmc_l12_spare[18]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[18]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[18]}]
#
#set_property PACKAGE_PIN U28 [get_ports {fmc_l12_spare[19]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[19]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[19]}]
#
#set_property PACKAGE_PIN T24 [get_ports {fmc_l12_spare[20]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[20]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[20]}]
#
#set_property PACKAGE_PIN V24 [get_ports {fmc_l12_spare[21]}]
#set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l12_spare[21]}]
#set_property PULLUP true [get_ports {fmc_l12_spare[21]}]
#
set_property PACKAGE_PIN AH27 [get_ports {fmc_l8_spare[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[0]}]

set_property PACKAGE_PIN AH28 [get_ports {fmc_l8_spare[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[1]}]

set_property PACKAGE_PIN AH25 [get_ports {fmc_l8_spare[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[2]}]

set_property PACKAGE_PIN AJ25 [get_ports {fmc_l8_spare[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[3]}]

set_property PACKAGE_PIN AH24 [get_ports {fmc_l8_spare[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[4]}]

set_property PACKAGE_PIN AJ24 [get_ports {fmc_l8_spare[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[5]}]

set_property PACKAGE_PIN AG26 [get_ports {fmc_l8_spare[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[6]}]

set_property PACKAGE_PIN AG27 [get_ports {fmc_l8_spare[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[7]}]

set_property PACKAGE_PIN AG28 [get_ports {fmc_l8_spare[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[8]}]

set_property PACKAGE_PIN AH29 [get_ports {fmc_l8_spare[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[9]}]

set_property PACKAGE_PIN AF28 [get_ports {fmc_l8_spare[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[10]}]

set_property PACKAGE_PIN AF29 [get_ports {fmc_l8_spare[11]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[11]}]

set_property PACKAGE_PIN AE27 [get_ports {fmc_l8_spare[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[12]}]

set_property PACKAGE_PIN AE28 [get_ports {fmc_l8_spare[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[13]}]

set_property PACKAGE_PIN AE26 [get_ports {fmc_l8_spare[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[14]}]

set_property PACKAGE_PIN AF26 [get_ports {fmc_l8_spare[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[15]}]

set_property PACKAGE_PIN AE24 [get_ports {fmc_l8_spare[16]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[16]}]

set_property PACKAGE_PIN AF24 [get_ports {fmc_l8_spare[17]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[17]}]

set_property PACKAGE_PIN AF25 [get_ports {fmc_l8_spare[18]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[18]}]

set_property PACKAGE_PIN AG25 [get_ports {fmc_l8_spare[19]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_l8_spare[19]}]

set_property PACKAGE_PIN AB26 [get_ports local_i2c_scl]
set_property IOSTANDARD LVCMOS33 [get_ports local_i2c_scl]

set_property PACKAGE_PIN AB27 [get_ports local_i2c_sda]
set_property IOSTANDARD LVCMOS33 [get_ports local_i2c_sda]

set_property PACKAGE_PIN AA24 [get_ports sysled1_r]
set_property IOSTANDARD LVCMOS33 [get_ports sysled1_r]

set_property PACKAGE_PIN V27 [get_ports sysled1_g]
set_property IOSTANDARD LVCMOS33 [get_ports sysled1_g]

set_property PACKAGE_PIN AA31 [get_ports sysled1_b]
set_property IOSTANDARD LVCMOS33 [get_ports sysled1_b]

set_property PACKAGE_PIN AA29 [get_ports sysled2_r]
set_property IOSTANDARD LVCMOS33 [get_ports sysled2_r]

set_property PACKAGE_PIN Y28 [get_ports sysled2_g]
set_property IOSTANDARD LVCMOS33 [get_ports sysled2_g]

set_property PACKAGE_PIN Y29 [get_ports sysled2_b]
set_property IOSTANDARD LVCMOS33 [get_ports sysled2_b]

set_property PACKAGE_PIN AC27 [get_ports fmc_l12_pg_m2c]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l12_pg_m2c]

set_property PACKAGE_PIN AB25 [get_ports fmc_l12_prsnt_l]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l12_prsnt_l]

set_property PACKAGE_PIN AC25 [get_ports fmc_l12_pwr_en]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l12_pwr_en]

set_property PACKAGE_PIN AC28 [get_ports fmc_l8_pg_m2c]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l8_pg_m2c]

set_property PACKAGE_PIN AD27 [get_ports fmc_l8_prsnt_l]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l8_prsnt_l]

set_property PACKAGE_PIN AD26 [get_ports fmc_l8_pwr_en]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l8_pwr_en]

set_property PACKAGE_PIN AC29 [get_ports fmc_pg_c2m]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_pg_c2m]

set_property PACKAGE_PIN AB28 [get_ports fmc_i2c_scl]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_i2c_scl]

set_property PACKAGE_PIN AA25 [get_ports fmc_i2c_sda]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_i2c_sda]

set_property PACKAGE_PIN AA28 [get_ports sw3]
set_property IOSTANDARD LVCMOS33 [get_ports sw3]

set_property PACKAGE_PIN AA26 [get_ports pca8574_int]
set_property IOSTANDARD LVCMOS33 [get_ports pca8574_int]

set_property PACKAGE_PIN Y32 [get_ports {cpld2fpga_gpio[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpld2fpga_gpio[0]}]

set_property PACKAGE_PIN AB32 [get_ports {cpld2fpga_gpio[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpld2fpga_gpio[1]}]

set_property PACKAGE_PIN AB33 [get_ports {cpld2fpga_gpio[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpld2fpga_gpio[2]}]

set_property PACKAGE_PIN AA30 [get_ports {cpld2fpga_gpio[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpld2fpga_gpio[3]}]

set_property PACKAGE_PIN Y27 [get_ports cpld2fpga_ebi_nrd]
set_property IOSTANDARD LVCMOS33 [get_ports cpld2fpga_ebi_nrd]

set_property PACKAGE_PIN W27 [get_ports cpld2fpga_ebi_nwe_0]
set_property IOSTANDARD LVCMOS33 [get_ports cpld2fpga_ebi_nwe_0]

set_property PACKAGE_PIN AA33 [get_ports {fpga_config_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[0]}]

set_property PACKAGE_PIN AA34 [get_ports {fpga_config_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[1]}]

set_property PACKAGE_PIN Y33 [get_ports {fpga_config_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[2]}]

set_property PACKAGE_PIN Y34 [get_ports {fpga_config_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[3]}]

set_property PACKAGE_PIN V32 [get_ports {fpga_config_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[4]}]

set_property PACKAGE_PIN V33 [get_ports {fpga_config_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[5]}]

set_property PACKAGE_PIN W31 [get_ports {fpga_config_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[6]}]

set_property PACKAGE_PIN W32 [get_ports {fpga_config_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[7]}]

set_property PACKAGE_PIN W30 [get_ports {fpga_config_data[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[8]}]

set_property PACKAGE_PIN V25 [get_ports {fpga_config_data[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[9]}]

set_property PACKAGE_PIN W25 [get_ports {fpga_config_data[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[10]}]

set_property PACKAGE_PIN V29 [get_ports {fpga_config_data[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[11]}]

set_property PACKAGE_PIN W29 [get_ports {fpga_config_data[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[12]}]

set_property PACKAGE_PIN V28 [get_ports {fpga_config_data[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[13]}]

set_property PACKAGE_PIN W24 [get_ports {fpga_config_data[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[14]}]

set_property PACKAGE_PIN Y24 [get_ports {fpga_config_data[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {fpga_config_data[15]}]

set_operating_conditions -board_layers 16+
set_operating_conditions -board custom



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

