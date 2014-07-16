// coforallOnByRef.chpl
//
// This program demonstrates that reference-counted variables shared across a
// coforall need not have their reference counts adjusted.
//
// [copied from streamEP.chpl]
//

use CommDiagnostics;

proc main() {
  var validAnswers: [LocaleSpace] bool;
resetCommDiagnostics();
startCommDiagnostics();
startVerboseComm();
  forall loc in Locales {
    //validAnswers[here.id] = true;
    //writeln("LocaleSpace loc = ", Locales._value.dom.locale.id);
    //writeln("x ", here.id, " ", loc.locale.id, " ", Locales._value.locale.id, " ", Locales._value.dom.backingDom.locale.id);
  }
stopVerboseComm();
stopCommDiagnostics();
writeln(getCommDiagnostics());
}
