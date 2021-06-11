MODULE ORC; (*Connection to RISC; NW 11.11.2013 / AP 13.6.20*)
  IMPORT SYSTEM, Files, Texts, Oberon, RS232;

  CONST stat = -52; BlkLen = 255;
    REQ = 20H; REC = 21H; SND = 22H; ACK = 10H;
    Tout = 1000;

  VAR W: Texts.Writer;

  PROCEDURE Rec(VAR x: INTEGER); (*receive 1 byte with timeout*)
    VAR T: LONGINT;
  BEGIN T := Oberon.Time();
    REPEAT UNTIL SYSTEM.BIT(stat, 0) OR (Oberon.Time()-T >= Tout);
    IF Oberon.Time()-T < Tout THEN RS232.Rec(x) ELSE x := 0 END
  END Rec;

  PROCEDURE RecInt(VAR x: INTEGER); (*receive 4 bytes with timeout*)
    VAR i, x0, y: INTEGER;
  BEGIN i := 4; x0 := 0;
    REPEAT DEC(i); Rec(y); x0 := ROR(x0+y, 8) UNTIL i = 0;
    x := x0
  END RecInt;

  PROCEDURE SendInt(x: INTEGER);
    VAR i: INTEGER;
  BEGIN i := 4;
    REPEAT DEC(i); RS232.Send(x); x := ROR(x, 8) UNTIL i = 0
  END SendInt;

  PROCEDURE SendName(x: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN i := 0;
    REPEAT k := ORD(x[i]); RS232.Send(k); INC(i) UNTIL k = 0
  END SendName;

  PROCEDURE Flush*; (*flush with timeout*)
    VAR x: INTEGER; T: LONGINT;
  BEGIN T := Oberon.Time();
    WHILE SYSTEM.BIT(stat, 0) & (Oberon.Time()-T < Tout) DO RS232.Rec(x) END
  END Flush;

  PROCEDURE TestReq*;
    VAR x: INTEGER;
  BEGIN RS232.Send(REQ); Rec(x); Texts.WriteInt(W, x, 4);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END TestReq;

  (*------------ load prelinked build-up boot file ------------*)

  PROCEDURE Load*;
    VAR i, m, n, w: LONGINT;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN (*input file name*)
      Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN Files.Set(R, F, 0);
        n := Files.Length(F); n := n DIV 4; (*size in words*) m := 0; (*address*)
        Texts.WriteString(W, " loading "); Texts.Append(Oberon.Log, W.buf);
        i := 0; SendInt(n*4); SendInt(m);
        WHILE i < n DO
          IF i + 1024 < n THEN m := i + 1024 ELSE m := n END ;
          WHILE i < m DO Files.ReadInt(R, w); SendInt(w); INC(i); END ;
          Texts.Write(W, "."); Texts.Append(Oberon.Log, W.buf)
        END ;
        SendInt(0); Texts.WriteInt(W, n*4, 6)
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END ;
    Flush
  END Load;

  (*------------ send and receive files ------------*)

  PROCEDURE Send*;
    VAR ch: CHAR;
      n, n0, L, LL: LONGINT;
      code: INTEGER;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN RS232.Send(REQ); Rec(code);
    IF code = ACK THEN
      Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
      WHILE S.class = Texts.Name DO
        Texts.WriteString(W, S.s); F := Files.Old(S.s);
        IF F # NIL THEN
          RS232.Send(REC); RS232.Rec(code);
          IF code = ACK THEN SendName(S.s); RS232.Rec(code) END ;
          IF code = ACK THEN
            Texts.WriteString(W, " sending ");
            L := Files.Length(F); Files.Set(R, F, 0); LL := 0;
            REPEAT (*send packet*)
              IF L > BlkLen THEN n := BlkLen ELSE n := L END ;
              n0 := n; RS232.Send(n); DEC(L, n);
              WHILE n > 0 DO Files.Read(R, ch); RS232.Send(ORD(ch)); DEC(n) END ;
              RS232.Rec(code); LL := LL + n0;
              IF code = ACK THEN Texts.Write(W, ".") ELSE Texts.Write(W, "*"); n := 0 END ;
              Texts.Append(Oberon.Log, W.buf)
            UNTIL n0 < BlkLen;
            RS232.Send(REQ); RS232.Rec(code);
            IF code = ACK THEN Texts.WriteInt(W, LL, 6) ELSE Texts.WriteString(W, " failed") END
          ELSE Texts.WriteString(W, " no response"); Texts.WriteInt(W, ORD(code), 4)
          END
        ELSE Texts.WriteString(W, " not found")
        END ;
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Texts.Scan(S)
      END
    ELSE Texts.WriteString(W, " connection not open");
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END Send;

  PROCEDURE Receive*;
    VAR ch: CHAR;
      code, x: INTEGER;
      n, L, LL: LONGINT;
      F: Files.File; R: Files.Rider;
      orgname: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN RS232.Send(REQ); Rec(code);
    IF code = ACK THEN
      Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
      WHILE S.class = Texts.Name DO
        Texts.WriteString(W, S.s); orgname := S.s;
        F := Files.New(S.s); Files.Set(R, F, 0); LL := 0;
        RS232.Send(SND); RS232.Rec(code);
        IF code = ACK THEN SendName(S.s); RS232.Rec(code) END ;
        IF code = ACK THEN
          Texts.WriteString(W, " receiving ");
          REPEAT (*receive packet*)
            RS232.Rec(x); L := x; n := L;
            WHILE n > 0 DO RS232.Rec(x); Files.Write(R, CHR(x)); DEC(n) END ;
            RS232.Send(ACK); LL := LL + L; Texts.Write(W, "."); Texts.Append(Oberon.Log, W.buf)
          UNTIL L < BlkLen;
          RS232.Send(REQ); RS232.Rec(code);
          IF code = ACK THEN Files.Register(F); Texts.WriteInt(W, LL, 6) ELSE Texts.WriteString(W, " failed") END
        ELSE Texts.WriteString(W, " no response"); Texts.WriteInt(W, ORD(code), 4)
        END ;
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Texts.Scan(S)
      END
    ELSE Texts.WriteString(W, " connection not open");
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END Receive;

  (*------------ Oberon-0 commands ------------*)

  PROCEDURE SR*;  (*send, then receive sequence of items*)
    VAR S: Texts.Scanner; i, k: LONGINT; ch: CHAR; x, y: INTEGER;
  BEGIN Texts.WriteString(W, "ORC.SR ");
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    WHILE (S.class # Texts.Char) & (S.c # "~") DO
      IF S.class = Texts.Int THEN Texts.WriteInt(W, S.i, 6); SendInt(S.i)
      ELSIF S.class = Texts.Real THEN
        Texts.WriteReal(W, S.x, 12); SendInt(SYSTEM.VAL(LONGINT, S.x))
      ELSIF S.class IN {Texts.Name, Texts.String} THEN
        Texts.Write(W, " "); Texts.WriteString(W, S.s); SendName(S.s)
      ELSIF S.class = Texts.Char THEN Texts.Write(W, S.c)
      ELSE Texts.WriteString(W, "bad value")
      END ;
      Texts.Scan(S)
    END ;
    Texts.WriteString(W, " | "); Texts.Append(Oberon.Log, W.buf);
    (*receive input*)
    REPEAT Rec(x);
      IF x = 0 THEN Texts.WriteString(W, " timeout"); Flush
      ELSIF x = 1 THEN (*Int*) RecInt(k); Texts.WriteInt(W, k, 6)
      ELSIF x = 2 THEN (*Hex*) RecInt(k); Texts.WriteHex(W, k)
      ELSIF x = 3 THEN (*Real*) RecInt(k); Texts.WriteReal(W, SYSTEM.VAL(REAL, k), 15)
      ELSIF x = 4 THEN (*String*) RS232.Rec(y); ch := CHR(y);
        WHILE ch > 0X DO Texts.Write(W, ch); RS232.Rec(y); ch := CHR(y) END
      ELSIF x = 5 THEN (*Char*) RS232.Rec(x); ch := CHR(x); Texts.Write(W, ch)
      ELSIF x = 6 THEN (*Line*) Texts.WriteLn(W)
      ELSIF x = 7 THEN (*End*) x := 0
      ELSIF x = 8 THEN RS232.Rec(k); Texts.WriteInt(W, k, 4)
      ELSE x := 0
      END ;
      Texts.Append(Oberon.Log, W.buf)
    UNTIL x = 0;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END SR;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OR Connection  11.11.13 / AP 13.6.20");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END ORC.
