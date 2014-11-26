/*****************************************************************************
Locales Replicated Distribution - below was stolen from ReplicatedDist

This LocalesRepDist distribution causes a domain and its arrays
to be replicated across the desired locales (all the locales by default).
An array receives a distinct set of elements - a "replicand" -
allocated on each locale.

In other words, mapping a domain with LocalesRepDist gives it
an implicit additional dimension - over the locales,
making it behave as if there is one copy of its indices per locale.

Replication over locales is observable:
- when iterating over a domain or array
- when printing with write() et al.
- when zippering and the replicated domain/array is
  the first among the zippered items
- when assigning into the replicated array
- when inquiring about the domain's numIndices
  or the array's numElements
- when accessing array element(s) from a locale that was not included
  in the array passed explicitly to the LocalesRepDist constructor,
  an out-of-bounds error will result

Only the replicand *on the current locale* is accessed
(i.e. replication is not observable):
- when examining certain domain properties:
  dim(d), dims(), low, high, stride;
  but not numIndices
- when indexing into an array
- when slicing an array  TODO: right?
- when zippering and the first zippered item is not replicated
- when assigning to a non-replicated array,
  i.e. the replicated array is on the right-hand side of the assignment
- when there is only a single locale (trivially: only one replicand)

E.g. when iterating, the number of iterations will be (the number of
locales involved) times (the number of iterations over this domain if
it were distributed with the default distribution).

Note that the above behavior may change in the future.

Features/limitations:
* Consistency/coherence among replicands' array elements is NOT maintained.
* Only rectangular domains are presently supported.
* When replicating over user-provided array of locales, that array
  must be "consistent" (see below).

"Consistent" array requirement:
* The array of locales passed to the LocalesRepDist constructor, if any,
  must be "consistent".
* A is "consistent" if for each ix in A.domain, A[ix].id == ix.
* Tip: if the domain of the desired array of locales cannot be described
  as a rectangular domain (which could be strided, multi-dimensional,
  and/or sparse), make that array's domain associative over int.

*/


/*****************************************************************************/
// THE REPLICATED DISTRIBUTION IMPLEMENTATION
//
// Classes defined:
//  LocalesRepDist -- Global distribution descriptor
//  LocalesRepDom -- Global domain descriptor
//  LocLocalesRepDom -- Local domain descriptor
//  LocalesRepArray -- Global array descriptor
//  LocLocalesRepArray -- Local array descriptor

// include locale information when printing out domains and arrays
config param printLocalesRepLocales = false;

// trace certain DSI methods as they are being invoked
config param traceLocalesRepDist = false;


/////////////////////////////////////////////////////////////////////////////
// distribution

//
// (global) distribution class
//
class LocalesRepDist : BaseDist {
  // the desired locales (an array of locales)
  const targetLocales;
  // "IDs" are indices into targetLocales
  proc targetIds return targetLocales.domain;

  // privatized object id
  var pid: int = -1;

  // TODO: Remove
  //proc LocalesRepDist() {
  //  writeln("made LocalesRepDist!");
  //}
}


// constructor: replicate over the given locales
// (by default, over all locales)
// TODO: the Locales._value.myElements realy should just be Locales...
proc LocalesRepDist.LocalesRepDist(targetLocales: [] locale = Locales._value.myElements,
                 purposeMessage: string = "used to create a LocalesRepDist")
{
  if traceLocalesRepDist then
    writeln("LocalesRepDist constructor over ", targetLocales);
  _localesCheckHelper(purposeMessage);
}

// helper to check consistency of the locales array
// TODO: going over all the locales - is there a scalability issue?
proc LocalesRepDist._localesCheckHelper(purposeMessage: string): void {
  // ideally would like to make this a "eureka"
  forall (ix, loc) in zip(targetIds, targetLocales) do
    if loc.id != ix {
      halt("The array of locales ", purposeMessage, " must be \"consistent\".",
           " See LocalesRepDist documentation for details.");
    }
}


// privatization

proc LocalesRepDist.dsiSupportsPrivatization() param return true;

proc LocalesRepDist.dsiGetPrivatizeData() {
  if traceLocalesRepDist then writeln("LocalesRepDist.dsiGetPrivatizeData");

  // TODO: return the targetLocales array by value,
  // to reduce communication needed in dsiPrivatize()
  // perhaps by wrapping it in a class (or tuple?).
  return targetLocales;
}

proc LocalesRepDist.dsiPrivatize(privatizeData: this.targetLocales.type)
  : this.type
{
  if traceLocalesRepDist then writeln("LocalesRepDist.dsiPrivatize on ", here);

  const pdTargetLocales = privatizeData;
  // make private copy of targetLocales and its domain
  const privTargetIds: domain(pdTargetLocales.domain.rank,
                              pdTargetLocales.domain.idxType,
                              pdTargetLocales.domain.stridable
                              ) = pdTargetLocales.domain;
  const privTargetLocales: [privTargetIds] locale = pdTargetLocales;
  return new LocalesRepDist(privTargetLocales, "used during privatization");
}


/////////////////////////////////////////////////////////////////////////////
// domains

//
// global domain class
//
class LocalesRepDom : BaseRectangularDom {
  // to support rectangular domains
  param rank: int;
  type idxType;
  param stridable: bool;
  // we need to be able to provide the domain map for our domain - to build its
  // runtime type (because the domain map is part of the type - for any domain)
  // (looks like it must be called exactly 'dist')
  const dist; // must be a LocalesRepDist

  // this is our index set; we store it here so we can get to it easily
  var domRep: domain(rank, idxType, stridable);

  // local domain objects
  // NOTE: 'dist' must be initialized prior to 'localDoms'
  // => currently have to use the default constructor
  // NOTE: if they ever change after the constructor - Reprivatize them
  var localDoms: [dist.targetIds] LocLocalesRepDom(rank, idxType, stridable);

  // privatized object id
  var pid: int = -1;

  proc toDefaultRectangular() {
    var retVal: domain(rank, idxType, stridable) = domRep;
    return retVal;
  }
}

//
// local domain class
//
class LocLocalesRepDom {
  // copy from the global domain
  param rank: int;
  type idxType;
  param stridable: bool;

  // our index set, copied from the global domain
  var domLocalRep: domain(rank, idxType, stridable);
}


// No explicit LocalesRepDom constructor - use the default one.
// proc LocalesRepDom.LocalesRepDom(...){...}

// Since we piggy-back on (default-mapped) Chapel domains, we can redirect
// a few operations to those. This function returns a Chapel domain
// that's fastest to access from the current locale.
// With privatization this is in the privatized copy of the LocalesRepDom.
//
// Not a parentheses-less method because of a bug as of r18460
// (see generic-parenthesesless-3.chpl).
proc LocalesRepDom.redirectee(): domain(rank, idxType, stridable)
  return domRep;

// The same across all domain maps
proc LocalesRepDom.dsiMyDist() return dist;


// privatization

proc LocalesRepDom.dsiSupportsPrivatization() param return true;

proc LocalesRepDom.dsiGetPrivatizeData() {
  if traceLocalesRepDist then writeln("LocalesRepDom.dsiGetPrivatizeData");

  // TODO: perhaps return 'domRep' and 'localDoms' by value,
  // to reduce communication needed in dsiPrivatize().
  return (dist.pid, domRep, localDoms);
}

proc LocalesRepDom.dsiPrivatize(privatizeData): this.type {
  if traceLocalesRepDist then writeln("LocalesRepDom.dsiPrivatize on ", here);

  var privdist = chpl_getPrivatizedCopy(this.dist.type, privatizeData(1));
  return new LocalesRepDom(rank=rank, idxType=idxType, stridable=stridable,
                           dist = privdist,
                           domRep = privatizeData(2),
                           localDoms = privatizeData(3));
}

proc LocalesRepDom.dsiGetReprivatizeData() {
  return (domRep,);
}

proc LocalesRepDom.dsiReprivatize(other, reprivatizeData): void {
  assert(this.rank == other.rank &&
         this.idxType == other.idxType &&
         this.stridable == other.stridable);

  this.domRep = reprivatizeData(1);
}


proc LocalesRepDist.dsiClone(): this.type {
  if traceLocalesRepDist then writeln("LocalesRepDist.dsiClone");
  return new LocalesRepDist(targetLocales);
}

// create a new domain mapped with this distribution
proc LocalesRepDist.dsiNewRectangularDom(param rank: int,
                                         type idxType,
                                         param stridable: bool)
  : LocalesRepDom(rank, idxType, stridable, this.type)
{
  if traceLocalesRepDist then writeln("LocalesRepDist.dsiNewRectangularDom ",
                                      (rank, typeToString(idxType), stridable));

  // Have to call the default constructor because we need to initialize 'dist'
  // prior to initializing 'localDoms' (which needs a non-nil value for 'dist'.
  var result = new LocalesRepDom(rank=rank, idxType=idxType,
                                 stridable=stridable, dist=this);

  // create local domain objects
  coforall (loc, locDom) in zip(targetLocales, result.localDoms) do
    on loc do
      locDom = new LocLocalesRepDom(rank, idxType, stridable);

  return result;
}

// create a new domain mapped with this distribution representing 'ranges'
proc LocalesRepDom.dsiBuildRectangularDom(param rank: int,
                                          type idxType,
                                          param stridable: bool,
                                          ranges: rank * range(idxType,
                                                BoundedRangeType.bounded,
                                                               stridable))
  : LocalesRepDom(rank, idxType, stridable, this.dist.type)
{
  // could be made more efficient to avoid visiting each locale twice
  // but perhaps not a big deal, for now anyways
  var result = dist.dsiNewRectangularDom(rank, idxType, stridable);
  result.dsiSetIndices(ranges);
  return result;
}

// Given an index, this should return the locale that owns that index.
// (This is the implementation of dmap.idxToLocale().)
// For LocalesRepDist, we point it to the current locale.
proc LocalesRepDist.dsiIndexToLocale(indexx): locale {
  return here;
}

/*
dsiSetIndices accepts ranges because it is invoked so from ChapelArray or so.
Most dsiSetIndices() on a tuple of ranges can be the same as this one.
Or that call dsiSetIndices(ranges) could be converted following this example.
*/
proc LocalesRepDom.dsiSetIndices(rangesArg: rank * range(idxType,
                                          BoundedRangeType.bounded,
                                                         stridable)): void {
  if traceLocalesRepDist then
    writeln("LocalesRepDom.dsiSetIndices on ranges");
  dsiSetIndices({(...rangesArg)});
}

proc LocalesRepDom.dsiSetIndices(domArg: domain(rank, idxType, stridable)): void {
  if traceLocalesRepDist then
    writeln("LocalesRepDom.dsiSetIndices on domain ", domArg);
  domRep = domArg;
  coforall locDom in localDoms do
    on locDom do
      locDom.domLocalRep = domArg;
}

proc LocalesRepDom.dsiGetIndices(): rank * range(idxType,
                                                 BoundedRangeType.bounded,
                                                 stridable) {
  if traceLocalesRepDist then writeln("LocalesRepDom.dsiGetIndices");
  return redirectee().getIndices();
}

// Iterators over the domain's indices (serial, leader, follower).
// Our semantics: yield each of the domain's indices once per each locale.

// Serial iterator: the compiler forces it to be completely serial
iter LocalesRepDom.these() {
  // compiler does not allow 'on' here (see r16137 and nestedForall*)
  // so instead of ...
  //---
  //for locDom in localDoms do
  //  on locDom do
  //    for i in locDom.domLocalRep do
  //      yield i;
  //---
  // ... so we simply do the same a few times
  var locDom = redirectee();
  for i in locDom do
    yield i;
}

//TODO: This may need a forall/coforall/on clause
iter LocalesRepDom.these(param tag: iterKind) where tag == iterKind.leader {
  var locDom = redirectee();
  for follow in locDom._value.domLocalRep._value.these(tag) do
    yield follow;
}

iter LocalesRepDom.these(param tag: iterKind, followThis) where tag == iterKind.follower {
  // redirect to DefaultRectangular
  for i in redirectee()._value.these(tag, followThis) do
    yield i;
}

/* Write the domain out to the given Writer serially. */
proc LocalesRepDom.dsiSerialWrite(f: Writer): void {
  // redirect to DefaultRectangular
  redirectee()._value.dsiSerialWrite(f);
  if printLocalesRepLocales {
    f.write(" replicated over ");
    dist.targetLocales._value.dsiSerialWrite(f);
  }
}

proc LocalesRepDom.dsiDims(): rank * range(idxType,
                                           BoundedRangeType.bounded,
                                           stridable)
  return redirectee().dims();

proc LocalesRepDom.dsiDim(dim: int): range(idxType,
                                           BoundedRangeType.bounded,
                                           stridable)
  return redirectee().dim(dim);

proc LocalesRepDom.dsiLow
  return redirectee().low;

proc LocalesRepDom.dsiHigh
  return redirectee().high;

proc LocalesRepDom.dsiStride
  return redirectee().stride;

// here replication is visible
proc LocalesRepDom.dsiNumIndices
  return redirectee().numIndices;

proc LocalesRepDom.dsiMember(indexx)
  return redirectee().member(indexx);

proc LocalesRepDom.dsiIndexOrder(indexx)
  return redirectee().dsiIndexOrder(indexx);


/////////////////////////////////////////////////////////////////////////////
// arrays

//
// global array class
//
class LocalesRepArr : BaseArr {
  // These two are hard-coded in the compiler - it computes the array's
  // type string as '[dom.type] eltType.type'
  type eltType;
  const dom; // must be a LocalesRepDom

  // the replicated arrays
  // NOTE: 'dom' must be initialized prior to initializing 'localArrs'
  var localArrs: [dom.dist.targetIds]
              LocLocalesRepArr(eltType, dom.rank, dom.idxType, dom.stridable);

  // privatized object id
  var pid: int = -1;
}

//
// local array class
//
class LocLocalesRepArr {
  // these generic fields let us give types to the other fields easily
  type eltType;
  param rank: int;
  type idxType;
  param stridable: bool;

  var myDom: LocLocalesRepDom(rank, idxType, stridable);
  var arrLocalRep: [myDom.domLocalRep] eltType;
}


// LocalesRepArr constructor.
// We create our own to make field initializations convenient:
// 'eltType' and 'dom' as passed explicitly;
// the fields in the parent class, BaseArr, are initialized to their defaults.
//
proc LocalesRepArr.LocalesRepArr(type eltType, dom: LocalesRepDom) {
  // initializes the fields 'eltType', 'dom' by name
}

// The same across all domain maps
proc LocalesRepArr.dsiGetBaseDom() return dom;

proc LocalesRepArr.dsiIsPrivatizedLocales() param return true;

// privatization

proc LocalesRepArr.dsiSupportsPrivatization() param return true;

proc LocalesRepArr.dsiGetPrivatizeData() {
  if traceLocalesRepDist then writeln("LocalesRepArr.dsiGetPrivatizeData");

  // TODO: perhaps return 'localArrs' by value,
  // to reduce communication needed in dsiPrivatize().
  return (dom.pid, localArrs);
}

proc LocalesRepArr.dsiPrivatize(privatizeData) {
  if traceLocalesRepDist then writeln("LocalesRepArr.dsiPrivatize on ", here);

  var privdom = chpl_getPrivatizedCopy(this.dom.type, privatizeData(1));
  var result = new LocalesRepArr(eltType, privdom);
  result.localArrs = privatizeData(2);
  return result;
}


// create a new array over this domain
proc LocalesRepDom.dsiBuildArray(type eltType)
  : LocalesRepArr(eltType, this.type)
{
  if traceLocalesRepDist then writeln("LocalesRepDom.dsiBuildArray");
  var result = new LocalesRepArr(eltType, this);
  coforall (loc, locDom, locArr)
   in zip(dist.targetLocales, localDoms, result.localArrs) do
    on loc do
      locArr = new LocLocalesRepArr(eltType, rank, idxType, stridable,
                                    locDom);
  return result;
}

// Return the array element corresponding to the index - on the current locale
proc LocalesRepArr.dsiAccess(indexx) ref: eltType {
  return localArrs[here.id].arrLocalRep[indexx];
}

// Write the array out to the given Writer serially.
proc LocalesRepArr.dsiSerialWrite(f: Writer): void {
  localArrs[here.id].arrLocalRep._value.dsiSerialWrite(f);
}

// iterators

// completely serial
iter LocalesRepArr.these() ref: eltType {
  for a in localArrs[here.id].arrLocalRep do
    yield a;
}

iter LocalesRepArr.these(param tag: iterKind) where tag == iterKind.leader {
  const locDom = dom.redirectee();
  coforall indx in locDom {
    var follow: dom.rank*range(dom.idxType);
    if dom.rank == 1 {
      const adjIndx = indx-locDom.low;
      follow(1) = adjIndx..adjIndx;
    } else {
      for param i in 1..locDom.rank {
        const adjIndx = indx(i)-locDom.dim(i).low;
        follow(i) = adjIndx..adjIndx;
      }
    }
    on localArrs[here.id].arrLocalRep[indx].locale {
      yield follow;
    }
  }
}

iter LocalesRepArr.these(param tag: iterKind, followThis) ref where tag == iterKind.follower {
  // redirect to DefaultRectangular
  for a in localArrs[here.id].arrLocalRep._value.these(tag, followThis) do
    yield a;
}


/////////////////////////////////////////////////////////////////////////////
// slicing, reindexing, etc.

// This supports reassignment of the array's domain.
/*
This gets invoked upon reassignment of the array's domain,
prior to calling this.dom.dsiSetIndices().
So this needs to adjust anything in the array that won't be taken care of
in this.dom.dsiSetIndices(). In our case, that's nothing.
*/
proc LocalesRepArr.dsiReallocate(d: domain): void {
  if traceLocalesRepDist then
    writeln("LocalesRepArr.dsiReallocate ", dom.domRep, " -> ", d, " (no-op)");
}

// array slicing
proc LocalesRepArr.dsiSlice(sliceDef: LocalesRepDom) {
  if traceLocalesRepDist then writeln("LocalesRepArr.dsiSlice on ", sliceDef);
  const slicee = this;
  const result = new LocalesRepArr(slicee.eltType, sliceDef);

  // ensure sliceDef and slicee are over the same set of locales/targetIds
  assert(sliceDef.localDoms.domain == slicee.localArrs.domain);

  coforall (loc, sliceDefLocDom, sliceeLocArr, resultLocArr)
   in zip(sliceDef.dist.targetLocales, sliceDef.localDoms,
       slicee.localArrs, result.localArrs) do
    on loc do
      resultLocArr = new LocLocalesRepArr(eltType,
        sliceDef.rank, sliceDef.idxType, sliceDef.stridable,
        myDom = sliceDefLocDom,
        arrLocalRep => sliceeLocArr.arrLocalRep[sliceDefLocDom.domLocalRep]);

  return result;
}

// array reindexing
// very similar to array slicing
proc LocalesRepArr.dsiReindex(sliceDef: LocalesRepDom) {
  if traceLocalesRepDist then writeln("LocalesRepArr.dsiReindex on ", sliceDef);
  var result = new LocalesRepArr(eltType, sliceDef);
  var slicee = this;

  // ensure 'dom' and 'slicee' are over the same set of locales/targetIds
  assert(sliceDef.localDoms.domain == slicee.localArrs.domain);

  coforall (loc, sliceDefLocDom, sliceeLocArr, resultLocArr)
   in zip(sliceDef.dist.targetLocales, sliceDef.localDoms,
       slicee.localArrs, result.localArrs) do
    on loc do
     {
      var locAlias: [sliceDefLocDom.domLocalRep] => sliceeLocArr.arrLocalRep;
      resultLocArr = new LocLocalesRepArr(eltType,
        sliceDef.rank, sliceDef.idxType, sliceDef.stridable,
        myDom = sliceDefLocDom,
        arrLocalRep => locAlias);
     }

  return result;
}

// rank-change slicing
// very similar to slicing
proc LocalesRepArr.dsiRankChange(sliceDef: LocalesRepDom,
                                 param newRank: int,
                                 param newStridable: bool,
                                 args) {
  if traceLocalesRepDist then writeln("LocalesRepArr.dsiRankChange");
  var result = new LocalesRepArr(eltType, sliceDef);
  var slicee = this;

  // ensure 'dom' and 'slicee' are over the same set of locales/targetIds
  assert(sliceDef.localDoms.domain == slicee.localArrs.domain);

  coforall (loc, sliceDefLocDom, sliceeLocArr, resultLocArr)
   in zip(sliceDef.dist.targetLocales, sliceDef.localDoms,
       slicee.localArrs, result.localArrs) do
    on loc do
      resultLocArr = new LocLocalesRepArr(eltType,
        sliceDef.rank, sliceDef.idxType, sliceDef.stridable,
        myDom = sliceDefLocDom,
        arrLocalRep => sliceeLocArr.arrLocalRep[(...args)]);

  return result;
}

// todo? these two seem to work (written by analogy with DefaultRectangular)
proc LocalesRepDist.dsiCreateReindexDist(newSpace, oldSpace) return this;
proc LocalesRepDist.dsiCreateRankChangeDist(param newRank, args) return this;
