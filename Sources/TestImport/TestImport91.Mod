MODULE TestImport91;
  IMPORT imp := TestImport90, Out;
  VAR i: INTEGER;
      str: ARRAY 10 OF CHAR;

 PROCEDURE WriteChar(ch: CHAR);
 BEGIN Out.Char(ch)
 END WriteChar;

 PROCEDURE WriteLn;
 BEGIN Out.Ln
 END WriteLn;

BEGIN
  str := imp.h;
  i := 0;
  WHILE str[i] # 0X DO
    WriteChar(str[i]);
    INC(i)
  END ;
  WriteChar(imp.x);
  WriteLn
END TestImport91.