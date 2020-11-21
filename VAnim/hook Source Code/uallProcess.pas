unit uallProcess;

interface

uses windows, tlhelp32, uallUtil, uallProtect, uallKernel;

function FindProcess(ExeNames: string): integer; stdcall;
function FindModulesInProcess(pid: cardinal): string; stdcall; overload;
function FindModulesInProcess(processname: string): string; stdcall; overload;
function FindAllProcesses: string; stdcall;
function GetThread(pid: integer): integer; stdcall;

implementation

function GetThread(pid: integer): integer; stdcall;
var
  FSnapshotHandle: THandle;
  FThreadEntry32: TThreadEntry32;
  ContinueLoop: boolean;
begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD,0);
  FThreadEntry32.dwSize := Sizeof(FThreadEntry32);
  ContinueLoop := Thread32First(FSnapshotHandle,FThreadEntry32);
  while ContinueLoop do
  begin
    if (integer(FThreadEntry32.th32OwnerProcessID) = pid) then
    begin
      result := FThreadEntry32.th32ThreadID;
      exit;
    end;
    ContinueLoop := Thread32Next(FSnapshotHandle,FThreadEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;



function FindModulesInProcess(processname: string): string; stdcall; overload;
begin
  result := FindModulesInProcess(FindProcess(processname));
end;

function FindModulesInProcess(pid: cardinal): string; stdcall; overload;
var s: string;
    FSnapshotHandle: THandle;
    FModuleEntry32: TModuleEntry32;
    ContinueLoop: BOOL;
begin
  if (pid <> 0) then
  begin
    FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE,pid);
    FModuleEntry32.dwSize := Sizeof(FModuleEntry32);
    ContinueLoop := Module32First(FSnapshotHandle,FModuleEntry32);
    result := '';
    while ContinueLoop do
    begin
      s := s+FModuleEntry32.szModule+#13#10;
      ContinueLoop := Module32Next(FSnapshotHandle,FModuleEntry32);
    end;
    result := s;
    CloseHandle(FSnapshotHandle);
  end;
end;

function FindAllProcesses: string; stdcall;
var
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  ContinueLoop: BOOL;
  s: string;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle,FProcessEntry32);
  s := '';
  while ContinueLoop do
  begin
    s := s+uppercase(extractfilename(FProcessEntry32.szExeFile))+#13#10;
    ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32);
  end;
  if length(s) > 0 then result := copy(s,1,length(s)-2);
  CloseHandle(FSnapshotHandle);
end;

function FindProcess(ExeNames: string): integer; stdcall;
  function DeleteExe(s: string): string;
  var i, j: integer;
  begin
    setlength(result,length(s));
    result := '';
    j := 0;
    for i := 1 to length(s) do
    begin
      if (copy(s,i,6) = ('.EXE'#13#10)) then
        j := 4;
      if (j > 0) then
        dec(j) else result := result+s[i];
    end;
  end;
var
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  ContinueLoop: BOOL;
  exesearch,exeprocess: string;
  i: integer;
begin
  result := 0;
  exesearch := deleteexe(uppercase(#13#10+exenames+#13#10));
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle,FProcessEntry32);
  while ContinueLoop do
  begin
    exeprocess := uppercase(uallUtil.extractfilename(FProcessEntry32.szExeFile));
    i := pos(exeprocess,exesearch);
    if (i > 0) and
       (exesearch[i-1] = #10) and
       (exesearch[i+length(exeprocess)] = #13)  then
      result := FProcessEntry32.th32ProcessID;
    ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

initialization
begin
  GetDebugPrivilege;
end;

finalization
begin
end;

end.
