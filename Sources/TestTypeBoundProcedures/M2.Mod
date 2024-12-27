MODULE M2;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT (*M0, *) M1, Out;
    
  TYPE
    Rec1Ext11* = RECORD (M1.Rec1Ext1) a3, b3*: INTEGER END ;
    Rec1Ext121* = RECORD (M1.Rec1Ext12) p3, q3*: INTEGER END ;

   VAR count: INTEGER; rec1ext11*: Rec1Ext11;

  PROCEDURE (VAR rec: Rec1Ext11) Method1* (str: ARRAY OF CHAR; p: LONGINT);  (*overrides M1.Rec1Ext1.Method1*)
  BEGIN Out.String("  Hello from M2.Rec1Ext11.Method1 (overrides M1.Rec1Ext1.Method1); str = "); Out.String(str);
    Out.String(", cnt = "); Out.Int(p, 4); Out.Ln;
    Out.String("  Calling super method M2.Rec1Ext11.Method1^ = M1.Rec1Ext1.Method1"); Out.Ln;
    rec.Method1^(str, p);  (*super call*)
  END Method1;

  PROCEDURE (VAR t: Rec1Ext11) Method3P (str: ARRAY OF CHAR; p: LONGINT);  (*private*)
  BEGIN END Method3P;

  PROCEDURE (VAR st: Rec1Ext121) Method3d* (str: ARRAY OF CHAR; p: LONGINT);  (*exported*)
  BEGIN END Method3d;

  PROCEDURE (VAR rec: Rec1Ext121) Method1* (str: ARRAY OF CHAR; p: LONGINT);  (*overwrites M1.RecExt12.Method1*)
  BEGIN Out.String("  Hello from M2.Rec1Ext121.Method1; str = "); Out.String(str); Out.String(", cnt ="); Out.Int(p, 4); Out.Ln;
    Out.String("  Calling method M2.Rec1Ext121.Method2b = M1.RecExt2b.Method2b"); Out.Ln;
    rec.x1 := 66; rec.Method2b(str, p);
    (* rec.Method2b^(str, p); *)  (*would lead to "redefined method must be called from overriding method" error*)
  END Method1;

  PROCEDURE Go1*;
  BEGIN Out.String("Calling rec1ext11.Method1 with str = Method1, count = "); Out.Int(count, 4); Out.Ln;
    rec1ext11.x1 := 55; rec1ext11.Method1("Method1", count); INC(count)
  END Go1;

BEGIN
END M2.

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
----------------------------
ORP.Compile M2.Mod/s ~          ORTool.DecObj M2.rsc ~
System.Free M2 M1 M0 ~
M2.Go1

