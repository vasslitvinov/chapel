//wass: not for PR

var DD = {1..5};
var BB: [DD] int;
type BBT = BB.type;

proc main {
  var A4: BBT = 5; // error: vass: initializing an array of a non-[]-type
                   // from an expression of a different type
  writeln(A4);
}
