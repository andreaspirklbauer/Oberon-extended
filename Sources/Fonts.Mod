MODULE Fonts; (*JG 18.11.90; PDR 8.6.12; NW 18.1.2019 / AP 16.9.20 Extended Oberon*)
  IMPORT SYSTEM, Files;
  CONST FontFileId = 0DBH; RasterBase = 512;

  TYPE Raster* = POINTER TO RasterDesc;
    RasterDesc* = ARRAY OF BYTE;

    Font* = POINTER TO FontDesc;
    FontDesc* = RECORD
      name*: ARRAY 32 OF CHAR;
      height*, minX*, maxX*, minY*, maxY*, base: INTEGER;
      next*: Font;
      raster: Raster
    END ;

    RunRec = RECORD beg, end: BYTE END ;
    BoxRec = RECORD dx, x, y, w, h: BYTE END ;

  (* raster sizes: Syntax8 1367, Syntax10 1628, Syntax12 1688, Syntax14 1843, Syntax14b 1983,
      Syntax16 2271, Syntax20 3034, Syntac24 4274, Syntax24b 4302  *)

  VAR Default*, root*: Font;

  PROCEDURE Base(r: Raster): INTEGER;
  BEGIN RETURN SYSTEM.ADR(r[0])
  END Base;

  PROCEDURE Put(r: Raster; i, x: INTEGER);
  BEGIN r[i] := x MOD 100H;
    r[i+1] := x DIV 100H MOD 100H;
    r[i+2] := x DIV 10000H MOD 100H;
    r[i+3] := x DIV 1000000H MOD 100H
  END Put;

  PROCEDURE Get(r: Raster; i: INTEGER; VAR x: INTEGER);
  BEGIN x := ((r[i+3] * 100H + r[i+2]) * 100H + r[i+1]) * 100H + r[i]
  END Get;

  PROCEDURE GetPat*(fnt: Font; ch: CHAR; VAR dx, x, y, w, h, patadr: INTEGER);
    VAR pa: INTEGER; yb: BYTE;
  BEGIN Get(fnt.raster, (ORD(ch) MOD 80H)*4, pa); patadr := fnt.base + pa;
    dx := fnt.raster[pa-3]; x := fnt.raster[pa-2]; yb := fnt.raster[pa-1]; w := fnt.raster[pa]; h := fnt.raster[pa+1];
    IF yb < 128 THEN y := yb ELSE y := yb - 256 END
  END GetPat;

  PROCEDURE Load*(name: ARRAY OF CHAR): Font;
    VAR F: Font;
      f: Files.File; R: Files.Rider;
      NofRuns, NofBoxes, height, minX, maxX, minY, maxY, b: BYTE;
      NofBytes, i, j, k, m, n: INTEGER;
      run: ARRAY 16 OF RunRec;
      box: ARRAY 512 OF BoxRec;

    PROCEDURE RdInt16(VAR R: Files.Rider; VAR b0: BYTE);
      VAR b1: BYTE;
    BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1)
    END RdInt16;

  BEGIN F := root;
    WHILE (F # NIL) & (name # F.name) DO F := F.next END ;
    IF F = NIL THEN
      f := Files.Old(name);
      IF f # NIL THEN
        Files.Set(R, f, 0); Files.ReadByte(R, b);
        IF b = FontFileId THEN
          Files.ReadByte(R, b);  (*abstraction*)
          Files.ReadByte(R, b);  (*family*)
          Files.ReadByte(R, b);  (*variant*)
          RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX); RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
          NofBoxes := 0; k := 0;
          WHILE k # NofRuns DO  (*read runs*)
            RdInt16(R, run[k].beg); RdInt16(R, run[k].end);
            NofBoxes := NofBoxes + run[k].end - run[k].beg;
            INC(k)
          END ;
          NofBytes := RasterBase + 5; j := 0;
          WHILE j # NofBoxes DO  (*read boxes*)
            RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
            RdInt16(R, box[j].w); RdInt16(R, box[j].h);
            NofBytes := NofBytes + 5 + (box[j].w + 7) DIV 8 * box[j].h;
            INC(j)
          END ;
          NEW(F); NEW(F.raster, NofBytes);
          F.name := name; F.base := Base(F.raster);
          F.height := height; F.minX := minX; F.maxX := maxX; F.maxY := maxY;
          IF minY >= 80H THEN F.minY := minY - 100H ELSE F.minY := minY END ;
          FOR i := RasterBase TO RasterBase+4 DO F.raster[i] := 0 END ;  (*null pattern for characters not in a run*)
          i := RasterBase + 5; j := 0; k := 0; m := 0;
          WHILE k < NofRuns DO
            WHILE (m < run[k].beg) & (m < 128) DO Put(F.raster, m*4, RasterBase + 3); INC(m) END ;
            WHILE (m < run[k].end) & (m < 128) DO Put(F.raster, m*4, i + 3);
              F.raster[i] := box[j].dx; F.raster[i+1] := box[j].x; F.raster[i+2] := box[j].y;
              F.raster[i+3] := box[j].w; F.raster[i+4] := box[j].h; INC(i, 5);
              n := (box[j].w + 7) DIV 8 * box[j].h;  (*pattern length*)
              WHILE n # 0 DO DEC(n); Files.ReadByte(R, b); F.raster[i] := b; INC(i) END ;
              INC(j); INC(m)
            END ;
            INC(k)
          END ;
          WHILE m < 128 DO Put(F.raster, m*4, RasterBase + 3); INC(m) END ;
          F.next := root; root := F
        ELSE (*bad file id*) F := Default
        END
      ELSE (*font file not available*) F := Default
      END
    END ;
    RETURN F
  END Load;

  PROCEDURE This*(name: ARRAY OF CHAR): Font;  (*for backward compatibility*)
  BEGIN RETURN Load(name)
  END This;

  PROCEDURE Free*;  (*remove all but first two from font list*)
  BEGIN IF root.next # NIL THEN root.next.next := NIL END
  END Free;

BEGIN root := NIL; Default := Load("Oberon10.Scn.Fnt")
END Fonts.
