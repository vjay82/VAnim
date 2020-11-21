library vAnimHook;

uses
  Windows,
  uallHook,
  Messages,
  SysUtils,
  SyncObjs,
  IniFiles,
  Classes,
  MainFunc,
  GlobalVarUnit in 'GlobalVarUnit.pas',
  PulseButtonUnit in 'PulseButtonUnit.pas',
  ProgressBarUnit in 'ProgressBarUnit.pas',
  MovingControlsUnit in 'MovingControlsUnit.pas',
  HaloUnit in 'HaloUnit.pas';

procedure stopHook; stdCall;
begin
 // baldiges ende
 if Infos.CBTHookHandle <> 0 then
 begin
  unHookWindowsHookEx( Infos.CBTHookHandle);
  Infos.CBTHookHandle := 0;
 end;
end;

procedure checkIT( const handle: integer);
var
 p: pchar;
begin
 getMem(p, 20);
 getClassName( handle, p, 20);

 if Infos.active_ProgressBarAnimator and isProgressBar(p, handle) then
  initProgressBarControl( handle)
 else if Infos.active_HaloControls and isHalo(p, handle) then
  initHaloControl( handle)
 else if Infos.active_ButtonPulser and isButton(p, handle) then
  initPulseButtonControl( handle);
 freeMem(p);
end;

function delaHook(code: Integer; leer: dword; msg: PCWPRETSTRUCT ): LRESULT stdcall;
begin
 if code >= 0 then
 begin
  if not excluded then
  begin
   if (msg^.message = WM_CREATE) then
   begin
    checkIt( msg.hWnd);
   end;
  end;

  if code <> HC_ACTION then
   result := CallNextHookEx(Infos.CBTHookHandle, Code, leer, dword( msg))
  else result:= 0;
 end
 else
   result := CallNextHookEx(Infos.CBTHookHandle, Code, leer, dword( msg));
end;

function getRunDLLDLL: string;
var
 wdh: integer;
begin
 for wdh:= 1 to ParamCount do
  if pos('.cpl', lowerCase( paramStr(wdh)))>0 then
  begin
   result:= extractFileName( lowerCase( paramStr(wdh)));
   exit;
  end;

 for wdh:= 1 to ParamCount do
  if pos('.dll', lowerCase( paramStr(wdh)))>0 then
  begin
   result:= extractFileName( lowerCase( paramStr(wdh)));
   exit;
  end;

 if paramStr(1) <> '' then result:= paramStr(1)
 else result:= 'unknown';
end;

var
 nextfunc: pointer;

function myDrawFrameControl(DC: HDC; const Rect: TRect; uType, uState: UINT): BOOL; stdcall;
begin
 beep; // does nothing
end;

procedure DllEntryPoint (dwReason: DWord);
var
 s1: string;
begin
  Case dwReason Of
  Dll_Process_Attach:
    begin
     HookCode( @DrawFrameControl, @myDrawFrameControl, nextFunc);

     hMMF := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, Sizeof( TInfos), MMFName);
     if hMMF <> 0 then
     begin
      Infos:= MapViewofFile(hMMF, FILE_MAP_ALL_ACCESS, 0, 0, 0);
      if Infos = NIL then
      begin
       closeHandle( hMMF);
       hMMF := 0;
       exit;
      end;

      s1:= lowerCase( extractFileName( paramStr(0)));
      if s1 = 'rundll32.exe' then
      begin
       s1:= getRunDLLDLL;
      end;
      excluded:= vIsStringInSeps(Infos.exclusionList, s1);
      if not excluded then excluded := s1 = 'vanimconfig.exe';

      HookedControls:= TList.create;
      Lock:= TCriticalSection.create;
      MovedControls:= TMovedControls.create;
      GesperrteControls:= TList.create;
      MovedControls.loadFromFile( Infos.mypath + 'movedControls\'+filterDateiName(s1)+'.ini');
      try
       if not debug then loadlibrary( 'vAnimHook.dll'); // the trick ;)
      except end;

     end;
    end;
  Dll_Process_Detach:
    begin
      // We never really detach, because we load ourself again
      // we detach when the process quits...

      try
       if hMMF <> 0 then
       begin
        excluded:= true;
        if Lock <> NIL then
        begin
         Lock.Acquire;
         MovedControls.free;
         GesperrteControls.free;
       //  while HookedControls.count > 0 do
       //   deInitControl( PHookedControl(HookedControls[0]).handle);
         freeAndNIL( HookedControls);
         Lock.free;
         Lock:= NIL;
        end;
        UnmapViewOfFile( Infos);
        closeHandle( hMMF);
        hMMF:= 0;
       end;
      except end;
    end;
  end
end;


procedure updateSettings; stdCall;
var
 Ini: TIniFile;
begin
 Ini:= TIniFile.create(Infos.mypath + 'settings.ini');
 Infos.active_ButtonPulser := Ini.ReadBool('active', 'buttonpulser', false);
 Infos.active_ProgressBarAnimator := Ini.ReadBool('active', 'progressbaranimator', false);
 Infos.active_HaloControls := Ini.ReadBool('active', 'haloeffects', false);
 Infos.exclusionList := lowerCase( Ini.ReadString('exclusions', 'processnames', ''));
 Ini.free;

 // Here ive to do an enum-function enumerating all windows and set the hooks
end;

function startHook( myPath: pchar): Boolean; stdCall;
begin
 excluded:= true; // we dont hook ourself
 Infos.mypath := myPath;
 updateSettings;

 Infos.CBTHookHandle := SetWindowsHookEx(WH_CALLWNDPROCRET, @deLaHook, hInstance, 0);
 result:= (Infos.CBTHookHandle<>0);
end;

procedure animateControl(const handle: integer); stdcall;
var
 p: pchar;
begin
 getMem(p, 20);
 getClassName( handle, p, 20);

 if isButton( p, handle) then
 begin
  initPulseButtonControl( handle);
 end
 else if isProgressBar( p, handle) then
 begin
  initProgressBarControl( handle);
 end
 else if isHalo( p, handle) then
 begin
  initHaloControl( handle);
 end;
 freeMem( p);
end;

procedure deAnimateControl(const handle: integer); stdcall;
begin
 deInitControl( handle);
end;

exports
 startHook, stopHook, updateSettings, animateControl, deAnimateControl;

begin
 if hMMF = 0 then
 begin
  IsMultiThread:= true;
  DLLProc := @DllEntryPoint;
  DllEntryPoint (Dll_Process_Attach);
 end;
end.
