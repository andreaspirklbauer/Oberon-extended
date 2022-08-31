MODULE TestImport150;
  IMPORT Out;
  TYPE
    Rec150* = RECORD
                a*: INTEGER;
              END ;

 PROCEDURE WriteInt(i: INTEGER);
 BEGIN Out.Int(i, 4)
 END WriteInt;

 PROCEDURE WriteLn;
 BEGIN Out.Ln
 END WriteLn;

  PROCEDURE Two*;
  BEGIN
    WriteInt(2); WriteLn
  END Two;
END TestImport150.