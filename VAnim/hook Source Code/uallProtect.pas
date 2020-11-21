unit uallProtect;

interface

uses windows, uallUtil, tlhelp32;

function HideLibraryNT(lib: integer): boolean; stdcall;
function ShowLibraryNT(lib: integer): boolean; stdcall;
function IsDebuggerPresent: boolean; stdcall;
function GetDebugPrivilege: boolean; stdcall;
function ForceLoadLibrary(libname: pchar): integer; stdcall;
function ForceLoadLibraryNt(dllname: pchar): cardinal; stdcall;
procedure ProtectCall(proc: pointer); stdcall;
procedure AntiDebugActiveProcess; stdcall;
function IsHooked(dllname, procname: pchar): boolean; stdcall;
function GetKernelHandle: integer; stdcall;

implementation

uses uallKernel, uallHook;

var oldRtlEqualUnicodeString: function(a,b: pointer; c: boolean): boolean; stdcall;
    nextRtlEqualUnicodeString: function(a,b: pointer; c: boolean): boolean; stdcall;
    forcename: string;

function myRtlEqualUnicodeString(a,b: pointer; c: boolean): boolean; stdcall;
begin
  if pos(forcename,uppercase(pwidechar(pointer(cardinal(b)+4)^))) > 0 then
    result := false else
    result := nextRtlEqualUnicodeString(a,b,c);
end;

function ForceLoadLibraryNt(dllname: pchar): cardinal; stdcall;
begin
  @oldRtlEqualUnicodeString := GetProcAddress(GetModuleHandle('ntdll.dll'),'RtlEqualUnicodeString');
  if (@oldRtlEqualUnicodeString <> nil) then
  begin
    uallHook.HookCode(@oldRtlEqualUnicodeString,@myRtlEqualUnicodeString,@nextRtlEqualUnicodeString);
    forcename := uppercase(dllname);
    result := LoadLibraryA(dllname);
    uallHook.UnhookCode(@nextRtlEqualUnicodeString);
  end else
    Result := LoadLibraryA(dllname);
end;

function GetKernelHandle: integer; stdcall;
asm
        MOV     EAX, FS:[030H]
        TEST    EAX, EAX
        JS      @@W9X

@@WNT:  MOV     EAX, [EAX+00CH]
        MOV     ESI, [EAX+01CH]
        LODSD
        MOV     EAX, [EAX+008H]
        JMP     @@K32

@@W9X:  MOV     EAX, [EAX+034H]
        LEA     EAX, [EAX+07CH]
        MOV     EAX, [EAX+03CH]
@@K32:
end;

function IsHooked(dllname, procname: pchar): boolean; stdcall;

  function CheckSame(p1,p2: pointer): boolean; stdcall;
  var i: integer;
  begin
    result := false;
    if (not isBadReadPtr(p1,8)) and (not isBadReadPtr(p2,8)) then
    begin
      for i := 0 to 7 do
        if pbyte(p1)^ <> pbyte(p2)^ then result := true;
      end;
  end;

  function IsAddrInModule(addr: pointer; dllname: pchar): boolean; stdcall;
  var
    INH: PImageNtHeaders;
    IDH: PImageDosHeader;
    moduleh: integer;
  begin
    moduleh := GetModuleHandle(dllname);
    result := true;
    IDH := pointer(moduleh);
    if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
    begin
      INH := pointer(cardinal(moduleh)+cardinal(IDH^._lfanew));
      if INH^.Signature = IMAGE_NT_SIGNATURE then
      begin
        if (integer(addr) < moduleh) or (integer(addr) > moduleh+integer(INH^.OptionalHeader.SizeOfImage)) then
           if GetRealModuleHandle(addr) <> GetModuleHandle('ntdll.dll') then
              result := false;
      end;
    end;
  end;

  function CheckImportTableModule(moduleh: integer; memp: pointer; modulename: pchar): boolean; stdcall;
  type timportblock = record
                        Characteristics: cardinal;
                        TimeDateStamp: cardinal;
                        ForwarderChain: cardinal;
                        Name: pchar;
                        FirstThunk: pointer;
                      end;
       pimportblock = ^timportblock;
  var myimport: pimportblock;
      thunks: ^pointer;
      dllname: pchar;
    INH: PImageNtHeaders;
    IDH: PImageDosHeader;
  begin
    result := false;
    IDH := pointer(moduleh);
    if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
    begin
      INH := pointer(cardinal(moduleh)+cardinal(IDH^._lfanew));
      if INH^.Signature = IMAGE_NT_SIGNATURE then
      begin
        myimport := pointer(moduleh+integer(INH^.OptionalHeader.DataDirectory[1].VirtualAddress));
        dllname := pointer(integer(moduleh)+integer(myimport^.name));
        while (myimport^.FirstThunk <> nil) do
        begin
          thunks := pointer(integer(myimport^.FirstThunk)+integer(moduleh));
          while thunks^ <> nil do
          begin
            if (uppercase(dllname) = uppercase(modulename)) then
            begin
              if not IsAddrInModule(thunks^,dllname) then
                result := true;
            end;
            inc(thunks,1);
          end;
          myimport := pointer(integer(myimport)+sizeof(timportblock));
          dllname := pointer(integer(moduleh)+integer(myimport^.name));
        end;
      end;
    end;
  end;

  function CheckImportTable(memp: pointer; modulename: pointer): boolean;
  var hsnap: integer;
    lpme: tagMODULEENTRY32;
  begin
    result := false;
    hsnap := CreateToolHelp32Snapshot(TH32CS_SNAPMODULE,GetCurrentProcessID);
    if (hsnap > 0) then
    begin
      lpme.dwSize := sizeOf(lpme);
      if Module32First(hsnap,lpme) then
      begin
        repeat
          if result <> true then
            result := CheckImportTableModule(lpme.hModule,memp,modulename);
        until (not Module32Next(hsnap,lpme));
      end;
      CloseHandle(hsnap);
    end;
  end;

  function CheckExportTable(fp: pointer; memp, basev: integer): boolean; stdcall;
  var
    INH: PImageNtHeaders;
    IDH: PImageDosHeader;
    exp: pointer;
    i, count: integer;
    addr: pointer;
  begin
    result := false;
    IDH := fp;
    if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
    begin
      INH := pointer(cardinal(fp)+cardinal(IDH^._lfanew));
      if INH^.Signature = IMAGE_NT_SIGNATURE then
      begin
        result := true;
        exp := pointer(INH^.OptionalHeader.DataDirectory[0].VirtualAddress);
        count := pinteger(integer(basev)+integer(exp)+24)^;
        addr := ppointer(integer(basev)+integer(exp)+28)^;
        for i := 0 to count-1 do
        begin
          if pinteger(basev+integer(addr)+i*4)^ = integer(memp) then
            result := false;
        end;
      end;
    end;
  end;

  function CheckAddr(fp: pointer; memp, basev: integer): boolean; stdcall;
  var
    INH: PImageNtHeaders;
    IDH: PImageDosHeader;
    i: integer;
    seca: cardinal;
    sectionh: PImageSectionHeader;
  begin
    result := false;
    IDH := fp;
    if IDH^.e_magic = IMAGE_DOS_SIGNATURE then
    begin
      INH := pointer(cardinal(fp)+cardinal(IDH^._lfanew));
      if INH^.Signature = IMAGE_NT_SIGNATURE then
      begin
        seca := INH^.FileHeader.NumberOfSections;
        for i := 0 to seca-1 do
        begin
          sectionh := pointer(integer(INH)+sizeof(TImageNtHeaders)+i*sizeof(TImageSectionHeader));
          if (sectionh^.VirtualAddress <= cardinal(memp)) and
             ((sectionh^.VirtualAddress+sectionh^.Misc.PhysicalAddress) >= cardinal(memp)) then
            result := CheckSame(pointer(integer(fp)+integer(sectionh^.PointerToRawData)
                      +(memp-integer(sectionh^.VirtualAddress))), pointer(memp+basev));
        end;
      end;
    end;
  end;

var s: string;
    hf: integer;
    fs,len: integer;
    mem: pointer;
    read: cardinal;
    realmod: integer;
    addr: pointer;
begin
  result := false;
  addr := GetProcAddress(GetModuleHandle(dllname),procname);
  if not IsAddrInModule(addr,dllname) then
    result := true else
  if (not IsBadReadPtr(addr,8)) then
  begin
    realmod := GetRealModuleHandle(addr);
    SetLength(s,256);
    len := GetModuleFileName(realmod,@s[1],256);
    if len > 0 then
    begin
      s := copy(s,1,len);
      hf := CreateFileA(pchar(s),GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,0,0);
      if hf > 0 then
      begin
        fs := GetFileSize(hf,nil);
        mem := VirtualAlloc(nil,fs,MEM_COMMIT or MEM_RESERVE,PAGE_EXECUTE_READWRITE);
        if mem <> nil then
        begin
          ReadFile(hf,mem^,fs,read,nil);
          result := CheckAddr(mem,integer(addr)-realmod, realmod);
          if (not result) then
            result := CheckExportTable(mem,integer(addr)-realmod, realmod);
          if (not result) then
            result := CheckImportTable(addr, dllname);
          VirtualFree(mem,fs,MEM_DECOMMIT);
          CloseHandle(hf);
        end;
      end;
    end;
  end;
end;


procedure AntiDebugActiveProcess; stdcall;
begin
  CreateFileA(pchar(paramstr(0)),GENERIC_READ,0,nil,OPEN_EXISTING,0,0)
end;

procedure ProtectCall(proc: pointer); stdcall;
asm
  MOV EBX, [EBP+4]
  PUSH EBX
  MOV EAX, proc
  XOR EAX, EBP
  PUSH EAX
  XOR EAX, EAX
  TEST EAX, EAX
  JNZ @muell
  JNZ @muell2
  JMP @weiter
@muell:
  DB $0F DB $80
@weiter:
  //RDTSC
  DB $0F DB $31
  MOV ECX, EAX
  MOV EBX, EDX
  JMP @weiter2
@muell2:
  DB $0F DB $80
@weiter2:
  //RDTSC
  DB $0F DB $31
  SUB EAX, ECX
  SUB EDX, EBX
  NEG EDX
  XOR EAX, EDX
  SHR EAX, 8
  XOR EBP, EAX
  @ende:
  POP EAX
  XOR EAX, EBP
  POP EBX
  POP EBP    
  POP ECX
  MOV [ESP], EBX
  JMP EAX
end;

function ForceLoadLibrary(libname: pchar): integer; stdcall;
var hide: array of integer;
    count, i: integer;
begin
  result := 0;
  if (pos('KERNEL32',UpperCase(libname)) > 0) or (pos('NTDLL',UpperCase(libname)) > 0) then exit;
  count := 0;
  while GetModuleHandle(libname) > 0 do
  begin
    inc(count);
    SetLength(hide,count);
    hide[count-1] := GetModuleHandle(libname);
    HideLibraryNT(GetModuleHandle(libname));
  end;
  result := LoadLibraryA(libname);
  for i := 0 to count-1 do
    ShowLibraryNT(hide[i]);
end;

function GetDebugPrivilege: boolean; stdcall;
var hToken,rel: cardinal;
    tkp: TOKEN_PRIVILEGES;
    luid: int64;
begin
  result := false;
  if OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then
  begin
    if LookupPrivilegeValue(nil, 'SeDebugPrivilege', luid) then
    begin
      tkp.PrivilegeCount            := 1;
      tkp.Privileges[0].Attributes  := SE_PRIVILEGE_ENABLED;
      tkp.Privileges[0].Luid        := luid;
      result := AdjustTokenPrivileges(hToken, FALSE, tkp, sizeof(tkp), nil, rel);
    end;
    CloseHandle(hToken);
  end;
end;

function HideLibraryNT(lib: integer): boolean; stdcall;
asm
  PUSH EDX                        // save all registers we use
  PUSH ECX
  PUSH EBX
  MOV EBX, lib                    // EBX = handle of dll to hide
  MOV EAX,DWORD PTR FS:[$18]      // get dll table
  MOV EAX,DWORD PTR [EAX+$30]
  MOV EAX,DWORD PTR [EAX+$C]
  ADD EAX,$0C
  MOV ECX,DWORD PTR [EAX]

@weiter:
  CMP ECX,EAX                     // successful got table?
  JE @ende                        // if not go to end
  MOV EDX,ECX
  CMP DWORD PTR DS:[EDX+$8],0     // check for valid module
  MOV ECX,DWORD PTR DS:[ECX]
  JE @weiter                      // if not valid (end of table) go to end
  CMP EBX,DWORD PTR DS:[EDX+$18]  // is it the module we search?
  JNE @weiter                     // if not get next module in table
  LEA EBX, [EDX+$28]              // if so get the library name
  MOV EBX, [EBX]

  CMP BYTE PTR [EBX],$0           // library name is empty? (already hidden dll?)
  JE @ende                        // if so go to end

  MOV EDX, EBX
  MOV EAX, EDX
  ADD EAX, 3
  MOV CL, BYTE PTR [EDX]          // get the first char
  MOV BYTE PTR [EAX], CL          // save it in the second char #0 (unicode!)
  MOV BYTE PTR [EDX], $0          // delete first char (hide dll path)

  XOR EDX, EDX                    // search for last backslash
  MOV EBX, EAX
  ADD EBX, 1
@weiter2:
  MOV EAX, EBX
  ADD EBX, 2
  CMP BYTE PTR [EAX], $5C         // check for backslash
  JNE @weiter3                    // jmp to next char if no backslash
  MOV EDX, EAX                    // save last backslash address to edx
@weiter3:
  CMP BYTE PTR [EAX], $0          // check for last char
  JNE @weiter2                    // if not go on

  TEST EDX, EDX                   // check if we found a backslash
  JZ @ende                        // no backslash found, goto end

  ADD EDX, 2
  MOV EAX, EDX
  ADD EAX, 3

  MOV CL, BYTE PTR [EDX]          // get first char of the library name
  MOV BYTE PTR [EAX], CL          // save it in second char of libary name
  MOV BYTE PTR [EDX], $0          // destroy the first char (hide library name)

  XOR EAX, EAX
  ADD EAX, 1                      // set return param to true
  JMP @ende2

@ende:
  XOR EAX, EAX
@ende2:
  POP EBX
  POP ECX
  POP EDX
end;

function ShowLibraryNT(lib: integer): boolean; stdcall;
asm
  PUSH EDX                        // save all registers we use
  PUSH ECX
  PUSH EBX
  MOV EBX, lib                    // EBX = handle of dll to hide
  MOV EAX,DWORD PTR FS:[$18]      // get dll table
  MOV EAX,DWORD PTR [EAX+$30]
  MOV EAX,DWORD PTR [EAX+$C]
  ADD EAX,$0C
  MOV ECX,DWORD PTR [EAX]

@weiter:
  CMP ECX,EAX                     // successful got table?
  JE @ende                        // if not go to end
  MOV EDX,ECX
  CMP DWORD PTR DS:[EDX+$8],0     // check for valid module
  MOV ECX,DWORD PTR DS:[ECX]
  JE @weiter                      // if not valid (end of table) go to end
  CMP EBX,DWORD PTR DS:[EDX+$18]  // is it the module we search?
  JNE @weiter                     // if not get next module in table
  LEA EBX, [EDX+$28]              // if so get the library name
  MOV EBX, [EBX]

  CMP BYTE PTR [EBX],$0           // library name is not empty? (no hidden dll?)
  JNE @ende                       // if so go to end

  MOV EDX, EBX
  MOV EAX, EDX
  ADD EAX, 3
  MOV CL, BYTE PTR [EAX]          // get the saved char
  MOV BYTE PTR [EDX], CL          // set it (revalid dll path)
  MOV BYTE PTR [EAX], $0          // delete saved char

  XOR EDX, EDX                    // search for last backslash
  MOV EBX, EAX
  ADD EBX, 1
@weiter2:
  MOV EAX, EBX
  ADD EBX, 2
  CMP BYTE PTR [EAX], $5C         // check for backslash
  JNE @weiter3                    // jmp to next char if no backslash
  MOV EDX, EAX                    // save last backslash address to edx
@weiter3:
  CMP BYTE PTR [EAX], $0          // check for last char
  JNE @weiter2                    // if not go on

  TEST EDX, EDX                   // check if we found a backslash
  JZ @ende                        // no backslash found, goto end

  ADD EDX, 2
  MOV EAX, EDX
  ADD EAX, 3

  MOV CL, BYTE PTR [EAX]          // get saved char of the library name
  MOV BYTE PTR [EDX], CL          // revalid library name
  MOV BYTE PTR [EAX], $0          // delete saved char

  XOR EAX, EAX
  ADD EAX, 1                      // set return param to true
  JMP @ende2

@ende:
  XOR EAX, EAX
@ende2:
  POP EBX
  POP ECX
  POP EDX
end;

function IsDebuggerPresent: boolean; stdcall;
asm
  MOV     EAX, FS:[030H]
  TEST    EAX, EAX
  JS      @@W9X
@@WNT:
  MOV EAX, FS:[$18]
  MOV EAX, [EAX+$30]
  MOVZX EAX, [EAX+2]
  RET
@@W9X:
  MOV EAX, [$BFFC9CE4]
  MOV ECX, [EAX]
  CMP [ECX+$54], 00000001
  SBB EAX, EAX
  INC EAX
  RET
end;

end.
