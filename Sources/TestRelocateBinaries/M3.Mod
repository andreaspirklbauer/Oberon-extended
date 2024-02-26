MODULE M3;  (*no asterisk after the keyword MODULE / AP 1.3.24 Extended Oberon*)
  IMPORT SYSTEM, M0, M1, M2;  (*import constants only*)
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

ORP.Compile M0.Mod/s M1.Mod/s M2.Mod/s M3.Mod/s ~
ORL.Link M3 ~                      # default destadr = 0
ORL.Relocate M3.bin M4.bin 1024 ~  # relocate the prelinked binary to destadr = 1024

ORL.Execute M1.rsc ~    # see the source file M1.Mod
Tools.Inspect 0 ~       # displays:  .... .... 0000000A .... ....

ORL.Run M3.bin ~        # automatically relocates the binary from destadr 0 to its actual memory location
ORL.Run M4.bin ~        # automatically relocates the binary from destadr 1024 to its actual memory location
Tools.Inspect 0 ~       # displays:  ... ... ... ... 0000000C 0000000D 0000000E ...

