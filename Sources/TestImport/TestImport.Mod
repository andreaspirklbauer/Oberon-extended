--------------------------- Preparation for subsequent test suites ----------

ORP.Compile @/s ~

MODULE M0;                                  (*no error message*)
  TYPE T0* = RECORD i: INTEGER END ;
END M0.

MODULE M1;                                  (*no error message*)
  TYPE T0* = RECORD i: INTEGER END ;
END M1.

MODULE M2;                                  (*no error message*)
  IMPORT M1;
  TYPE T1* = RECORD (M1.T0) j: INTEGER END ;
  VAR a: M1.T0; b: T1;
BEGIN a := b
END M2.

MODULE M3;                                  (*no error message*)
  IMPORT M0, M1, M2;
  TYPE T2* = RECORD (M0.T0) k: INTEGER END ;
END M3.

MODULE M4;                                  (*no error message*)
  TYPE T3* = POINTER TO R3;
    R3* = RECORD i: INTEGER END ;
END M4.

MODULE M5;                                  (*no error message*)
  IMPORT M4;
  TYPE T4* = POINTER TO R4;
    R4* = RECORD (M4.R3) j: INTEGER END ;
  VAR a: M4.T3; b: T4;
BEGIN a := b
END M5.

MODULE M6;                                  (*no error message*)
 TYPE A* = RECORD i: INTEGER END ;
   B* = A;
END M6.

MODULE M7;                                  (*no error message*)
  IMPORT M6;
  VAR a*: M6.A;                             (*re-exports M6.A, but not M6.B*)
END M7.

MODULE M8;                                  (*no error message*)
  IMPORT M7, M6;                            (*M7 re-imports M6.A*)
  VAR a*: M6.A; b*: M6.B;
BEGIN a := b
END M8.

--------------------------- Test suite A ------------------------------------

ORP.Compile @/s ~

MODULE A0;  (*no error message*)
  IMPORT M1, X := M2;
END A0.

MODULE A1;  (*no error message, M0 imported under alias M1, M0 then reused as alias for M2*)
  IMPORT M1 := M0, M0 := M2;
END A1.
  
MODULE A2;  (*no error message, M0 imported under alias M1, M0 then reused as alias for M1 itself*)
  IMPORT M1 := M0, M0 := M1;
END A2.

MODULE A3;  (*no error message, M0 imported under alias M1, M1 then imported under another alias X*)
  IMPORT M1 := M0, X := M1;
END A3.
  
MODULE A4;  (*no error message, M0 imported under alias M1, M1 then imported under alias M0 => same as A2*)
  IMPORT M1 := M0, M0 := M1;
END A4.

MODULE A5;  (*no error message, M1 first explicitly imported, then re-imported by M2*)
  IMPORT M1, M2;
END A5.
  
MODULE A6;  (*no error message, M1 first explicitly imported, then re-imported by M2*)
  IMPORT M0 := M1, M2;
END A6.
  
MODULE A7;  (*no error message, M1 first re-imported by M2, then M0 explicitly imported under an alias M1*)
  IMPORT M2, M1 := M0;
END A7.

--------------------------- Test suite B --------------------------------------

ORP.Compile @/s ~

MODULE B1;                                  (*no error message*)
  IMPORT M2;
  TYPE T2* = RECORD (M2.T1) ch: CHAR END ;  (*re-imports the type M1.T0, but module M1 remains invisible*)
  VAR a: M2.T1; b: T2;
    M1: INTEGER;
BEGIN a := b
END B1.

MODULE B2;                                  (*no error message*)
  IMPORT M2;
  TYPE T2* = RECORD (M2.T1) ch: CHAR END ;  (*re-imports the type M1.T0, but module M1 remains invisible*)
    M1 = RECORD x: INTEGER END ;
    T3 = POINTER TO M1;
  VAR a: M2.T1; b: T2;
BEGIN a := b
END B2.

MODULE B3;                                  (*no error message*)
  IMPORT M0 := M1, M2;
  VAR a: M0.T0; b: M2.T1;
BEGIN a := b
END B3.

MODULE B4;                                  (*no error message*)
  IMPORT M0 := M1, M1 := M2;
  VAR a: M0.T0; b: M1.T1;
BEGIN a := b
END B4.

MODULE B5;                                  (*no error message*)
  IMPORT Y1 := M1, M2;
  VAR a: Y1.T0; b: M2.T1;
BEGIN a := b
END B5.

MODULE B6;                                  (*no error message*)
  IMPORT D := Display, Oberon;              (*module Display is explicitly imported before it is re-imported by module Oberon*)
  VAR m1: D.FrameMsg; m2: Oberon.InputMsg;
  PROCEDURE Handle(V: D.Frame; VAR M: D.FrameMsg);
  BEGIN
    CASE M OF
      Oberon.InputMsg: m2 := M |
      D.FrameMsg: m1 := M
    END
  END Handle;
END B6.

MODULE B7;                                  (*no error message*)
  IMPORT M2, M1 := M0;                      (*M2 re-imports M1, but there is no conflict with the alias name M1*)
  VAR a: M1.T0; b: M2.T1;
BEGIN (*a := b*)                            (*this, however, WOULD be an illegal assignment, because M1.T0 is in fact M0.T0 here*)
END B7.

MODULE B8;                                  (*no error mesage*)
  IMPORT M1 := M0, M2;                      (*M2 re-imports M1, but there is no conflict with the alias name M1*)
  VAR a: M1.T0; b: M2.T1;
BEGIN (*a := b*)                            (*this, however, WOULD be an illegal assignment, because M1.T0 is in fact M0.T0 here*)
END B8.

--------------------------- Test suite C ------------------------------------

ORP.Compile @/s ~

MODULE C1;                                  (*no error message*)
  IMPORT M1, M2;
  VAR a: M1.T0; b: M2.T1;
BEGIN a := b
END C1.

MODULE C2;                                  (*no error message*)
  IMPORT M2, M1;                            (*M1 is first-reimported by M2, then M1 is explicitly imported*)
  VAR a: M1.T0; b: M2.T1;
BEGIN a := b
END C2.

MODULE C3;                                  (*no error message*)
  IMPORT M4, M5;
  VAR a: M4.T3; b: M5.T4;
BEGIN a := b
END C3.

MODULE C4;                                  (*no error message*)
  IMPORT M5, M4;                            (*M4 is first-reimported by M5, then M4 is explicitly imported*)
  VAR a: M4.T3; b: M5.T4;
BEGIN a := b
END C4.

---------------------------------------------------------------

MODULE C5;
  TYPE T5* = RECORD END ;
END C5.

MODULE C6;
  IMPORT C5;                                (*this imports C5.T5*)
  TYPE T6* = RECORD END ;
    T5Alias1* = C5.T5;                      (*this re-exports C5.T5 to clients of C6*)
  VAR r2*: C5.T5;                           (*this also re-exports C5.T5 to clients of C6*)
END C6.

MODULE C7;
  IMPORT C6;                                (*this re-imports C5.T5, even though C7 does not explicitly import C5*)
  TYPE T5Alias2* = C6.T5Alias1;             (*this re-exports the original type C5.T5*)
  VAR r3*: C6.T5Alias1;                     (*this also re-exports the original type C5.T5*)
    r4*: T5Alias2;                          (*this also re-exports the original type C5.T5*)
END C7.

MODULE C8;
  IMPORT C7;                                (*this re-imports C5.T5, even though C8 does not explicitly import C5*)
  VAR r4*: C7.T5Alias2;                     (*this re-exports the original type C5.T5*)
END C8.

ORP.Compile @/s ~

ORTool.DecSym C5.smb ~                      # shows C5.T5
ORTool.DecSym C6.smb ~                      # shows C5.T5
ORTool.DecSym C7.smb ~                      # shows C5.T5
ORTool.DecSym C8.smb ~                      # shows C5.T5

--------------------------- Test suite D (should produce error messages) ------------------------------------

ORP.Compile @/s ~

MODULE D1;
  IMPORT M0, M0;                 (*mult def*)
END D1.

MODULE D2;
  IMPORT M0, M0 := M1;           (*mult def*)
END D2.

MODULE D3;
  IMPORT M0 := M1, M0;           (*mult def*)
END D3.

MODULE D4;
  IMPORT M0 := M1, M0 := M1;     (*mult def*)
END D4.

MODULE D5;
  IMPORT X := M0, X := M1;       (*mult def*)
END D5.

MODULE D6;
  IMPORT M0, X := M0;            (*mult def*)
END D6.

MODULE D7;
  IMPORT X := M0, M0;            (*mult def*)
END D7.

MODULE D8;
  IMPORT X := M0, Y := M0;       (*mult def*)
END D8.

MODULE D9;
  IMPORT M0, X := M0, Y := M0;   (*2x mult def*)
END D9.

--------------------------- Test suite E (should produce error messages) ------------------------------------

ORP.Compile @/s ~

MODULE E1;                                   (*mult def*)
  IMPORT M0 := M1, M1;                       (*because a module M1 is imported under *two* different names M0 and M1*)
  VAR a: M0.T0; b: M1.T0;
BEGIN a := b
END E1.

MODULE E2;                                   (*mult def*)
  IMPORT M0 := M1, M3, M0;                   (*because the name M0 is used twice, once as an alias, once as a module name*)
  TYPE T3* = RECORD (M3.T2) ch: CHAR END ;
  VAR a: M3.T2; b: T3; c: M0.T0;
BEGIN a := b; c := b
END E2.

MODULE E3;                                    (*mult def*)
  IMPORT M0 := M1, M0 := M3;                  (*because the name M0 is used twice as an alias*)
END E3.

MODULE E4;                                    (*mult def*)
  IMPORT M0, M0 := M1, M3;                    (*because the name M0 is used twice, once as an alias, once as a module name*)
  TYPE T3* = RECORD (M3.T2) ch: CHAR END ;
  VAR a: M3.T2; b: T3; c: M0.T0;
BEGIN a := b; c := b
END E4.

MODULE E5;                      (*mult def*)
  IMPORT M2, M1 := M0, M1;      (*M2 re-imports M1, no conflict with alias name M1, but conflict with explicit import M1*)
  VAR a: M1.T0; b: M2.T1;       (*Note:the direct import of M1 converts a previous re-import of M1 into an explicit one*)
END E5.                         (*This must be detected: after the conversion, M1 is an explicit import, THEN conflict with M1*)

--------------------------- Test suite F (should produce error messages) ------------------------------------

ORP.Compile @/s ~

MODULE F1;
  TYPE T = RECORD i, j*: INTEGER END ;      (*invalid field export of field j*)
    V* = T;                                 (*type T not exported*)
    R* = RECORD a*, b*: T END ;             (*type T not exported*)
  VAR c, d: T;
    e*, f: T;                               (*type T not exported*)
    g*, h*: RECORD i, j*, k*: INTEGER END ;  
    m, n*: RECORD i, j*, k*: INTEGER END ;  (*invalid field export*)
END F1.

