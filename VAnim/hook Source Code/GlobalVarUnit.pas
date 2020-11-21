unit GlobalVarUnit;

interface

uses Windows, Messages, SyncObjs, Classes, SysUtils, MovingControlsUnit;

const
 MMFName = 'looksBetterMMF';
 debug = false;

type
 THookedControlTyp = (hktButton, hktProgressBar, hktHalo);

 PInfos = ^TInfos;
 TInfos = packed record
  active_ButtonPulser: Boolean;
  active_ProgressBarAnimator: Boolean;
  active_HaloControls: Boolean;
  mypath: string[255];
  CBTHookHandle: hHook;
  exclusionList: string[255];
 end;

 PHookedControl = ^THookedControl;
 THookedControl = record
  handle: integer;
  typ: THookedControlTyp;
  origWndFunction: pointer;
  Objekt: pointer;
 end;

var
 hMMF: THandle = 0;
 Infos: PInfos;
 excluded: Boolean = false;
 HookedControls: TList = NIL;
 GesperrteControls: TList;
 Lock: TCriticalSection = NIL;
 MovedControls: TMovedControls;

function getHKTIndex( const handle: integer): integer;
function looksBetterWindowProc( handle: dWord; Msg: cardinal; wParam: dWord; lParam: dWord): dWord; stdcall;
procedure deInitControl(const handle: integer);

implementation

uses PulseButtonUnit, ProgressBarUnit, HaloUnit;

procedure deInitControl(const handle: integer);
var
 i1: integer;
 HookedControl: PHookedControl;
begin

 Lock.Acquire;
 i1:= getHKTIndex( handle);
 if i1 <> -1 then
 begin
  HookedControl:= HookedControls[i1];
  HookedControls.delete( i1);
 end
 else HookedControl:= NIL;
 Lock.Release;

 if HookedControl <> NIL then
 begin
  case HookedControl.typ of
   hktButton: deInitPulseButton( HookedControl.objekt);
   hktProgressBar: deInitProgressBar( HookedControl.objekt);
   hktHalo: deInitHalo( HookedControl.objekt);
  end;
  dispose( HookedControl);
 end;
end;

procedure paintCount( const handle: dword);
var
 dc: HDC;
 s1: string;
begin
 Lock.Acquire;
 s1:= intToStr( HookedControls.count);
 Lock.Release;
 dc:= getDC( handle);
 textOut(dc, 0, 0, pchar( s1), length(s1));
 releaseDC( handle, dc);
end;

function looksBetterWindowProc( handle: dWord; Msg: cardinal; wParam: dWord; lParam: dWord): dWord; stdcall;
var
 i1: integer;
 wndProc: pointer;
 typ: THookedControlTyp;
 Objekt: pointer;
 mustDo: Boolean;
begin
 if hookedControls <> NIL then
 begin
  Lock.Acquire;
  i1:= getHKTIndex( handle);
  if i1 <> -1 then
  begin
   wndproc:= PHookedControl( HookedControls[i1]).origWndFunction;
   typ:= PHookedControl( HookedControls[i1]).typ;
   Objekt:= PHookedControl( HookedControls[i1]).objekt;
  end;
  Lock.Release;


  if i1 <> -1 then
  begin
   mustDo:= true;
   case typ of
    hktButton: mustDo:= buttonWndProc( handle, Msg, wParam, lParam, objekt, result);
    hktProgressBar: mustDo:= progressBarWndProc( handle, Msg, wParam, lParam, objekt, result);
    hktHalo: mustDo:= haloWndProc( handle, Msg, wParam, lParam, objekt, result);
   end;
   if mustDo then Result := CallWindowProc( wndProc, handle, Msg, wParam, lParam);
  end
  else // oh shitte
   Result := DefWindowProc( handle, Msg, wParam, lParam);
 end
 else
  Result := DefWindowProc( handle, Msg, wParam, lParam);
end;

function getHKTIndex( const handle: integer): integer;
var
 wdh: integer;
begin
 if HookedControls<>NIL then
 begin
  for wdh:= HookedControls.count-1 downto 0 do
   if PHookedControl( HookedControls[wdh]).handle = handle then
   begin
    result:= wdh;
    exit;
   end;
 end;
 result:= -1;
end;

end.
