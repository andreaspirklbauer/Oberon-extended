MODULE RS232;   (*NW 3.1.2012*)
  IMPORT SYSTEM;
  CONST data = -56; stat = -52;

  PROCEDURE Send*(x: INTEGER);
  BEGIN
    REPEAT UNTIL SYSTEM.BIT(stat, 1);
    SYSTEM.PUT(data, x)
  END Send;
  
  PROCEDURE Rec*(VAR x: INTEGER);
  BEGIN
    REPEAT UNTIL SYSTEM.BIT(stat, 0);
    SYSTEM.GET(data, x)
  END Rec;

  PROCEDURE SendInt*(x: INTEGER);
    VAR i: INTEGER;
  BEGIN Send(1); i := 4;
    REPEAT i := i-1; Send(x);  x := ROR(x, 8) UNTIL i = 0
  END SendInt;

  PROCEDURE SendHex*(x: INTEGER);
    VAR i: INTEGER;
  BEGIN Send(2); i := 4;
    REPEAT i := i-1; Send(x);  x := ROR(x, 8) UNTIL i = 0
  END SendHex;

  PROCEDURE SendReal*(x: REAL);
    VAR i, u: INTEGER;
  BEGIN Send(3); u := ORD(x); i := 4;
    REPEAT i := i-1; Send(u);  u := ROR(u, 8) UNTIL i = 0
  END SendReal;

  PROCEDURE SendStr*(x: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN Send(4); i := 0;
    REPEAT k := ORD(x[i]); Send(k); INC(i) UNTIL k = 0
  END SendStr;

  PROCEDURE RecInt*(VAR x: INTEGER);
    VAR i, x0, y: INTEGER;
  BEGIN i := 4; x0 := 0;
    REPEAT i := i-1; Rec(y); x0 := ROR(x0+y, 8) UNTIL i = 0;
    x := x0
  END RecInt;

  PROCEDURE RecReal*(VAR x: REAL);
    VAR i, x0, y: INTEGER;
  BEGIN i := 4; x0 := 0;
    REPEAT i := i-1; Rec(y); x0 := ROR(x0+y, 8) UNTIL i = 0;
    x := SYSTEM.VAL(REAL, x0)
  END RecReal;

  PROCEDURE RecStr*(VAR x: ARRAY OF CHAR);
    VAR i, k: INTEGER;
  BEGIN i := 0;
    REPEAT Rec(k); x[i] := CHR(k); INC(i) UNTIL k = 0
  END RecStr;

  PROCEDURE Line*;
  BEGIN Send(6)
  END Line;
  
  PROCEDURE End*;
  BEGIN Send(7)
  END End;

BEGIN END RS232.
