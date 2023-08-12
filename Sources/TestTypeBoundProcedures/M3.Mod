MODULE M3;  (*test type-bound procedures / AP 1.8.23 Extended Oberon*)
  IMPORT Out;

  TYPE
    Ptr* = POINTER TO Rec;
    PtrExt* = POINTER TO RecExt;
    Handler* = PROCEDURE(p: Ptr; str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);

    Rec* = RECORD x0*, x1*, x2, x3*, x4, x5, x6*: INTEGER; handle: Handler END ;
    RecExt* = RECORD (Rec) y1, y2*, y3, y4*: INTEGER END ;

  VAR ptr: Ptr; rec: Rec; ptrext: PtrExt; recext: RecExt; B: INTEGER;

  PROCEDURE Write(x0, x1, x2, x3, x4, x5, x6, a, b: INTEGER);
  BEGIN Out.String("; x0 ="); Out.Int(x0, 3); Out.String(", x1 ="); Out.Int(x1, 3); Out.String(", x2 ="); Out.Int(x2, 3);
    Out.String(", x3 ="); Out.Int(x3, 3); Out.String(", x4 ="); Out.Int(x4, 3); Out.String(", x5 ="); Out.Int(x5, 3);
    Out.String(", x6 ="); Out.Int(x6, 3); Out.String(";  a ="); Out.Int(a, 3); Out.String(",  b ="); Out.Int(b, 3)
  END Write;
 
  PROCEDURE (p: Ptr) Method1*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.Ptr.Method1; str = "); Out.String(str);
    Write(p.x0, p.x1, p.x2, p.x3, p.x4, p.x5, p.x6, a, b); INC(b)
  END Method1;

  PROCEDURE (VAR r: Rec) Method2*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.Rec.Method2; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b);

    (*

    (*super call of a method bound to the base type of an extension) via pointer*)
    Out.String("Calling ptrext.Method2 with str = Method2s (super call via pointer)"); Out.Ln;
    INC(ptrext.x2);
    ptrext.Method2^("Method2s (super call via pointer)", ptrext.x2, B); Out.Ln;
    (*would lead to a "receiver must be the same as in overriding method" error*)

    
    (*super call of a method bound to the base type of an extension) via record*)
    Out.String("Calling recext.Method2^ with str = Method2s (super call via record)"); Out.Ln;
    recext.x2 := 1;
    recext.Method2^("Method2s (super call via record)", recext.x2, B); Out.Ln
    (*would lead to a "receiver must be the same as in overriding method" error*)

    *)
  END Method2;

  PROCEDURE (VAR r: Rec) Method3*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER): INTEGER;
  BEGIN Out.String("  Hello from M3.Rec.Method3; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b); Out.Ln; RETURN r.x4
  END Method3;

  PROCEDURE (VAR r: Rec) Method5*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.Rec.Method5; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method5;

  PROCEDURE (VAR r: Rec) Method6*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.Rec.Method6; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method6;

  PROCEDURE (r: Ptr) Method6pdp*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.Ptr.Method6pdp; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method6pdp;

  PROCEDURE (VAR r: RecExt) Method2*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.RecExt.Method2; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method2;

  PROCEDURE (VAR r: RecExt) Method4*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.RecExt.Method4; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method4;

  PROCEDURE (VAR r: RecExt) Method6*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.RecExt.Method6; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method6;

  PROCEDURE (r: PtrExt) Method6pdp*(str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.PtrExt.Method6pdp; str = "); Out.String(str);
    Write(r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6, a, b); INC(b)
  END Method6pdp;

  PROCEDURE Handler1(p: Ptr; str: ARRAY OF CHAR; a: INTEGER; VAR b: INTEGER);
  BEGIN Out.String("  Hello from M3.Ptr.Handler1; str = "); Out.String(str);
    Write(p.x0, p.x1, p.x2, p.x3, p.x4, p.x5, p.x6, a, b); INC(b)
  END Handler1;

  PROCEDURE Go0*;  (*call to a regular handler that is not a method*)
  BEGIN Out.String("Calling ptr.handle with str = Handler1"); Out.Ln;
    INC(ptr.x0); ptr.handle(ptr, "Handler1", ptr.x0, B); Out.Ln
  END Go0;

  PROCEDURE Go1*;  (*caller AUTOMATICALLY passes the de-referenced ptr^ to the method which accepts a POINTER*)
  BEGIN Out.String("Calling ptr.Method1 with str = Method1"); Out.Ln;
    INC(ptr.x1); ptr.Method1("Method1", ptr.x1, B); Out.Ln
  END Go1;

  PROCEDURE Go1b*;  (*caller EXPLICITLY de-references ptr^ BEFORE calling the method which accepts a POINTER*)
  BEGIN Out.String("Calling ptr^.Method1 with str = Method1b"); Out.Ln;
    INC(ptr^.x1); ptr.Method1("Method1b", ptr^.x1, B); Out.Ln
  END Go1b;

  (*PROCEDURE Go1r*;  (*would lead to "incompatible receiver" error*)
  BEGIN INC(rec.x2); rec.Method1("Method1r", rec.x2, B); Out.Ln
  END Go1r;*)

  PROCEDURE Go2*;  (*caller AUTOMATICALLY passes the de-referenced ptr^ to the method which accepts a VAR record*)
  BEGIN Out.String("Calling ptr.Method2 with str = Method2"); Out.Ln;
    INC(ptr.x2); ptr.Method2("Method2", ptr.x2, B); Out.Ln
  END Go2;

  PROCEDURE Go2r*;  (*a statically declared global record can also be a receiver*)
  BEGIN Out.String("Calling rec.Method2 with str = Method2r"); Out.Ln;
    INC(rec.x2); rec.Method2("Method2r", rec.x2, B); Out.Ln
  END Go2r;

  PROCEDURE Go2e*;  (*call a method that is bound to a record extension*)
  BEGIN Out.String("Calling ptrext.Method2 with str = Method2e"); Out.Ln;
    INC(ptrext.x2); ptrext.Method2("Method2e", ptrext.x2, B); Out.Ln
  END Go2e;

  (*
  PROCEDURE Go2s*;  (*super call of a method bound to the base type of an extension) via pointer*)
  BEGIN Out.String("Calling ptrext.Method2 with str = Method2s (super call via pointer)"); Out.Ln;
    INC(ptrext.x2);
    ptrext.Method2^("Method2s (super call via pointer)", ptrext.x2, B); Out.Ln
    (*would lead to a "redefined method must be called from overriding method" error*)
  END Go2s;

  PROCEDURE Go2sr*;  (*super call of a method bound to the base type of an extension) via record*)
  BEGIN Out.String("Calling recext.Method2^ with str = Method2s (super call via record)"); Out.Ln;
    recext.x2 := 1;
    recext.Method2^("Method2s (super call via record)", recext.x2, B); Out.Ln
    (*would lead to a "redefined method must be called from overriding method" error*)
  END Go2sr;
  *)

  PROCEDURE Go3*;  (*call of a method that is a function procedure*)
    VAR res: INTEGER;
  BEGIN Out.String("Calling ptr.Method3 twice, with str = Method3a and with str = Method3b"); Out.Ln;
    INC(ptr.x3); res := ptr.Method3("Method3a", ptr.x3, B) + ptr.Method3("Method3b", ptr.x3+1, B)
  END Go3;

  PROCEDURE Go4r*;  (*a statically declared global record EXTENSION can also be a receiver*)
  BEGIN Out.String("Calling recext.Method4 with str = Method4r"); Out.Ln;
    INC(recext.x4); recext.Method4("Method4r", recext.x3, B); Out.Ln
  END Go4r;

  PROCEDURE Go4e*;  (*call a method that is bound to a record extension*)
  BEGIN Out.String("Calling ptrext.Method4 with str = Method4e"); Out.Ln;
    INC(ptrext.x4); ptrext.Method4("Method4e", ptrext.x4, B); Out.Ln
  END Go4e;

  (*PROCEDURE Go4s*;  (*would lead to "method undefined in base types" error*)
  BEGIN INC(ptrext.x4); ptrext.Method4^("Method4s", ptrext.x4, B)
  END Go4s;*)

  PROCEDURE Go5*;  (*ptr is automatically dereferenced by the caller when the method is called*)
  BEGIN Out.String("Calling ptr.Method5 with str = Method5"); Out.Ln;
    INC(ptr.x5); ptr.Method5("Method5", ptr.x5, B); Out.Ln
  END Go5;
  
  PROCEDURE Go5b*;  (*caller explicitly de-references ptr^ BEFORE calling the method*)
  BEGIN Out.String("Calling ptr.Method5 with str = Method5b"); Out.Ln;
    INC(ptr^.x5); ptr.Method5("Method5b", ptr.x5, B); Out.Ln
  END Go5b;

  PROCEDURE Go5pe*;  (*ptr to an EXTENSION is passed to VAR param of a BASE type*)
  BEGIN Out.String("Calling ptrext.Method5 with str = Method5pe"); Out.Ln;
    INC(ptrext.x5); ptrext.Method5("Method5pe", ptrext.x5, B); Out.Ln
  END Go5pe;

  PROCEDURE Go6*;  (*caller AUTOMATICALLY passes the de-referenced ptr^ to a method which accepts a VAR record*)
  BEGIN Out.String("Calling ptr.Method6 with str = Method6"); Out.Ln;
    INC(ptr.x6); ptr.Method6("Method6", ptr.x6, B); Out.Ln
  END Go6;

  PROCEDURE Go6b*;  (*caller EXPLICITLY passes the de-referenced ptr^ to a method which accepts a VAR record*)
  BEGIN Out.String("Calling ptr.Method6 with str = Method6b"); Out.Ln;
    INC(ptr^.x6); ptr.Method6("Method6b", ptr.x6, B); Out.Ln
  END Go6b;

  PROCEDURE Go6pe*;  (*ptr to an extension is passed to a VAR param of a base type*)
  BEGIN Out.String("Calling ptrext.Method6 with str = Method6pe"); Out.Ln;
    INC(ptrext.x6); ptrext.Method6("Method6pe", ptrext.x6, B); Out.Ln
  END Go6pe;
  
  PROCEDURE Go6pd*;  (*dynamic type of receiver set to an extension through an assignment*)
  BEGIN Out.String("Calling ptr.Method6 with str = Method6pd"); Out.Ln;
    INC(ptrext.x6); ptr := ptrext; ptr.Method6("Method6pd", ptr.x6, B); Out.Ln
  END Go6pd;

  PROCEDURE Go6pdp*;  (*dynamic type of receiver set to an extension through an assignment AND and an overwritten method is called*)
  BEGIN Out.String("Calling ptr.Method6pdp with str = Method6pdp"); Out.Ln;
    INC(ptrext.x6); ptr := ptrext; ptr.Method6pdp("Method6pdp", ptr.x6, B); Out.Ln
  END Go6pdp;

  (*
    Note: Go6pdp works only because Method6pdp is ALSO defined for the base type Ptr, in addition to being overwritten in PtrExt.
    - First, ptr is used to see WHETHER the method Method6pdp is bound to the base type Ptr.
    - Second, the DYNAMIC type of ptr (=PtrExt) is used to pass the receiver pointed to by ptr (=ptrext)
      AND call the method Method6pdp that is bound to the extended type PtrExt.

    The output will be "Method6pdp (ext6) followed by "Method6pdp (base)" rather than "Method6pdp (base) followed by "Method6pdp (base)").

    This behaviour is intentional. For example, if a base module "Graphics" defines a method "Draw" for graphic objects of
    type "Graphic" and contains a loop that calls obj.Draw for each graphic object in a data structure rooted in Graphics.root,
    then in a client module "ColoredGraphics", method "Draw" may be overwritten for an extended type "ColoredGraphgic".

    We want to be sure that the base type "Graphics.graphic" also has a Draw routine defined. Otherwise, the base
    module that calls Draw would not work and the module structure would make little sense.
   *)

BEGIN NEW(ptr); NEW(ptrext); ptr.handle := Handler1; ptrext.handle := Handler1;
  recext.x0 := 0; recext.x1 := 0; recext.x2 := 0; recext.x3 := 0; recext.x4 := 0; recext.x5 := 0; recext.x6 := 0;
  recext.y1 := 0; recext.y2 := 0; recext.y3 := 0; recext.y4 := 0
END M3.

ORP.Compile M3.Mod/s ~          ORTool.DecObj M3.rsc ~
System.Free M3 ~

M3.Go0       # call to a regular handler that is not a method

M3.Go1       # Method1 (caller AUTOMATICALLY passes the de-referenced ptr^ to a method which accepts a pointer)
M3.Go1b     # Method1 (caller EXPLICITLY de-references ptr^ BEFORE calling a method which accepts a pointer)

M3.Go2       # Method2 (caller AUTOMATICALLY passes the de-referenced ptr^ to a method which accepts a VAR record)
M3.Go2r     # Method2 (a statically declared global record can also be a receiver)
M3.Go2e     # Method2 (call a method that is bound to a record extension)

M3.Go3       # Method3 call (call of a method that is a function procedure)

M3.Go4r     # Method2 (a statically declared global record EXTENSION can also be a receiver)
M3.Go4e     # Method4 (call a method that is bound to a record extension)

M3.Go5       # Method5 (caller AUTOMATICALLY passes the de-referenced RECORD to a method which accepts a VAR record)
M3.Go5b     # Method5 (caller EXPLICITLY de-references record BEFORE calling a method which accepts a VAR record)
M3.Go5pe     # Method5 (ptr to an EXTENSION is passed to VAR param of a BASE type)

M3.Go6       # Method6 (caller AUTOMATICALLY passes the de-referenced ptr^ to a method which accepts a VAR record)
M3.Go6b     # Method6 (caller EXPLICITLY passes the de-referenced ptr^ to a method which accepts a VAR record)
M3.Go6pe     # Method6 (ptr to an extension is passed to a VAR param of a base type)
M3.Go6pd     # Method6 (dynamic type of receiver set to an extension through an assignment)
M3.Go6pdp   # Method6 (dynamic type of receiver set to an extension through an assignment AND and an overwritten method is called)
