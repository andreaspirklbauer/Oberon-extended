#!/bin/sh
#
#  buildtarget.sh -- simulate building an Oberon system on a target machine
#
#  Description:
#
#    When using an Oberon emulator, this script simulates the process of
#    booting a target system connected to a host system via a data link.
#
#    This is done by starting TWO emulator instances connected via TWO
#    Unix-style pipes, one for each direction.
#
#    This script must be executed IN the directory of the Oberon emulator,
#    which has a subdirectoy S3RISCinstall (containing an image RISC.img)
#
#    Note: When started, the windows of the two emulator instances overlap.
#
# ----------------------------------------------------------------------------------------

# create two pipes (one for each direction) linking the host and the target system
mkfifo pipe1 pipe2  2>/dev/null

# delete any old disk images for the host and the "target" system (optional)
rm -f ob1.dsk ob2.dsk                 

# make a copy of a valid Oberon disk image to be used for the "host" system
cp S3RISCinstall/RISC.img ob1.dsk     

# create an "empty" disk image for the target system (will be "filled" later)
touch ob2.dsk                         

# start the "target" system over the serial link (connected to the host system)
 ./risc --serial-in pipe2 --serial-out pipe1 ob2.dsk --boot-from-serial &
sleep 3

# start the "host" system from a local disk
 ./risc --serial-in pipe1 --serial-out pipe2 ob1.dsk &

