#!/bin/bash

export PATH=$PATH:/home/pi/.local/bin
AP_BIN_DIR="/home/pi/ardupilot/bin/"

RPIPROC=$(cat /proc/cpuinfo |grep "Hardware" | awk '{print $3}')
if [ "$RPIPROC" = "BCM2708" ]; then
        echo "Raspberry Pi 1/0"
        SERIAL_PORT="/dev/ttyAMA0"
elif [ -c /dev/ttyS0 ]; then
        echo "Raspberry Pi 3"
        SERIAL_PORT="/dev/ttyS0"
else
        echo "Raspberry pi 2"
        SERIAL_PORT="/dev/ttyAMA0"
fi

#backup last log
mv /home/pi/ardupilot/info/mavproxy.log /home/pi/ardupilot/info/mavproxy.log.bak

cd $AP_BIN_DIR
cd -
restart_counter=0 
while [ $restart_counter -lt 40 ]; do
    cd $AP_BIN_DIR
    #sitl
    #mavproxy.py --master tcp:127.0.0.1:5760 --sitl 127.0.0.1:5501 --out 127.0.0.1:14550 --out $1:14550
    #raspilot
    #mavproxy.py --master=$SERIAL_PORT --baudrate 57600 --out $1:14550 
    #pixhawk
    mavproxy.py --master=$SERIAL_PORT --baudrate 57600 --out $1:14550 
    #mavproxy.py --master=$SERIAL_PORT --baudrate 921600 --out $1:14550 
    cd -
    restart_counter=$((restart_counter+1))
done
#done >> /home/pi/ardupilot/info/mavproxy.log 2>&1

