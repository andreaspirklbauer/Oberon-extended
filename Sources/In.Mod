MODULE In; (*AP 12.4.21 / Extended Oberon*)
  IMPORT Viewers, Texts, Oberon, TextFrames;

  VAR Done*: BOOLEAN;
    S: Texts.Scanner;

  PROCEDURE Open*;
    VAR T: Texts.Text; V: Viewers.Viewer;
      beg, end, time: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Done := TRUE ELSE Done := FALSE END
    ELSIF (S.class = Texts.Char) & (S.c = "*") THEN
      V := Oberon.MarkedViewer();
      IF (V # NIL) & (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
        Texts.OpenScanner(S, V.dsc.next(TextFrames.Frame).text, 0); Done := TRUE
      ELSE Done := FALSE
      END
    ELSE Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Done := TRUE
    END
  END Open;

  PROCEDURE Char*(VAR ch: CHAR);
  BEGIN
    IF Done THEN ch := S.nextCh; Done := ~S.eot; Texts.Read(S, S.nextCh) END
  END Char;

  PROCEDURE Int*(VAR x: LONGINT);
  BEGIN
    IF Done THEN Texts.Scan(S);
      IF S.class = Texts.Int THEN x := S.i ELSE Done := FALSE END
    END
  END Int;

  PROCEDURE Real*(VAR x: REAL);
  BEGIN
    IF Done THEN Texts.Scan(S);
      IF S.class = Texts.Real THEN x := S.x
      ELSIF S.class = Texts.Int THEN x := FLT(S.i)
      ELSE Done := FALSE
      END
    END
  END Real;

  PROCEDURE String*(VAR x: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    IF Done THEN Texts.Scan(S);
      IF (S.class = Texts.String) OR (S.class = Texts.Name) THEN i := 0;
        WHILE (S.s[i] # 0X) & (i < LEN(x)-1) DO x[i] := S.s[i]; INC(i) END ;
        x[i] := 0X
      END
    END
  END String;

  PROCEDURE Name*(VAR x: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN
    IF Done THEN Texts.Scan(S);
      IF S.class = Texts.Name THEN i := 0;
        WHILE (S.s[i] # 0X) & (i < LEN(x)-1) DO x[i] := S.s[i]; INC(i) END ;
        x[i] := 0X
      END
    END
  END Name;

BEGIN Done := FALSE
END In.
