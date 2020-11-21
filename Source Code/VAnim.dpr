program VAnim;
                                                  
uses  HookUnit, Windows, Messages, ShellApi;


{$WARNINGS OFF}
{$HINTS OFF}
{$R ressourcen\ressourcen.res}
const
  IDM_ABOUT    = 1;
  IDM_SETTINGS = 2;
  IDM_CLOSE    = 3;
  WM_TRAYNOTIFY = WM_USER + 1024; // selbstregistrierte Nachricht für TrayIcon-Events
  WM_CONFIG = WM_USER + 1023;


type
 PNotifyIconData = ^TNotifyIconData;
 TNotifyIconData = record
    cbSize: LongWord;
    Wnd: LongWord;
    uID: LongWord;
    uFlags: LongWord;
    uCallbackMessage: LongWord;
    hIcon: LongWord;
    szTip: array [0..63] of AnsiChar;
  end;

var
  WM_TASKBARCREATED: Cardinal;    // Nachricht, die wir brauchen, um das TrayIcon bei Bedarf neu zu zeichnen ( also immer wenn der Explorer abratzt ;) )
  IconData: TNotifyIconData;      // Enthält alle "Werte" vom TrayIcon
  handle: integer;
  doTray: Boolean;

procedure addTray;
var
 DLLHandle: integer;
begin
 if not doTray then exit;

 if IconData.cbSize = 0 then
 begin
   IconData.cbSize := SizeOf(TNotifyIconData);                   // Struktur für TaskbarIcons initialisieren
   IconData.wnd := handle;                                       // übernimmt unsere eigene mainhWnd
   IconData.uId := 0;
   IconData.hIcon := LoadIcon(HInstance, 'tna');
   IconData.uFlags := 1 or 2 or 4;
   IconData.uCallbackMessage := WM_TRAYNOTIFY;
   IconData.szTip := 'V Animator';
 end;
 Shell_NotifyIcon(NIM_ADD, @IconData);
end;

procedure removeTray;
begin
 if not doTray then exit;
 Shell_NotifyIcon(2, @IconData);
end;

procedure doMenu;
var
 hm: HMENU;
 p: TPoint;
begin
 GetCursorPos(p);
 hm := CreatePopupMenu;

 AppendMenu(hm,MF_STRING,IDM_ABOUT,'Information');
 AppendMenu(hm,MF_STRING,IDM_SETTINGS,'Settings');
 AppendMenu(hm,MF_SEPARATOR,0,NIL);
 AppendMenu(hm,MF_STRING,IDM_CLOSE,'Exit');

 SetForegroundWindow(handle);
 TrackPopupMenu(hm,TPM_RIGHTALIGN,p.X,p.Y,0,handle,nil);
 DestroyMenu(hm);
end;

{----------------------------------RunProcess----------------------------------}

function RunProcess(commandLine:String; MustWait: Boolean; Visibility: Word):DWORD;
var
 SI: TStartupInfo;
 PI: TProcessInformation;
 Proc: THandle;
begin
 FillChar(SI, SizeOf(SI), 0);
 SI.cb := SizeOf(SI);
 SI.dwFlags := STARTF_USESHOWWINDOW;
 SI.wShowWindow := Visibility;
 if not CreateProcess(NIL, pchar(commandLine),
  nil, nil, false, Normal_Priority_Class, nil, nil, SI, PI) then
   messageBox(0, pchar('Cannot open "'+commandLine+'"'), 'V Animator', MB_OK);

 Proc := PI.hProcess;
 CloseHandle(PI.hThread);

 if MustWait then
  if WaitForSingleObject(Proc, Infinite) <> Wait_Failed then
   GetExitCodeProcess(Proc, Result);

 CloseHandle(Proc);
end;


function WndProc(hWnd: LongWord; uMsg: LongWord; wParam: Longint; lParam: Longint): LongInt; stdcall;
begin
  case uMsg OF
    WM_TRAYNOTIFY:
      begin
      // if lParam= WM_LBUTTONDOWN then messageBox(0, 'test', 'test', 0)
      // else
       if lParam= WM_RBUTTONDOWN then doMenu;
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
    WM_TIMER: begin
               if wParam = 0 then
               begin
                if startHook then
                 killTimer(handle, wParam);
               end;
              end;
    WM_CONFIG: sendMessage(hWnd, WM_COMMAND, IDM_SETTINGS, 0);
    WM_COMMAND: case wParam of
                 IDM_CLOSE: postQuitMessage(0);
                 IDM_ABOUT: MessageBox(0, pchar('This program is OpenSource.'#13#13+'There is no Homepage until now, but you can visit http://www.aqua-soft.org/board/showthread.php?t=17001 for further informations or updates.'#13#13+'Programmed 2004 by Vjay'), 'V Animator', MB_OK or MB_ICONINFORMATION);
                 IDM_SETTINGS: begin
                                stopHook;
                                runProcess('VAnim\VAnimConfig.exe', true, SW_SHOW);
                                startHook;
                                updateHook;
                               end;
                end;
  else
   if uMsg = WM_TASKBARCREATED then addTray
   else Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

procedure checkDoTray;
begin
 doTray:= true;
 if ParamCount > 0 then
  doTray:= ParamStr(1) <> '/start';
end;

function specialStart: Boolean;
begin
 result:= false;
 if ParamCount > 0 then
 begin
  if ParamStr(1) = '/config' then
  begin
   postMessage( findWindow('#32770', 'V Animator'), WM_CONFIG, 0, 0);
   result:= true;
  end
  else if ParamStr(1) = '/stop' then
  begin
   postMessage( findWindow('#32770', 'V Animator'), WM_QUIT, 0, 0);
   result:= true;
  end;

 end;
end;

var
 msg: TMsg;
begin                     {prevents doublestarts}
 if not specialStart and (findWindow('#32770', 'VAnim')=0) then
 begin
  checkDoTray;
  handle:= CreateWindowEx(0, '#32770', 'VAnim', LONGWORD($80000000), -999, 0, 0, 0, 0, 0, hInstance, NIL);
  if not startHook then
  begin
   setTimer(handle, 0, 1000, NIL);
  end;

  addTray;
  WM_TASKBARCREATED := RegisterWindowMessage('TaskbarCreated'); // Da der Explorer öfters abstürzt - evtl. Icon neu reinmachen
  setWindowLong(handle, -4, integer( @WndProc));
  while True do begin
    if not GetMessage(msg, 0, 0, 0) then break; //au revoir
    translatemessage(msg);
    dispatchmessage(msg);
  end;
  stopHook;
  removeTray;
 end;
end.
