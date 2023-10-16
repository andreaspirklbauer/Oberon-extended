MODULE Out; (*AP 1.10.23*)
  IMPORT Texts, Oberon, TextFrames, MenuViewers;

  CONST StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store | System.Expand System.Spread System.Clone";

  VAR T: Texts.Text; W: Texts.Writer;
    immediate: BOOLEAN;
    
  PROCEDURE Append*;
  BEGIN IF immediate THEN Texts.Append(T, W.buf) END
  END Append;

  PROCEDURE Open*;  (*open a separate viewer for output*)
    VAR X, Y: INTEGER; V: MenuViewers.Viewer;
  BEGIN
    IF T = Oberon.Log THEN T := TextFrames.Text(""); 
      Oberon.AllocateUserViewer(0, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu("Out.Text", StandardMenu),
        TextFrames.NewText(T, 0), TextFrames.menuH, X, Y)
    END
  END Open;

  PROCEDURE Close*;  (*revert output to the system log*)
  BEGIN T := Oberon.Log
  END Close;

  PROCEDURE Char*(ch: CHAR);
  BEGIN Texts.Write(W, ch); Append
  END Char;

  PROCEDURE String*(x: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, x); Append
  END String;

  PROCEDURE Int*(x, n: INTEGER);
  BEGIN Texts.WriteInt(W, x, n); Append
  END Int;

  PROCEDURE Hex*(x: LONGINT);
  BEGIN Texts.WriteHex(W, x); Append
  END Hex;

  PROCEDURE CharHex*(ch: CHAR);  (*char as hex*)
    VAR i, x, d: INTEGER;  a: ARRAY 2 OF CHAR;
  BEGIN i := 0;  x := ORD(ch);
    REPEAT d := x MOD 16;
      IF d < 10 THEN a[i] := CHR(d + ORD("0")) ELSE a[i] := CHR(d - 10 + ORD("A")) END ;
      x := x DIV 16; INC(i)
    UNTIL x = 0;
    IF a[i-1] >= "A" THEN Texts.Write(W, "0") END ;
    REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0;
    Texts.Write(W, "X");
    Append
  END CharHex;

  PROCEDURE ByteHex*(b: BYTE; h: BOOLEAN);  (*byte as two-digit hex, three-digit if h is set*)
    VAR i, x, d: INTEGER;  a: ARRAY 2 OF CHAR;
  BEGIN i := 0;  x := b;
    REPEAT d := x MOD 16;
      IF d < 10 THEN a[i] := CHR(d + ORD("0")) ELSE a[i] := CHR(d - 10 + ORD("A")) END ;
      x := x DIV 16; INC(i)
    UNTIL x = 0;
    IF h THEN Texts.Write(W, "0") END ;
    IF b < 16 THEN Texts.Write(W, "0") END ;
    REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0;
    IF h THEN Texts.Write(W, "H") END ;
    Append
  END ByteHex;

  PROCEDURE IntHex*(x: INTEGER);  (*integer as hex*)
  BEGIN Texts.WriteHex(W, x);  Texts.Write(W, "H"); Append
  END IntHex;

  PROCEDURE RealHex*(x: REAL);  (*real as hex*)
  BEGIN Texts.WriteHex(W, ORD(x));  Texts.Write(W, "H"); Append
  END RealHex;

  PROCEDURE Real*(x: REAL;  n: INTEGER);
  BEGIN Texts.WriteReal(W, x, n); Append
  END Real;

  PROCEDURE RealFix*(x: REAL; n, k: INTEGER);  (*fixed point notation*)
  BEGIN Texts.WriteRealFix(W, x, n, k); Append
  END RealFix;

  PROCEDURE Bool*(b: BOOLEAN);
  BEGIN IF b THEN Char("T") ELSE Char("F") END
  END Bool;

  PROCEDURE Ln*;
  BEGIN Texts.WriteLn(W); Texts.Append(T, W.buf)
  END Ln;

  PROCEDURE SetImmediate*(on: BOOLEAN);
  BEGIN immediate := on
  END SetImmediate;

  PROCEDURE ImmediateOn*(): BOOLEAN;
  BEGIN RETURN immediate
  END ImmediateOn;

BEGIN Texts.OpenWriter(W); T := Oberon.Log; immediate := TRUE
END Out.
