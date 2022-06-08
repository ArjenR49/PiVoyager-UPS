#!/bin/bash

# PiVoyager UPS control script

# PiVoyager watchdog function takes care of cutting power to the Pi
# after shutdown forced by a battery low situation through this script/service.

# To make the Pi reboot automatically in case it crashes, install and
# enable the hardware watchdog, which makes use of the GPU on the Pi.
# Test with 'forkbomb'.

# Short button press: shutdown & delayed power-off.

# When on battery: shutdown & delayed power-off as soon as battery is depleted
# (depletion limit set by f/w is 3,10 V).
# Automatic power-on when USB power is restored.

# In case the Pi was shut down by virtue of the UPS button
# while USB power was present, a wakeup alarm is set in PiVoyager
# to make the Pi restart automatically after 3600 seconds.

# Developed from the original OMZLO PiVoyager sample UPS script example.
# ar - 06-10-2021, 10-10-2021, 16-10-2021, 19-10-2021, 20-10-2021, 07-04-2022,
#      25-04-2022, 26-04-2022, 30-04-2022, 01-05-2022, 08-05-2022

# Synchronize PiVoyager RTC
pivoyager date sync

# Initialize variables
FullyCharged=0

# Main control loop is infinite and contains two infinite loops,
# one for the 'USB power' state and one for ''On Battery' state.
# Exiting these loops is only through break statements (see code)
# which cause the shut down script in step 3 to be executed.

while true;
do

   # Step 1: Every x seconds check if button flag was raised.
   #          - If yes, jump directly to shutdown routine (Step 3).
   #          - If no, check USB power flag ('pg').
   #          - If USB power lost, jump to battery voltage check loop (Step 2).
   #          - If USB power present, continue looping.

   delay1=10
   echo Checking USB power every $delay1 seconds ...
   i=0
   while true;
   do
     if pivoyager status flags | grep button >>/dev/null; then
       # Button pressed.
       break 2                  # Jump to Step 3
     else
       if ! pivoyager status flags | grep pg >>/dev/null; then
         echo USB power lost
	       FullyCharged=0
         break 1                # Jump to Step 2
       fi
     fi
     # Write charging status & battery voltage to the system log
     # only every 6th time, and only until battery fully charged
     # to prevent filling the system log with useless information.
     if ! pivoyager status battery | grep "charge complete" >>/dev/null; then
       # Print voltage to system log only every 6th time
       if [ $(expr $i % 6) == 0 ]; then echo $(pivoyager status voltage | grep VBat | sed "s/\./,/;s/V/\ V/2;s/VBat/Battery charging/"); fi
	     FullyCharged=0
       (( i++ ))
     else
       if [ $FullyCharged == 0 ]; then echo $(pivoyager status voltage | grep VBat | sed "s/\./,/;s/V/\ V/2;s/VBat/Battery charging completed/"); fi
	     FullyCharged=1
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
   echo Running on battery. Checking battery voltage every $delay2 seconds ...
   echo PiVoyager shuts down Pi when battery is depleted \(3,1 V\).
   i=0
   while true;
   do
     if  pivoyager status battery | grep low    >>/dev/null || \
         pivoyager status flags   | grep button >>/dev/null    ; then
       # Button pressed or battery low.
       break 2                      # Jump to Step 3
     else
       # Check whether USB power was restored.
       if pivoyager status flags | grep pg >>/dev/null; then
         echo USB power restored
         break 1                    # Back to Step 1
       else
         # Write voltage to system log only every 6th time
         # to prevent filling the log with useless information.
         if [ $(expr $i % 6) == 0 ]; then echo On battery - $(pivoyager status voltage | grep VBat | sed "s/\./,/;s/V/\ V/2;s/VBat/Battery voltage/"); fi
         (( i++ ))
         sleep $delay2
       fi
     fi
   done

done


# Step 3: Initiate shutdown routine ...

# Message to system log
echo Either battery is depleted \(\< 3,1 V\) or button was pressed.
echo A shutdown command halts the OS immediately and subsequently
echo the Pi is powered off by the UPS 30 seconds later
echo by virtue of PiVoyager\'s watchdog timing out.
echo However, the Pi will be restarted 3600 seconds later
echo by virtue of the PiVoyager alarm function.

# Synchronize PiVoyager RTC
pivoyager date sync

# Set alarm to restart Pi after 3600 seconds in case it was halted
# and powered off by 'button press' rather than by 'battery low',
# but not restarted manually within the hour (3600 seconds) ...
if ! pivoyager status battery | grep low >>/dev/null; then pivoyager wakeup 3600; fi

# Enable automatic power-on upon return of USB power
pivoyager enable power-wakeup

# Set full power-off after watchdog time-out (x seconds).
# PiVoyager UPS has two mutually exclusive watchdog functions: I2C or GPIO.

# Enable I2C watchdog & set time-out
#pivoyager watchdog 30

# Enable GPIO watchdog & set time-out
gpio -g mode 26 output
gpio -g write 26 1
pivoyager enable gpio-watchdog
pivoyager watchdog 30
pivoyager disable i2c-watchdog

# Issue OS shutdown command on the Raspberry Pi;
sudo shutdown now

# The UPS (PiVoyager f/w) performs a full power-off upon expiry of the watchdog time-out. 

# EOF
