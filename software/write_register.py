# FC7 register reading script script
# Usage: python read_register.py [crate] [slot] [address table node]

import uhal, sys
uhal.disableLogging()

# check number of arguments
if len(sys.argv)!=5:
    print( 'usage: python read_register.py [crate] [slot] [address table node] [value]')
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://$GM2DAQ_DIR/address_tables/FC7_CCC.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# write control registers
register             = fc7.getNode(sys.argv[3]).write(int(sys.argv[4]))
fc7.dispatch()

print("ok.")

