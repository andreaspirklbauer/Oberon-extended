MODULE M1;  (*AP 1.5.21 Extended Oberon*)
  IMPORT SYSTEM, M0;
  CONST C1* = 11;  (*11 decimal = B hexadecimal*)
BEGIN SYSTEM.PUT(8, M0.C0)   (*10 decimal = A hexadecimal*)
END M1.

ORP.Compile Run.Mod/s M0.Mod/s M1.Mod/s ~

Run.RunRsc M1.rsc ~  
Tools.Inspect 0 ~   # yields this output:  .... .... 0000000A .... ....

# This experiment executes a single object file M.rsc which imports
# only constants from other modules (module M0 in this example).
#
# Note that there is NO asterisk after the key word MODULE
# of module M1. Thus, M1 is NOT compiled as a "standalone program".
#
# This is just so that M1 does not jump to memory address 0 at the end.
#
# But one CAN of course compile module M1 also WITH the asterisk. The
# only difference is that there are modified start and ending sequences.
#
# Thus, there is no reason why this wouldn't work with the boot loader
# (so long as the boot loader only imports modules containing constants).
