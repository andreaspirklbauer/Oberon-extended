MODULE M1;  (*test safe module unloading / AP 1.5.21 Extended Oberon*)
  IMPORT SYSTEM, M0;

  TYPE Ptr* = POINTER TO Rec;
    Rec* = RECORD (M0.Rec) END ;  (*extension of M0.Rec*)
    PtrArr* = M0.PtrArr;
    PtrArrProc* = M0.PtrArrProc;

  VAR gptr*, sptr*: Ptr; grec*: Rec;
    gptrarr*: PtrArr;
    gproc*: M0.Proc;
    garrptr*: M0.PtrArrPtr;
    garrproc*: M0.PtrArrProc;

  PROCEDURE P*; BEGIN END P;

  PROCEDURE SetGlobalPtr*(q: M0.Ptr); BEGIN gptr := q(Ptr) END SetGlobalPtr;
  PROCEDURE SetDynamicPtr*(q: M0.Ptr); BEGIN gptr.ptr := q(Ptr) END SetDynamicPtr;

  PROCEDURE SetGlobalPtrArr*(q: M0.PtrArr); BEGIN gptrarr := q(PtrArr) END SetGlobalPtrArr;
  PROCEDURE SetDynamicPtrArr*(q: M0.PtrArr); BEGIN gptrarr[1].ptr := q(PtrArr) END SetDynamicPtrArr;

  PROCEDURE SetGlobalProc*(q: M0.Proc); BEGIN gproc := q END SetGlobalProc;
  PROCEDURE SetDynamicProc*(q: M0.Proc); BEGIN gptr.proc := q END SetDynamicProc;

  PROCEDURE SetDynamicArrRec*(q: M0.Proc); BEGIN gptrarr[2].x := 8; gptrarr[2].proc := q END SetDynamicArrRec;
  PROCEDURE SetDynamicArrProc*(q: M0.Proc); BEGIN garrproc[2] := q END SetDynamicArrProc;

  PROCEDURE Init*; BEGIN END Init;

  (*
   * pointer variable references to static module data -> these are only possible by resorting to low-level facilitie
   *)
  PROCEDURE SetStaticPtrRef*(adr: LONGINT); BEGIN sptr := SYSTEM.VAL(Ptr, adr) END SetStaticPtrRef;
  PROCEDURE UnSetStaticPtrRef*(); BEGIN sptr := NIL END UnSetStaticPtrRef;

  PROCEDURE SetDynamicPtrRef*(adr: LONGINT); BEGIN gptr.ptr := SYSTEM.VAL(Ptr, adr) END SetDynamicPtrRef;
  PROCEDURE UnSetDynamicPtrRef*(); BEGIN gptr.ptr := NIL END UnSetDynamicPtrRef;

  PROCEDURE SetDynamicArrRecPtrRef*(adr: LONGINT); BEGIN gptrarr[2].ptr := SYSTEM.VAL(Ptr, adr) END SetDynamicArrRecPtrRef;
  PROCEDURE UnSetDynamicArrRecPtrRef*; BEGIN gptrarr[2].ptr := NIL END UnSetDynamicArrRecPtrRef;

  PROCEDURE SetDynamicArrPtrPtrRef*(adr: LONGINT); BEGIN garrptr[3] := SYSTEM.VAL(Ptr, adr) END SetDynamicArrPtrPtrRef;
  PROCEDURE UnSetDynamicArrPtrPtrRef*; BEGIN garrptr[3] := NIL END UnSetDynamicArrPtrPtrRef;

BEGIN NEW(gptr); NEW (gptrarr, 10); NEW(garrproc, 150); NEW(garrptr, 100)
END M1.
