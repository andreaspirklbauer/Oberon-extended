MODULE M0;
  IMPORT Out;
  TYPE P = POINTER TO A;
    A = ARRAY OF INTEGER;
    B = ARRAY 12 OF INTEGER;
    C = ARRAY 20 OF INTEGER;
    D = ARRAY 0 OF INTEGER;
  VAR p1, p2: P;
    b1, b2: B;
    c1, c2: C;
    d1, d2: D;

  PROCEDURE Go1*;  (*no compile time error, no run time error*)
  BEGIN
    p1^ := b1;  Out.Int(p1[5], 4); (*5*)
    p1^ := p2^; Out.Int(p1[7], 4)  (*7*)
  END Go1;

  PROCEDURE Go2*;  (*no compile time error, but run time error (as expected)*)
  BEGIN
    b1 := p1^  (*correctly issues a TRAP 3 runtime error, array overflow*)
  END Go2;

  PROCEDURE Go3*;  (*no compile time error, run time error (as expected)*)
  BEGIN
    p2^ := p1^  (*corrently issues a TRAP 3 runtime error, array overflow*)
  END Go3;

  (*
  PROCEDURE Go4*;  (*compile time errors*)
  BEGIN
    d1  := b1; (*inadmissible assignment, length of d1 is 0*)
    p1^ := d2; (*inadmissible assignment, length of d2 is 0*)
    b1  := c1  (*different length/size, not implemented*) 
  END Go4;
  *)

BEGIN b1[5] := 5;
  NEW(p1, 16); p1[6] := 6;
  NEW(p2, 8); p2[7] := 7
END M0.

ORP.Compile M0.Mod/s ~
System.Free M0 ~
M0.Go1 ~
M0.Go2 ~   # runtime error (TRAP 3)
M0.Go3 ~   # runtime error (TRAP 3)

ORTool.DecObj M0.rsc ~
