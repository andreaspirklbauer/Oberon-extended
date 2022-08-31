MODULE TestImport62;
IMPORT TestImport60, TestImport61, Out;
  VAR p1* : TestImport61.P1;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

 PROCEDURE WriteReal(x: REAL);
 BEGIN Out.Real(x, 4)
 END WriteReal;

 PROCEDURE WriteChar(ch: CHAR);
 BEGIN Out.Char(ch)
 END WriteChar;

 PROCEDURE WriteLn;
 BEGIN Out.Ln
 END WriteLn;

BEGIN
  NEW(p1);
  p1.y := "A";
  WriteChar(p1.y);
  IF p1 IS TestImport61.P1 THEN WriteChar("Y") END;
  WriteReal(TestImport60.PI);
  WriteInt(TestImport60.N)
END TestImport62.