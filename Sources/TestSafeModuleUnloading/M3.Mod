MODULE M3;  (*test safe module unloading / AP 7.2.20 Extended Oberon*)
  IMPORT SYSTEM, M0, M1, M2, Out;

  PROCEDURE SetGlobalProc1*;
  BEGIN M1.SetGlobalProc(M2.P); Out.Str("  creating a global procedure variable reference to M2 from a global procedure variable in M1"); Out.Ln
  END SetGlobalProc1;

  PROCEDURE UnSetGlobalProc1*;
  BEGIN M1.SetGlobalProc(M1.P); Out.Str("  removing the global procedure variable reference to M2 from a global procedure variable in M1"); Out.Ln
  END UnSetGlobalProc1;

  PROCEDURE SetGlobalProc2*;
  BEGIN M2.SetGlobalProc(M1.P); Out.Str("  creating a global procedure variable reference to M1 from a global procedure variable in M2"); Out.Ln
  END SetGlobalProc2;

  PROCEDURE UnSetGlobalProc2*;
  BEGIN M2.SetGlobalProc(M2.P); Out.Str("  removing the global procedure variable reference to M1 from a global procedure variable in M2"); Out.Ln
  END UnSetGlobalProc2;

  PROCEDURE SetDynamicProc1*;
  BEGIN M1.SetDynamicProc(M2.P); Out.Str("  creating a dynamic procedure variable reference to M2 from a dynamic record allocated by M1 in the heap"); Out.Ln
  END SetDynamicProc1;

  PROCEDURE UnSetDynamicProc1*;
  BEGIN M1.SetDynamicProc(M1.P); Out.Str("  removing the dynamic procedure variable reference to M2 from a dynamic record allocated by M1 in the heap"); Out.Ln
  END UnSetDynamicProc1;

  PROCEDURE SetDynamicProc2*;
  BEGIN M2.SetDynamicProc(M1.P); Out.Str("  creating a dynamic procedure variable reference to M1 from a dynamic record allocated by M2 in the heap"); Out.Ln
  END SetDynamicProc2;

  PROCEDURE UnSetDynamicProc2*;
  BEGIN M2.SetDynamicProc(M2.P); Out.Str("  removing the dynamic procedure variable reference to M1 from a dynamic record allocated by M2 in the heap"); Out.Ln
  END UnSetDynamicProc2;

  PROCEDURE SetDynamicArrRec1*;
  BEGIN M1.SetDynamicArrRec(M2.P); Out.Str("  creating a dynamic procedure variable reference to M2 from a dynamic array of record allocated by M1 in the heap"); Out.Ln
  END SetDynamicArrRec1;

  PROCEDURE UnSetDynamicArrRec1*;
  BEGIN M1.SetDynamicArrRec(M1.P); Out.Str("  removing the dynamic procedure variable reference to M2 from a dynamic array of record allocated by M1 in the heap"); Out.Ln
  END UnSetDynamicArrRec1;

  PROCEDURE SetDynamicArrRec2*;
  BEGIN M2.SetDynamicArrRec(M1.P); Out.Str("  creating a dynamic procedure variable reference to M1 from a dynamic array of record allocated by M2 in the heap"); Out.Ln
   END SetDynamicArrRec2;

  PROCEDURE UnSetDynamicArrRec2*;
  BEGIN M2.SetDynamicArrRec(M2.P); Out.Str("  removing the dynamic procedure variable reference to M1 from a dynamic array of record allocated by M2 in the heap"); Out.Ln
  END UnSetDynamicArrRec2;

  PROCEDURE SetDynamicArrProc1*;
  BEGIN M1.SetDynamicArrProc(M2.P); Out.Str("  creating a dynamic procedure variable reference to M2 from a dynamic array of procedure allocated by M1 in the heap"); Out.Ln
  END SetDynamicArrProc1;

  PROCEDURE UnSetDynamicArrProc1*;
  BEGIN M1.SetDynamicArrProc(M1.P); Out.Str("  removing the dynamic procedure variable reference to M2 from a dynamic array of procedure allocated by M1 in the heap"); Out.Ln
  END UnSetDynamicArrProc1;

  PROCEDURE SetDynamicArrProc2*;
  BEGIN M2.SetDynamicArrProc(M1.P); Out.Str("  creating a dynamic procedure variable reference to M1 from a dynamic array of procedure allocated by M2 in the heap"); Out.Ln
  END SetDynamicArrProc2;

  PROCEDURE UnSetDynamicArrProc2*;
  BEGIN M2.SetDynamicArrProc(M2.P); Out.Str("  removing the dynamic procedure variable reference to M1 from a dynamic array of procedure allocated by M2 in the heap"); Out.Ln
  END UnSetDynamicArrProc2;

  PROCEDURE SetPtr1*;
    VAR p1: M1.Ptr; (*extension declared in M1 of a base type declared in M0*)
  BEGIN  (*insert p1 into a structure rooted in a variable of a base type declared in M0*)
    NEW(p1); M0.InsertPtr(p1); Out.Str("  creating a dynamic type reference to M1 from a dynamic record allocated by M0 in the heap"); Out.Ln
  END SetPtr1;

  PROCEDURE SetPtr2*;
    VAR p2: M2.Ptr; (*extension declared in M2 of a base type declared in M0*)
  BEGIN  (*insert p2 into a structure rooted in a variable of a base type declared in M0*)
    NEW(p2); M0.InsertPtr(p2); Out.Str("  creating a dynamic type reference to M2 from a dynamic record allocated by M0 in the heap"); Out.Ln
  END SetPtr2;

  PROCEDURE UnSetPtr1*;
  BEGIN M0.InitPtr; Out.Str("  removing the dynamic type reference to M1 from a dynamic record allocated by M0 in the heap"); Out.Ln
  END UnSetPtr1;

  PROCEDURE UnSetPtr2*;
  BEGIN M0.InitPtr; Out.Str("  removing the dynamic type reference to M2 from a dynamic record allocated by M0 in the heap"); Out.Ln
  END UnSetPtr2;

  PROCEDURE SetPtrArr1*;
    VAR p1: M1.PtrArr; (*extension declared in M1 of a base type declared in M0*)
  BEGIN  (*insert p1 into a structure rooted in a variable of a base type declared in M0*)
    NEW(p1, 20); M0.InsertArr(p1); Out.Str("  creating a dynamic type reference to M1 from a dynamic array allocated by M0 in the heap"); Out.Ln
  END SetPtrArr1;

  PROCEDURE SetPtrArr2*;
    VAR p2: M2.PtrArr; (*extension declared in M2 of a base type declared in M0*)
  BEGIN  (*insert p2 into a structure rooted in a variable of a base type declared in M0*)
    NEW(p2, 40); M0.InsertArr(p2); Out.Str("  creating a dynamic type reference to M2 from a dynamic array allocated by M0 in the heap"); Out.Ln
  END SetPtrArr2;

  PROCEDURE Init*;
  BEGIN Out.Str("  loading modules M0, M1, M2, M3"); Out.Ln
  END Init;

END M3.

--------------------------------------------------------------------------------------------------

ORP.Compile M0.Mod/s M1.Mod/s M2.Mod/s M3.Mod/s ~

Call sequence #1:  (no references among M1, M2, M3, but dynamic type references from M1 and M2 to M0 exist)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M0 ~                # references from M1 and M2 to M0 exist (types of M0 in use in dynamic objects reachable by M1, M2)
   System.ShowRefs M1 M2 M3 ~          # no references to any of M1, M2 or M3 exist
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading successful
   System.Free M1 ~                    # M1 unloading successful
   System.ShowRefs M0 ~                # no more references to M0 exist (as M1, M2, M3 have been unloaded)
   System.Free M0 ~                    # M0 unloading successful
   System.ShowModules                  # modules M0, M1, M2, M2 no longer loaded

Call sequence #2:  (procedure variable reference from a global procedure variable)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M2 ~                # no references to M2 exist
   M3.SetGlobalProc1                   # set M1.gproc to M2.P (create a global procedure variable reference to M2 from a global procedure variable in M1)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (procedures of M2 in use in global procedure variables of M1)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in global procedure variables of M1)
   M3.UnSetGlobalProc1                 # set M1.gproc to M1.P (remove the global procedure variable reference to M2 from a global procedure variable in M1)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M3 no longer loaded (only M0 and M1 remain loaded)

Call sequence #3:  (procedure variable reference from a dynamic *record* allocated in the heap)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M2 ~                # no references to M2 exist
   M3.SetDynamicProc1                  # set M1.gptr.proc to M2.P (create a dynamic procedure variable reference to M2 from a dynamic record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (procedures of M2 in use in dynamic objects reachable by M1)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in dynamic objects reachable by M1)
   M3.UnSetDynamicProc1                # set M1.gptr.proc to M1.P (remove the dynamic procedure variable reference to M2 from a dynamic record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M3 no longer loaded (only M0 and M1 remain loaded)

Call sequence #4:  (procedure variable reference from a dynamic *array of record* allocated in the heap)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M2 ~                # no references to M2 exist
   M3.SetDynamicArrRec1                # set M1.gptrarr[2].proc to M2.P (create a dynamic procedure variable reference to M2 from a dynamic array of record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (procedures of M2 in use in dynamic objects reachable by M1)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in dynamic objects reachable by M1)
   M3.UnSetDynamicArrRec1              # set M1.gptrarr[2].proc to M1.P (remove the dynamic procedure variable reference to M2 from a dynamic array of record allocated by M1 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M3 no longer loaded (only M0 and M1 remain loaded)

Call sequence #5:  (procedure variable reference from a dynamic *array of procedure*)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M2 ~                # no references to M2 exist
   M3.SetDynamicArrProc1               # set M1.garrproc[2] to M2.P (create a dynamic procedure variable reference to M2 from a dynamic array of procedure allocated by M1 in the heap)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (procedures of M2 in use in dynamic objects reachable by M1)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in dynamic objects reachable by M1)
   M3.UnSetDynamicArrProc1             # set M1.garrproc[2] to M2.P (remove the dynamic procedure variable reference to M2 from a dynamic array of procedure allocated by M1 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M1 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M3 no longer loaded (only M0 and M1 remain loaded)

Call sequence #6:  (type reference from a dynamic *record* allocated in the heap)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M2 ~                # no references to M2 exist
   M3.SetPtr2                          # insert a variable of type M2.Ptr into a data structure rooted in M0 (create a dynamic type reference to M2 from a dynamic record allocated by M0 in the heap)
   System.ShowRefs M2 ~                # references from M0 to M1 exist (types of M2 in use in dynamic objects reachable by M0)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (types of M2 in use in dynamic objects reachable by M0)
   M3.UnSetPtr2                        # clear the data structure in M0 (remove the dynamic type reference to M2 from a dynamic record allocated by M0 in the heap)
   System.ShowRefs M2 ~                # no more references to M2 exist
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading now successful (as the reference from M0 to M2 no longer exists)
   System.ShowModules                  # modules M2 and M3 no longer loaded (only M0 and M1 remain loaded)

Call sequence #7:  (unloading of a *group* of 2 modules containing *unidirectional* references among themselves)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M2 ~                # no references to M2 exist
   M3.SetGlobalProc1                   # set M1.gproc to M2.P (create a global procedure variable reference to M2 from a global procedure variable in M1)
   System.ShowRefs M2 ~                # references from M1 to M2 exist (procedures of M2 in use in global procedure variables of M1)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in global procedure variables of M1)
   System.ShowRefs M1 M2 ~             # references from M1 to M2 exist (procedures of M2 in use in global procedure variables of M1)
   System.ShowGroupRefs M1 M2 ~        # no (external) references to the modules M1 and M2 taken *as a group* exist
   System.Free M1 M2 ~                 # M2 M1 unloading taken *as a group* successful
   System.ShowModules                  # modules M1 and M2 no longer loaded (only M0 remains loaded)

Call sequence #8:  (unloading of a *group* of 2 modules containing *circular* references among themselves)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M1 M2 ~             # no references to any of M1 or M2 exist

   M3.SetGlobalProc1                   # set M1.gproc to M2.P (create a global procedure variable reference to M2 from a global procedure variable in M1)
   M3.SetGlobalProc2                   # set M2.gproc to M1.P (create a global procedure variable reference to M1 from a global procedure variable in M2)

   M3.SetDynamicProc1                  # set M1.gptr.proc to M2.P (create a dynamic procedure variable reference to M2 from a dynamic record allocated by M1 in the heap)
   M3.SetDynamicProc2                  # set M2.gptr.proc to M1.P (create a dynamic procedure variable reference to M1 from a dynamic record allocated by M2 in the heap)

   System.ShowRefs M1 M2 ~             # circular references among M1 and M2 exist (in both directions)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M1 ~                    # M1 unloading failed (procedures of M1 in use in dynamic *and* global procedure variables of M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in dynamic *and* global procedure variables of M1)
   System.ShowGroupRefs M1 M2 ~        # no (external) references to modules M1 and M2 taken *as a group* exist
   System.Free M1 M2 ~                 # M2 M1 unloading taken *as a group* successful
   System.ShowModules                  # modules M1 and M2 no longer loaded (only M0 remains loaded)

Call sequence #9:  (unloading of a *group* of 3 modules containing *circular* references among themselves)

   M3.Init                             # load M0, M1, M2, M3
   System.ShowRefs M1 M2 M3 ~          # no references to any of M1, M2 or M3 exist

   M3.SetGlobalProc1                   # set M1.gproc to M2.P (create a global procedure variable reference to M2 from a global procedure variable in M1)
   M3.SetGlobalProc2                   # set M2.gproc to M1.P (create a global procedure variable reference to M1 from a global procedure variable in M2)

   M3.SetDynamicProc1                  # set M1.gptr.proc to M2.P (create a dynamic procedure variable reference to M2 from a dynamic record allocated by M1 in the heap)
   M3.SetDynamicProc2                  # set M2.gptr.proc to M1.P (create a dynamic procedure variable reference to M1 from a dynamic record allocated by M2 in the heap)

   M3.SetPtr1                          # insert a variable of type M1.Ptr into a data structure rooted in M0 (create a dynamic type reference to M1 from a dynamic record allocated by M0 in the heap)
   M3.SetPtr2                          # insert a variable of type M2.Ptr into a data structure rooted in M0 (create a dynamic type reference to M2 from a dynamic record allocated by M0 in the heap)

   System.ShowRefs M0 M1 M2 M3 ~       # circular references among M0, M1, M2, M3 exist (in multiple directions)
   System.Free M3 ~                    # M3 unloading successful (M3 is a client of M0, M1, M2)
   System.Free M1 ~                    # M1 unloading failed (types of M1 in use in dynamic objects of M0, procedures of M1 in use in dynamic and global procedure variables of M2)
   System.Free M2 ~                    # M2 unloading failed (procedures of M2 in use in dynamic and global procedure variables of M1)
   System.Free M2 M1 ~                 # M2 M1 unloading *as a group* failed (types of M1 in use in dynamic objects reachable by M0)
   System.Free M2 M0 ~                 # M2 M0 unloading *as a group* failed (types of M0 in use in dynamic objects reachable by M1, procedures of M2 in use in dynamic and global objects of M1)
   System.Free M1 M0 ~                 # M1 M0 unloading *as a group* failed (types of M0 in use in dynamic objects reachable by M2, procedures of M1 in use in dynamic and global objects of M2)
   System.ShowGroupRefs M1 M2 ~        # references from M0 to the modules M1 and M2 taken *as a group* exist (types of M1 in use in dynamic objects reachable by M0)
   System.Free M1 M2 ~                 # M2 M1 unloading taken *as a group* failed (types of M1 in use in dynamic objects reachable by M0)
   System.ShowGroupRefs M0 M1 M2 ~     # no (external) references to modules M0, M1 and M2 taken *as a group* exist
   System.Free M0 M1 M2 ~              # M2 M1 M0 unloading taken *as a group* successful
   System.ShowModules                  # modules M0, M1, M2 and M3 no longer loaded

#
# See module M4.Mod for additional call sequences
#
