MODULE Oberon0Tool; (*AP 7.2.20*)
  IMPORT Texts, Oberon, Oberon0;
  VAR T: Oberon.Task;
    W: Texts.Writer;

  PROCEDURE Run*;
  BEGIN Oberon.Install(T); Texts.WriteString(W, "Oberon0 started");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Run;

  PROCEDURE Stop*;
  BEGIN Oberon.Remove(T); Texts.WriteString(W, "Oberon0 stopped");
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END Stop;

BEGIN Texts.OpenWriter(W); T := Oberon.NewTask(Oberon0.Task, 0)
END Oberon0Tool.
