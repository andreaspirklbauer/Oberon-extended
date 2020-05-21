MODULE M2;
  IMPORT M1;
  CONST C2* = 12;  (*12 decimal = C hexadecimal*)
  TYPE Ptr2* = POINTER TO Rec2;
    Rec2* = RECORD x: INTEGER END ;

  PROCEDURE P2*; BEGIN END P2;

  PROCEDURE (VAR rec: Rec2) Method20* (str: ARRAY OF CHAR; p: LONGINT);
  BEGIN END Method20;

  PROCEDURE (ptr: Ptr2) Method21* (str: ARRAY OF CHAR; p: LONGINT);
  BEGIN END Method21;

END M2.
