//wass: not for PR

var DD = {1..3};
var BB: [DD] int;
type BBT = BB.type;

proc main {
  var A1: [DD] int;      // A1 <- newRayDI(DD, int)
  writeln(A1);           // prints: 0 0 0

  BB[2] = 2;

  var A2: [DD] int = BB; // A2 <- chpl__coerceCopy(DD, int, BB, isCst)
  writeln(A2);           // prints: 0 2 0

  var A3: BBT      = BB; // BBT will be a static type
  writeln(A3);           // prints: 0 2 0
}
