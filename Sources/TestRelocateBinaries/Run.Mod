MODULE Run;  (*Run standalone programs M.rsc or prelinked binaries M.bin / AP 1.5.21 Extended Oberon*)
  IMPORT SYSTEM, Files, Texts, Oberon, ORL;
  CONST maxCode = 8000;

  VAR code: ARRAY maxCode OF LONGINT;
    W: Texts.Writer;

  PROCEDURE GetArg(VAR S: Texts.Scanner);
    VAR T: Texts.Text; beg, end, time: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END
  END GetArg;

  PROCEDURE EndLine;
  BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EndLine;

  PROCEDURE ExtractCode(F: Files.File; VAR code: ARRAY OF LONGINT; VAR codelen, entry, res: INTEGER);
    VAR n, data: INTEGER; ch: CHAR; b: BYTE;               (*codelen in words, entry in bytes*)
      R: Files.Rider;
      name: ARRAY 32 OF CHAR;
  BEGIN Files.Set(R, F, 0); Files.ReadString(R, name); Files.ReadInt(R, data); (*key*)
    Files.ReadByte(R, b); (*version*) Files.ReadInt(R, data); (*size*)
    Files.ReadString(R, name); (*imports*)
    WHILE name[0] # 0X DO Files.ReadInt(R, data); (*key*) Files.ReadString(R, name) END ;
    Files.ReadInt(R, n); (*variable space*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n); (*strings*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n); (*type descriptors*)
    Files.ReadInt(R, codelen);
    IF codelen > LEN(code) THEN res := ORL.nospace
    ELSE n := 0;
      WHILE n < codelen DO Files.ReadInt(R, data); code[n] := data; INC(n) END ; (*code*)
      Files.ReadString(R, name);
      WHILE name[0] # 0X DO Files.ReadInt(R, data); Files.ReadString(R, name) END ; (*commands*)
      Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n*4); (*entries*)
      Files.ReadInt(R, data);
      WHILE data >= 0 DO Files.ReadInt(R, data) END ; (*pointer references*)
      Files.ReadInt(R, data);
      WHILE data >= 0 DO Files.ReadInt(R, data) END ; (*procedure variable references*)
      Files.ReadInt(R, data); (*fixorgP*) Files.ReadInt(R, data); (*fixorgD*)
      Files.ReadInt(R, data); (*fixorgT*) Files.ReadInt(R, data); (*fixorgM*)
      Files.ReadInt(R, entry); (*body*) Files.ReadInt(R, data); (*final*)
      Files.Read(R, ch);
      IF ch # "O" THEN res := ORL.badfile ELSE res := ORL.noerr END
    END
  END ExtractCode;

  PROCEDURE RunRsc*;  (*extract, load and execute code section of standalone program  M.rsc*)
    VAR codelen, entry, res: INTEGER;
      body: ORL.Command;
      F: Files.File;
      S: Texts.Scanner;
  BEGIN GetArg(S); Texts.WriteString(W, "Run.RunRsc ");
    IF S.class = Texts.Name THEN (*name of object file*)
      Texts.WriteString(W, S.s); Texts.Append(Oberon.Log, W.buf);
      F := Files.Old(S.s);
      IF F # NIL THEN ExtractCode(F, code, codelen, entry, res); (*extract code section from M.rsc*)
        IF res = ORL.noerr THEN Texts.WriteString(W, " done");
          body := SYSTEM.VAL(ORL.Command, SYSTEM.ADR(code) + entry); body
        ELSIF res = ORL.nofile THEN Texts.WriteString(W, " failed")
        ELSIF res = ORL.badfile THEN Texts.WriteString(W, " input file format error")
        ELSIF res = ORL.nospace THEN Texts.WriteString(W, " program too long")
        END
      END ;
      EndLine
    END
  END RunRsc;

  PROCEDURE RunBin*;  (*load and execute prelinked binary  M.bin*)
  BEGIN ORL.Execute
  END RunBin;

BEGIN Texts.OpenWriter(W)
END Run.

ORP.Compile Run.Mod/s ~

ORP.Compile M.Mod/s ~   # generate M.rsc
ORL.Link M ~            # generate M.bin

Run.RunRsc M.rsc ~      # execute code section of M.rsc
Run.RunBin M.bin ~      # execute prelinked binary M.bin
