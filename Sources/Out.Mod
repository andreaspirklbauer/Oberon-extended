MODULE Out; (*AP 12.4.21 / Extended Oberon*)
  IMPORT Texts, Oberon, TextFrames, MenuViewers;

  CONST StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store | System.Expand System.Spread System.Clone";

  VAR T: Texts.Text; W: Texts.Writer;

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
  BEGIN Texts.Write(W, ch); Texts.Append(T, W.buf)
  END Char;

  PROCEDURE Int*(x, n: INTEGER);
  BEGIN Texts.WriteInt(W, x, n); Texts.Append(T, W.buf)
  END Int;

  PROCEDURE Hex*(x: LONGINT);
  BEGIN Texts.WriteHex(W, x); Texts.Append(T, W.buf)
  END Hex;

  PROCEDURE Real*(x: REAL;  n: INTEGER);
  BEGIN Texts.WriteReal(W, x, n); Texts.Append(T, W.buf)
  END Real;

  PROCEDURE RealFix*(x: REAL; n, k: INTEGER);
  BEGIN Texts.WriteRealFix(W, x, n, k); Texts.Append(T, W.buf)
  END RealFix;

  PROCEDURE String*(x: ARRAY OF CHAR);
  BEGIN Texts.WriteString(W, x); Texts.Append(T, W.buf)
  END String;

  PROCEDURE Ln*;
  BEGIN Texts.WriteLn(W); Texts.Append(T, W.buf)
  END Ln;

BEGIN Texts.OpenWriter(W); T := Oberon.Log
END Out.
