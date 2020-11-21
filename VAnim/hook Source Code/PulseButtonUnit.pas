unit PulseButtonUnit;

interface

uses Windows, Messages, GlobalVarUnit, Classes, SysUtils, Graphics, IniFiles, Math,
     MainFunc, MovingControlsUnit;

function isButton(const p: pchar; const handle: integer): Boolean;
procedure initPulseButtonControl(const handle: integer);
procedure deInitPulseButton( const objekt: pointer);
function buttonWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; const objekt: pointer; var rueckgabe: dWord): Boolean;

const
 bgActive    = 1;
 bgMouseOver = 2;
 bgInactive  = 3;
 bgDisabled  = 4;
 bgClicked   = 5;
 bgPulsed    = 6;

 WM_ACTIVATEPULSING = WM_USER + 100;

type
 TButtonGenerator = class
 private
  ButtonPath: string;
  FRightBorder: integer;
  FLeftBorder: integer;

  FPTransparent: TPoint;
  FTransparent: Boolean;

  BActive: TBitmap;
  BClicked: TBitmap;
  BDisabled: TBitmap;
  BInactive: TBitmap;
  BMouseOver: TBitmap;
  BPulsed: TBitmap;
 public
  ButtonCount: integer;
  FontActive: TFont;
  FontInActive: TFont;
  ScaleDownFont: Boolean;
  ScaleDownFontWidth: integer;
  PulsingSpeed: integer;
  MultiPulsing: Boolean;

  function getNeededSize(const Caption: string; const Bild: TBitmap): Integer;
  procedure generateButton( const bgStatus: integer; const altDown: Boolean; Caption: string; const Bild: TBitmap);
  procedure setTransparency( const Bild: TBitmap);
  function getTransparentColor( const Bild: TBitmap): TColor;
  procedure readSettings;

  constructor create;
  destructor destroy; override;

  property LeftBorder: integer read FLeftBorder;
  property RightBorder: integer read FRightBorder;
 end;

 TPulseButton = class( TMovingControl)
 private
  Bild: TBitmap;
  BildPulsed1: TBitmap;
  BildPulsed2: TBitmap;
  PulsePos: integer;
  PulseAb: Boolean;
  LButtonDown: Boolean;
  overlayWndHandle: integer;


  FParent: integer;
  FPulsing: Boolean;
  origWndProc: pointer;

  LastPaintSize: TPoint;
  LastPaintCaption: string;
  LastButtonStatus: integer;
  LastAltDown: Boolean;

  MouseLeaveCountDown: integer;

  function isAltDown: Boolean;
  procedure activate;
  function ButtonStatus: integer;

  procedure resetPictures;
  procedure Paint;
  procedure NextPulse;
  function isDisabled: Boolean;
  function isMouseOverButton: Boolean;
  function isPushed: Boolean;
  function isActive: Boolean;
  function readParent: integer;
  function getButtonTopParent: integer;
  function readPulsing: Boolean;
  procedure writePulsing(const Value: Boolean);
  procedure checkMouseover;
    procedure createOverlayWindow;
    procedure destroyOverlayWindow;
 public
 // MyLock: TCriticalSection;

  constructor create(const handle: integer; const origWndProc: pointer);
  destructor destroy; override;
  function left: integer;
  function top: integer;
  function buttonWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; var rueckgabe: dWord): Boolean;

  property Parent: integer read readParent;
  property Pulsing: Boolean read readPulsing write writePulsing;
 end;

var
 ButtonGenerator: TButtonGenerator = NIL;

implementation

uses HaloUnit;

function buttonWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; const objekt: pointer; var rueckgabe: dWord): Boolean;
begin
 result:= TPulseButton( Objekt).buttonWndProc( handle, Msg, wParam, lParam, rueckgabe);
end;

procedure deInitPulseButton(const objekt: pointer);
begin // Braucht kein Lock wird bereits gelockt aufgerufen
 if ButtonGenerator <> NIL then
 begin
  ButtonGenerator.ButtonCount := ButtonGenerator.ButtonCount-1;
  if ButtonGenerator.ButtonCount = 0 then
  begin
   freeAndNIL( ButtonGenerator);
  end;
 end;
 TPulseButton( objekt).free;
end;

procedure initPulseButtonControl(const handle: integer);
var
 HKT: PHookedControl;
begin
 Lock.Acquire;
 if getHKTIndex( handle) = -1 then // wir haben was zu tun
 begin
  if ButtonGenerator = NIL then ButtonGenerator:= TButtonGenerator.create
  else ButtonGenerator.ButtonCount := ButtonGenerator.ButtonCount+1;

  new( HKT);
  HKT.handle := 0;
  HKT.typ := hktButton;
  HKT.origWndFunction := pointer( getWindowLong(handle, GWL_WNDPROC));
  HKT.Objekt := TPulseButton.create( handle, HKT.origWndFunction);
  HookedControls.add( HKT);
  setWindowLong( handle, GWL_WNDPROC, integer( @looksBetterWindowProc));
  HKT.handle := handle;
 end;
 Lock.release;
end;

function isButton(const p: pchar; const handle: integer): Boolean;
var
 i1: integer;
begin
 result:= false;

 if (p = 'button') or (p = 'Button') or (p = 'TButton') then
 begin
  i1:= getWindowLong(handle, GWL_STYLE	);
  if (i1 or BS_RADIOBUTTON <> i1) and
     (i1 or BS_AUTORADIOBUTTON <> i1) and
     (i1 or BS_CHECKBOX	<> i1) and
     (i1 or BS_3STATE	<> i1) and
     (i1 or BS_OWNERDRAW <> i1) and
     (i1 or BS_GROUPBOX <> i1) and
     (i1 or BS_USERBUTTON	<> i1) and
     (i1 or BS_BITMAP <> i1) and
     (i1 or BS_ICON	<> i1) and
     (i1 or BS_PUSHBUTTON = i1) and
     (i1 or BS_TEXT = i1) then
  begin
   // checken ob wir vor uns den explorer-START button haben
   i1:= getParent( handle);
   if i1 <> 0 then
   begin
    getClassName( i1, p, 20);
    result:= p <> 'Shell_TrayWnd';
   end
   else result:= true;
  end;
 end;
end;

{ TPulseButton }

constructor TPulseButton.create(const handle: integer; const origWndProc: pointer);
begin
 self.handle := handle;
 self.origWndProc := origWndProc;
 inherited create;

 updateRects;

 Bild:= TBitmap.create;
 Bild.PixelFormat := pf24Bit;
 FParent:= -1;

 setWindowLong( handle, GWL_EXSTYLE, getWindowLong(handle, GWL_EXSTYLE) or WS_EX_TRANSPARENT);
 setWindowLong( handle, GWL_STYLE, getWindowLong(handle, GWL_STYLE) or WS_CLIPCHILDREN);
 setTimer(handle, 995, 500, NIL);
end;

destructor TPulseButton.destroy;
begin
 destroyOverlayWindow;
 Pulsing := false;
 Bild.free;
 inherited;
end;

procedure TPulseButton.Paint;
var
 C: TCanvas;
 Caption: string;
 ButtonStatus, i1: integer;
 resetPictures: Boolean;
 Pushed: Boolean;
 BTemp: TBitmap;
// oldRgn, Rgn: hRgn;
begin
 if not isWindowVisible( handle) then exit;

 updateRects;
 Caption:= self.Caption;
 ButtonStatus:= self.ButtonStatus;

// Rgn:= createRectRgn(0,0,0,0);
// GetUpdateRgn(handle, Rgn, false);

 ValidateRect(handle, NIL);

 Pushed:= isPushed;

 C:= TCanvas.create;
 //Beginpaint( handle, ps);
 C.handle := getWindowDC( handle);

// oldRgn:= SelectObject(C.Handle, Rgn);

 if (LastPaintSize.X <> ClientRect.right) or
    (LastPaintSize.Y <> ClientRect.bottom) then
 begin
  LastPaintSize:= ClientRect.BottomRight;
  resetPictures:= true;;
 end
 else if
    (LastPaintCaption <> Caption) or
    (ButtonStatus <> LastButtonStatus) then
 begin
  LastPaintCaption:= Caption;
  LastButtonStatus:= ButtonStatus;
  ResetPictures:= true;
 end
 else if LastAltDown <> isAltDown then
 begin
  LastAltDown:= isAltDown;
  ResetPictures:= true;
  if LastAltDown then setTimer(handle, 996, 100, NIL);
 end
 else resetPictures:= false;

 

 if resetPictures then
 begin
  self.resetPictures;
  if FPulsing and not Pushed then
  begin
   ButtonGenerator.generateButton(bgActive, LastAltDown, Caption, BildPulsed1);
   ButtonGenerator.generateButton(bgPulsed, LastAltDown, Caption, BildPulsed2);
  end
  else ButtonGenerator.generateButton(ButtonStatus, LastAltDown, Caption, Bild);
 end;

 if FPulsing and not Pushed then
 begin
  fadeBitmap(BildPulsed1, BildPulsed2, Bild, PulsePos);
 end;

 ButtonGenerator.setTransparency( Bild);
 i1:= getWindowLong(getParent(handle), GWL_STYLE);
                 
 if (i1 or WS_CLIPCHILDREN = i1) or (i1 or WS_CLIPSIBLINGS = i1) then
 begin
  BTemp:= TBitmap.create;
  BTemp.width:= ClientRect.Right;
  BTemp.Height:= ClientRect.Bottom;
  SetViewportOrgEx(BTemp.Canvas.Handle, left*-1, top*-1, NIL);
  sendMessage(getParent( handle), WM_ERASEBKGND, BTemp.canvas.handle, 0);
  SetViewportOrgEx(BTemp.Canvas.Handle, 0, 0, NIL);
  BTemp.Canvas.Draw(0,0, Bild);
  BitBlt(C.Handle, 0, 0, ClientRect.right, ClientRect.bottom, BTemp.canvas.handle, 0, 0, SRCCOPY);
  BTemp.free;
 end 
 else C.Draw(0, 0, Bild);

// SelectObject( C.Handle, oldRgn);
// DeleteObject( Rgn);

 releaseDC( handle, C.Handle);
 C.Handle:= 0;
 C.free;

 if (getForegroundWindow = parent) and (ButtonStatus = bgActive) then Pulsing := true
 else if not ButtonGenerator.MultiPulsing then Pulsing:= false;
end;

procedure TPulseButton.resetPictures;
begin
// Bild.Height := 0;
 Bild.Width := ClientRect.Right;
 Bild.Height := ClientRect.Bottom;
 if BildPulsed1 <> NIl then
 begin
 // BildPulsed1.Height := 0;
  BildPulsed1.Width := Bild.width;
  BildPulsed1.Height := Bild.height;
//  BildPulsed2.Height := 0;
  BildPulsed2.Width := Bild.width;
  BildPulsed2.Height := Bild.height;
 end;
end;

procedure TPulseButton.checkMouseover;
begin
 if not isMouseOverButton then
 begin
  InvalidateRect(handle, NIL, false);
  dec( MouseLeaveCountDown);
  if MouseLeaveCountDown < 1 then
  begin
   killTimer(handle, 998);
   Paint;
  end;
 end
 else MouseLeaveCountDown:= 10;
end;

function OverlayWndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam): lresult; stdcall;
begin
 case uMsg of
  WM_PAINT: begin validateRect(hWnd, NIL); invalidateRect(getParent(hWnd), NIL, false); sendMessage( getParent(hWnd), WM_PAINT, 0, 0); end;
  WM_ERASEBKGND: begin result:= 1; end;
 else
  Result:= DefWindowProc( hWnd, uMsg, wParam, lParam);
 end;
end;

procedure TPulseButton.createOverlayWindow;
var
 p1: TPoint;
begin
 if overlayWndHandle = 0 then
 begin
  updateRects;
  p1:= Point( 0, 0);
  Windows.ClientToScreen(getParent(handle), p1);
  overlayWndHandle := CreateWindowEx(WS_EX_TOPMOST, '#32770', '', WS_CHILD, 0, 0, ClientRect.right, ClientRect.bottom, handle, 0, hInstance, nil);
  setWindowLong( overlayWndHandle, GWL_WNDPROC, integer(@OverlayWndProc));
  setWindowPos(overlayWndHandle, 0, 0, 0, 0, 0, SWP_NOZORDER or SWP_NOACTIVATE or SWP_SHOWWINDOW or SWP_NOMOVE or SWP_NOSIZE);
 end;
end;

procedure TPulseButton.destroyOverlayWindow;
begin
 if overlayWndHandle <> 0 then
 begin
  destroyWindow( overlayWndHandle);
  overlayWndHandle:= 0;
 end;
end;

function TPulseButton.buttonWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; var rueckgabe: dWord): Boolean;
begin
 result:= false;
 if MovingControlWndProc( handle, Msg, wParam, lParam) then exit;

 try
   case Msg of
    WM_PAINT{, WM_NCPAINT}: begin
               if wParam= 0 then Paint
               else result:= true;
              end;
    WM_ERASEBKGND: rueckgabe:= 1;
    WM_TIMER: begin
               if WParam = 999 then NextPulse
               else if WParam = 996 then
               begin
                if not isAltDown then
                begin
                 killTimer(handle, 996);
                 InvalidateRect(handle, NIL, false);
                end;
               end
               else if WParam = 998 then checkMouseOver
               else if WParam = 995 then
               begin
                killTimer(handle, 995);
                InvalidateRect(handle, NIL, false);
               end
               else result:= true;

               result:= true;
              end;
   WM_SIZE, WM_WINDOWPOSCHANGED, WM_MOVE: begin
              Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
              InvalidateRect(handle, NIL, false);
             end;
   WM_LBUTTONDOWN: begin
                     if not LButtonDown then
                     begin
                      LButtonDown:= true;
                      activate;
                      createOverlayWindow;
                      Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                      destroyOverlayWindow;
                     end;
                    end;
   WM_LBUTTONUP, WM_LBUTTONDBLCLK: begin
                   if LButtonDown then
                   begin
                    LButtonDown:= false;
                    createOverlayWindow;
                    Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                    destroyOverlayWindow;
                    InvalidateRect(handle, NIL, false);
                   end;
                  end;
   WM_ENABLE, WM_RBUTTONDBLCLK, WM_SHOWWINDOW, WM_NCACTIVATE, WM_CAPTURECHANGED,
   WM_KILLFOCUS, WM_SETFOCUS, BM_SETSTATE, BM_SETSTYLE, WM_SETTEXT: begin
                  createOverlayWindow;
                  Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                  destroyOverlayWindow;
                  InvalidateRect(handle, NIL, true);
                  Paint;
                  InvalidateRect(handle, NIL, false);
                 end;
    WM_NCHITTEST: begin
                   Rueckgabe := HTCLIENT;
                   InvalidateRect(handle, NIL, false);
                  end;
    //WM_PRINT, WM_PRINTCLIENT: begin end;

    WM_MOUSEMOVE: begin
                   Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                   InvalidateRect(handle, NIL, false);
                   killTimer(handle, 998);
                   setTimer(handle, 998, 100, NIL);
                  end;
   // WM_NCMOUSEMOVE, WM_NCLBUTTONDOWN, WM_NCLBUTTONUP: begin end;
    WM_ACTIVATEPULSING: Pulsing:= boolean( wParam);
    WM_NCDESTROY: begin
                 Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                 deInitControl( handle);
                end;
   else
    result:= true;
   end;
 except end;
end;


function TPulseButton.isDisabled: Boolean;
begin
 result:= not isWindowEnabled( Handle);
end;

function TPulseButton.isPushed: Boolean;
var
 i1: integer;
begin
 i1:= sendMessage(handle, BM_GETSTATE, 0, 0);
 result:= (i1 or BST_PUSHED	 = i1);
// result:= LButtonDown;
end;

function TPulseButton.isMouseOverButton: Boolean;
var
 p1: TPoint;
begin
 getCursorPos( p1);
 result:= ptInRect( BoundsRect, p1);

 if result then
 begin
  // Doesnt work now
  try
   Bild.Transparent := false;
   if Bild.Canvas.Pixels[p1.X - BoundsRect.left, p1.Y - BoundsRect.top] = ButtonGenerator.getTransparentColor( Bild) then result:= false;
  except
   Result:= false;
  end;
 end;
end;

function TPulseButton.isActive: Boolean;
var
 i1, wdh, defHandle: integer;
 B: TPulseButton;
begin
 result:= false;

 i1:= sendMessage(handle, BM_GETSTATE, 0, 0);
 if (i1 or BST_FOCUS = i1) then result:= true;

 i1:= sendMessage(Parent, DM_GETDEFID, 0, 0);
 if i1 <> 0 then
 begin
  defHandle:= getDlgItem(Parent, loWord( i1));
  if not result then result:= handle= defHandle;
 end
 else defHandle:= 0;

 if Result then
 begin
  Lock.Acquire;

  for wdh:= HookedControls.Count-1 downto 0 do
  begin
   if PHookedControl(HookedControls[wdh]).typ <> hktButton then continue;
   B:= PHookedControl(HookedControls[wdh]).Objekt;

   if B.parent = parent then
   begin
    if not isWindowVisible( B.handle) then continue;
    if B <> self then
    begin
     if B.handle = defHandle then
     begin
      InvalidateRect(B.handle, NIL, false);
//      B.Paint;
     end;

     i1:= sendMessage(B.handle, BM_GETSTATE, 0, 0);
     if (i1 or BST_FOCUS = i1) then
     begin
      result:= false;
      Lock.Release;
      exit;
     end;
    end;
   end;
  end;
  Lock.Release;
 end;

end;

function TPulseButton.ButtonStatus: integer;
begin
 if isDisabled then result:= bgDisabled
 else if isPushed then result:= bgClicked
 else if isActive then
 begin
  if getForegroundWindow = parent then
  begin
   result:= bgActive;
  end
  else result:= bgInActive;
 end
 else if isMouseOverButton then result:= bgMouseOver
 else result:= bgInActive;
end;

function TPulseButton.getButtonTopParent: integer;
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

function TPulseButton.readParent: integer;
begin
 if FParent = -1 then FParent:= getButtonTopParent;
 result:= FParent;
end;

procedure TPulseButton.activate;
var
 wdh: integer;
 PB: TPulseButton;
begin
 setFocus( handle);
 Lock.Acquire;
 try
  for wdh:= HookedControls.count-1 downto 0 do
  begin
   if PHookedControl(HookedControls[wdh]).typ <> hktButton then continue;
   PB:= PHookedControl(HookedControls[wdh]).Objekt;

   if PB = self then continue;
   if ButtonGenerator.MultiPulsing then
    if PB.Parent <> Parent then continue;

   if PB.Pulsing then
    sendMessage(PB.handle, WM_ACTIVATEPULSING, 0, 0);
  end;
 except end;
 Lock.Release;
end;

function TPulseButton.readPulsing: Boolean;
begin
 result:= FPulsing;
end;

procedure TPulseButton.writePulsing(const Value: Boolean);
var
 wdh: integer;
 PB: TPulseButton;
begin
 if Value <> FPulsing then
 begin
  FPulsing:= Value;
  if Value then
  begin
   for wdh:= HookedControls.count-1 downto 0 do
   begin
    if PHookedControl(HookedControls[wdh]).typ <> hktButton then continue;
    PB:= PHookedControl(HookedControls[wdh]).Objekt;

    if PB = self then continue;
    if ButtonGenerator.MultiPulsing then
     if PB.Parent <> Parent then continue;

    if PB.Pulsing then
     sendMessage(PB.handle, WM_ACTIVATEPULSING, 0, 0);
   end;

   BildPulsed1:= TBitmap.create;
   BildPulsed1.PixelFormat := pf24Bit;
   BildPulsed2:= TBitmap.create;
   BildPulsed2.PixelFormat := pf24Bit;
   LastButtonStatus:= -1;
   PulsePos:= 1;
   PulseAb:= false;
   setTimer(handle, 999, ButtonGenerator.PulsingSpeed, NIL);
   InvalidateRect(handle, NIL, false);
   Paint;
  end
  else
  begin
   killTimer(handle, 999);
   InvalidateRect(handle, NIL, false);
   Paint;
   InvalidateRect(handle, NIL, false);
   BildPulsed1.free;
   BildPulsed1:= NIL;
   BildPulsed2.free;
   LastButtonStatus:= -1;

  end;

 end;
end;

procedure TPulseButton.NextPulse;
begin
 if PulseAb then
 begin
  dec( PulsePos, 2);
  if PulsePos < 1 then
  begin
   PulsePos:= 0;
   PulseAb:= false;
  end;
 end
 else
 begin
  inc( PulsePos, 2);
  if PulsePos > 30 then PulseAb:= true;
 end;
 InvalidateRect(handle, NIL, false);
 Paint;
end;

function TPulseButton.left: integer;
var
 p1: TPoint;
begin
 p1 := Point(0, 0);
 clientToScreen( getParent(handle), p1);
 result:= boundsrect.Left-p1.x;
end;

function TPulseButton.top: integer;
var
 p1: TPoint;
begin
 p1 := Point(0, 0);
 clientToScreen( getParent(handle), p1);
 result:= boundsrect.Top-p1.y;
end;

function TPulseButton.isAltDown: Boolean;
begin
 result:= getKeyState( VK_MENU	) < 0;
end;

{ TButtonGenerator }

constructor TButtonGenerator.create;
begin
 inherited;

 ButtonCount:= 1; // bei init der erste
 
 FontActive:= TFont.create;
 FontInActive:= TFont.create;
 ButtonPath:= Infos.mypath + 'ButtonAnimator\';

 BActive:= TBitmap.create;
 BClicked:= TBitmap.create;
 BDisabled:= TBitmap.create;
 BInactive:= TBitmap.create;
 BMouseOver:= TBitmap.create;
 BPulsed:= TBitmap.create;

 BActive.loadFromFile(ButtonPath + 'button_active.bmp');
 BClicked.loadFromFile(ButtonPath + 'button_clicked.bmp');
 BDisabled.loadFromFile(ButtonPath + 'button_disabled.bmp');
 BInactive.loadFromFile(ButtonPath + 'button_inactive.bmp');
 BMouseOver.loadFromFile(ButtonPath + 'button_mouseover.bmp');
 BPulsed.loadFromFile(ButtonPath + 'button_pulsed.bmp');

 readSettings;
end;

destructor TButtonGenerator.destroy;
begin
 FontActive.free;
 FontInActive.free;

 BActive.free;
 BClicked.free;
 BDisabled.free;
 BInactive.free;
 BMouseOver.free;
 BPulsed.free;
 inherited;
end;

procedure TButtonGenerator.generateButton(const bgStatus: integer; const altDown: Boolean; Caption: string; const Bild: TBitmap);

 function calc( r,r2,a: Byte): integer;
 begin
  if a= 0 then result:=r2
  else if a=255 then result:=r
  else
  result:= round( (r2*(255-a)/255)+(r*a/255) );
 end;

var
 Button: TBitmap;
 Rect1, Rect2: TRect;
 wdh, copyWidth: integer;
 myWidth, myHeight: integer;
 buttonWidth, buttonHeight: integer;
 MyRgn: HRGN;
 flags: integer;
begin
 Lock.Acquire;
 try
   case bgStatus of
    bgActive: Button:= BActive;
    bgMouseOver: Button:= BMouseOver;
    bgInactive: Button:= BInactive;
    bgDisabled: Button:= BDisabled;
    bgClicked: Button:= BClicked;
    bgPulsed: Button:= BPulsed;
   else
    Lock.Release;
    exit;
   end;
   //sourceFile:= buttonPath + s1 + '.bmp';

   //if fileExists( sourceFile) then
   begin

    SetStretchBltMode(Bild.Canvas.Handle, COLORONCOLOR);
    myWidth:= Bild.width;
    myheight:= Bild.Height;
    buttonWidth:= Button.Width;
    buttonHeight:= Button.Height;


    wdh:= FLeftBorder;
    copyWidth:= buttonWidth - FRightBorder - FLeftBorder;
    Rect2:= Rect(FLeftBorder, 0, buttonWidth-FRightBorder-FLeftBorder, buttonHeight);

    MyRgn := CreateRectRgn (0, 0, myWidth-FRightBorder, myHeight);
    SelectClipRgn(Bild.Canvas.Handle,MyRgn);

    repeat
     StretchBlt(Bild.Canvas.Handle, wdh, 0, CopyWidth, myHeight, Button.Canvas.Handle, Rect2.left, rect2.top, rect2.right, rect2.bottom, SRCCOPY);
     inc(wdh, copyWidth);
    until wdh > myWidth - FRightBorder;

    SelectClipRgn(Bild.Canvas.Handle, 0);
    deleteObject( MyRgn);

    StretchBlt(Bild.Canvas.Handle, 0, 0, FLeftBorder, myHeight, Button.Canvas.Handle, 0, 0, FLeftBorder, buttonHeight, SRCCOPY);
    StretchBlt(Bild.Canvas.Handle, myWidth - FRightBorder, 0, FRightBorder, myHeight, Button.Canvas.Handle, buttonWidth - FRightBorder, 0, FRightBorder, buttonHeight, SRCCOPY);


    if bgDisabled = bgStatus then Bild.Canvas.Font.Assign( FontInActive)
    else Bild.Canvas.Font.Assign( FontActive);

    with Bild.Canvas do
    begin
     Brush.Style := bsClear;
     if not altDown then
      for wdh:= length(Caption) downto 1 do
       if Caption[wdh]= '&' then delete(Caption, wdh, 1);

     if not altdown then flags:= DT_NOPREFIX
     else flags:= 0;


     if scaleDownFont then
     begin
      Rect1:= Rect(0, 0, myWidth-1, myHeight-1);
      repeat
      drawText(Bild.canvas.handle, pchar(caption), length(caption), Rect1, DT_CALCRECT or DT_SINGLELINE or DT_VCENTER or DT_CENTER or flags);
      if Rect1.right + ScaleDownFontWidth*2 >= myWidth then
      begin
       if Bild.Canvas.Font.Size < 6 then break
       else Bild.Canvas.Font.Size := Bild.Canvas.Font.Size -1;
      end;
      until Rect1.Right + ScaleDownFontWidth*2 < myWidth;
     end;
     Rect1:= Rect(0, 0, myWidth-1, myHeight-1);
     drawText(Bild.canvas.handle, pchar(caption), length(caption), Rect1, DT_SINGLELINE or DT_VCENTER or DT_CENTER or flags);
    end;

   end;
 except end;
 Lock.Release;
end;

function TButtonGenerator.getNeededSize(const Caption: string; const Bild: TBitmap): Integer;
begin
 Lock.Acquire;
 try
  Bild.Canvas.Font.Assign( FontActive);
  result:= Bild.Canvas.TextWidth( Caption);
 except end;
 Lock.Release;
end;

function TButtonGenerator.getTransparentColor(const Bild: TBitmap): TColor;
var
 x, y: integer;
begin
 Lock.Acquire;
 try
  if FTransparent then
   begin
    Bild.Transparent := false;
    x:= round((Bild.width-1) / 100 * FPTransparent.x);
    y:= round((Bild.height-1) / 100 * FPTransparent.y);
    result := Bild.Canvas.Pixels[x, y];
   end
   else Result:= $01000001;
 except end;
 Lock.Release;
end;

procedure TButtonGenerator.readSettings;
 procedure readFont(const Ini: TIniFile; const Sektion: string; const Font: TFont);
 begin
  Font.Name := Ini.ReadString(Sektion, 'name', Font.Name);
  Font.Size := Ini.ReadInteger(Sektion, 'size', Font.Size);
  Font.Color := Ini.ReadInteger(Sektion, 'color', Font.Color);

  Font.Style := [];
  if Ini.ReadBool(Sektion, 'bold', false) then Font.Style:= Font.Style + [fsBold];
  if Ini.ReadBool(Sektion, 'italic', false) then Font.Style:= Font.Style + [fsItalic];
 end;
var
 Ini: TIniFile;
begin
 Ini:= TIniFile.Create( ButtonPath + 'Settings.ini');

 FPTransparent.x := Ini.ReadInteger('def', 'transparentx', 0);
 FPTransparent.Y := Ini.ReadInteger('def', 'transparenty', 0);
 FTransparent:= Ini.ReadBool('def', 'transparent', false);

 MultiPulsing:= Ini.ReadBool('def', 'multipulsing', true);
 PulsingSpeed:= Ini.ReadInteger('def', 'pulsingspeed', 50);
 ScaleDownFontWidth := Ini.ReadInteger('def', 'scaledownfontwidth', 0);
 ScaleDownFont:= Ini.ReadBool('def', 'scaledownfont', false);
 FLeftBorder:= Ini.ReadInteger('def', 'leftborder', 15);
 FRightBorder:= Ini.ReadInteger('def', 'rightborder', 15);

 readFont(Ini, 'fontactive', FontActive);
 readFont(Ini, 'fontinactive', FontInActive);

 Ini.free;
end;

procedure TButtonGenerator.setTransparency(const Bild: TBitmap);
var
 x, y: integer;
begin
 if FTransparent then
  begin
   Bild.Transparent := false;
   x:= round((Bild.width-1) / 100 * FPTransparent.x);
   y:= round((Bild.height-1) / 100 * FPTransparent.y);
   Bild.Transparent := true;
   Bild.TransparentColor := Bild.Canvas.Pixels[x, y];
  end;
end;

end.
