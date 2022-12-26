//wass: not for PR

var DD = {1..5};
var BB: [DD] int;
type BBT = BB.type;

proc main {
  var A1: [DD] int;      // A1 <- newRayDI(DD, int)    WASS CONTINUE HERE
  var A2: [DD] int = BB; // A2 <- newRayI(DD, int, BB) WASS NEXT
  var A3: BBT      = BB; // BBT will be a static type
  writeln(A1, A2, A3);
}
