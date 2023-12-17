# The Extended Oberon operating system and the programming language Oberon-2 (2020 Edition)
The Extended Oberon System is a revision of the *Project Oberon 2013* operating system and its compiler.

Note: In this repository, the term "Project Oberon 2013" refers to a re-implementation of the original "Project Oberon" on an FPGA development board around 2013, as published at www.projectoberon.com.

Features

* Programming language Oberon-2 (2020 Edition) defined as a superset of the Oberon-07 language
* Safe module unloading and module finalization
* System building and maintenance tools
* Smooth line scrolling with variable line spaces
* Multiple logical displays
* Improved decoder tools
* Improved import/export, e.g. import any number of modules and in any order
* Simple batch execution facility

**Last release:** 1.11.2023 / Extended-Oberon-1.8

**Last update:** 17.12.2023

The file [**S3RISCinstall.tar.gz**](Documentation/S3RISCinstall.tar.gz) always reflects the *latest* version of Extended Oberon, as described in the file [**EOS_news.txt**](EOS_news.txt).

Documentation: [**Documentation**](Documentation)

------------------------------------------------------

# Instructions for converting an existing Project Oberon 2013 system to Extended Oberon

If you run Oberon in an emulator on the desktop (e.g., http://github.com/pdewacht/oberon-risc-emu), you can simply backup your existing S3RISCinstall directory, download the compressed archive [**S3RISCinstall.tar.gz**](Documentation/S3RISCinstall.tar.gz) from this repository (containing Extended Oberon) to your emulator directory, run the command *tar xvzf S3RISCinstall.tar.gz* in that directory and then restart the emulator.

