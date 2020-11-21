unit MainFunc;

interface

uses Windows, Classes, Messages, SysUtils, Graphics, StrUtils;

function forceForegroundWindow(hwnd: THandle): boolean;
procedure fadeBitmap( const BitmapFrom, BitmapTo, BitmapAusgabe: TBitmap; const fade: Byte);
function RunProcess(commandLine:String; MustWait: Boolean; Visibility: Word):DWORD; overload;
function RunProcess(commandLine, desktop:String; MustWait: Boolean; Visibility: Word):DWORD; overload;
function vIsStringInSeps( const input, suchenach: string): Boolean;
function trySendMessage( const handle, uMsg: dword; const wParam: dword; const lParam: dword): dword;
function vGetwindowtext(const h:integer):string;
function getClientWindowList(const h: integer): TList;
function FilterDateiName( const DateiName: string): string;


implementation

var
   EBX, ESI, EDI, ESP, EBP, FinA, Dens1, Dens2: Longint; // für Fadeeffekte benutzt

function FilterDateiName( const DateiName: string): string;
var
 wdh, i1: integer;
 liste, s1: string;
begin
 liste:= '%\/*?"<>|:;'#13#10;
 result:= DateiName;

 for wdh:= length( result) downto 1 do
 begin
  i1:= pos( result[wdh], liste);
  if i1 > 0 then
  begin
   delete(result, wdh, 1);
   s1:= intToStr(byte(liste[i1]));
   while length(s1) < 3 do s1:= '0' + s1;
   insert('%'+s1, result, wdh);
  end;
 end;
end;

{----------------------------------getClientWindowList-------------------------}
{** EnumChildWindows, aber als Rückgabewert eine Handle-Liste}
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

{** Gibt die Caption eines Fensters zurück.}
function vGetwindowtext(const h:integer):string;
var
 i1: integer;
begin
 i1:= sendMessage(h, WM_GETTEXTLENGTH, 0, 0) + 1;
 setLength(result, i1);
 sendMessage(h, WM_GETTEXT, i1, integer(pchar(result)));
 setLength(result, strlen( pchar(result)));
end;

function trySendMessage( const handle, uMsg: dword; const wParam: dword; const lParam: dword): dword;
begin
 if sendMessageTimeOut( Handle, uMsg, wParam, lParam, SMTO_ABORTIFHUNG, 50, result) = 0 then
  postMessage( Handle, uMsg, wParam, lParam);
end;

function vIsStringInSeps( const input, suchenach: string): Boolean;
var
  startPos, endPos: integer;
begin
 result:= false;
 endPos:= 0;
 repeat
  startPos:= endPos+1;
  endPos:= posEx('÷', input, startPos);
  if endPos > startPos then
   if copy(  input, startPos, endPos-startPos) = sucheNach then
   begin
    result:= true;
    break;
   end;
 until startPos > endPos;
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

{----------------------------------fadeBitmap----------------------------------}
procedure fadeNow(const bFr, bTo, bLn: Pointer; const Width, Height: Integer; const Dens: LongInt); assembler;
const
   Mask0101 = $00FF00FF;
   Mask1010 = $FF00FF00;

   ASM

      MOV &EBX, EBX
      MOV &EDI, EDI
      MOV &ESI, ESI
      MOV &ESP, ESP
      MOV &EBP, EBP

      MOV EBX, Dens
      MOV Dens1, EBX

      NEG BL
      ADD BL, $20
      MOV Dens2, EBX
      CMP Dens1, 0
      JZ  @Final
      MOV EDI, bFr
      MOV ESI, bTo
      MOV ECX, bLn

      MOV EAX, Width
      lea EAX, [EAX + EAX * 2 + 3]
      AND EAX, $FFFFFFFC
      IMUL Height
      ADD EAX, EDI
      MOV FinA, EAX

      MOV EBP, EDI
      MOV ESP, ESI
      MOV ECX, ECX

      @LOOPA:
      MOV  EAX, [EBP]
      MOV  EDI, [ESP]
      MOV  EBX, EAX
      AND  EAX, Mask1010
      AND  EBX, Mask0101
      SHR  EAX, 5
      IMUL EAX, Dens2
      IMUL EBX, Dens2
      MOV  ESI, EDI
      AND  EDI, Mask1010
      AND  ESI, Mask0101
      SHR  EDI, 5
      IMUL EDI, Dens1
      IMUL ESI, Dens1
      ADD  EAX, EDI
      ADD  EBX, ESI
      AND  EAX, Mask1010
      SHR  EBX, 5
      AND  EBX, Mask0101
      OR   EAX, EBX
      MOV [ECX], EAX

      ADD  EBP, 4
      ADD  ESP, 4
      ADD  ECX, 4

      CMP  EBP, FinA
      JNE  @LOOPA

      @FINAL:

      MOV EBX, &EBX
      MOV EDI, &EDI
      MOV ESI, &ESI
      MOV ESP, &ESP
      MOV EBP, &EBP
end;

function Pt(B: TBitmap): Pointer;
begin
   Pt := B.Scanline[(B.Height - 1)]
end;
procedure fadeBitmap( const BitmapFrom, BitmapTo, BitmapAusgabe: TBitmap; const fade: Byte);
begin
   fadeNow(Pt(BitmapFrom), Pt(BitmapTo), Pt(BitmapAusgabe), BitmapAusgabe.width, BitmapAusgabe.height, fade);
end;

{----------------------------------forceForegroundWindow-----------------------}

function forceForegroundWindow(hwnd: THandle): boolean;
const
  SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
  SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
  ForegroundThreadID: DWORD;
  ThisThreadID: DWORD;
  timeout: DWORD;
begin
  if IsIconic(hwnd) then
    ShowWindow(hwnd, SW_RESTORE);
  if GetForegroundWindow = hwnd then
    Result := true
  else
  begin
    {Windows 98/2000 doesn't want to foreground a window when some other
    window has keyboard focus}
    if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4)) or
       ((Win32Platform = VER_PLATFORM_WIN32_WINDOWS) and ((Win32MajorVersion > 4) or
       ((Win32MajorVersion = 4) and (Win32MinorVersion > 0)))) then
    begin
      {Code from Karl E. Peterson, www.mvps.org/vb/sample.htm
      Converted to Delphi by Ray Lischner
      Published in The Delphi Magazine 55, page 16}
      Result := false;
      ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
      ThisThreadID := GetWindowThreadPRocessId(hwnd, nil);
      if AttachThreadInput(ThisThreadID, ForegroundThreadID, true) then
      begin
        BringWindowToTop(hwnd);  {IE 5.5 related hack}
        SetForegroundWindow(hwnd);
        AttachThreadInput(ThisThreadID, ForegroundThreadID, false);
        Result := (GetForegroundWindow = hwnd);
      end;
      if not Result then
      begin
        {Code by Daniel P. Stasinski (dannys@karemor.com)}
        SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @timeout, 0);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0,
                                                     TObject(0), SPIF_SENDCHANGE);
        BringWindowToTop(hwnd);  {IE 5.5 related hack}
        SetForegroundWindow(hWnd);
        SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0,
                                                      TObject(timeout), SPIF_SENDCHANGE);
      end;
    end
    else
    begin
      BringWindowToTop(hwnd);  {IE 5.5 related hack}
      SetForegroundWindow(hwnd);
    end;
    Result := (GetForegroundWindow = hwnd);
  end;
end;

end.
