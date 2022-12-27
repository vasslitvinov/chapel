//wass: not for PR

var DD = {1..5};
var BB: [DD] int;
type BBT = BB.type;

proc main {
  var A1: [DD] int;      // A1 <- newRayDI(DD, int)
  var A2: [DD] int = BB; // A2 <- chpl__coerceCopy(DD, int, BB, isCst) WASS CONTINUE HERE
  var A3: BBT      = BB; // BBT will be a static type
  var A4: BBT = 5;       // should be an error
  writeln(A1, A2, A3);
}
