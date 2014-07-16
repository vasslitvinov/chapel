config const numTasks=4;

iter leadfollow() {
  for i in 0..numLocales do
    yield i;
}

iter leadfollow(param tag: iterKind) where tag == iterKind.leader {
  forall loc in Locales {
    coforall taskid in 0..#numTasks {
      const lo = loc.id*numTasks + taskid;
      yield lo;
    }
  }
}

iter leadfollow(param tag: iterKind, followThis) where tag == iterKind.follower {
  yield followThis;
}


forall i in leadfollow() {
  writeln(here.id, " got ", i);
}
