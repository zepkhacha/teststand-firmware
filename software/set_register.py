# FC7 register setting script
# Usage: python set_register.py [crate] [slot] [address table node] [value]

import uhal, sys, ctypes
uhal.disableLogging()

# check number of arguments
if len(sys.argv)!=5:
    print( 'usage: python set_register.py [crate] [slot] [address table node] [value]')
    sys.exit(2)

uri = "ipbusudp-2.0://192.168."+sys.argv[1]+"."+sys.argv[2]+":50001"
address_table = "file://$GM2DAQ_DIR/address_tables/FC7_CCC.xml"
fc7 = uhal.getDevice("hw_id", uri, address_table)

# write control registers
register             = fc7.getNode(sys.argv[3]).write(ctypes.c_uint32(int(sys.argv[4])).value)
fc7.dispatch()

# readback check
readback             = fc7.getNode(sys.argv[3]).read()
fc7.dispatch()
print( sys.argv[3]+':   '+str(int( readback.value() )))

