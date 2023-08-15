MODULE M7;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT M6, Out;

  VAR ptr: M6.Ptr;
    
  PROCEDURE Go*;
  BEGIN ptr.ExportedMethod("M7")
  END Go;

BEGIN NEW(ptr); ptr.x := 7
END M7.

ORP.Compile M5.Mod/s M6.Mod/s M7.Mod/s ~
System.Free M7 M6 M5 ~
M7.Go ~
M6.Go ~
M5.Go
