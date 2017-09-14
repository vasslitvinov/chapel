// This test is to check that the errors "can't assign to a const"
// with the notes "due to task intents" are present and have
// correct line numbers.

// The output should be the same as 'const-due-to-task-intent-with-main.chpl'.




var DDD, EEE: domain(1);
var LLL: locale;
var RRR = 1..1;

//proc main {
  // 1: no curlies, no 'on' statements
  begin
    DDD = EEE;
  cobegin {
    DDD = EEE;
    DDD = EEE;
  }
  cobegin {
    DDD = EEE;
    var JJJ: int;
  }
  coforall III in RRR do
    DDD = EEE;
  // 2: no curlies, with 'on' statements
    // todo: distinguish line numbers for 'begin' vs. 'on' under --no-local
  begin  on LLL do
      DDD = EEE;
  cobegin
  {
    on LLL do
      DDD = EEE;
    on LLL do
      on LLL do
        on LLL do
          DDD = EEE;
  }
  cobegin
  {
    on LLL do
      DDD = EEE;
    var JJJ: int;
  }
  coforall III in RRR do
    on LLL do
      DDD = EEE;
  // 3: with curlies, no 'on' statements
  begin
  {
    DDD = EEE;
  }
  cobegin
  {
    {
      DDD = EEE;
    }
    {
      DDD = EEE;
    }
  }
  cobegin
  {
    {
      DDD = EEE;
    }
    {
      var JJJ: int;
    }
  }
  coforall III in RRR
  {
    DDD = EEE;
  }
  // 4: with curlies, with 'on' statements
    // todo: distinguish line numbers for 'begin' vs. 'on' under --no-local
  begin  {  on LLL do
      DDD = EEE;
  }
  cobegin
  {
    {
      on LLL do
        DDD = EEE;
    }
    {
      on LLL do
        on LLL do
          on LLL do
            DDD = EEE;
    }
  }
  cobegin
  {
    {
      on LLL do
        DDD = EEE;
    }
    {
      var JJJ: int;
    }
  }
  coforall III in RRR
  {
    on LLL do
      DDD = EEE;
  }
//}
