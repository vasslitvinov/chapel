/////////////////////////////////////////////////////////////////////////////

const Dconst = {1..2};
var Dvar = {1..2};

writeln(Dconst._value.definedConst);  //true
writeln(Dvar._value.definedConst);    //false

var Arange: [1..2] int;   //clear
var Aconst: [Dconst] int; //clear
var Avar:   [Dvar] int;   //warn
pragma "array resize OK"
var Avarvar: [Dvar] int;  //clear

var AreshapeConst = reshape(Arange, Dconst);  //clear
var AreshapeVar   = reshape(Arange, Dvar);    //warn
pragma "array resize OK"
var AreshapeVarVar = reshape(Arange, Dvar);   //clear

/////////////////////////////////////////////////////////////////////////////

use BlockDist;

{
  const DBconst = Dvar dmapped Block(Dvar);
  var   DBvar   = Dvar dmapped Block(Dvar);

  var ABconst: [DBconst] int;  //clear
  var ABvar:   [DBvar] int;    //warn
}
{
  const DBconst = Block.createDomain(Dvar);
  var   DBvar   = Block.createDomain(Dvar);

  var ABconst: [DBconst] int;  //clear
  var ABvar:   [DBvar] int;    //warn
}
{
  var ABrange = Block.createArray(1..2, int);   //clear
  var ABconst = Block.createArray(Dconst, int); //clear
  var ABvar   = Block.createArray(Dvar, int);   //clear
}

/////////////////////////////////////////////////////////////////////////////
