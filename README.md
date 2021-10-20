# PiVoyager-UPS

The control script should be used as described in OMZLO's PiVoyager documentation.

To safeguard the Pi against 'freezing' of the OS, use the Raspberry Pi hardware watchdog. The PiVoyager watchdog cannot serve to this purpose as communications between Pi and UPS board also break when the Pi would crash/freeze.
