MODULE M4;  (*test safe module unloading / AP 7.2.20 Extended Oberon*)
  IMPORT SYSTEM, M0, M1, M2, Out;

  (*pointer variable reference from a static (global) pointer variable to static module data*)

  PROCEDURE SetStaticPtrRef1*;
  BEGIN M1.SetStaticPtrRef(SYSTEM.ADR(M2.grec)); Out.Str("  creating a global pointer variable reference to M2 from a global pointer variable in M1"); Out.Ln
  END SetStaticPtrRef1;

  PROCEDURE UnSetStaticPtrRef1*;
  BEGIN M1.UnSetStaticPtrRef(); Out.Str("  removing the global pointer variable reference to M2 from a global pointer variable in M1"); Out.Ln
  END UnSetStaticPtrRef1;

  PROCEDURE SetStaticPtrRef2*;
  BEGIN M2.SetStaticPtrRef(SYSTEM.ADR(M1.grec)); Out.Str("  creating a global pointer variable reference to M1 from a global pointer variable in M2"); Out.Ln
  END SetStaticPtrRef2;

  PROCEDURE UnSetStaticPtrRef2*;
  BEGIN M2.UnSetStaticPtrRef(); Out.Str("  removing the global pointer variable reference to M1 from a global pointer variable in M2"); Out.Ln
  END UnSetStaticPtrRef2;

  (*pointer variable reference from a dynamic pointer variable in a dynamic *record* in the heap to static module data*)

  PROCEDURE SetDynamicPtrRef1*;
  BEGIN M1.SetDynamicPtrRef(SYSTEM.ADR(M2.grec)); Out.Str("  creating a dynamic pointer variable reference to M2 from a dynamic pointer variable reachable by M1"); Out.Ln
  END SetDynamicPtrRef1;

  PROCEDURE UnSetDynamicPtrRef1*;
  BEGIN M1.UnSetDynamicPtrRef(); Out.Str("  removing the dynamic pointer variable reference to M2 from a dynamic pointer variable reachable by M1"); Out.Ln
  END UnSetDynamicPtrRef1;

  PROCEDURE SetDynamicPtrRef2*;
  BEGIN M2.SetDynamicPtrRef(SYSTEM.ADR(M1.grec)); Out.Str("  creating a dynamic pointer variable reference to M1 from a dynamic pointer variable reachable by M2"); Out.Ln
  END SetDynamicPtrRef2;

  PROCEDURE UnSetDynamicPtrRef2*;
  BEGIN M2.UnSetDynamicPtrRef(); Out.Str("  removing the dynamic pointer variable reference to M1x from a dynamic pointer variable reachable by M2"); Out.Ln
  END UnSetDynamicPtrRef2;

  (*pointer variable reference from a dynamic pointer variable in a dynamic *array of record* in the heap to static module data*)

  PROCEDURE SetDynamicArrRecPtrRef1*;
  BEGIN M1.SetDynamicArrRecPtrRef(SYSTEM.ADR(M2.grec)); Out.Str("  creating a dynamic pointer variable reference to M2 from a dynamic array of record allocated by M1 in the heap"); Out.Ln
  END SetDynamicArrRecPtrRef1;

  PROCEDURE UnSetDynamicArrRecPtrRef1*;
  BEGIN M1.UnSetDynamicArrRecPtrRef(); Out.Str("  removing the dynamic pointer variable reference to M2 from a dynamic array of record allocated by M1 in the heap"); Out.Ln
  END UnSetDynamicArrRecPtrRef1;

  PROCEDURE SetDynamicArrRecPtrRef2*;
  BEGIN M2.SetDynamicArrRecPtrRef(SYSTEM.ADR(M1.grec)); Out.Str("  creating a dynamic pointer variable reference to M1 from a dynamic array of record allocated by M2 in the heap"); Out.Ln
  END SetDynamicArrRecPtrRef2;

  PROCEDURE UnSetDynamicArrRecPtrRef2*;
  BEGIN M2.UnSetDynamicArrRecPtrRef(); Out.Str("  removing the dynamic pointer variable reference to M1 from a dynamic array of record allocated by M2 in the heap"); Out.Ln
  END UnSetDynamicArrRecPtrRef2;

  (*pointer variable reference from a dynamic pointer variable in a dynamic *array of pointer* in the heap to static module data*)

  PROCEDURE SetDynamicArrPtrPtrRef1*;
  BEGIN M1.SetDynamicArrPtrPtrRef(SYSTEM.ADR(M2.grec)); Out.Str("  creating a dynamic pointer variable reference to M2 from a dynamic array of pointer allocated by M1 in the heap"); Out.Ln
  END SetDynamicArrPtrPtrRef1;

  PROCEDURE UnSetDynamicArrPtrPtrRef1*;
  BEGIN M1.UnSetDynamicArrPtrPtrRef(); Out.Str("  removing the dynamic pointer variable reference to M2 from a dynamic array of pointer allocated by M1 in the heap"); Out.Ln
  END UnSetDynamicArrPtrPtrRef1;

  PROCEDURE SetDynamicArrPtrPtrRef2*;
  BEGIN M2.SetDynamicArrPtrPtrRef(SYSTEM.ADR(M1.grec)); Out.Str("  creating a dynamic pointer variable reference to M1 from a dynamic array of pointer  allocated by M2 in the heap"); Out.Ln
  END SetDynamicArrPtrPtrRef2;

  PROCEDURE UnSetDynamicArrPtrPtrRef2*;
  BEGIN M2.UnSetDynamicArrPtrPtrRef(); Out.Str("  removing the dynamic pointer variable reference to M1 from a dynamic array of pointer allocated by M2 in the heap"); Out.Ln
  END UnSetDynamicArrPtrPtrRef2;

  PROCEDURE Init*;
  BEGIN Out.Str("  loading modules M0, M1, M2, M4"); Out.Ln
  END Init;

END M4.

--------------------------------------------------------------------------------------------------

ORP.Compile M0.Mod/s M1.Mod/s M2.Mod/s M4.Mod/s ~

#
# The following call sequences test pointer variables references from static or dynamic pointer variables to STATIC module data.
# Note that such references can only be created by resorting to low-level facilities (e.g., by using SYSTEM.VAL)
#

Call sequence #10:  (pointer variable reference from a static (global) pointer variable to static module data)

   M4.Init                             # load M0, M1, M2, M4
   System.ShowRefs M2 ~                # no references to M2 exist
   M4.SetStaticPtrRef1                 # set M1.sptr to ADR(M2.grec) (create a global pointer variable reference to M2 from a global pointer variable in M1)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (global variables of M2 referenced by global pointer variables of M1)
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (global variables of M2 referenced by global pointer variables of M1)
   M4.UnSetStaticPtrRef1               # set M1.sptr to NIL (remove the global pointer variable reference to M2 from a global pointer variable in M1)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M4 no longer loaded (only M0 and M1 remain loaded)

Call sequence #11:  (pointer variable reference from a dynamic pointer variable in a dynamic *record* in the heap to static module data)

   M4.Init                             # load M0, M1, M2, M4
   System.ShowRefs M2 ~                # no references to M2 exist
   M4.SetDynamicPtrRef1                # set M1.gptr.ptr to ADR(M2.grec) (create a dynamic pointer variable reference to M2 from a dynamic pointer variable allocated by M1 in the heap)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (static module data of M2 referenced by dynamic pointer variables reachable by M1)
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (static module data of M2 referenced by dynamic pointer variables reachable by M1)
   M4.UnSetDynamicPtrRef1              # set M1.gptr.ptr to NIL (remove the dynamic pointer variable reference to M2 from a dynamic pointer variable in a dynamic record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M4 no longer loaded (only M0 and M1 remain loaded)

Call sequence #12:  (pointer variable reference from a pointer variable in a dynamic *array of record* in the heap to static module data)

   M4.Init                             # load M0, M1, M2, M4
   System.ShowRefs M2 ~                # no references to M2 exist
   M4.SetDynamicArrRecPtrRef1          # set M1.gptrarr[2].ptr to ADR(M2.grec) (create a dynamic pointer variable reference to M2 from a dynamic array of record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (static module data of M2 referenced by dynamic pointer variables reachable by M1)
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (static module data of M2 referenced by dynamic pointer variables reachable by M1)
   M4.UnSetDynamicArrRecPtrRef1        # set M1.gptrarr[2].ptr to NIL (remove the dynamic pointer variable reference to M2 from a dynamic array of record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M4 no longer loaded (only M0 and M1 remain loaded)

Call sequence #13:  (pointer variable reference from a dynamic pointer variable in a dynamic *array of pointer* in the heap to static module data)

   M4.Init                             # load M0, M1, M2, M4
   System.ShowRefs M2 ~                # no references to M2 exist
   M4.SetDynamicArrPtrPtrRef1          # set M1.garrptr[3].to ADR(M2.grec) (create a dynamic pointer variable reference to M2 from a dynamic array of pointer allocated by M1 in the heap)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (static module data of M2 referenced by dynamic pointer variables reachable by M1)
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (static module data of M2 referenced by dynamic pointer variables reachable by M1)
   M4.UnSetDynamicArrPtrPtrRef1        # set M1.garrptr[3] to NIL (remove the dynamic pointer variable reference to M2 from a dynamic array of pointer allocated by M1 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M4 ~                    # M4 unloading successful (M4 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M4 no longer loaded (only M0 and M1 remain loaded)
