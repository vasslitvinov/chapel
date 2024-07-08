use CommDiagnostics, Time;

config const n = 100;

startCommDiagnostics();
on Locales[numLocales-1] {
  for i in 1..n {
    dateTime.createFromTimestamp(i);
  }
}
stopCommDiagnostics();
printCommDiagnosticsTable();
