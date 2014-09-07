azerty
======

Azerty keyboard driver for use in Microsoft's NTVDM DOS environment.

16-bit DOS applications can run on recent 32-bit Windows machines (in my case Win7) because of the presence of an MS-DOS virtual machine, called NTVDM.
However, after loading the AZERTY keyboard (with the command "kb16 be" or "kb16 fr"), you'll note that e.g. the AltGR key is not functional. Support for keyboards other than QWERTY isn't even fully implemented...
After a long search, I found a German QWERTZ-driver from 1990 coded in Assembly, and decided to give it a go to adapt it to AZERTY.

Contents
--------

This repository contains the original driver which I adapted, the Assembly file with the code, and the .COM file which just has to be run in DOS to load the driver.

Building
--------

You will need the MASM32 toolkit and a decent Hex editor to build this driver from the code. Instructions can be found in the .ASM file.
