MODULE RISC;     (*NW 22.9.07 / 1.11.2013*)
  IMPORT SYSTEM, Texts, Oberon;
  CONST
    MOV = 0; LSL = 1; ASR = 2; ROR = 3; AND = 4; ANN = 5; IOR = 6; XOR = 7;
    ADD = 8; SUB = 9;  MUL = 10; Div = 11;

  VAR IR: LONGINT;   (*instruction register*)
    PC: LONGINT;   (*program counter*)
    N, Z: BOOLEAN;  (*condition flags*)
    R: ARRAY 16 OF LONGINT;
    H: LONGINT;  (*aux register for division*)
    
  PROCEDURE Execute*(VAR M: ARRAY OF LONGINT; pc: LONGINT;
      VAR S: Texts.Scanner; VAR W: Texts.Writer);
    VAR a, b, op, im: LONGINT;  (*instruction fields*)
      adr, A, B, C, n: LONGINT;
      MemSize: LONGINT;
  BEGIN PC := 0; R[13] := pc * 4; R[14] := LEN(M)*4; n := 0;
    REPEAT (*interpretation cycle*)
      IR := M[PC]; INC(PC); INC(n);
      a := IR DIV 1000000H MOD 10H;
      b := IR DIV 100000H MOD 10H;
      op := IR DIV 10000H MOD 10H;
      im := IR MOD 10000H;
      IF ~ODD(IR DIV 80000000H) THEN  (*~p:  register instruction*)
        B := R[b];
        IF ~ODD(IR DIV 40000000H) THEN (*~q*) C := R[IR MOD 10H]
        ELSIF ~ODD(IR DIV 10000000H) THEN (*q&~v*) C := im
        ELSE (*q&v*) C := im + 0FFFF0000H
        END ;
        CASE op OF
            MOV: IF ~ODD(IR DIV 20000000H) THEN A := C ELSE A := H END |
            LSL: A := SYSTEM.LSH(B, C) |
            ASR: A := ASH(B, -C) |
            ROR: A := SYSTEM.ROT(B, -C) |
            AND: A := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, B) * SYSTEM.VAL(SET, C)) |
            ANN: A := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, B) - SYSTEM.VAL(SET, C)) |
            IOR: A := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, B) + SYSTEM.VAL(SET, C)) |
            XOR: A := SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, B) / SYSTEM.VAL(SET, C)) |
            ADD: A := B + C |
            SUB: A := B - C |
            MUL: A := B * C |
            Div: A := B DIV C; H := B MOD C
         END ;
         R[a] := A; N := A < 0; Z := A = 0
      ELSIF ~ODD(IR DIV 40000000H) THEN (*p & ~q: memory instruction*)
        adr := (R[b] + IR MOD 100000H) DIV 4;
        IF ~ODD(IR DIV 20000000H) THEN
          IF adr >= 0 THEN (*load*) R[a] := M[adr]; N := A < 0; Z := A = 0
          ELSE (*input*)
            IF adr = -1 THEN (*ReadInt*) Texts.Scan(S); R[a] := S.i;
            ELSIF adr = -2 THEN (*eot*)  Z := S.class # Texts.Int
            END 
          END
        ELSE
          IF adr >= 0 THEN (*store*) M[adr] := R[a];
          ELSE (*output*)
            IF adr = -1 THEN Texts.WriteInt(W, R[a], 4)
            ELSIF adr = -2 THEN Texts.Write(W, CHR(R[a] MOD 80H))
            ELSIF adr = -3 THEN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
            END
          END
        END
      ELSE (* p & q: branch instruction*)
        IF (a = 0) & N OR (a = 1) & Z OR (a = 5) & N OR (a = 6) & (N OR Z) OR (a = 7) OR
            (a = 8) & ~N OR (a = 9) & ~Z OR (a = 13) & ~N OR (a = 14) & ~(N OR Z) THEN
          IF ODD(IR DIV 10000000H) THEN R[15] := PC * 4 END ;
          IF ODD(IR DIV 20000000H) THEN PC := (PC + (IR MOD 1000000H)) MOD 40000H 
          ELSE PC := R[IR MOD 10H] DIV 4
          END
        END
      END
    UNTIL (PC = 0) OR (n = 100000);
    Texts.WriteInt(W, n, 8);
    IF n = 100000 THEN Texts.WriteString(W, " aborted") END ;
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Execute;
END RISC.


