System.Open ^ System.Recall System.Flush System.Watch System.Collect
Edit.Open ^  Edit.Recall                            System.ShowDisplays
Edit.ChangeFont Oberon8.Scn.Fnt            System.OpenDisplay name
Edit.ChangeFont Oberon10i.Scn.Fnt         System.SetDisplayName 1 new
Edit.ChangeFont Oberon10b.Scn.Fnt        System.SetDisplay 1
Edit.ChangeFont Oberon12.Scn.Fnt          System.CloseDisplay 1
Edit.ChangeFont Oberon16.Scn.Fnt          System.NextDisplay
Edit.ChangeFont Times24.Scn.Fnt             System.PrevDisplay

System.Directory ^
  *.Mod  *.Bak  *.Tool  *.Text  *.Scn.Fnt  *.smb  *.rsc  *.bin  *.mem

ORP.Compile @  ORP.Compile @/s  ORP.Compile ^/s ORP.Compile ~
System.Free ~  # free modules as a group, /f hides modules if refs exist
System.Open Draw.Tool      System.Batch ~
System.CopyFiles ~
System.RenameFiles ~         Stars.Open Stars.Run System.Free Stars~
System.DeleteFiles ~           14.ShowModules  *Stars.Stop

System.ShowModules  System.ShowCommands ^  Modules.Collect
System.ShowImports ORP~  System.ShowReferences Hilbert Sierpinski ~
System.ShowClients ORS~  System.ShowGroupReferences Hilbert Viewers ~
                                
PCLink1.Run  PCLink1.Stop    Oberon0Tool.Run  Oberon0Tool.Stop  # run only of of these 2
Hilbert.Draw  Sierpinski.Draw  Blink.Run  Stars.Open
Tools.Inspect 0  Tools.Sector 1  Tools.ShowFile
Tools.Recall  Tools.Clear  FontTool.Show Oberon10.Scn.Fnt ~

# --------------- building the system ---------------

ORP.Compile ORS.Mod/s ORB.Mod/s ~         Edit.Open Build.Tool ~
ORP.Compile ORG.Mod/s ORP.Mod/s ~
ORP.Compile ORL.Mod/s ORX.Mod/s ORTool.Mod/s ~
System.Free ORTool ORP ORG ORB ORS ORL ORX ~

ORP.Compile Kernel.Mod/s Disk.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
ORL.Link Modules ~            # generate a regular boot file
ORL.Load Modules.bin ~     # load the boot file onto the boot area

ORP.Compile Input.Mod/s Display.Mod/s Viewers.Mod/s ~
ORP.Compile Fonts.Mod/s Texts.Mod/s ~
ORP.Compile Oberon.Mod/s ~                      Edit.Open Oberon.Mod
ORP.Compile MenuViewers.Mod/s ~             Edit.Open MenuViewers.Mod
ORP.Compile TextFrames.Mod/s ~                Edit.Open TextFrames.Mod
ORP.Compile System.Mod/s Edit.Mod/s ~          Edit.Open System.Mod
ORP.Compile Tools.Mod/s FontTool.Mod/s ~      Edit.Open Edit.Mod

ORP.Compile PCLink1.Mod/s Clipboard.Mod/s In.Mod/s Out.Mod/s ~
ORP.Compile RS232.Mod/s SCC.Mod/s Net.Mod/s ~

ORP.Compile Graphics.Mod/s GraphicFrames.Mod/s ~
ORP.Compile GraphTool.Mod/s MacroTool.Mod/s Draw.Mod/s ~

ORP.Compile Curves.Mod/s Sierpinski.Mod/s ~
ORP.Compile Hilbert.Mod/s Stars.Mod/s ~
ORP.Compile Rectangles.Mod/s Checkers.Mod/s ~
ORP.Compile Math.Mod/s PIO.Mod/s Blink.Mod/s ~

# ---------- building the system with a single mouse click ----------

Oberon.Batch
  ORP.Compile Kernel.Mod/s Disk.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
  ORL.Link Modules ~
  ORL.Load Modules.bin ~

  ORP.Compile Input.Mod/s Display.Mod/s Viewers.Mod/s ~
  ORP.Compile Fonts.Mod/s Texts.Mod/s ~
  ORP.Compile Oberon.Mod/s ~
  ORP.Compile MenuViewers.Mod/s ~
  ORP.Compile TextFrames.Mod/s ~
  ORP.Compile System.Mod/s Edit.Mod/s ~
  ORP.Compile Tools.Mod/s FontTool.Mod/s ~

  ORP.Compile ORS.Mod/s ORB.Mod/s ~
  ORP.Compile ORG.Mod/s ORP.Mod/s ~
  ORP.Compile ORL.Mod/s ORX.Mod/s ORTool.Mod/s ~

  ORP.Compile PCLink1.Mod/s Clipboard.Mod/s In.Mod/s Out.Mod/s ~
  ORP.Compile RS232.Mod/s SCC.Mod/s Net.Mod/s ~

  ORP.Compile Graphics.Mod/s GraphicFrames.Mod/s ~
  ORP.Compile GraphTool.Mod/s MacroTool.Mod/s Draw.Mod/s ~

  ORP.Compile Curves.Mod/s Sierpinski.Mod/s ~
  ORP.Compile Hilbert.Mod/s Stars.Mod/s ~
  ORP.Compile Rectangles.Mod/s Checkers.Mod/s ~
  ORP.Compile Math.Mod/s PIO.Mod/s Blink.Mod/s ~
  ORP.Compile EBNF.Mod/s RISC.Mod/s ~

  ORP.Compile BootLoad.Mod/s BootLoadDisk.Mod/s BootLoadLine.Mod/s ~

  ORP.Compile ORC.Mod/s PCLink0.Mod/s Oberon0.Mod/s Oberon0Tool.Mod/s ~
  ORL.Link Oberon0 ~

  ORP.Compile System1.Mod/s ~
  ORL.Link System1 ~
~
