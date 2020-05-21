MODULE PIO;   (*NW 16.10.2014  PIC Input/Output for RISC*)
  IMPORT SYSTEM;
  
(* PIC interface, output:
  D0  =  PIC B7  data out
  D1  =  PIC B6  clk  out
  D2  =  PIC A4  data in *)

  CONST gpio = -32; gpoc = -28;  (*I/O addresses*)

  PROCEDURE del(i: INTEGER);
  BEGIN
    REPEAT DEC(i) UNTIL i = 0
  END del;

  PROCEDURE Send*(x: LONGINT);
    VAR i: INTEGER;
  BEGIN (*send byte*)
    FOR i := 0 TO 7 DO
      SYSTEM.PUT(gpio, x MOD 2 + 2); del(60); SYSTEM.PUT(gpio, x MOD 2); del(25); x := x DIV 2
    END ;
    SYSTEM.PUT(gpio, 0); del(100)
  END Send;

  PROCEDURE Receive*(VAR x: LONGINT);
    VAR i, x0: INTEGER;
  BEGIN (*receive byte*) x0 := 0;
    REPEAT UNTIL ~SYSTEM.BIT(gpio, 2);
    FOR i := 0 TO 7 DO
      SYSTEM.PUT(gpio, 2); del(60);
      IF SYSTEM.BIT(gpio, 2) THEN x0 := x0 + 100H END ;
      SYSTEM.PUT(gpio, 0); del(25); x0 := ROR(x0, 1)
    END ;
    x := x0
  END Receive;

  PROCEDURE Reset*;
  BEGIN SYSTEM.PUT(gpio, 0); SYSTEM.PUT(gpoc, 3)  (*set bit 0, 1 to output*)
  END Reset;

BEGIN Reset
END PIO.
