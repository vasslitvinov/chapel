// 'mylock' field provides for locking; to be removed later

// "no generate" option; no combine()
record ROP1 {
  type inputType;
  proc init(type inputType) { this.inputType = inputType; }
  proc init=(parentOp)      { this.inputType = parentOp.inputType; }
  proc newAccumState() return 0;
  proc accumulate(ref AS: int, input: int) { AS += input; }
  // no combine()
  // no generate()

  forwarding var mylock: chpl_reduce_lock;
}

// "no generate" option; with combine()
record ROP2 {
  type inputType;
  proc init(type inputType) { this.inputType = inputType; }
  proc init=(parentOp)      { this.inputType = parentOp.inputType; }
  proc newAccumState() return 0;
  proc accumulate(ref AS: int, input: int) { AS += input; }
  proc combine(ref parentAS: int, childAS: int) { parentAS += childAS; }
  // no generate()

  forwarding var mylock: chpl_reduce_lock;
}

// "with generate" option - one generate()
record ROP3 {
  type inputType;
  proc init(type inputType) { this.inputType = inputType; }
  proc init=(parentOp)      { this.inputType = parentOp.inputType; }
  proc newAccumState() return 0;
  proc accumulate(ref AS: int, input: int) { AS += input; }
  proc combine(ref parentAS: int, childAS: int) { parentAS += childAS; }

  // yes, use generate()
  proc generate(globalAS: int) { return globalAS + 10000; }

  forwarding var mylock: chpl_reduce_lock;
}

// "with generate" option - two generate()
record ROP4 {
  type inputType;
  proc init(type inputType) { this.inputType = inputType; }
  proc init=(parentOp)      { this.inputType = parentOp.inputType; }
  proc newAccumState() return 0;
  proc accumulate(ref AS: int, input: int) { AS += input; }
  proc combine(ref parentAS: int, childAS: int) { parentAS += childAS; }

  // yes, use generate()
  proc generate(globalAS: int) { return globalAS + 20000; }
  // also allow the more efficient generate()
  proc generate(ref output: int, globalAS: int) { output += globalAS + 30000; }

  forwarding var mylock: chpl_reduce_lock;
}

iter MYITER() { yield 55; }
iter MYITER(param tag) {
  yield 66;
  coforall idx in 33..44 {
    yield idx;
  }
}

proc main {
  var xv1 = 5;
  var xv2 = 6;
  var xv3 = 7;
  var xv4 = 8;

  forall idx in MYITER() with (
    ROP1 reduce xv1,
    ROP2 reduce xv2,
    ROP3 reduce xv3,
    ROP4 reduce xv4
  ) {
    xv1 reduce= idx;
    xv2 reduce= idx;
    xv3 reduce= idx;
    xv4 reduce= idx;
  }

  writeln(xv1);
  writeln(xv2);
  writeln(xv3);
  writeln(xv4);

  writeln();

  writeln(ROP1 reduce MYITER());
  writeln(ROP2 reduce MYITER());
  writeln(ROP3 reduce MYITER());
  writeln(ROP4 reduce MYITER());
}
