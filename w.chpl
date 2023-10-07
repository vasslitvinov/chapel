//wass: not for PR

var DD = {112..113};
var BB: [DD] int = [320, 340];
type BBT2 = [DD] int;
type BBT3 = BB.type;

proc test1(type TT8) {
  // basic declarations, explicit array type
  // these are OK as the domain is given explicitly
  var BE1: [DD] int;        // default init var BE1 calltemp
  var BE2: [DD] int = BB;   // init var BE2 BB calltemp
  var BE3: [DD] int = 5;    // init var BE3 5 calltemp
  writeln(BE1, BE2, BE3);
}
proc test2(type TT8) {
  // basic declarations, the type is BBT2
  // these are OK if we can get to BBT2's domain
  var BS1: BBT2;            // default init var BS1 BBT2
  var BS2: BBT2 = BB;       // init var BS2 BB BBT2
  var BS3: BBT2 = 5;        // init var BS3 5 BBT2
  writeln(BS1, BS2, BS3);
}
proc test3(type TT8) {
  // basic declarations, the type is BBT3
  // these are OK if we can get to BBT3's domain
  var BQ1: BBT3;
  var BQ2: BBT3 = BB;
  var BQ3: BBT3 = 5;
  writeln(BQ1, BQ2, BQ3);
}
proc test4(type TT8) {
  // basic declarations, the type is TT8
  // these are not OK as the domain comes from the caller
  var BZ1: TT8;          // warn
  var BZ2: TT8 = BB;     // warn
  var BZ3: TT8 = 5;      // warn
  writeln(BZ1, BZ2, BZ3);
}
proc test5(type TT8) {
  // split initialization
  // same reasoning as above
  var SE1: [DD] int;
  var SS1: BBT2;
  var SQ1: BBT3;
  var SZ1: TT8;          // warn
  SE1 = BB;
  SS1 = BB;;
  SQ1 = BB;
  SZ1 = BB;
  writeln(SE1, SS1, SQ1, SZ1);
}
proc test6(type TT8) {
  // multi-var decls
  // same reasoning as above
  var ME1, ME2: [DD] int;
  var MS1, MS2: BBT2;
  var MQ1, MQ2: BBT3;
  var MZ1, MZ2: TT8;     // warn
  writeln(ME1, MS1, MQ1, MZ1);
  writeln(ME2, MS2, MQ2, MZ2);
}
proc test7(type TT8) {
  // mixed default- and split-init
  // same reasoning as above
  var ME3, ME4: [DD] int;
  var MZ3, MZ4: TT8;     // warn
  ME4 = BB;
  MZ4 = BB;
  writeln(ME3, ME4, MZ3, MZ4);
}
proc test8(type TT8) {
  // casts
  // casting to BBT2 is OK if we can get to BBT2's domain
  // casting to TT8 is unstable: domain handling may change
  var BS1, BZ1: [DD] int;
  writeln(BS1, BZ1);
  BS1 = BB: BBT2;
  BZ1 = BB: TT8;         // warn
  writeln(BS1, BZ1);
}

// todo: formal arg types; fields

proc main {
  test1(BBT2);
  test2(BBT2);
  test3(BBT2);
  test4(BBT2);
  test5(BBT2);
  test6(BBT2);
  test7(BBT2);
  test8(BBT2);
}
