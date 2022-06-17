# #############
# I/O Standards
# #############

set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_master_xpoint_ctrl[9]}]

set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {k7_pcie_clk_ctrl[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports k7_tclkb_en]
set_property IOSTANDARD LVCMOS25 [get_ports k7_tclkd_en]

set_property IOSTANDARD LVCMOS33 [get_ports cdce_sync_b]
set_property IOSTANDARD LVCMOS25 [get_ports cdce_sync_r0]
set_property IOSTANDARD LVCMOS25 [get_ports cdce_ref_sel]
set_property IOSTANDARD LVCMOS25 [get_ports cdce_pwrdown]
set_property IOSTANDARD LVCMOS25 [get_ports {cdce_xpoint[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {cdce_xpoint[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {cdce_xpoint[4]}]

set_property IOSTANDARD LVCMOS25 [get_ports osc_coax_sel]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {osc_xpoint_ctrl[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {top_led2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {top_led2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {top_led2[2]}]

set_property IOSTANDARD LVCMOS25 [get_ports {top_led3[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {top_led3[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {top_led3[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {bot_led1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {bot_led1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {bot_led1[2]}]

set_property IOSTANDARD LVCMOS25 [get_ports {bot_led2[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {bot_led2[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {bot_led2[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports fmc_l12_absent]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l12_pwr_en]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l8_absent]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_l8_pwr_en]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_i2c_scl]
set_property IOSTANDARD LVCMOS33 [get_ports fmc_i2c_sda]

set_property IOSTANDARD LVCMOS33 [get_ports sw3]

set_property IOSTANDARD LVCMOS33 [get_ports cpld2fpga_gpio0]
set_property IOSTANDARD LVCMOS33 [get_ports cpld2fpga_gpio1]
set_property IOSTANDARD LVCMOS33 [get_ports cpld2fpga_gpio2]
set_property IOSTANDARD LVCMOS33 [get_ports cpld2fpga_gpio3]

set_property IOSTANDARD LVCMOS33 [get_ports flash_spi_miso]
set_property IOSTANDARD LVCMOS33 [get_ports flash_spi_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports flash_spi_ss]

## constraints commented below give the following error in Vivado 2018
##  [Vivado 12-1815] Setting property 'IOSTANDARD' is not allowed for GT terminals.
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports daq_txp]
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports daq_txn]
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports daq_rxp]
#set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports daq_rxn]

set_property IOSTANDARD LVDS_25 [get_ports ttc_rx_p]
set_property IOSTANDARD LVDS_25 [get_ports ttc_rx_n]

set_property IOSTANDARD LVDS_25 [get_ports fabric_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports fabric_clk_n]

# ###############
# Pin Assignments
# ###############

set_property PACKAGE_PIN AD5 [get_ports osc125_a_n]

set_property PACKAGE_PIN U7 [get_ports osc125_b_n]

set_property PACKAGE_PIN AG3 [get_ports amc_rx_n0]

set_property PACKAGE_PIN AN18 [get_ports {k7_master_xpoint_ctrl[0]}]
set_property PACKAGE_PIN AN17 [get_ports {k7_master_xpoint_ctrl[1]}]
set_property PACKAGE_PIN AM21 [get_ports {k7_master_xpoint_ctrl[2]}]
set_property PACKAGE_PIN AL21 [get_ports {k7_master_xpoint_ctrl[3]}]
set_property PACKAGE_PIN AP19 [get_ports {k7_master_xpoint_ctrl[4]}]
set_property PACKAGE_PIN AN19 [get_ports {k7_master_xpoint_ctrl[5]}]
set_property PACKAGE_PIN AP20 [get_ports {k7_master_xpoint_ctrl[6]}]
set_property PACKAGE_PIN AN20 [get_ports {k7_master_xpoint_ctrl[7]}]
set_property PACKAGE_PIN AP22 [get_ports {k7_master_xpoint_ctrl[8]}]
set_property PACKAGE_PIN AP21 [get_ports {k7_master_xpoint_ctrl[9]}]

set_property PACKAGE_PIN AL16 [get_ports {k7_pcie_clk_ctrl[0]}]
set_property PACKAGE_PIN AM16 [get_ports {k7_pcie_clk_ctrl[1]}]
set_property PACKAGE_PIN AJ16 [get_ports {k7_pcie_clk_ctrl[2]}]
set_property PACKAGE_PIN AJ17 [get_ports {k7_pcie_clk_ctrl[3]}]

set_property PACKAGE_PIN AP16 [get_ports k7_tclkb_en]
set_property PACKAGE_PIN AP17 [get_ports k7_tclkd_en]

set_property PACKAGE_PIN AC24 [get_ports cdce_sync_b]
set_property PACKAGE_PIN AJ27 [get_ports cdce_sync_r0]
set_property PACKAGE_PIN AH27 [get_ports cdce_ref_sel]
set_property PACKAGE_PIN AJ24 [get_ports cdce_pwrdown]
set_property PACKAGE_PIN AG26 [get_ports {cdce_xpoint[2]}]
set_property PACKAGE_PIN AG27 [get_ports {cdce_xpoint[3]}]
set_property PACKAGE_PIN AG28 [get_ports {cdce_xpoint[4]}]

set_property PACKAGE_PIN AH29 [get_ports osc_coax_sel]
set_property PACKAGE_PIN AE27 [get_ports {osc_xpoint_ctrl[0]}]
set_property PACKAGE_PIN AE28 [get_ports {osc_xpoint_ctrl[1]}]
set_property PACKAGE_PIN AE26 [get_ports {osc_xpoint_ctrl[2]}]
set_property PACKAGE_PIN AF26 [get_ports {osc_xpoint_ctrl[3]}]
set_property PACKAGE_PIN AE24 [get_ports {osc_xpoint_ctrl[4]}]
set_property PACKAGE_PIN AF24 [get_ports {osc_xpoint_ctrl[5]}]
set_property PACKAGE_PIN AF25 [get_ports {osc_xpoint_ctrl[6]}]
set_property PACKAGE_PIN AG25 [get_ports {osc_xpoint_ctrl[7]}]

set_property PACKAGE_PIN AA24 [get_ports {top_led2[0]}]
set_property PACKAGE_PIN V27 [get_ports {top_led2[1]}]
set_property PACKAGE_PIN AA31 [get_ports {top_led2[2]}]

set_property PACKAGE_PIN P25 [get_ports {top_led3[0]}]
set_property PACKAGE_PIN P26 [get_ports {top_led3[1]}]
set_property PACKAGE_PIN R24 [get_ports {top_led3[2]}]

set_property PACKAGE_PIN AA29 [get_ports {bot_led1[0]}]
set_property PACKAGE_PIN Y28 [get_ports {bot_led1[1]}]
set_property PACKAGE_PIN Y29 [get_ports {bot_led1[2]}]

set_property PACKAGE_PIN P24 [get_ports {bot_led2[0]}]
set_property PACKAGE_PIN R26 [get_ports {bot_led2[1]}]
set_property PACKAGE_PIN R27 [get_ports {bot_led2[2]}]

set_property PACKAGE_PIN AB25 [get_ports fmc_l12_absent]
set_property PACKAGE_PIN AC25 [get_ports fmc_l12_pwr_en]
set_property PACKAGE_PIN AD27 [get_ports fmc_l8_absent]
set_property PACKAGE_PIN AD26 [get_ports fmc_l8_pwr_en]
set_property PACKAGE_PIN AB28 [get_ports fmc_i2c_scl]
set_property PACKAGE_PIN AA25 [get_ports fmc_i2c_sda]

set_property PACKAGE_PIN AA28 [get_ports sw3]

set_property PACKAGE_PIN Y32 [get_ports cpld2fpga_gpio0]
set_property PACKAGE_PIN AB32 [get_ports cpld2fpga_gpio1]
set_property PACKAGE_PIN AB33 [get_ports cpld2fpga_gpio2]
set_property PACKAGE_PIN AA30 [get_ports cpld2fpga_gpio3]

set_property PACKAGE_PIN AA34 [get_ports flash_spi_miso]
set_property PACKAGE_PIN AA33 [get_ports flash_spi_mosi]
set_property PACKAGE_PIN V30 [get_ports flash_spi_ss]

set_property PACKAGE_PIN AF5 [get_ports daq_rxn]

set_property PACKAGE_PIN AL23 [get_ports ttc_rx_n]

set_property PACKAGE_PIN AK19 [get_ports fabric_clk_n]

# ################################################ end of file ################################################ #
