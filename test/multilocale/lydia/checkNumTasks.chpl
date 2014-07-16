var num: atomic int;
forall loc in Locales {
  num.add(here.runningTasks());
}

if (num.read() > numLocales) {
  writeln("Error: there was (were) ", num.read() - numLocales, " additional task(s) created");
} else {
  writeln("Success: each locale had only one task");
 }
