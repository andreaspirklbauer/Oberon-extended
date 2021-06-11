# ---------------------------------------------------------------------------------------------------------------------
#  1. Compile the modules needed for Oberon system building
# ---------------------------------------------------------------------------------------------------------------------
ORP.Compile Kernel.Mod Disk.Mod FileDir.Mod Files.Mod Modules.Mod ~      # modules for the "regular" boot file
ORP.Compile RS232.Mod PCLink0.Mod Oberon0.Mod ~    # additional modules for the "build-up" boot file
ORP.Compile ORC.Mod/s Oberon0Tool.Mod/s ~     # partner program ORC and Oberon0 tool module
ORP.Compile BootLoad.Mod/s ~        # the regular Oberon boot loader
ORP.Compile BootLoadDisk.Mod/s ~    # a boot loader for booting the target system from the local disk
ORP.Compile BootLoadLine.Mod/s ~    # a boot loader for booting the target system over the data link
ORP.Compile ORL.Mod/s ORX.Mod/s ~   # the Oberon boot linker/loader and boot converter

# ---------------------------------------------------------------------------------------------------------------------
#  2. Link the modules needed for Oberon system building
# ---------------------------------------------------------------------------------------------------------------------
ORL.Link Modules ~        # generate a pre-linked binary file of the "regular" boot file (Modules.bin)
ORL.Link Oberon0 ~        # generate a pre-linked binary file of the "build-up" boot file (Oberon0.bin)

# ---------------------------------------------------------------------------------------------------------------------
#  3. Update the boot area of the local disk with the "regular" boot file
# ---------------------------------------------------------------------------------------------------------------------
ORL.Load Modules.bin ~    # load the "regular" boot file onto the boot area of the local disk

# ---------------------------------------------------------------------------------------------------------------------
#  4. Build Oberon on the target system connected to the host system via a data link (e.g., RS232 line)
#     (restart the target system over the data link, then execute the following commands on the host system)
# ---------------------------------------------------------------------------------------------------------------------
#
# ORC.Load Oberon0.bin ~          ->  load the Oberon-0 command interpreter over the data link to the target system AND start it
# ORC.SR 8 1234 ~                 ->  test whether the Oberon-0 command interpreter is running (send and mirror integer s)
# ORC.SR 101 ~                    ->  clear the file directory on the target system
# ORC.Send ... ~                  ->  send the required (plus some additional) files to the target system
# ORC.SR 100 Modules.bin ~        ->  load the "regular" boot file onto the boot area of the local disk of the target system
# ORC.SR 102 BootLoadDisk.rsc ~   ->  reboot the target system from the local disk (i.e. initiate the "regular" boot process)
# ORC.SR 20 Oberon ~              ->  alternatively, one can simply load module Oberon on the target system
#

Oberon.Batch
  ORC.Load Oberon0.bin ~
  ORC.SR 8 1234 ~
  ORC.SR 101 ~
  ORC.Send Modules.bin Oberon10.Scn.Fnt System.Tool
      Input.rsc Display.rsc Viewers.rsc
      Fonts.rsc Texts.rsc Oberon.rsc
      MenuViewers.rsc TextFrames.rsc System.rsc
      BootLoadDisk.rsc ORL.rsc
      RS232.rsc PCLink0.rsc
      Oberon0.rsc Oberon0Tool.rsc
      Edit.rsc PCLink1.rsc
      ORP.rsc ORG.rsc
      ORB.rsc ORS.rsc ORTool.rsc ~
  ORC.SR 100 Modules.bin ~
  ORC.SR 102 BootLoadDisk.rsc ~
~

# ---------------------------------------------------------------------------------------------------------------------
#  5. Load an ENTIRE Oberon system in a single boot file to a target system WITHOUT rebuilding the target system
#     (restart the target system over the data link, then execute the following commands on the host system)
# ---------------------------------------------------------------------------------------------------------------------
ORP.Compile System1.Mod/s ~                # compile the files needed to include an ENTIRE Oberon system in a boot file
ORL.Link System1 ~                         # generate a boot file containing the ENTIRE Oberon system (System1.bin)
ORC.Load System1.bin ~                     # load the ENTIRE Oberon system over the data link to the target system AND start it

# ---------------------------------------------------------------------------------------------------------------------
#  6. Load an ENTIRE Oberon system in a single boot file to a target system AND rebuild the target system
#     (restart the target system over the data link, then execute the following commands on the host system)
# ---------------------------------------------------------------------------------------------------------------------
ORP.Compile System1.Mod/s ~                              # compile the files needed to include an ENTIRE Oberon system in a boot file
ORL.Link Modules ~                                       # (optional) generate a REGULAR boot file (Modules.bin)
ORL.Link System1 ~                                       # generate a boot file containing the ENTIRE Oberon system (System1.bin)
ORC.Load System1.bin ~                                   # load the ENTIRE Oberon system over the data link to the target system AND start it
ORC.SR 101 ~                                             # clear the file directory on the target system
ORC.Send System1.bin Oberon10.Scn.Fnt System.Tool
      BootLoadDisk.rsc ORL.rsc
      RS232.rsc PCLink0.rsc
      Oberon0.rsc Oberon0Tool.rsc
      Edit.rsc PCLink1.rsc
      ORP.rsc ORG.rsc
      ORB.rsc ORS.rsc ORTool.rsc ~         # Group A: send the files for booting with a boot file containing the ENTIRE Oberon system to the target system
ORC.Send Modules.bin
      Input.rsc Display.rsc Viewers.rsc
      Fonts.rsc Texts.rsc Oberon.rsc
      MenuViewers.rsc TextFrames.rsc
      System.rsc ~                         # Group B (optional): send the files for booting with the REGULAR boot file to the target system
# Decide which boot file to load onto the boot area of the disk of the target system (sectors 2-159)
ORC.SR 100 System1.bin ~        # EITHER load the boot file containing the ENTIRE Oberon system onto the boot area
ORC.SR 100 Modules.bin ~        # OR load the REGULAR boot file onto the boot area (requires the files from group B above)
# Reboot the target system
ORC.SR 102 BootLoadDisk.rsc ~   # reboot the target system from its local disk (i.e. initiate the "regular" boot process)

# ---------------------------------------------------------------------------------------------------------------------
#  7. Extract the code section of the boot loader and convert it to a PROM file in hex format
# ---------------------------------------------------------------------------------------------------------------------
ORP.Compile BootLoad.Mod/s ~
ORX.WriteFile BootLoad.rsc BootLoad.mem ~

# -------------------------------------------------------------------------------------------------
#  8. Other Oberon-0 commands
# -------------------------------------------------------------------------------------------------
Rebooting

  ORC.Send Modules.bin ~              # send the "regular" boot file to the target system
  ORC.SR 100 Modules.bin ~            # load the "regular" boot file onto the boot area of the local disk of the target system

  ORC.Send BootLoadDisk.rsc ~         # send the boot loader for booting from the local disk of the target system
  ORC.SR 102 BootLoadDisk.rsc ~       # reboot from the boot area of the local disk ("regular" boot process)

  ORC.Send BootLoadLine.rsc ~         # send the boot loader for booting the target system over the serial link
  ORC.SR 102 BootLoadLine.rsc ~       # reboot the target system over the serial link ("build-up" boot process)
  ORC.Load Oberon0.bin ~              # after booting over the data link, one needs to run ORC.Load Oberon0.bin again

System

  ORC.SR 7 ~                          # show allocation, nof sectors, switches, and timer
  ORC.SR 8 1234 ~                     # send and mirror integer s (test whether the Oberon-0 command interpreter is running)

Files

  ORC.Send System.Tool ~              # send a file to the target system
  ORC.Receive System.Tool ~           # receive a file from the target system
  ORC.SR 13 System.Tool ~             # delete a file on the target system

  ORC.SR 12 "*.rsc" ~                 # list files matching the specified prefix
  ORC.SR 12 "*.Mod!" ~                # list files matching the specified prefix and the directory option set
  ORC.SR 4 System.Tool ~              # show the contents of the specified file

Modules

  ORC.SR 10 ~                         # list modules on the target system
  ORC.SR 11 Kernel ~                  # list commands of a module on the target system
  ORC.SR 22 M.P ~                     # call command on the target system

  ORC.SR 20 Oberon ~                  # load module on the target system
  ORC.SR 21 Edit ~                    # unload module on the target system

Disk

  ORC.SR 3 123 ~                      # show sector   secno
  ORC.SR 52 123 3 10 20 30 ~          # write sector  secno, n, list of n values (words)
  ORC.SR 53 123 3 ~                   # clear sector  secno, n (n words))

Memory

  ORC.SR 1 50000 16 ~                 # show memory   adr, n words (in hex) M[a], M[a+4], ..., M[a+(n-1)*4]
  ORC.SR 50 50000 3 10 20 30 ~        # write memory  adr, n, list of n values (words)
  ORC.SR 51 50000 32 ~                # clear memory  adr, n (n words))

Display

  ORC.SR 2 0 ~                        # fill display with words w (0 = black)
  ORC.SR 2 4294967295 ~               # fill display with words w (4294967295 = white)

