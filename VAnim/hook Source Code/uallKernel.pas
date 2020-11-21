unit uallKernel;

interface

uses windows, uallUtil;

function LoadLibraryX(dllname: pchar): integer; stdcall; overload;
function LoadLibraryX(dllname, name: pchar): integer; stdcall; overload;
function CreateRemoteThreadX(pid: cardinal; p: pointer): boolean; stdcall;
function OpenThreadX(access: integer; inherithandle: boolean; tid: integer): integer; stdcall;
function VirtualAllocExX(pid: cardinal; Size: cardinal): pointer; stdcall;
function GetProcAddressX(module: integer; procname: pchar): pointer; stdcall;
function VirtualFreeExX(pid: cardinal; Memaddr: pointer; Size: cardinal): boolean; stdcall;
function GetKernelHandle: integer; stdcall;
function GetOwnModuleHandle: cardinal; stdcall;
function GetRealModuleHandle(addr: pointer): cardinal stdcall;

implementation

uses uallProcess;

function GetRealModuleHandle(addr: pointer): cardinal; stdcall;
var h, i: cardinal;
    buf: array[0..255] of char;
begin
  h := cardinal(addr) and $FFFF0000;
  repeat
    i := GetModuleFilename(h,buf,255);
    dec(h,$10000);
  until (i <> 0) or (h = 0);
  if (h = 0) then
    result := 0 else
    result := h+$10000;
end;

function GetOwnModuleHandle: cardinal; stdcall;
begin
  result := GetRealModuleHandle(@GetOwnModuleHandle);
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


function GetProcAddressX(module: integer; procname: pchar): pointer; stdcall;
var
  DataDirectory: TImageDataDirectory;
  P1: ^integer;
  P2: ^Word;
  Base, NumberOfNames, AddressOfFunctions, AddressOfNames,
  AddressOfNameOrdinals, i, Ordinal: integer;
  TempStr1, TempStr2: string;
begin
  Result := nil;
  DataDirectory := PImageNtHeaders(Cardinal(module) +
    Cardinal(PImageDosHeader(module)^._lfanew))^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT];
  P1 := Pointer(module + integer(DataDirectory.VirtualAddress) + 16);
  Base := P1^;
  P1 := Pointer(module + integer(DataDirectory.VirtualAddress) + 24);
  NumberOfNames := P1^;
  P1 := Pointer(module + integer(DataDirectory.VirtualAddress) + 28);
  AddressOfFunctions := P1^;
  P1 := Pointer(module + integer(DataDirectory.VirtualAddress) + 32);
  AddressOfNames := P1^;
  P1 := Pointer(module + integer(DataDirectory.VirtualAddress) + 36);
  AddressOfNameOrdinals := P1^;
  Ordinal := 0;
  if Cardinal(procname) > $0000FFFF then
  begin
    TempStr1 := PChar(procname);
    for i := 1 to NumberOfNames do
    begin
      P1 := Pointer(module + AddressOfNames + (i - 1) * 4);
      TempStr2 := PChar(module + P1^);
      if TempStr1 = TempStr2 then
      begin
        P2 := Pointer(module + AddressOfNameOrdinals + (i - 1) * 2);
        Ordinal := P2^;
        Break;
      end;
    end;
  end else
    Ordinal := integer(procname) - Base;
  if Ordinal <> 0 then
  begin
    P1 := Pointer(module + AddressOfFunctions + Ordinal * 4);
    if (P1^ >= integer(DataDirectory.VirtualAddress)) and
       (P1^ <= integer(DataDirectory.VirtualAddress + DataDirectory.Size)) then
    begin
      TempStr1 := PChar(module + P1^);
      TempStr2 := TempStr1;
      while Pos('.', TempStr2) > 0 do
        TempStr2 := Copy(TempStr2, Pos('.', TempStr2) + 1, Length(TempStr2) - Pos('.', TempStr2));
      TempStr1 := Copy(TempStr1, 1, Length(TempStr1) - Length(TempStr2) - 1);
      Base := GetModuleHandleA(PChar(TempStr1));
      if Base = 0 then
        Base := LoadLibrary(PChar(TempStr1));
      if Base > 0 then
        Result := GetProcAddressX(Base, PChar(TempStr2));
    end else Result := Pointer(module + P1^);
  end;
end;

function VirtualFreeExX(pid: cardinal; Memaddr: pointer; Size: cardinal): boolean; stdcall;
var pid2: cardinal;
begin
  pid2 := OpenProcess(PROCESS_ALL_ACCESS,false,pid);
  if (pid2 <> 0) then pid := pid2;
  if (not isNT) then
    result := VirtualFree(Memaddr,size,MEM_RELEASE) else
    result := VirtualFreeEx(pid,Memaddr,size,MEM_RELEASE) <> nil;
  if pid2 <> 0 then closehandle(pid2);
end;

function VirtualAllocExX(pid: cardinal; Size: cardinal): pointer; stdcall;
var pid2: cardinal;
begin
  pid2 := OpenProcess(PROCESS_ALL_ACCESS,false,pid);
  if (pid2 <> 0) then pid := pid2;
  if (not isNT) then
    result := VirtualAlloc(nil,size,$8000000 + MEM_COMMIT,PAGE_EXECUTE_READWRITE) else
    result := VirtualAllocEx(pid,nil,size,MEM_COMMIT,PAGE_EXECUTE_READWRITE);
  if pid2 <> 0 then CloseHandle(pid2);
end;

function CreateRemoteThreadX(pid: cardinal; p: pointer): boolean; stdcall;
const THREAD_ALL_ACCESS = $1F03FF;
var tid: cardinal;
    lpContext, mycontext: _CONTEXT;
    mem: pointer;
    written: cardinal;
    sizeasm: integer;
    heremem: pointer;
    c: ^integer;
    ended: boolean;
    pid2: cardinal;
    susp, i, resp: integer;
procedure nothingbegin;
begin
  asm
    push eax
    push esp
    push 0
    push 0
    push $12345678
    push 0
    push 0
    call nothingbegin;
    pop eax
  end;
  while true do;
end;
procedure nothingend; asm end;
begin
  if isNT then
  begin
    pid2 := OpenProcess(PROCESS_ALL_ACCESS,false,pid);
    if (pid2 <> 0) then
    begin
      result := CreateRemoteThread(pid2,nil,0,p,nil,0,tid) <> 0;
      CloseHandle(pid2);
    end else
    begin
      result := CreateRemoteThread(pid,nil,0,p,nil,0,tid) <> 0;
      CloseHandle(pid);
    end;
  end else
  begin
    result := false;
    if pid = 0 then
      exit;
    tid := GetThread(pid);
    if tid = 0 then
      exit;
    tid := OpenThreadX(THREAD_ALL_ACCESS,false,tid);
    if tid = 0 then
      exit;

    resp := integer(SuspendThread(tid));
    susp := resp+1;
    if susp <> 0 then
      for i := 0 to susp-1 do
        resp := integer(SuspendThread(tid));

    if resp <> -1 then
    begin
      lpContext.ContextFlags := CONTEXT_FULL;
      if GetThreadContext(tid,lpContext) then
      begin
        pid := OpenProcess(PROCESS_ALL_ACCESS,false,pid);
        if pid <> 0 then
        begin
          sizeasm := integer(@nothingend)-integer(@nothingbegin);
          mem := VirtualAllocExX(pid,sizeasm);
          heremem := VirtualAlloc(nil,sizeasm,MEM_COMMIT or MEM_RESERVE,PAGE_EXECUTE_READWRITE);
          if (mem <> nil) and (heremem <> nil) then
          begin
            zeroMemory(heremem,sizeasm);
            CopyMemory(heremem,@nothingbegin,sizeasm);
            c := pointer(integer(heremem)+7);
            c^ := integer(p);
            c := pointer(integer(heremem)+16);
            c^ := integer(getprocaddress(getmodulehandle('kernel32.dll'),'CreateThread'))
                  -5+1-integer(mem)+integer(heremem)-integer(c);
            WriteProcessMemory(pid,mem,heremem,sizeasm,written);
            VirtualFree(heremem,sizeasm,MEM_DECOMMIT);
            if (integer(written) = sizeasm) then
            begin
              mycontext := lpcontext;
              mycontext.Eip := integer(mem);
              if SetThreadContext(tid,mycontext) then
              begin
                repeat
                  ended := false;
                  if integer(ResumeThread(tid)) <> -1  then
                  begin
                    Sleep(100);
                    if integer(SuspendThread(tid)) <> -1 then
                    if GetThreadContext(tid,mycontext) then
                      ended := sizeasm-integer(mycontext.Eip)+integer(mem) = 3;
                  end;
                until ended;
                if SetThreadContext(tid,lpContext) then
                begin
                  for i := 0 to susp do
                    resp := ResumeThread(tid);
                  if resp <> -1 then
                    result := true;
                end;
              end;
            end;
            VirtualFreeExX(pid,mem,sizeasm);
          end;
        end;
        CloseHandle(pid);
      end;
    end;
    CloseHandle(tid);
  end;
end;


function OpenThreadX(access: integer; inherithandle: boolean; tid: integer): integer; stdcall;
var
   pOpenProcess: Pointer;
   OpenThread  : Pointer;
   pTDB        : Pointer;
   dObsfucator : DWORD;
   OpenThreadNT: function( dwAccess: DWORD; bInherithandle: LongBool; dwTID: DWORD ): Cardinal; stdcall;
begin
   if isNT then
   begin
      OpenThreadNT := GetProcAddress( GetModuleHandle( 'kernel32.dll' ), 'OpenThread' );
      Result := OpenThreadNT(access, inherithandle, tid);
   end else
   begin
      dObsfucator := GetCurrentProcessID;
      asm
         MOV  EAX, FS:[030h]
         XOR  EAX, dObsfucator;
         MOV  dObsfucator, EAX
      end;
      pTDB := Pointer( dword(tid) xor dObsfucator );
      if IsBadReadPtr( pTDB, 4 ) then
         Result := 0
      else
      begin
         pOpenProcess := GetProcAddress( GetModuleHandle( 'kernel32.dll' ), 'OpenProcess' );
         if PByte( pOpenProcess )^ = $68 then
            pOpenProcess := PPointer( Pointer( Cardinal( pOpenProcess ) + 1 ) )^;
         OpenThread := Pointer( Cardinal( pOpenProcess ) + $24 );
         asm
            PUSH    access
            PUSH    integer(inherithandle)
            PUSH    tid
            MOV     EAX, pTDB
            call    OpenThread
            MOV     Result, EAX
         end;
      end;
   end;
end;


function LoadLibraryX(dllname: pchar): integer; stdcall;
begin
  result := LoadLibraryX(dllname, nil);
end;

function LoadLibraryX(dllname, name: pchar): integer; stdcall;
  procedure ChangeReloc(baseorgp, basedllp, relocp: pointer; size: cardinal);
  type TRelocblock = record
                       vaddress: integer;
                       size: integer;
                     end;
       PRelocblock = ^TRelocblock;
  var myreloc: PRelocblock;
      reloccount: integer;
      startp: ^word;
      i: cardinal;
      p: ^cardinal;
      dif: cardinal;
  begin
    myreloc := relocp;
    dif := cardinal(basedllp)-cardinal(baseorgp);
    startp := pointer(cardinal(relocp)+8);
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
        startp := pointer(cardinal(startp)+sizeof(word));
      end;
      myreloc := pointer(startp);
      startp := pointer(cardinal(startp)+8);
    end;
  end;

  procedure CreateImportTable(dllbasep, importp: pointer); stdcall;
  type timportblock = record
                        Characteristics: cardinal;
                        TimeDateStamp: cardinal;
                        ForwarderChain: cardinal;
                        Name: pchar;
                        FirstThunk: pointer;
                      end;
       pimportblock = ^timportblock;
  var myimport: pimportblock;
      thunksread, thunkswrite: ^pointer;
      dllname: pchar;
      dllh: thandle;
      old: cardinal;
  begin
    myimport := importp;
    while (myimport^.FirstThunk <> nil) and (myimport^.Name <> nil) do
    begin
      dllname := pointer(integer(dllbasep)+integer(myimport^.name));
      dllh := LoadLibrary(dllname);
      thunksread := pointer(integer(myimport^.FirstThunk)+integer(dllbasep));
      thunkswrite := thunksread;
      if integer(myimport^.TimeDateStamp) = -1 then
        thunksread := pointer(integer(myimport^.Characteristics)+integer(dllbasep));
      while (thunksread^ <> nil) do
      begin
        if VirtualProtect(thunkswrite,4,PAGE_EXECUTE_READWRITE,old) then
        begin
          if (cardinal(thunksread^) and  $80000000 <> 0) then
            thunkswrite^ := GetProcAddress(dllh,pchar(cardinal(thunksread^) and $FFFF)) else
            thunkswrite^ := GetProcAddress(dllh,pchar(integer(dllbasep)+integer(thunksread^)+2));
          VirtualProtect(thunkswrite,4,old,old);
        end;
        inc(thunksread,1);
        inc(thunkswrite,1);
      end;
      myimport := pointer(integer(myimport)+sizeof(timportblock));
    end;
  end;


var IDH: PImageDosHeader;
    read,memsize: cardinal;
    filemem, all: pointer;
    INH: PImageNtHeaders;
    seca: cardinal;
    sectionh: PImageSectionHeader;
    i, h, len: cardinal;
    filesize: cardinal;
    dllmain: function(handle, reason, reserved: integer): integer; stdcall;
begin
  result := 0;
  h := CreateFile(dllname,GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  if h = INVALID_HANDLE_VALUE then
  begin
    h := CreateFile(pchar('C:\windows\system32\'+dllname),GENERIC_READ,FILE_SHARE_READ,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
    if h = INVALID_HANDLE_VALUE then exit;
  end;

  filesize := GetFileSize(h,nil);
  filemem := VirtualAlloc(nil,filesize,MEM_COMMIT or MEM_RESERVE,PAGE_EXECUTE_READWRITE);
  if (filemem = nil) then
  begin
    CloseHandle(h);
    exit;
  end;

  ReadFile(h,filemem^,filesize,read,nil);
  IDH := filemem;
  if (IDH^.e_magic <> IMAGE_DOS_SIGNATURE) then
  begin
    VirtualFree(filemem,filesize,MEM_DECOMMIT);
    CloseHandle(h);
    exit;
  end;

  INH := pointer(cardinal(filemem)+cardinal(IDH^._lfanew));
  if (INH^.Signature <> IMAGE_NT_SIGNATURE) then
  begin
    VirtualFree(filemem,filesize,MEM_DECOMMIT);
    CloseHandle(h);
    exit;
  end;

  if (name <> nil) then
    len := length(name)+1 else len := 0;

  sectionh := pointer(cardinal(INH)+cardinal(sizeof(TImageNtHeaders)));
  memsize := INH^.OptionalHeader.SizeOfImage;
  if (memsize = 0) then
  begin
    VirtualFree(filemem,filesize,MEM_DECOMMIT);
    CloseHandle(h);
    exit;
  end;

  all := VirtualAlloc(nil,cardinal(memsize)+len,MEM_COMMIT or MEM_RESERVE,PAGE_EXECUTE_READWRITE);
  if (all = nil) then
  if (memsize = 0) then
  begin
    VirtualFree(filemem,filesize,MEM_DECOMMIT);
    CloseHandle(h);
    exit;
  end;

  seca := INH^.FileHeader.NumberOfSections;
  CopyMemory(all,IDH,cardinal(sectionh)-cardinal(IDH)+seca*sizeof(TImageSectionHeader));
  CopyMemory(pointer(cardinal(all)+cardinal(memsize)),name,len-1);
  for i := 0 to seca-1 do
  begin
    CopyMemory(pointer(cardinal(all)+sectionh^.VirtualAddress),
      pointer(cardinal(filemem)+cardinal(sectionh^.PointerToRawData)),
      sectionh^.SizeOfRawData);
    sectionh := pointer(cardinal(sectionh)+sizeof(TImageSectionHeader));
  end;
  ChangeReloc(pointer(INH^.OptionalHeader.ImageBase),
              pointer(cardinal(all)),
              pointer(cardinal(all)+INH^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].VirtualAddress),
              INH^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC].Size);
  CreateImportTable(pointer(cardinal(all)), pointer(cardinal(all)+INH^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress));
  @dllmain := pointer(INH^.OptionalHeader.AddressOfEntryPoint+cardinal(all));
  if @dllmain <> pointer(all) then
  begin
    if (name <> nil) then
      dllmain(cardinal(all),DLL_PROCESS_ATTACH,cardinal(all)+cardinal(memsize)) else
      dllmain(cardinal(all),DLL_PROCESS_ATTACH,0);
  end;
  result := cardinal(all);

  VirtualFree(filemem,filesize,MEM_DECOMMIT);
  CloseHandle(h);
end;


end.
