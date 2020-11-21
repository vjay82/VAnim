unit MainFunc;

interface

uses Windows, Classes, Messages, SysUtils, Graphics, StrUtils;

function vExitWindowsEx(flag: word): Boolean;  // Für scheiss Privelegien von NT
function getFileList(folderAndFiles: string): TStringList;
function RunProcess(commandLine:String; MustWait: Boolean; Visibility: Word):DWORD; overload;
function RunProcess(commandLine, desktop:String; MustWait: Boolean; Visibility: Word):DWORD; overload;
function getClientWindowList(const h: integer): TList;
procedure vGetThatInSepsList( const input: string; const Sl: TStrings);
function vGetinSeps(const Sl: TStrings): string;


implementation

var
   EBX, ESI, EDI, ESP, EBP, FinA, Dens1, Dens2: Longint; // für Fadeeffekte benutzt


procedure vGetThatInSepsList( const input: string; const Sl: TStrings);
var
  startPos, endPos: integer;
begin
 Sl.clear;
 endPos:= 0;
 repeat
  startPos:= endPos+1;
  endPos:= posEx('÷', input, startPos);
  if endPos > startPos then
   Sl.Add( copy(  input, startPos, endPos-startPos));
 until startPos > endPos;
end;

function vGetinSeps(const Sl: TStrings): string;
var
 wdh: integer;
begin
 result:= '';
 for wdh:= 0 to Sl.count-1 do result:= result + Sl[wdh]+ '÷';
end;

{----------------------------------getFileList---------------------------------}
function getFileList(folderAndFiles: string): TStringList;
var
 SearchRec: TSearchRec;
begin
 result:= TStringList.create;
 if findFirst(folderAndFiles, faAnyFile, SearchRec)= 0 then
 begin
  repeat
   if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then result.Add( SearchRec.Name);
  until findNext( SearchRec)<>0;
  findClose( SearchRec);
 end;
end;

{----------------------------------getClientWindowList-------------------------}
function getClientWindowList(const h: integer): TList;
type
 pList= ^TList;
 function enumWindowsProc (hWnd: integer;  bla: pointer): BOOL; stdcall;
 begin
 // enumChildWindows( h, @enumWindowsProc, integer(bla));
  pList(bla)^.Add( pointer( hWnd));
  result:= true;
 end;
begin
 result:= TList.create;
 enumChildWindows( h, @enumWindowsProc, integer(@result));
end;


function vExitWindowsEx(flag: word): Boolean;  // Für scheiss Privelegien von NT
var
  vi     : TOSVersionInfo;
  hToken : THandle;
  tp     : TTokenPrivileges;
  h      : DWord;
begin
  vi.dwOSVersionInfoSize:=SizeOf(vi);
  GetVersionEx(vi);
  if vi.dwPlatformId = VER_PLATFORM_WIN32_NT then
  begin // Windows NT
    OpenProcessToken(GetCurrentProcess(),TOKEN_ADJUST_PRIVILEGES,hToken);
    LookupPrivilegeValue(nil,'SeShutdownPrivilege',tp.Privileges[0].Luid);
    tp.PrivilegeCount := 1;
    tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    h := 0;
    AdjustTokenPrivileges(hToken,False,tp,0,PTokenPrivileges(nil)^,h);
    CloseHandle(hToken);
    result := ExitWindowsEx(flag,0);
  end
  else
  begin // Windows 95
    Result := ExitWindowsEx(flag,0);
  end;
end;

{----------------------------------RunProcess----------------------------------}
{** Startet einen anderen Prozess}
function RunProcess(commandLine, desktop:String; MustWait: Boolean; Visibility: Word):DWORD;
var
 SI: TStartupInfo;
 PI: TProcessInformation;
 Proc: THandle;
begin
 FillChar(SI, SizeOf(SI), 0);
 SI.cb := SizeOf(SI);
 SI.dwFlags := STARTF_USESHOWWINDOW;
 SI.wShowWindow := Visibility;
 SI.lpDesktop := pchar( desktop);
 if not CreateProcess(NIL, pchar(commandLine),
  nil, nil, false, Normal_Priority_Class, nil, nil, SI, PI) then
   raise Exception.CreateFmt('Fehler beim Ausführen von: ' + commandLine + '. Fehlercode: %d', [GetLastError]);

 Proc := PI.hProcess;
 CloseHandle(PI.hThread);

 if MustWait then
  if WaitForSingleObject(Proc, Infinite) <> Wait_Failed then
   GetExitCodeProcess(Proc, Result);

 CloseHandle(Proc);
end;

{----------------------------------RunProcess----------------------------------}
{** Startet einen anderen Prozess}
function RunProcess(commandLine:String; MustWait: Boolean; Visibility: Word):DWORD;
begin
 result:= RunProcess(commandLine, '', MustWait, Visibility);
end;
end.
