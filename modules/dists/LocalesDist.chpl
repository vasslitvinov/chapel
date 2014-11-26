use LocalesRepDist;
use ReplicatedDist;

class LocalesDist : BaseDist {
  proc dsiClone() : LocalesDist {
    return this;
  }

  proc dsiDisplayRepresentation() {
    //TODO
  }

  proc dsiNewRectangularDom(param rank: int,
                            type idxType,
                            param stridable: bool) {
    return new LocalesDom(rank=rank, idxType=idxType,
                          dist=this, stridable=stridable);
  }

  proc dsiCreateReindexDist(newSpace, oldSpace) {
    writeln("inside create reindex");
    //TODO
  }

  proc dsiCreateRankChangeDist(param newRank: int, args) {
    writeln("inside create rank change");
    //TODO
  }

}

class LocalesDom : BaseRectangularDom {
  param rank: int;
  type idxType;
  param stridable: bool;
  const dist: LocalesDist;
  const backingDom: domain(rank, idxType, stridable);

  inline proc dsiMyDist() return dist;

  inline proc dsiGetIndices() return backingDom.getIndices();

  inline proc dsiSetIndices(x) {
    backingDom.setIndices(x);
  }

  iter these() {
    for i in backingDom do
      yield i;
  }

  iter these(param tag: iterKind) where tag == iterKind.leader {
    extern const c_sublocid_any: chpl_sublocID_t;
    if rank > 1 {
      compilerError("LocalesDom does not support parallel iteration when rank > 1");
    } else {
      if backingDom.high > numLocales {
        halt("LocalesDom can not perform a parallel iteration over more locales than exist");
      }
      if numLocales == 1 {
        for locIdx in backingDom {
          const adjLocIdx = locIdx-backingDom.low;
          yield (adjLocIdx..adjLocIdx,);
        }
      } else {
        coforall locIdx in backingDom {
          const adjLocIdx = locIdx-backingDom.low;
          on __primitive("chpl_on_locale_num",
                         chpl_buildLocaleID(adjLocIdx:chpl_nodeID_t,
                                            c_sublocid_any)) {
            yield (adjLocIdx..adjLocIdx,);
          }
        }
      }
    }
  }

  iter these(param tag: iterKind, followThis) where tag == iterKind.follower {
    for i in backingDom._value.these(tag, followThis) do
      yield i;
  }

  inline proc dsiSerialWrite(f: Writer) {
    f.write(backingDom);
  }

  inline proc dsiDisplayRepresentation() {
    backingDom.displayRepresentation();
  }

  proc dsiBuildArray(type eltType) {
    return new LocalesArr(eltType=eltType, rank=rank, idxType=idxType,
                          stridable=stridable, dom=this);
  }

  inline proc dsiDim(dim: int) return backingDom.dim(dim);
  inline proc dsiDims() return backingDom.dims();
  inline proc dsiLow return backingDom.low;
  inline proc dsiHigh return backingDom.high;
  inline proc dsiStride return backingDom.stride;
  inline proc dsiNumIndices return backingDom.numIndices;
  inline proc dsiMember(indx) return backingDom.member(indx);
  inline proc dsiIndexOrder(indx) return backingDom.indexOrder(indx);

  proc dsiBuildRectangularDom(param rank: int,
                            type idxType,
                            param stridable: bool,
                            ranges: rank*range(idxType,
                                               BoundedRangeType.bounded,
                                               stridable)) {
    const result = dist.dsiNewRectangularDom(rank, idxType, stridable);
    result.dsiSetIndices(ranges);
    return result;
  }

}

class LocalesArr : BaseArr {
  type eltType;
  param rank: int;
  type idxType;
  param stridable: bool;
  var dom: LocalesDom(rank, idxType, stridable);
  var myElements: [dom.backingDom] eltType;

  proc dsiGetBaseDom() return dom;

  inline proc dsiAccess(indx) ref: eltType {
    return myElements[indx];
  }

  inline proc dsiSerialWrite(f: Writer) {
    f.write(myElements);
  }

  // completely serial
  iter these() ref : eltType {
    for e in myElements do
      yield e;
  }

  iter these(param tag: iterKind) where tag == iterKind.leader {
    coforall indx in dom {
      //TODO: (file bug) compilation will fail if this extern const is outside
      //      of the coforall...
      extern const c_sublocid_any: chpl_sublocID_t;
      var follow: rank*range(idxType);
      if rank == 1 {
        const adjIndx = indx-dom.backingDom.low;
        follow(1) = adjIndx..adjIndx;
      } else {
        for param i in 1..rank {
          const adjIndx = indx(i)-dom.backingDom.dim(i).low;
          follow(i) = adjIndx..adjIndx;
        }
      }
      on __primitive("chpl_on_locale_num",
                     chpl_buildLocaleID(myElements[indx].locale.id:chpl_nodeID_t,
                                        c_sublocid_any)) {
        yield follow;
      }
    }
  }

  //TODO: would like to remove var, but that seems to cause issues
  iter these(param tag: iterKind, followThis) ref where tag == iterKind.follower {
    // redirect to DefaultRectangular on the current locale - I dont like this
    // at all either. it will return incorrect values if Locales gets out of
    // sync on different locales. also prevents the dist from being used by any
    // other array.
    //
    // In l/f 2.0 we may be able to optimize this to just be 'yield here' (in
    // certain cases)
    for e in Locales._value.myElements._value.these(tag, followThis) do
      yield e;
  }

  proc dsiReallocate(d: domain) {}

  inline proc dsiDisplayRepresentation() {
    myElements.displayRepresentation(); //TODO: need separate implementation?
  }

  proc dsiReshape(D: domain) {
    var repSpace = D dmapped LocalesRepDist();
    var repArr: [repSpace] this.eltType;

    coforall locArray in repArr._value.localArrs {
      on locArray.locale {
        for (i, e) in zip(D, this) do
          locArray.arrLocalRep[i] = e;
      }
    }

    return repArr;
  }

  proc dsiSlice(sliceDef: LocalesDom) {
    // it'd be nice to just be able to replicate to the locales included in the
    // slice, but we dont know what locale this slice is actually going to be
    // used on. So replicate to everything :(
    var repSpace = sliceDef.backingDom dmapped LocalesRepDist();
    var repArr: [repSpace] eltType = this.myElements[sliceDef.backingDom];
    return repArr._value;
  }

  proc dsiReindex(reindexDef: LocalesDom) {
    // We replicate to avoid a large number of communication operations inside
    // of the follower iterator
    var repSpace = reindexDef.backingDom dmapped LocalesRepDist();
    var repArr = new LocalesRepArr(eltType=eltType, rank=rank, idxType=idxType,
                               stridable=reindexDef.stridable, dom=reindexDef);
    for (i,j) in zip(reindexDef, dom) {
      repArr.myElements[i] = myElements[j];
    }
    return repArr;
  }

  proc dsiRankChange(reindexDef: LocalesDom,
                     param newRank: int,
                     param newStridable: bool,
                     args) {
    compilerError("Rank change not possible on Locales.");
  }

  //TODO: Any way to support bulk transfer?  Could fall back to the myElements
  //      bulk transfer, would need to make sure the locality is correct after
  proc dsiSupportsBulkTransfer() param return false;
  proc dsiSupportsBulkTransferInterface() param return false;
  proc doiCanBulkTransferStride() param return false;
}

