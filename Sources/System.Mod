MODULE System; (*JG 3.10.90 / NW 12.10.93 / NW 20.6.2016 / AP 19.5.21 Extended Oberon*)
  IMPORT SYSTEM, Kernel, Disk, FileDir, Files, Modules,
    Input, Display, Viewers, Fonts, Texts, Oberon, MenuViewers, TextFrames;

  CONST Version* = "Extended Oberon System  AP 19.5.21";
    StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store | System.Expand System.Spread System.Clone";
    LogMenu = "Edit.Locate Edit.Search System.Copy System.Grow System.Clear | System.Expand System.Spread System.Clone";
    SystemLog = "System.Log"; SystemTool = "System.Tool"; SystemBatch = "System.Batch";
    TAB = Input.TAB; CR = Input.CR; LNK = 15; TaskPeriod = 500; (*ms*)

  TYPE Handler = PROCEDURE(name: ARRAY OF CHAR);

  VAR W: Texts.Writer; M: Modules.Module; T: Oberon.Task; ref, last: INTEGER; defer: BOOLEAN;
    pat: ARRAY 32 OF CHAR;

  PROCEDURE GetArg(VAR S: Texts.Scanner);
    VAR T: Texts.Text; beg, end, time: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END
  END GetArg;

  PROCEDURE EndLine;
  BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EndLine;

  (* ------------- Toolbox for system control ---------------*)

  PROCEDURE SetUser*;
    VAR i: INTEGER; ch: CHAR;
      user: ARRAY 8 OF CHAR;
      password: ARRAY 16 OF CHAR;
  BEGIN i := 0; Input.Read(ch);
    WHILE (ch # "/") & (i < 7) DO user[i] := ch; INC(i); Input.Read(ch) END;
    user[i] := 0X; i := 0; Input.Read(ch);
    WHILE (ch > " ") & (i < 15) DO password[i] := ch; INC(i); Input.Read(ch) END;
    password[i] := 0X; Oberon.SetUser(user, password)
  END SetUser;

  PROCEDURE SetFont*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN Oberon.SetFont(Fonts.Load(S.s)) END
  END SetFont;

  PROCEDURE SetColor*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN Oberon.SetColor(S.i) END
  END SetColor;

  PROCEDURE SetOffset*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN Oberon.SetOffset(S.i) END
  END SetOffset;

  PROCEDURE Date*;
    VAR S: Texts.Scanner;
      dt, hr, min, sec, yr, mo, day: LONGINT;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN (*set clock*)
      day := S.i; Texts.Scan(S); mo := S.i; Texts.Scan(S); yr := S.i; Texts.Scan(S);
      hr := S.i; Texts.Scan(S); min := S.i; Texts.Scan(S); sec := S.i;
      dt := ((((yr*16 + mo)*32 + day)*32 + hr)*64 + min)*64 + sec;
      Kernel.SetClock(dt)
    ELSE (*read clock*) Texts.WriteString(W, "System.Clock");
      dt := Oberon.Clock(); Texts.WriteClock(W, dt); EndLine
    END
  END Date;

  PROCEDURE Collect*;
  BEGIN Oberon.Collect(0)
  END Collect;

  (* ------------- Toolbox for standard display ---------------*)

  PROCEDURE Open*;  (*open viewer in system track*)
    VAR X, Y: INTEGER;
      V: Viewers.Viewer;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, StandardMenu),
        TextFrames.NewText(TextFrames.Text(S.s), 0), TextFrames.menuH, X, Y)
    END
  END Open;

  PROCEDURE OpenLog*;  (*open another viewer for Log*)
    VAR V: Viewers.Viewer; X, Y: INTEGER;
  BEGIN Oberon.AllocateSystemViewer(0, X, Y);
    IF Oberon.Log = NIL THEN Oberon.OpenLog(TextFrames.Text("")) END ;
    V := MenuViewers.New(
      TextFrames.NewMenu(SystemLog, LogMenu),
      TextFrames.NewText(Oberon.Log, 0), TextFrames.menuH, X, Y)
  END OpenLog;

  PROCEDURE Clear*;  (*clear Log*)
    VAR T: Texts.Text; F: Display.Frame; buf: Texts.Buffer;
  BEGIN F := Oberon.Par.frame;
    IF (F # NIL) & (F.next IS TextFrames.Frame) & (F = Oberon.Par.vwr.dsc) THEN
      NEW(buf); Texts.OpenBuf(buf); T := F.next(TextFrames.Frame).text; Texts.Delete(T, 0, T.len, buf)
    END
  END Clear;

  PROCEDURE Close*;  (*viewer*)
    VAR V: Viewers.Viewer;
  BEGIN
    IF Oberon.Par.frame = Oberon.Par.vwr.dsc THEN V := Oberon.Par.vwr
    ELSE V := Oberon.MarkedViewer()
    END;
    Viewers.Close(V)
  END Close;

  PROCEDURE CloseSelf*;
  BEGIN Viewers.Close(Oberon.Par.vwr)
  END CloseSelf;

  PROCEDURE CloseTrack*;
    VAR D: Viewers.DisplayArea; V: Viewers.Viewer;
  BEGIN V := Oberon.MarkedViewer(); D := Viewers.ThisDisplay(V); Viewers.CloseTrack(D, V.X)
  END CloseTrack;

  PROCEDURE Flush*;  (*clear the last closed viewer of the current display*)
  BEGIN Viewers.Flush(Viewers.CurDisplay)
  END Flush;

  PROCEDURE Recall*;  (*recover the last closed viewer of the current display*)
    VAR V: Viewers.Viewer; curDisplay: Viewers.DisplayArea; M: Viewers.ViewerMsg;
  BEGIN curDisplay := Viewers.CurDisplay; Viewers.Recall(curDisplay, V);
    IF (V # NIL) & (V.state = 0) THEN
      Viewers.Open(curDisplay, V, V.X, V.Y + V.H); M.id := Viewers.restore; V.handle(V, M)
    END
  END Recall;

  PROCEDURE RecallFocus*;  (*recover the focus viewer of the current display*)
    VAR V: Viewers.Viewer; M: Viewers.ViewerMsg;
  BEGIN V := Viewers.FocusViewer;
    IF (V # NIL) & (V.state = 0) THEN
      Viewers.Open(Viewers.CurDisplay, V, V.X, V.Y + V.H); M.id := Viewers.restore; V.handle(V, M)
    END
  END RecallFocus;

  PROCEDURE Copy*;  (*create a copy of the viewer in the current display*)
    VAR V, V1: Viewers.Viewer; M: Oberon.CopyMsg; N: Viewers.ViewerMsg;
  BEGIN V := Oberon.Par.vwr; V.handle(V, M); V1 := M.F(Viewers.Viewer);
    Viewers.Open(Viewers.CurDisplay, V1, V.X, V.Y + V.H DIV 2);
    N.id := Viewers.restore; V1.handle(V1, N)
  END Copy;

  PROCEDURE Grow*;  (*create a copy of the viewer in a newly created overlaying track*)
    VAR D: Viewers.DisplayArea; V, V1: Viewers.Viewer; M: Oberon.CopyMsg; N: Viewers.ViewerMsg;
  BEGIN V := Oberon.Par.vwr; D := Viewers.ThisDisplay(V);
    IF V.H < D.H - D.minH THEN Oberon.OpenTrack(D, V.X, V.W)
    ELSIF V.W < D.W THEN Oberon.OpenTrack(D, Oberon.UserTrack(V.X), D.W)
    END ;
    IF (V.H < D.H - D.minH) OR (V.W < D.W) THEN
      V.handle(V, M); V1 := M.F(Viewers.Viewer);
      Viewers.Open(D, V1, V.X, D.H);
      N.id := Viewers.restore; V1.handle(V1, N)
    END
  END Grow;

  PROCEDURE Expand*;  (*expand the viewer vertically as much as possible*)
    VAR V: Viewers.Viewer; y, h: INTEGER;
  BEGIN V := Oberon.Par.vwr; y := 0; h := Oberon.DisplayHeight(0);
    Viewers.Validate(V, y, h); Viewers.Change(V, y, h)
  END Expand;

  PROCEDURE Spread*;  (*redistribute viewers vertically*)
    VAR D: Viewers.DisplayArea; V: Viewers.Viewer;
  BEGIN V := Oberon.Par.vwr; D := Viewers.ThisDisplay(V); Viewers.Spread(D, V.X, V.W)
  END Spread;

  PROCEDURE MakeDisplayName(prefix: ARRAY OF CHAR; id: INTEGER; VAR name: ARRAY OF CHAR);  (*0 <= id < 10^5*)
    VAR i, j: INTEGER; buf: ARRAY 5 OF INTEGER;
  BEGIN i := 0; j := 0;
    WHILE (i < Viewers.DnLength-1) & (prefix[i] # 0X) DO name[i] := prefix[i]; INC(i) END ;
    REPEAT buf[j] := id MOD 10; id := id DIV 10; INC(j) UNTIL id = 0;
    WHILE (i < Viewers.DnLength-1) & (j > 0) DO DEC(j); name[i] := CHR(buf[j] + ORD("0")); INC(i) END ;
    name[i] := 0X
  END MakeDisplayName;

  PROCEDURE OpenViewers;  (*open log and system tool viewer in system track of current display*)
    VAR logV, toolV: Viewers.Viewer;
      menu, main: Display.Frame;
      X, Y: INTEGER;
  BEGIN
    IF Viewers.CurDisplay # NIL THEN
      Texts.WriteString(W, Version); Texts.WriteString(W, " / Display ");
      Texts.WriteInt(W, Viewers.CurDisplay.id, 3); Texts.Write(W, " ");
      Texts.WriteString(W, Viewers.CurDisplay.name); EndLine;
      Oberon.AllocateSystemViewer(0, X, Y);
      menu := TextFrames.NewMenu(SystemLog, LogMenu);
      main := TextFrames.NewText(Oberon.Log, 0);
      logV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y);
      Oberon.AllocateSystemViewer(0, X, Y);
      menu := TextFrames.NewMenu(SystemTool, StandardMenu);
      main := TextFrames.NewText(TextFrames.Text(SystemTool), 0);
      toolV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y)
    END
  END OpenViewers;

  PROCEDURE CreateDisplay(name: ARRAY OF CHAR);
    VAR D: Viewers.DisplayArea;
  BEGIN NEW(D); Oberon.InitDisplay(D, name); Oberon.SetDisplay(D); OpenViewers
  END CreateDisplay;

  PROCEDURE OpenDisplay*;  (*display name is provided as parameter*)
    VAR S: Texts.Scanner; prev: INTEGER;
  BEGIN prev := Viewers.CurDisplay.id; GetArg(S);
    IF S.class # Texts.Name THEN MakeDisplayName("opened from display ", prev, S.s) END ;
    CreateDisplay(S.s);
    Texts.WriteString(W, " now in display "); Texts.WriteInt(W, Viewers.CurDisplay.id, 3);
    Texts.WriteString(W,", to return: System.SetDisplay "); Texts.WriteInt(W, prev, 3); EndLine
  END OpenDisplay;

  PROCEDURE Clone*;  (*create a copy of the viewer in a newly created display*)
    VAR D: Viewers.DisplayArea; V, V1: Viewers.Viewer;
      M: Oberon.CopyMsg; N: Viewers.ViewerMsg; prev: INTEGER;
      name: ARRAY Viewers.DnLength OF CHAR;
  BEGIN V := Oberon.Par.vwr; V.handle(V, M); V1 := M.F(Viewers.Viewer); prev := Viewers.CurDisplay.id;
    MakeDisplayName("cloned from display ", prev, name); CreateDisplay(name);
    Viewers.Open(Viewers.CurDisplay, V1, 0, Oberon.DisplayHeight(0));
    N.id := Viewers.restore; V1.handle(V1, N);
    Texts.WriteString(W, " now in display "); Texts.WriteInt(W, Viewers.CurDisplay.id, 3);
    Texts.WriteString(W,", to return: System.SetDisplay ");
    Texts.WriteInt(W, prev, 3); Texts.WriteLn(W);
    Texts.WriteString(W," to close this cloned display and then return: System.CloseDisplay ");
    Texts.WriteInt(W, Viewers.CurDisplay.id, 3); Texts.WriteInt(W, prev, 3);
    EndLine
  END Clone;

  PROCEDURE ExtendDisplay*;  (*extend the current display to the right*)
    VAR V: Viewers.Viewer; curDisplay: Viewers.DisplayArea;
      X, Y, DX, DW, DH: INTEGER;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN curDisplay := Viewers.CurDisplay; DX := curDisplay.curW;
      DW := Oberon.DisplayWidth(DX); DH := Oberon.DisplayHeight(DX);
      Oberon.InitTrack(curDisplay, DW DIV 8 * 5, DH);  (*wide user track on the left, 5/8 of the screen width*)
      Oberon.InitTrack(curDisplay, DW DIV 8 * 3, DH);  (*narrow system track on the right, 3/8 of the screen width*)
      Input.SetMouseLimits(curDisplay.curW, curDisplay.H);
      Oberon.AllocateSystemViewer(DX, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, StandardMenu),
        TextFrames.NewText(TextFrames.Text(S.s), 0),
        TextFrames.menuH, X, Y)
    END
  END ExtendDisplay;

  PROCEDURE CloseDisplay*;  (*display id and (optionally) a hint for the display to switch to are provided as parameters*)
    VAR D: Viewers.DisplayArea; S: Texts.Scanner; prev, id, hint: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN id := S.i; D := Viewers.GetDisplay(S.i);
      IF D = NIL THEN Texts.WriteString(W, " no such display ")
      ELSE prev := Viewers.CurDisplay.id;
        IF D.id = prev THEN Texts.Scan(S);
          IF S.class = Texts.Int THEN hint := S.i ELSE hint := 0 END
        ELSE hint := prev
        END ;
        Oberon.CloseDisplay(D, hint);
        IF (id = prev) & (Viewers.CurDisplay.id = prev) THEN Texts.WriteString(W, " last display")
        ELSE Texts.WriteString(W, " display "); Texts.WriteInt(W, id, 3); Texts.WriteString(W, " closed");
          IF id = prev THEN Texts.WriteString(W, ", now in display "); Texts.WriteInt(W, Viewers.CurDisplay.id, 3) END
        END
      END
    ELSE Texts.WriteString(W, " invalid display number")
    END ;
    EndLine
  END CloseDisplay;

  PROCEDURE SwitchDisplay(D: Viewers.DisplayArea);  (*switch to the specified display*)
    VAR prev: INTEGER;
  BEGIN prev := Viewers.CurDisplay.id;
    IF (D # NIL) & (D.id # prev) THEN Oberon.SetDisplay(D);
      Texts.WriteString(W, " now in display "); Texts.WriteInt(W, Viewers.CurDisplay.id, 3);
      Texts.WriteString(W,", to return: System.SetDisplay "); Texts.WriteInt(W, prev, 3); EndLine
    END
  END SwitchDisplay;

  PROCEDURE SetDisplay*;  (*display id is provided as parameter*)
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN SwitchDisplay(Viewers.GetDisplay(S.i)) END
  END SetDisplay;

  PROCEDURE NextDisplay*;  (*switch to display on the "right"*)
    VAR D: Viewers.Viewer;
  BEGIN D := Viewers.Next(Viewers.CurDisplay); SwitchDisplay(D(Viewers.DisplayArea))
  END NextDisplay;

  PROCEDURE PrevDisplay*;  (*switch to display on the "left"*)
    VAR D: Viewers.Viewer;
  BEGIN D := Viewers.Prev(Viewers.CurDisplay); SwitchDisplay(D(Viewers.DisplayArea))
  END PrevDisplay;

  PROCEDURE SetDisplayName*;  (*display id and name are provided as parameters*)
    VAR D: Viewers.DisplayArea; S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN Texts.Scan(S);
      IF S.class = Texts.Name THEN D := Viewers.GetDisplay(S.i);
        IF D = NIL THEN Texts.WriteString(W, " no such display ")
        ELSE D.name := S.s; Texts.WriteString(W, " display "); Texts.WriteInt(W, D.id, 3);
          Texts.WriteString(W, " renamed to "); Texts.WriteString(W, D.name)
        END
      ELSE Texts.WriteString(W, " no display name provided (SetDisplayName id name)")
      END
    ELSE Texts.WriteString(W, " no display id provided (SetDisplayName id name)")
    END ;
    EndLine
  END SetDisplayName;

  PROCEDURE ThisDisplay*;
    VAR D: Viewers.DisplayArea;
  BEGIN D := Viewers.ThisDisplay(Oberon.Par.vwr); Texts.WriteString(W, " current display ");
    Texts.WriteInt(W, D.id, 3); Texts.Write(W, " "); Texts.WriteString(W, D.name); EndLine
  END ThisDisplay;

  PROCEDURE ShowDisplays*;
    VAR D: Viewers.DisplayArea;
  BEGIN D := Viewers.root; Texts.WriteString(W, "System.ShowDisplays"); EndLine;
    WHILE D # NIL DO Texts.WriteString(W, " display "); Texts.WriteInt(W, D.id, 3);
      Texts.WriteString(W, " "); Texts.WriteString(W, D.name);
      IF D = Viewers.CurDisplay THEN Texts.WriteString(W, "      (current display)") END ;
      EndLine; D := D.next(Viewers.DisplayArea)
     END
  END ShowDisplays;

  (* ------------- Toolbox for module management ---------------*)

  PROCEDURE Select(VAR S: Texts.Scanner; on, this, clients, imports: BOOLEAN; handle: Handler);  (*modules*)
    VAR T: Texts.Text;
      beg, end, time: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenScanner(S, T, beg); Texts.Scan(S);
        IF (S.class = Texts.Name) OR (S.class = Texts.String) THEN
          Modules.Select(S.s, on, this, clients, imports); handle(S.s); Texts.Scan(S)
        END
      END
    ELSE
      WHILE (S.class = Texts.Name) OR (S.class = Texts.String) DO
        Modules.Select(S.s, on, this, clients, imports); handle(S.s); Texts.Scan(S)
      END
    END
  END Select;

  PROCEDURE WriteName(name: ARRAY OF CHAR);  (*write the name of a module*)
  BEGIN Texts.Write(W, " "); Texts.WriteString(W, name)
  END WriteName;

  PROCEDURE WriteSelection;  (*write the names of modules previously selected by Select*)
    VAR mod: Modules.Module;
  BEGIN mod := Modules.root;
    WHILE mod # NIL DO
      IF (mod.name[0] # 0X) & mod.selected THEN WriteName(mod.name) END ;
      mod := mod.next
    END
  END WriteSelection;

  PROCEDURE WriteRef(src, dst: LONGINT; s: ARRAY OF CHAR; VAR continue: BOOLEAN): INTEGER;  (*write one reference*)
    VAR mod: Modules.Module; i: INTEGER;
  BEGIN i := 0;
    IF (dst > 0) & (dst < Modules.AllocPtr) THEN mod := Modules.root;
      WHILE (mod # NIL) & ~((mod.name[0] # 0X) & mod.selected & (mod.data <= dst) & (dst < mod.imp)) DO mod := mod.next END ;
      IF mod # NIL THEN i := 1;
        IF (M # mod) OR (pat # s) THEN M := mod; pat := s;
          IF ref = Modules.dyntypes THEN Texts.WriteString(W, "  types of "); Texts.WriteString(W, mod.name);
            Texts.WriteString(W, " in use in dynamic objects reachable by ")
          ELSIF ref = Modules.dynptrs THEN Texts.WriteString(W, "  static module data of "); Texts.WriteString(W, mod.name);
            Texts.WriteString(W, " referenced by pointer variables in dynamic objects reachable by ")
          ELSIF ref = Modules.dynpvrs THEN Texts.WriteString(W, "  procedures of "); Texts.WriteString(W, mod.name);
            Texts.WriteString(W, " in use in dynamic objects reachable by ")
          ELSIF ref = Modules.statptrs THEN Texts.WriteString(W, "  static module data of "); Texts.WriteString(W, mod.name);
            Texts.WriteString(W, " referenced by global pointer variables of ")
          ELSIF ref = Modules.statpvrs THEN Texts.WriteString(W, "  procedures of "); Texts.WriteString(W, mod.name);
            Texts.WriteString(W, " in use in global procedure variables of ")
          END ;
          Texts.WriteString(W, s); Texts.WriteLn(W)
        END
      END
    END ;
    RETURN i
  END WriteRef;

  PROCEDURE WriteReferences;  (*write references from each unselected module to any of the selected modules*)
    VAR resTyp, resPtr, resPvr: INTEGER;
  BEGIN Oberon.ClearPar;  (*exclude viewers that are reachable only via Oberon.Par.vwr*)
    M := NIL; ref := Modules.dyntypes; Modules.FindDynamicReferences(WriteRef, NIL, NIL, resTyp, resPtr, resPvr, FALSE);
    M := NIL; ref := Modules.dynptrs; Modules.FindDynamicReferences(NIL, WriteRef, NIL, resTyp, resPtr, resPvr, FALSE);
    M := NIL; ref := Modules.dynpvrs; Modules.FindDynamicReferences(NIL, NIL, WriteRef, resTyp, resPtr, resPvr, FALSE);
    M := NIL; ref := Modules.statptrs; Modules.FindStaticReferences(WriteRef, NIL, resPtr, resPvr);
    M := NIL; ref := Modules.statpvrs; Modules.FindStaticReferences(NIL, WriteRef, resPtr, resPvr);
    Texts.Append(Oberon.Log, W.buf)
  END WriteReferences;

  PROCEDURE ShowRefs(name: ARRAY OF CHAR);
  BEGIN
    IF Modules.NofSelected > 0 THEN WriteReferences; Modules.Deselect END
  END ShowRefs;

  PROCEDURE ShowReferences*;  (*show references from all modules to any of the specified modules individually*)
    VAR S: Texts.Scanner;
  BEGIN Texts.WriteString(W, "System.ShowReferences"); EndLine;
    Modules.Deselect; Select(S, TRUE, TRUE, FALSE, FALSE, ShowRefs)
  END ShowReferences;

  PROCEDURE ShowGroupReferences*;  (*show references from all modules outside the group to the specified module group*)
    VAR S: Texts.Scanner;
  BEGIN Texts.WriteString(W, "System.ShowGroupReferences");
    Modules.Deselect; Select(S, TRUE, TRUE, FALSE, FALSE, WriteName); EndLine;
    IF Modules.NofSelected > 0 THEN WriteReferences; Modules.Deselect END
  END ShowGroupReferences;

  PROCEDURE Show(this, clients, imports: BOOLEAN);
    VAR S: Texts.Scanner;
  BEGIN Modules.Deselect; Select(S, TRUE, this, clients, imports, WriteName); EndLine;
    IF Modules.NofSelected > 0 THEN Texts.Write(W, " "); WriteSelection; EndLine; Modules.Deselect END
  END Show;

  PROCEDURE ShowLoaded*;  (*show the specified modules if they are loaded*)
  BEGIN Texts.WriteString(W, "System.ShowLoaded"); Show(TRUE, FALSE, FALSE)
  END ShowLoaded;

  PROCEDURE ShowImports*;  (*show the specified modules and all their direct and indirect imports*)
  BEGIN Texts.WriteString(W, "System.ShowImports"); Show(TRUE, FALSE, TRUE)
  END ShowImports;

  PROCEDURE ShowClients*;  (*show the specified modules and all their direct and indirect clients*)
  BEGIN Texts.WriteString(W, "System.ShowClients"); Show(TRUE, TRUE, FALSE)
  END ShowClients;

  PROCEDURE WriteClient(mod, imp: Modules.Module; VAR continue: BOOLEAN): INTEGER;
  BEGIN (*mod imports imp*)
    IF M = imp THEN Texts.Write(W, " ")
    ELSE M := imp; EndLine; Texts.WriteString(W, "  "); Texts.WriteString(W, imp.name); Texts.WriteString(W, " imported by ")
    END ;
    Texts.WriteString(W, mod.name); RETURN 1
  END WriteClient;

  PROCEDURE FreeModules(this, clients, imports: BOOLEAN);
    VAR S: Texts.Scanner; hide: BOOLEAN; res: INTEGER;
  BEGIN Modules.Deselect; Select(S, TRUE, this, clients, imports, WriteName); EndLine;
    hide := (S.class = Texts.Char) & (S.c = "/") & (S.nextCh = "f");  (*force option*)
    Modules.Select("System", FALSE, TRUE, FALSE, TRUE);  (*deselect module "System" and its imports*)
    IF Modules.NofSelected > 0 THEN Texts.Write(W, " "); WriteSelection; Modules.FreeSelection(hide);
      IF Modules.res = Modules.noref THEN Texts.WriteString(W, " unloading"); EndLine
      ELSE
        IF hide & (Modules.res > Modules.clients) THEN Texts.WriteString(W, " removing from module list")
        ELSE Texts.WriteString(W, " unloading failed, try /f option");
          IF Modules.res = Modules.clients THEN M := NIL; Modules.FindClients(WriteClient, res) END
        END ;
        EndLine; WriteReferences
      END ;
      Modules.Deselect; Oberon.Collect(0)
    END
  END FreeModules;

  PROCEDURE Free*;  (*free the specified modules as a group; if refs exist and the /f option is specified, hide the modules*)
  BEGIN Texts.WriteString(W, "System.Free"); FreeModules(TRUE, FALSE, FALSE)
  END Free;

  PROCEDURE FreeImports*;  (*free the specified modules and all their direct and indirect imports as a group*)
  BEGIN Texts.WriteString(W, "System.FreeImports"); FreeModules(TRUE, FALSE, TRUE)
  END FreeImports;

  PROCEDURE FreeClients*;  (*free the specified modules and all their direct and indirect clients as a group*)
  BEGIN Texts.WriteString(W, "System.FreeClients"); FreeModules(TRUE, TRUE, FALSE)
  END FreeClients;

  PROCEDURE FreeFonts*;
  BEGIN Texts.WriteString(W, "System.FreeFonts"); Fonts.Free; EndLine
  END FreeFonts;

  (* ------------- Toolbox of file system ---------------*)

  PROCEDURE List(name: FileDir.FileName; adr: LONGINT; VAR cont: BOOLEAN);
    VAR i0, i, j0, j, length, date: INTEGER;
  BEGIN i := 0;
    WHILE (pat[i] > "*") & (pat[i] = name[i]) DO INC(i) END ;
    IF (pat[i] = 0X) & (name[i] = 0X) THEN i0 := i; j0 := i
    ELSIF pat[i] = "*" THEN
      i0 := i; j0 := i+1;
      WHILE name[i0] # 0X DO
        i := i0; j := j0;
        WHILE (name[i] # 0X) & (name[i] = pat[j]) DO INC(i); INC(j) END ;
        IF pat[j] = 0X THEN
          IF name[i] = 0X THEN (*match*) j0 := j ELSE INC(i0) END
        ELSIF pat[j] = "*" THEN i0 := i; j0 := j+1
        ELSE INC(i0)
        END
      END
    END ;
    IF (name[i0] = 0X) & (pat[j0] = 0X) THEN (*found*)
      Texts.WriteString(W, name);
      IF pat[j0+1] = "!" THEN (*option*)
        FileDir.Attributes(adr, length, date);
        Texts.Write(W, TAB); Texts.WriteClock(W, date); Texts.WriteInt(W, length, 8); Texts.WriteHex(W, adr)
      END ;
      Texts.WriteLn(W)
    END
  END List;

  PROCEDURE Directory*;
    VAR X, Y, i: INTEGER; ch: CHAR;
      R: Texts.Reader;
      T, t: Texts.Text;
      V: Viewers.Viewer;
      beg, end, time: LONGINT;
      pre: ARRAY 32 OF CHAR;
  BEGIN Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos); Texts.Read(R, ch);
    WHILE ch = " " DO Texts.Read(R, ch) END ; (*spaces*)
    IF (ch = "^") OR (ch = CR) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenReader(R, T, beg); Texts.Read(R, ch);
        WHILE ch <= " " DO Texts.Read(R, ch) END
      END
    END ;
    i := 0;
    WHILE ch > " " DO (*pattern*)
      IF ch = "!" THEN pat[i] := 0X; INC(i) END ; (*directory option*)
      pat[i] := ch; INC(i);
      Texts.Read(R, ch)
    END ;
    WHILE i < LEN(pat) DO pat[i] := 0X; INC(i) END ;
    i := 0;
    WHILE pat[i] > "*" DO pre[i] := pat[i]; INC(i) END ; (*prefix*)
    WHILE i < LEN(pre) DO pre[i] := 0X; INC(i) END ;
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y); t := TextFrames.Text("");
    V := MenuViewers.New(
      TextFrames.NewMenu("System.Directory", StandardMenu),
      TextFrames.NewText(t, 0), TextFrames.menuH, X, Y);
    FileDir.Enumerate(pre, List); Texts.Append(t, W.buf)
  END Directory;

  PROCEDURE CopyFiles*;
    VAR f, g: Files.File; Rf, Rg: Files.Rider; ch: CHAR;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.CopyFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.c = ">") THEN Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
            Texts.WriteString(W, " copying"); Texts.Append(Oberon.Log, W.buf);
            f := Files.Old(name);
            IF f # NIL THEN g := Files.New(S.s);
              Files.Set(Rf, f, 0); Files.Set(Rg, g, 0); Files.Read(Rf, ch);
              WHILE ~Rf.eof DO Files.Write(Rg, ch); Files.Read(Rf, ch) END;
              Files.Register(g)
            ELSE Texts.WriteString(W, " failed")
            END ;
            EndLine
          END
        END
      END ;
      Texts.Scan(S)
    END
  END CopyFiles;

  PROCEDURE RenameFiles*;
    VAR res: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.RenameFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.c = ">") THEN Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
            Texts.WriteString(W, " renaming"); Files.Rename(name, S.s, res);
            IF res > 1 THEN Texts.WriteString(W, " failed") END;
            EndLine
          END
        END
      END ;
      Texts.Scan(S)
    END
  END RenameFiles;

  PROCEDURE DeleteFiles*;
    VAR res: INTEGER; S: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.DeleteFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s); Texts.WriteString(W, " deleting");
      Files.Delete(S.s, res);
      IF res # 0 THEN Texts.WriteString(W, " failed") END;
      EndLine; Texts.Scan(S)
    END
  END DeleteFiles;

  (* ------------- Toolbox for system inspection ---------------*)

  PROCEDURE Watch*;
  BEGIN Texts.WriteString(W, "System.Watch"); Texts.WriteLn(W);
    Texts.WriteString(W, "  Modules space (bytes)"); Texts.WriteInt(W, Modules.AllocPtr, 8);
    Texts.WriteInt(W, Modules.AllocPtr * 100 DIV Kernel.heapOrg, 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Heap speace"); Texts.WriteInt(W, Kernel.allocated, 8);
    Texts.WriteInt(W, Kernel.allocated * 100 DIV (Kernel.heapLim - Kernel.heapOrg), 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Disk sectors "); Texts.WriteInt(W, Disk.NofSectors, 4);
    Texts.WriteInt(W, Disk.NofSectors * 100 DIV 10000H, 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Tasks"); Texts.WriteInt(W, Oberon.NofTasks, 4); EndLine
  END Watch;

  PROCEDURE ShowModules*;
    VAR T: Texts.Text;
      V: Viewers.Viewer;
      M: Modules.Module;
      X, Y: INTEGER;
  BEGIN T := TextFrames.Text("");
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu("System.ShowModules", StandardMenu),
        TextFrames.NewText(T, 0), TextFrames.menuH, X, Y);
    Modules.Collect;
    M := Modules.root;
    WHILE M # NIL DO
      IF M.name[0] # 0X THEN
        Texts.WriteString(W, M.name); Texts.WriteInt(W, M.num, 4); Texts.Write(W, TAB);
        Texts.WriteHex(W, ORD(M)); Texts.WriteHex(W, M.code); Texts.WriteInt(W, M.refcnt, 4)
      ELSE Texts.WriteString(W, "---")
      END ;
      Texts.WriteLn(W); M := M.next
    END;
    Texts.Append(T, W.buf)
  END ShowModules;

  PROCEDURE ShowCommands*;
    VAR M: Modules.Module;
      comadr: LONGINT; ch: CHAR;
      T: Texts.Text;
      S: Texts.Scanner;
      V: Viewers.Viewer;
      X, Y: INTEGER;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      Modules.Load(S.s, M);
      IF M # NIL THEN
        Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y); T := TextFrames.Text("");
        V := MenuViewers.New(TextFrames.NewMenu("System.Commands", StandardMenu),
            TextFrames.NewText(T, 0), TextFrames.menuH, X, Y);
        comadr := M.cmd; SYSTEM.GET(comadr, ch); INC(comadr);
        WHILE ch # 0X DO
          Texts.WriteString(W, S.s); Texts.Write(W, ".");
          REPEAT Texts.Write(W, ch); SYSTEM.GET(comadr, ch); INC(comadr)
          UNTIL ch = 0X;
          WHILE comadr MOD 4 # 0 DO INC(comadr) END ;  (*commands are aligned to multiple of 4 bytes*)
          Texts.WriteLn(W); INC(comadr, 4); SYSTEM.GET(comadr, ch); INC(comadr)
        END ;
        Texts.Append(T, W.buf)
      END
    END
  END ShowCommands;

  PROCEDURE ShowFonts*;
    VAR fnt: Fonts.Font;
  BEGIN Texts.WriteString(W, "System.ShowFonts"); Texts.WriteLn(W); fnt := Fonts.root;
    WHILE fnt # NIL DO
      Texts.Write(W, TAB); Texts.WriteString(W, fnt.name); Texts.WriteLn(W); fnt := fnt.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END ShowFonts;

  PROCEDURE Run(name: ARRAY OF CHAR);  (*execute multiple commands separated by ~ in the specified batch file*)
    VAR F: Files.File; T: Texts.Text;
      menu, main: Display.Frame;
      V: Viewers.Viewer; X, Y: INTEGER;
  BEGIN F := Files.Old(name);
    IF F # NIL THEN T := TextFrames.Text(name);
      Oberon.AllocateSystemViewer(0, X, Y);
      menu := TextFrames.NewMenu(name, StandardMenu);
      main := TextFrames.NewText(T, 0);
      V := MenuViewers.New(menu, main, TextFrames.menuH, X, Y);
      Oberon.Run(main, T, 0)
    END
  END Run;

  PROCEDURE Batch*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s); Texts.WriteString(W, " executing"); EndLine;
      Run(S.s); Texts.Scan(S)
    END
  END Batch;

  PROCEDURE Trap(VAR a: INTEGER; b, c, d: INTEGER);
    VAR u, v, w: INTEGER; mod: Modules.Module;
  BEGIN u := SYSTEM.REG(LNK);  (*return address deposited in register LNK by the trap (=BLR TR) instruction*)
    SYSTEM.GET(u - 4, v);  (*trap instruction, contains code position and trap number as generated in ORG.Trap*)
    w := v DIV 10H MOD 10H;  (*trap number*)
    IF w = 0 THEN Kernel.New(a, b, c, d)
    ELSE (*trap*)
      IF defer THEN (*defer trap handling*) last := u; Oberon.Install(T)
      ELSE defer := TRUE;
        Texts.WriteLn(W); Texts.WriteString(W, "  pos ");
        Texts.WriteInt(W, v DIV 100H MOD 10000H, 4);  (*code position*)
        Texts.WriteString(W, "  TRAP"); Texts.WriteInt(W, w, 4); mod := Modules.root;
        WHILE (mod # NIL) & ((u < mod.code) OR (u >= mod.imp)) DO mod := mod.next END ;
        IF mod # NIL THEN Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
        Texts.WriteString(W, " at"); Texts.WriteHex(W, u);
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
        defer := FALSE
      END ;
      Oberon.Collect(0); Oberon.Reset
    END
  END Trap;

  PROCEDURE Abort;
    VAR u: INTEGER; mod: Modules.Module;
  BEGIN u := SYSTEM.REG(LNK);  (*return address deposited in register LNK by the abort (=BL 0) instruction*)
    IF defer THEN (*defer abort handling*) last := u; Oberon.Install(T)
    ELSE defer := TRUE;
      Texts.WriteLn(W); Texts.WriteString(W, "  ABORT  "); mod := Modules.root;
      WHILE (mod # NIL) & ((u < mod.code) OR (u >= mod.imp)) DO mod := mod.next END ;
      IF mod # NIL THEN Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
      Texts.WriteString(W, " at"); Texts.WriteHex(W, u);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      defer := FALSE
    END ;
    Oberon.Collect(0); Oberon.Reset
  END Abort;

  PROCEDURE Deferred;  (*handle trap/abort as soon as the garbage collector has freed up enough heap space*)
    VAR v, w, pos: INTEGER; mod: Modules.Module;
  BEGIN
    IF Kernel.allocated < Kernel.heapLim - Kernel.heapOrg - 10000H THEN Oberon.Remove(T);
      SYSTEM.GET(last - 4, v); (*trap instruction*) pos := v DIV 100H MOD 10000H; (*code position*)
      Texts.WriteLn(W);
      IF pos # 0 THEN w := v DIV 10H MOD 10H; (*trap number*)
        Texts.WriteString(W, "  pos "); Texts.WriteInt(W, pos, 4);
        Texts.WriteString(W, "  RECURSIVE TRAP"); Texts.WriteInt(W, w, 4)
      ELSE Texts.WriteString(W, "  RECURSIVE ABORT  ")
      END ;
      mod := Modules.root;
      WHILE (mod # NIL) & ((last < mod.code) OR (last >= mod.imp)) DO mod := mod.next END ;
      IF mod # NIL THEN Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name) END ;
      Texts.WriteString(W, " at"); Texts.WriteHex(W, last);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); defer := FALSE
    END
  END Deferred;

BEGIN Texts.OpenWriter(W); defer := FALSE; T := Oberon.NewTask(Deferred, TaskPeriod);
  Oberon.OpenLog(TextFrames.Text("")); CreateDisplay("Oberon");
  Kernel.Install(SYSTEM.ADR(Trap), Kernel.TrapAdr); Kernel.Install(SYSTEM.ADR(Abort), 0); Run(SystemBatch)
END System.
