class C {
  var x: int = 1;

  proc x ref {
    return x;
  }
  proc x {
    if x < 0 then
      halt("x accessed when negative");
    return x;
  }

}

var myC = (new owned C(x = 2)).borrow();
writeln("myC is: ", myC);

myC.x = 3;
writeln("myC is: ", myC);

myC.x = -1;
writeln("myC is: ", myC);
writeln("myC.x is: ", myC.x);
