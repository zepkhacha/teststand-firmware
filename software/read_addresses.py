# FC7 IP/MAC address reading script
# Usage: python read_addresses.py [crate numbers] [slot numbers]

import sys, time, subprocess, shlex

if len(sys.argv)!=2 and len(sys.argv)!=3:
    print ("usage: "+sys.argv[0]+" [crate numbers] [slot numbers]")
    sys.exit(2)

# parse argument numbers
def PARSE_ARG(arg):
    parsed = []
    csplit = arg.split(',')
    for c in csplit:
        dsplit = c.split('-')
        if len(dsplit)==1:
            parsed.append(dsplit[0])
        else:
            for d in xrange(int(dsplit[0]),int(dsplit[1])+1):
                parsed.append(str(d))
    return parsed

def doIPMI(ipmi_base, cmd_base, cmd):
    IPMI_INCANTATION = "%s raw 0x%02x 0x%02x" % (ipmi_base, cmd_base, cmd)
    args = shlex.split(IPMI_INCANTATION)
    p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    rc = p.returncode

    IPaddress  = "\033[m\017"+"-              "
    MACaddress = "\033[m\017"+"-"
    serialNumber = "-  "

    # parse the return value
    if rc == 0:
        hexAddr = shlex.split(out.decode("utf-8"))
        IPaddress = "%03d.%03d.%03d.%03d" % (int(hexAddr[0],16), int(hexAddr[1],16), int(hexAddr[2],16), int(hexAddr[3],16))
        MACaddress = "%s:%s:%s:%s:%s:%s" % (hexAddr[4], hexAddr[5], hexAddr[6], hexAddr[7], hexAddr[8], hexAddr[9])
        serialNumber = "%03d" % (int(hexAddr[9],16)-90)
    
    time.sleep(0.1)
    return IPaddress, MACaddress, serialNumber

# IPMI base command options
username = "shelf"
password = "shelf"
transit_address = 0x82  # for the -T option
transit_channel = 0     # for the -B option
destination_channel = 7 # for the -b option

# colors
GRAY  = "\033[47;30m"
BLUE  = "\033[0;34m"
RESET = "\033[m\017"

# print header
print ('')
print (GRAY+"Crate   Slot   S/N   IP Address        MAC Address      "+RESET)

# parse argument numbers
crates = PARSE_ARG(sys.argv[1])
if len(sys.argv) == 3:
    slots = PARSE_ARG(sys.argv[2])
else:
    slots = PARSE_ARG("1-12")

# read addresses
for crate in crates:
    for slot in slots:
        host = "192.168."+crate+".15"

        # check that the destination slot is valid
        if int(slot)>12 or int(slot)<1:
            print ("Error: Slot number must be in range 1-12")
            sys.exit(2)
        else:
            dest_ipmb = 0x70 + ( 2*int(slot) )

        # form the base of the command
        IPMI_BASE = "ipmitool -I lan -H %s -U %s -P %s -B 0x%x -T 0x%x -b %d -t 0x%x" % \
                    (host, username, password, transit_channel, transit_address, destination_channel, dest_ipmb)

        # netfn and function commands for the IPMI IP/MAC store command as part of custom NETFN
        COMMAND_BASE = 0x30
        COMMAND      = 0x05

        # execute the write to FC7 ports
        ip, mac, sn = doIPMI(IPMI_BASE, COMMAND_BASE, COMMAND)

        # print addresses
        print ("%02d      %02d    " % (int(crate), int(slot)), sn+"   "+BLUE+ip+"   "+mac+RESET)
    print ('')
print ('')
