# PiVoyager-UPS

The control script should be used as described in OMZLO's PiVoyager documentation.
It caters for button presses and USB power failure with shut-down and power cut-off when the battery is depleted (less than 3,1 V). Upon return of USB power the Pi will be started automatically when the battery reaches 3,3 V per the original documentation.

Please note: performing shutdown as a terminal command or via the GUI will require pressing the PiVoyager's button to make the Pi start up again. Therefore, if the Pi is shut down remotely, control will be lost and require physical access to the Pi/PiVoyager combination.

To safeguard the Pi against 'freezing' of the OS, by rebooting a crashed Pi, use the Raspberry Pi hardware watchdog, which makes use of the PI's GPU. The PiVoyager watchdog cannot serve this purpose as communications between Pi and UPS board breaks when the Pi crashes/freezes.
The hardware watchdog can be tested with the so-called 'forkbomb'.
