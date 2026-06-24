#!/bin/sh
case $1 in
onbatt)
logger -t upssched-cmd "UPS running on battery for 5 seconds"
/bin/bash send.sh -w "" -f "UPS On Battery for 5s" -c 0xF53127
;;
online)
logger -t upssched-cmd "UPS is back on line power"
/bin/bash send.sh -w "" -f "UPS back on line power" -c 0x27F531
;;
shutdowncritical)
logger -t upssched-cmd "UPS battery critical, forced shutdown"
/bin/bash send.sh -w "" -f "UPS Low Battery Shutdown" -c 0xF53127
/usr/sbin/upsmon -c fsd
;;
commbad)
logger -t upssched-cmd "UPS has lost communication for 45s"
/bin/bash send.sh -w "" -f "UPS Comms down for 45s" -c 0xF53127
;;
commok)
logger -t upssched-cmd "UPS Communication been restored."
/bin/bash send.sh -w "" -f "UPS Comms OK" -c 0x27F531
;;
fsdtimer)
logger -t upssched-cmd "UPS running on battery for 20 minutes shutting down"
/bin/bash send.sh -w "" -f "UPS On Battery for 20mins shutting down" -c 0xF53127
/usr/sbin/upsmon -c fsd
;;
powerdown)
logger -t upssched-cmd "UPS has requested shutdown"
/bin/bash send.sh -w "" -f "UPS requested shutdown" -c 0xF53127
/usr/sbin/upsmon -c fsd
;;
battbad)
logger -t upssched-cmd "UPS Battery has failed test"
/bin/bash send.sh -w "" -f "UPS Battery needs replacement" -c 0xEBF527
;;
*)
logger -t upssched-cmd "Unrecognized command: $1"
/bin/bash send.sh -w "" -f "Unknown command "$1"" -c 0xEBF527
;;
esac