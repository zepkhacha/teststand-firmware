########################################################
set_property IOSTANDARD LVDS_25 [get_ports fabric_clk_p]
set_property PACKAGE_PIN AK18 [get_ports fabric_clk_p]
create_clock -period 25.000 -name fabric_clk [get_ports fabric_clk_p]

###################EXT 40 MHZ Clock################################
#set_property IOSTANDARD LVDS_25                 [get_ports fmc_l8_gbtclk0_p]
#set_property PACKAGE_PIN AJ31                   [get_ports fmc_l8_gbtclk0_p]
#set_property PACKAGE_PIN AH9                   [get_ports fmc_l8_gbtclk0_n]
#create_clock -period 25.000 -name ext_40MHz_clk [get_ports fmc_l8_gbtclk0_p]

########################################################
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks eth_txoutclk] -group [get_clocks -include_generated_clocks osc125_a] -group [get_clocks -include_generated_clocks osc125_b] -group [get_clocks -include_generated_clocks fabric_clk]
#   -group [get_clocks -include_generated_clocks ext_40MHz_clk]
########################################################
set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
########################################################
set_operating_conditions -airflow 0
set_operating_conditions -heatsink low
########################################################



