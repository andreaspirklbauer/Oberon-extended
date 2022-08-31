MODULE TestImport71;
IMPORT Qs := TestImport70, Out;
TYPE
  ActorDesc* = RECORD (Qs.ItemDesc) END;
VAR a: POINTER TO ActorDesc;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

BEGIN NEW(a); a.key := 1; WriteInt(a.key)
END TestImport71.