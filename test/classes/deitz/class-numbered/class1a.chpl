class foo {
  var i : int;
  var f : real;
}

var x : foo = new foo(2, 3.2);

x.i = -1;
x.f = 3.1415;

writeln("x: (", x.i, ", ", x.f, ")");

var y : foo = x;

writeln("y: (", y.i, ", ", y.f, ")");

y.i = -2;

writeln("x: (", x.i, ", ", x.f, ")");

delete x;
