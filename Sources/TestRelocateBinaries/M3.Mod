MODULE M3;  (*no asterisk after the keyword MODULE*)
  IMPORT SYSTEM, M0, M1, M2;  (*import constants only for RunRsc*)
  TYPE Ptr3* = POINTER TO Rec3;
    Rec3* = RECORD (M2.Rec2) x: INTEGER END ;

  VAR i0, i1, i2: INTEGER;

  PROCEDURE P3*; BEGIN END P3;

  PROCEDURE (VAR rec: Rec3) Method20* (str: ARRAY OF CHAR; p: LONGINT);  (*redefinition*)
  BEGIN END Method20;

  PROCEDURE (ptr: Ptr3) Method31* (str: ARRAY OF CHAR; p: LONGINT);
  BEGIN END Method31;

  PROCEDURE Do*;
  BEGIN i0 := M0.C0 + 2; SYSTEM.PUT(16, i0);  (*12 decimal = C hexadecimal*)
    i1 := M1.C1 + 2; SYSTEM.PUT(20, i1);  (*13 decimal = D hexadecimal*)
    i2 := M2.C2 + 2; SYSTEM.PUT(24, i2)   (*14 decimal = E hexadecimal*)
  END Do;
BEGIN Do
END M3.

ORP.Compile Run.Mod/s M0.Mod/s M1.Mod/s M2.Mod/s M3.Mod/s ~
ORL.Link M3 ~                      # default destadr = 0
ORL.Relocate M3.bin M4.bin 1024 ~  # relocate the prelinked binary to destadr = 1024

Run.RunRsc M1.rsc ~   # see the source file M1.Mod
Tools.Inspect 0 ~     # yields this output:  .... .... 0000000A .... ....

ORL.Execute M3.bin ~  # will automatically relocate the binary from destadr 0 to its actual memory location
ORL.Execute M4.bin ~  # will automatically relocate the binary from destadr 1024 to its actual memory location
Tools.Inspect 0 ~     # yields this output:  ... ... ... ... 0000000C 0000000D 0000000E ...

