#!/bin/bash

export PATH=$PATH:/home/pi/.local/bin
AP_BIN_DIR="/home/pi/ardupilot/bin/"
VEHICLE_BIN="ArduCopter.elf"

RPIPROC=$(cat /proc/cpuinfo |grep "Hardware" | awk '{print $3}')
if [ "$RPIPROC" = "BCM2708" ]; then
        echo "Raspberry Pi 1/0"
        GPS="/dev/ttyAMA0"
elif [ -c /dev/ttyS0 ]; then
        echo "Raspberry Pi 3"
        GPS="/dev/ttyS0"
else
        echo "Raspberry pi 2"
        GPS="/dev/ttyAMA0"
fi

FLAGS="-l /home/pi/media/logs -t /home/pi/media/terrain/"

#remove old tlogs generated by mavproxy, they can become quite big overtime.
rm -f $AP_BIN_DIR/*tlog*

#backup last log
mv /home/pi/ardupilot/info/ardupilot.log /home/pi/ardupilot/info/ardupilot.log.bak

restart_counter=0 
while [ $restart_counter -lt 4 ]; do
    cd $AP_BIN_DIR
    #sitl
    $AP_BIN_DIR/$VEHICLE_BIN -S -I0 --home -35.363261,149.165230,584,353 --model + --speedup 1 --defaults /home/pi/ardupilot/ardupilot/Tools/autotest/default_params/copter.parm
    #raspilot
    #$AP_BIN_DIR/$VEHICLE_BIN -A tcp:127.0.0.1:5760 -B $GPS $FLAGS
    cd -
    restart_counter=$((restart_counter+1))
done
#done > /home/pi/ardupilot/info/ardupilot.log 2>&1

