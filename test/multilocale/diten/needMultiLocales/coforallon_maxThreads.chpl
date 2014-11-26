use Time;

proc main {
  var a: sync int = 0;
  forall loc in Locales {
    sleep(2);
    a += 1;
  }
  writeln(a.readFF());
}
