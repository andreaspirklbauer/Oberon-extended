MODULE PCLink0;  (*AP 7.2.20 / 13.6.20*)
  IMPORT Files, RS232;
  CONST BlkLen = 255; (*packet size for Send and Receive*)
    REQ = 20H; ACK = 10H; NAK = 11H;

  PROCEDURE Send*; (*filename - send file*)
    VAR ch: CHAR;
      x, n, i, L: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
  BEGIN RS232.Send(ACK); RS232.RecStr(name); F := Files.Old(name);
    IF F # NIL THEN
      RS232.Send(ACK); L := Files.Length(F); Files.Set(R, F, 0);
      REPEAT (*send packet*)
        IF L > BlkLen THEN n := BlkLen ELSE n := L END ;
        RS232.Send(n); DEC(L, n); i := 0;
        WHILE i < n DO Files.Read(R, ch); RS232.Send(ORD(ch)); INC(i) END ;
        RS232.Rec(x);
        IF x # ACK THEN n := 0 END
      UNTIL n < BlkLen;
      RS232.Rec(x);
      IF x = REQ THEN RS232.Send(ACK) ELSE RS232.Send(NAK) END
    ELSE RS232.Send(NAK)
    END
  END Send;

  PROCEDURE Receive*; (*filename - receive file*)
    VAR x, n, i: INTEGER;
      name: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      buf: ARRAY 256 OF BYTE;
  BEGIN RS232.Send(ACK); RS232.RecStr(name); F := Files.New(name);
    IF F # NIL THEN
      RS232.Send(ACK); Files.Set(R, F, 0);
      REPEAT (*receive packet*)
        RS232.Rec(n); i := 0;
        WHILE i < n DO RS232.Rec(x); buf[i] := x; INC(i) END ;
        i := 0;
        WHILE i < n DO Files.WriteByte(R, buf[i]); INC(i) END ;
        RS232.Send(ACK)
      UNTIL n < BlkLen;
      Files.Register(F); RS232.Rec(x);
      IF x = REQ THEN RS232.Send(ACK) ELSE RS232.Send(NAK) END
    ELSE RS232.Send(NAK)
    END
  END Receive;

END PCLink0.
