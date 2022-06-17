# FC7 firmware programming wrapper
# Usage: python start_screens.py [crate numbers] [slot numbers] [mcs files]

import sys, subprocess, time, os

if len(sys.argv) < 4:
    print "usage: "+sys.argv[0]+" [crate numbers] [slot numbers] [mcs files]"
    sys.exit(2)

# parse argument numbers
def PARSE_ARG(arg):
    parsed = []
    csplit = arg.split(',')
    for c in csplit:
        dsplit = c.split('-')
        if len(dsplit) == 1:
            parsed.append(dsplit[0])
        else:
            for d in xrange(int(dsplit[0]), int(dsplit[1]) + 1):
                parsed.append(str(d))
    return parsed

# parse argument numbers
crates = PARSE_ARG(sys.argv[1])
slots  = PARSE_ARG(sys.argv[2])

# parse mcs files
files  = ''
for file in sys.argv[3:]:
    files = files + ' ' + file

# launch screen processes
for crate in crates:
    for slot in slots:
        host = 'g2aux-priv'
        screen = 'reprog-crate%02d-slot%02d' % (int(crate), int(slot))
        cmd = 'screen -d -m -S '+str(screen)+' ssh -t '+str(host)+' "'+\
              'cd '+os.environ['HOME']+'; '+\
              'source .bashrc; '+\
              'cd '+os.environ['FLASH_TOOL_ROOT']+'; '+\
              'source setenv.sh; '+\
              './bin/programFirmware '+str(crate)+' '+str(slot)+str(files)+'; '+\
              'if [ $? -ne 0 ]; then cd '+os.environ['HOME']+'; exec bash; cd '+os.environ['FLASH_TOOL_ROOT']+'; fi;"'

        subprocess.Popen(str(cmd), shell=True)

# print list of screens
time.sleep(1)
os.system("screen -ls reprog")
