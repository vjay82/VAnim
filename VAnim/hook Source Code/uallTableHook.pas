unit uallTableHook;

interface

uses windows;

function myInstructionLength(addr: pointer): integer; stdcall;
function UnhookAPIJMP(nextfunction: pointer): boolean; stdcall;
function HookAPIJMP(oldfunction,yourfunction: pointer; var nextfunction: pointer): boolean; stdcall;

implementation


const
  OP_eins = -1;
  OPnull = 0;
  OPeins = 1;
  OPzwei = 2;
  OPdrei = 3;
  OPvier = 4;
  OPfuenf = 5;
  OPsechs = 6;
  OPsieben = 7;
  OPacht = 8;
  OPneun = 9;
  OPzehn = 10;
  OPtable7 = 11;  // table2 +1  (ok)
  OPtable2 = 12;  //            (ok)
  OPtable5 = 15;  //            (ok)
  OPtable6 = 16;  // table2 +4  (ok)
  OPtableFF = 17; //            (ok)
  OPtableF7 = 18; //            (ok)
  OPtable8 = 19;  //            (ok)
  OPtableFE = 20; //            (ok)
  OPtableDD = 21; //            (ok)
  OPtable0F = 22; //            (ok)
  OPtable = 23;
  OPtable3 = 24;

var firsttable: array[$00..$FF] of integer =

(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPnull  ,OPtable0F,
OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPtable ,OPnull  ,OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPtable ,OPnull  ,
OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPtable ,OPnull  ,OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPvier  ,OPtable ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPtable2,OPtable2,OPtable ,OPtable ,OPtable ,OPtable ,OPvier  ,OPtable6,OPeins  ,OPtable7,OPnull  ,OPnull,  OPnull  ,OPnull  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,
OPtable7,OPtable6,OPtable7,OPtable7,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPsechs ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,
OPtable7,OPzwei  ,OPzwei  ,OPnull  ,OPtable2,OPtable2,OPtable7,OPtable6,OPvier  ,OPnull  ,OPzwei  ,OPnull  ,OPnull  ,OPeins  ,OPnull  ,OPnull  ,
OPtable2,OPtable2,OPtable2,OPtable2,OPeins  ,OPeins  ,OPnull  ,OPnull  ,OPtable2,OPtable2,OPtable2,OPtable2,OPtable2,OPtableDD,OPtable2,OPtable2,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPvier  ,OPvier  ,OPsechs ,OPeins  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPtable ,OPnull  ,OPtable ,OPtable ,OPnull  ,OPnull  ,OPtable8,OPtableF7,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPtableFE,OPtableFF);


var thirdtable: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPvier  ,OPnull  ,OPnull);

var secondtable: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPtable3  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPtable3  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPtable3  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPtable3  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  );

var fftable: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins );

var f7table: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPacht  ,OPvier  ,OPvier  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPfuenf ,OPeins  ,OPeins  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPsechs ,OPfuenf ,OPfuenf ,OPfuenf ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPacht  ,OPacht  ,OPacht  ,OPacht  ,OPneun  ,OPacht  ,OPacht  ,OPacht  ,OPfuenf ,OPfuenf ,OPfuenf ,OPfuenf ,OPsechs ,OPfuenf ,OPfuenf ,OPfuenf ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull);

var table8: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPfuenf ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPfuenf ,OPeins  ,OPeins  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPdrei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPzwei  ,OPdrei  ,OPzwei  ,OPzwei  ,OPzwei  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPfuenf ,OPfuenf ,OPfuenf ,OPfuenf ,OPsechs ,OPfuenf ,OPfuenf ,OPfuenf ,OPfuenf ,OPfuenf ,OPfuenf ,OPfuenf ,OPsechs ,OPfuenf ,OPfuenf ,OPfuenf ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull);

var fetable: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins);

var ddtable: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPeins  ,OPvier  ,OPnull  ,OPnull  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPeins  ,OPzwei  ,OPeins  ,OPeins  ,OPeins  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,OP_eins ,
OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPvier  ,OPfuenf ,OPnull ,OPvier  ,OPvier  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OP_eins  ,OPnull  ,OPnull ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,
OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OPnull  ,OP_eins ,OPnull  ,OPnull  );

var table0F: array[$00..$FF] of integer =
(
  // $0     $1      $2        $3      $4       $5      $6        $7       $8        $9      $a       $b       $c       $d       $e      $f
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OP_eins  ,OP_eins  ,OPnull   ,OP_eins  ,OPnull   ,OP_eins  ,OP_eins  ,OPnull   ,OP_eins  ,OPtable  ,OPnull   ,OPtable ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins  ,OP_eins ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier   ,OPvier  ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull    ,OPnull  ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull   ,OPnull  ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,
OP_eins  ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OPtable2 ,OP_eins);

function myInstructionLength(addr: pointer): integer; stdcall;
var anzahl: integer;
    fertig: boolean;
    b: ^byte;
    x: integer;
begin
  fertig := false;
  anzahl := 1;
  b := addr;
  x := firsttable[b^];
  repeat
    case x of
      -1..10:
      begin
        inc(anzahl,x);
        fertig := true;
      end;
      OPtable:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        x := firsttable[b^];
      end;
      OPtable2:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        x := secondtable[b^];
      end;
      OPtable7:
      begin
        inc(anzahl,2);
        b := pointer(integer(b)+1);
        x := secondtable[b^];
      end;
      OPtable6:
      begin
        inc(anzahl,5);
        b := pointer(integer(b)+1);
        x := secondtable[b^];
      end;
      OPtableFF:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        inc(anzahl,FFtable[b^]);
        fertig := true;
      end;
      OPtableF7:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        inc(anzahl,F7table[b^]);
        fertig := true;
      end;
      OPtableFE:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        inc(anzahl,FEtable[b^]);
        fertig := true;
      end;
      OPtableDD:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        inc(anzahl,DDtable[b^]);
        fertig := true;
      end;
      OPtable8:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        inc(anzahl,table8[b^]);
        fertig := true;
      end;
      OPtable3:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        inc(anzahl,thirdtable[b^]);
        fertig := true;
      end;
      OPtable0f:
      begin
        inc(anzahl);
        b := pointer(integer(b)+1);
        x := table0f[b^];
      end else fertig := true
    end;
  until fertig;
  result := anzahl;
end;


function UnhookAPIJMP(nextfunction: pointer): boolean; stdcall;
type
  tjumpcode = packed
  record
    nix: byte;
    JMP: Byte;
    Distance: Integer;
  end;
var old: cardinal;
    anzahl, gesamt,origfkt: cardinal;
    jcode: ^tjumpcode;
begin
  result := false;
  gesamt := 0;
  repeat
    virtualprotect(nextfunction,12,PAGE_EXECUTE_READWRITE,old);
    anzahl := myInstructionLength(nextfunction);
    virtualprotect(nextfunction,anzahl,old,old);
    nextfunction := pointer(cardinal(nextfunction)+anzahl);
    inc(gesamt,anzahl);
  until gesamt >= sizeof(tjumpcode);
  jcode := nextfunction;
  if (jcode^.nix = $65) and
     (jcode^.JMP = $E9) then
  begin
    origfkt := cardinal(jcode^.Distance)+6+cardinal(nextfunction)-gesamt;
    jcode := pointer(origfkt);
    if (jcode^.nix = $65) and
       (jcode^.JMP = $E9) then
    begin
      nextfunction := pointer(cardinal(nextfunction)-gesamt);
      copymemory(pointer(origfkt),nextfunction,gesamt);
      freemem(nextfunction);
      result := true;
    end;
  end;
end;

function HookAPIJMP(oldfunction,yourfunction: pointer; var nextfunction: pointer): boolean; stdcall;
type
  tjumpcode = packed
  record
    nix: byte;
    JMP: Byte;
    Distance: Integer;
  end;
var anzahl, gesamt: integer;
    old: cardinal;
    jmpcode: tjumpcode;
begin
  result := false;
  jmpcode.nix := $65;
  jmpcode.jmp := $E9;
  gesamt := 0;
  repeat
    virtualprotect(oldfunction,12,PAGE_EXECUTE_READWRITE,old);
    anzahl := myInstructionLength(oldfunction);
    virtualprotect(oldfunction,anzahl,old,old);
    oldfunction := pointer(integer(oldfunction)+anzahl);
    inc(gesamt,anzahl);
  until gesamt >= sizeof(tjumpcode);
  oldfunction := pointer(integer(oldfunction)-gesamt);

  getmem(nextfunction,gesamt+sizeof(tjumpcode));
  if virtualprotect(oldfunction,gesamt,PAGE_EXECUTE_READWRITE,old) and
     virtualprotect(nextfunction,gesamt+sizeof(tjumpcode),PAGE_EXECUTE_READWRITE,old) then
  begin
    copymemory(nextfunction,oldfunction,gesamt);
    jmpcode.distance := (integer(oldfunction)+gesamt)-(integer(nextfunction)+gesamt)-6;
    copymemory(pointer(integer(nextfunction)+gesamt),@jmpcode,sizeof(tjumpcode));
    jmpcode.distance := (integer(yourfunction))-(integer(oldfunction))-6;
    copymemory(oldfunction,@jmpcode,sizeof(jmpcode));
    result := true;
    virtualprotect(oldfunction,gesamt,old,old);
    virtualprotect(oldfunction,gesamt+sizeof(tjumpcode),old,old);
  end;
end;


end.
