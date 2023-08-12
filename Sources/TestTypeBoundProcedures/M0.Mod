MODULE M0;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT Out;

  TYPE
    PtrRec3* = POINTER TO Rec3;
    PtrRec2* = POINTER TO Rec2;
    PtrRec1* = POINTER TO Rec1;
    PtrArrRec3* = POINTER TO ArrRec3;

    Rec1* = RECORD x1*, y1: INTEGER END ;
    Rec2* = RECORD x: INTEGER; ptrrec2: PtrRec2 END ;
    Rec3* = RECORD
      arrrec1: ARRAY 15 OF Rec1;
      arrptrrec1: ARRAY 10 OF PtrRec1;
      ptrarrrec3: PtrArrRec3;
    END ;
    ArrRec3* = ARRAY 20 OF Rec3;

  VAR count: INTEGER;
    ptrrec1*: PtrRec1; rec1*: Rec1;
    arrrec3: ARRAY 20 OF Rec3;
    arrptrrec2: ARRAY 20 OF PtrRec2;
    arrrec1: ARRAY 10 OF Rec1;

  PROCEDURE (VAR rec: Rec1) Method1* (str: ARRAY OF CHAR; p: LONGINT); (*exported*)
  BEGIN Out.String("  Hello from M0.Rec1.Method1; str = "); Out.String(str);
    Out.String(", cnt ="); Out.Int(p, 4); Out.String(", rec.x1 ="); Out.Int(rec.x1, 4); INC(rec.x1); Out.Ln
  END Method1;

  PROCEDURE (VAR rec: Rec1) Method2* (str: ARRAY OF CHAR; p: LONGINT); (*exported*)
  BEGIN Out.String("  Hello from M0.Rec1.Method2; str = "); Out.String(str);
    Out.String(", cnt ="); Out.Int(p, 4); Out.String(", rec.x1 ="); Out.Int(rec.x1, 4); INC(rec.x1); Out.Ln
  END Method2;

  PROCEDURE (ptr: PtrRec1) Method3* (str: ARRAY OF CHAR; p: LONGINT); (*exported*)
  BEGIN Out.String("  Hello from M0.PtrRec1.Method3; str = "); Out.String(str);
    Out.String(", cnt ="); Out.Int(p, 4); Out.String(", ptr.x1 ="); Out.Int(ptr.x1, 4); INC(ptr.x1); Out.Ln
  END Method3;

  PROCEDURE (ptr: PtrRec1) Method5* (str: ARRAY OF CHAR; p: LONGINT); (*exported*)
  BEGIN Out.String("  Hello from M0.PtrRec1.Method5; str = "); Out.String(str);
    Out.String(", cnt ="); Out.Int(p, 4); Out.String(", ptr.x1 ="); Out.Int(ptr.x1, 4); INC(ptr.x1); Out.Ln
  END Method5;

  PROCEDURE (VAR rec: Rec1) Method1Q (str: ARRAY OF CHAR; p: LONGINT); (*private*)
  BEGIN END Method1Q;

  PROCEDURE (ptr: PtrRec2) Method6* (str: ARRAY OF CHAR; p: LONGINT); (*exported*)
  BEGIN Out.String("  Hello from M0.PtrRec2.Method6; str = "); Out.String(str);
    Out.String(", count ="); Out.Int(p, 4); Out.String(", ptr.x ="); Out.Int(ptr.x, 6); INC(ptr.x); Out.Ln
  END Method6;

  PROCEDURE Go1*;
  BEGIN Out.String("Calling rec1.Method1 with str = Method1, count = "); Out.Int(count, 4); Out.Ln;
    rec1.Method1("Method1", count); INC(count)
  END Go1;

  PROCEDURE Go2*;
  BEGIN Out.String("Calling arrrec1[3].Method1 with str = Method1, count = "); Out.Int(count, 4); Out.Ln;
    arrrec1[3].Method1("Method1", count); INC(count)
  END Go2;

  PROCEDURE Go3*;
  BEGIN Out.String("Calling arrrec3[5].arrrec1[8].Method1 with str = Method1, count = "); Out.Int(count, 4); Out.Ln;
    arrrec3[5].arrrec1[8].Method1("Method1", count); INC(count)
  END Go3;

  PROCEDURE Go4*;
  BEGIN Out.String("Calling arrrec3[12].arrptrrec1[2].Method3 with str = Method3, count = "); Out.Int(count, 4); Out.Ln;
    arrrec3[12].arrptrrec1[2]^.Method3("Method3", count); INC(count)
  END Go4;

  PROCEDURE Go5*;
  BEGIN Out.String("Calling arrrec3[14].ptrarrrec3[3].arrptrrec1[6].Method5 with str = Method5, count = "); Out.Int(count, 4); Out.Ln;
    arrrec3[14].ptrarrrec3[3].arrptrrec1[6].Method5("Method5", count); INC(count)
  END Go5;

  PROCEDURE Go6*;
  BEGIN Out.String("Calling arrptrrec2[12].ptrrec2.Method6 with str = Method6, count = "); Out.Int(count, 4); Out.Ln;
    arrptrrec2[12].ptrrec2.Method6("Method6", count); INC(count)
  END Go6;

BEGIN NEW(ptrrec1);
  NEW(arrrec3[12].arrptrrec1[2]);
  NEW(arrrec3[14].ptrarrrec3);
  NEW(arrrec3[14].ptrarrrec3[3].arrptrrec1[6]);
  NEW(arrptrrec2[12]);
  NEW(arrptrrec2[12].ptrrec2)
END M0.

ORP.Compile M0.Mod/s ~          ORTool.DecObj M0.rsc ~
System.Free M0 ~
M0.Go1
M0.Go2
M0.Go3
M0.Go4
M0.Go5
M0.Go6
