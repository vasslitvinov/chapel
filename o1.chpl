
config const flag = true;
var AA: [1..9] int = 5;
ref BB = AA[1..4];
/*
record R { var x: int; }

proc sli0() {
  return new R();
}
*/
proc sli1() /*ref*/ {
  return BB;
}

proc sli2() ref {
  ref r1 = AA[1..3];
  ref r2 = r1;
  return r2;
//  return AA[1..3];
}

/*
proc sli3() ref {
  if flag then
    return BB;
  else if flag then
    return sli1();
  else
    return AA[1..3];
}
*/

//ref r0 = sli0();
ref r1 = sli1();
ref r2 = sli2();
//ref r3 = sli3();

/*
var AA: [1..9] int = 5;
ref BB = AA[1..4];
BB = 2;
writeln(AA);

proc sli() const ref {
  return BB;//AA[1..3];
}

ref s = sli();
//s = 8;
writeln(s);
writeln(AA);
*/
