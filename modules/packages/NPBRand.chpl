/*
  NAS Parallel Benchmark Random Number Generator.

  The pseudorandom number generator (PRNG) implemented by
  this module uses the algorithm from the NAS Parallel Benchmarks
  (NPB, available at: https://www.nas.nasa.gov/publications/npb.html
  which can be used to generate random values of type `real(64)`,
  `imag(64)`, and `complex(128)`.

  Paraphrasing the comments from the NPB reference implementation:

    This generator returns uniform pseudorandom real values in the
    range (0, 1) by using the linear congruential generator

      `x_{k+1} = a x_k  (mod 2**46)`

    where 0 < x_k < 2**46 and 0 < a < 2**46.  This scheme
    generates 2**44 numbers before repeating.  The generated values
    are normalized to be between 0 and 1, i.e., 2**(-46) * x_k.

    This generator should produce the same results on any computer
    with at least 48 mantissa bits for `real(64)` data.

  To generate `complex` elements, consecutive pairs of random numbers are
  assigned to the real and imaginary components, respectively.

  The values generated by this NPB RNG do not include 0.0 and 1.0.

  We have tested this implementation with TestU01 (available at
  http://simul.iro.umontreal.ca/testu01/tu01.html ). In our experiments with
  TestU01 1.2.3 and the Crush suite (which consists of 144 statistical
  tests), this NPB RNG failed 41/144 tests. As a linear congruential
  generator, this RNG has known statistical problems that TestU01
  was able to detect.

  .. note::

    This module is currently restricted to generating `real(64)`,
    `imag(64)`, and `complex(128)` complex values.

*/
module NPBRand {
  private use Random.RandomSupport;
  private use ChapelLocks;
  private use IO;

  /*
    Models a stream of pseudorandom numbers.  See the module-level
    notes for :mod:`NPBRandom` for details on the PRNG used.
  */
  class NPBRandomStream: writeSerializable {
    /*
      Specifies the type of value generated by the NPBRandomStream.
      Currently, only `real(64)`, `imag(64)`, and `complex(128)` are
      supported.
    */
    type eltType = real(64);

    /*
      The seed value for the PRNG.  It must be an odd integer in the
      interval [1, 2**46).
    */
    const seed: int(64);

    /*
      Indicates whether or not the NPBRandomStream needs to be
      parallel-safe by default.  If multiple tasks interact with it in
      an uncoordinated fashion, this must be set to `true`.  If it will
      only be called from a single task, or if only one task will call
      into it at a time, setting to `false` will reduce overhead related
      to ensuring mutual exclusion.
    */
    param parSafe: bool = true;


    /*
      Creates a new stream of random numbers using the specified seed
      and parallel safety.

      .. note::

        The NPB generator requires an odd seed value. Constructing
        an NPBRandomStream with an even seed value will cause a call to
        halt(). Only the lower 46 bits of the seed will be used.

      :arg eltType: The element type to be generated.
      :type eltType: `type`

      :arg seed: The seed to use for the PRNG.  Defaults to
        `oddCurrentTime` from :type:`~RandomSupport.SeedGenerator`.
      :type seed: `int(64)`

      :arg parSafe: The parallel safety setting.  Defaults to `true`.
      :type parSafe: `bool`

    */
    proc init(type eltType = real(64),
              seed: int(64) = _SeedGenerator.oddCurrentTime,
              param parSafe: bool = true) {
      use HaltWrappers;

      this.eltType = eltType;

      // The mod operation is written in these steps in order
      // to work around an apparent PGI compiler bug.
      // See test/portability/bigmod.test.c
      var one:uint(64) = 1;
      var two_46:uint(64) = one << 46;
      var two_46_mask:uint(64) = two_46 - 1;
      var useed = seed:uint(64);
      var mod:uint(64);
      if useed % 2 == 0 then
        HaltWrappers.initHalt("NPBRandomStream seed must be an odd integer");
      // Adjust seed to be between 0 and 2**46.
      mod = useed & two_46_mask;
      this.seed = mod:int(64);
      this.parSafe = parSafe;
      init this;

      if this.seed % 2 == 0 || this.seed < 1 || this.seed > two_46:int(64) then
        HaltWrappers.initHalt("NPBRandomStream seed must be an odd integer between 0 and 2**46");

      NPBRandomStreamPrivate_cursor = seed;
      NPBRandomStreamPrivate_count = 1;
      if eltType == real || eltType == imag || eltType == complex {
        // OK, supported element type
      } else {
        compilerError("NPBRandomStream only supports eltType=real(64), imag(64), or complex(128)");
      }
    }

    @chpldoc.nodoc
    proc NPBRandomStreamPrivate_getNext_noLock() {
      if (eltType == complex) {
        NPBRandomStreamPrivate_count += 2;
      } else {
        NPBRandomStreamPrivate_count += 1;
      }
      return randlc(eltType, NPBRandomStreamPrivate_cursor);
    }

    @chpldoc.nodoc
    proc NPBRandomStreamPrivate_skipToNth_noLock(in n: integral) {
      n += 1;
      if eltType == complex then n = n*2 - 1;
      NPBRandomStreamPrivate_count = n;
      NPBRandomStreamPrivate_cursor = randlc_skipto(seed, n);
    }

    /*
      Returns the next value in the random stream.

      Real numbers generated by the NPB RNG are in (0,1). It is not
      possible for this particular RNG to generate 0.0 or 1.0.

      :returns: The next value in the random stream as type :type:`eltType`.
      */
    proc getNext(): eltType {
      _lock();
      const result = NPBRandomStreamPrivate_getNext_noLock();
      _unlock();
      return result;
    }

    /*
      Advances/rewinds the stream to the `n`-th value in the sequence.
      The first value corresponds to n=0.  n must be >= 0, otherwise an
      IllegalArgumentError is thrown.

      :arg n: The position in the stream to skip to.  Must be >= 0.
      :type n: `integral`

      :throws IllegalArgumentError: When called with negative `n` value.
      */
    proc skipToNth(n: integral) throws {
      if n < 0 then
        throw new owned IllegalArgumentError("NPBRandomStream.skipToNth(n) called with negative 'n' value " + n:string);
      _lock();
      NPBRandomStreamPrivate_skipToNth_noLock(n);
      _unlock();
    }

    /*
      Advance/rewind the stream to the `n`-th value and return it
      (advancing the stream by one).  n must be >= 0, otherwise an
      IllegalArgumentError is thrown.  This is equivalent to
      :proc:`skipToNth()` followed by :proc:`getNext()`.

      :arg n: The position in the stream to skip to.  Must be >= 0.
      :type n: `integral`

      :returns: The `n`-th value in the random stream as type :type:`eltType`.
      :throws IllegalArgumentError: When called with negative `n` value.
      */
    proc getNth(n: integral): eltType throws {
      if (n < 0) then
        throw new owned IllegalArgumentError("NPBRandomStream.getNth(n) called with negative 'n' value " + n:string);
      _lock();
      NPBRandomStreamPrivate_skipToNth_noLock(n);
      const result = NPBRandomStreamPrivate_getNext_noLock();
      _unlock();
      return result;
    }

    /*
      Fill the argument array with pseudorandom values.  This method is
      identical to the standalone :proc:`~Random.fillRandom` procedure,
      except that it consumes random values from the
      :class:`NPBRandomStream` object on which it's invoked rather
      than creating a new stream for the purpose of the call.

      :arg arr: The array to be filled
      :type arr: [] :type:`eltType`
    */
    proc fillRandom(ref arr: [] eltType) {
      if(!arr.isRectangular()) then
        compilerError("fillRandom does not support non-rectangular arrays");

      forall (x, r) in zip(arr, iterate(arr.domain, arr.eltType)) do
        x = r;
    }

    @chpldoc.nodoc
    proc fillRandom(ref arr: []) {
      compilerError("NPBRandomStream(eltType=", eltType:string,
                    ") can only be used to fill arrays of ", eltType:string);
    }

    @chpldoc.nodoc
    proc choice(const x: [], size:?sizeType=none, replace=true, prob:?probType=none)
      throws
    {
      compilerError("NPBRandomStream.choice() is not supported.");
    }

    @chpldoc.nodoc
    proc choice(x: range(?), size:?sizeType=none, replace=true, prob:?probType=none)
      throws
    {
      compilerError("NPBRandomStream.choice() is not supported.");
    }

    @chpldoc.nodoc
    proc choice(x: domain, size:?sizeType=none, replace=true, prob:?probType=none)
      throws
    {
      compilerError("NPBRandomStream.choice() is not supported.");
    }

    /*

        Returns an iterable expression for generating `D.size` random
        numbers. The RNG state will be immediately advanced by `D.size`
        before the iterable expression yields any values.

        The returned iterable expression is useful in parallel contexts,
        including standalone and zippered iteration. The domain will determine
        the parallelization strategy.

        :arg D: a domain
        :arg resultType: the type of number to yield
        :return: an iterable expression yielding random `resultType` values

      */
    pragma "fn returns iterator"
    proc iterate(D: domain, type resultType=real) {
      _lock();
      const start = NPBRandomStreamPrivate_count;
      NPBRandomStreamPrivate_count += D.sizeAs(int);
      NPBRandomStreamPrivate_skipToNth_noLock(NPBRandomStreamPrivate_count-1);
      _unlock();
      return NPBRandomPrivate_iterate(resultType, D, seed, start);
    }

    // Forward the leader iterator as well.
    pragma "fn returns iterator"
    @chpldoc.nodoc
    proc iterate(D: domain, type resultType=real, param tag)
      where tag == iterKind.leader
    {
      // Note that proc iterate() for the serial case (i.e. the one above)
      // is going to be invoked as well, so we should not be taking
      // any actions here other than the forwarding.
      const start = NPBRandomStreamPrivate_count;
      return NPBRandomPrivate_iterate(resultType, D, seed, start, tag);
    }

    @chpldoc.nodoc
    override proc writeThis(f) throws {
      f.write("NPBRandomStream(eltType=", eltType:string);
      f.write(", parSafe=", parSafe);
      f.write(", seed=", seed, ")");
    }

    @chpldoc.nodoc
    override proc serialize(writer, ref serializer) throws {
      writeThis(writer);
    }

    ///////////////////////////////////////////////////////// CLASS PRIVATE //
    //
    // It is the intent that once Chapel supports the notion of
    // 'private', everything in this class declared below this line will
    // be made private to this class.
    //

    @chpldoc.nodoc
    var _l: if parSafe then chpl_LocalSpinlock else nothing;
    @chpldoc.nodoc
    inline proc _lock() {
      if parSafe then _l.lock();
    }
    @chpldoc.nodoc
    inline proc _unlock() {
      if parSafe then _l.unlock();
    }
    @chpldoc.nodoc
    var NPBRandomStreamPrivate_cursor: real = seed;
    @chpldoc.nodoc
    var NPBRandomStreamPrivate_count: int(64) = 1;
  }


  ////////////////////////////////////////////////////////// MODULE PRIVATE //
  //
  // It is the intent that once Chapel supports the notion of 'private',
  // everything declared below this line will be made private to this
  // module.
  //

  //
  // NPB-defined constants for linear congruential generator
  //
  @chpldoc.nodoc
  private const r23   = 0.5**23,
                t23   = 2.0**23,
                r46   = 0.5**46,
                t46   = 2.0**46,
                arand = 1220703125.0; // TODO: Is arand something that a
                                      // user might want to set on a
                                      // case-by-case basis?

  //
  // NPB-defined randlc routine
  //
  private proc randlc(inout x: real, a: real = arand) {
    var t1 = r23 * a;
    const a1 = floor(t1),
      a2 = a - t23 * a1;
    t1 = r23 * x;
    const x1 = floor(t1),
      x2 = x - t23 * x1;
    t1 = a1 * x2 + a2 * x1;
    const t2 = floor(r23 * t1),
      z  = t1 - t23 * t2,
      t3 = t23 * z + a2 * x2,
      t4 = floor(r46 * t3),
      x3 = t3 - t46 * t4;
    x = x3;
    return r46 * x3;
  }

  // Wrapper that takes a result type (two calls for complex types)
  private proc randlc(type resultType, inout x: real) {
    if resultType == complex then
      return (randlc(x), randlc(x)):complex;
    else
      if resultType == imag then
        //
        // BLC: I thought that casting real to imag did this automatically?
        //
        return _r2i(randlc(x));
      else
        return randlc(x);
    }

  //
  // Return a value for the cursor so that the next call to randlc will
  // return the same value as the nth call to randlc
  //
  private proc randlc_skipto(seed: int(64), in n: integral): real {
    var cursor = seed:real;
    n -= 1;
    var t = arand;
    arand;
    while (n != 0) {
      const i = n / 2;
      if (2 * i != n) then
        randlc(cursor, t);
      if i == 0 then
        break;
      else
        n = i;
      randlc(t, t);
      n = i;
    }
    return cursor;
  }

  //
  // iterate over outer ranges in tuple of ranges
  //
  private iter outer(ranges, param dim: int = 0) {
    if dim + 2 == ranges.size {
      foreach i in ranges(dim) do
        yield (i,);
    } else if dim + 2 < ranges.size {
      foreach i in ranges(dim) do
        foreach j in outer(ranges, dim+1) do
          yield (i, (...j));
    } else {
      yield 0; // 1D case is a noop
    }
  }

  //
  // RandomStream iterator implementation
  //
  @chpldoc.nodoc
  iter NPBRandomPrivate_iterate(type resultType, D: domain, seed: int(64),
                        start: int(64)) {
    var cursor = randlc_skipto(seed, start);
    for i in D do
      yield randlc(resultType, cursor);
  }

  @chpldoc.nodoc
  iter NPBRandomPrivate_iterate(type resultType, D: domain, seed: int(64),
                        start: int(64), param tag: iterKind)
        where tag == iterKind.leader {
    // forward to the domain D's iterator
    for block in D.these(tag=iterKind.leader) do
      yield block;
  }

  @chpldoc.nodoc
  iter NPBRandomPrivate_iterate(type resultType, D: domain, seed: int(64),
                start: int(64), param tag: iterKind, followThis)
        where tag == iterKind.follower {
    use DSIUtil;
    param multiplier = if resultType == complex then 2 else 1;
    const ZD = computeZeroBasedDomain(D);
    const innerRange = followThis(ZD.rank-1);
    var cursor: real;
    for outer in outer(followThis) {
      var myStart = start;
      if ZD.rank > 1 then
        myStart += multiplier * ZD.indexOrder(((...outer), innerRange.lowBound)).safeCast(int(64));
      else
        myStart += multiplier * ZD.indexOrder(innerRange.lowBound).safeCast(int(64));
      if innerRange.hasUnitStride() {
        cursor = randlc_skipto(seed, myStart);
        for i in innerRange do
          yield randlc(resultType, cursor);
      } else {
        myStart -= innerRange.lowBound.safeCast(int(64));
        for i in innerRange {
          cursor = randlc_skipto(seed, myStart + i.safeCast(int(64)) * multiplier);
          yield randlc(resultType, cursor);
        }
      }
    }
  }
} // close module NPBRandom
