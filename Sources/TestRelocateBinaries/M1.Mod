MODULE M1;  (*AP 1.3.24 Extended Oberon*)
  IMPORT SYSTEM, M0;
  CONST C1* = 11;  (*11 decimal = B hexadecimal*)
BEGIN SYSTEM.PUT(8, M0.C0)   (*10 decimal = A hexadecimal*)
END M1.

ORP.Compile M0.Mod/s M1.Mod/s ~

ORL.Execute M1.rsc ~  
Tools.Inspect 0 ~       # displays:  .... .... 0000000A .... ....

# Executes a single object file M.rsc which imports only constants from other modules.
#
# There is NO asterisk after the key word MODULE of module M1.
# Therefore, M1 is NOT compiled as a "standalone program".
# This is to make sure that M1 does not jump to memory address 0 at the end.
#
# But one CAN of course compile module M1 also WITH the asterisk. The
# only difference is that there are modified start and ending sequences.
#
# Thus, there is no reason why this shouldn't work with the boot loader
# so long as the boot loader only imports modules containing constants.

