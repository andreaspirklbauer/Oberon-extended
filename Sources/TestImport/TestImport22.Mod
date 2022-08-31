MODULE TestImport22;
IMPORT TestImport20, TestImport21, Out;
  VAR
    x : TestImport20.R;
    y : TestImport21.X;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

BEGIN
  x.u := 8;
  y := x;
  WriteInt(y.u);
END TestImport22.