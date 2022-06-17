# Export the bitstream file and create the .mcs file
if {[file exists ./fc7_fanout_top.bit]} {
  file copy -force ./fc7_fanout_top.bit [file dirname [info script]]/../bitstreams/fc7_fanout_$version.bit
  puts "INFO: Bitstream copied: fc7_fanout.bit"
  write_cfgmem -force -format MCS -size 32 -interface SPIx1 \
      -loadbit "up 0x0 ./fc7_fanout_top.bit" [file dirname [info script]]/../bitstreams/fc7_fanout_$version
} else {
  puts "ERROR: Bitstream not found: fc7_fanout_top.bit"
}

# Export the debug file
if {[file exists ./debug_nets.ltx]} {
  file copy -force ./debug_nets.ltx [file dirname [info script]]/../bitstreams/fc7_fanout_$version.ltx
  puts "INFO: Debug copied: fc7_fanout.ltx"
} else {
  puts "WARNING: Debug not found: debug_nets.ltx"
}
