MODULE* BootLoadLine;  (*NW 20.10.2013 / PR 4.2.2014 / AP 13.3.20 for use in Oberon0*)
  IMPORT SYSTEM;
  (* sw0: init SD; sw1: line|disk*)
  CONST TR = 13; SP = 14;
    TrapAdr = 04H; MemLim = 0E7EF0H; stackOrg = 80000H;
    rsData = -56; rsCtrl = -52;

  PROCEDURE RecInt(VAR x: INTEGER);
    VAR z, y, i: INTEGER;
  BEGIN z := 0;  i := 4;
    REPEAT i := i-1;
      REPEAT UNTIL SYSTEM.BIT(rsCtrl, 0);
      SYSTEM.GET(rsData, y); z := ROR(z+y, 8)
    UNTIL i = 0;
    x := z
  END RecInt;

  PROCEDURE LoadFromLine*;
    VAR len, adr, dat: INTEGER;
  BEGIN RecInt(len);
    WHILE len > 0 DO
      RecInt(adr);
      REPEAT RecInt(dat); SYSTEM.PUT(adr, dat); adr := adr + 4; len := len - 4 UNTIL len = 0;
      RecInt(len)
    END
  END LoadFromLine;

BEGIN SYSTEM.LDREG(SP, stackOrg); SYSTEM.LDREG(TR, TrapAdr);
  LED(82H); LoadFromLine;
  SYSTEM.PUT(12, MemLim); SYSTEM.PUT(24, stackOrg); LED(84H)
END BootLoadLine.
