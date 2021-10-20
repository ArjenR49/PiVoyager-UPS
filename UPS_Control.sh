#!/bin/bash

# PiVoyager UPS control script

# PiVoyager watchdog function takes care of cutting power to the Pi
# after shutdown forced by a battery low situation through this script/service.

# To make the Pi reboot automatically in case it crashes, install and
# enable the hardware watchdog, which makes use of the GPU on the Pi.
# Test with 'forkbomb'.

# The echo commands will fill the syslog ... consider commenting them out ...

# Short button press: shutdown & delayed power-off.
# On battery, when depleted: shutdown & delayed power-off.
# Automatic power-on when USB power is restored.

# Developed from original OMZLO PiVoyager sample UPS script
# ar - 06-10-2021, 10-10-2021, 16-10-2021, 19-10-2021, 20-10-2021

# Initialize PiVoyager

# Sync clock
pivoyager date sync


# Main control loop

while true;
do

   # Step 1: Every x seconds check if button flag was raised.
   #          - If yes, jump directly to shutdown routine (Step 3).
   #          - If no, check USB power flag ('pg').
   #          - If USB power lost, jump to battery voltage check loop (Step 2).
   #          - If USB power present, continue looping.

   delay1=10
   echo "Checking USB power every $delay1 seconds ..."
   while true;
   do
     if pivoyager status flags | grep button >>/dev/null; then
       echo "Button pressed"
       break 2
     else
       if ! pivoyager status flags | grep pg >>/dev/null; then
         echo "USB power lost"
         break 1
       fi
     fi
     sleep $delay1
   done

   # Step 2: Running on battery: every x seconds check battery voltage flag for 'low battery'.
   #          - If 'low battery', jump directly to shutdown routine (Step 3).
   #         Check if button flag was raised.
   #          - If yes, jump directly to shutdown routine (Step 3).
   #          - If no, check USB power flag ('pg').
   #          - If USB power was returned, jump out of loop (back to Step 1).
   #          - If on battery and not 'low battery', continue looping.

   delay2=10
   echo "Running on battery. Checking battery voltage every $delay2 seconds ..."
   echo "PiVoyager will shut down Pi when battery is depleted (3,1 V)."
   while ! pivoyager status battery | grep low >>/dev/null;
   do
     if pivoyager status flags | grep button >>/dev/null; then
       echo "Button pressed"
       break 2
     else
       # Check whether USB power was restored.
       if pivoyager status flags | grep pg >>/dev/null; then
         echo "USB power restored"
         break 1
       else
         echo "On battery - $(pivoyager status voltage | grep VBat)"
         sleep $delay2
       fi
     fi
   done

done


# Shutdown routine

# Step 3: Initiate shutdown ...

# Enable automatic power-on upon return of USB power
pivoyager enable power-wakeup

# Set full power-off after watchdog time-out (x seconds).
# There are two alternative, mutually exclusive, watchdog functions: I2C or GPIO.

# Enable I2C watchdog & set time-out
#pivoyager watchdog 30

# Enable GPIO watchdog & set time-out
gpio -g mode 26 output
gpio -g write 26 1
pivoyager enable gpio-watchdog
pivoyager watchdog 30; pivoyager disable i2c-watchdog

# Issue OS shut down command on the Raspberry Pi;
# UPS (PiVoyager) will perform full power-off upon expiry of the watchdog time-out. 
sudo shutdown now

# EOF
