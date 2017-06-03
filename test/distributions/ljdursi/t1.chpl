use DiagonalDist;

config const n = numLocales;
const dn = {1..n,1..n};

var D: domain(2) dmapped Diagonal(boundingBox=dn) = dn;
D = dn;
writeln(D);
writeln();

var A: [D] real;

var count = 0;
for a in A {
  a = count;
  count += 1;
}
writeln(A);
writeln();

forall a in A do
  a = here.id;
writeln(A);
writeln();
