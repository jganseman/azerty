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

Usage
-----

Just run the .com file in the Windows command line as if it were an executable. Make sure the codepage is set to 850 (DOS-Latin1), eventually by running "mode con cp select=850" first.

Known issues
------------

- Acute, grave and caret accents are now active keys, not dead keys (i.e. there is no waiting for the next characters, instead they produce the accents on their own). It is therefore not possible to type É or È in capital letters, or any other accented character than those available on the Azerty keyboard. 
- Nothing much is done with the Alt+Shift or Ctrl+Shift possibilities for the moment, though they seem to give some result in the NTVDM giving access to more exotic characters of the codepage. Maybe I'll figure it out in the future.

Credits
-------

Many thanks go to J. Tucht who wrote the QWERTZ driver on which this AZERTY driver is based.
