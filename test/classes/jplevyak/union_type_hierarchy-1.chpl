union C {
  var x : integer;
}

union D {
  var x : integer;
  var y : integer;
}

function f(a : C) {
  return 1;
}

var b = C();

writeln(f(b));
