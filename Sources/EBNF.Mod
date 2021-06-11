MODULE EBNF;  (*NW 3.9.97 / 12.9.97 / 1.3.2014 / AP 15.9.20 Extended Oberon*)
  IMPORT Texts, Oberon;

  CONST IdLen = 16; TAB = 09X;
    ident = 0; literal = 2; lparen = 3; lbrak = 4; lbrace = 5; bar = 6; eql = 7;
    rparen = 8; rbrak = 9; rbrace = 10; period = 11; other = 12;

  TYPE Identifier = ARRAY IdLen OF CHAR;

  (*tag values: 0 = tsym, 1 = ntsym, 2 = option, 3 = iteration, 4 = catenation, 5 = alternate*)

    Item = POINTER TO ItemDesc;
    ItemDesc = RECORD
        tag, flag0, flag1: INTEGER;
        u, v: Item
      END ;

    Symbol = POINTER TO SymbolDesc;
    SymbolDesc = RECORD (ItemDesc)
        id: Identifier;
        no: INTEGER;
        first, crit: SET;
        next: Symbol
      END ;

  VAR ch: CHAR;
    sym: INTEGER;
    lastpos: LONGINT;
    tsno, ntsno: INTEGER;
    id: Identifier;
    root, curs: Symbol;
    R: Texts.Reader;
    W: Texts.Writer;

  PROCEDURE error(n: INTEGER);
    VAR pos: LONGINT;
  BEGIN pos := Texts.Pos(R);
    IF pos > lastpos THEN
      Texts.WriteString(W, "  pos"); Texts.WriteInt(W, pos, 6);
      Texts.WriteString(W, "  err"); Texts.WriteInt(W, n, 4); lastpos := pos;
      Texts.WriteString(W, "  sym "); Texts.WriteInt(W, sym, 4);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END error;

  PROCEDURE This(VAR ident: Identifier; tag: INTEGER): Symbol;
    VAR s: Symbol;   (*find or enter symbol in list*)
  BEGIN s := root;

    WHILE (s # NIL) & (s.id # ident) DO s := s.next END ;
    IF s = NIL THEN
      NEW(s); s.id := ident; s.tag := tag;
      IF tag = 0 THEN s.no := tsno; INC(tsno) ELSE s.no := ntsno; INC(ntsno) END ;
      s.next := root; root := s
    END ;
    RETURN s
  END This;

  PROCEDURE New(t: INTEGER; x, y: Item): Item;
    VAR z: Item;
  BEGIN NEW(z); z.tag := t; z.u := x; z.v := y; RETURN z
  END New;

  (*------------------- scanner --------------------*)

  PROCEDURE GetSym;
    VAR i: INTEGER;
  BEGIN
    WHILE ~R.eot & (ch <= " ") DO Texts.Read(R, ch) END ;
    IF (ch >= "a") & (ch <= "z") OR (ch >= "A") & (ch <= "Z") THEN
      sym := ident; i := 0;
      REPEAT
        IF i < IdLen-1 THEN id[i] := ch; INC(i) END ;
        Texts.Read(R, ch)
      UNTIL ~((ch >= "a") & (ch <= "z") OR (ch >= "A") & (ch <= "Z"));
      id[i] := 0X
    ELSE
      IF ch = 22X THEN
        Texts.Read(R, ch); sym := literal; i := 0;
        REPEAT (*at least one char*)
          IF i < IdLen-1 THEN id[i] := ch; INC(i) END ;
          Texts.Read(R, ch)
        UNTIL (ch = 22X) OR (ch <= " ");
        IF ch <= " " THEN error(1) END ;
        id[i] := 0X
      ELSIF ch = "=" THEN sym := eql
      ELSIF ch = "(" THEN sym := lparen
      ELSIF ch = ")" THEN sym := rparen
      ELSIF ch = "[" THEN sym := lbrak
      ELSIF ch = "]" THEN sym := rbrak
      ELSIF ch = "{" THEN sym := lbrace
      ELSIF ch = "}" THEN sym := rbrace
      ELSIF ch = "|" THEN sym := bar
      ELSIF ch = "." THEN sym := period
      ELSE sym := other
      END ;
      Texts.Read(R, ch)
    END
  END GetSym;

  (*-------------------- parser ---------------------*)

  PROCEDURE expression(VAR x: Item);
    VAR y: Item;

    PROCEDURE term(VAR x: Item);
      VAR y: Item;

      PROCEDURE factor(VAR x: Item);
        VAR y: Item;
      BEGIN
        IF sym = literal THEN x := This(id, 0); GetSym
        ELSIF sym = ident THEN x := This(id, 1); GetSym
        ELSIF sym = lparen THEN
          GetSym; expression(x);
          IF sym = rparen THEN GetSym ELSE error(2) END
        ELSIF sym = lbrak THEN
          GetSym; expression(y); x := New(2, NIL, y);
          IF sym = rbrak THEN GetSym ELSE error(3) END
        ELSIF sym = lbrace THEN
          GetSym; expression(y); x := New(3, NIL, y);
          IF sym = rbrace THEN GetSym ELSE error(4) END
        ELSE error(5)
        END
      END factor;

    BEGIN (*term*) factor(x);
      IF sym < bar THEN term(y); x := New(4, x, y) END
    END term;

  BEGIN (*expression*) term(x);
    IF sym = bar THEN GetSym; expression(y); x := New(5, x, y) END
  END expression;

  PROCEDURE production;
    VAR s: Symbol;
  BEGIN (*sym = ident*)
    s := This(id, 1); GetSym;
    IF sym = eql THEN GetSym ELSE error(7) END ;
    expression(s.v);
    IF sym = period THEN GetSym ELSE error(8) END
  END production;

  PROCEDURE syntax(T: Texts.Text; pos: LONGINT);
  BEGIN Texts.OpenReader(R, T, pos);  Texts.Read(R, ch);
    tsno := 0; ntsno := 0; lastpos := 0; GetSym;
    WHILE sym = ident DO production END ;
    Texts.WriteString(W, "compiled"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END syntax;

  PROCEDURE Compile*;
    VAR beg, end, time: LONGINT;
      T: Texts.Text;
      S: Texts.Scanner;
  BEGIN root := NIL;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "@") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN syntax(T, beg) END
    END
  END Compile;

  (*------------------ List symbols -------------------*)

  PROCEDURE List*;
    VAR s: Symbol;
  BEGIN Texts.WriteString(W, "Nonterminals:"); Texts.WriteLn(W); s := root;
    WHILE s # NIL DO
      IF s.tag = 1 THEN Texts.Write(W, TAB); Texts.WriteString(W, s.id); Texts.WriteLn(W) END ;
      s := s.next
    END ;
    Texts.WriteString(W, "Terminals:"); Texts.WriteLn(W); s := root;
    WHILE s # NIL DO
      IF s.tag = 0 THEN Texts.Write(W, TAB); Texts.WriteString(W, s.id); Texts.WriteLn(W) END ;
      s := s.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END List;

  (*------------------ Tabulate syntax tree -------------------*)

  PROCEDURE traverse(x: Item);
    VAR t: INTEGER;
  BEGIN
    IF x # NIL THEN t := x.tag;
      IF t = 0 THEN Texts.Write(W, 22X); Texts.WriteString(W, x(Symbol).id); Texts.Write(W, 22X)
      ELSIF t = 1 THEN Texts.WriteString(W, x(Symbol).id)
      ELSIF t = 2 THEN Texts.Write(W, "?"); traverse(x.v)
      ELSIF t = 3 THEN Texts.Write(W, "!"); traverse(x.v)
      ELSE Texts.Write(W, "("); traverse(x.u);
        IF t = 4 THEN Texts.Write(W, " ") ELSE Texts.Write(W, "|") END ;
        traverse(x.v); Texts.Write(W, ")")
      END
    END
  END traverse;

  PROCEDURE Tabulate*;
    VAR s: Symbol;
  BEGIN s := root;
    WHILE s # NIL DO
      IF s.tag = 1 THEN
        Texts.WriteString(W, s.id); Texts.WriteString(W, " =  "); traverse(s.v); Texts.WriteLn(W)
      END ;
      s := s.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END Tabulate;

  (*------------------ Find sets of first symbols -------------------*)

  PROCEDURE WriteSet(VAR id: ARRAY OF CHAR; s: SET);
    VAR x: Symbol;
  BEGIN Texts.Write(W, TAB); Texts.WriteString(W, id); Texts.WriteString(W, " :: ");
    x := root;
    WHILE (s # {}) & (x # NIL) DO
      IF (x.tag = 0) & (x.no IN s) THEN Texts.Write(W, " "); Texts.WriteString(W, x.id); EXCL(s, x.no) END ;
      x := x.next
    END ;
    Texts.WriteLn(W)
  END WriteSet;

  PROCEDURE first(x: Item): SET;
    VAR t: INTEGER; s, a, b: SET; save: Symbol;
  BEGIN
    IF x # NIL THEN t := x.tag;
      IF t = 0 THEN s := {x(Symbol).no}
      ELSIF t = 1 THEN
        IF x.flag0 = 0 THEN x.flag0 := 1; save := curs; curs := x(Symbol);
          s := first(x.v); x.flag0 := 2; x(Symbol).first := s; curs := save
        ELSIF x.flag0 > 1 THEN s := x(Symbol).first
        END
      ELSIF t <= 3 THEN s := first(x.v)
      ELSIF t = 4 THEN s := first(x.u);
        IF x.u.tag IN {2, 3} THEN s := first(x.u.v) + first(x.v) ELSE s := first(x.u) END
      ELSIF x.tag = 5 THEN
        a := first(x.u); b := first(x.v); s := a+b;
        IF a*b # {} THEN
          Texts.WriteString(W, "error A in "); WriteSet(curs.id, a/b); Texts.WriteLn(W)
        END
      END
    ELSE s := {}
    END ;
    RETURN s
  END first;

  PROCEDURE First*;
    VAR s: Symbol;
  BEGIN Texts.WriteString(W, "First symbols:"); Texts.WriteLn(W); s := root;
    WHILE s # NIL DO
      IF s.tag = 1 THEN curs := s; s.first := first(s.v); WriteSet(s.id, s.first) END ;
      s := s.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END First;

  (*------------------ Find sets of follow symbols -------------------*)

  PROCEDURE critical(x: Item): SET;
    VAR t: INTEGER; s: SET;
  BEGIN
    IF x # NIL THEN t := x.tag;
      IF t = 0 THEN s := {}
      ELSIF t = 1 THEN
        IF x.flag1 = 0 THEN x.flag1 := 1; x(Symbol).crit := critical(x.v) END ;
        s := x(Symbol).crit
      ELSIF t <= 3 THEN s := first(x.v)
      ELSIF t = 4 THEN s := critical(x.v)
      ELSIF t = 5 THEN s := critical(x.u) + critical(x.v)
      END
    ELSE s := {}
    END ;
    RETURN s
  END critical;

  PROCEDURE pair(x: Item);
  BEGIN
    IF (x # NIL) & (x.tag >= 2) THEN
      pair(x.u); pair(x.v);
      IF (x.tag = 4) & (x.u.tag = 1) THEN
        IF first(x.v) * x.u(Symbol).crit # {} THEN
          Texts.WriteString(W, " clash "); WriteSet(x.u(Symbol).id, x.u(Symbol).crit);
          Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
        END
      END
    END
  END pair;

  PROCEDURE Follow*;
    VAR s: Symbol;
  BEGIN Texts.WriteString(W, "Non-follow symbols:"); Texts.WriteLn(W); s := root;
    WHILE s # NIL DO
      IF s.tag = 1 THEN curs := s; s.crit := critical(s.v) END ;
      s := s.next
    END ;
    s := root;
    WHILE s # NIL DO
      IF s.tag = 1 THEN WriteSet(s.id, s.crit) END ;

      s := s.next
    END ;
    s := root;
    WHILE s # NIL DO
      IF s.tag = 1 THEN pair(s.v) END ;
      s := s.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END Follow;

BEGIN Texts.OpenWriter(W)
END EBNF.

EBNF.Compile @  EBNF.List  EBNF.Tabulate  EBNF.First  EBNF.Follow

Syntax  =  {Production} .
Production  =  "id" "=" Expression "." .
Expression  =  Term {"|" Term}.
Term  =  Factor {Factor}.
Factor  =  "id" | "lit" | "(" Expression ")" | "[" Expression "]" | "{" Expression "}" .
~

S  =  A | B.
A  =  "0" | "2".
B  =  "1" | "3".
~

S  =  A B.
A  =  "0" {"0"}.
B  =  "1" | "2".
~

S  =  A B C.
A  =  "0" {"0"}.
B  =  "1" {"1"}.
C  =  "2" | "3".
~

S  =  A B.
A  =  "*".
B  =  {"0"} {"1"} ("2" | "3").
~

syntax  =  expression {"," expression} .
expression  =  ["+" | "-"] term {("+" | "-") term}.
term  =  factor {("*" | "/") factor}.
factor  =  "id" | "(" expression ")" .
~

syntax  =  {production} .
production  =  "id" "=" expression "." .
expression  =  term ["|" expression].
term  =  factor [term].
factor  =  "id" | "lit" | "(" expression ")" | "[" expression "]" | "{" expression "}" .
~

syntax  =  {production} .
production  =  "id" "=" expression "." .
expression  =  term {"|" term}.
term  =  factor {factor}.

factor  =  "id" | "lit" | "(" expression ")" | "[" expression "]" | "{" expression "}" .
~

primary  =  "variable" | "number" | "(" arithExp ")" .
factor  =  primary | factor "^" primary.
term  =  factor | term ("*" | "/" | "DIV") factor.
simArithExp  =  term | ("+" | "-") term | simArithExp ("+" | "-") term.
arithExp  =  simArithExp | "IF" BoolExp "THEN" simArithExp "ELSE" arithExp.
relOp  =  "<" | "<=" | "=" | ">=" | ">" | "#" .
relation  =  arithExp relOp arithExp.
BoolPrimary  =  "TRUE" | "FALSE" | "variable" | relation | "(" BoolExp ")".
BoolSec  =  BoolPrimary | "~" BoolPrimary.
BoolFactor  =  BoolSec | BoolFactor "&" BoolSec.
BoolTerm  =  BoolFactor | BoolTerm "|" BoolFactor.
implication  =  BoolTerm | implication "=>" BooleanTerm.
simpleBoolean  =  implication | simpleBoolean "==" implication.
BoolExp  =  simpleBoolean | "IF" BoolExp "THEN" simpleBoolean "ELSE" BoolExp.
expression  =  arithExp | BoolExp .
~

primary  =  "variable" | "number" | "(" arithExp ")" .
factor  =  primary {"^" primary}.
term  =  factor {("*" | "/" | "DIV") factor}.
simArithExp  =  ["+" | "-"] term {("+" | "-") term}.
arithExp  =  simArithExp | "IF" BoolExp "THEN" simArithExp "ELSE" arithExp.
relOp  =  "<" | "<=" | "=" | ">=" | ">" | "#" .
relation  =  arithExp relOp arithExp.
BoolPrimary  =  "TRUE" | "FALSE" | "Bvariable" | relation | "[" BoolExp "]".
BoolSec  =  ["~"] BoolPrimary.
BoolFactor  =  BoolSec {"&" BoolSec}.
BoolTerm  =  BoolFactor {"|" BoolFactor}.
implication  =  BoolTerm {"=>" BooleanTerm}.
simBoolExp  =  implication {"==" implication}.
BoolExp  =  simBoolExp | "IFB" BoolExp "THEN" simBoolExp "ELSE" BoolExp.
~ 