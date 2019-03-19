/*
 * Copyright 2004-2019 Cray Inc.
 * Other additional copyright holders may be indicated within.
 *
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module ChapelReduce {
/*
  use ChapelStandard;

  config param enableParScan = false;

  proc chpl__scanStateResTypesMatch(op) param {
    type resType = op.generate().type;
    type stateType = op.identity.type;
    return (resType == stateType);
  }

  proc chpl__scanIteratorZip(op, data) {
    compilerWarning("scan has been serialized (see issue #5760)");
    var arr = for d in zip((...data)) do chpl__accumgen(op, d);

    delete op;
    return arr;
  }

  proc chpl__scanIterator(op, data) {
    use Reflection;
    param supportsPar = isArray(data) && canResolveMethod(data, "_scan", op);
    if (enableParScan && supportsPar) {
      return data._scan(op);
    } else {
      compilerWarning("scan has been serialized (see issue #5760)");
      if (supportsPar) {
        compilerWarning("(recompile with -senableParScan to enable a prototype parallel implementation)");
      }
      var arr = for d in data do chpl__accumgen(op, d);

      delete op;
      return arr;
    }
  }

  // helper routine to run the accumulate + generate steps of a scan
  // in an expression context.
  proc chpl__accumgen(op, d) {
    op.accumulate(d);
    return op.generate();
  }

  proc chpl__reduceCombine(globalOp, localOp) {
    on globalOp {
      globalOp.lock();
      globalOp.combine(localOp);
      globalOp.unlock();
    }
  }

  inline proc chpl__cleanupLocalOp(globalOp, localOp) {
    // should this be part of chpl__reduceCombine ?
    delete localOp;
  }
*/

  /* Op = reduction op record; AS = Accumulation State */

  proc chpl__reduceCombine(ref parentOp, ref parentAS, childAS) {
    on parentOp {
      parentOp.lock();
      if Reflection.canResolveMethod(parentOp, "combine", parentAS, childAS) {
        parentOp.combine(parentAS, childAS);
      } else {
        parentOp.accumulate(parentAS, childAS);
      }
      parentOp.unlock();
    }
  }

  inline proc chpl_reduce_generate(ref ovar, ref globalOp, ref globalAS) {
    if Reflection.canResolveMethod(globalOp, "generate", ovar, globalAS) {
      // Use this more general methood, if available.
      globalOp.generate(ovar, globalAS);
    } else {
      // Incorporate the initial value of ovar, as required by semantics.
      globalOp.accumulate(globalAS, ovar);
      ovar = globalOp.generate(globalAS);
    }
  }

  record chpl_reduce_lock {
    var l: chpl__processorAtomicType(bool); // only accessed locally
    proc init() { }     // avoid calculating default arg at callsite

    proc lock() {
      var lockAttempts = 0,
          maxLockAttempts = (2**10-1);
      while l.testAndSet() {
        lockAttempts += 1;
        if (lockAttempts & maxLockAttempts) == 0 {
          maxLockAttempts >>= 1;
          chpl_task_yield();
        }
      }
    }
    proc unlock() {
      l.clear();
    }
  }

  // Return true for simple cases where x.type == (x+x).type.
  // This should be true for the great majority of cases in practice.
  // This proc helps us avoid run-time computations upon chpl__sumType().
  // Which is important for costly cases ex. when 'eltType' is an array.
  // It also allows us to accept 'eltType' that is the result of
  // __primitive("static typeof"), i.e. with uninitialized _RuntimeTypeInfo.
  //
  proc chpl_sumTypeIsSame(type eltType) param {
    if isNumeric(eltType) || isString(eltType) {
      return true;

    } else if isDomain(eltType) {
      // Since it is a param function, this code will be squashed.
      // It will not execute at run time.
      var d: eltType;
      // + preserves the type for associative domains.
      // Todo: any other easy-to-compute cases?
      return isAssociativeDom(d);

    } else if isArray(eltType) {
      // Follow the lead of chpl_buildStandInRTT. Thankfully, this code
      // will not execute at run time. Otherwise we could get in trouble,
      // as "static typeof" produces uninitialized _RuntimeTypeInfo values.
      type arrInstType = __primitive("static field type", eltType, "_instance");
      var instanceObj: arrInstType;
      type instanceEltType = __primitive("static typeof", instanceObj.eltType);
      return chpl_sumTypeIsSame(instanceEltType);

    } else {
      // Otherwise, let chpl__sumType() deal with it.
      return false;
    }
  }

  proc chpl__sumType(type eltType) type {
   if chpl_sumTypeIsSame(eltType) {
    return eltType;
   } else {
    // The answer may or may not be 'eltType'.
    var x: eltType;
    if isArray(x) {
      type xET = x.eltType;
      type xST = chpl__sumType(xET);
      if xET == xST then
        return eltType;
      else
        return [x.domain] xST;
    } else {
      use Reflection;
      if ! canResolve("+", x, x) then
        // Issue a user-friendly error.
        compilerError("+ reduce cannot be used on values of the type ",
                      eltType:string);
      return (x + x).type;
    }
   }
  }

//
// Some common patterns for these reduce ops are:
//
// The lock is included in the reduce op. The near-future goal is
// to keep it separately from the op.
//
// Once that happens, we can drop init=(). init=() is included for now
// to prevent the lock from being copied when cloning the reduce op.
// Such copying is unnessary.
//
// None of these ops need combine() or generate().
//

  record SumReduceScanOp {
    type accumType;
    inline proc init(type inputType) { accumType = chpl__sumType(inputType); }
    inline proc init=(parentOp)              { accumType = parentOp.accumType; }
    inline proc newAccumState()              { var x: accumType; return x; }
    inline proc accumulate(ref state, input) { state += input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  record ProductReduceScanOp {
    type accumType;
    inline proc init(type inputType)         { accumType = inputType; }
    inline proc init=(parentOp)              { accumType = parentOp.accumType; }
    inline proc newAccumState()              { return _prod_id(accumType); }
    inline proc accumulate(ref state, input) { state *= input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  record MaxReduceScanOp {
    type accumType;
    inline proc init(type inputType)         { accumType = inputType; }
    inline proc init=(parentOp)              { accumType = parentOp.accumType; }
    inline proc newAccumState()              { return min(accumType); }
    inline proc accumulate(ref state, input) { state = max(state, input); }
    forwarding var mylock: chpl_reduce_lock;
  }

  record MinReduceScanOp {
    type accumType;
    inline proc init(type inputType)         { accumType = inputType; }
    inline proc init=(parentOp)              { accumType = parentOp.accumType; }
    inline proc newAccumState()              { return max(accumType); }
    inline proc accumulate(ref state, input) { state = min(state, input); }
    forwarding var mylock: chpl_reduce_lock;
  }

  record LogicalAndReduceScanOp {
    inline proc init(type inputType)         { }
    inline proc init=(parentOp)              { }
    inline proc newAccumState()              { return true; }
    inline proc accumulate(ref state, input) { state &&= input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  record LogicalOrReduceScanOp {
    inline proc init(type inputType)         { }
    inline proc init=(parentOp)              { }
    inline proc newAccumState()              { return false; }
    inline proc accumulate(ref state, input) { state ||= input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  record BitwiseAndReduceScanOp {
    type accumType;
    inline proc init(type inputType)         { this.accumType = inputType; }
    inline proc init=(parentOp)     { this.accumType = parentOp.accumType; }
    inline proc newAccumState()              { return _band_id(accumType); }
    inline proc accumulate(ref state, input) { state &= input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  record BitwiseOrReduceScanOp {
    type accumType;
    inline proc init(type inputType)         { this.accumType = inputType; }
    inline proc init=(parentOp)     { this.accumType = parentOp.accumType; }
    inline proc newAccumState()              { return _bor_id(accumType); }
    inline proc accumulate(ref state, input) { state |= input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  record BitwiseXorReduceScanOp {
    type accumType;
    inline proc init(type inputType)         { this.accumType = inputType; }
    inline proc init=(parentOp)     { this.accumType = parentOp.accumType; }
    inline proc newAccumState()              { return _bxor_id(accumType); }
    inline proc accumulate(ref state, input) { state ^= input; }
    forwarding var mylock: chpl_reduce_lock;
  }

  proc _maxloc_id(type eltType) return (min(eltType(1)), max(eltType(2)));
  proc _minloc_id(type eltType) return max(eltType); // max() on both components

  record maxloc {
    type accumType;
    inline proc init(type inputType)  { this.accumType = inputType; }
    inline proc init=(parentOp)       { this.accumType = parentOp.accumType; }
    inline proc newAccumState()       { return _maxloc_id(accumType); }

    inline proc accumulate(ref state, input) {
      if input(1) > state(1) ||
         ( (input(1) == state(1)) && (input(2) < state(2)) )
      then
         state = input;
    }

    forwarding var mylock: chpl_reduce_lock;
  }

  record minloc {
    type accumType;
    inline proc init(type inputType)  { this.accumType = inputType; }
    inline proc init=(parentOp)       { this.accumType = parentOp.accumType; }
    inline proc newAccumState()       { return _minloc_id(accumType); }

    inline proc accumulate(ref state, input) {
      if input(1) < state(1) ||
         ( (input(1) == state(1)) && (input(2) < state(2)) )
      then
         state = input;
    }

    forwarding var mylock: chpl_reduce_lock;
  }
}
