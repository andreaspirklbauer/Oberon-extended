MODULE M0;  (*test safe module unloading / AP 7.2.20 Extended Oberon*)
  TYPE Proc* = PROCEDURE;

    Ptr* = POINTER TO Rec;
    Rec* = RECORD x*: INTEGER;
      proc*: Proc;
      ptr*, next: Ptr;
    END;

    Arr* = ARRAY OF Rec;
    PtrArr* = POINTER TO Arr;

    ArrProc* = ARRAY OF Proc;
    PtrArrProc* = POINTER TO ArrProc;

    ArrPtr* = ARRAY OF Ptr;
    PtrArrPtr* = POINTER TO ArrPtr;

  VAR root: Ptr;
    rootarr: PtrArr;
    rootarrptr: PtrArrPtr;
    rootarrproc: PtrArrProc;

  PROCEDURE InsertPtr*(p: Ptr); BEGIN p.next := root; root := p END InsertPtr;
  PROCEDURE InsertArr*(p: PtrArr); BEGIN p[0].next := rootarr; rootarr := p END InsertArr;
  PROCEDURE SetArrProc*(p: PtrArrProc); BEGIN rootarrproc := p END SetArrProc;

  PROCEDURE InitPtr*; BEGIN root := NIL END InitPtr;
  PROCEDURE InitArr*; BEGIN rootarr := NIL END InitArr;
  PROCEDURE InitArrPtr*; BEGIN rootarrptr := NIL END InitArrPtr;
  PROCEDURE InitArrProc*; BEGIN rootarrproc := NIL END InitArrProc;

  PROCEDURE Init*; BEGIN END Init;

BEGIN InitPtr; InitArr; InitArrPtr; InitArrProc
END M0.
