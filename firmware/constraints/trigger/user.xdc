# ################
# L8 I/O Standards
# ################

set_property IOSTANDARD LVCMOS25 [get_ports aux_lemo_a]
set_property IOSTANDARD LVCMOS25 [get_ports aux_lemo_b]
set_property IOSTANDARD LVDS_25 [get_ports tr0_lemo_p]
set_property IOSTANDARD LVDS_25 [get_ports tr0_lemo_n]
set_property IOSTANDARD LVDS_25 [get_ports tr1_lemo_p]
set_property IOSTANDARD LVDS_25 [get_ports tr1_lemo_n]
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

## Cornell Card usage
# ###################
# L12 I/O Standards
# ###################

set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[11]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[16]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[17]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[18]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[19]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[20]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[21]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[22]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[23]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[24]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[25]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[26]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[27]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[28]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[29]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[30]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[31]}]

set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[8]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[9]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[10]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[11]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[12]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[13]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[14]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[15]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[16]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[17]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[18]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[19]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[20]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[21]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[22]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[23]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[24]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[25]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[26]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[27]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[28]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[29]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[30]}]
set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[31]}]


# ###################
# L12 Pin Assignments
# ###################

# OUTPUT BANK A
set_property PACKAGE_PIN B30 [get_ports {fmc_header_p[31]}]
set_property PACKAGE_PIN H32 [get_ports {fmc_header_p[27]}]
set_property PACKAGE_PIN L33 [get_ports {fmc_header_p[23]}]
set_property PACKAGE_PIN B33 [get_ports {fmc_header_p[19]}]
set_property PACKAGE_PIN J34 [get_ports {fmc_header_p[15]}]
set_property PACKAGE_PIN L34 [get_ports {fmc_header_p[11]}]
set_property PACKAGE_PIN P34 [get_ports {fmc_header_p[7]}]
set_property PACKAGE_PIN R32 [get_ports {fmc_header_p[3]}]

# OUTPUT BANK B
set_property PACKAGE_PIN D29 [get_ports {fmc_header_p[30]}]
set_property PACKAGE_PIN H29 [get_ports {fmc_header_p[26]}]
set_property PACKAGE_PIN N32 [get_ports {fmc_header_p[22]}]
set_property PACKAGE_PIN E31 [get_ports {fmc_header_p[18]}]
set_property PACKAGE_PIN F33 [get_ports {fmc_header_p[14]}]
set_property PACKAGE_PIN P30 [get_ports {fmc_header_p[10]}]
set_property PACKAGE_PIN R33 [get_ports {fmc_header_p[6]}]
set_property PACKAGE_PIN T30 [get_ports {fmc_header_p[2]}]

# OUTPUT BANK C
set_property PACKAGE_PIN B31 [get_ports {fmc_header_p[29]}]
set_property PACKAGE_PIN C32 [get_ports {fmc_header_p[25]}]
set_property PACKAGE_PIN L31 [get_ports {fmc_header_p[21]}]
set_property PACKAGE_PIN E32 [get_ports {fmc_header_p[17]}]
set_property PACKAGE_PIN F34 [get_ports {fmc_header_p[13]}]
set_property PACKAGE_PIN M30 [get_ports {fmc_header_p[9]}]
set_property PACKAGE_PIN N33 [get_ports {fmc_header_p[5]}]
set_property PACKAGE_PIN T28 [get_ports {fmc_header_p[1]}]

# OUTPUT BANK D
set_property PACKAGE_PIN F29 [get_ports {fmc_header_p[28]}]
set_property PACKAGE_PIN G31 [get_ports {fmc_header_p[24]}]
set_property PACKAGE_PIN D34 [get_ports {fmc_header_p[20]}]
set_property PACKAGE_PIN H33 [get_ports {fmc_header_p[16]}]
set_property PACKAGE_PIN K32 [get_ports {fmc_header_p[12]}]
set_property PACKAGE_PIN T33 [get_ports {fmc_header_p[8]}]
set_property PACKAGE_PIN U32 [get_ports {fmc_header_p[4]}]
set_property PACKAGE_PIN R28 [get_ports {fmc_header_p[0]}]

# INPUT BANK A
set_property PACKAGE_PIN A31 [get_ports {fmc_header_n[31]}]
set_property PACKAGE_PIN G32 [get_ports {fmc_header_n[27]}]
set_property PACKAGE_PIN K33 [get_ports {fmc_header_n[23]}]
set_property PACKAGE_PIN A33 [get_ports {fmc_header_n[19]}]
set_property PACKAGE_PIN H34 [get_ports {fmc_header_n[15]}]
set_property PACKAGE_PIN K34 [get_ports {fmc_header_n[11]}]
set_property PACKAGE_PIN N34 [get_ports {fmc_header_n[7]}]
set_property PACKAGE_PIN P32 [get_ports {fmc_header_n[3]}]

# INPUT BANK B
set_property PACKAGE_PIN D30 [get_ports {fmc_header_n[30]}]
set_property PACKAGE_PIN H30 [get_ports {fmc_header_n[26]}]
set_property PACKAGE_PIN M32 [get_ports {fmc_header_n[22]}]
set_property PACKAGE_PIN D31 [get_ports {fmc_header_n[18]}]
set_property PACKAGE_PIN E33 [get_ports {fmc_header_n[14]}]
set_property PACKAGE_PIN N30 [get_ports {fmc_header_n[10]}]
set_property PACKAGE_PIN R34 [get_ports {fmc_header_n[6]}]
set_property PACKAGE_PIN T31 [get_ports {fmc_header_n[2]}]

# INPUT BANK C
set_property PACKAGE_PIN B32 [get_ports {fmc_header_n[29]}]
set_property PACKAGE_PIN C33 [get_ports {fmc_header_n[25]}]
set_property PACKAGE_PIN K31 [get_ports {fmc_header_n[21]}]
set_property PACKAGE_PIN D32 [get_ports {fmc_header_n[17]}]
set_property PACKAGE_PIN E34 [get_ports {fmc_header_n[13]}]
set_property PACKAGE_PIN M31 [get_ports {fmc_header_n[9]}]
set_property PACKAGE_PIN M33 [get_ports {fmc_header_n[5]}]
set_property PACKAGE_PIN T29 [get_ports {fmc_header_n[1]}]

# INPUT BANK D
set_property PACKAGE_PIN E29 [get_ports {fmc_header_n[28]}]
set_property PACKAGE_PIN F31 [get_ports {fmc_header_n[24]}]
set_property PACKAGE_PIN C34 [get_ports {fmc_header_n[20]}]
set_property PACKAGE_PIN G33 [get_ports {fmc_header_n[16]}]
set_property PACKAGE_PIN J32 [get_ports {fmc_header_n[12]}]
set_property PACKAGE_PIN T34 [get_ports {fmc_header_n[8]}]
set_property PACKAGE_PIN U33 [get_ports {fmc_header_n[4]}]
set_property PACKAGE_PIN R29 [get_ports {fmc_header_n[0]}]



## HiTech Card usage
## # #################
## # L12 I/O Standards
## # #################
##
## ## the actual output signals that we will use
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[0]}];   # header pin number 0
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[1]}];   # header pin number 2
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[2]}];   # header pin number 4
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[3]}];   # header pin number 6
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[4]}];   # header pin number 8
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[5]}];   # header pin number 10
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[6]}];   # header pin number 12
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[7]}];   # header pin number 14
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[8]}];   # header pin number 16
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[9]}];   # header pin number 18
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[10]}];  # header pin number 20
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[11]}];  # header pin number 22
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[12]}];  # header pin number 24
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[13]}];  # header pin number 26
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[14]}];  # header pin number 28
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[15]}];  # header pin number 30
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[16]}];  # header pin number 32
##
## ## the n-side signals will see ground.  Set these as input ports to avoid damage.
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[0]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[1]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[2]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[3]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[4]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[5]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[6]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[7]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[8]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[9]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[10]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[11]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[12]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[13]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[14]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[15]}]
## set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[16]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[17]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[18]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[19]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[20]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[21]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[22]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[23]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[24]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[25]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[26]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[27]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[28]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[29]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[30]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[31]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[32]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_n[33]}]
##
##
## ## these correspond to the unused ports that we won't map to any signal.
## ## set them all to input in case we get our wires crossed
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[17]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[18]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[19]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[20]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[21]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[22]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[23]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[24]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[25]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[26]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[27]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[28]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[29]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[30]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[31]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[32]}]
## #set_property IOSTANDARD LVCMOS25 [get_ports {fmc_header_p[33]}]
##
## # ###################
## # L12 Pin Assignments
## # ###################
##
## ## the pins that we use.  Note that the port number on the
## ## breakout board corresponds to twice the fmc_header index
## ## These are not the standard FMC mapping
## set_property PACKAGE_PIN R28 [get_ports {fmc_header_p[0]}]
## set_property PACKAGE_PIN R29 [get_ports {fmc_header_n[0]}]
## set_property PACKAGE_PIN T30 [get_ports {fmc_header_p[1]}]
## set_property PACKAGE_PIN T31 [get_ports {fmc_header_n[1]}]
## set_property PACKAGE_PIN U32 [get_ports {fmc_header_p[2]}]
## set_property PACKAGE_PIN U33 [get_ports {fmc_header_n[2]}]
## set_property PACKAGE_PIN R33 [get_ports {fmc_header_p[3]}]
## set_property PACKAGE_PIN R34 [get_ports {fmc_header_n[3]}]
## set_property PACKAGE_PIN T33 [get_ports {fmc_header_p[4]}]
## set_property PACKAGE_PIN T34 [get_ports {fmc_header_n[4]}]
## set_property PACKAGE_PIN P30 [get_ports {fmc_header_p[5]}]
## set_property PACKAGE_PIN N30 [get_ports {fmc_header_n[5]}]
## set_property PACKAGE_PIN K32 [get_ports {fmc_header_p[6]}]
## set_property PACKAGE_PIN J32 [get_ports {fmc_header_n[6]}]
## set_property PACKAGE_PIN F33 [get_ports {fmc_header_p[7]}]
## set_property PACKAGE_PIN E33 [get_ports {fmc_header_n[7]}]
## set_property PACKAGE_PIN H33 [get_ports {fmc_header_p[8]}]
## set_property PACKAGE_PIN G33 [get_ports {fmc_header_n[8]}]
## set_property PACKAGE_PIN E31 [get_ports {fmc_header_p[9]}]
## set_property PACKAGE_PIN D31 [get_ports {fmc_header_n[9]}]
## set_property PACKAGE_PIN D34 [get_ports {fmc_header_p[10]}]
## set_property PACKAGE_PIN C34 [get_ports {fmc_header_n[10]}]
## set_property PACKAGE_PIN N32 [get_ports {fmc_header_p[11]}]
## set_property PACKAGE_PIN M32 [get_ports {fmc_header_n[11]}]
## set_property PACKAGE_PIN G31 [get_ports {fmc_header_p[12]}]
## set_property PACKAGE_PIN F31 [get_ports {fmc_header_n[12]}]
## set_property PACKAGE_PIN H29 [get_ports {fmc_header_p[13]}]
## set_property PACKAGE_PIN H30 [get_ports {fmc_header_n[13]}]
## set_property PACKAGE_PIN F29 [get_ports {fmc_header_p[14]}]
## set_property PACKAGE_PIN E29 [get_ports {fmc_header_n[14]}]
## set_property PACKAGE_PIN D29 [get_ports {fmc_header_p[15]}]
## set_property PACKAGE_PIN D30 [get_ports {fmc_header_n[15]}]
## set_property PACKAGE_PIN A29 [get_ports {fmc_header_p[16]}]
## set_property PACKAGE_PIN A30 [get_ports {fmc_header_n[16]}]
##
## ## these are the pins that we will skipping for I/O
## ## these are not the standard FMC mapping...
## #set_property PACKAGE_PIN T28 [get_ports {fmc_header_p[17]}]
## #set_property PACKAGE_PIN T29 [get_ports {fmc_header_n[17]}]
## #set_property PACKAGE_PIN R32 [get_ports {fmc_header_p[18]}]
## #set_property PACKAGE_PIN P32 [get_ports {fmc_header_n[18]}]
## #set_property PACKAGE_PIN N33 [get_ports {fmc_header_p[19]}]
## #set_property PACKAGE_PIN M33 [get_ports {fmc_header_n[19]}]
## #set_property PACKAGE_PIN P34 [get_ports {fmc_header_p[20]}]
## #set_property PACKAGE_PIN N34 [get_ports {fmc_header_n[20]}]
## #set_property PACKAGE_PIN M30 [get_ports {fmc_header_p[21]}]
## #set_property PACKAGE_PIN M31 [get_ports {fmc_header_n[21]}]
## #set_property PACKAGE_PIN L34 [get_ports {fmc_header_p[22]}]
## #set_property PACKAGE_PIN K34 [get_ports {fmc_header_n[22]}]
## #set_property PACKAGE_PIN F34 [get_ports {fmc_header_p[23]}]
## #set_property PACKAGE_PIN E34 [get_ports {fmc_header_n[23]}]
## #set_property PACKAGE_PIN J34 [get_ports {fmc_header_p[24]}]
## #set_property PACKAGE_PIN H34 [get_ports {fmc_header_n[24]}]
## #set_property PACKAGE_PIN E32 [get_ports {fmc_header_p[25]}]
## #set_property PACKAGE_PIN D32 [get_ports {fmc_header_n[25]}]
## #set_property PACKAGE_PIN B33 [get_ports {fmc_header_p[26]}]
## #set_property PACKAGE_PIN A33 [get_ports {fmc_header_n[26]}]
## #set_property PACKAGE_PIN L31 [get_ports {fmc_header_p[27]}]
## #set_property PACKAGE_PIN K31 [get_ports {fmc_header_n[27]}]
## #set_property PACKAGE_PIN L33 [get_ports {fmc_header_p[28]}]
## #set_property PACKAGE_PIN K33 [get_ports {fmc_header_n[28]}]
## #set_property PACKAGE_PIN C32 [get_ports {fmc_header_p[29]}]
## #set_property PACKAGE_PIN C33 [get_ports {fmc_header_n[29]}]
## #set_property PACKAGE_PIN H32 [get_ports {fmc_header_p[30]}]
## #set_property PACKAGE_PIN G32 [get_ports {fmc_header_n[30]}]
## #set_property PACKAGE_PIN B31 [get_ports {fmc_header_p[31]}]
## #set_property PACKAGE_PIN B32 [get_ports {fmc_header_n[31]}]
## #set_property PACKAGE_PIN B30 [get_ports {fmc_header_p[32]}]
## #set_property PACKAGE_PIN A31 [get_ports {fmc_header_n[32]}]
## #set_property PACKAGE_PIN C29 [get_ports {fmc_header_p[33]}]
## #set_property PACKAGE_PIN C30 [get_ports {fmc_header_n[33]}]
##
## # ###################
## # L12 Output port Properties
## # ###################
##
##
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[16]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[15]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[14]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[13]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[12]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[11]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[10]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[9]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[8]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[7]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[6]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[5]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[4]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[3]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[2]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[1]]
## set_property OFFCHIP_TERM NONE [get_ports fmc_header_p[0]]
##
## set_property DRIVE 16 [get_ports fmc_header_p[16]]
## set_property DRIVE 16 [get_ports fmc_header_p[15]]
## set_property DRIVE 16 [get_ports fmc_header_p[14]]
## set_property DRIVE 16 [get_ports fmc_header_p[13]]
## set_property DRIVE 16 [get_ports fmc_header_p[12]]
## set_property DRIVE 16 [get_ports fmc_header_p[11]]
## set_property DRIVE 16 [get_ports fmc_header_p[10]]
## set_property DRIVE 16 [get_ports fmc_header_p[9]]
## set_property DRIVE 16 [get_ports fmc_header_p[8]]
## set_property DRIVE 16 [get_ports fmc_header_p[7]]
## set_property DRIVE 16 [get_ports fmc_header_p[6]]
## set_property DRIVE 16 [get_ports fmc_header_p[5]]
## set_property DRIVE 16 [get_ports fmc_header_p[4]]
## set_property DRIVE 16 [get_ports fmc_header_p[3]]
## set_property DRIVE 16 [get_ports fmc_header_p[2]]
## set_property DRIVE 16 [get_ports fmc_header_p[1]]
## set_property DRIVE 16 [get_ports fmc_header_p[0]]
##
##
##
##

