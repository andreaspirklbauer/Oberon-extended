(*  ORP.Compile @
    ORX.WriteFile BootLoad.rsc 512 "D:/Verilog/RISC5/prom.mem"~ *)

MODULE* BootLoad;  (*NW 20.10.2013 / PR 4.2.2014; boot from SDHC disk or line / AP 13.3.20*)
  IMPORT SYSTEM;
  (* sw0: init SD; sw1: line|disk*)
  CONST TR = 13; SP = 14; LNK = 15;
    TrapAdr = 04H; MemLim = 0E7EF0H; stackOrg = 80000H;
    swi = -60; led = -60; rsData = -56; rsCtrl = -52;
    spiData = -48; spiCtrl = -44;
    CARD0 = 1; SPIFAST = 4;
    FSoffset = 80000H;   (*block offset*)

  PROCEDURE RecInt(VAR x: INTEGER);
    VAR z, y, i: INTEGER;
  BEGIN z := 0;  i := 4;
    REPEAT i := i-1;
      REPEAT UNTIL SYSTEM.BIT(rsCtrl, 0);
      SYSTEM.GET(rsData, y); z := ROR(z+y, 8)
    UNTIL i = 0;
    x := z
  END RecInt;

  PROCEDURE LoadFromLine;
    VAR len, adr, dat: INTEGER;
  BEGIN RecInt(len);
    WHILE len > 0 DO
      RecInt(adr);
      REPEAT RecInt(dat); SYSTEM.PUT(adr, dat); adr := adr + 4; len := len - 4 UNTIL len = 0;
      RecInt(len)
    END
  END LoadFromLine;

(* ---------- disk ------------*)

  PROCEDURE SPIIdle(n: INTEGER); (*send n FFs slowly with no card selected*)
  BEGIN SYSTEM.PUT(spiCtrl, 0);
    WHILE n > 0 DO DEC(n); SYSTEM.PUT(spiData, -1);
      REPEAT UNTIL SYSTEM.BIT(spiCtrl, 0)
    END
  END SPIIdle;

  PROCEDURE SPI(n: INTEGER); (*send&rcv byte slowly with card selected*)
  BEGIN SYSTEM.PUT(spiCtrl, CARD0); SYSTEM.PUT(spiData, n);
    REPEAT UNTIL SYSTEM.BIT(spiCtrl, 0)
  END SPI;

  PROCEDURE SPICmd(n, arg: INTEGER);
    VAR i, data, crc: INTEGER;
  BEGIN (*send cmd*)
    REPEAT SPIIdle(1); SYSTEM.GET(spiData, data) UNTIL data = 255; (*flush while unselected*)
    REPEAT SPI(255); SYSTEM.GET(spiData, data) UNTIL data = 255; (*flush while selected*)
    IF n = 8 THEN crc := 135 ELSIF n = 0 THEN crc := 149 ELSE crc := 255 END;
    SPI(n MOD 64 + 64); (*send command*)
    FOR i := 24 TO 0 BY -8 DO SPI(ROR(arg, i)) END; (*send arg*)
    SPI(crc); i := 32;
    REPEAT SPI(255); SYSTEM.GET(spiData, data); DEC(i) UNTIL (data < 80H) OR (i = 0)
  END SPICmd;

  PROCEDURE InitSPI;
    VAR res, data: INTEGER;
  BEGIN SPIIdle(9); (*first, idle for at least 80 clks*)
    SPICmd(0, 0); (*CMD0 when card selected, sets MMC SPI mode*)
    SPICmd(8, 1AAH); SPI(-1); SPI(-1); SPI(-1); (*CMD8 for SD cards*)
    REPEAT (*until card becomes ready*)
      (*ACMD41, optionally with high-capacity (HCS) bit set, starts init*)
      SPICmd(55, 0); (*APP cmd follows*)
      SPICmd(41, LSL(1(*HCS*), 30));
      SYSTEM.GET(spiData, res);
      SPI(-1); SPI(-1); SPI(-1); (*flush response*)
      SPIIdle(10000)
    UNTIL res = 0;
    (*CMD16 set block size as a precaution (should default)*)
    SPICmd(16, 512); SPIIdle(1)
  END InitSPI;

  PROCEDURE SDShift(VAR n: INTEGER);
    VAR data: INTEGER;
  BEGIN SPICmd(58, 0);  (*CMD58 get card capacity bit*)
    SYSTEM.GET(spiData, data); SPI(-1);
    IF (data # 0) OR ~SYSTEM.BIT(spiData, 6) THEN n := n * 512 END ;  (*non-SDHC card*)
    SPI(-1); SPI(-1); SPIIdle(1)  (*flush response*)
  END SDShift;

  PROCEDURE ReadSD(src, dst: INTEGER);
    VAR i, data: INTEGER;
  BEGIN SDShift(src); SPICmd(17, src); (*CMD17 read one block*)
    i := 0; (*wait for start data marker*)
    REPEAT SPI(-1); SYSTEM.GET(spiData, data); INC(i) UNTIL data = 254;
    SYSTEM.PUT(spiCtrl, SPIFAST + CARD0);
    FOR i := 0 TO 508 BY 4 DO
      SYSTEM.PUT(spiData, -1);
      REPEAT UNTIL SYSTEM.BIT(spiCtrl, 0);
      SYSTEM.GET(spiData, data); SYSTEM.PUT(dst, data); INC(dst, 4)
    END;
    SPI(255); SPI(255); SPIIdle(1) (*may be a checksum; deselect card*)
  END ReadSD;

  PROCEDURE LoadFromDisk;
    VAR src, dst, adr, lim: INTEGER;
  BEGIN src := FSoffset + 4;   (*start at boot block*)
    ReadSD(src, 0); SYSTEM.GET(16, lim);
    INC(src); dst := 512;
    WHILE dst < lim DO ReadSD(src, dst); INC(src); INC(dst, 512) END
  END LoadFromDisk;

BEGIN SYSTEM.LDREG(SP, stackOrg); SYSTEM.LDREG(TR, TrapAdr);
  IF SYSTEM.REG(LNK) = 0 THEN (*cold start*)
    LED(80H); InitSPI;
    IF SYSTEM.BIT(swi, 0) THEN LED(81H); LoadFromLine ELSE LED(82H); LoadFromDisk END ;
  ELSIF SYSTEM.BIT(swi, 0) THEN LED(81H); LoadFromLine
  END ;
  SYSTEM.PUT(12, MemLim); SYSTEM.PUT(24, stackOrg); LED(84H)
END BootLoad.

ORP.Compile @  ORG.Decode
ORX.WriteFile BootLoad.rsc "Spartan" "D:/Verilog/RISC/scripts/ins1.mem"~
ORG.WriteFile BootLoad.rsc "Spartan" "D:/Verilog/RISC3/scripts/ins1.mem" ~
ORG.WriteFile BootLoad.rsc "Spartan" "D:/Verilog/RISC5/scripts/ins1.mem"~

MODULE* BootLoad;  (*NW 10.2.2013, boot from line only / AP 13.3.20*)
  IMPORT SYSTEM;
  CONST TR = 13; SP = 14; TrapAdr = 04H; StkOrg = 0FFFE7F00H;
    swi = -60; led = -60; data = -56; stat = -52;

  PROCEDURE RecInt(VAR x: INTEGER);
    VAR z, y, i: INTEGER;
  BEGIN z := 0;  i := 4;
    REPEAT i := i-1;
      REPEAT UNTIL SYSTEM.BIT(stat, 0);
      SYSTEM.GET(data, y); z := ROR(z+y, 8)
    UNTIL i = 0;
    x := z
  END RecInt;

  PROCEDURE Load;
    VAR len, adr, dat: INTEGER;
  BEGIN RecInt(len);
    WHILE len > 0 DO
      RecInt(adr);
      REPEAT RecInt(dat); SYSTEM.PUT(adr, dat); adr := adr + 4; len := len - 4 UNTIL len = 0;
      RecInt(len)
    END
  END Load;

BEGIN SYSTEM.LDREG(SP, StkOrg); SYSTEM.LDREG(TR, TrapAdr); SYSTEM.PUT(led, 128); 
  IF ~SYSTEM.BIT(swi, 0) THEN Load END
END BootLoad.

ORP.Compile @  ORG.Decode
ORX.WriteFile Counter.rsc 2048 "D:/Verilog/RISC/prom.mem"~
ORX.WriteFile Shifter.rsc 2048 "D:/Verilog/RISC/prom.mem"~
ORX.WriteFile TestInt.rsc 2048 "D:/Verilog/RISC3/scripts/ins1.mem"~
ORX.WriteFile BootLoad.rsc 512 "D:/Verilog/RISC5/prom.mem"~

MODULE* Counter;
  VAR x, y, z: INTEGER;
BEGIN LED(1); z := 0;
  REPEAT LED(z); x := 1000;
     REPEAT y := 1000;
       REPEAT y := y-1 UNTIL y = 0;
       x := x-1
     UNTIL x = 0;
     z := z+1
   UNTIL FALSE
END Counter.

MODULE* Shifter;
  VAR x, y, z, d: INTEGER;
BEGIN  z := 1; d := 1;
  REPEAT LED(z); x := 1000;
     REPEAT y := 1000;
       REPEAT y := y-1 UNTIL y = 0;
       x := x-1
     UNTIL x = 0;
     IF z = 128 THEN d := -1 ELSIF z = 1 THEN d := 1 END ;
     IF d = 1 THEN z := LSL(z, 1) ELSE z := ASR(z, 1) END
   UNTIL FALSE
END Shifter.

MODULE* TestInt;
  IMPORT SYSTEM;
  VAR led, led1, cnt, cnt1: INTEGER;

  PROCEDURE* Int; (*interrupt every millisecond*)
  BEGIN INC(cnt1);
    IF cnt1 = 500 THEN led1 := 1 - led1; LED(led1); cnt1 := 0 END
  END Int;

BEGIN led := 0; led1 := 0; cnt := 0; cnt1 := 0;
  SYSTEM.PUT(4, 0E7000000H + SYSTEM.ADR(Int) DIV 4 - 2);
  SYSTEM.LDPSR(1);  (*int enable*)
  REPEAT
    IF SYSTEM.BIT(-60, 0) THEN
      cnt := 100000;
      REPEAT DEC(cnt) UNTIL cnt = 0;
      LED(led); INC(led)
    END
  UNTIL FALSE;
END TestInt.
