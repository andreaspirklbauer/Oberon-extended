MODULE TestTypeCase;  (*test type case statements / AP 1.5.21 Extended Oberon*)
  IMPORT Texts, Oberon;
  TYPE R0 = RECORD fld0: INTEGER END ;
    R1 = RECORD (R0) fld1: INTEGER END ;
    R2 = RECORD (R0) fld2: INTEGER END ;

    P0 = POINTER TO R0;
    P1 = POINTER TO R1;
    P2 = POINTER TO R2;

    A = ARRAY OF INTEGER;  (*open array*)
    P = POINTER TO A;

  VAR p: P; p0: P0; p1: P1; p2: P2;
    r0: R0; r1: R1; r2: R2;

  PROCEDURE AssignGlobal();
  BEGIN p0 := p2
  END AssignGlobal;

  PROCEDURE Proc1(p0: P0); BEGIN END Proc1;
  PROCEDURE Proc2(VAR p1: P1); BEGIN END Proc2;
  PROCEDURE Proc3(VAR r0: R0); BEGIN r0 := r2 (*projection*) END Proc3;
  PROCEDURE Proc4(r0: R0); BEGIN END Proc4;
  PROCEDURE Proc5(VAR i: INTEGER); BEGIN END Proc5;
  PROCEDURE Proc6(b: BOOLEAN); BEGIN END Proc6;

  PROCEDURE check0();
  BEGIN p0 := p1;
    CASE p0 OF             (*ERROR "invalid case expression" - global case variables are not allowed*)
      P1:
        AssignGlobal();    (*if p0 were allowed to be global, the dynamic type of p0 would be set to P2 here*)
        p0.fld1 := 123     (*and there would be a type violation here, as p0 is considered of type P1*)
    END ;
    CASE Oberon.Log OF
      Texts.Text: p0 := p1
    END
  END check0;

  PROCEDURE check1();
    VAR p, pa: P0;
  BEGIN p := p1; p.fld0 := 33;
    CASE p OF
      P1:
        pa := p;
        Proc1(p);
        Proc2(p);          (*ERROR "read-only" - cannot pass a case variable of a pointer type as a VAR parameter*)
        Proc5(p.fld1);
        p := p2;           (*ERROR "read-only" - cannot modify a case variable through an assignment*)
        p.fld1 := 123;
        CASE p OF
          P1:
            p := p1;       (*ERROR "read-only" - cannot modify a case variable through an assignment*)
            Proc1(p);
            Proc2(p)       (*ERROR "read-only" - cannot pass a case variable of a pointer type as a VAR parameter*)
        END ;
        p := p1            (*ERROR "read-only" - cannot modify a case variable through an assignment*)
    ELSE p := p1           (*ERROR "read-only" - cannot modify a case variable through an assignment*)
    END ;
    CASE p.fld0 OF         (*selecting a field is allowed for the numeric case statement*)
      33..44: INC(p.fld0)
    END
  END check1;

  PROCEDURE check2();
  BEGIN p0 := p1;
    IF p0 IS P1 THEN
      AssignGlobal();      (*the runtime type of p0 is not P1 anymore, but P2, after this statement*)
      p0(P1).fld1 := 123;  (*thereore, there (correctly) will be a type guard failure at runtime here*)
    END
  END check2;

  PROCEDURE check3(VAR r: R0);
    VAR rr: R1;
  BEGIN r := r1;           (*projection of the fields of r1 onto the fiels of r0*)
    CASE r OF
      R1:
        rr := r;
        r := r1;           (*projection of the fields of r1 onto the fiels of r0*)
        Proc3(r);
        Proc4(r);
        r.fld1 := 234
    END
  END check3;

  PROCEDURE check4();
    VAR r: R1;
  BEGIN r := r1;
    CASE r OF              (*ERROR "invalid case expression" - a record must be a variable parameter*)
      R1: r.fld1 := 345
    END
  END check4;

  PROCEDURE check5(p: P0);
  BEGIN
    CASE p OF
      P1: Proc6(p IS P1)
    END
  END check5;

  PROCEDURE check6(VAR p: P0);
  BEGIN
    CASE p OF P1:          (*ERROR "invalid case expression" - a pointer must be either a local variable or a value parameter*)
      p0 := p2;
      p.fld1 := {4,1}
    END
  END check6;

  PROCEDURE check7();
    VAR q: P;
  BEGIN q := p;
    CASE q OF              (*ERROR "invalid case expression" - a pointer must be a pointer to record*)
      P: q[3] := 3
    END
  END check7;

  PROCEDURE Go*;
  BEGIN
    check0();
    check1();
    check2();
    check3(r0);
    check4();
    check5(p0);
    p0 := p1; check6(p0);
    check7()
  END Go;

BEGIN NEW(p, 100); NEW(p0); NEW(p1); NEW(p2)
END TestTypeCase.

ORP.Compile TestTypeCase.Mod/s ~
System.Free TestTypeCase ~
TestTypeCase.Go
