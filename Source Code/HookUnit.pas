unit HookUnit;

interface

uses Windows;

function startHook: Boolean;
procedure stopHook;
procedure updateHook;

implementation

var
 DLLHandle: integer = 0;

procedure stopHook;
type
 TStopHook = procedure;
begin
 TStopHook( getProcAddress(DLLHandle, 'stopHook'));
 freeLibrary( DLLHandle);
 DllHandle:= 0;
end;

procedure updateHook;
type
 TStopHook = procedure;
begin
 TStopHook( getProcAddress(DLLHandle, 'updateSettings'));
end;

function startHook: Boolean;
type
 TstartHook = function ( p: pchar): Boolean; stdcall;
var
 startHook: TStartHooK;
 s1: string;
 lastpos, wdh: integer;
begin
 if DLLHandle = 0 then DLLHandle:= loadLibrary('VAnim\VAnimHook.dll');
 @startHook:= getProcAddress(DLLHandle, 'startHook');
 lastPos:= 0;
 s1:= paramstr(0);
 for wdh:= 1 to length(s1) do
  if s1[wdh] = '\' then lastPos:= wdh;

 s1:= copy(s1, 1, lastPos) + 'VAnim\';

 if length(s1)>255 then
 begin
  MessageBox(0, 'Error, to save memory i decided to limit the length of the path, the program runs in to 255 chars. Please copy it to a shorter filepath.', 'VAnim', 0);
  postQuitMessage( 0);
 end
 else result:= startHook( pchar( s1));
end;

end.
