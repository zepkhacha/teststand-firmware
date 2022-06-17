# FC7 IP address configuration script
# Usage: python store_ip.py [crate number] [slot number] [ip address]

import sys, os, time

def doIPMI1(ipmi_base, cmd_base, cmd, ip):
    IPMI_INCANTATION = "%s raw 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x" % \
                       (ipmi_base, cmd_base, cmd, ip[0], ip[1], ip[2], ip[3])
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
    print 'usage: python store_ip.py [crate number] [slot number] [ip address]'
    sys.exit(2)

# IPMI base command options
username = "shelf"
password = "shelf"
transit_address = 0x82  # for the -T option
transit_channel = 0     # for the -B option
destination_channel = 7 # for the -b option

host = "192.168."+sys.argv[1]+".15"
slot = int(sys.argv[2])

# check that the destination slot is valid
if slot>12 or slot<1:
    print "Error: Slot number must be in range 1-12"
    sys.exit(2)
else:
    dest_ipmb = 0x70+(2*slot)

# set the configuration bytes to be programmed
ipAddr_bytes = []

# set the IP address bytes
ipAddr_bytes = sys.argv[3].split(".")
for i in range(len(ipAddr_bytes)):
    try:
        ipAddr_bytes[i] = int(ipAddr_bytes[i])
    except ValueError:
        print "Error: Provided IP address must be decimal numbers delimited by periods"
        sys.exit(2)

if len(ipAddr_bytes)!=4:
    print "Error: Only allowed 4 bytes in IP address"
    sys.exit(2)

# form the base of the command
IPMI_BASE = "ipmitool -I lan -H %s -U %s -P %s -B 0x%x -T 0x%x -b %d -t 0x%x" % \
            (host, username, password, transit_channel, transit_address, destination_channel, dest_ipmb)

# netfn and function commands for the IPMI IP store command as part of custom NETFN
COMMAND_BASE = 0x30
COMMAND1     = 0x03
COMMAND2     = 0x01

# execute the write to FC7 ports
doIPMI1(IPMI_BASE, COMMAND_BASE, COMMAND1, ipAddr_bytes)
doIPMI2(IPMI_BASE, COMMAND_BASE, COMMAND2)
