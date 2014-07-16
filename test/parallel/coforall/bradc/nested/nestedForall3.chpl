use DSIUtil;

config const numTasks=4;

forall loc in Locales {
  coforall taskid in 0..#numTasks {
    const (lo,hi) = _computeBlock(1, numTasks, taskid, loc.id, loc.id, loc.id);
    writeln("yielding ", {lo..hi});
  }
}

