MODULE M1;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT M0, Out;

  TYPE
    PtrRec1Ext1* = POINTER TO Rec1Ext1;

    Rec1Ext1* = RECORD (M0.Rec1) x2, y2*: INTEGER END ;
    Rec1Ext2* = RECORD (M0.Rec1) z2*: INTEGER END ;  (*at same extension level as Rec1Ext1*)
    Rec1Ext11* = RECORD (Rec1Ext1) END ;  (*emtpy field list must be handled correctly*)
    Rec1Ext12* = RECORD (Rec1Ext1) m2, n2*: CHAR END ;
    Rec1Ext123* = RECORD (Rec1Ext11) p3, q3*, r3*: CHAR END ;

  VAR count: INTEGER;
    rec1ext1*: Rec1Ext1; rec1ext11*: Rec1Ext11; rec1ext123*: Rec1Ext123;
    ptrrec1ext1*: PtrRec1Ext1;

  PROCEDURE (VAR rec: Rec1Ext1) Method1* (str: ARRAY OF CHAR; p: LONGINT); (*overrides M0.Rec1.Method1*)
  BEGIN Out.String("  Hello from M1.Rec1Ext1.Method1 (overrides M0.Rec1.Method1); str = "); Out.String(str);
    Out.String(", cnt ="); Out.Int(p, 4); Out.Ln;
    Out.String("  Calling super method M1.Rec1Ext1.Method1^ = M0.Rec1.Method1 with str = "); Out.String(str); Out.Ln;
    rec.Method1^(str, p)
  END Method1;

  (*
  PROCEDURE (VAR rec: Rec1Ext1) Method1P (str: ARRAY OF CHAR; p: LONGINT); (*private*)
  BEGIN rec.Method1^(str, p)  (*would lead to a "redefined method must be called from overriding method" error*)
  END Method1P;

  PROCEDURE (VAR rec: Rec1Ext1) Method2P (str: ARRAY OF CHAR; p: LONGINT); (*private*)
  BEGIN rec.Method1^(str, p)  (*would lead to a "redefined method must be called from overriding method" error*)
  END Method2P;
  *)
  
  PROCEDURE (VAR rec: Rec1Ext1) Method2* (str: ARRAY OF CHAR; p: LONGINT); (*exported*)
  BEGIN Out.String("  Hello from M1.Rec1Ext1.Method2 (overwritten method); str = "); Out.String(str);
    Out.String(", cnt ="); Out.Int(p, 4); Out.String(", rec.x1 ="); Out.Int(rec.x1, 4); INC(rec.x1); Out.Ln;
    Out.String("  Calling super method M1.Rec1Ext1.Method2^ = M0.Rec1.Method2 with str = Method2"); Out.Ln;
    rec.Method2^("Method2", p)
  END Method2;

  PROCEDURE (ptr: PtrRec1Ext1) Method3* (str: ARRAY OF CHAR; p: LONGINT);
  BEGIN Out.String("  Hello from M1.PtrRec1Ext1.Method3; str = "); Out.String(str); Out.String(", cnt ="); Out.Int(p, 4); Out.Ln;
    Out.String("  Calling super method M1.PtrRec1Ext1.Method3^ = M0.PtrRec1.Method3 with str = "); Out.String(str); Out.Ln;
    ptr.Method3^(str, p)
  END Method3;

  PROCEDURE (VAR rec: Rec1Ext12) Method2b* (str: ARRAY OF CHAR; p: LONGINT);
    BEGIN Out.String("  Hello from M1.Rec1Ext12.Method2b"); Out.Ln
  END Method2b;

  PROCEDURE (VAR rec: Rec1Ext2) Method1c* (str: ARRAY OF CHAR; p: LONGINT); (*method at lower ext level OK if not a base type*)
  BEGIN rec.Method1(str, p)
  END Method1c;

  PROCEDURE (VAR rec: Rec1Ext11) Method2a* (str: ARRAY OF CHAR; p: LONGINT);
  BEGIN Out.String("  Hello from M1.Rec1Ext11.Method2a"); Out.Ln;
    (*rec.Method2a^(str, p)*)  (*would lead to "method undefined in base types"* error mesage*)
  END Method2a;

  PROCEDURE (VAR rec: Rec1Ext11) Method2c* (str: ARRAY OF CHAR; p: LONGINT);  (*another method at the same ext level is ok*)
  BEGIN rec.Method2a(str, p)
  END Method2c;

  PROCEDURE (VAR rec: Rec1Ext11) Method2* (str: ARRAY OF CHAR; p: LONGINT); (*overrides Rec1Ext1.Method2 declared above*)
  BEGIN Out.String("  Hello from M1.Rec1Ext11.Method2 (overrides M1.Rec1Ext1.Method2); str = "); Out.String(str);
    Out.String(", cnt = "); Out.Int(p, 4); Out.Ln;
    Out.String("  Calling super method M1.Rec1Ext11.Method2^ = M1.Rec1Ext1.Method2 with str = Method2, cnt = "); Out.Int(p, 4); Out.Ln;
    rec.Method2^(str, p)
  END Method2;

  PROCEDURE (VAR rec: Rec1Ext123) M3* (str: ARRAY OF CHAR; p: LONGINT); (*one ext level higher is also ok*)
  BEGIN rec.Method1(str, p)
  END M3;

  PROCEDURE Go1*;
  BEGIN Out.String("Calling M1.Rec1Ext1.Method1 with str = Method1, count = "); Out.Int(count, 4); Out.Ln;
    rec1ext1.x1 := 11; rec1ext1.Method1("Method1", count); INC(count)
  END Go1;

  PROCEDURE Go2*;
  BEGIN Out.String("Calling M1.Rec1Ext11.Method2 with str = Method2, count = "); Out.Int(count, 4); Out.Ln;
    rec1ext11.x1 := 22; rec1ext11.Method2("Method2", count); INC(count)
  END Go2;

  PROCEDURE Go3*;
  BEGIN Out.String("Calling M0.ptrrec1.Method3 with str = Method3, count = "); Out.Int(count, 4); Out.Ln;
    (*M0.ptrrec1.x1 := 33;*) (*would lead to a "read-only" error*)
    M0.ptrrec1.Method3("Method3", count); INC(count)  (*external pointer value parameter as receiver is ok*)
  END Go3;

  PROCEDURE Go4*;
  BEGIN Out.String("Calling M1.ptrrec1ext1.Method3 with str = Method3, count = "); Out.Int(count, 4); Out.Ln;
    ptrrec1ext1.Method3("Method3", count); INC(count)
  END Go4;

BEGIN NEW(ptrrec1ext1)
END M1.

ORP.Compile M0.Mod/s ~          ORTool.DecObj M0.rsc ~
System.Free M0 ~
M0.Go1
M0.Go2
M0.Go3
M0.Go4
M0.Go5
M0.Go6
----------------------------
ORP.Compile M1.Mod/s ~          ORTool.DecObj M1.rsc ~
System.Free M1 M0 ~
M1.Go1
M1.Go2
M1.Go3
M1.Go4
