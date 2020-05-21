MODULE Hilbert;  (*NW 8.1.2013  for RISC / AP 12.2.20 Extended Oberon*)
  IMPORT Display, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  CONST Menu = "System.Close System.Copy System.Grow | System.Expand System.Spread System.Clone";

  VAR x, y, d: INTEGER;
    A, B, C, D: PROCEDURE (i: INTEGER);

  PROCEDURE E;
  BEGIN Display.ReplConst(Display.white, x, y, d, 1, Display.paint); INC(x, d)
  END E;

  PROCEDURE N;
  BEGIN Display.ReplConst(Display.white, x, y, 1, d, Display.paint); INC(y, d)
  END N;

  PROCEDURE W;
  BEGIN DEC(x, d); Display.ReplConst(Display.white, x, y, d, 1, Display.paint)
  END W;

  PROCEDURE S;
  BEGIN DEC(y, d); Display.ReplConst(Display.white, x, y, 1, d, Display.paint)
  END S;

  PROCEDURE HA(i: INTEGER);
  BEGIN
    IF i > 0 THEN D(i-1); W; A(i-1); S; A(i-1); E; B(i-1) END
  END HA;

  PROCEDURE HB(i: INTEGER);
  BEGIN
    IF i > 0 THEN C(i-1); N; B(i-1); E; B(i-1); S; A(i-1) END
  END HB;

  PROCEDURE HC(i: INTEGER);
  BEGIN
    IF i > 0 THEN B(i-1); E; C(i-1); N; C(i-1); W; D(i-1) END
  END HC;

  PROCEDURE HD(i: INTEGER);
  BEGIN
    IF i > 0 THEN A(i-1); S; D(i-1); W; D(i-1); N; C(i-1) END
  END HD;

  PROCEDURE DrawHilbert(F: Display.Frame);
    VAR k, n, w, x0, y0: INTEGER;
  BEGIN k := 0; d := 8;
    IF F.W < F.H THEN w := F.W ELSE w := F.H END ;
    WHILE d*2 < w DO d := d*2; INC(k) END ;
    Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, Display.replace);
    x0 := F.W DIV 2; y0 := F.H DIV 2; n := 0;
    WHILE n < k DO
      d := d DIV 2; INC(x0, d DIV 2); INC(y0, d DIV 2);
      x := F.X + x0; y := F.Y + y0; INC(n); HA(n)
    END
  END DrawHilbert;

  PROCEDURE Handler(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F0: Display.Frame;
  BEGIN
    IF M IS Oberon.InputMsg THEN
      IF M(Oberon.InputMsg).id = Oberon.track THEN
        Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y)
      END
    ELSIF M IS Viewers.ViewerMsg THEN
      IF (M(Viewers.ViewerMsg).id = Viewers.restore) OR (M(Viewers.ViewerMsg).id = Viewers.modify) THEN
        F.Y := M(Viewers.ViewerMsg).Y; F.H := M(Viewers.ViewerMsg).H; DrawHilbert(F)
      END
    ELSIF M IS Oberon.ControlMsg THEN
      IF M(Oberon.ControlMsg).id = Oberon.neutralize THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H) END
    ELSIF M IS Oberon.CopyMsg THEN
      NEW(F0); F0^ := F^; M(Oberon.CopyMsg).F := F0
    END
  END Handler;

  PROCEDURE New(): Display.Frame;
    VAR F: Display.Frame;
  BEGIN NEW(F); F.handle := Handler; RETURN F
  END New;

  PROCEDURE Draw*;
    VAR V: Viewers.Viewer; X, Y: INTEGER;
  BEGIN Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu("Hilbert", Menu), New(), TextFrames.menuH, X, Y)
  END Draw;
  
BEGIN A := HA; B := HB; C := HC; D := HD
END Hilbert.
