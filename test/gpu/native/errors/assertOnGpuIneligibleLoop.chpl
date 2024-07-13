
iter asdf() {
  yield 543543;
}

iter asdf(param tag) {
  coforall locIdx in 1..9 do
    on here do
      yield locIdx;
}

proc main {
  @assertOnGpu
  forall locIdx in asdf() {
    writeln(here);
  }
}
