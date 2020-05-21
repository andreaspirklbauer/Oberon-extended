MODULE Out; (*AP 7.2.20*)
  IMPORT Texts, Oberon;
  VAR W: Texts.Writer;

  PROCEDURE Char*(ch: CHAR);
  BEGIN Texts.Write(W, ch); Texts.Append(Oberon.Log, W.buf)
  END Char;

  PROCEDURE Ln*;
  BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Ln;

  PROCEDURE Str*(s: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, s); Texts.Append(Oberon.Log, W.buf)
  END Str;

  PROCEDURE Int*(x, n: INTEGER);
  BEGIN Texts.WriteInt(W, x, n); Texts.Append(Oberon.Log, W.buf)
  END Int;

  PROCEDURE Hex*(x: LONGINT);
  BEGIN Texts.WriteHex(W, x); Texts.Append(Oberon.Log, W.buf)
  END Hex;

  PROCEDURE Real*(x: REAL;  n: INTEGER);
  BEGIN Texts.WriteReal(W, x, n); Texts.Append(Oberon.Log, W.buf)
  END Real;

  PROCEDURE RealFix*(x: REAL; n, k: INTEGER);
  BEGIN Texts.WriteRealFix(W, x, n, k); Texts.Append(Oberon.Log, W.buf)
  END RealFix;

  PROCEDURE Bool*(x: BOOLEAN);
  BEGIN IF x THEN Texts.WriteString(W, "TRUE") ELSE Texts.WriteString(W, "FALSE") END ;
    Texts.Append(Oberon.Log, W.buf)
  END Bool;

BEGIN Texts.OpenWriter(W)
END Out.
