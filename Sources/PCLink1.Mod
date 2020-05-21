MODULE PCLink1;  (*NW 25.7.2013  for Oberon on RISC*)
  IMPORT SYSTEM, Files, Texts, Oberon;
  
  CONST data = -56; stat = -52;
    BlkLen = 255;
    REQ = 20H; REC = 21H; SND = 22H; ACK = 10H; NAK = 11H;

  VAR T: Oberon.Task;
    W: Texts.Writer;

  PROCEDURE Rec(VAR x: BYTE);
  BEGIN
    REPEAT UNTIL SYSTEM.BIT(stat, 0);
    SYSTEM.GET(data, x)
  END Rec;

  PROCEDURE RecName(VAR s: ARRAY OF CHAR);
    VAR i: INTEGER; x: BYTE;
  BEGIN i := 0; Rec(x);
    WHILE x > 0 DO s[i] := CHR(x); INC(i); Rec(x) END ;
    s[i] := 0X
  END RecName;

  PROCEDURE Send(x: BYTE);
  BEGIN
    REPEAT UNTIL SYSTEM.BIT(stat, 1);
    SYSTEM.PUT(data, x)
  END Send;

  PROCEDURE Task;
    VAR len, n, i: INTEGER;
      x, ack, len1, code: BYTE;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      buf: ARRAY 256 OF BYTE;
  BEGIN
    IF  SYSTEM.BIT(stat, 0) THEN (*byte available*)
      Rec(code);
        IF code = SND THEN  (*send file*)
          LED(20H); RecName(name); F := Files.Old(name);
          IF F # NIL THEN
            Texts.WriteString(W, "sending "); Texts.WriteString(W, name);
            Texts.Append(Oberon.Log, W.buf);
            Send(ACK); len := Files.Length(F); Files.Set(R, F, 0);
            REPEAT
              IF len >= BlkLen THEN len1 := BlkLen ELSE len1 := len END ;
              Send(len1); n := len1; len := len - len1;
              WHILE n > 0 DO Files.ReadByte(R, x); Send(x); DEC(n) END ;
              Rec(ack);
              IF ack # ACK THEN  len1 := 0 END
            UNTIL len1 < BlkLen;
            Texts.WriteString(W, " done"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
          ELSE Send(11H)
          END
        ELSIF code = REC THEN (*receive file*)
          LED(30H); RecName(name); F := Files.New(name);
          IF F # NIL THEN
            Texts.WriteString(W, "receiving "); Texts.WriteString(W, name);
            Texts.Append(Oberon.Log, W.buf);
            Files.Set(R, F, 0); Send(ACK);
            REPEAT Rec(x); len := x; i := 0;
              WHILE i < len DO Rec(x); buf[i] := x; INC(i) END ;
              i := 0;
              WHILE i < len DO Files.WriteByte(R, buf[i]); INC(i) END ;
              Send(ACK)
            UNTIL len < 255;
            Files.Register(F); Send(ACK);
            Texts.WriteString(W, " done"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
          ELSE Send(NAK)
          END
        ELSIF code = REQ THEN Send(ACK)
        END ;
      LED(0)
    END
  END Task;

  PROCEDURE Run*;
  BEGIN Oberon.Install(T); Texts.WriteString(W, "PCLink started");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Run;

  PROCEDURE Stop*;
  BEGIN Oberon.Remove(T); Texts.WriteString(W, "PCLink stopped");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Stop;

BEGIN Texts.OpenWriter(W); T := Oberon.NewTask(Task, 0)
END PCLink1.
