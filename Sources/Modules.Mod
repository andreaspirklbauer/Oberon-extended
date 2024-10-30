MODULE Modules;  (*Link and load on RISC; NW 20.10.2013 / 8.1.2019 / AP 1.5.23 Extended Oberon*)
  IMPORT SYSTEM, Kernel, Files;
  CONST versionkey = 1X; TR = 13; LNK = 15; DescSize = 96; MnLength = 32;
    noerr* = 0; nofile* = 1; badversion* = 2; badkey* = 3; badfile* = 4;
    nospace* = 5; nocmd* = 6; badcmd* = 7; nomod* = 8; badfin* = 9;
    noref* = 0; clients* = 10; dyntypes* = 11; dynptrs* = 12; dynpvrs* = 13; statptrs* = 14; statpvrs* = 15;
    U = 20000000H; V = 10000000H; B = 100000H;  (*modifier bits*)
    MOV = 40000000H; IOR = 40060000H; BCT = 0E7000000H; BLT = 0F7000000H; F2 = -2;  (*instructions*)
    C4 = 10H; C6 = 40H; C8 = 100H; C10 = 400H; C12 = 1000H; C14 = 4000H; C16 = 10000H; C18 = 40000H;
    C20 = 100000H; C22 = 400000H; C24 = 1000000H; C26 = 4000000H; C28 = 10000000H; C30 = 40000000H;

  TYPE Module* = POINTER TO ModDesc;
    Command* = PROCEDURE;
    ModuleName* = ARRAY MnLength OF CHAR;

    ModDesc* = RECORD
      name*: ModuleName;
      next*: Module;
      key*, num*, size*, refcnt*: INTEGER;
      var*, str*, tdx*, prg*, imp*, cmd*, ent*, ptr*, pvr*: INTEGER;  (*addresses*)
      selected*, marked, hidden, sel: BOOLEAN;
      final: Command
    END ;

    ClientHandler* = PROCEDURE(mod, imp: Module; VAR continue: BOOLEAN): INTEGER;
    RefHandler* = PROCEDURE(src, dst: LONGINT; s: ARRAY OF CHAR; VAR continue: BOOLEAN): INTEGER;

  VAR root*, M: Module;
    AllocPtr*, res*, NofSelected*, NofHidden*, limit: INTEGER;
    importing*, imported*: ModuleName;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR i: INTEGER;
      filename: ModuleName;
  BEGIN i := 0;
    WHILE name[i] # 0X DO filename[i] := name[i]; INC(i) END ;
    filename[i] := "."; filename[i+1] := "r"; filename[i+2] := "s"; filename[i+3] := "c"; filename[i+4] := 0X;
    RETURN Files.Old(filename)
  END ThisFile;

  PROCEDURE error(n: INTEGER; name: ARRAY OF CHAR);
  BEGIN res := n; importing := name
  END error;

  PROCEDURE check(s: ARRAY OF CHAR; VAR slen: INTEGER);  (*slen includes trailing 0X*)
    VAR i: INTEGER; ch: CHAR;
  BEGIN ch := s[0]; res := 1; i := 0; slen := 0;
    IF (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") THEN
      REPEAT INC(i); ch := s[i]
      UNTIL ~((ch >= "0") & (ch <= "9") OR (ch >= "A") & (ch <= "Z")
        OR (ch >= "a") & (ch <= "z") OR (ch = ".")) OR (i >= MnLength);
      IF ch = 0X THEN res := 0; slen := i+1 END
    END
  END check;

  PROCEDURE Load*(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, load module.
      res = noerr: already present or loaded;
      res = nofile: file not available;
      res = badversion: bad file version;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space*)
    VAR mod, impmod: Module;
      i, n, key, impkey, mno, nofimps, size: INTEGER;
      p, u, v, w: INTEGER;  (*addresses*)
      ch: CHAR;
      body: Command;
      fixorgP, fixorgD, fixorgT, fixorgM: INTEGER;
      disp, adr, inst, pno, vno, dest, offset: INTEGER;
      name1, impname: ModuleName;
      F: Files.File; R: Files.Rider;
      import: ARRAY 64 OF Module;
  BEGIN mod := root; error(noerr, name); nofimps := 0;
    WHILE (mod # NIL) & (name # mod.name) DO mod := mod.next END ;
    IF mod = NIL THEN (*load*)
      check(name, n);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF ch = versionkey THEN
          Files.ReadString(R, impname);  (*imports*)
          WHILE (impname[0] # 0X) & (res = noerr) DO
            Files.ReadInt(R, impkey);
            Load(impname, impmod); import[nofimps] := impmod; importing := name1;
            IF res = noerr THEN
              IF impmod.key = impkey THEN INC(impmod.refcnt); INC(nofimps)
              ELSE error(badkey, name1); imported := impname
              END
            END ;
            Files.ReadString(R, impname)
          END
        ELSE error(badversion, name1)
        END
      ELSE error(nofile, name)
      END ;
      IF res = noerr THEN (*search for a hole in the list allocate and link*)
        INC(size, DescSize); mod := root;
        WHILE (mod # NIL) & ~((mod.name[0] = 0X) & (mod.size >= size)) DO mod := mod.next END ;
        IF mod = NIL THEN (*no large enough hole was found*)
          IF AllocPtr + size < limit THEN (*allocate*)
            p := AllocPtr; mod := SYSTEM.VAL(Module, p);
            AllocPtr := (p + size + 3) DIV 4 * 4; mod.size := AllocPtr - p;
            IF root = NIL THEN mod.num := 1 ELSE mod.num := root.num + 1 END ;
            mod.next := root; root := mod
          ELSE error(nospace, name1)
          END
        ELSE (*fill hole*) p := SYSTEM.VAL(INTEGER, mod)
        END
      END ;
      IF res = noerr THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; mod.key := key; mod.refcnt := 0; i := n;
        WHILE i < MnLength DO mod.name[i] := 0X; INC(i) END ;
        mod.selected := FALSE; mod.hidden := FALSE; mod.marked := FALSE; mod.sel := FALSE;
        mod.var := p; Files.ReadInt(R, n);
        WHILE n > 0 DO SYSTEM.PUT(p, 0); INC(p, 4); DEC(n, 4) END ;  (*variable space*)
        mod.str := p; Files.ReadInt(R, n);
        WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END ;  (*strings*)
        mod.tdx := p; Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;  (*type descriptors*)
        mod.prg := p; Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;  (*program code*)
        mod.imp := p; i := 0;
        WHILE i < nofimps DO SYSTEM.PUT(p, import[i]); INC(p, 4); INC(i) END ;  (*copy imports*)
        mod.cmd := p; Files.Read(R, ch);
        WHILE ch # 0X DO  (*commands*)
          REPEAT SYSTEM.PUT(p, ch); INC(p); Files.Read(R, ch) UNTIL ch = 0X;
          REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
          Files.ReadInt(R, n); SYSTEM.PUT(p, n); INC(p, 4); Files.Read(R, ch)
        END ;
        REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
        mod.ent := p; Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;  (*entries*)
        mod.ptr := p; Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.var + w); INC(p, 4); Files.ReadInt(R, w) END ;  (*pointer references*)
        SYSTEM.PUT(p, 0); INC(p, 4);
        mod.pvr := p; Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.var + w); INC(p, 4); Files.ReadInt(R, w) END ;  (*procedure variable references*)
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD);
        Files.ReadInt(R, fixorgT); Files.ReadInt(R, fixorgM);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Command, mod.prg + w);
        Files.ReadInt(R, w);
        IF w >= 0 THEN mod.final := SYSTEM.VAL(Command, mod.prg + w) ELSE mod.final := NIL END ;
        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res = noerr THEN (*fixup of BL*)
        adr := mod.prg + fixorgP*4;
        WHILE adr # mod.prg DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV C22 MOD C6;
          pno := inst DIV C14 MOD C8;
          disp := inst MOD C14;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.prg;
          offset := (dest - adr - 4) DIV 4;
          SYSTEM.PUT(adr, BLT + offset MOD C24);
          adr := adr - disp*4
        END ;
        (*fixup of LDR/STR/ADD*)
        adr := mod.prg + fixorgD*4;
        WHILE adr # mod.prg DO
          SYSTEM.GET(adr, inst);
          pno := inst DIV C26 MOD C4;
          mno := inst DIV C20 MOD C6;
          disp := inst MOD C12;
          IF mno = 0 THEN (*global*)
            offset := inst DIV C12 MOD C8 * C16;
            SYSTEM.GET(adr+4, inst);
            INC(offset, mod.var + inst MOD C16)
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(adr+4, inst); vno := inst MOD C8;
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV C8) THEN INC(offset, impmod.prg) ELSE INC(offset, impmod.var) END
          END ;
          SYSTEM.PUT(adr, MOV+U+B + pno*C24 + offset DIV C16);  (*mark as fixed up by setting the B bit*)
          IF inst DIV C30 = F2 THEN inst := inst DIV C20 * C20
          ELSE inst := IOR + inst DIV C24 MOD C4 * C24 + inst DIV C20 MOD C4 * C20
          END ;
          SYSTEM.PUT(adr+4, inst + offset MOD C16);
          adr := adr - disp*4
        END ;
        (*fixup of type descriptors*)
        adr := mod.tdx + fixorgT*4;
        WHILE adr # mod.tdx DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV C24 MOD C6;
          vno := inst DIV C12 MOD C12;
          disp := inst MOD C12;
          IF mno = 0 THEN (*global*) inst := mod.tdx + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.var + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        (*fixup of method tables*)
        adr := mod.tdx + fixorgM*4;
        WHILE adr # mod.tdx DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV C26 MOD C6;
          vno := inst DIV C10 MOD C16;
          disp := inst MOD C10;
          IF mno = 0 THEN (*global*) inst := mod.prg + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.prg + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        body   (*initialize module*)
      ELSIF res >= badkey THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END
    END ;
    newmod := mod
  END Load;

  PROCEDURE ThisCommand*(mod: Module; name: ARRAY OF CHAR): Command;
    (*return the command named 'name' from module 'mod'.
      res = noerr: command found;
      res = nocmd: command not found*)
    VAR k, adr, w: INTEGER; ch: CHAR;
      s: ARRAY 32 OF CHAR;
  BEGIN res := nocmd; w := 0;
    IF mod # NIL THEN
      adr := mod.cmd; SYSTEM.GET(adr, ch);
      WHILE (ch # 0X) & (res # noerr) DO k := 0; (*read command name*)
        REPEAT s[k] := ch; INC(k); INC(adr); SYSTEM.GET(adr, ch) UNTIL ch = 0X;
        s[k] := 0X;
        REPEAT INC(adr) UNTIL adr MOD 4 = 0;
        SYSTEM.GET(adr, k); INC(adr, 4);
        IF s = name THEN res := noerr; w := mod.prg + k ELSE SYSTEM.GET(adr, ch) END
      END
    END ;
    RETURN SYSTEM.VAL(Command, w)
  END ThisCommand;

  PROCEDURE Call*(name: ARRAY OF CHAR; VAR err: INTEGER);
    (*call the command named 'name' of the form M.P, where M is either a module name or
      a module number; if M is not loaded, load module hierarchy M* before calling P.
      res = noerr: module loaded, command found and executed;
      res = nofile: file not available;
      res = badversion: bad file version;
      res = badkey: key conflict;
      res = badfile: corrupted file;
      res = nospace: insufficient space;
      res = nocmd: command not found;
      res = badcmd: invalid command;
      res = nomod: module not found in module list;
      err = the value of res before the command is called (for recursion)*)
    VAR mod: Module; P: Command;
      i, j: INTEGER; ch: CHAR;
      Mname, Cname: ModuleName;
  BEGIN i := 0; ch := name[0];
    IF ("0" <= ch) & (ch <= "9") THEN (*module number*) j := 0;
      REPEAT j := 10*j + (ORD(ch) - 30H); INC(i); ch := name[i] UNTIL (ch < "0") OR (ch > "9");
      IF ch = "." THEN INC(i); mod := root;
        WHILE (mod # NIL) & (mod.name[0] # 0X) & (mod.num # j) DO mod := mod.next END ;
        IF (mod # NIL) & (mod.name[0] # 0X) THEN res := noerr; j := 0;
          REPEAT ch := mod.name[j]; Mname[j] := ch; INC(j) UNTIL ch = 0X
        ELSE res := nomod
        END
      ELSE res := badcmd
      END
    ELSIF ("A" <= ch) & (ch <= "Z") OR ("a" <= ch) & (ch <= "z") OR (ch = "*") THEN (*module name*)
      REPEAT Mname[i] := ch; INC(i); ch := name[i] UNTIL (ch = ".") OR (ch = 0X);
      IF ch = "." THEN Mname[i] := 0X; INC(i); Load(Mname, mod) ELSE res := badcmd END
    ELSE res := badcmd
    END ;
    IF res = noerr THEN
      j := 0; ch := name[i]; INC(i);
      WHILE ch # 0X DO Cname[j] := ch; INC(j); ch := name[i]; INC(i) END ;
      Cname[j] := 0X;
      P := ThisCommand(mod, Cname);
      IF res = noerr THEN P END
    END ;
    err := res
  END Call;

  (*--------------------------- selections ---------------------------*)

  PROCEDURE select(mod: Module; clients, imports: BOOLEAN);
    VAR imp, m: Module; p, q: INTEGER;
  BEGIN (*~mod.sel & mod.name[0] # 0X*) mod.sel := TRUE;
    IF clients THEN m := root;
      WHILE m # NIL DO
        IF (m.name[0] # 0X) & (m # mod) & ~m.sel THEN p := m.imp; q := m.cmd;
          WHILE p < q DO (*imports*) SYSTEM.GET(p, imp);
            IF imp = mod THEN select(m, clients, imports); p := q ELSE INC(p, 4) END
          END
        END ;
        m := m.next
      END
    END ;
    IF imports THEN p := mod.imp; q := mod.cmd;
      WHILE p < q DO (*imports*) SYSTEM.GET(p, imp); INC(p, 4);
        IF (imp.name[0] # 0X) & ~imp.sel THEN select(imp, clients, imports) END
      END
    END
  END select;

  PROCEDURE Select*(name: ARRAY OF CHAR; on, this, clients, imports: BOOLEAN);
    VAR mod, m: Module;
  BEGIN mod := root; m := NIL;
    WHILE mod # NIL DO mod.sel := FALSE;
      IF (mod.name[0] # 0X) & (mod.name = name) THEN m := mod END ;
      mod := mod.next
    END ;
    IF m # NIL THEN select(m, clients, imports); mod := root;
      WHILE mod # NIL DO
        IF mod.sel & ((mod # m) OR this) THEN
          IF on THEN
            IF ~mod.selected THEN mod.selected := TRUE; INC(NofSelected) END
          ELSIF mod.selected THEN mod.selected := FALSE; DEC(NofSelected)
          END
        END ;
        mod := mod.next
      END
    END
  END Select;

  PROCEDURE Deselect*; (*all modules*)
    VAR mod: Module;
  BEGIN mod := root; NofSelected := 0;
    WHILE mod # NIL DO mod.selected := FALSE; mod := mod.next END
  END Deselect;

  (*--------------------------- reference checking ---------------------------*)

  PROCEDURE FindClients*(client: ClientHandler; VAR res: INTEGER);
    VAR mod, imp, m: Module; p, q: INTEGER; continue: BOOLEAN;
  BEGIN res := noref; m := root; continue := client # NIL;
    WHILE continue & (m # NIL) DO
      IF (m.name[0] # 0X) & m.selected & (m.refcnt > 0) THEN mod := root;
        WHILE continue & (mod # NIL) DO
          IF (mod.name[0] # 0X) & ~mod.selected THEN p := mod.imp; q := mod.cmd;
            WHILE p < q DO (*imports*) SYSTEM.GET(p, imp);
              IF imp = m THEN INC(res, client(mod, imp, continue)); p := q ELSE INC(p, 4) END
            END
          END ;
          mod := mod.next
        END
      END ;
      m := m.next
    END
  END FindClients;

  PROCEDURE FindDynamicRefs*(typ, ptr, pvr: RefHandler; VAR resTyp, resPtr, resPvr: INTEGER; all: BOOLEAN);
    VAR mod: Module;
  BEGIN mod := root;
    WHILE mod # NIL DO
      IF (mod.name[0] # 0X) & ~mod.selected THEN
        Kernel.Mark(mod.ptr);
        IF ~all THEN Kernel.Scan(typ, ptr, pvr, mod.name, resTyp, resPtr, resPvr) END
      END ;
      mod := mod.next
    END ;
    IF all THEN Kernel.Scan(typ, ptr, pvr, "", resTyp, resPtr, resPvr) END
  END FindDynamicRefs;

  PROCEDURE FindStaticRefs*(ptr, pvr: RefHandler; VAR resPtr, resPvr: INTEGER);
    VAR mod: Module; pref, pvadr, r: LONGINT; continue: BOOLEAN;
  BEGIN resPtr := noref; resPvr := noref; mod := root; continue := (ptr # NIL) OR (pvr # NIL);
    WHILE continue & (mod # NIL) DO
      IF (mod.name[0] # 0X) & ~mod.selected THEN
        IF ptr # NIL THEN
          pref := mod.ptr; SYSTEM.GET(pref, pvadr);
          WHILE continue & (pvadr # 0) DO (*pointers*) SYSTEM.GET(pvadr, r);
            INC(resPtr, ptr(pvadr, r, mod.name, continue));
            INC(pref, 4); SYSTEM.GET(pref, pvadr)
          END
        END ;
        IF pvr # NIL THEN
          pref := mod.pvr; SYSTEM.GET(pref, pvadr);
          WHILE continue & (pvadr # 0) DO (*procedures*) SYSTEM.GET(pvadr, r);
            INC(resPvr, pvr(pvadr, r, mod.name, continue));
            INC(pref, 4); SYSTEM.GET(pref, pvadr)
          END
        END
      END ;
      mod := mod.next
    END
  END FindStaticRefs;

  PROCEDURE HandleClient(mod, imp: Module; VAR continue: BOOLEAN): INTEGER;
  BEGIN (*mod imports imp*) continue := FALSE; RETURN 1
  END HandleClient;

  PROCEDURE HandleRef(src, dst: LONGINT; s: ARRAY OF CHAR; VAR continue: BOOLEAN): INTEGER;
    VAR mod: Module; i: INTEGER;
  BEGIN i := 0;
    IF (dst > 0) & (dst < AllocPtr) THEN mod := root;
      WHILE (mod # NIL) & ~((mod.name[0] # 0X) & mod.selected & (mod.var <= dst) & (dst < mod.imp)) DO mod := mod.next END ;
      IF mod # NIL THEN (*src references mod*) i := 1; continue := FALSE END
    END ;
    RETURN i
  END HandleRef;

  PROCEDURE Check*(VAR res: INTEGER);
    (*check whether external client, type, pointer or procedure variable references to selected modules exist.
      res = noref: no client, type, pointer or procedure variable references;
      res = clients: clients exist;
      res = dyntypes: types in use in dynamically allocated objects;
      res = dynptrs: static module data referenced by pointer variables in dynamically allocated objects;
      res = dynpvrs: procedures in use in dynamically allocated objects;
      res = statptrs: static module data referenced by global pointer variables;
      res = statpvrs: procedures in use in global procedure variables*)
    VAR resTyp, resPtr, resPvr: INTEGER;
  BEGIN FindClients(HandleClient, res);
    IF res > noref THEN res := clients
    ELSE FindDynamicRefs(HandleRef, HandleRef, HandleRef, resTyp, resPtr, resPvr, TRUE);
      IF resTyp > noref THEN res := dyntypes
      ELSIF resPtr > noref THEN res := dynptrs
      ELSIF resPvr > noref THEN res := dynpvrs
      ELSE FindStaticRefs(HandleRef, HandleRef, resPtr, resPvr);
        IF resPtr > noerr THEN res := statptrs ELSIF resPvr > noerr THEN res := statpvrs END
      END
    END
  END Check;

  (*--------------------------- unloading ---------------------------*)

  PROCEDURE Final*(final: Command); (*set module finalization sequence*)
    VAR u, v, w: INTEGER; mod: Module;
  BEGIN u := SYSTEM.REG(LNK); mod := root;
    WHILE (mod # NIL) & ((u < mod.prg) OR (u >= mod.imp)) DO mod := mod.next END ; (*search for caller*)
    IF mod # NIL THEN v := SYSTEM.VAL(INTEGER, final);
      SYSTEM.GET(mod.ent, w); w := mod.prg + w; (*module initialization body*)
      IF (v >= mod.prg) & (v < w) & (u >= w) & (mod.final = NIL) THEN mod.final := final ELSE res := badfin END
    END
  END Final;

  PROCEDURE Unload(mod: Module); (*from memory*)
    VAR imp: Module; p, q: INTEGER;
  BEGIN (*mod.refcnt = 0 & mod.name[0] # 0X*)
    IF mod.final # NIL THEN mod.final END ;
    mod.name[0] := 0X; p := mod.imp; q := mod.cmd;
    WHILE p < q DO (*imports*) SYSTEM.GET(p, imp); DEC(imp.refcnt); INC(p, 4) END ;
    IF mod.hidden THEN mod.hidden := FALSE; DEC(NofHidden) END ;
    IF mod.selected THEN mod.selected := FALSE; DEC(NofSelected) END ;
    IF mod = root THEN (*increase size of available module space*)
      p := mod.size; mod := mod.next;
      WHILE (mod # NIL) & (mod.name[0] = 0X) DO INC(p, mod.size); mod := mod.next END ;
      AllocPtr := AllocPtr - p; root := mod
    END
  END Unload;

  PROCEDURE Hide(mod: Module); (*from module list*)
    VAR i: INTEGER;
  BEGIN (*~mod.hidden & mod.name[0] # 0X*) i := 0;
    WHILE mod.name[i] # 0X DO INC(i) END ;
    IF i = MnLength-1 THEN DEC(i) ELSE mod.name[i+1] := 0X END ;
    WHILE i > 0 DO DEC(i); mod.name[i+1] := mod.name[i] END ;
    mod.name[0] := "*"; mod.hidden := TRUE; INC(NofHidden)
  END Hide;

  PROCEDURE FreeSelection*(hide: BOOLEAN); (*unload or hide selected modules; res is set by Check*)
    VAR mod: Module;
  BEGIN res := noref;
    IF NofSelected > 0 THEN Check(res);
      IF res = noref THEN (*unload*)
        WHILE NofSelected > 0 DO mod := root;
          WHILE mod # NIL DO
            IF (mod.name[0] # 0X) & mod.selected & (mod.refcnt = 0) THEN Unload(mod) END ;
            mod := mod.next
          END
        END
      ELSIF (res > clients) & hide THEN (*hide*) mod := root;
        WHILE mod # NIL DO
          IF (mod.name[0] # 0X) & mod.selected & ~mod.hidden THEN Hide(mod) END ;
          mod := mod.next
        END
      END
    END
  END FreeSelection;

  PROCEDURE Free*(name: ARRAY OF CHAR; hide: BOOLEAN); (*unload or hide specified module; res is set by Check*)
    VAR mod: Module;
  BEGIN mod := root; NofSelected := 0;
    WHILE mod # NIL DO
      IF (mod.name[0] # 0X) & (mod.name = name) THEN mod.selected := TRUE; INC(NofSelected)
      ELSE mod.selected := FALSE
      END ;
      mod := mod.next
    END ;
    FreeSelection(hide)
  END Free;

  (*--------------------------- garbage collection ---------------------------*)

  PROCEDURE Collect*; (*no longer referenced hidden modules*)
    VAR mod, m, m1: Module; continue: BOOLEAN;
      p, q, k, res: INTEGER;
  BEGIN
    IF NofHidden > 0 THEN k := 0; NofSelected := 0; mod := root;
      WHILE mod # NIL DO mod.sel := mod.selected; mod.selected := FALSE; mod := mod.next END ; (*save selection*)
      WHILE k < NofHidden DO INC(k);
        mod := root; p := 0; NofSelected := k; continue := TRUE;
        WHILE mod # NIL DO (*set first selection of k modules among hidden modules*)
          IF (mod.name[0] # 0X) & mod.hidden THEN mod.selected := p < k; INC(p) END ;
          mod := mod.next
        END ;
        WHILE continue DO Check(res);
          IF res = noref THEN (*unload current selection of k modules and start over*)
            k := 0; continue := FALSE;
            WHILE NofSelected > 0 DO mod := root;
              WHILE mod # NIL DO
                IF (mod.name[0] # 0X) & mod.selected & (mod.refcnt = 0) THEN Unload(mod) END ;
                mod := mod.next
              END
            END
          ELSIF k < NofHidden THEN
            mod := root; q := 0; m1 := NIL;
            WHILE mod # NIL DO (*determine whether there is a next selection of k modules*)
              IF (mod.name[0] # 0X) & mod.hidden THEN
                IF mod.selected THEN m := mod; INC(q) (*number of selected modules at end of list*)
                ELSIF q > 0 THEN q := 0; m1 := m (*last selected module before last unselected group*)
                END
              END ;
              mod := mod.next
            END ;
            IF m1 # NIL THEN (*if there is a next selection of k modules*)
              mod := m1.next; p := 0; m1.selected := FALSE;
              WHILE mod # NIL DO (*set next selection of k modules*)
                IF (mod.name[0] # 0X) & mod.hidden THEN mod.selected := p <= q; INC(p) END ;
                mod := mod.next
              END
            ELSE continue := FALSE (*otherwise continue with selections of k+1 modules*)
            END
          ELSE continue := FALSE (*all combinations of k modules chosen from n hidden modules checked*)
          END
        END
      END ;
      NofSelected := 0; mod := root; 
      WHILE mod # NIL DO (*restore selection without re-selecting the just unloaded hidden modules*)
        IF mod.sel & (mod.name[0] # 0X) THEN mod.selected := TRUE; INC(NofSelected) ELSE mod.selected := FALSE END ;
        mod := mod.next
      END
    END
  END Collect;

  PROCEDURE Init*;
  BEGIN SYSTEM.LDREG(TR, Kernel.TrapAdr); Files.Init; SYSTEM.GET(16, AllocPtr); SYSTEM.GET(20, root);
    limit := Kernel.stackOrg - Kernel.stackSize; NofHidden := 0; Deselect
  END Init;

BEGIN Init; Load("Oberon", M);
  LED(res); REPEAT UNTIL FALSE  (*only if load fails*)
END Modules.
