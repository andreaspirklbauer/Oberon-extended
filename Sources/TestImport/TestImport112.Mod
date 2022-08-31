MODULE TestImport112;
  IMPORT TestImport110, TestImport111, Out;
  VAR
    x: TestImport110.X;
    y: TestImport111.Y;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

BEGIN
  y := TestImport111.TWELVE;
  x.i := y;
  WriteInt(x.i)
END TestImport112.