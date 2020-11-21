unit HaloUnit;

interface

uses Windows, Messages, GlobalVarUnit, Classes, SysUtils, Graphics, IniFiles, Math,
     MainFunc, MovingControlsUnit;

function isHalo( const p: pchar; const handle: integer): Boolean;
function haloWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; const objekt: pointer; var rueckgabe: dWord): Boolean;
procedure initHaloControl(const handle: integer);
procedure deInitHalo(const objekt: pointer);
function ShiningWindowProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam): lresult; stdcall;

const WM_DESTROYHALO = WM_USER + 100;

type

 THalo = class//(TMovingControl)
 private
  origWndProc: pointer;
  haloActive: Boolean;
  shiningHandle: integer;

  function dontDraw: Boolean;
  procedure createHalo;
  procedure destroyHalo;
  procedure reAlignHalo;
 public
  handle: integer;

  function haloWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; var rueckgabe: dWord): Boolean;
  function isVisible: Boolean;
  constructor create( const handle: integer; const origWndProc: pointer);
  destructor destroy; override;
 end;


implementation

function haloWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; const objekt: pointer; var rueckgabe: dWord): Boolean;
begin
 result:= THalo( Objekt).haloWndProc( handle, Msg, wParam, lParam, rueckgabe);
end;

procedure deInitHalo(const objekt: pointer);
begin // Braucht kein Lock wird bereits gelockt aufgerufen
 THalo( objekt).free;
end;

procedure initHaloControl(const handle: integer);
var
 HKT: PHookedControl;
begin
 Lock.Acquire;
 if getHKTIndex( handle) = -1 then // wir haben was zu tun
 begin
  new( HKT);
  HKT.handle := 0;
  HKT.typ := hktHalo;
  HKT.origWndFunction := pointer( getWindowLong(handle, GWL_WNDPROC));
  HKT.Objekt := THalo.create( handle, HKT.origWndFunction);
  HookedControls.add( HKT);
  setWindowLong( handle, GWL_WNDPROC, integer( @looksBetterWindowProc));
  HKT.handle := handle;
 end;
 Lock.release;
end;

function isHalo( const p: pchar; const handle: integer): Boolean;
begin
 result:= (p = 'msctls_hotkey32') or (p = 'Edit') or (p = 'TEdit');
end;

{ THalo }

constructor THalo.create(const handle: integer; const origWndProc: pointer);
begin
 inherited create;
 self.handle := handle;
 self.origWndProc := origWndProc;
end;

destructor THalo.destroy;
begin
 destroyHalo;
 inherited;
end;

function THalo.dontDraw: Boolean;
var
 p: pchar;
 i1: integer;
begin
 getMem(p, 20);
 getClassName( getParent( handle), p, 19);
 result:= pos('combobox', lowercase(p))>0;
 freeMem(p);

 if not result then
 begin
  i1:= getWindowLong(handle, GWL_STYLE);
  result:= ES_READONLY or i1 = i1;
 end;
end;

function THalo.haloWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; var rueckgabe: dWord): Boolean;
begin
 result:= false;
// if MovingControlWndProc( handle, Msg, wParam, lParam) then exit;

 case Msg of
  WM_WINDOWPOSCHANGING, WM_WINDOWPOSCHANGED: begin
                         Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                         reAlignHalo;
                        end;
  WM_SETFOCUS: begin createHalo; result:= true; end;
  WM_KILLFOCUS: begin postMessage(handle, WM_DESTROYHALO, 0, 0); result:= true; end;
  WM_DESTROYHALO: destroyHalo;

  WM_NCDESTROY: begin
                 Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                 deInitControl( handle);
                end;
 else
  result:= true;
 end;
end;


function THalo.isVisible: Boolean;
begin
 result:= isWindowVisible( handle);
end;

procedure THalo.reAlignHalo;
var
 p1: TPoint;
 r1: TRect;
begin
 getWindowRect(handle, r1);
 p1:= Point(0, 0);
 Windows.clientToScreen( getParent( handle), p1);

 setWindowPos( shiningHandle, handle, r1.Left-p1.x-8, r1.top-p1.Y-8, r1.Right-r1.left+15, r1.Bottom-r1.top+15, SWP_SHOWWINDOW or SWP_NOACTIVATE);
end;

procedure THalo.createHalo;
var
 myParent: integer;
begin
 if not haloActive and not dontDraw then
 begin
  haloActive:= true;

  myParent:= getParent(handle);
  shiningHandle := CreateWindowEx(WS_EX_TRANSPARENT, '#32770', '', WS_CHILDWINDOW or WS_DISABLED, 0, 0, 0, 0, myParent, 0, hInstance, nil);
  setWindowLong( shiningHandle, GWL_WNDPROC, integer(@ShiningWindowProc));
  reAlignHalo;
 end;
end;

procedure THalo.destroyHalo;
begin
 if haloActive then
 begin
  haloActive:= false;
  destroyWindow( shiningHandle);
  sendMessage( getParent( handle), WM_PAINT, 0, 0);
  sendMessage( handle, WM_PAINT, 0, 0);
 end;
end;

procedure drawTopShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for y:= 8 downto 0 do
 begin
  cmod:= y div 2;

  for x := CR.right-10 downto 9 do
  begin
   Co:= C.Pixels[x,y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x,y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawLeftShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for x := 8 downto 0 do
 begin
  cmod:= x div 2;

  for y:= CR.bottom-9 downto 9 do
  begin
   Co:= C.Pixels[x,y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x,y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawRightShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for x := CR.right-1 downto CR.right-9 do
 begin
  cmod:= (CR.right-x) div 2;

  for y:= CR.bottom-9 downto 9 do
  begin
   Co:= C.Pixels[x,y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x,y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawBottomShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for y:= CR.Bottom-2 downto CR.bottom-9 do
 begin
  cmod:= (CR.Bottom-y) div 2;

  for x := CR.right-10 downto 9 do
  begin
   Co:= C.Pixels[x,y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x,y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawTopLeftShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for y:= 8 downto 0 do
 begin


  for x := 8 downto 0 do
  begin
   cmod:= trunc((min(x,y)+1) / 2.1);
   Co:= C.Pixels[x, y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x, y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawTopRightShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for x := CR.right-1 downto CR.right-9 do
 begin
  for y:= 8 downto 0 do
  begin
   cmod:= trunc((min((CR.right-x),y)+1) / 2.1);
   Co:= C.Pixels[x, y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x, y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawBottomRightShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for x := CR.right-1 downto CR.right-9 do
 begin
  for y:= CR.Bottom-1 downto CR.bottom-8 do
  begin
   cmod:= trunc((min((CR.right-x),(CR.Bottom-y))+1) / 2.1);
   Co:= C.Pixels[x, y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x, y] := RGB(r, g, b);
  end;
 end;
end;

procedure drawBottomLeftShine( const C: TCanvas; const CR: TRect);
var
 x,y, cmod: integer;
 r, g, b: integer;
 Co: TColor;
begin
 for y:= CR.Bottom-1 downto CR.bottom-8 do
 begin


  for x := 8 downto 0 do
  begin
   cmod:= trunc((min(x,(CR.Bottom-y))+1) / 2.1);
   Co:= C.Pixels[x, y];
   r:= round( (getRValue( Co)*(9-cmod)/9) + (138*cmod/9));
   g:= round( (getGValue( Co)*(9-cmod)/9) + (189*cmod/9));
   b:= round( (getBValue( Co)*(9-cmod)/9) + (235*cmod/9) );
   C.Pixels[x, y] := RGB(r, g, b);
  end;
 end;
end;

procedure PaintShiningWindow(const handle: integer);
var
 C: TCanvas;
 CR: TRect;
 oldRgn, Rgn: hRgn;
begin
 Rgn:= createRectRgn(0,0,0,0);
 GetUpdateRgn(handle, Rgn, false);

 ValidateRect(handle, NIL);
 getWindowRect( handle, CR);
 CR:= Rect(0, 0, CR.right - CR.left, CR.bottom - CR.top);


 C:= TCanvas.create;
 C.handle := getWindowDC( handle);
 oldRgn:= SelectObject(C.Handle, Rgn);

 drawTopShine( C, CR);
 drawBottomShine( C, CR);
 drawLeftShine( C, CR);
 drawRightShine( C, CR);

 drawTopLeftShine( C, CR);
 drawTopRightShine( C, CR);
 drawBottomRightShine( C, CR);
 drawBottomLeftShine( C, CR);

 SelectObject( C.Handle, oldRgn);
 DeleteObject( Rgn);
 releaseDC(handle, C.Handle);
 C.Handle := 0;
 C.free;
end;

function ShiningWindowProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam): lresult; stdcall;
begin
 case uMsg of
  WM_PAINT: begin
             PaintShiningWindow( hWnd);
            end;
  WM_ERASEBKGND: begin result:= 1; end;
 else
  Result:= DefWindowProc( hWnd, uMsg, wParam, lParam);
 end;
end;

end.
