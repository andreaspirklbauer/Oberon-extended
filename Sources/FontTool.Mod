MODULE FontTool; (*JG 18.11.90; PDR 8.6.12; NW 22.2.2020 / AP 16.9.20 Extended Oberon*)
  IMPORT Files, Texts, Oberon;
  CONST FontFileId = 0DBH; LargeFontSize = 4920; TAB = 09X;

  TYPE RunRec = RECORD beg, end: INTEGER END ;
    BoxRec = RECORD dx, x, y, w, h: INTEGER END ;

  VAR W: Texts.Writer;

  PROCEDURE Show*;
    VAR S: Texts.Scanner;
      f: Files.File; R: Files.Rider;
      height, minX, maxX, minY, maxY: INTEGER;
      NofRuns, NofBoxes, NofBytes: INTEGER;
      i, j, k, m, n: INTEGER;
      b: BYTE;
      run: ARRAY 16 OF RunRec;
      box: ARRAY 256 OF BoxRec;
      T: ARRAY 256 OF INTEGER;
      raster: ARRAY LargeFontSize OF BYTE;

    PROCEDURE WriteHex(n: INTEGER);
      VAR m: INTEGER;
    BEGIN Texts.Write(W, " "); m := n MOD 10H; n := n DIV 10H;
      IF n < 10 THEN Texts.Write(W, CHR(n+30H)) ELSE Texts.Write(W, CHR(n+37H)) END ;
      IF m < 10 THEN Texts.Write(W, CHR(m+30H)) ELSE Texts.Write(W, CHR(m+37H)) END
    END WriteHex;

    PROCEDURE RdInt16(VAR R: Files.Rider; VAR i: INTEGER);
      VAR b0, b1: BYTE;
    BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1);
      IF b1 >= 80H THEN i := (b1 - 100H) * 100H + b0 ELSE i := b1 * 100H + b0 END
    END RdInt16;

  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, S.s);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); f := Files.Old(S.s);
      IF f # NIL THEN
        Files.Set(R, f, 0); Files.ReadByte(R, b);
        IF b = FontFileId THEN
          Files.ReadByte(R, b);  (*abstraction*)
          Files.ReadByte(R, b);  (*family*)
          Files.ReadByte(R, b);  (*variant*)
          RdInt16(R, height); RdInt16(R, minX); RdInt16(R, maxX); RdInt16(R, minY); RdInt16(R, maxY); RdInt16(R, NofRuns);
          Texts.WriteString(W, "height"); Texts.WriteInt(W, height, 4); Texts.WriteInt(W, minX, 4); Texts.WriteInt(W, maxX, 4);
          Texts.WriteInt(W, minY, 4); Texts.WriteInt(W, maxY, 4); Texts.WriteLn(W);
          Texts.WriteString(W, "Runs"); Texts.WriteLn(W);
          NofBoxes := 0; k := 0;
          WHILE k # NofRuns DO  (*read runs*)
            RdInt16(R, run[k].beg); Texts.WriteInt(W, run[k].beg, 4);
            RdInt16(R, run[k].end); Texts.WriteInt(W, run[k].end, 4);
            NofBoxes := NofBoxes + run[k].end - run[k].beg;
            Texts.WriteLn(W); INC(k)
          END ;
          NofBytes := 5; j := 0;
          WHILE j # NofBoxes DO  (*read boxes*)
            RdInt16(R, box[j].dx); RdInt16(R, box[j].x); RdInt16(R, box[j].y);
            RdInt16(R, box[j].w); RdInt16(R, box[j].h);
            NofBytes := NofBytes + 5 + (box[j].w + 7) DIV 8 * box[j].h;
            INC(j)
          END ;
          NofBytes := NofBytes + (-NofBytes) MOD 4;
          Texts.WriteInt(W, NofRuns, 4); Texts.WriteInt(W, NofBoxes, 4); Texts.WriteInt(W, NofBytes, 6); Texts.WriteLn(W);
          FOR i := 0 TO 4 DO raster[i] := 0 END ;  (*null pattern for characters not in a run*)
          i := 5; j := 0; k := 0; m := 0;
          WHILE k < NofRuns DO
            WHILE (m < run[k].beg) & (m < 128) DO T[m] := 0; INC(m) END ;
            WHILE (m < run[k].end) & (m < 128) DO
              T[m] := i;
              raster[i] := box[j].dx; raster[i+1] := box[j].x; raster[i+2] := box[j].y;
              raster[i+3] := box[j].w; raster[i+4] := box[j].h;
              n := (box[j].w + 7) DIV 8 * box[j].h; INC(i, 5);  (*pattern length*)
              WHILE n # 0 DO DEC(n); Files.ReadByte(R, raster[i]); INC(i) END ;
              INC(j); INC(m)
            END ;
            INC(k)
          END ;
          Texts.WriteString(W, "Raster"); Texts.WriteInt(W, i, 6); Texts.WriteLn(W);
          FOR i := 0 TO 127 DO
            j := T[i];
            IF j # 0 THEN
              Texts.Write(W, CHR(i)); Texts.Write(W, " "); WriteHex(i);
              IF j >= LargeFontSize THEN
                Texts.WriteString(W, "??"); Texts.WriteInt(W, i, 15); Texts.WriteInt(W, j, 15);
                Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
              END ;
              Texts.WriteInt(W, raster[j], 4); Texts.WriteInt(W, raster[j+1], 4);
              Texts.WriteInt(W, LSL(ASR(raster[j+2], 24), 24), 4);
              Texts.WriteInt(W, raster[j+3], 4); Texts.WriteInt(W, raster[j+4], 4);
              n := (raster[j+3] + 7) DIV 8 * raster[j+4]; INC(j, 5);  (*pattern length*)
              Texts.Write(W, TAB);
              WHILE n > 0 DO DEC(n); WriteHex(raster[j]); INC(j) END ;
              Texts.WriteLn(W)
            END
          END ;
          Texts.Append(Oberon.Log, W.buf)
        END
      END
    END
  END Show;

BEGIN Texts.OpenWriter(W); Texts.WriteString(W, "FontTool 16.9.2020");
  Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
END FontTool.

FontTool.Show Oberon10.Scn.Fnt ~
FontTool.Show Oberon10i.Scn.Fnt ~
FontTool.Show Oberon16.Scn.Fnt ~
