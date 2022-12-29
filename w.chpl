//wass: not for PR

// The following, esp. VC2.init() / this.arr, highlights the problem
// that is experienced, for example, in RootLocale.init() / this.myLocales
// where the underlying array is autoDestroy-ed right after it is stored
// in the myLocales field.

var DD = {1..5};

record MR {
  var kkk=555;
  proc init() { writeln("MR.init"); }
  proc deinit() { writeln("MR.deinit"); }
}

class VC {
  var jjj: int;
  var mre: MR;
  var arr: [DD] int;
  proc init() {
    super.init();
this.complete();
//compilerError("VASS-w1");
//private use ChapelDebugPrint;
//chpl_debug_writeln("w1 RootLocale.init");
use CTypes;
extern proc printf(format, arg);
printf("VC.init %p\n", c_ptrTo(arr[1]));
  }
}

proc main {
  var vvc = new unmanaged VC();
  var vvc2 = new unmanaged VC2();
}

proc makeMR() return new MR();
proc makeArr() { var res: [DD] int; return res; }

// clearer view of the problem than VC
class VC2 {
  var jjj: int;
  var mka = makeArr();
  var arr: [DD] int;
  proc init() { }
}

/* temporarily using this file for the above instead
var DD = {1..5};
var BB: [DD] int;
type BBT = BB.type;

proc main {
  var A1: [DD] int;      // A1 <- newRayDI(DD, int)
  var A2: [DD] int = BB; // A2 <- chpl__coerceCopy(DD, int, BB, isCst)
  var A3: BBT      = BB; // BBT will be a static type
  //var A4: BBT = 5;     // error "need []-type, not BBT"
  writeln(A1, A2, A3);
}
*/

// WASS CONTINUE HERE: halts at runtime
// WASS NEXT: asdf([DD] int)
