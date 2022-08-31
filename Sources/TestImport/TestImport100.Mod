MODULE TestImport100;
  IMPORT S := SYSTEM, Out;
  VAR
    s: SET;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

BEGIN
  s := {1};
  WriteInt(S.VAL(INTEGER, s));
END TestImport100.