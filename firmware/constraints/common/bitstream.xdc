set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.CONFIG.NEXT_CONFIG_REBOOT DISABLE [current_design]
set_property BITSTREAM.CONFIG.TIMER_CFG 32'h00800000 [current_design]
set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
set_property BITSTREAM.CONFIG.USERID 32'h46433732 [current_design]

## encodes the version number into the bitstream: should match the version information in user_version_package.vhd
set_property BITSTREAM.CONFIG.USR_ACCESS 0x4B070009 [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

