MODULE ORX;  (*Oberon boot converter for RISC / AP 1.3.24 Extended Oberon*)
  IMPORT Files, Texts, Oberon;
  CONST CR = 0DX; noerr = 0; badfile = 4;  (*copied from Modules for use as cross development tool*)

  TYPE Writer = PROCEDURE(VAR R: Files.Rider; x: LONGINT);

  VAR res*: INTEGER;
    W: Texts.Writer;

  PROCEDURE EndLine;
  BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EndLine;

  PROCEDURE WriteHex(VAR R: Files.Rider; x: LONGINT);  (*write a 4 byte LONGINT in 8 digit hex format*)
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN i := 0;
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END ;
      x := x DIV 10H; INC(i)
    UNTIL i = 8;
    REPEAT DEC(i); Files.Write(R, a[i]) UNTIL i = 0 ;
    Files.Write(R, CR)
  END WriteHex;

  PROCEDURE ExtractCode(VAR R, R1: Files.Rider; write: Writer; VAR codelen, entry, res: INTEGER);
    VAR n, data: INTEGER;                                      (*codelen in words, entry in bytes*)
      ch: CHAR; b: BYTE;
      F: Files.File;
      name: ARRAY 32 OF CHAR;
  BEGIN F := Files.Base(R); Files.ReadString(R, name); Files.ReadInt(R, data); (*key*)
    Files.ReadByte(R, b); (*version*) Files.ReadInt(R, data); (*size*)
    Files.ReadString(R, name); (*imports*)
    WHILE ~R.eof & (name[0] # 0X) DO Files.ReadInt(R, data); (*key*) Files.ReadString(R, name) END ;
    Files.ReadInt(R, n); (*variable space*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n); (*strings*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n); (*type descriptors*)
    Files.ReadInt(R, codelen); n := 0;
    WHILE ~R.eof & (n < codelen) DO Files.ReadInt(R, data); write(R1, data); INC(n) END ; (*write code*)
    Files.ReadString(R, name);
    WHILE ~R.eof & (name[0] # 0X) DO Files.ReadInt(R, data); Files.ReadString(R, name) END ; (*commands*)
    Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n*4); (*entries*)
    Files.ReadInt(R, data);
    WHILE ~R.eof & (data >= 0) DO Files.ReadInt(R, data) END ; (*pointer references*)
    Files.ReadInt(R, data);
    WHILE ~R.eof & (data >= 0) DO Files.ReadInt(R, data) END ; (*procedure variable references*)
    Files.ReadInt(R, data); (*fixorgP*) Files.ReadInt(R, data); (*fixorgD*)
    Files.ReadInt(R, data); (*fixorgT*) Files.ReadInt(R, data); (*fixorgM*)
    Files.ReadInt(R, entry); (*body*) Files.ReadInt(R, data); (*final*)
    Files.Read(R, ch);
    IF ch # "O" THEN res := badfile ELSE res := noerr END
  END ExtractCode;

  PROCEDURE WriteFile*;  (*write code section of M.rsc in hex format to output file*)
    VAR f, g: Files.File; Rf, Rg: Files.Rider;
      n, codelen, filelen, entry: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteFile "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          IF Files.Length(f) > 0 THEN
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            ExtractCode(Rf, Rg, WriteHex, codelen, entry, res);
            IF res = noerr THEN
              filelen := ((codelen DIV 512) + 1) * 512; n := codelen;
              WHILE n < filelen DO WriteHex(Rg, 0); INC(n) END ; (*zero-fill*)
              Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
              Texts.WriteString(W, "  done"); Files.Register(g)
            ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
            END
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: ORX.WriteFile M.rsc M.mem") END ;
    EndLine; Oberon.Return(res)
  END WriteFile;

  PROCEDURE WriteCode*;  (*write code section of M.rsc in binary format to output file*)
    VAR f, g: Files.File; Rf, Rg: Files.Rider;
      codelen, entry: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN Texts.WriteString(W, "  WriteCode "); res := -2;
        Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, S.s);
        f := Files.Old(name);
        IF f # NIL THEN
          IF Files.Length(f) > 0 THEN
            g := Files.New(S.s); Files.Set(Rf, f, 0); Files.Set(Rg, g, 0);
            ExtractCode(Rf, Rg, Files.WriteInt, codelen, entry, res);
            IF res = noerr THEN
              Texts.WriteInt(W, codelen*4, 6); Texts.WriteInt(W, entry, 6);
              Texts.WriteString(W, "  done"); Files.Register(g)
            ELSIF res = badfile THEN Texts.WriteString(W, "  input file format error")
            END
          ELSE Texts.WriteString(W, "  input file empty")
          END
        ELSE Texts.WriteString(W, "  input file not found")
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: ORX.WriteCode M.rsc M.code") END ;
    EndLine; Oberon.Return(res)
  END WriteCode;

  PROCEDURE MakeStream(VAR Rf, Rg: Files.Rider; blksize, destadr: INTEGER);
    VAR i, a: INTEGER; b: BYTE;
  BEGIN Files.ReadByte(Rf, b); i := 0; a := destadr;
    WHILE ~Rf.eof DO
      IF i MOD blksize = 0 THEN Files.WriteInt(Rg, blksize); Files.WriteInt(Rg, a); INC(a, blksize); i := 0 END ;
      Files.WriteByte(Rg, b); INC(i); Files.ReadByte(Rf, b)
    END ;
    WHILE i < blksize DO Files.WriteByte(Rg, 0); INC(i) END ;
    Files.WriteInt(Rg, 0)  (*size of last block*)
  END MakeStream;

  PROCEDURE WriteStream*;  (*convert boot file to stream format with specified block size and dest adr*)
    VAR f, g: Files.File; Rf, Rg: Files.Rider;
      filelen, blksize: INTEGER;
      name, name1: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN name1 := S.s; Texts.Scan(S);
        IF S.class = Texts.Int THEN blksize := S.i; Texts.Scan(S);
          IF S.class = Texts.Int THEN Texts.WriteString(W, "  WriteStream "); res := -2;
            Texts.WriteString(W, name); Texts.Write(W, " "); Texts.WriteString(W, name1);
            Texts.WriteInt(W, blksize, 5); Texts.WriteInt(W, S.i, 5);
            IF blksize >= 0 THEN
              IF S.i >= 0 THEN f := Files.Old(name);
                IF f # NIL THEN filelen := Files.Length(f);
                  IF filelen > 0 THEN g := Files.New(name1); res := noerr;
                    IF blksize = 0 THEN blksize := filelen END ;
                    Files.Set(Rf, f, 0); Files.Set(Rg, g, 0); MakeStream(Rf, Rg, blksize, S.i);
                    Files.Register(g); Texts.WriteString(W, "  done")
                  ELSE Texts.WriteString(W, "  input file empty")
                  END
                ELSE Texts.WriteString(W, "  input file not found")
                END
              ELSE Texts.WriteString(W, "  destadr must be >= 0")
              END
            ELSE Texts.WriteString(W, "  blocksize must be >= 0")
            END
          END
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: ORX.WriteStream M.bin M.stream blocksize destadr") END ;
    EndLine; Oberon.Return(res)
  END WriteStream;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OR boot converter  AP 1.3.24"); EndLine
END ORX.
