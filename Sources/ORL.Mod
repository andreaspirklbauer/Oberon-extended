MODULE ORL;  (*Oberon boot linker/loader for RISC / AP 5.5.20 Extended Oberon*)
  IMPORT SYSTEM, Kernel, Disk, Files, Modules, Texts, Oberon;
  CONST versionkey = 1X; versionkey0 = 0X; DescSize = 92; MnLength = 32; BootSec = 2;
    noerr* = 0; nofile* = 1; badversion* = 2; badkey* = 3; badfile* = 4; nospace* = 5;
    TrapAdr = 4; DestAdr = 8; MemAdr = 12; AllocAdr = 16; RootAdr = 20; StackAdr = 24; FPrintAdr = 28; ModAdr = 32;
    U = 20000000H; V = 10000000H; B = 100000H;  (*modifier bits*)
    MOV = 40000000H; IOR = 40060000H;  (*F1 register instructions*)
    F2 = -2;  (*F2 memory instruction*)
    F3 = -1; BCT = 0E7000000H; BLT = 0F7000000H;  (*F3 branch instructions*)
    C4 = 10H; C6 = 40H; C8 = 100H; C10 = 400H; C12 = 1000H; C14 = 4000H; C16 = 10000H; C18 = 40000H;
    C20 = 100000H; C22 = 400000H; C24 = 1000000H; C26 = 4000000H; C28 = 10000000H; C30 = 40000000H;

  TYPE  (*copied from Modules for use as cross linker/loader*)
    Module* = POINTER TO ModDesc;
    Command* = PROCEDURE;
    ModuleName* = ARRAY MnLength OF CHAR;
    ModDesc* = RECORD
      name*: ModuleName;
      next*: Module;
      key*, num*, size*, refcnt*: INTEGER;
      data*, str*, tdx*, code*, imp*, cmd*, ent*, ptr*, pvr*: INTEGER;  (*addresses*)
      selected*, marked, hidden, sel: BOOLEAN
    END ;

  VAR root: Module;
    AllocPtr, Start, limit, res*: INTEGER;
    importing*, imported*: ModuleName;
    W: Texts.Writer;

  PROCEDURE MakeFileName(VAR FName: ARRAY OF CHAR; name, ext: ARRAY OF CHAR);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;  (*assume name suffix less than 4 characters*)
    WHILE (i < MnLength-5) & (name[i] > 0X) DO FName[i] := name[i]; INC(i) END ;
    REPEAT FName[i]:= ext[j]; INC(i); INC(j) UNTIL ext[j] = 0X;
    FName[i] := 0X
  END MakeFileName;

  PROCEDURE ThisFile(name: ARRAY OF CHAR): Files.File;
    VAR F: Files.File;
      filename: ModuleName;
  BEGIN MakeFileName(filename, name, ".rsc"); F := Files.Old(filename); RETURN F
  END ThisFile;

  PROCEDURE error(n: INTEGER; name: ARRAY OF CHAR);
  BEGIN res := n; importing := name
  END error;

  PROCEDURE Check(s: ARRAY OF CHAR);
    VAR i: INTEGER; ch: CHAR;
  BEGIN ch := s[0]; res := 1; i := 1;
    IF (ch >= "A") & (ch <= "Z") OR (ch >= "a") & (ch <= "z") THEN
      REPEAT ch := s[i]; INC(i)
      UNTIL ~((ch >= "0") & (ch <= "9") OR (ch >= "A") & (ch <= "Z")
        OR (ch >= "a") & (ch <= "z") OR (ch = ".")) OR (i = MnLength);
      IF (i < MnLength) & (ch = 0X) THEN res := 0 END
    END
  END Check;

  PROCEDURE LinkOne(name: ARRAY OF CHAR; VAR newmod: Module);
    (*search module in list; if not found, link module.
      res = noerr: already present or linked;
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
    IF mod = NIL THEN (*link*)
      Check(name);
      IF res = noerr THEN F := ThisFile(name) ELSE F := NIL END ;
      IF F # NIL THEN
        Files.Set(R, F, 0); Files.ReadString(R, name1); Files.ReadInt(R, key); Files.Read(R, ch);
        Files.ReadInt(R, size); importing := name1;
        IF (ch = versionkey) (*regular module*) OR (ch = versionkey0) (*standalone program*) THEN
          Files.ReadString(R, impname);   (*imports*)
          WHILE (impname[0] # 0X) & (res = noerr) DO
            Files.ReadInt(R, impkey);
            LinkOne(impname, impmod); import[nofimps] := impmod; importing := name1;
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
      IF res = noerr THEN
        INC(size, DescSize);
        IF AllocPtr + size < limit THEN (*allocate*)
          p := AllocPtr; mod := SYSTEM.VAL(Module, p);
          AllocPtr := (p + size + 3) DIV 4 * 4; mod.size := AllocPtr - p;
          IF root = NIL THEN mod.num := 1 ELSE mod.num := root.num + 1 END ;
          mod.next := root; root := mod
        ELSE error(nospace, name1)
        END
      END ;
      IF res = noerr THEN (*read file*)
        INC(p, DescSize); (*allocate descriptor*)
        mod.name := name; mod.key := key; mod.refcnt := 0;
        mod.selected := FALSE; mod.hidden := FALSE; mod.marked := FALSE; mod.sel := FALSE;
        mod.data := p;  (*data*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO SYSTEM.PUT(p, 0); INC(p, 4); DEC(n, 4) END ;  (*variable space*)
        mod.str := p;  (*strings*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.Read(R, ch); SYSTEM.PUT(p, ch); INC(p); DEC(n) END ;
        mod.tdx := p;  (*type descriptors*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n, 4) END ;
        mod.code := p;  (*program*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;  (*program code*)
        mod.imp := p;  (*copy imports*)
        i := 0;
        WHILE i < nofimps DO
          SYSTEM.PUT(p, import[i]); INC(p, 4); INC(i)
        END ;
        mod.cmd := p;  (*commands*) Files.Read(R, ch);
        WHILE ch # 0X DO
          REPEAT SYSTEM.PUT(p, ch); INC(p); Files.Read(R, ch) UNTIL ch = 0X;
          REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
          Files.ReadInt(R, n); SYSTEM.PUT(p, n); INC(p, 4); Files.Read(R, ch)
        END ;
        REPEAT SYSTEM.PUT(p, 0X); INC(p) UNTIL p MOD 4 = 0;
        mod.ent := p;  (*entries*)
        Files.ReadInt(R, n);
        WHILE n > 0 DO Files.ReadInt(R, w); SYSTEM.PUT(p, w); INC(p, 4); DEC(n) END ;
        mod.ptr := p;  (*pointer references*)
        Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w - Start); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        mod.pvr := p;  (*procedure variable references*)
        Files.ReadInt(R, w);
        WHILE w >= 0 DO SYSTEM.PUT(p, mod.data + w - Start); INC(p, 4); Files.ReadInt(R, w) END ;
        SYSTEM.PUT(p, 0); INC(p, 4);
        Files.ReadInt(R, fixorgP); Files.ReadInt(R, fixorgD);
        Files.ReadInt(R, fixorgT); Files.ReadInt(R, fixorgM);
        Files.ReadInt(R, w); body := SYSTEM.VAL(Command, mod.code + w - Start);
        Files.Read(R, ch);
        IF ch # "O" THEN mod := NIL; error(badfile, name) END
      END ;
      IF res = noerr THEN (*fixup of BL*)
        adr := mod.code + fixorgP*4;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV C22 MOD C6;
          pno := inst DIV C14 MOD C8;
          disp := inst MOD C14;
          SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
          SYSTEM.GET(impmod.ent + pno*4, dest); dest := dest + impmod.code;
          offset := (dest - adr - 4) DIV 4;
          SYSTEM.PUT(adr, (offset MOD C24) + BLT);
          adr := adr - disp*4
        END ;
        (*fixup of MOV/LDR/STR/ADD*)
        adr := mod.code + fixorgD*4;
        WHILE adr # mod.code DO
          SYSTEM.GET(adr, inst);
          pno := inst DIV C26 MOD C4;
          mno := inst DIV C20 MOD C6;
          disp := inst MOD C12;
          IF mno = 0 THEN (*global*)
            offset := inst DIV C12 MOD C8 * C16;
            SYSTEM.GET(adr+4, inst);
            INC(offset, mod.data + inst MOD C16)
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(adr+4, inst); vno := inst MOD C8;
            SYSTEM.GET(impmod.ent + vno*4, offset);
            IF ODD(inst DIV C8) THEN INC(offset, impmod.code) ELSE INC(offset, impmod.data) END
          END ;
          SYSTEM.PUT(adr, MOV+U+B + pno*C24 + (offset - Start) DIV C16);  (*mark as fixed up*)
          IF inst DIV C30 = F2 THEN inst := inst DIV C20 * C20
          ELSE inst := IOR + (inst DIV C24 MOD C4) * C24 + (inst DIV C20 MOD C4) * C20
          END ;
          SYSTEM.PUT(adr+4, inst + (offset - Start) MOD C16);
          adr := adr - disp*4
        END ;
        (*fixup of type descriptors*)
        adr := mod.tdx + fixorgT*4;
        WHILE adr # mod.tdx DO
          SYSTEM.GET(adr, inst);
          mno := inst DIV C24 MOD C6;
          vno := inst DIV C12 MOD C12;
          disp := inst MOD C12;
          IF mno = 0 THEN (*global*) inst := mod.tdx - Start + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.data - Start + offset
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
          IF mno = 0 THEN (*global*) inst := mod.code - Start + vno
          ELSE (*import*)
            SYSTEM.GET(mod.imp + (mno-1)*4, impmod);
            SYSTEM.GET(impmod.ent + vno*4, offset);
            inst := impmod.code - Start + offset
          END ;
          SYSTEM.PUT(adr, inst); adr := adr - disp*4
        END ;
        SYSTEM.PUT(Start, body) (*module initialization body*)
      ELSIF res >= badkey THEN importing := name;
        WHILE nofimps > 0 DO DEC(nofimps); DEC(import[nofimps].refcnt) END
      END
    END ;
    newmod := mod
  END LinkOne;

  PROCEDURE Link*;  (*link multiple object files together and create a single boot file M.bin from them*)
    VAR i, x: INTEGER;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
      M, p: Module;
      name: ModuleName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      root := NIL; Start := Modules.AllocPtr; AllocPtr :=  Start + ModAdr; i := Start;
      WHILE i < AllocPtr DO SYSTEM.PUT(i, 0); INC(i, 4) END ;
      REPEAT LinkOne(S.s, M); Texts.Scan(S) UNTIL (S.class # Texts.Name) OR (res # noerr);
      IF res = noerr THEN p := root; Texts.WriteString(W, "  linking");
        WHILE p # NIL DO (*fixup*) Texts.Write(W, " "); Texts.WriteString(W, p.name);
          M := p; p := p.next;
          IF p # NIL THEN M.next := SYSTEM.VAL(Module, SYSTEM.VAL(INTEGER, p) - Start) END ;
          M.data := M.data - Start;
          M.str := M.str - Start;
          M.tdx := M.tdx - Start;
          M.code := M.code - Start;
          i := M.imp;
          WHILE i < M.cmd DO SYSTEM.GET(i, x); SYSTEM.PUT(i, x - Start); INC(i, 4) END ;
          M.imp := M.imp - Start;
          M.cmd := M.cmd - Start;
          M.ent := M.ent - Start;
          M.ptr := M.ptr - Start;
          M.pvr := M.pvr - Start
        END ;
        SYSTEM.GET(Start, x);  (*address of initialization body of the top module relative to Start*)
        SYSTEM.PUT(Start, BCT + (x DIV 4) - 1);  (*branch instruction to the initialization body of the top module*)
        SYSTEM.PUT(Start + TrapAdr, 0);  (*trap handler, typically overwritten by the inner core*)
        SYSTEM.PUT(Start + DestAdr, 0);  (*destination address of the prelinked, executable binary*)
        SYSTEM.PUT(Start + MemAdr, Kernel.MemLim);  (*limit of available memory, typically overwritten by the boot loader*)
        SYSTEM.PUT(Start + AllocAdr, AllocPtr - Start);  (*address of the end of the module space loaded*)
        SYSTEM.PUT(Start + RootAdr, SYSTEM.VAL(INTEGER, root) - Start);  (*current root of the links of loaded modules*)
        SYSTEM.PUT(Start + StackAdr, Kernel.stackOrg);  (*current limit of the module area, typically overwritten by the boot loader*)
        SYSTEM.PUT(Start + FPrintAdr, 12345678H);  (*fingerprint*)
        MakeFileName(name, S.s, ".bin"); F := Files.New(name); Files.Set(R, F, 0); i := Start;
        WHILE i < AllocPtr DO SYSTEM.GET(i, x); Files.WriteInt(R, x); INC(i, 4) END ;
        Texts.WriteInt(W, AllocPtr - Start, 7); Files.Register(F)
      ELSE
        Texts.WriteString(W, "Link error:  "); Texts.WriteString(W, importing);
        IF res = nofile THEN Texts.WriteString(W, " module not found")
        ELSIF res = badversion THEN Texts.WriteString(W, " bad version")
        ELSIF res = badkey THEN Texts.WriteString(W, " imports ");
          Texts.WriteString(W, imported); Texts.WriteString(W, " with bad key")
        ELSIF res = badfile THEN Texts.WriteString(W, " corrupted obj file")
        ELSIF res = nospace THEN Texts.WriteString(W, " insufficient space")
        END
      END
    ELSE Texts.WriteString(W, "Usage: ORL.Link [module...] topmodule")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); root := NIL
  END Link;

  PROCEDURE Load*;  (*load prelinked boot file M.bin onto the boot area of the local disk*)
    VAR i, secno: LONGINT; b: BYTE;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
      buf: ARRAY Disk.SectorLength OF BYTE;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "  loading "); Texts.WriteString(W, S.s); F := Files.Old(S.s);
      IF F # NIL THEN Texts.WriteString(W, " onto boot area"); Texts.WriteInt(W, Files.Length(F), 7);
        secno := BootSec; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b);
        WHILE ~R.eof DO buf[i] := b; INC(i);
          IF i = Disk.SectorLength THEN Disk.PutSector(secno*29, buf); INC(secno); i := 0 END ;
          Files.ReadByte(R, b)
        END ;
        IF i > 0 THEN
          WHILE i < Disk.SectorLength DO buf[i] := 0; INC(i) END ;
          Disk.PutSector(secno*29, buf)
        END
      ELSE Texts.WriteString(W, " not found")
      END
    ELSE Texts.WriteString(W, "Usage: ORL.Load M.bin")
    END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Load;

  PROCEDURE RelocateLoaded*(start, dst: INTEGER);  (*relocate prelinked binary loaded at Mem[start] for execution at dst*)
    VAR p, i, j, x, y, im: INTEGER; M: Module;
  BEGIN SYSTEM.GET(start + DestAdr, x); SYSTEM.PUT(start + DestAdr, dst); SYSTEM.GET(start + RootAdr, p);
    p := p + start; dst := dst - x; start := start - x;
    WHILE p # 0 DO (*fixup*)
      M := SYSTEM.VAL(Module, p); p := SYSTEM.VAL(INTEGER, M.next);
      IF p # 0 THEN M.next := SYSTEM.VAL(Module, p + dst); p := p + start END ;
      i := M.tdx + start; j := M.code + start;
      WHILE i < j DO  (*type descriptors*)
        SYSTEM.GET(i, x); INC(i, 4); y := -x-1;  (*nofmth*)
        WHILE y > 0 DO SYSTEM.GET(i, x);
          IF x > 0 THEN (*not an imported hidden method*) SYSTEM.PUT(i, x + dst) END ;  (*methods*)
          INC(i, 4); DEC(y)
        END ;
        INC(i, 4);  (*size*)
        FOR y := 0 TO 2 DO SYSTEM.GET(i, x);
          IF x # -1 THEN SYSTEM.PUT(i, x + dst) END ;  (*base types*)
          INC(i, 4)
        END ;
        SYSTEM.GET(i, x);
        WHILE x # -1 DO SYSTEM.PUT(i, x + dst); INC(i, 4); SYSTEM.GET(i, x) END ;  (*pointer offsets*)
        INC(i, 4); SYSTEM.GET(i, x);
        WHILE x # -1 DO SYSTEM.PUT(i, x + dst); INC(i, 4); SYSTEM.GET(i, x) END ;  (*procedure variable offsets*)
        INC(i, 4)
      END ;
      j := M.imp + start;
      WHILE i < j DO SYSTEM.GET(i, x);  (*code*)
        IF (x DIV C28 * C28 = MOV+U) & (x DIV C20 MOD C4 = B DIV C20) THEN  (*marked as fixed up*)
          SYSTEM.GET(i+4, y); im := x MOD C16 * C16 + y MOD C16 + dst;
          SYSTEM.PUT(i, x DIV C16 * C16 + im DIV C16);
          SYSTEM.PUT(i+4, y DIV C16 * C16 + im MOD C16); INC(i, 4)
        END ;
        INC(i, 4)
      END ;
      j := M.cmd + start;
      WHILE i < j DO SYSTEM.GET(i, x); SYSTEM.PUT(i, x + dst); INC(i, 4) END ;  (*imports*)
      i := M.ptr + start; SYSTEM.GET(i, x);
      WHILE x # 0 DO SYSTEM.PUT(i, x + dst); INC(i, 4); SYSTEM.GET(i, x) END ;  (*pointer references*)
      i := M.pvr + start; SYSTEM.GET(i, x);
      WHILE x # 0 DO SYSTEM.PUT(i, x + dst); INC(i, 4); SYSTEM.GET(i, x) END ;  (*procedure variable references*)
      M.data := M.data + dst;
      M.str := M.str + dst;
      M.tdx := M.tdx + dst;
      M.code := M.code + dst;
      M.imp := M.imp + dst;
      M.cmd := M.cmd + dst;
      M.ent := M.ent + dst;
      M.ptr := M.ptr + dst;
      M.pvr := M.pvr + dst
    END
  END RelocateLoaded;

  PROCEDURE Relocate*;  (*relocate prelinked binary M.bin for execution at destadr and write result to output file R.bin*)
    VAR start, i, filelen, destadr, res: INTEGER; b: BYTE;
      name, name1: ARRAY 32 OF CHAR;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); res := -1;
    IF S.class = Texts.Name THEN name := S.s; Texts.Scan(S);
      IF S.class = Texts.Name THEN name1 := S.s; Texts.Scan(S);
        IF S.class = Texts.Int THEN res := 0; destadr := S.i;
          Texts.WriteString(W, "  relocating "); Texts.WriteString(W, name); Texts.WriteString(W, " => ");
          Texts.WriteString(W, name1); Texts.WriteString(W, " at address "); Texts.WriteInt(W, destadr, 7);
          IF destadr >= 0 THEN F := Files.Old(name);
            IF F # NIL THEN filelen := Files.Length(F);
              IF filelen > 0 THEN
                Files.Set(R, F, 0); Files.ReadByte(R, b); start := Modules.AllocPtr; i := start;
                WHILE ~R.eof DO SYSTEM.PUT(i, b); INC(i); Files.ReadByte(R, b) END ;
                RelocateLoaded(start, destadr);
                F := Files.New(name1); Files.Set(R, F, 0); i := start;
                WHILE i < start + filelen DO SYSTEM.GET(i, b); Files.WriteByte(R, b); INC(i) END ;
                Files.Register(F); Texts.WriteInt(W, Files.Length(F), 7)
              ELSE Texts.WriteString(W, "  input file empty")
              END
            ELSE Texts.WriteString(W, "  input file not found")
            END
          ELSE Texts.WriteString(W, "  destadr must be >= 0")
          END
        END
      END
    END ;
    IF res = -1 THEN Texts.WriteString(W, "Usage: ORL.Relocate M.bin R.bin destadr") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Relocate;

  PROCEDURE Execute*;  (*load and execute prelinked binary M.bin*)
    VAR start, i: INTEGER; b: BYTE;
      body: Modules.Command;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "  executing "); Texts.WriteString(W, S.s);
      F := Files.Old(S.s);
      IF F # NIL THEN
        IF Modules.AllocPtr + Files.Length(F) < limit THEN
          Files.Set(R, F, 0); Files.ReadByte(R, b); start := Modules.AllocPtr; i := start;
          WHILE ~R.eof DO SYSTEM.PUT(i, b); INC(i); Files.ReadByte(R, b) END ;
          RelocateLoaded(start, start); Texts.WriteString(W, " at address ");
          Texts.WriteInt(W, start, 7); Texts.WriteInt(W, i - start, 7);
          body := SYSTEM.VAL(Command, start); body  (*branch to initialization body of top module*)
        ELSE Texts.WriteString(W, " insufficient space")
        END
      ELSE Texts.WriteString(W, " failed")
      END ;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    ELSE Texts.WriteString(W, "Usage: ORL.Execute M.bin")
    END
  END Execute;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "OR Boot linker/loader  AP 5.5.20");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); limit := Kernel.stackOrg - Kernel.stackSize
END ORL.
