MODULE TestImport41;
IMPORT TestImport40, Out;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

  PROCEDURE P*(VAR t: TestImport40.T);
  BEGIN WriteInt(t.x)
  END P;
END TestImport41.