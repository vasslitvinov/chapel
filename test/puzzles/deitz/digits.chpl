config param digits = 4;

proc number2tuple(n: int) {
  var nn: digits*int;
  for param i in 0..digits-1 do
    nn(i) = n/10**(digits-(i+1))%10;
  return nn;
}

proc tuple2number(nn: digits*int) {
  var n: int;
  for param i in 0..digits-1 do
    n += nn(i)*10**(digits-(i+1));
  return n;
}

proc smallest(n: int) {
  var nn = number2tuple(n);
  for param i in 0..digits-2 do
    for param j in 0..digits-2 do
      if nn(j) > nn(j+1) then
        nn(j) <=> nn(j+1);
  return tuple2number(nn);
}

proc biggest(n: int) {
  var nn = number2tuple(n);
  for param i in 0..digits-2 do
    for param j in 0..digits-2 do
      if nn(j) < nn(j+1) then
        nn(j) <=> nn(j+1);
  return tuple2number(nn);
}

var n = 10**digits-1;
var A: [0..n] int;

for i in 1..n {
  var j = i;
  while A(j) == 0 {
    A(j) = i;
    j = biggest(j) - smallest(j);
  }
  if A(j) == i || A(j) == 0 {
    while A(j) != n+1 {
      A(j) = n+1;
      write(j, " ");
      j = biggest(j) - smallest(j);
    }
    writeln();
  }
}
