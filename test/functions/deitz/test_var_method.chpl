class C {
  var i : int;
  proc foo() ref {
    return i;
  }
}

var c : borrowed C = (new owned C()).borrow();
c.i = 2;
writeln(c);
writeln(c.foo());
c.foo() = 3;
writeln(c);
