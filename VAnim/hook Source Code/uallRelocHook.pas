{by uall}

unit uallRelocHook;

interface

uses windows, tlhelp32, uallKernel;

function HookRelocationTable(oldaddress, newaddress: pointer; var nextaddress: pointer): integer; stdcall;
function UnHookRelocationTable(nextaddress, newaddress: pointer): integer; stdcall;

implementation

type
     PTableAddress = ^TTableAddress;
     TTableAddress = record
                       oldaddr: pointer;
                       newaddr: pointer;
                       next: PTableAddress;
                     end;

var
  oldGetProcAddress: function(hmodule: integer; procname: pchar): pointer; stdcall;
  nextGetProcAddress: function(hmodule: integer; procname: pchar): pointer; stdcall;

  oldLoadLibraryA: function(modulename: PChar): integer; stdcall;
  nextLoadLibraryA: function(modulename: PChar): integer; stdcall;


  Table: PTableAddress = nil;
  isGlobalHookPossible: boolean = false;

function HookRelocationTableModule(hmodule: integer; oldaddress, newaddress: pointer; var nextaddress: pointer): integer; stdcall;
type TRelocBlock = record
                     vaddress: integer;
                     size: integer;
                   end;
     PRelocBLock = ^TRelocBlock;
var myreloc: PRelocBlock;
    reloccount: integer;
    startp: ^word;
    i: integer;
    p: ^integer;
    IDH: PImageDosHeader;
    INH: PImageNtHeaders;
    old: cardinal;
begin
  result := -1;
  IDH := pointer(hmodule);
  if (not IsBadReadPtr(IDH,4)) and (IDH^.e_magic = IMAGE_DOS_SIGNATURE) then
  begin
    INH := pointer(cardinal(hmodule)+cardinal(IDH^._lfanew));
    if (not IsBadReadPtr(INH,4)) and (INH^.Signature = IMAGE_NT_SIGNATURE) then
    begin
      myreloc := pointer(hmodule+integer(INH^.OptionalHeader.DataDirectory[5].VirtualAddress));
      startp := pointer(integer(myreloc)+8);
      while (not isbadreadptr(myreloc,8)) and (myreloc^.vaddress <> 0) do
      begin
        reloccount := (myreloc^.size-8) div sizeof(word);
        for i := 0 to reloccount-1 do
        begin
          if (not isbadreadptr(startp,2)) and  (startp^ xor $3000 < $1000) then
          begin
            p := pointer(myreloc^.vaddress+startp^ mod $3000+hmodule);
            if (not isbadreadptr(pointer(integer(p)-2),6)) and
               (pbyte(integer(p)-2)^ = $FF) and
               ((pbyte(integer(p)-1)^ = $25) or (pbyte(integer(p)-1)^ = $15)) and
               (not isbadreadptr(pointer(p^),4)) and
               (not isbadreadptr(ppointer(p^)^,4)) and
               (ppointer(p^)^ = oldaddress) then
            begin
              if VirtualProtect(pointer(p^),4,PAGE_EXECUTE_READWRITE,old) then
              begin
                ppointer(p^)^ := newaddress;
                inc(result);
                VirtualProtect(pointer(p^),4,old,old);
              end;
            end;
          end;
          startp := pointer(integer(startp)+sizeof(word));
        end;
        myreloc := pointer(startp);
        startp := pointer(integer(startp)+8);
      end;
    end;
  end;
  nextaddress := oldaddress;
end;

procedure HookNewLibrary(Table: PTableAddress; hmodule: integer);
var dummy: pointer;
begin
  while (Table <> nil) do
  begin
    HookRelocationTableModule(hmodule,Table^.oldaddr,Table^.newaddr,dummy);
    Table := Table^.next;
  end;
end;

function ChangeTableAddress(Table: PTableAddress; oldAddress: pointer): pointer;
begin
  result := oldAddress;
  while (Table <> nil) do
  begin
    if Table^.oldaddr = oldaddress then
    begin
      result := Table^.newaddr;
      exit;
    end else
      Table := Table^.next;
  end;
end;

procedure RemoveFromTable(var Table: PTableAddress; oldAddress: pointer);
var Tablex, TableY: PTableAddress;
begin
  TableY := Table;
  if (Table <> nil) then
  begin
     if (Table^.oldaddr = oldAddress) then
     begin
       Tablex := Table^.next;
       Dispose(Table);
       Table := Tablex;
     end else
     begin
        while TableY^.next <> nil do
        begin
          Tablex := TableY^.next;
          if Tablex.newaddr = oldAddress then
          begin
            TableY^.next := Tablex^.next;
            Dispose(Tablex);
            Exit;
          end;
          TableY := TableY^.next;
        end;
     end;
  end;
end;


procedure AddToTable(var Table: PTableAddress; oldAddress, newAddress: pointer);
var Tablex: PTableAddress;
begin
  if (Table = nil) then
  begin
    New(Table);
    Table^.next := nil;
    Table^.oldaddr := oldAddress;
    Table^.newaddr := newAddress;
  end else
  begin
    Tablex := Table;
    while (Tablex^.next <> nil) do
      Tablex := Tablex^.next;
    New(Tablex^.next);
    Tablex^.next^.oldaddr := oldAddress;
    Tablex^.next^.newaddr := newAddress;
    Tablex^.next^.next := nil;
  end;
end;

function myGetProcAddress(hmodule: integer; procname: pchar): pointer; stdcall;
begin
  result := nextGetProcAddress(hmodule, procname);
  if (cardinal(result) < $80000000) or (isGlobalHookPossible) then
    result := ChangeTableAddress(Table,result);
end;

function myLoadLibraryA(modulename: PChar): integer; stdcall;
begin
  result := nextLoadLibraryA(modulename);
  HookNewLibrary(Table,result);
end;

function HookRelocationTableAllModules(oldaddress, newaddress: pointer; var nextaddress: pointer): integer; stdcall;
var hsnap: integer;
    lpme: tagMODULEENTRY32;
begin
  result := 0;
  hsnap := CreateToolHelp32Snapshot(TH32CS_SNAPMODULE,GetCurrentProcessID);
  if (hsnap > 0) then
  begin
    lpme.dwSize := sizeOf(lpme);
    if Module32First(hsnap,lpme) then
    begin
      repeat
        inc(result,HookRelocationTableModule(lpme.hModule,oldaddress,newaddress,nextaddress));
      until (not Module32Next(hsnap,lpme));
    end;
    CloseHandle(hsnap);
  end;
end;

function UnHookRelocationTable(nextaddress, newaddress: pointer): integer; stdcall;
var dummy: pointer;
begin
  if (cardinal(nextaddress) < $80000000) or (isGlobalHookPossible) then
  begin
    result := HookRelocationTableAllModules(newaddress,nextaddress,dummy);
    RemoveFromTable(Table,newaddress);
  end else result := 0;
end;

function HookRelocationTable(oldaddress, newaddress: pointer; var nextaddress: pointer): integer; stdcall;
begin
  if (cardinal(oldaddress) < $80000000) or (isGlobalHookPossible) then
  begin
    AddToTable(Table,oldaddress,newaddress);
    result := HookRelocationTableAllModules(oldaddress,newaddress,nextaddress);
  end else result := 0;
end;

initialization
begin
  Table := nil;
  isGlobalHookPossible := (GetVersion and $80000000 = 0) or (GetOwnModuleHandle > $80000000);
  if isGlobalHookPossible then
  begin
    @oldGetProcAddress := GetProcAddress(GetModuleHandle('kernel32.dll'),'GetProcAddress');
    @oldLoadLibraryA := GetProcAddress(GetModuleHandle('kernel32.dll'),'LoadLibraryA');

    HookRelocationTable(@oldGetProcAddress,@myGetProcAddress,@nextGetProcAddress);
    HookRelocationTable(@oldLoadLibraryA,@myLoadLibraryA,@nextLoadLibraryA);
  end;
end;

finalization
begin
  if isGlobalHookPossible then
  begin
    UnHookRelocationTable(@nextLoadLibraryA,@myLoadLibraryA);
    UnHookRelocationTable(@nextGetProcAddress,@myGetProcAddress);
  end;
end;

end.
