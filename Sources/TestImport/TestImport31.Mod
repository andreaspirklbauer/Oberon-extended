MODULE TestImport31;
IMPORT TestImport30, Out;
  VAR y : TestImport30.T;

 PROCEDURE WriteChar(ch: CHAR);
 BEGIN Out.Char(ch)
 END WriteChar;

BEGIN
  y := TestImport30.x;
  WriteChar(y.c)
END TestImport31.