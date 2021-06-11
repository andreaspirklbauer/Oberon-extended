# The Extended Oberon operating system and the programming language Oberon-2 (2020 Edition)
The Extended Oberon System is a revision of the *Project Oberon 2013* operating system and its compiler.

Note: In this repository, the term "Project Oberon 2013" refers to a re-implementation of the original "Project Oberon" on an FPGA development board around 2013, as published at www.projectoberon.com.

Features

* Programming language Oberon-2 (2020 Edition), implementing a superset of Oberon-07
* Safe module unloading and module finalization
* System building and maintenance tools
* Smooth line scrolling with variable line spaces
* Multiple logical displays
* Improved decoder tools
* Import any number of modules
* Simple batch execution facility

**Last release:** 19.5.2021

**Last update:** 19.5.2021

The file [**S3RISCinstall.tar.gz**](Documentation/S3RISCinstall.tar.gz) always reflects the *latest* version of Extended Oberon, as described in the file [**EOS_news.txt**](EOS_news.txt).

Documentation: [**Documentation**](Documentation)

------------------------------------------------------

# Instructions for converting an existing Project Oberon 2013 system to Extended Oberon

**PREREQUISITES**: A current version of the Project Oberon 2013 system (see http://www.projectoberon.com).

**NOTE**: If you run Oberon in an emulator on the desktop (e.g., http://github.com/pdewacht/oberon-risc-emu), you can simply backup your existing S3RISCinstall directory, download the compressed archive [**S3RISCinstall.tar.gz**](Documentation/S3RISCinstall.tar.gz) from this repository (containing Extended Oberon) to your emulator directory, run the command *tar xvzf S3RISCinstall.tar.gz* in that directory and then restart the emulator, instead of going through the instructions outlined below.

------------------------------------------------------

**STEP 1**: Build a slightly modified Project Oberon 2013 compiler on your Project Oberon 2013 system

Edit the file *ORG.Mod* on your original system and set the following constants to the indicated new values:

     CONST ...
       maxCode = 8800; maxStrx = 3200; ...

Then recompile your Project Oberon 2013 compiler (and unload the old one):

     ORP.Compile ORS.Mod/s ORB.Mod/s ~
     ORP.Compile ORG.Mod/s ORP.Mod/s ~
     System.Free ORP ORG ORB ORS ~

This step is (unfortunately) necessary since the original Oberon-07 compiler has a tick too restrictive constants. To compile Extended Oberon, one needs slightly more space (in the compiler) for both *code* and *string constants*.

------------------------------------------------------

**STEP 2**: Build a slightly modified version of module Oberon on your Project Oberon 2013 system

Edit the file *Oberon.Mod* on your original system and add the following line anywhere in the source text

     PROCEDURE Return*(n: INTEGER); BEGIN END Return;

Then recompile the following modules on your original system:

     ORP.Compile Oberon.Mod/s ~
     ORP.Compile MenuViewers.Mod/s TextFrames.Mod/s ~
     ORP.Compile System.Mod/s Edit.Mod/s ~
     ORP.Compile Tools.Mod/s PCLink1.Mod/s ~

Then re-compile the Oberon compiler again(!) before (!) restarting the system:

     ORP.Compile ORS.Mod/s ORB.Mod/s ~
     ORP.Compile ORG.Mod/s ORP.Mod/s ~
     ORP.Compile ORL.Mod/s ORX.Mod/s ORTool.Mod/s ~

------------------------------------------------------

**STEP 3:** Restart the Oberon system

You are now running a slightly modified version  of your your original Project Oberon 2013 system.

------------------------------------------------------

**STEP 4**: Download and import the Extended Oberon files to your (slightly modified) Project Oberon 2013 system

Download all files from the [**Sources**](Sources/) directory of this repository. Convert the *source* files to Oberon format (Oberon uses CR as line endings) using the command [**dos2oberon**](dos2oberon), also available in this repository (example shown for Linux or MacOS):

     for x in *.Mod *.Tool ; do ./dos2oberon $x $x ; done

Import the files to your Oberon system. If you use an emulator, click on the *PCLink1.Run* link in the *System.Tool* viewer, copy the files to the emulator directory, and execute the following command on the command shell of your host system:

     cd oberon-risc-emu
     for x in *.Mod *.Tool *.Scn.Fnt ; do ./pcreceive.sh $x ; sleep 0.5 ; done

Open the Extended Oberon version of the [**System.Tool**](Sources/System.Tool) viewer in the system track of your Project Oberon 2013 system, so that you can directly activate the compilations needed to build Extended Oberon:

     System.Open System.Tool

If you just follow the compilation sequence shown in *System.Tool*, you should be done with the remaining steps in a few seconds!

------------------------------------------------------

**STEP 5:** Build a cross-development toolchain by compiling the "new" compiler and boot linker/loader on the "old" system

     ORP.Compile ORS.Mod/s ORB.Mod/s ~
     ORP.Compile ORG.Mod/s ORP.Mod/s ~

Temporarily compile module *Disk* with the "old" compiler on the "old" system, so it can be used by the cross-linker *ORL* (this works, because module *Disk* is written such that it can be compiled under both Project Oberon 2013 and Extended Oberon). Note that module *Disk* will later be recompiled again with the "new" compiler (for execution in Extended Oberon).

     ORP.Compile Disk.Mod/s ~

Compile the remaining modules of the cross-development toolchain (where *ORL* uses a temporary version of *Disk*):

     ORP.Compile ORL.Mod/s ORX.Mod/s ORTool.Mod/s ~
     System.Free ORTool ORP ORG ORB ORS ORL ORX ~

------------------------------------------------------

**STEP 6:** Use the cross-development toolchain on your Project Oberon 2013 system to build Extended Oberon

First, load the temporary version of ORL (using module *Disk* compiled for the "old" system):

     ORL.Link nonexistingmodulename ~   # load the "old" version of module Disk into memory, so module Disk can be safely re-compiled below

This step is absolutely necessary! Otherwise the next command below (*ORP.Compile Kernel.Mod/s Disk.Mod/s ...*) would create a "new" version of module *Disk* (i.e. a version that is compiled for Extended Oberon), before the command *ORL.Link* gets a chance to load the "old" version into memory.

Compile the *inner core* of Extended Oberon and load it onto the boot area of the local disk:

     ORP.Compile Kernel.Mod/s Disk.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~    # modules for the "regular" boot file for Extended Oberon
     ORL.Link Modules ~                                                    # generate a pre-linked binary file of the "regular" boot file (Modules.bin)
     ORL.Load Modules.bin ~                                                # load the "regular" boot file onto the boot area of the local disk

This step is possible, because module *ORL* is written such that it can be executed on both the Project Oberon 2013 and the Extended Oberon system. It produces output using the Extended Oberon module and object file format.

Release the temporary versions of modules *ORL* and *Disk* (compiled for the "old" system), as they are no longer needed:

     System.Free ORL Disk ~

Compile the remaining modules of Extended Oberon:

     ORP.Compile Input.Mod/s Display.Mod/s Viewers.Mod/s ~
     ORP.Compile Fonts.Mod/s Texts.Mod/s Oberon.Mod/s ~
     ORP.Compile MenuViewers.Mod/s TextFrames.Mod/s ~
     ORP.Compile System.Mod/s Edit.Mod/s Tools.Mod/s ~

------------------------------------------------------

**STEP 7:** Re-compile the Oberon compiler itself before (!) restarting the system:

     ORP.Compile ORS.Mod/s ORB.Mod/s ~
     ORP.Compile ORG.Mod/s ORP.Mod/s ~
     ORP.Compile ORL.Mod/s ORX.Mod/s ORTool.Mod/s ~

This step is necessary because Extended Oberon uses a different Oberon object file format (the currently loaded Extended Oberon compiler runs under Project Oberon 2013, but wouldn't be able to run under Extended Oberon).

------------------------------------------------------

**STEP 8:** Restart the Oberon system

You are now running Extended Oberon. Re-compile any other modules that you may have on your system.
