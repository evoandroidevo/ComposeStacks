#!/bin/bash

BOTNAME="UPS Notification"
# Old ups info
#MAINTEXT=$(upsc ups@ip | jq -Rsa | gawk '{ gsub(/"/,"") } 1')
# Eaton Li ups info
batterycharge=$(upsc ups@ip battery.charge)
batteryruntime=$(upsc ups@ip battery.runtime)
inputvoltage=$(upsc ups@ip input.voltage)
outlet1status=$(upsc ups@ip outlet.1.status)
outlet2status=$(upsc ups@ip outlet.2.status)
outputpower=$(upsc ups@ip output.realpower)
upsstatus=$(upsc ups@ip ups.status)

while getopts w:c:f: flag
do
    case "${flag}" in
        w) webhook=${OPTARG};;
        c) color=${OPTARG};;
        f) fault=${OPTARG};;
    esac
done

./discord.sh --webhook-url="$webhook" \
--username "$BOTNAME" \
--avatar "" \
--title "(RPI Server) $fault" \
--description "\`\`\`yaml\nBattery Charge: $batterycharge \nBattery Runtime: $batteryruntime \nInput Voltage: $inputvoltage \nOutlet 1 Status: $outlet1status \nOutlet 2 Status: $outlet2status \nOutput Power: $outputpower \nUPS Status: $upsstatus \`\`\`" \
--color "$color" \
--url "" \
--footer "discord.sh" \
--footer-icon "" \
--timestamp