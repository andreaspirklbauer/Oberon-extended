MODULE M5;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT Out;

  TYPE
    Ptr* = POINTER TO Rec;
    Rec* = RECORD x*: INTEGER END ;

  VAR ptr: Ptr;

  PROCEDURE (p: Ptr) Method (s: ARRAY OF CHAR);
  BEGIN Out.String("  Hello from M0.Ptr.Method, "); Out.String(s); Out.Int(p.x, 4); Out.Ln
  END Method;

  PROCEDURE (p: Ptr) ExportedMethod* (s: ARRAY OF CHAR);
  BEGIN Out.String("  Hello from M0.Ptr.ExportedMethod, "); Out.String(s); Out.Int(p.x, 4); Out.Ln;
    p.Method(s)
  END ExportedMethod;

  PROCEDURE Go*;
  BEGIN ptr.ExportedMethod("M5")
  END Go;

BEGIN NEW(ptr); ptr.x := 5
END M5.

ORP.Compile M5.Mod/s ~
System.Free M5 ~
M5.Go ~