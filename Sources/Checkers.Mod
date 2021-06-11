MODULE Checkers;  (*NW 4.10.90 / 10.3.13 / AP 12.2.20 Extended Oberon*)
  IMPORT SYSTEM, Display, Viewers, Oberon, MenuViewers, TextFrames;

  CONST Menu = "System.Close System.Copy System.Grow | System.Expand System.Spread System.Clone";

  TYPE Frame = POINTER TO FrameDesc;

    FrameDesc = RECORD (Display.FrameDesc)
        col: INTEGER
      END ;

  VAR i: INTEGER;
    checks: INTEGER;
    pat: ARRAY 17 OF INTEGER;

  PROCEDURE Restore(F: Frame);
  BEGIN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
    Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, Display.replace); (*clear*)
    Display.ReplPattern(F.col, checks, F.X+1, F.Y, F.W-1, F.H-1, Display.paint)
  END Restore;

  PROCEDURE Handle(G: Display.Frame; VAR M: Display.FrameMsg);
    VAR G1: Frame;
  BEGIN
    CASE G OF Frame:
      CASE M OF
      Oberon.InputMsg:
        IF M.id = Oberon.track THEN Oberon.DrawMouseArrow(M.X, M.Y) END |
      Oberon.CopyMsg:
        Oberon.RemoveMarks(G.X, G.Y, G.W, G.H); NEW(G1); G1^ := G^; M.F := G1 |
      Viewers.ViewerMsg:
        IF M.id = Viewers.restore THEN G.Y := M.Y; G.H := M.H; Restore(G)
        ELSIF M.id = Viewers.modify THEN
          IF (M.Y # G.Y) OR (M.H # G.H) THEN G.Y := M.Y; G.H := M.H; Restore(G) END
        END
      END
    END
  END Handle;

  PROCEDURE Open*;
    VAR F: Frame; V: Viewers.Viewer; X, Y: INTEGER;
  BEGIN NEW(F); F.col := 14; F.handle := Handle;
    Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(
      TextFrames.NewMenu("CheckerViewer", Menu),
      F, TextFrames.menuH, X, Y)
  END Open;

BEGIN checks := SYSTEM.ADR(pat); pat[0] := 1010H; i := 1;
  REPEAT pat[i] := 0FF00FFH; INC(i) UNTIL i = 9;
  REPEAT pat[i] := 0FF00FF00H; INC(i) UNTIL i = 17
END Checkers.
