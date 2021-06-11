MODULE Tools;   (*NW 22.2.14 / AP 15.9.20 Extended Oberon*)
  IMPORT SYSTEM, Disk, Files, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  CONST StandardMenu = "Tools.Close System.Copy System.Grow Edit.Search Edit.Store | System.Expand System.Spread System.Clone";
    TAB = 09X; LF = 0AX; CR = 0DX;

  VAR T: Texts.Text; W: Texts.Writer; open: BOOLEAN;

  PROCEDURE OpenViewer(T: Texts.Text; title: ARRAY OF CHAR);
    VAR X, Y: INTEGER; V: MenuViewers.Viewer; (*V is declared local to make other viewers unreachable from V*)
  BEGIN
    IF ~open THEN open := TRUE;
      Oberon.AllocateUserViewer(0, X, Y);
      V := MenuViewers.New(
          TextFrames.NewMenu(title, StandardMenu),
          TextFrames.NewText(T, 0), TextFrames.menuH, X, Y)
    END
  END OpenViewer;

  PROCEDURE Clear*;  (*used to clear output*)
    VAR buf: Texts.Buffer;
  BEGIN NEW(buf); Texts.OpenBuf(buf); Texts.Delete(T, 0, T.len, buf)
  END Clear;

  PROCEDURE Close*;
    VAR V: Viewers.Viewer;
  BEGIN open := FALSE;
    IF Oberon.Par.frame = Oberon.Par.vwr.dsc THEN V := Oberon.Par.vwr ELSE V := Oberon.MarkedViewer() END;
    Viewers.Close(V)
  END Close;

  PROCEDURE Recall*;
  BEGIN OpenViewer(T, "Tools.Text") (*consecutive calls to Recall will open output only once*)
  END Recall;

  PROCEDURE Inspect*;
    VAR m, n, adr, data: INTEGER;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN
      adr := S.i DIV 20H * 20H; Texts.Scan(S);
      IF S.class = Texts.Int THEN n := S.i ELSE n := 8 END ;
      REPEAT DEC(n); Texts.WriteLn(W); Texts.WriteHex(W, adr); Texts.Write(W, TAB); m := 8;
        REPEAT SYSTEM.GET(adr, data); INC(adr, 4); Texts.WriteHex(W, data); DEC(m)
        UNTIL m = 0
      UNTIL n = 0;
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END Inspect;

  PROCEDURE Sector*;
    VAR k, m, n, secno: INTEGER;
      S: Texts.Scanner;
      buf: ARRAY 256 OF INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN
      secno := S.i; Texts.Scan(S);
      IF S.class = Texts.Int THEN n := S.i ELSE n := 8 END ;
      Disk.GetSector(secno*29, buf); Texts.WriteString(W, "Sector "); Texts.WriteInt(W, S.i, 4);
      k := 0;
      REPEAT DEC(n); m := 8; Texts.WriteLn(W); Texts.WriteHex(W, k*4); Texts.Write(W, TAB);
        REPEAT Texts.WriteHex(W, buf[k]); INC(k); DEC(m) UNTIL m = 0;
      UNTIL n = 0;
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END Sector;

  PROCEDURE ShowFile*;
    VAR x, n: INTEGER;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN
        n := 0; Files.Set(R, F, 0); Files.ReadInt(R, x);
        WHILE ~R.eof DO
          IF n MOD 20H = 0 THEN Texts.WriteLn(W); Texts.WriteHex(W, n); Texts.Write(W, TAB) END ;
          Texts.WriteHex(W, x); INC(n, 4); Files.ReadInt(R, x)
        END ;
        Texts.WriteHex(W, x)
      ELSE Texts.WriteString(W, " not found")
      END ;
      Texts.WriteLn(W); Texts.Append(T, W.buf)
    END
  END ShowFile;

  PROCEDURE Convert*;   (*convert selected text to txt-format*)
    VAR beg, end, time: LONGINT
      ; ch: CHAR;
      T: Texts.Text; R: Texts.Reader;  (*input*)
      F: Files.File; Q: Files.Rider;   (*output*)
      S: Texts.Scanner;
  BEGIN Oberon.GetSelection(T, beg, end, time);
    IF time >= 0 THEN
      Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
      Texts.WriteString(W, "converting to "); Texts.WriteString(W, S.s);
      F := Files.New(S.s); Files.Set(Q, F, 0); Texts.OpenReader(R, T, beg); Texts.Read(R, ch);
      WHILE ~R.eot DO
        IF ch = CR THEN Files.Write(Q, CR); Files.Write(Q, LF)
        ELSIF ch = TAB THEN Files.Write(Q, " "); Files.Write(Q, " ")
        ELSE Files.Write(Q, ch)
        END ;
        Texts.Read(R, ch)
      END ;
      Files.Register(F); Texts.WriteString(W, " done")
    ELSE Texts.WriteString(W, " not found")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Texts.Scan(S)
  END Convert;

  PROCEDURE Id*;
  BEGIN Texts.WriteHex(W, SYSTEM.H(1)); Texts.WriteLn(W); Texts.Append(T, W.buf)
  END Id;

BEGIN Texts.OpenWriter(W); T := TextFrames.Text(""); open := FALSE; OpenViewer(T, "Tools.Text")
END Tools.

Tools.Clear  (clear tool viewer)
Tools.Recall   (recall closed tool viewer)
Tools.Inspect adr len
Tools.Sector secno
Tools.ShowFile filename  (in hex)
Tools.Convert filename  (selected text to txt-format)
Tools.Id   (processor id)
