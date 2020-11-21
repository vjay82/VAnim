unit uallHook;

interface

uses windows, uallDisasm, uallProcess, uallKernel, tlhelp32;

function HookCode(oldfunction, yourfunction: pointer; var nextfunction: pointer): boolean; stdcall;
function UnhookCode(var nextfunction: pointer): boolean; stdcall;
function HookApiIAT(modulehandle: integer; oldfunction, yourfunction: pointer): boolean; stdcall; overload;
function HookApiIAT(oldfunction, yourfunction: pointer): boolean; stdcall; overload;
function InjectMe(pid: integer; dllmain: pointer): boolean; stdcall;
function InjectLibrary(pid: cardinal; dlln: pchar): pointer; stdcall;
function UnloadLibrary(pid: cardinal; dlln: pchar): pointer; stdcall;
function GlobalUnloadLibrary(libname: pchar): integer; stdcall;
function GlobalInjectLibrary(libname: pchar): integer; stdcall;

implementation

function GlobalInjectLibrary(libname: pchar): integer; stdcall;
var
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  ContinueLoop: BOOL;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle,FProcessEntry32);
  result := 0;
  while ContinueLoop do
  begin
    if uallHook.InjectLibrary(FProcessEntry32.th32ProcessID,libname) <> nil then
      inc(result);
    ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function GlobalUnloadLibrary(libname: pchar): integer; stdcall;
var
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  ContinueLoop: BOOL;
  s: string;
begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle,FProcessEntry32);
  s := '';
  while ContinueLoop do
  begin
    if uallHook.UnloadLibrary(FProcessEntry32.th32ProcessID,libname) <> nil then
      inc(result);
    ContinueLoop := Process32Next(FSnapshotHandle,FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function UnloadLibrary(pid: cardinal; dlln: pchar): pointer; stdcall;
  procedure ASMbegin; assembler;
  asm
    push $12345678
    call [$00000000]
    push eax
    call [$00000000]
  end;
  procedure ASMend; assembler;
  begin
  end;
var pid2: cardinal;
    mem, asmmem, oldFreeLibrary,oldGetModuleHandleA: pointer;
    written: cardinal;
    asmsize: cardinal;
    nchange: ^cardinal;
    s: string;
begin
  result := nil;
  pid2 := OpenProcess(PROCESS_ALL_ACCESS,false,pid);
  if pid2 = 0 then {MessageBoxA(0,'process is not valid or opened',nil,0)} else
  begin
    asmsize := cardinal(@asmend)-cardinal(@asmbegin);
    mem := VirtualAllocExX(pid2,cardinal(length(s))+1+asmsize+4);
    if (mem <> nil) then
    begin
      s := dlln;
      oldFreeLibrary := GetProcAddress( LoadLibrary('kernel32.dll'), 'FreeLibrary');
      oldGetModuleHandleA := GetProcAddress( LoadLibrary('kernel32.dll'), 'GetModuleHandleA');
      asmmem := VirtualAlloc(nil,asmsize+1+cardinal(length(s))+8,MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
      if asmmem <> nil then
      begin
        CopyMemory(asmmem,@asmbegin,asmsize);
        nchange := pointer(cardinal(asmmem)+1);
        nchange^ := cardinal(mem)+asmsize+8;
        nchange := pointer(cardinal(asmmem)+7);
        nchange^ := cardinal(mem)+asmsize;
        nchange := pointer(cardinal(asmmem)+14);
        nchange^ := cardinal(mem)+asmsize+4;

        nchange := pointer(cardinal(asmmem)+asmsize+4);
        nchange^ := cardinal(oldFreeLibrary);
        nchange := pointer(cardinal(asmmem)+asmsize);
        nchange^ := cardinal(oldGetModuleHandleA);
        CopyMemory(pointer(cardinal(asmmem)+asmsize+8),@s[1],length(s));
        if WriteProcessMemory(pid2,mem,asmmem,asmsize+1+cardinal(length(s))+8,written) and
           CreateRemoteThreadX(pid,mem) then
             result := mem;
      end;
      VirtualFree(asmmem,asmsize+1+cardinal(length(s))+8,MEM_DECOMMIT);
    end;
    CloseHandle(pid2);
  end;
end;

function InjectLibrary(pid: cardinal; dlln: pchar): pointer; stdcall;
  procedure ASMbegin; assembler;
  asm
    push $12345678
    call [$00000000]
  end;
  procedure ASMend; assembler;
  begin
  end;
var pid2: cardinal;
    mem, asmmem, oldLoadLibraryA: pointer;
    written: cardinal;
    asmsize: cardinal;
    nchange: ^cardinal;
    s: string;
begin
  result := nil;
  pid2 := OpenProcess(PROCESS_ALL_ACCESS,false,pid);
  if pid2 = 0 then {MessageBoxA(0,'process is not valid or opened',nil,0)} else
  begin
    asmsize := cardinal(@asmend)-cardinal(@asmbegin);
    mem := VirtualAllocExX(pid2,cardinal(length(s))+1+asmsize+4);
    if (mem <> nil) then
    begin
      s := dlln;
      oldLoadLibraryA := GetProcAddress( LoadLibrary('kernel32.dll'), 'LoadLibraryA');
      asmmem := VirtualAlloc(nil,asmsize+1+cardinal(length(s))+4,MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
      if asmmem <> nil then
      begin
        CopyMemory(asmmem,@asmbegin,asmsize);
        nchange := pointer(cardinal(asmmem)+1);
        nchange^ := cardinal(mem)+asmsize+4;
        nchange := pointer(cardinal(asmmem)+7);
        nchange^ := cardinal(mem)+asmsize;
        nchange := pointer(cardinal(asmmem)+asmsize);
        nchange^ := cardinal(oldLoadLibraryA);
        CopyMemory(pointer(cardinal(asmmem)+asmsize+4),@s[1],length(s));
        if WriteProcessMemory(pid2,mem,asmmem,asmsize+1+cardinal(length(s))+4,written) and
           CreateRemoteThreadX(pid,mem) then
             result := mem;
      end;
      VirtualFree(asmmem,asmsize+1+cardinal(length(s))+4,MEM_DECOMMIT);
    end;
    CloseHandle(pid2);
  end;
end;

function InjectMe(pid: integer; dllmain: pointer): boolean; stdcall;
  procedure ChangeReloc(baseorgp, basedllp, relocp, basedllpop: pointer; size: integer);
  type trelocblock = record
                       vaddress: integer;
                       size: integer;
                     end;
       prelocblock = ^trelocblock;
  var myreloc: prelocblock;
      reloccount: integer;
      startp: ^word;
      i: integer;
      p: ^integer;
      dif: integer;
  begin
    myreloc := relocp;
    dif := integer(basedllpop)-integer(baseorgp);
    startp := pointer(integer(relocp)+8);
    while myreloc^.vaddress <> 0 do
    begin
      reloccount := (myreloc^.size-8) div sizeof(word);
      for i := 0 to reloccount-1 do
      begin
        if (startp^ xor $3000 < $1000) then
        begin
          p := pointer(myreloc^.vaddress+startp^ mod $3000+integer(basedllp));
          p^ := p^+dif;
        end;
        startp := pointer(integer(startp)+sizeof(word));
      end;
      myreloc := pointer(startp);
      startp := pointer(integer(startp)+8);
    end;
  end;

var h: integer;
    IDH: PImageDosHeader;
    INH: PImageNtHeaders;
    mem, mem2: pointer;
    written: cardinal;
    size: integer;
begin
  result := false;
  h := GetModuleHandleA(nil);
  if h <> 0 then
  begin
    IDH := pointer(h);
    if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
    begin
      INH := pointer(cardinal(h)+cardinal(IDH^._lfanew));
      if INH^.Signature = IMAGE_NT_SIGNATURE then
      begin
        size := INH^.OptionalHeader.SizeOfImage;
        mem := VirtualAllocExX(pid,size);
        if (mem <> nil) then
        begin
          mem2 := VirtualAlloc(nil,size,MEM_COMMIT or MEM_RESERVE,PAGE_EXECUTE_READWRITE);
          if (mem2 <> nil) then
          begin
            CopyMemory(mem2,pointer(h),size);
            ChangeReloc(pointer(h),
                        pointer(integer(mem2)),
                        pointer(integer(mem2)+
                          integer(INH^.OptionalHeader.DataDirectory[5].VirtualAddress)),
                        pointer(integer(mem)),
                        INH^.OptionalHeader.DataDirectory[5].Size);
            WriteProcessMemory(pid,mem,mem2,size,written);
            if integer(written) = size then
              result := CreateRemoteThreadX(pid,pointer(integer(dllmain)-h+integer(mem)));
            VirtualFree(mem2,size,MEM_DECOMMIT);
          end;
        end;
      end;
    end;
  end;
end;

function HookApiIAT(modulehandle: integer; oldfunction, yourfunction: pointer): boolean; stdcall; overload;
  procedure HookIAT(dlladdr, importaddr, faddr, newaddr: pointer);
    type TImportBlock = record
                          Characteristics: cardinal;
                          TimeDateStamp: cardinal;
                          ForwarderChain: cardinal;
                          Name: cardinal;
                          FirstThunk: pointer;
                        end;
         PImportBlock = ^TImportBlock;

         TImportfBlock = record
                           hint: word;
                           name: pchar;
                         end;
         PImportfBlock = ^TImportfBlock;
    var myimport: PImportblock;
        thunks: ^pointer;
        old: cardinal;
  begin
    myimport := pointer(integer(dlladdr)+integer(importaddr));
    while (myimport^.name <> 0) and (myimport^.FirstThunk <> nil) do
    begin
      thunks := pointer(integer(myimport^.FirstThunk)+integer(dlladdr));
      while thunks^ <> nil do
      begin
        if VirtualProtect(thunks,4,PAGE_EXECUTE_READWRITE, old) then
        begin
          if thunks^ = faddr then
          begin
            result := true;
            thunks^ := newaddr;
          end;
          VirtualProtect(thunks,4,old, old);
        end;
        thunks := pointer(integer(thunks)+4);
      end;
      myimport := pointer(integer(myimport)+sizeof(TImportBlock));
    end;
  end;
var IDH: PImageDosHeader;
    INH: PImageNtHeaders;
    old, old2: cardinal;
begin
  result := false;
  idh := pointer(modulehandle);
  if VirtualProtect(idh,sizeof(TImageDosHeader),PAGE_EXECUTE_READWRITE,old) then
  begin
    if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
    begin
      INH := pointer(cardinal(idh)+cardinal(IDH^._lfanew));
      if VirtualProtect(inh,sizeof(TImageNTHeaders),PAGE_EXECUTE_READWRITE,old2) then
      begin
        if INH^.Signature = IMAGE_NT_SIGNATURE then
          hookiat(pointer(idh),
                  pointer(INH^.OptionalHeader.DataDirectory[1].VirtualAddress),
                  oldfunction,
                  yourfunction);
        VirtualProtect(inh,sizeof(TImageNTHeaders),old,old2);
      end;
    end;
    VirtualProtect(idh,sizeof(TImageDosHeader),old,old);
  end;
end;

function HookApiIAT(oldfunction, yourfunction: pointer): boolean; stdcall; overload;
var s, t: string;
begin
  result := false;
  s := FindModulesInProcess(GetCurrentProcessId);
  while length(s) > 0 do
  begin
    delete(s,1,1);
    t := copy(s,1,pos(';',s)-1);
    if HookApiIAT(GetModuleHandleA(pchar(t)),oldfunction,yourfunction) then
      result := true;
    delete(s,1,length(t));
  end;
end;

function UnhookCode(var nextfunction: pointer): boolean; stdcall;
type Tjmpcode = packed record
                  pushb: byte;
                  addrdw: pointer;
                  retb: byte;
                end;
var fname: string;
    fsize: integer;
    sizeall: integer;
    p: pointer;
    error: boolean;
    jmp: tjmpcode;
    old: cardinal;
    jmpsize: integer;
begin
  sizeall := 0;
  jmpsize := sizeof(tjmpcode);
  p := nextfunction;
  jmp.pushb := $00;
  jmp.retb := $00;
  result := false;
  if (nextFunction <> nil) then
  begin
    repeat
      error := not InstructionInfo(p,fname,fsize);
      inc(sizeall,fsize);
      p := pointer(integer(p)+fsize);
    until (sizeall >= jmpsize) or error;
    if (not error) then
    begin
      CopyMemory(@jmp,pointer(integer(nextfunction)+sizeall),jmpsize);
      if (jmp.pushb = $68) and (jmp.retb = $C3) then
      begin
        if VirtualProtect(pointer(integer(jmp.addrdw)-sizeall),jmpsize,PAGE_EXECUTE_READWRITE,old) then
        begin
          CopyMemory(pointer(integer(jmp.addrdw)-sizeall),nextfunction,jmpsize);
          VirtualProtect(pointer(integer(jmp.addrdw)-sizeall),jmpsize,old,old);
          nextfunction := nil;
          result := true;
        end;
      end;
    end;
  end;
end;

function HookCode(oldfunction, yourfunction: pointer; var nextfunction: pointer): boolean; stdcall;
type Tjmpcode = packed record
                  pushb: byte;
                  addrdw: pointer;
                  retb: byte;
                end;
var fname: string;
    fsize: integer;
    sizeall: integer;
    p: pointer;
    error: boolean;
    jmp: tjmpcode;
    old: cardinal;
    jmpsize: integer;
begin
  sizeall := 0;
  jmpsize := sizeof(tjmpcode);
  p := oldfunction;
  jmp.pushb := $68;
  jmp.retb := $C3;
  result := false;
  repeat
    error := not InstructionInfo(p,fname,fsize);
    inc(sizeall,fsize);
    p := pointer(integer(p)+fsize);
  until (sizeall >= jmpsize) or error;
  if (not error) then
  begin
    nextfunction := VirtualAlloc(nil,jmpsize+sizeall,MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (nextfunction <> nil) then
    begin
      CopyMemory(nextfunction,oldfunction,sizeall);
      jmp.addrdw := pointer(integer(oldfunction)+sizeall);
      CopyMemory(pointer(integer(nextfunction)+sizeall),@jmp,jmpsize);
      jmp.addrdw := yourfunction;
      if VirtualProtect(oldfunction,jmpsize,PAGE_EXECUTE_READWRITE,old) then
      begin
        CopyMemory(oldfunction,@jmp,jmpsize);
        result := true;
        VirtualProtect(oldfunction,jmpsize,old,old);
      end else
        VirtualFree(nextfunction,jmpsize+sizeall,MEM_DECOMMIT);
    end;
  end;
end;

end.
