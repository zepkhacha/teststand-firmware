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

# elimnate constraints between these clock groups
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {usr/a6_channels/clock_array[0].clk_500M/inst/mmcm_adv_inst/CLKOUT0B}]] -group [get_clocks -of_objects [get_pins usr/a6_channels/clk_200M/inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {usr/a6_channels/clock_array[0].clk_500M/inst/mmcm_adv_inst/CLKOUT0}]] -group [get_clocks -of_objects [get_pins usr/a6_channels/clk_200M/inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {usr/a6_channels/clock_array[1].clk_500M/inst/mmcm_adv_inst/CLKOUT0B}]] -group [get_clocks -of_objects [get_pins usr/a6_channels/clk_200M/inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {usr/a6_channels/clock_array[1].clk_500M/inst/mmcm_adv_inst/CLKOUT0}]] -group [get_clocks -of_objects [get_pins usr/a6_channels/clk_200M/inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_out1_clk_wiz_trig_200M_1] -group [get_clocks -include_generated_clocks clk_out1_clk_wiz_trig_500M]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_out1_clk_wiz_trig_200M_1] -group [get_clocks -include_generated_clocks clk_out2_clk_wiz_trig_500M]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk_out1_clk_wiz_trig_200M_1] -group [get_clocks -include_generated_clocks clk_out1_clk_wiz_trig_200M]


# Active-high resets
set_switching_activity -signal_rate 0.000 -static_probability 0.000 [get_nets sys/clocks/rst_eth]
set_switching_activity -signal_rate 0.000 -static_probability 0.000 [get_nets usr/ttc_decoder_rst]
#set_switching_activity -static_probability 0 -signal_rate 0 [get_nets usr/rst_osc125__3]
#set_switching_activity -static_probability 0 -signal_rate 0 [get_nets usr/soft_rst_ttc_sync/rst_ttc]
set_switching_activity -signal_rate 0.000 -static_probability 0.000 [get_nets usr/reset_t9_correction_ttc/t9_gapcorr_reset_ttc]


# False paths
set_false_path -from [get_cells {usr/trig_regs_inst/regs_delay_fast_buf_reg[*][*][*][*][*][*]}]
set_false_path -from [get_cells {usr/trig_regs_inst/regs_width_fast_buf_reg[*][*][*][*][*][*]}]
set_false_path -from [get_cells {usr/trig_regs_inst/regs_delay_slow_buf_reg[*][*][*][*][*][*]}]
set_false_path -from [get_cells {usr/trig_regs_inst/regs_width_slow_buf_reg[*][*][*][*][*][*]}]

set_false_path -from [get_cells {usr/trig_t9_regs_inst/regs_t9_delay_buf_reg[*][*][*][*]}]

set_false_path -from [get_cells usr/seq_limit_check/pr_found_pen_reg]

