unit ButtonPulserUnit;

interface

uses Windows, Messages, Classes, SysUtils, Graphics, IniFiles, Dialogs;

type
 TButtonPulser = class;

 PButton = ^TButton;
 TButton = record
  handle: integer;
  parent: integer;
 end;

 TPButton = class
 private
  ButtonPulser: TButtonPulser;
  Bounds: TRect;
  caption: string;
  BitmapPulsed: TBitmap;
  BitmapActive: TBitmap;
  BitmapTemp: TBitmap;
  pulsepos: integer;
  pulseauf: Boolean;
 public
  PB: PButton;
  procedure NextPulse;
  procedure draw;
  constructor create(const ButtonPulser: TButtonPulser; const PB: PButton);
  destructor destroy; override;
 end;

 TButtonPulser = class
 private
   Handle: integer;
   ButtonList: TList;
   PBList: TList;
   delay, delayButton: integer;
   procedure clearPBList;
   procedure clearButtonList;
   function getButtonTopParent( const Handle: integer): integer;
   function isActiveButton( const Handle: integer):Boolean;
   function isButtonDisabled( const Handle: integer):Boolean;
   function isButtonPushed( const Handle: integer):Boolean;
   function isMouseOverButton( const Handle: integer): Boolean;
   function indexOfHandle( const Handle: integer): integer;
   function getButtonRect(const handle: integer): TRect;
   function getButtonCaption(const handle: integer): string;
   procedure initButtonPulsing( const PB: PButton);
   procedure deInitButtonPulsing(const Handle: integer);
   procedure MyWndProc( var Message: TMessage);
   procedure pulseAll;
   function getBLButton( const handle: integer): PButton;
   procedure paintDelayedTimer;
 public
  procedure PaintButtonDelayed( const Handle: integer);
  procedure PaintButton( const Handle: integer);
  procedure ButtonCreated( const Handle: integer);
  procedure ButtonDestroyed( const Handle: integer);
  function isButtonPulsing( const handle: integer): Integer;
  constructor create;
  destructor destroy; override;
 end;

implementation

uses MainUnit, MainFunc, ButtonGeneratorUnit;

{ TButtonPulser }

constructor TButtonPulser.create;
begin
 inherited;
 PBList:= TList.create;
 ButtonList:= TList.create;
 handle:= allocatehWnd( MyWndProc);
end;

destructor TButtonPulser.destroy;
begin
 deAllocatehWnd( handle);

 clearButtonList;
 clearPBList;

 PBList.free;
 ButtonList.free;
 ButtonPulser:= NIL;
 inherited;
end;

function TButtonPulser.getButtonCaption(const handle: integer): string;
begin
 setLength(result, 256);
 sendMessage(handle, WM_GETTEXT, 256, integer(pchar(result)));
 setLength(Result, strlen(pchar(result)));
end;

function TButtonPulser.getButtonRect( const handle: integer): TRect;
begin
 getWindowRect( handle, result);
 result.right:= result.right - result.left;
 result.bottom := result.bottom - result.top;
 result.left:= 0;
 result.top:= 0;
end;

function TButtonPulser.indexOfHandle(const Handle: integer): integer;
var
 wdh: integer;
begin
 result:= -1;
 for wdh:= 0 to PBList.Count-1 do
  if TPButton( PBList[wdh]).PB.handle = Handle then
  begin
   result:= wdh;
   exit;
  end;
end;

procedure TButtonPulser.initButtonPulsing( const PB: PButton);
var
 wdh: integer;
 i1: integer;
 B: TPButton;
begin
 if indexofHandle( Handle) = -1 then
 begin
  for wdh:= PBList.count-1 downto 0 do
  begin
   if TPButton( PBList[wdh]).PB.parent = PB.parent then
    deInitButtonPulsing( PB.handle);
  end;


  B:= TPButton.create(self, PB);
  if PBList.count = 0 then setTimer(handle, 0, 50, NIL);
  PBList.add( B);
 end;
end;

procedure TButtonPulser.pulseAll;
var
 wdh: integer;
begin
 for wdh:= PBList.count-1 downto 0 do
 begin
  TPButton( PBList[wdh]).NextPulse;
 end;
end;

procedure TButtonPulser.MyWndProc(var Message: TMessage);
begin
 if Message.Msg = WM_TIMER then
 begin
  case Message.wParam of
   0: pulseAll;
   1: paintDelayedTimer;
  end;
 end
 else Message.Result := Windows.DefWindowProc(handle, Message.Msg, Message.WParam, Message.LParam);
end;

procedure TButtonPulser.PaintButton(const Handle: integer);
var
 R1, R2, R3: TRect;
 B1: TBitmap;
 dc: HDC;
 State: integer;
 pHandle: integer;
 Font: TFont;
 p1: TPoint;
 i1: integer;
 s1: string;
 PB: PButton;
begin
 if not isWindow(handle) then exit;

 i1:= indexOfHandle( handle);

 if i1 <> -1 then TPButton( PBList[i1]).draw
 else
 begin
   PB:= getBLButton( handle);
   if PB= NIL then
   begin
    new( PB);
    PB^.handle := handle;
    PB.parent := getbuttontopParent( handle);
    ButtonList.add( PB);

   end;
   r1:= getButtonRect(handle);


   B1:= TBitmap.create;
   B1.PixelFormat := pf24Bit;
   B1.Width := R1.Right;
   B1.Height := R1.Bottom;
   if isButtonDisabled( Handle) then State:= bgDisabled
   else if isButtonPushed( handle) then
   begin
    State:= bgClicked;
   end
   else if isActiveButton( handle) then
   begin
    if getForegroundWindow = PB.parent then
    begin
     State:= bgInActive;
     initButtonPulsing( PB);
    end 
    else State:= bgInActive; 
   end
   else if isMouseOverButton(handle) then State:= bgMouseOver
   else State:= bgInActive;

   dc:= getDC( handle);
   if dc <> 0 then
   begin
    try
     bitBlt(B1.Canvas.handle, 0, 0, r1.right, r1.Bottom, dc, 0, 0, SRCCOPY);
     ButtonGenerator.generateButton( State, getButtonCaption(PB.handle), B1);
     bitBlt(dc, 0, 0, r1.right, r1.Bottom, B1.Canvas.Handle, 0, 0, SRCCOPY);
    except end;
    releaseDC( handle, dc);
   end;
   B1.free;

 end;

end;

procedure TButtonPulser.deInitButtonPulsing(const Handle: integer);
var
 i1: integer;
 PB: TPButton;
begin
 i1:= indexofHandle( Handle);
 if i1 <> -1 then
 begin
  TPButton( PBList[i1]).free;
  PBList.delete(i1);
  if PBList.count = 0 then killTimer(self.Handle, 0);
  if isWindow(handle) then PaintButton( handle);
 end;
end;

function TButtonPulser.isActiveButton(const Handle: integer): Boolean;
var
 i1, wdh: integer;
 PB, PB2: PButton;
begin
 result:= false;

 PB:= getBLButton( handle);
 if PB= NIL then exit;

 i1:= sendMessage(handle, BM_GETSTATE, 0, 0);
 if (i1 or BST_FOCUS = i1) then result:= true;

 if not Result then
 begin
  i1:= sendMessage(PB.Parent, DM_GETDEFID, 0, 0);
  if i1 <> 0 then
  begin
   result:= handle= getDlgItem(PB.Parent, loWord( i1));
  end;
 end;

 if Result then
 begin
  for wdh:= 0 to ButtonList.Count-1 do
   if PButton(ButtonList[wdh]).parent = PB.parent then
   begin
    PB2:= PButton(ButtonList[wdh]);
    if not isWindowVisible( PB2.handle) then break;
    if PB <> PB2 then
    begin
     i1:= sendMessage(pb2.handle, BM_GETSTATE, 0, 0);
     if (i1 or BST_FOCUS = i1) then
     begin
      result:= false;
      break;
     end;
    end;
   end;
 end;

end;

procedure TButtonPulser.ButtonCreated(const Handle: integer);
var
 h: integer;
 PB: PButton;
 p: pchar;
begin
 if getBLButton( Handle) = NIL then // neu erzeugen
 begin
  new(PB);
  PB.parent:= -1;
  PB.handle := Handle;
  ButtonList.Add( PB);
 end;
end;

procedure TButtonPulser.ButtonDestroyed(const Handle: integer);
var
 PB: PButton;
begin
 PB:= getBLButton( Handle);
 if PB <> NIL then
 begin
  ButtonList.Delete( ButtonList.indexOf( PB));
 end;
end;

function TButtonPulser.getBLButton(const handle: integer): PButton;
var
 wdh: integer;
begin
 result:= NIL;
 for wdh:= 0 to ButtonList.Count-1 do
  if PButton( ButtonList[wdh]).handle = Handle then
  begin
   result:= ButtonList[wdh];
   if result.parent = -1 then
    if isWindowVisible( result.handle) then
     result.parent:= getButtonTopParent(result.handle);
   exit;
  end;
end;

procedure TButtonPulser.clearButtonList;
var
 wdh: integer;
begin
 for wdh:= 0 to ButtonList.count-1 do
  dispose( ButtonList[wdh]);
 ButtonList.clear;
end;

procedure TButtonPulser.clearPBList;
var
 wdh: integer;
begin
 for wdh:= 0 to PBList.count-1 do
  TPButton( PBList[wdh]).free;
 ButtonList.clear;
end;

function TButtonPulser.isButtonDisabled(const Handle: integer): Boolean;
begin
 result:= not isWindowEnabled( Handle);
end;

function TButtonPulser.isButtonPushed(const Handle: integer): Boolean;
var
 i1: integer;
begin
 i1:= sendMessage(handle, BM_GETSTATE, 0, 0);
 result:= (i1 or BST_PUSHED	 = i1);
end;

function TButtonPulser.isMouseOverButton(const Handle: integer): Boolean;
var
 p1: TPoint;
 r1: TRect;
begin
 getCursorPos( p1);
 getWindowRect(handle, r1);
 result:= ptInRect( r1, p1);
end;

function TButtonPulser.getButtonTopParent(const Handle: integer): integer;
var
 i1: integer;
begin
 result:= handle;
 repeat
  result:= getParent( result);
  i1:= getWindowLong(result, GWL_STYLE);

  if (i1 or (WS_OVERLAPPED or WS_CAPTION) = i1) then break;

  if ((GetWindowLong(result, GWL_HWNDPARENT) = 0) or
     (GetWindowLong(result, GWL_HWNDPARENT) = GetDesktopWindow)) then break;
 until result = 0;
end;

function TButtonPulser.isButtonPulsing(const handle: integer): Integer;
begin
 if getBlButton( handle) <> NIL then result:= 1
 else result:= 0;
end;

procedure TButtonPulser.PaintButtonDelayed(const Handle: integer);
begin
 PaintButton( handle);

 delay:= 50;
 delayButton:= Handle;
 killTimer(handle, 1);
 setTimer(handle, 1, 100, NIL);
end;

procedure TButtonPulser.paintDelayedTimer;
begin
 dec( delay);
 if delay= 0 then killTimer(handle, 1);
 paintButton( delayButton);
end;

{ TPButton }

constructor TPButton.create(const ButtonPulser: TButtonPulser; const PB: PButton);
var
 dc: HDC;
begin
 inherited create;
 self.PB := PB;
 self.ButtonPulser := ButtonPulser;
 Bounds:= ButtonPulser.getButtonRect( PB.handle);

 BitmapPulsed:= TBitmap.create;
 BitmapActive:= TBitmap.create;
 BitmapTemp:= TBitmap.create;


 BitmapPulsed.PixelFormat := pf24Bit;
 BitmapPulsed.Width := Bounds.right;
 BitmapPulsed.Height := Bounds.bottom;

 BitmapActive.PixelFormat := pf24Bit;
 BitmapActive.Width := Bounds.right;
 BitmapActive.Height := Bounds.bottom;

 BitmapTemp.PixelFormat := pf24Bit;
 BitmapTemp.Width := Bounds.right;
 BitmapTemp.Height := Bounds.bottom;

 Caption:= ButtonPulser.getButtonCaption( PB.Handle);

 dc:= getDC( PB.handle);
 if dc <> 0 then
 begin
  bitBlt(BitmapActive.Canvas.Handle, 0, 0, Bounds.right, Bounds.Bottom, dc, 0, 0, SRCCOPY);
  bitBlt(BitmapPulsed.Canvas.handle, 0, 0, Bounds.right, Bounds.Bottom, dc, 0, 0, SRCCOPY);
  releaseDC( PB.handle, dc);
 end;

 ButtonGenerator.generateButton(bgActive, Caption, BitmapActive);
 ButtonGenerator.generateButton(bgPulsed, Caption, BitmapPulsed);
 pulseAuf:= true;
end;

destructor TPButton.destroy;
begin
 BitmapPulsed.free;
 BitmapActive.free;
 BitmapTemp.free;
 inherited;
end;

procedure TPButton.NextPulse;
begin
 if pulseauf then
 begin
  inc( pulsepos);
  if pulsepos>15 then pulseauf:= false;
 end
 else
 begin
  dec( pulsepos);
  if pulsepos<2 then pulseauf:= true;
 end;
 draw;
end;


procedure TPButton.draw;
var
 dc: hdc;
begin
 if not isWindowVisible( PB.handle) or (not ButtonPulser.isActiveButton(PB.handle) and (PB.parent = getforegroundwindow)     ) then
 begin
  ButtonPulser.deInitButtonPulsing( PB.handle);
  exit;
 end
 else if ButtonPulser.isMouseOverButton( PB.handle) then exit;

 FadeBitmap(BitmapActive, BitmapPulsed, BitmapTemp, PulsePos);

 dc:= getDC( PB.handle);
 if dc<>0 then
 begin
  bitBlt(dc, 0, 0, Bounds.Right, Bounds.Bottom, BitmapTemp.Canvas.Handle, 0, 0, SRCCOPY);
  releaseDC( PB.handle, dc);
 end;

end;

end.
