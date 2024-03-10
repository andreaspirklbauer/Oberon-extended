MODULE ORTool;  (*NW 18.2.2013 / 12.4.2017 / AP 10.3.24 Extended Oberon*)
  IMPORT SYSTEM, Files, Modules, Texts, Oberon, ORB;
  CONST TAB = 09X;  (*copied from Input for use as cross development tool*)
    AllocAdr = 16; FPrintAdr = 28; ModAdr = 32; FPrint = 12345678H; (*copied from ORL*)
  VAR W: Texts.Writer;
    mnemo0, mnemo1: ARRAY 16, 4 OF CHAR;  (*mnemonics*)
    typlev: INTEGER;

  PROCEDURE Read(VAR R: Files.Rider; VAR x: INTEGER);
    VAR b: BYTE;
  BEGIN Files.ReadByte(R, b);
    IF b < 80H THEN x := b ELSE x := b - 100H END
  END Read;

  PROCEDURE ReadType(VAR R: Files.Rider);
    VAR key, len, size, off: INTEGER;
      ref, orgref, class, form, readonly: INTEGER;
      name, modname: ARRAY 32 OF CHAR;
  BEGIN INC(typlev); Read(R, ref); Texts.Write(W, " "); Texts.WriteLn(W);
    FOR off := 0 TO typlev DO Texts.Write(W, 09X) END ;
    Texts.Write(W, "[");
    IF ref < 0 THEN Texts.Write(W, "^"); Texts.WriteInt(W, -ref, 1)
    ELSE Texts.WriteInt(W, ref, 1);
      IF ref > 0 THEN  (*named type*)
        Files.ReadString(R, modname);
        IF modname[0] # 0X THEN
          Files.ReadInt(R, key); Files.ReadString(R, name); Read(R, orgref);
          Texts.Write(W, " "); Texts.WriteString(W, modname); Texts.Write(W, "."); Texts.WriteString(W, name);
          Texts.WriteHex(W, key)
        END
      END ;
      Read(R, form); Texts.WriteString(W, "  form = "); Texts.WriteInt(W, form, 1);
      IF form = ORB.Pointer THEN ReadType(R)
      ELSIF form = ORB.Array THEN
        ReadType(R); Files.ReadNum(R, len); Files.ReadNum(R, size);
        Texts.WriteString(W, "  len = "); Texts.WriteInt(W, len, 1);
        Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1)
      ELSIF form = ORB.Record THEN
        ReadType(R);  (*base type*)
        Files.ReadNum(R, off); Texts.WriteString(W, "  exno = "); Texts.WriteInt(W, off, 1);
        Files.ReadNum(R, off); Texts.WriteString(W, "  extlev = "); Texts.WriteInt(W, off, 1);
        Files.ReadNum(R, size); Texts.WriteString(W, "  size = "); Texts.WriteInt(W, size, 1);
        Texts.Write(W, " "); Texts.Write(W, "{"); Read(R, class);
        WHILE class # 0 DO  (*fields*)
          Files.ReadString(R, name);
          IF name[0] # 0X THEN Texts.Write(W, " "); Texts.WriteString(W, name); ReadType(R);
            IF class = ORB.Const THEN Files.ReadNum(R, off); Texts.WriteInt(W, off, 4) END  (*exno*)
          ELSE (*hidden*) Texts.WriteString(W, " --")
          END ;
          Files.ReadNum(R, off); Texts.WriteInt(W, off, 4);  (*mthno/offset*)
          Read(R, class)
        END ;
        Texts.Write(W, "}")
      ELSIF form IN {ORB.Proc, ORB.TProc} THEN
        ReadType(R); Texts.Write(W, "("); Read(R, class);
        WHILE class # 0 DO  (*parameters*)
          Texts.WriteString(W, " class = "); Texts.WriteInt(W, class, 1); Read(R, readonly);
          IF readonly = 1 THEN Texts.Write(W, "#") END ;
          ReadType(R); Read(R, class)
        END ;
        Texts.Write(W, ")")
      END
    END ;
    Texts.Write(W, "]"); DEC(typlev)
  END ReadType;

  PROCEDURE DecSym*;  (*decode symbol file*)
    VAR class, k: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "OR-decode "); Texts.WriteString(W, S.s);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      F := Files.Old(S.s);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadInt(R, k); Files.ReadInt(R, k);
        Files.ReadString(R, name); Texts.WriteString(W, name); Texts.WriteHex(W, k);
        Read(R, class); Texts.WriteInt(W, class, 3);  (*sym file version*)
        IF class = ORB.versionkey THEN
          Texts.WriteLn(W); Read(R, class); typlev := 0;
          WHILE class # 0 DO
            Texts.WriteInt(W, class, 4); Files.ReadString(R, name); Texts.Write(W, " "); Texts.WriteString(W, name);
            ReadType(R);
            IF (class = ORB.Const) OR (class = ORB.Var) THEN
              Files.ReadNum(R, k); Texts.WriteInt(W, k, 5);  (*Reals, Strings!*)
            END ;
            Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
            Read(R, class)
          END
        ELSE Texts.WriteString(W, " bad symfile version")
        END
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END DecSym;

(* ---------------------------------------------------*)

  PROCEDURE WriteReg(r: LONGINT);
  BEGIN Texts.Write(W, " ");
    IF r < 13 THEN Texts.WriteString(W, " R"); Texts.WriteInt(W, r MOD 10H, 1)
    ELSIF r = 13 THEN Texts.WriteString(W, "TR")
    ELSIF r = 14 THEN Texts.WriteString(W, "SP")
    ELSE Texts.WriteString(W, "LNK")
    END
  END WriteReg;

  PROCEDURE opcode(w: LONGINT; fixP, fixD: BOOLEAN);
    VAR k, u, v, a, b, op: LONGINT;
  BEGIN
    k := w DIV 40000000H MOD 4;
    u := w DIV 20000000H MOD 2;
    v := w DIV 10000000H MOD 2;
    a := w DIV 1000000H MOD 10H;
    b := w DIV 100000H MOD 10H;
    op := w DIV 10000H MOD 10H;
    IF k = 0 THEN  (*F0 register instruction*)
      IF (op = 12) & (u = 0) & (v = 1) THEN Texts.WriteString(W, "FLR"); WriteReg(a); WriteReg(b)
      ELSIF (op = 12) & (u = 1) & (v = 0) THEN Texts.WriteString(W, "FLT"); WriteReg(a); WriteReg(b)
      ELSE
        Texts.WriteString(W, mnemo0[op]);
        IF u = 1 THEN Texts.Write(W, "'") END ;
        WriteReg(a); WriteReg(b); WriteReg(w MOD 10H)
      END
    ELSIF k = 1 THEN  (*F1 register instruction*)
      IF fixD THEN
        a := w DIV 4000000H MOD 10H;  (*RH*)
        b := w DIV 100000H MOD 40H;  (*mno*)
        Texts.WriteString(W, "MOV'"); WriteReg(a);
        Texts.WriteString(W, " mno "); Texts.WriteInt(W, b, 3)
      ELSE
        Texts.WriteString(W, mnemo0[op]);
        IF u = 1 THEN Texts.Write(W, "'") END ;
        WriteReg(a); WriteReg(b); w := w MOD 10000H;
        IF w >= 8000H THEN w := w - 10000H END ;
        Texts.WriteInt(W, w, 7)
      END
    ELSIF k = 2 THEN  (*F2 memory instruction*)
      IF u = 1 THEN Texts.WriteString(W, "ST") ELSE Texts.WriteString(W, "LD") END ;
      IF v = 1 THEN Texts.Write(W, "B") ELSE Texts.Write(W, "W") END ;
      WriteReg(a); WriteReg(b); w := w MOD 100000H;
      IF w >= 80000H THEN w := w - 100000H END ;
      Texts.WriteInt(W, w, 8)
    ELSIF k = 3 THEN  (*F3 branch instruction*)
      k := w DIV 10H MOD 10H;
      IF (u = 0) & (v = 0) & (k # 0) THEN  (*interrupt*)
        IF k = 1 THEN Texts.WriteString(W, "RTI"); WriteReg(w MOD 10H)
        ELSIF k = 2 THEN
          IF ODD(w) THEN Texts.WriteString(W, "STI") ELSE Texts.WriteString(W, "CLI") END
        END
      ELSE
        Texts.Write(W, "B");
        IF v = 1 THEN Texts.Write(W, "L") END ;
        IF u = 0 THEN Texts.WriteString(W, mnemo1[a]); WriteReg(w MOD 10H)
        ELSIF fixP THEN
          a := w DIV 400000H MOD 40H;  (*mno*)
          b := w DIV 4000H MOD 100H;  (*pno*)
          Texts.WriteString(W, " mno "); Texts.WriteInt(W, a, 3);
          Texts.WriteString(W, ", pno "); Texts.WriteInt(W, b, 3)
        ELSE
          Texts.WriteString(W, mnemo1[a]); w := w MOD 100000H;
          IF w >= 80000H THEN w := w - 100000H END ;
          Texts.WriteInt(W, w, 8)
        END
      END
    END
  END opcode;

  PROCEDURE Write(VAR R: Files.Rider; x: INTEGER);
  BEGIN Files.WriteByte(R, x)  (* -128 <= x < 128 *)
  END Write;

  PROCEDURE DecObj*;  (*decode object file*)
    VAR class, i, n, key, size, adr, data, prg: INTEGER;
      ch: CHAR;
      name: ARRAY 32 OF CHAR;
      fixorgP, fixorgD, nofP, nofD: LONGINT;
      fixP, fixD: ARRAY 1000 OF LONGINT;  (*fixup positions*)
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name); Texts.WriteLn(W); Texts.WriteString(W, name);
        Files.ReadInt(R, key); Texts.WriteHex(W, key); Read(R, class); Texts.WriteInt(W, class, 4);  (*version*)
        Files.ReadInt(R, size); Texts.WriteInt(W, size, 6); Texts.WriteLn(W);
        Texts.WriteString(W, "imports:"); Texts.WriteLn(W); Files.ReadString(R, name);
        WHILE name[0] # 0X DO
          Texts.Write(W, TAB); Texts.WriteString(W, name);
          Files.ReadInt(R, key); Texts.WriteHex(W, key); Texts.WriteLn(W);
          Files.ReadString(R, name)
        END ;
        Texts.WriteString(W, "variables"); Files.ReadInt(R, data); Texts.WriteInt(W, data, 6); Texts.WriteLn(W);
        Texts.WriteString(W, "strings"); Files.ReadInt(R, n); Texts.WriteInt(W, n, 6); Texts.WriteLn(W);
        i := 0;
        WHILE i < n DO Files.Read(R, ch); Texts.Write(W, ch); INC(i) END ;
        Texts.WriteLn(W);
        Texts.WriteString(W, "type descriptors"); Files.ReadInt(R, n); Texts.WriteInt(W, n, 6); Texts.WriteLn(W);
        n := n DIV 4; i := 0;
        WHILE i < n DO Files.ReadInt(R, data); Texts.WriteHex(W, data); INC(i) END ;
        Texts.WriteLn(W);
        (*first pass*)
        Files.ReadInt(R, n); prg := Files.Pos(R); Files.Set(R, F, prg + n*4);  (*program code*)
        Files.ReadString(R, name);
        WHILE name[0] # 0X DO Files.ReadInt(R, data); Files.ReadString(R, name) END ;  (*commands*)
        Files.ReadInt(R, n); Files.Set(R, F, Files.Pos(R) + n*4);  (*entries*)
        Files.ReadInt(R, data);
        WHILE data >= 0 DO Files.ReadInt(R, data) END ;  (*pointer references*)
        Files.ReadInt(R, data);
        WHILE data >= 0 DO Files.ReadInt(R, data) END ;  (*procedure variable references*)
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD);
        (*record fixup positions*)
        adr := prg + fixorgP*4; nofP := 0;
        WHILE adr # prg DO
          Files.Set(R, F, adr);
          Files.ReadInt(R, data);  (*inst*)
          fixP[nofP] := (adr - prg) DIV 4; INC(nofP);
          adr := adr - (data MOD 4000H)*4
        END ;
        adr := prg + fixorgD*4; nofD := 0;
        WHILE adr # prg DO
          Files.Set(R, F, adr);
          Files.ReadInt(R, data);  (*inst*)
          fixD[nofD] := (adr - prg) DIV 4; INC(nofD);
          adr := adr - (data MOD 10000H)*4
        END ;
        Files.Set(R, F, prg-4);
        (*second pass*)
        Texts.WriteString(W, "program code"); Texts.WriteLn(W);
        Files.ReadInt(R, n); i := 0; DEC(nofP); DEC(nofD);
        WHILE i < n DO
          Files.ReadInt(R, data); Texts.WriteInt(W, i, 4); Texts.Write(W, TAB); Texts.WriteHex(W, data);
          Texts.Write(W, TAB);
          IF (nofP >= 0) & (i = fixP[nofP]) THEN opcode(data, TRUE, FALSE); DEC(nofP)
          ELSIF (nofD >= 0) & (i = fixD[nofD]) THEN opcode(data, FALSE, TRUE); DEC(nofD)
          ELSE opcode(data, FALSE, FALSE)
          END ;
          Texts.WriteLn(W); INC(i)
        END ;
        Texts.WriteString(W, "commands:"); Texts.WriteLn(W);
        Files.ReadString(R, name);
        WHILE name[0] # 0X DO
          Texts.Write(W, TAB); Texts.WriteString(W, name);
          Files.ReadInt(R, adr); Texts.WriteInt(W, adr, 5); Texts.WriteLn(W);
          Files.ReadString(R, name)
        END ;
        Texts.WriteString(W, "entries"); Texts.WriteLn(W);
        Files.ReadInt(R, n); i := 0;
        WHILE i < n DO Files.ReadInt(R, adr); Texts.WriteInt(W, adr, 6); INC(i) END ;
        Texts.WriteLn(W);
        Texts.WriteString(W, "pointer refs"); Texts.WriteLn(W); Files.ReadInt(R, adr);
        WHILE adr # -1 DO Texts.WriteInt(W, adr, 6); Files.ReadInt(R, adr) END ;
        Texts.WriteLn(W);
        Texts.WriteString(W, "procedure variables"); Texts.WriteLn(W); Files.ReadInt(R, adr);
        WHILE adr # -1 DO Texts.WriteInt(W, adr, 6); Files.ReadInt(R, adr) END ;
        Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "fixP = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "fixD = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "fixT = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "fixM = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "entry = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.ReadInt(R, data); Texts.WriteString(W, "final = "); Texts.WriteInt(W, data, 8); Texts.WriteLn(W);
        Files.Read(R, ch);
        IF ch # "O" THEN Texts.WriteString(W, "format error"); Texts.WriteLn(W) END
      ELSE Texts.WriteString(W, " not found"); Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END DecObj;

  PROCEDURE DecMod*;
    VAR mod: Modules.Module;
      adr, data: INTEGER;
      S: Texts.Scanner;
   BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
     IF S.class = Texts.Name THEN
       Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s);
       mod := Modules.root;
       WHILE (mod # NIL) & (mod.name # S.s) DO mod := mod.next END ;
       IF mod # NIL THEN
         Texts.WriteLn(W); adr := mod.prg;
         Texts.WriteString(W, "program code"); Texts.WriteInt(W, (mod.imp - adr) DIV 4, 6); Texts.WriteLn(W);
         WHILE adr # mod.imp DO
           SYSTEM.GET(adr, data); Texts.WriteInt(W, adr, 4); Texts.Write(W, TAB); Texts.WriteHex(W, data);
           Texts.Write(W, TAB); opcode(data, FALSE, FALSE); Texts.WriteLn(W); INC(adr, 4)
         END ;
       ELSE Texts.WriteString(W, " not loaded"); Texts.WriteLn(W)
       END ;
       Texts.Append(Oberon.Log, W.buf)
     END
  END DecMod;

  PROCEDURE DecBin*;  (*decode pre-linked binary file*)
    VAR AllocPtr, fprint, pos, num, size, prg, refcnt: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "decode "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN
        Files.Set(R, F, FPrintAdr); Files.ReadInt(R, fprint);
        IF fprint = FPrint THEN
          Files.Set(R, F, AllocAdr); Files.ReadInt(R, AllocPtr); Texts.WriteInt(W, AllocPtr, 7); Texts.WriteLn(W);
          Files.Set(R, F, ModAdr); pos := ModAdr;
          WHILE ~R.eof & (pos < AllocPtr) DO
            Files.ReadString(R, name);
            Files.Set(R, F, pos+40); (*num*) Files.ReadInt(R, num);
            Files.ReadInt(R, size); (*size*) Files.ReadInt(R, refcnt); (*refcnt*)
            Files.Set(R, F, pos+64); (*prg*) Files.ReadInt(R, prg);
            IF name[0] # 0X THEN Texts.WriteString(W, "  ");
              Texts.WriteString(W, name); Texts.WriteInt(W, num, 4); Texts.Write(W, TAB);
              Texts.WriteHex(W, pos); Texts.WriteHex(W, prg); Texts.WriteInt(W, refcnt, 4)
            ELSE Texts.WriteString(W, "---")
            END ;
            Texts.WriteLn(W); INC(pos, size); Files.Set(R, F, pos)
          END
        ELSE Texts.WriteString(W, "  input file format error"); Texts.WriteLn(W)
        END
      ELSE Texts.WriteString(W, " not found"); Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END DecBin;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "ORTool 18.2.2013 / AP 10.3.24");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
  mnemo0[0] := "MOV";
  mnemo0[1] := "LSL";
  mnemo0[2] := "ASR";
  mnemo0[3] := "ROR";
  mnemo0[4] := "AND";
  mnemo0[5] := "ANN";
  mnemo0[6] := "IOR";
  mnemo0[7] := "XOR";
  mnemo0[8] := "ADD";
  mnemo0[9] := "SUB";
  mnemo0[10] := "MUL";
  mnemo0[11] := "DIV";
  mnemo0[12] := "FAD";
  mnemo0[13] := "FSB";
  mnemo0[14] := "FML";
  mnemo0[15] := "FDV";
  mnemo1[0] := "MI ";
  mnemo1[8] := "PL";
  mnemo1[1] := "EQ ";
  mnemo1[9] := "NE ";
  mnemo1[2] := "LS ";
  mnemo1[10] := "HI ";
  mnemo1[5] := "LT ";
  mnemo1[13] := "GE ";
  mnemo1[6] := "LE ";
  mnemo1[14] := "GT ";
  mnemo1[15] := "NO "
END ORTool.
