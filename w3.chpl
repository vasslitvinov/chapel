//wass: not for PR

var DD = {112..113};
var BB: [DD] int = [320, 340];
type BBT = BB.type;
proc showType(type STT) { compilerWarning(STT:string); }

proc main {
  /// basic declarations
  var A1: [DD] int;      // A1 <- newRayDI(DD, int)
  var A2: [DD] int = BB; // A2 <- chpl__coerceCopy(DD, int, BB, isCst)
  writeln(A1);           // prints 0 0
  writeln(A2);           // prints 320 340

  // split initialization
  var A5: [DD] int;
  var A6: [DD] int;
  A5 = BB;
  A6 = 560;
  writeln(A5);           // prints 320 340
  writeln(A6);           // prints 560 560

  showType([DD] real);   // [domain(1,int(64),one)] real(64)
  type t11 = BB.type;
  showType(t11);         // [domain(1,int(64),one)] int(64)
  type t22 = [DD] bool;
  showType(t22);         // [domain(1,int(64),one)] bool
}
