MODULE M6;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT M5, Out;

  TYPE Ptr* = M5.Ptr;

  VAR ptr*: M5.Ptr;  (*re-export type M0.Ptr*)

  PROCEDURE Go*;
  BEGIN ptr.ExportedMethod("M6")
  END Go;

BEGIN NEW(ptr); ptr.x := 6
END M6.

ORP.Compile M5.Mod/s M6.Mod/s ~
System.Free M6 M5 ~
M6.Go ~
M5.Go
