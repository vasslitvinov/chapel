//wass: not for PR

var DD = {112..113};
var BB: [DD] int = [320, 340];
type BBT = BB.type;
proc showType(type STT) { compilerWarning(STT:string); }

proc main {
  /// basic declarations
  var A1: [DD] int;      // A1 <- newRayDI(DD, int)
  var A2: [DD] int = BB; // A2 <- chpl__coerceCopy(DD, int, BB, isCst)
  //var A3: BBT = BB;    // TODO: BBT will be a static type
  //var A4: BBT = 5;     // error "need []-type, not BBT"

  // split initialization
  var A5: [DD] int;
  var A6: [DD] int;
  writeln(A1, A2);
  A5 = BB;
  A6 = 560;
  writeln(A5, A6);

  showType([DD] real);
  type t11 = BB.type;
  showType(t11);
  type t22 = [DD] bool;
  showType(t22);

  // multi-var decl
  var A7, A8, A9: [DD] int;
  writeln(A7, A8, A9);

  // CONTINUE HERE: a mix of default- and split-init
  var A11, A12: [DD] int;
  writeln(A11);
  A12 = A11;
  writeln(A12);
}
