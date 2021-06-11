MODULE M4;  (*test type-bound procedures, ORP.selector/deref and ORP.CheckReceiver / AP 1.5.21 Extended Oberon*)
  IMPORT Out;

  TYPE
    Ptr1* = POINTER TO Rec1;
    Ptr2* = POINTER TO Rec2;
    Ptr3* = POINTER TO Rec3;
    Ptr4* = POINTER TO Rec3;
    Ptr5* = POINTER TO Rec5;

    Rec1* = RECORD x1: INTEGER END ;
    Rec2* = RECORD a: INTEGER; r1: Rec1; x2: INTEGER END ;
    Rec3* = RECORD b, c: INTEGER; r2: Rec2; x3:INTEGER END ;
    Rec4* = RECORD d, e, f: INTEGER; r3: Ptr3; x4:INTEGER END ;
    Rec5* = RECORD g, h, i, j: INTEGER; r4: Rec4; x5:INTEGER END ;

  VAR rec1: Rec1; rec2: Rec2; rec3: Rec3; rec4: Rec4; rec5: Rec5;

  PROCEDURE (VAR r: Rec1) Method1(i: INTEGER);
  BEGIN Out.String("  Hello from Method1"); Out.Int(r.x1, 8); Out.Int(i, 8); Out.Ln
  END Method1;

  PROCEDURE (VAR r: Rec2) Method2(i: INTEGER);
  BEGIN Out.String("  Hello from Method2"); Out.Int(r.x2, 8); Out.Int(i, 8); Out.Ln
  END Method2;

  PROCEDURE (VAR r: Rec3) Method3(i: INTEGER);
  BEGIN Out.String("  Hello from Method3"); Out.Int(r.x3, 8); Out.Int(i, 8); Out.Ln
  END Method3;

  PROCEDURE (VAR r: Rec4) Method4(i: INTEGER);
  BEGIN Out.String("  Hello from Method4"); Out.Int(r.x4, 8); Out.Int(i, 8); Out.Ln
  END Method4;

  PROCEDURE (VAR r: Rec5) Method5(i: INTEGER);
  BEGIN Out.String("  Hello from Method5"); Out.Int(r.x5, 8); Out.Int(i, 8); Out.Ln
  END Method5;

  PROCEDURE Go1*;
  BEGIN Out.String("Calling Method1"); Out.Ln; rec1.x1 := 1; rec1.Method1(11)
  END Go1;

  PROCEDURE Go2*;
  BEGIN Out.String("Calling Method1, Method2"); Out.Ln; rec2.r1.x1 := 1; rec2.x2 := 2;
    rec2.r1.Method1(11); rec2.Method2(22)
  END Go2;

  PROCEDURE Go3*;
  BEGIN Out.String("Calling Method1, Method2, Method3"); Out.Ln; rec3.r2.r1.x1 := 1; rec3.r2.x2 := 2; rec3.x3 := 3;
    rec3.r2.r1.Method1(11); rec3.r2.Method2(22); rec3.Method3(33)
  END Go3;

  PROCEDURE Go4*;
  BEGIN Out.String("Calling Method1, Method2, Method3, Method4"); Out.Ln; NEW(rec4.r3);
    rec4.r3.r2.r1.x1 := 1; rec4.r3.r2.x2 := 2; rec4.r3.x3 := 3; rec4.x4 := 4;
    rec4.r3.r2.r1.Method1(11);  (*test record selector AFTER pointer selector*)
    rec4.r3.r2.Method2(22);
    rec4.r3.Method3(33); rec4.Method4(44)
  END Go4;

  PROCEDURE Go5*;
    VAR rec1: Rec1; rec2: Rec2;
  BEGIN Out.String("Calling Method1, Method2, Method3, Method4, Method5"); Out.Ln; NEW(rec5.r4.r3);
    rec5.r4.r3.r2.r1.x1 := 1; rec5.r4.r3.r2.x2 := 2; rec5.r4.r3.x3 := 3; rec5.r4.x4 := 4; rec5.x5 := 5;
    rec1 := rec5.r4.r3.r2.r1; rec1.Method1(11);
    rec2 := rec5.r4.r3.r2; rec2.Method2(22);
    rec5.r4.r3.Method3(33); rec5.r4.Method4(44); rec5.Method5(55)
  END Go5;

BEGIN
END M4.

ORP.Compile M4.Mod/s ~          ORTool.DecObj M4.rsc ~
System.Free M4 ~

M4.Go1
M4.Go2
M4.Go3
M4.Go4
M4.Go5
