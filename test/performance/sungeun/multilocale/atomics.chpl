use CommDiagnostics;

var au: atomic uint;
resetCommDiagnostics();
startCommDiagnostics();
forall l in Locales {
  var x = au.fetchAdd(l.id:uint);
}
stopCommDiagnostics();
writeln(getCommDiagnostics());

var ai: atomic int;
ai.write(-1);
resetCommDiagnostics();
startCommDiagnostics();
forall l in Locales {
  var x = ai.compareExchangeStrong(l.id-1, l.id);
}
stopCommDiagnostics();
writeln(getCommDiagnostics());

var ab: atomic bool;
resetCommDiagnostics();
startCommDiagnostics();
forall l in Locales {
  var f = ab.testAndSet();
}
stopCommDiagnostics();
writeln(getCommDiagnostics());

