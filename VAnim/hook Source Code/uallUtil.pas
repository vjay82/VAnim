unit uallUtil;

interface

uses windows;

function ExtractFileNameWithExtention(s: string): string; stdcall;
function ExtractFileName(s: string): string; stdcall;
function UpperCase(s: string): string; stdcall;
function ExtractFilePath(s: String): string; stdcall;
function IntToStr(Value: integer): string; stdcall;
function IntToHex(Value, Digits: integer): string; stdcall;
function LowerCase(s: string): string; stdcall;
function GetExeDirectory: string; stdcall;
function isNT: boolean; stdcall;
function is9x: boolean; stdcall;

implementation

function is9x: boolean; stdcall;
asm
  MOV     EAX, FS:[030H]
  TEST    EAX, EAX
  SETS    AL
end;

function isNT: boolean; stdcall;
begin
  result := (GetVersion and $80000000) = 0;
end;

function ExtractFileNameWithExtention(s: string): string; stdcall;
var i,j: integer;
begin
  j := 0;
  for i := 1 to length(s) do
    if (s[i] = '\') then j := i;
  result := copy(s,j+1,length(s));
end;

function ExtractFilePath(s: string): string; stdcall;
var i,j: integer;
begin
  j := length(s);
  for i := 1 to length(s) do
    if s[i] = '\' then j := i;
  result := copy(s,1,j);
end;

function GetExeDirectory: string; stdcall;
begin
  result := ExtractFilePath(ParamStr(0));
end;

function IntToHex(Value, Digits: integer): string; stdcall;
const hex: array[0..$F] of char =
  ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
begin
  result := copy(
       hex[(Value and $F0000000) shr 28]+
       hex[(Value and $0F000000) shr 24]+
       hex[(Value and $00F00000) shr 20]+
       hex[(Value and $000F0000) shr 16]+
       hex[(Value and $0000F000) shr 12]+
       hex[(Value and $00000F00) shr 8]+
       hex[(Value and $000000F0) shr 4]+
       hex[(Value and $0000000F) shr 0],9-Digits,Digits);
end;

function IntToStr(Value: integer): string; stdcall;
var Minus : Boolean;
begin
   Result := '';
   if Value = 0 then
      Result := '0';
   Minus := Value < 0;
   if Minus then
      Value := -Value;
   while Value > 0 do
   begin
      Result := Char( (Value mod 10) + Integer( '0' ) ) + Result;
      Value := Value div 10;
   end;
   if Minus then
      Result := '-' + Result;
end;

function LowerCase(s: string): string; stdcall;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'A') and (Ch <= 'Z') then Inc(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function UpperCase(s: string): string; stdcall;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function ExtractFileName(s: string): string; stdcall;
var i, j: integer;
begin
  j := 0;
  for i := 1 to length(s) do
    if (s[i] = '\') then j := i;
  s := copy(s,j+1,length(s));
  j := 0;
  for i := 1 to length(s) do
    if (s[i] = '.') then j := i;
  if j = 0 then j := length(s)+1;
  result := copy(s,1,j-1);
end;


end.
