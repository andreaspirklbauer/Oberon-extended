ORP.Compile @/s  Blink.Run  BlinkStop

MODULE Blink;   (*NW 30.5.2013  use of a Task; blinks LED every second*)
  IMPORT SYSTEM, Oberon;
  VAR z: INTEGER;
    T: Oberon.Task;
  
  PROCEDURE Run*;
  BEGIN Oberon.Install(T)
  END Run;

  PROCEDURE Stop*;
  BEGIN Oberon.Remove(T)
  END Stop;

  PROCEDURE Tick;
  BEGIN z := 1-z; LED(z)
  END Tick;

BEGIN z := 0; T := Oberon.NewTask(Tick, 500)
END Blink.

ORP.Compile @/s  Permutations.Generate 2 3 4~

MODULE Permutations;  (*NW 22.1.2013*)
  IMPORT Texts, Oberon;
  VAR n: INTEGER;
    a: ARRAY 10 OF INTEGER;
    S: Texts.Scanner;
    W: Texts.Writer;

  PROCEDURE perm(k: INTEGER);
    VAR i, x: INTEGER;
  BEGIN
    IF k = 0 THEN i := 0;
      WHILE i < n DO Texts.WriteInt(W, a[i], 5); i := i+1 END ;
      Texts.WriteLn(W)
    ELSE perm(k-1); i := 0;
      WHILE i < k-1 DO
        x := a[i]; a[i] := a[k-1]; a[k-1] := x;
        perm(k-1);
        x := a[i]; a[i] := a[k-1]; a[k-1] := x;
        i := i+1
      END
    END
  END perm;

  PROCEDURE Generate*;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); n := 0;
    WHILE S.class = Texts.Int DO a[n] := S.i; INC(n); Texts.Scan(S) END ;
    perm(n);
    Texts.Append(Oberon.Log, W.buf)
  END Generate;

BEGIN Texts.OpenWriter(W)
END Permutations.

ORP.Compile @/s  MagicSquares.Generate 3

MODULE MagicSquares;   (*NW 11.8.97*)
  IMPORT Texts, Oberon;

  VAR W: Texts.Writer;

  PROCEDURE Generate*;  (*magic square of order 3, 5, 7, ... *)
    VAR i, j, x, nx, nsq, n: INTEGER;
      M: ARRAY 13, 13 OF INTEGER;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN
      n := S.i; nsq := n*n; x := 0;
      i := n DIV 2; j := n-1;
      WHILE x < nsq DO
        nx := n + x; j := (j-1) MOD n; INC(x); M[i, j] := x;
        WHILE x < nx DO
          i := (i+1) MOD n; j := (j+1) MOD n;
          INC(x); M[i, j] := x
        END
      END ;
      FOR i := 0 TO n-1 DO
        FOR j := 0 TO n-1 DO Texts.WriteInt(W, M[i, j], 6) END ;
        Texts.WriteLn(W)
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END Generate;

BEGIN Texts.OpenWriter(W)
END MagicSquares.

ORP.Compile @/s  PrimeNumbers.Generate 12

MODULE PrimeNumbers;  (*NW 6.9.07; Tabulate prime numbers; for Oberon-07  NW 25.1.2013*)
  IMPORT Texts, Oberon;
  
  VAR n: INTEGER;
    W: Texts.Writer;
    p: ARRAY 400 OF INTEGER;
    v: ARRAY 20 OF INTEGER;

  PROCEDURE Primes(n: INTEGER);
    VAR i, k, m, x, inc, lim, sqr: INTEGER; prim: BOOLEAN;
  BEGIN x := 1; inc := 4; lim := 1; sqr := 4; m := 0;
    FOR i := 3 TO n DO
      REPEAT x := x + inc; inc := 6 - inc;
        IF sqr <= x THEN  (*sqr = p[lim]^2*)
          v[lim] := sqr; INC(lim); sqr := p[lim]*p[lim]
        END ;
        k := 2; prim := TRUE;
        WHILE prim & (k < lim) DO
          INC(k);;
          IF v[k] < x THEN v[k] := v[k] + p[k] END ;
          prim := x # v[k]
        END
      UNTIL prim;
      p[i] := x; Texts.WriteInt(W, x, 5);
      IF m = 10 THEN Texts.WriteLn(W); m := 0 ELSE INC(m) END
    END ;
    IF m > 0 THEN Texts.WriteLn(W) END
  END Primes;

  PROCEDURE Generate*;
    VAR S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.i < 400 THEN
      Primes(S.i); Texts.Append(Oberon.Log, W.buf)
    END
  END Generate;

BEGIN Texts.OpenWriter(W);
END PrimeNumbers.

ORP.Compile @/s  Fractions.Generate 16

MODULE Fractions;  (*NW  10.10.07;  Tabulate fractions 1/n*)
  IMPORT Input, Texts, Oberon;
  
  CONST Base = 10; N = 32; TAB = Input.TAB;
  VAR W: Texts.Writer;
  
  PROCEDURE Generate*;
    VAR i, j, m, r: INTEGER;
      d: ARRAY N OF INTEGER;  (*digits*)
      x: ARRAY N OF INTEGER;  (*index*)
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Int) & (S.i < N) THEN
      i := 2;
      WHILE i <= S.i DO j := 0;
        WHILE j < i DO x[j] := 0; INC(j) END ;
        m := 0; r := 1;
        WHILE x[r] = 0 DO
          x[r] := m; r := Base*r; d[m] := r DIV i; r := r MOD i; INC(m)
        END ;
        Texts.WriteInt(W, i, 5); Texts.Write(W, TAB); Texts.Write(W, "."); j := 0;
        WHILE j < x[r] DO Texts.Write(W, CHR(d[j] + 48)); INC(j) END ;
        Texts.Write(W, "'");
        WHILE j < m DO Texts.Write(W, CHR(d[j] + 48)); INC(j) END ;
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); INC(i)
      END
    END
  END Generate;

BEGIN Texts.OpenWriter(W)
END Fractions.

ORP.Compile @/s  Powers.Generate 16

MODULE Powers;  (*NW  10.10.07; Tabulate positive and negative powers of 2*)
  IMPORT Texts, Oberon;

  CONST N = 32; M = 11;  (*M ~ N*log2*)
  VAR W: Texts.Writer;
  
  PROCEDURE Generate*;
    VAR i, k, n, exp: INTEGER;
      c, r, t: INTEGER;
      d: ARRAY M OF INTEGER;
      f: ARRAY N OF INTEGER;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Int) & (S.i <= N) THEN
      n := S.i; d[0] := 1; k := 1; exp := 1;
      WHILE exp < n DO
        (*compute d = 2^exp*)
        c := 0;  (*carry*) i := 0;
        WHILE i < k DO
          t := 2*d[i] + c;
          IF t < 10 THEN d[i] := t; c := 0 ELSE d[i] := t - 10; c := 1 END ;
          i := i+1
        END ;
        IF c = 1 THEN d[k] := 1; k := k+1 END ;
        (*write d*) i := M;
        WHILE i > k DO i := i-1; Texts.Write(W, " ") END ;
        WHILE i > 0 DO i := i-1; Texts.Write(W, CHR(d[i] + 30H)) END ;
        Texts.WriteInt(W, exp, M);
        (*compute  f = 2^-exp*)
        Texts.WriteString(W, "  0."); r := 0; i := 1;
        WHILE i < exp DO
          r := 10*r + f[i]; f[i] := r DIV 2; r := r MOD 2;
          Texts.Write(W, CHR(f[i] + 30H)); i := i+1
        END ;
        f[exp] := 5; Texts.Write(W, "5"); Texts.WriteLn(W); exp := exp + 1
      END ;
      Texts.Append(Oberon.Log, W.buf)
    END
  END Generate;

BEGIN Texts.OpenWriter(W)
END Powers.

ORP.Compile @/s  Harmonic.Compute 200

MODULE Harmonic;   (*NW 27.1.2013*)
  IMPORT Texts, Oberon;
  VAR W: Texts.Writer;
  
  PROCEDURE Compute*;
      VAR n: INTEGER;
        x0, x1, u: REAL;
        S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Int) & (S.i > 0) THEN
      n := 0; u := 0.0; x0 := 0.0; x1 := 0.0;
      WHILE n < S.i DO INC(n); u := u + 1.0; x0 := x0 + 1.0/u END ;
      WHILE n > 0 DO x1 := x1 + 1.0/u; u := u - 1.0; DEC(n) END ;
      Texts.WriteInt(W, S.i, 6); Texts.WriteReal(W, x0, 15); Texts.WriteReal(W, x1, 15);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
    END
  END Compute;

BEGIN Texts.OpenWriter(W)
END Harmonic.
