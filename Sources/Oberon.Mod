MODULE Oberon; (*JG 6.9.90 / 23.9.93 / 13.8.94 / NW 14.4.2013 / 22.12.2015 / AP 4.4.24 Extended Oberon*)
  IMPORT SYSTEM, Kernel, Files, Modules, Input, Display, Viewers, Fonts, Texts;

  CONST (*message ids*)
    consume* = 0; track* = 1; defocus* = 0; neutralize* = 1; mark* = 2;
    off = 0; idle = 1; active = 2;  (*task states*)
    BasicCycle = 20;
    TaskPeriod = 500;  (*milliseconds*)
    TAB = Input.TAB; CR = Input.CR; LF = Input.LF; ESC = Input.ESC; SETSTAR = 1AX; LNK = 15;

  TYPE Painter* = PROCEDURE (x, y: INTEGER);
    Marker* = RECORD Fade*, Draw*: Painter END ;

    Cursor* = RECORD
       marker*: Marker; on*: BOOLEAN; X*, Y*: INTEGER
    END ;

    InputMsg* = RECORD (Display.FrameMsg)
      id*: INTEGER;                      (*consume, track*)
      keys*: SET;
      X*, Y*: INTEGER;
      ch*: CHAR;
      fnt*: Fonts.Font;
      col*, voff*: INTEGER
    END ;

    SelectionMsg* = RECORD (Display.FrameMsg)
      time*: LONGINT;
      text*: Texts.Text;
      beg*, end*: LONGINT
    END ;

    ControlMsg* = RECORD (Display.FrameMsg)
      id*, X*, Y*: INTEGER               (*defocus, neutralize, mark*)
    END ;

    CopyMsg* = RECORD (Display.FrameMsg)
      F*: Display.Frame
    END ;

    Task* = POINTER TO TaskDesc;

    Handler* = PROCEDURE;

    TaskDesc* = RECORD
      state, nextTime, period*: INTEGER;
      next: Task;
      handle: Handler
    END ;

    ParDesc* = RECORD
      vwr*: Viewers.Viewer;
      frame*: Display.Frame;
      text*: Texts.Text;
      cmd*, pos*: LONGINT;
      res*: INTEGER
    END ;

  VAR User*: ARRAY 8 OF CHAR; Password*: LONGINT;
    Arrow*, Star*: Marker; (*predefined markers representing an arrow pointing to the NW and a star symbol*)
    Mouse, Pointer: Cursor; (*predefined cursors representing a mouse and a global system pointer*)

    Log*: Texts.Text;
    Par*: ParDesc;

    CurFnt*: Fonts.Font;
    CurCol*, CurOff*: INTEGER;

    NofTasks*: INTEGER;
    CurTask, DeferTask: Task;

    DW, DH, CL: INTEGER;
    ActCnt: INTEGER; (*action count for garbage collector*)
    Mod: Modules.Module;

    defer: BOOLEAN; last: INTEGER;
    W: Texts.Writer;

  (*user identification*)

  PROCEDURE Code(VAR s: ARRAY OF CHAR): LONGINT;
    VAR i: INTEGER; a, b, c: LONGINT;
  BEGIN
    a := 0; b := 0; i := 0;
    WHILE s[i] # 0X DO
      c := b; b := a; a := (c MOD 509 + 1) * 127 + ORD(s[i]);
      INC(i)
    END ;
    IF b >= 32768 THEN b := b - 65536 END ;
    RETURN b * 65536 + a
  END Code;

  PROCEDURE SetUser* (VAR user, password: ARRAY OF CHAR);
  BEGIN User := user; Password := Code(password)
  END SetUser;

  PROCEDURE Clock*(): LONGINT;
  BEGIN RETURN Kernel.Clock()
  END Clock;

  PROCEDURE SetClock* (d: LONGINT);
  BEGIN Kernel.SetClock(d)
  END SetClock;

  PROCEDURE Time*(): LONGINT;
  BEGIN RETURN Kernel.Time()
  END Time;

  (*cursors handling*)

  PROCEDURE FlipArrow (X, Y: INTEGER);
  BEGIN
    IF X < CL THEN
      IF X > DW - 15 THEN X := DW - 15 END
    ELSE
      IF X > CL + DW - 15 THEN X := CL + DW - 15 END
    END ;
    IF Y < 14 THEN Y := 14 ELSIF Y > DH THEN Y := DH END ;
    Display.CopyPattern(Display.white, Display.arrow, X, Y - 14, Display.invert)
  END FlipArrow;

  PROCEDURE FlipStar (X, Y: INTEGER);
  BEGIN
    IF X < CL THEN
      IF X < 7 THEN X := 7 ELSIF X > DW - 8 THEN X := DW - 8 END
    ELSE
      IF X < CL + 7 THEN X := CL + 7 ELSIF X > CL + DW - 8 THEN X := CL + DW - 8 END
    END ;
    IF Y < 7 THEN Y := 7 ELSIF Y > DH - 8 THEN Y := DH - 8 END ;
    Display.CopyPattern(Display.white, Display.star, X - 7, Y - 7, Display.invert)
  END FlipStar;

  PROCEDURE OpenCursor(VAR c: Cursor);
  BEGIN c.on := FALSE; c.X := 0; c.Y := 0
  END OpenCursor;

  PROCEDURE FadeCursor(VAR c: Cursor);
  BEGIN IF c.on THEN c.marker.Fade(c.X, c.Y); c.on := FALSE END
  END FadeCursor;

  PROCEDURE DrawCursor(VAR c: Cursor; m: Marker; x, y: INTEGER);
  BEGIN
    IF c.on & ((x # c.X) OR (y # c.Y) OR (m.Draw # c.marker.Draw)) THEN
      c.marker.Fade(c.X, c.Y); c.on := FALSE
    END ;
    IF ~c.on THEN
      m.Draw(x, y); c.marker := m; c.X := x; c.Y := y; c.on := TRUE
    END
  END DrawCursor;

  PROCEDURE DrawMouse*(m: Marker; x, y: INTEGER);
  BEGIN DrawCursor(Mouse, m, x, y)
  END DrawMouse;

  PROCEDURE DrawMouseArrow*(x, y: INTEGER);
  BEGIN DrawCursor(Mouse, Arrow, x, y)
  END DrawMouseArrow;

  PROCEDURE DrawMouseStar* (x, y: INTEGER);
  BEGIN DrawCursor(Mouse, Star, x, y)
  END DrawMouseStar;

  PROCEDURE FadeMouse*;
  BEGIN FadeCursor(Mouse)
  END FadeMouse;

  PROCEDURE MouseOn*(): BOOLEAN;
  BEGIN RETURN Mouse.on
  END MouseOn;

  PROCEDURE DrawPointer*(m: Marker; x, y: INTEGER);
  BEGIN DrawCursor(Pointer, m, x, y)
  END DrawPointer;

  PROCEDURE DrawPointerArrow*(x, y: INTEGER);
  BEGIN DrawCursor(Pointer, Arrow, x, y)
  END DrawPointerArrow;

  PROCEDURE DrawPointerStar*(x, y: INTEGER);
  BEGIN DrawCursor(Pointer, Star, x, y)
  END DrawPointerStar;

  PROCEDURE FadePointer*;
  BEGIN FadeCursor(Pointer)
  END FadePointer;

  PROCEDURE PointerOn*(): BOOLEAN;
  BEGIN RETURN Pointer.on
  END PointerOn;

  PROCEDURE RemoveMarks* (X, Y, W, H: INTEGER);
  BEGIN
    IF (Mouse.X > X - 16) & (Mouse.X < X + W + 16) & (Mouse.Y > Y - 16) & (Mouse.Y < Y + H + 16) THEN
      FadeCursor(Mouse)
    END ;
    IF (Pointer.X > X - 8) & (Pointer.X < X + W + 8) & (Pointer.Y > Y - 8) & (Pointer.Y < Y + H + 8) THEN
      FadeCursor(Pointer)
    END
  END RemoveMarks;

  (*current looks*)

  PROCEDURE SetFont* (fnt: Fonts.Font);
  BEGIN CurFnt := fnt
  END SetFont;

  PROCEDURE SetColor* (col: INTEGER);
  BEGIN CurCol := col
  END SetColor;

  PROCEDURE SetOffset* (voff: INTEGER);
  BEGIN CurOff := voff
  END SetOffset;

  (*logs and text selections*)

  PROCEDURE OpenLog* (T: Texts.Text);
  BEGIN Log := T
  END OpenLog;

  PROCEDURE GetSelection* (VAR text: Texts.Text; VAR beg, end, time: LONGINT); (*from current display*)
    VAR M: SelectionMsg;
  BEGIN M.time := -1; Viewers.Broadcast(M); time := M.time;
    IF time >= 0 THEN text := M.text; beg := M.beg; end := M.end END
  END GetSelection;

  (*display management*)

  PROCEDURE HandleFiller (V: Display.Frame; VAR M: Display.FrameMsg);
  BEGIN
    CASE M OF
    InputMsg: IF M.id = track THEN DrawMouseArrow(M.X, M.Y) END |
    ControlMsg: IF M.id = mark THEN DrawPointerStar(M.X, M.Y) END |
    Viewers.ViewerMsg:
      IF (M.id = Viewers.restore) & (V.W > 0) & (V.H > 0) THEN
        RemoveMarks(V.X, V.Y, V.W, V.H);
        Display.ReplConst(Display.black, V.X, V.Y, V.W, V.H, Display.replace)
      ELSIF M.id = Viewers.modify THEN
        IF M.Y < V.Y THEN
          RemoveMarks(V.X, M.Y, V.W, V.Y - M.Y);
          Display.ReplConst(Display.black, V.X, M.Y, V.W, V.Y - M.Y, Display.replace)
        ELSIF M.Y > V.Y THEN RemoveMarks(V.X, V.Y, V.W, M.Y - V.Y)
        END
      END
    END
  END HandleFiller;

  PROCEDURE InitTrack* (D: Viewers.DisplayArea; W, H: INTEGER); (*add new track to the right*)
    VAR Filler: Viewers.Viewer;
  BEGIN NEW(Filler); Filler.handle := HandleFiller; Viewers.InitTrack(D, W, H, Filler)
  END InitTrack;

  PROCEDURE OpenTrack* (D: Viewers.DisplayArea; X, W: INTEGER); (*create overlay track at X*)
    VAR Filler: Viewers.Viewer;
  BEGIN NEW(Filler); Filler.handle := HandleFiller; Viewers.OpenTrack(D, X, W, Filler)
  END OpenTrack;

  PROCEDURE InitDisplay* (D: Viewers.DisplayArea; name: ARRAY OF CHAR);
  BEGIN Viewers.InitDisplay(D, DW, DH, name);
    InitTrack(D, DW DIV 8 * 5, DH);
    InitTrack(D, DW DIV 8 * 3, DH)
  END InitDisplay;

  PROCEDURE SetDisplay* (D: Viewers.DisplayArea);
  BEGIN Viewers.SetDisplay(D); Input.SetMouseLimits(D.curW, D.H)
  END SetDisplay;

  PROCEDURE CloseDisplay* (D: Viewers.DisplayArea; hint: INTEGER);
    VAR prev: Viewers.DisplayArea;
  BEGIN prev := Viewers.CurDisplay; Viewers.CloseDisplay(D, hint);
    IF Viewers.CurDisplay # prev THEN Input.SetMouseLimits(Viewers.CurDisplay.curW, Viewers.CurDisplay.H) END
  END CloseDisplay;

  PROCEDURE DisplayWidth* (X: INTEGER): INTEGER;
  BEGIN RETURN DW
  END DisplayWidth;

  PROCEDURE DisplayHeight* (X: INTEGER): INTEGER;
  BEGIN RETURN DH
  END DisplayHeight;

  PROCEDURE MarkedViewer* (): Viewers.Viewer;
  BEGIN RETURN Viewers.This(Pointer.X, Pointer.Y)
  END MarkedViewer;

  PROCEDURE PassFocus* (V: Viewers.Viewer);
    VAR M: ControlMsg;
  BEGIN
    IF Viewers.FocusViewer # NIL  THEN
      M.id := defocus; Viewers.FocusViewer.handle(Viewers.FocusViewer, M)
    END ;
    Viewers.SetFocus(Viewers.ThisDisplay(V), V)
  END PassFocus;

  PROCEDURE FocusViewer(): Viewers.Viewer;
  BEGIN RETURN Viewers.FocusViewer
  END FocusViewer;

  (*standard Oberon display with user track and system track, and filler viewer*)

  PROCEDURE UserTrack* (X: INTEGER): INTEGER;
  BEGIN RETURN X DIV DW * DW
  END UserTrack;

  PROCEDURE SystemTrack* (X: INTEGER): INTEGER;
  BEGIN RETURN X DIV DW * DW + DW DIV 8 * 5
  END SystemTrack;

  PROCEDURE UY (X: INTEGER): INTEGER;
    VAR y: INTEGER;
      fil, top, bot, alt, max: Display.Frame;
  BEGIN Viewers.Locate(Viewers.CurDisplay, X, 0, fil, top, bot, alt, max);
    IF fil.H >= DH DIV 8 THEN y := DH ELSE y := max.Y + max.H DIV 2 END ;
    RETURN y
  END UY;

  PROCEDURE AllocateUserViewer* (DX: INTEGER; VAR X, Y: INTEGER);
  BEGIN
    IF PointerOn() THEN X := Pointer.X; Y := Pointer.Y
    ELSE X := DX DIV DW * DW; Y := UY(X)
    END
  END AllocateUserViewer;

  PROCEDURE SY (X: INTEGER): INTEGER;
    VAR H0, H1, H2, H3, y: INTEGER;
      fil, top, bot, alt, max: Display.Frame;
  BEGIN H3 := DH - DH DIV 3; H2 := H3 - H3 DIV 2; H1 := DH DIV 5; H0 := DH DIV 10;
    Viewers.Locate(Viewers.CurDisplay, X, DH, fil, top, bot, alt, max);
    IF fil.H >= DH DIV 8 THEN y := DH
    ELSIF max.H >= DH - H0 THEN y := max.Y + H3
    ELSIF max.H >= H3 - H0 THEN y := max.Y + H2
    ELSIF max.H >= H2 - H0 THEN y := max.Y + H1
    ELSE y := max.Y + max.H DIV 2
    END ;
    RETURN y
  END SY;

  PROCEDURE AllocateSystemViewer* (DX: INTEGER; VAR X, Y: INTEGER);
  BEGIN
    IF PointerOn() THEN X := Pointer.X; Y := Pointer.Y
    ELSE X := DX DIV DW * DW + DW DIV 8 * 5; Y := SY(X)
    END
  END AllocateSystemViewer;

  (*garbage collection*)

  PROCEDURE CollectGarbage;
    VAR mod: Modules.Module;
  BEGIN
    IF (ActCnt <= 0) OR (Kernel.allocated >= Kernel.heapLim - Kernel.heapOrg - 10000H) THEN
      mod := Modules.root; LED(21H);
      WHILE mod # NIL DO
        IF mod.name[0] # 0X THEN Kernel.Mark(mod.ptr) END ;
        mod := mod.next
      END ;
      LED(23H);
      Files.RestoreList; LED(27H);
      Kernel.Collect; LED(20H);
      Modules.Collect;
      ActCnt := BasicCycle
    END
  END CollectGarbage;

  (*command interpretation*)

  PROCEDURE SetPar*(F: Display.Frame; T: Texts.Text; cmd, pos: LONGINT; res: INTEGER);
  BEGIN Par.vwr := Viewers.This(F.X, F.Y); Par.frame := F; Par.text := T; Par.cmd := cmd; Par.pos := pos; Par.res := res
  END SetPar;

  PROCEDURE ClearPar*;
  BEGIN Par.vwr := NIL; Par.frame := NIL; Par.text := NIL; Par.cmd := 0; Par.pos := 0; Par.res := 0
  END ClearPar;

  PROCEDURE Return*(n: INTEGER);
  BEGIN Par.res := n
  END Return;

  PROCEDURE Skip(VAR S: Texts.Scanner; VAR len: INTEGER);  (*skip and count white spaces*)
    VAR ch: CHAR; i: INTEGER;
  BEGIN Texts.Read(S, ch); i := 0;
    WHILE (ch = " ") OR (ch = TAB) OR (ch = CR) OR (ch = LF) DO
      IF ch = CR THEN INC(S.line) END ;
      Texts.Read(S, ch); INC(i)
    END ;
    S.nextCh := ch; len := i
  END Skip;

  PROCEDURE Scan(VAR S: Texts.Scanner);
    VAR ch: CHAR; i: INTEGER;
  BEGIN ch := S.nextCh;
    IF ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z") OR (ch = "*") OR ("0" <= ch) & (ch <= "9") THEN i := 0;
      REPEAT S.s[i] := ch; INC(i); Texts.Read(S, ch)
      UNTIL ((ch < "0") & (ch # ".") & (ch # "*") OR ("9" < ch) & (ch < "A") OR ("Z" < ch) & (ch < "a") OR ("z" < ch)) OR (i = 31);
      S.s[i] := 0X; S.len := i; S.class := Texts.Name; S.nextCh := ch
    ELSE S.class := Texts.Inval
    END
  END Scan;

  PROCEDURE Call*(F: Display.Frame; T: Texts.Text; pos: LONGINT; new: BOOLEAN);
    VAR S: Texts.Scanner; res, len: INTEGER;
  BEGIN Texts.OpenScanner(S, T, pos); Skip(S, len); Scan(S);
    IF (S.class = Texts.Name) & (S.line = 0) THEN
      SetPar(F, T, pos, pos + len + S.len, 0); Modules.Call(S.s, res);
      IF (res > Modules.noerr) & (res < Modules.clients) & (Log # NIL) THEN Texts.WriteString(W, "Call error: ");
        CASE res OF
           Modules.nofile: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " module not found")
         | Modules.badversion: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " bad version")
         | Modules.badkey: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " imports ");
             Texts.WriteString(W, Modules.imported); Texts.WriteString(W, " with bad key")
         | Modules.badfile: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " corrupted obj file")
         | Modules.nospace: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " insufficient space")
         | Modules.nocmd: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " command not found")
         | Modules.badcmd: Texts.WriteString(W, S.s); Texts.WriteString(W, " invalid command")
         | Modules.nomod: Texts.WriteString(W, Modules.importing); Texts.WriteString(W, " module not found")
         | Modules.badfin: Texts.WriteString(W, S.s); Texts.WriteString(W, " invalid finalization")
        END ;
        Par.res := res; Texts.WriteLn(W); Texts.Append(Log, W.buf)
      END
    END
  END Call;

  PROCEDURE Execute(F: Display.Frame; T: Texts.Text; pos: LONGINT; collect: BOOLEAN);  (*execute multiple commands separated by ~*)
    VAR S: Texts.Scanner; len: LONGINT; continue: BOOLEAN;
  BEGIN continue := pos >= 0;
    WHILE continue DO
      Texts.OpenScanner(S, T, pos); Skip(S, len); Scan(S); continue := FALSE;
      IF (S.class = Texts.Name) & (S.s # "Oberon.Batch") THEN S.line := 0;
        Call(F, T, pos + len, FALSE);
        IF collect THEN ActCnt := 0; CollectGarbage END ;
        IF Par.res = 0 THEN
          REPEAT Texts.Scan(S) UNTIL S.eot OR (S.class = Texts.Char) & (S.c = "~");
          IF ~S.eot THEN pos := Texts.Pos(S); continue := TRUE END
        END
      END
    END
  END Execute;

  PROCEDURE Run*(F: Display.Frame; T: Texts.Text; pos: LONGINT);  (*does not invoke garbage collector*)
  BEGIN Execute(F, T, pos, FALSE)
  END Run;

  PROCEDURE Batch*;  (*invokes garbage collector after each executed command*)
    VAR S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Par.text, Par.cmd); Texts.Scan(S);
    Execute(Par.frame, Par.text, Par.pos, (S.class = Texts.Name) & (S.s = "Oberon.Batch"))
  END Batch;

  (*task management*)

  PROCEDURE NewTask*(h: Handler; period: INTEGER): Task;
    VAR t: Task;
  BEGIN NEW(t); t.state := off; t.next := t; t.handle := h; t.period := period; RETURN t
  END NewTask;

  PROCEDURE Install* (T: Task);
  BEGIN
    IF T.state = off THEN
      T.next := CurTask.next; CurTask.next := T; T.state := idle; T.nextTime := 0; INC(NofTasks)
    END
  END Install;

  PROCEDURE Remove* (T: Task);
    VAR t: Task;
  BEGIN
    IF T.state # off THEN t := T;
      WHILE t.next # T DO t := t.next END ;
      t.next := T.next; T.state := off; T.next := NIL; CurTask := t; DEC(NofTasks)
    END
  END Remove;

  PROCEDURE Collect* (count: INTEGER);
  BEGIN ActCnt := count
  END Collect;

  PROCEDURE Loop*;
    VAR V: Viewers.Viewer; M: InputMsg; N: ControlMsg;
      prevX, prevY, X, Y, t: INTEGER; keys: SET; ch: CHAR;
  BEGIN
    REPEAT
      Input.Mouse(keys, X, Y);
      IF Input.Available() > 0 THEN Input.Read(ch);
        IF ch = ESC THEN
          N.id := neutralize; Viewers.Broadcast(N); FadePointer; LED(0)
        ELSIF ch = SETSTAR THEN
          N.id := mark; N.X := X; N.Y := Y; V := Viewers.This(X, Y); V.handle(V, N)
        ELSE M.id := consume; M.ch := ch; M.fnt := CurFnt; M.col := CurCol; M.voff := CurOff;
          V := Viewers.FocusViewer; V.handle(V, M); DEC(ActCnt)
        END
      ELSIF keys # {} THEN
        M.id := track; M.X := X; M.Y := Y; M.keys := keys;
        REPEAT V := Viewers.This(M.X, M.Y); V.handle(V, M); Input.Mouse(M.keys, M.X, M.Y)
        UNTIL M.keys = {};
        DEC(ActCnt)
      ELSE
        IF (X # prevX) OR (Y # prevY) OR ~MouseOn() THEN
          M.id := track; M.X := X;
          IF Y >= DH THEN Y := DH END ;
          M.Y := Y; M.keys := keys; V := Viewers.This(X, Y); V.handle(V, M); prevX := X; prevY := Y
        END ;
        CurTask := CurTask.next; t := Kernel.Time();
        IF t >= CurTask.nextTime THEN
          CurTask.nextTime := t + CurTask.period; CurTask.state := active; CurTask.handle; CurTask.state := idle
        END
      END
    UNTIL FALSE
  END Loop;

  PROCEDURE Reset*;
  BEGIN
    IF CurTask.state = active THEN Remove(CurTask) END ;
    SYSTEM.LDREG(14, Kernel.stackOrg); (*reset stack pointer*) Loop
  END Reset;

  PROCEDURE Trap(VAR a: INTEGER; b, c, d: INTEGER);
    VAR u, v, w: INTEGER; mod: Modules.Module;
  BEGIN u := SYSTEM.REG(LNK);  (*return address, deposited in register LNK by the trap (BLR TR) instruction*)
    SYSTEM.GET(u - 4, v);  (*trap instruction, contains code position and trap number*)
    w := v DIV 10H MOD 10H;  (*trap number*)
    IF w = 0 THEN Kernel.New(a, b, c, d)
    ELSE (*trap*)
      IF Log # NIL THEN
        IF defer THEN (*defer trap handling*) last := u; Install(DeferTask)
        ELSE defer := TRUE;
          Texts.WriteLn(W); Texts.WriteString(W, "  pos ");
          Texts.WriteInt(W, v DIV 100H MOD 10000H, 4);  (*code position*)
          Texts.WriteString(W, "  TRAP"); Texts.WriteInt(W, w, 4); mod := Modules.root;
          WHILE (mod # NIL) & ((u < mod.prg) OR (u >= mod.imp)) DO mod := mod.next END ;
          IF mod # NIL THEN Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
          Texts.WriteString(W, " at"); Texts.WriteHex(W, u); Texts.WriteLn(W); Texts.Append(Log, W.buf);
          defer := FALSE
        END
      END ;
      Collect(0); Reset
    END
  END Trap;

  PROCEDURE Abort;
    VAR u: INTEGER; mod: Modules.Module;
  BEGIN
    IF Log # NIL THEN
      u := SYSTEM.REG(LNK);  (*return address, deposited in register LNK by the abort (BL 0) instruction*)
      IF defer THEN (*defer abort handling*) last := u; Install(DeferTask)
      ELSE defer := TRUE;
        Texts.WriteLn(W); Texts.WriteString(W, "  ABORT  "); mod := Modules.root;
        WHILE (mod # NIL) & ((u < mod.prg) OR (u >= mod.imp)) DO mod := mod.next END ;
        IF mod # NIL THEN Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
        Texts.WriteString(W, " at"); Texts.WriteHex(W, u); Texts.WriteLn(W); Texts.Append(Log, W.buf);
        defer := FALSE
      END
    END ;
    Collect(0); Reset
  END Abort;

  PROCEDURE Deferred;  (*handle trap/abort as soon as the garbage collector has freed up enough heap space*)
    VAR v, w, pos: INTEGER; mod: Modules.Module;
  BEGIN
    IF (Kernel.allocated < Kernel.heapLim - Kernel.heapOrg - 10000H) & (Log # NIL) THEN Remove(DeferTask);
      SYSTEM.GET(last - 4, v);  (*trap instruction, contains code position and trap number*)
      pos := v DIV 100H MOD 10000H;  (*code position*)
      Texts.WriteLn(W);
      IF pos # 0 THEN
        w := v DIV 10H MOD 10H;  (*trap number*)
        Texts.WriteString(W, "  pos "); Texts.WriteInt(W, pos, 4);
        Texts.WriteString(W, "  RECURSIVE TRAP"); Texts.WriteInt(W, w, 4)
      ELSE Texts.WriteString(W, "  RECURSIVE ABORT  ")
      END ;
      mod := Modules.root;
      WHILE (mod # NIL) & ((last < mod.prg) OR (last >= mod.imp)) DO mod := mod.next END ;
      IF mod # NIL THEN Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
      Texts.WriteString(W, " at"); Texts.WriteHex(W, last); Texts.WriteLn(W); Texts.Append(Log, W.buf);
      defer := FALSE
    END
  END Deferred;

BEGIN User[0] := 0X;
  Arrow.Fade := FlipArrow; Arrow.Draw := FlipArrow;
  Star.Fade := FlipStar; Star.Draw := FlipStar;
  OpenCursor(Mouse); OpenCursor(Pointer);

  DW := Display.Width; DH := Display.Height; CL := DW;
  CurFnt := Fonts.Default; CurCol := Display.white; CurOff := 0;

  ActCnt := 0; CurTask := NewTask(CollectGarbage, 1000); Install(CurTask);
  Texts.OpenWriter(W); Log := NIL;

  defer := FALSE; DeferTask := NewTask(Deferred, TaskPeriod);
  Kernel.Install(SYSTEM.ADR(Trap), Kernel.TrapAdr); Kernel.Install(SYSTEM.ADR(Abort), 0);

  IF Modules.importing = "Oberon" THEN (*loaded by the regular loader*)
    Modules.Load("System", Mod); Mod := NIL; Loop
  END
END Oberon.
