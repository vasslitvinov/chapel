
class C {
  var field:int;
}

class D {
  var field:real;
}


record WrapperOne {
  var instance; // e.g. some class
  proc f( a, b:a.type, c = b ) {
    writeln("in f ", instance, " a=", a, " b=", b, " c=", c);
  }
}

record WrapperTwo {
  var instance; // WrapperOne
  forwarding instance;
}


{
  var a = new WrapperTwo(new WrapperOne(new C(1)));

  a.f(2,3);
  a.f(2,3,4);
}

{
  var b = new WrapperTwo(new WrapperOne(new D(1.0)));

  b.f(2.0,3.0);
  b.f(2.0,3.0,4.0);
}
