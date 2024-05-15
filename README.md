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

**Last release:** 15.5.2024 / Extended-Oberon-1.14

**Last update:** 15.5.2024

The file [**S3RISCinstall.tar.gz**](Documentation/S3RISCinstall.tar.gz) always reflects the *latest* version of Extended Oberon.

The file [**EOS_news.txt**](EOS_news.txt) describes the changes made to Extended Oberon.

Documentation: [**Documentation**](Documentation)

------------------------------------------------------

# Instructions for running Extended Oberon

**To obtain Extended Oberon**:

- Download the compressed archive [**S3RISCinstall.tar.gz**](Documentation/S3RISCinstall.tar.gz) from this repository

**To run Extended Oberon in an emulator** (e.g., http://github.com/pdewacht/oberon-risc-emu):

- Backup your existing *S3RISCinstall* directory
- Uncompress the downloaded archive in the emulator directory *S3RISCinstall*
  - On Unix/Linux/Mac, run the command **tar xvzf S3RISCinstall.tar.gz**
  - On Windows, use one of the available Zip tools such as *WinZip*, *7-Zip*, ...
- Restart the emulator

**To run Extended Oberon on a FGPA development board**:

- Uncompress the downloaded archive
  - On Unix/Linux/Mac, run the command **tar xvzf S3RISCinstall.tar.gz**
  - On Windows, use one of the available Zip tools, such as *WinZip*, *7-Zip*, ...
- Transfer the file *RISC.img* to an SD-card as a *raw image* (do not simply copy the file)
  - On Unix/Linux/Mac, run the command **ls -l RISC.img** (to get the file size of *RISC.img*) followed by the command **dd if=RISC.img of=/dev/sdc bs=1024 count=filesize** (replace */dev/sdc* with the device name on your system and *filesize* with the actual file size)
  - On Windows, use one of the available SD tools, such as *Win32 Disk Imager*, ...
- Insert the SD-card in the FPGA board/daughterboard, verify that everything is connected
- Cold-start the FPGA board/daughterboard by pressing the appropriate button on the board
