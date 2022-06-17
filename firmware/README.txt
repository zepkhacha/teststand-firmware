============================================================================
Muon g-2 Experiment (E989) Clock and Controls Center (CCC) FC7 FPGA Firmware
============================================================================

This repository contains the firmware and software for the FC7 FPGA used in
the Clock and Controls Center (CCC) in the Muon g-2 Experiment (E989) at Fermi
National Accelerator Laboratory. This firmware performs several tasks:

1. Encode TTC protocol from external signals, including clock and triggers.
2. Re-encode and fanout TTC protocol from backplane signals.
3. Keep track of fill numbers as well as other bookkeeping.
4. Coordinate data transfer from the FC7 FPGA to the AMC13.

The firmware is divided in three versions - one specific to the Encoder FC7,
one specific to the Fanout FC7, and one specific to the Trigger FC7. The
version-specific files are designated with a 'encoder', 'fanout', or 'trigger'
tag in their filename or in the parent directory.


Firmware Developers
-------------------

The firmware was orinally developed by CERN and Imperial College London. The
firmware specific to E989 was written by David A. Sweigart.  Feel free to
contact him with any comments and/or questions at das556@cornell.edu.


Versions
--------

This firmware was developed and tested with Vivado 2014.4.


Synthesizing and Implementing the Firmware
------------------------------------------

This repository is intended to be run in Vivado's project mode. To build the
Vivado project from a fresh checkout, first open the Vivado 2014.4 GUI and run
the script 'scripts/build_project_[version].tcl'. This will create a new folder
named 'project/[version]' which contains all of the project-related files. To
open the project afterward, use the Vivado project file 'FC7_[Version].xpr'. Note
that the local repository's absolute path is not allowed to have any spaces.

To build the firmware, click 'Generate Bitstream' from the Flow Navigator which
will automatically run synthesis and/or implementation if required.  If successful,
the bitstream 'bitstreams/fc7_[version].bit' will be generated, along with the
debug file 'bitstreams/fc7_[version].ltx' if set up and the .mcs file to be used
for Flash storage of the firmware.


Intellectual Property (IP)
--------------------------

This repository stores only the XCI file for each IP in the 'ip' folder. It is
unclear whether merging will be successful between IP versions. Therefore, any
changes to the IPs should be coordinated between the firmware developers.
