# Fabric clock
create_clock -period 25.000 -name fabric_clk [get_ports fabric_clk_p]

# System clocks
create_clock -period 8.000 -name clk125_a [get_ports osc125_a_p]
create_clock -period 8.000 -name clk125_b [get_ports osc125_b_p]

# DAQ_Link_7S (README said to include this line)
create_clock -period 4.000 -name DAQ_usrclk [get_pins usr/daq_link/i_UsrClk/O]

# Ethernet clock
create_clock -period 16.000 -name eth_txoutclk [get_pins sys/eth/bufg_tx/O]

# Separate asynchronous clock domains
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks fabric_clk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk125_a]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk125_b]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks DAQ_usrclk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks eth_txoutclk]

# Active-high resets
set_switching_activity -static_probability 0 -signal_rate 0 [get_nets sys/clocks/rst_eth]
set_switching_activity -static_probability 0 -signal_rate 0 [get_nets usr/ttc_decoder_rst_inst/ttc_decoder_rst]
