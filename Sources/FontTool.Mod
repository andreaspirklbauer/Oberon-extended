MODULE FontTool; (*JG 18.11.90; PDR 8.6.12; NW 22.2.2020 / AP 9.3.20 Extended Oberon*)
  IMPORT SYSTEM, Files, Input, Texts, Oberon;
  CONST FontFileId = 0DBX; TAB = Input.TAB;
  VAR W: Texts.Writer;

PROCEDURE Show*;
  TYPE RunRec = RECORD beg, end: INTEGER END;
    BoxRec = RECORD dx, x, y, w, h: INTEGER END;

  VAR height, minX, maxX, minY, maxY: INTEGER;
    NofBytes: INTEGER;
    NofRuns, NofBoxes: INTEGER;
    i, j, k, l, m, n: INTEGER;
    b: CHAR;
    S: Texts.Scanner;
    f: Files.File; R: Files.Rider;
    run: ARRAY 16 OF RunRec;
    box: ARRAY 256 OF BoxRec;
    T: ARRAY 256 OF INTEGER;
    raster: ARRAY 4400 OF CHAR;

  PROCEDURE WriteHex(n: INTEGER);
    VAR m: INTEGER;
  BEGIN Texts.Write(W, " "); m := n MOD 10H; n := n DIV 10H;
    IF n < 10 THEN Texts.Write(W, CHR(n+30H)) ELSE Texts.Write(W, CHR(n+37H)) END ;
    IF m < 10 THEN Texts.Write(W, CHR(m+30H)) ELSE Texts.Write(W, CHR(m+37H)) END
  END WriteHex;

  PROCEDURE RdInt16(VAR R: Files.Rider; VAR i: INTEGER);
    VAR b0, b1: CHAR;
  BEGIN Files.Read(R, b0); Files.Read(R, b1);
    IF b1 >= 80X THEN i := (ORD(b1) - 100H) * 100H + ORD(b0)
    ELSE i := ORD(b1) * 100H + ORD(b0)
    END
  END RdInt16;

BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
  IF S.class = Texts.Name THEN
    Texts.WriteString(W, S.s);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); f := Files.Old(S.s);
    IF f # NIL THEN
      Files.Set(R, f, 0); Files.Read(R, b);
      IF b = FontFileId THEN
        Files.Read(R, b); (*abstraction*)
        Files.Read(R, b); (*family*)
        Files.Read(R, b); (*variant*)
        RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX);
        RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
        Texts.WriteString(W, "height"); Texts.WriteInt(W, height, 4); Texts.WriteInt(W, minX, 4); Texts.WriteInt(W, maxX, 4);
        Texts.WriteInt(W, minY, 4); Texts.WriteInt(W, maxY, 4); Texts.WriteLn(W);
        Texts.WriteString(W, "Runs"); Texts.WriteLn(W);
        NofBoxes := 0; k := 0;
        WHILE k # NofRuns DO  (*read runs*)
          RdInt16(R, run[k].beg); Texts.WriteInt(W, run[k].beg, 4); 
        (* IF run[k].beg >= 128 THEN run[k].beg := 128 END ; *)
          RdInt16(R, run[k].end); Texts.WriteInt(W, run[k].end, 4);
        (* IF run[k].end >= 128 THEN run[k].end := 127 END ; *)
          NofBoxes := NofBoxes + run[k].end - run[k].beg;
          Texts.WriteLn(W); INC(k)
        END ;
        NofBytes := 5; j := 0;
        WHILE j # NofBoxes DO  (*read boxes*)
          RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
          RdInt16(R, box[j].w); RdInt16(R, box[j].h);
          NofBytes := NofBytes + 5 + (box[j].w + 7) DIV 8 * box[j].h;
          INC(j)
        END;
        NofBytes := NofBytes + (-NofBytes) MOD 4;
        Texts.WriteInt(W, NofRuns, 4); Texts.WriteInt(W, NofBoxes, 4); Texts.WriteInt(W, NofBytes, 6); Texts.WriteLn(W);
        raster[0] := 0X; raster[1] := 0X; raster[2] := 0X; raster[3] := 0X; raster[4] := 0X;
        (*null pattern for characters not in a run*)
        i := 5; j := 0; k := 0; m := 0;
        WHILE k < NofRuns DO
          WHILE m < run[k].beg DO T[m] := 0; INC(m) END;
          WHILE m < run[k].end DO
            T[m] := i;
            raster[i] := CHR(box[j].dx); raster[i+1] := CHR(box[j].x); raster[i+2] := CHR(box[j].y);
            raster[i+3] := CHR(box[j].w); raster[i+4] := CHR(box[j].h);
            n := (box[j].w + 7) DIV 8 * box[j].h; INC(i, 5);
            WHILE n # 0 DO DEC(n); Files.Read(R, raster[i]); INC(i) END ;
            INC(j); INC(m)
          END ;
          INC(k)
        END ;
        Texts.WriteString(W, "Raster"); Texts.WriteInt(W, i, 6); Texts.WriteLn(W);
        FOR i := 0 TO 127 DO  (*-------*)
          j := T[i];
          IF j # 0 THEN
            Texts.Write(W, CHR(i)); Texts.Write(W, " "); WriteHex(i);
            IF j >= 4400 THEN
              Texts.WriteString(W, "??"); Texts.WriteInt(W, i, 15); Texts.WriteInt(W, j, 15);
              Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
            END ;
            Texts.WriteInt(W, ORD(raster[j]), 4); Texts.WriteInt(W, ORD(raster[j+1]), 4);
            Texts.WriteInt(W, LSL(ASR(ORD(raster[j+2]), 24), 24), 4);
            Texts.WriteInt(W, ORD(raster[j+3]), 4); Texts.WriteInt(W, ORD(raster[j+4]), 4);
            n := (ORD(raster[j+3]) + 7) DIV 8 * ORD(raster[j+4]); INC(j, 5);  (*pattern len*)
            Texts.Write(W, TAB);
            WHILE n > 0 DO DEC(n); WriteHex(ORD(raster[j])); INC(j) END ;
            Texts.WriteLn(W)
          END
        END ;
        Texts.Append(Oberon.Log, W.buf)
      END
    END
  END
END Show;

BEGIN Texts.OpenWriter(W)
END FontTool.

FontTool.Show Oberon10.Scn.Fnt
