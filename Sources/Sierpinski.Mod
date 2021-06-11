MODULE Sierpinski;  (*NW 15.1.2013 / AP 12.2.20 Extended Oberon*)
  IMPORT Display, Viewers, Oberon, MenuViewers, TextFrames;

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

  PROCEDURE NE;
    VAR i: INTEGER;
  BEGIN i := d;
    REPEAT Display.Dot(Display.white, x, y, Display.paint); INC(x); INC(y); DEC(i) UNTIL i = 0
  END NE;

  PROCEDURE NW;
    VAR i: INTEGER;
  BEGIN i := d;
    REPEAT Display.Dot(Display.white, x, y, Display.paint); DEC(x); INC(y); DEC(i) UNTIL i = 0
  END NW;

  PROCEDURE SW;
    VAR i: INTEGER;
  BEGIN i := d;
    REPEAT Display.Dot(Display.white, x, y, Display.paint); DEC(x); DEC(y); DEC(i) UNTIL i = 0
  END SW;

  PROCEDURE SE;
    VAR i: INTEGER;
  BEGIN i := d;
    REPEAT Display.Dot(Display.white, x, y, Display.paint); INC(x); DEC(y); DEC(i) UNTIL i = 0
  END SE;

  PROCEDURE SA(i: INTEGER);
  BEGIN
    IF i > 0 THEN A(i-1); SE; B(i-1); E; E; D(i-1); NE; A(i-1) END
  END SA;

  PROCEDURE SB(i: INTEGER);
  BEGIN
    IF i > 0 THEN B(i-1); SW; C(i-1); S; S; A(i-1); SE; B(i-1) END
  END SB;

  PROCEDURE SC(i: INTEGER);
  BEGIN
    IF i > 0 THEN C(i-1); NW; D(i-1); W; W; B(i-1); SW; C(i-1) END
  END SC;

  PROCEDURE SD(i: INTEGER);
  BEGIN
    IF i > 0 THEN D(i-1); NE; A(i-1); N; N; C(i-1); NW; D(i-1) END
  END SD;

  PROCEDURE DrawSierpinski(F: Display.Frame);
    VAR k, n, w, x0, y0: INTEGER;
  BEGIN; k := 0; d := 4;
    IF F.W < F.H THEN w := F.W ELSE w := F.H END ;
    WHILE d*8 < w DO d := d*2; INC(k) END ;
    Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, Display.replace);
    x0 := F.W DIV 2; y0 := F.H DIV 2 + d; n := 0;
    WHILE n < k DO
      INC(n); DEC(x0, d); d := d DIV 2; INC(y0, d);
      x := F.X + x0; y := F.Y + y0;
      SA(n); SE; SB(n); SW; SC(n); NW; SD(n); NE
    END
  END DrawSierpinski;

  PROCEDURE Handler(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F1: Display.Frame;
  BEGIN
    IF M IS Oberon.InputMsg THEN
      IF M(Oberon.InputMsg).id = Oberon.track THEN
        Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y)
      END
    ELSIF M IS Viewers.ViewerMsg THEN
      IF (M(Viewers.ViewerMsg).id = Viewers.restore) OR (M(Viewers.ViewerMsg).id = Viewers.modify) THEN
        F.Y := M(Viewers.ViewerMsg).Y; F.H := M(Viewers.ViewerMsg).H; DrawSierpinski(F)
      END
    ELSIF M IS Oberon.ControlMsg THEN
      IF M(Oberon.ControlMsg).id = Oberon.neutralize THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H) END
    ELSIF M IS Oberon.CopyMsg THEN
       NEW(F1); F1^ := F^; M(Oberon.CopyMsg).F := F1
    END
  END Handler;

  PROCEDURE New(): Display.Frame;
    VAR F: Display.Frame;
  BEGIN NEW(F); F.handle := Handler; RETURN F
  END New;

  PROCEDURE Draw*;
    VAR V: Viewers.Viewer; X, Y: INTEGER;
  BEGIN Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu("Sierpinski", Menu), New(), TextFrames.menuH, X, Y)
  END Draw;

BEGIN A := SA; B := SB; C := SC; D := SD
END Sierpinski.

