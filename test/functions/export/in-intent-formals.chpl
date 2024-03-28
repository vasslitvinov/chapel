// ensure that in-intent formals are codegen-ed correctly, see #23419

// int argument

proc updateInt(ref intArg: int) {
  write("intArg = ", intArg);
  intArg *= 10;
  writeln("  updated to ", intArg);
}

export proc withIntArg(in intIn: int) {
  intIn = 123;
  updateInt(intIn);
  updateInt(intIn);
  writeln("withIntArg: ", intIn);
}

// argument of a record type

extern {
  typedef struct { int i1, i2; } RR;
  RR myr;
}

extern record RR {
//  var i1: uint(32);
  var i2: uint(64);
}

var globalRec: RR;
globalRec.i2 = 321;

proc updateRec(ref recArg: RR) {
  write("recArg = ", recArg.i2);
  recArg.i2 += 100;
  writeln("  updated to ", recArg.i2);
}

export proc withRecArg(in recIn: RR) {
  recIn = globalRec;
  updateRec(recIn);
  updateRec(recIn);
  writeln("withRecArg: ", recIn.i2);
}

export proc inDriver() {
  withIntArg(456);
  withRecArg(myr);
}

inDriver();
