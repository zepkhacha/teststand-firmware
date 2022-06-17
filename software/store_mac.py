# FC7 MAC address configuration script
# Usage: python store_mac.py [crate number] [slot number] [serial number]

import sys, os, time

def doIPMI1(ipmi_base, cmd_base, cmd, mac):
    IPMI_INCANTATION = "%s raw 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x" % \
                       (ipmi_base, cmd_base, cmd, mac[0], mac[1], mac[2], mac[3], mac[4], mac[5])
    print IPMI_INCANTATION
    os.system(IPMI_INCANTATION)
    time.sleep(0.1)

def doIPMI2(ipmi_base, cmd_base, cmd):
    IPMI_INCANTATION = "%s raw 0x%02x 0x%02x 0xFE 0xEF" % (ipmi_base, cmd_base, cmd)
    print IPMI_INCANTATION
    os.system(IPMI_INCANTATION)
    time.sleep(0.1)

# check number of arguments
if len(sys.argv)<4:
    print 'usage: python store_mac.py [crate number] [slot number] [serial number]'
    sys.exit(2)

# IPMI base command options
username = "shelf"
password = "shelf"
transit_address = 0x82  # for the -T option
transit_channel = 0     # for the -B option
destination_channel = 7 # for the -b option

host = "192.168."+sys.argv[1]+".15"
slot = int(sys.argv[2])
sn   = int(sys.argv[3])

# check that the destination slot is valid
if slot>12 or slot<1:
    print "Error: Slot number must be in range 1-12"
    sys.exit(2)
else:
    dest_ipmb = 0x70+(2*slot)

# check that the serial number is valid
if sn<1 or sn>512:
   print "Error: Serial number must be in range 1-512"
   sys.exit(2)

# set the configuration bytes to be programmed
macAddr_bytes = []

# set the MAC address bytes
macAddr_bytes.append(  0 )
macAddr_bytes.append( 96 )
macAddr_bytes.append( 85 )
macAddr_bytes.append(  0 )
macAddr_bytes.append(  2 )
macAddr_bytes.append( sn + 90 )

#form the base of the command
IPMI_BASE = "ipmitool -I lan -H %s -U %s -P %s -B 0x%x -T 0x%x -b %d -t 0x%x" % \
            (host, username, password, transit_channel, transit_address, destination_channel, dest_ipmb)

# netfn and function commands for the IPMI MAC store command as part of custom NETFN
COMMAND_BASE = 0x30
COMMAND1     = 0x02
COMMAND2     = 0x01

# execute the write to FC7 ports
doIPMI1(IPMI_BASE, COMMAND_BASE, COMMAND1, macAddr_bytes)
doIPMI2(IPMI_BASE, COMMAND_BASE, COMMAND2)
