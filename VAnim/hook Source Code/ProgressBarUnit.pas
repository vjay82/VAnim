unit ProgressBarUnit;

interface

uses Windows, Messages, GlobalVarUnit, Classes, SysUtils, Graphics, IniFiles, Math,
     MainFunc, commctrl;

const
 pgVertical = 0;
 pgFloating = 1;

function isProgressbar( const p: pchar; const handle: integer): Boolean;
function progressbarWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; const objekt: pointer; var rueckgabe: dWord): Boolean;
procedure initProgressBarControl(const handle: integer);
procedure deInitProgressBar(const objekt: pointer);

type
 TProgressBarGenerator = class
 private
  BActivePart: TBitmap;
  BInActivePart: TBitmap;
  BSpacerBetweenParts: TBitmap;
 public
  ProgressBarCount: integer;
  procedure generateProgressBar( const Style, Promille, xMod: integer; const Bild: TBitmap);
  constructor create;
  destructor destroy; override;
 end;

 TProgressBar = class
 private
  BoundsRect: TRect;
  ClientRect: TRect;
  LastPaintSize: TPoint;
  origWndProc: pointer;
  xMod: integer;

  procedure Paint;
  procedure updateRects;
  procedure resetPictures;
 public
  Bild: TBitmap;
  handle: integer;

  function progressBarWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; var rueckgabe: dWord): Boolean;
  function isVisible: Boolean;
  constructor create( const handle: integer; const origWndProc: pointer);
  destructor destroy; override;
 end;

var
 ProgressBarGenerator: TProgressBarGenerator = NIL;

implementation

function progressbarWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; const objekt: pointer; var rueckgabe: dWord): Boolean;
begin
 result:= TProgressBar( Objekt).progressBarWndProc( handle, Msg, wParam, lParam, rueckgabe);
end;

procedure deInitProgressBar(const objekt: pointer);
begin // Braucht kein Lock wird bereits gelockt aufgerufen
 if ProgressBarGenerator <> NIL then
 begin
  ProgressBarGenerator.ProgressBarCount := ProgressBarGenerator.ProgressBarCount-1;
  if ProgressBarGenerator.ProgressBarCount = 0 then
  begin
   freeAndNIL( ProgressBarGenerator);
  end;
 end;
 TProgressBar( objekt).free;
end;

procedure initProgressBarControl(const handle: integer);
var
 HKT: PHookedControl;
begin
 Lock.Acquire;
 if getHKTIndex( handle) = -1 then // wir haben was zu tun
 begin
  if ProgressBarGenerator = NIL then ProgressBarGenerator:= TProgressBarGenerator.create
  else ProgressBarGenerator.ProgressBarCount := ProgressBarGenerator.ProgressBarCount+1;

  new( HKT);
  HKT.handle := 0;
  HKT.typ := hktProgressBar;
  HKT.origWndFunction := pointer( getWindowLong(handle, GWL_WNDPROC));
  HKT.Objekt := TProgressBar.create( handle, HKT.origWndFunction);
  HookedControls.add( HKT);
  setWindowLong( handle, GWL_WNDPROC, integer( @looksBetterWindowProc));
  HKT.handle := handle;
 end;
 Lock.release;
end;

function isProgressbar( const p: pchar; const handle: integer): Boolean;
begin
 result:= (p = 'ProgressBar') or (p = 'TProgressBar') or (p = 'msctls_progress32');
end;

{ TProgressBar }

constructor TProgressBar.create(const handle: integer; const origWndProc: pointer);
begin
 inherited create;
 self.handle := handle;
 self.origWndProc := origWndProc;

 Bild:= TBitmap.create;
 Bild.PixelFormat := pf24Bit;
 setTimer(handle, 999, 50, NIL);
end;

destructor TProgressBar.destroy;
begin
 Bild.free;
 inherited;
end;

procedure TProgressBar.updateRects;
begin
 getWindowRect( handle, BoundsRect);
 ClientRect:= BoundsRect;

 ClientRect.right:= ClientRect.right - ClientRect.left;
 ClientRect.bottom := ClientRect.bottom - ClientRect.top;
 ClientRect.left:= 0;
 ClientRect.top:= 0;
end;

procedure TProgressBar.resetPictures;
begin
 Bild.Width := ClientRect.Right;
 Bild.Height := ClientRect.Bottom;
end;

procedure TProgressBar.Paint;
var
 C: TCanvas;
 Caption: string;
 r1: Trect;
 PR: PBRange;
 i1, i2: integer;
begin
 updateRects;
 ValidateRect(handle, NIL);

 C:= TCanvas.create;
 C.handle := getWindowDC( handle);

 if (LastPaintSize.X <> ClientRect.right) or
    (LastPaintSize.Y <> ClientRect.bottom) then
 begin
  LastPaintSize:= ClientRect.BottomRight;
  self.resetPictures;
//  lastPercent := -1;
 end;
                                                  
 CallWindowProc( origWndProc, handle, PBM_GETRANGE, 0, integer(@PR));
 i1:= CallWindowProc( origWndProc, handle, PBM_GETPOS, 0, 0) - PR.iLow;

 i2:= PR.iHigh - PR.iLow;
 if i2 <= 0 then i2:= 1;
 if i1 < 0 then i1:= 0;
 if i1 > i2 then i1:= i2;

 ProgressBarGenerator.generateProgressbar( getWindowLong( handle, GWL_STYLE), round(1000 / i2 * i1), xMod, Bild);

 C.Draw(0, 0, Bild);
 releaseDC( handle, C.Handle);
 C.Handle:= 0;
 C.free;
end;

function TProgressBar.progressBarWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord; var rueckgabe: dWord): Boolean;
begin
 result:= false;
  try
   case Msg of
    WM_ERASEBKGND: Rueckgabe:= 1;
    WM_PAINT: begin
               if WParam = 0 then Paint
               else result:= true;
              end;
    WM_NCPAINT: Paint;
    WM_TIMER: begin
               if wParam = 999 then
               begin
                inc( XMod);
                if XMod > ProgressBarGenerator.BActivePart.width then XMod:= 0;
                InvalidateRect(handle, NIL, false);
               end
               else result:= true;
              end;
    WM_NCDESTROY: begin
                   Rueckgabe := CallWindowProc( origWndProc, handle, Msg, wParam, lParam);
                   deInitControl( handle);
                  end;
   else
    result:= true;
   end;
 except end;
end;

function TProgressBar.isVisible: Boolean;
begin
 result:= isWindowVisible( handle);
end;

{ TProgressBarGenerator }

constructor TProgressBarGenerator.create;
var
 Path: string;
begin
 inherited;
 Path:= Infos.mypath + 'ProgressBarAnimator\';
 BActivePart:= TBitmap.create;
 BInActivePart:= TBitmap.create;
 BSpacerBetweenParts:= TBitmap.create;

 BActivePart.LoadFromFile(Path + 'activePart.bmp');
 BInActivePart.LoadFromFile(Path + 'inActivePart.bmp');
 BSpacerBetweenParts.LoadFromFile(Path + 'SpacerBetweenParts.bmp');

 ProgressBarCount:= 1;
end;

destructor TProgressBarGenerator.destroy;
begin
 BActivePart.free;
 BInActivePart.free;
 BSpacerBetweenParts.free;
 inherited;
end;


procedure Rotate90Degrees(Bitmap: TBitmap);
type
  THelpRGB = packed record
    rgb: TRGBTriple;
    dummy: byte;
  end;

  TRGBArray = Array[0..0] of TRGBTriple;
  pRGBArray = ^TRGBArray;
var
  aStream: TMemorystream;
  header: TBITMAPINFO;
  dc: hDC;
  P: ^THelpRGB;
  x, y, b, h: Integer;
  RowOut:  pRGBArray;
begin
  aStream := TMemoryStream.Create;
  aStream.SetSize(Bitmap.Height * Bitmap.Width * 4);
  with header.bmiHeader do
  begin
    biSize := SizeOf(TBITMAPINFOHEADER);
    biWidth := Bitmap.Width;
    biHeight := Bitmap.Height;
    biPlanes := 1;
    biBitCount := 32;
    biCompression := 0;
    biSizeimage := aStream.Size;
    biXPelsPerMeter :=1;
    biYPelsPerMeter :=1;
    biClrUsed :=0;
    biClrImportant :=0;
  end;
  dc := GetDC(0);
  P := aStream.Memory;
  GetDIBits(dc, Bitmap.Handle, 0, Bitmap.Height, P, header, dib_RGB_Colors);
  ReleaseDC(0, dc);
  b := bitmap.Height;  {rotate}
  h := bitmap.Width;  {rotate}
  bitmap.Width := b;
  bitmap.height := h;
  for y := 0 to (h - 1) do
  begin
    rowOut := Bitmap.ScanLine[y];
    P := aStream.Memory;  {reset pointer}
    inc(p, y);
    for x := 0 to (b - 1) do
    begin
      rowout[x] := p^.rgb;
      inc(p, h);
    end;
  end;
  aStream.Free;
end;



procedure TProgressBarGenerator.generateProgressBar( const Style, promille, xMod: integer; const Bild: TBitmap);
var
 x: integer;
 myHeight: integer;
 activeWidth: integer;
begin
 Lock.Acquire;
 try
   if ( Style or PBS_VERTICAL = Style) then
   begin
    x:= Bild.width;
    Bild.width:= Bild.height;
    Bild.Height := x;
   end;
   if ( Style or 8 = Style){MARQUEE} then activeWidth:= Bild.Width
   else activeWidth:= round( Bild.width * promille / 1000);

   SetStretchBltMode(Bild.Canvas.Handle, COLORONCOLOR);

   begin
     myheight:= Bild.height ;// BBottomShadow.height - 1;
     x:= 0- XMod;             
     repeat
      StretchBlt(Bild.Canvas.handle, x, 0, BActivePart.width, myHeight, BActivePart.Canvas.handle, 0, 0, BActivepart.Width, BActivePart.Height, SRCCOPY);
      inc(x, BActivePart.width);
     until x >= activeWidth;

     x:= activeWidth;
     StretchBlt(Bild.Canvas.Handle, x, 0, BSpacerBetweenParts.width, myHeight, BSpacerBetweenParts.Canvas.Handle, 0, 0, BSpacerBetweenParts.Width, BSpacerBetweenParts.Height, SRCCOPY);

     inc( x, BSpacerBetweenParts.width);
     repeat
      StretchBlt(Bild.Canvas.Handle, x, 0, BInActivePart.width, myHeight, BInActivePart.Canvas.handle, 0, 0, BInActivePart.Width, BInActivePart.Height, SRCCOPY);
      inc(x, BInActivePart.width);
     until x >= Bild.Width;
   end;

   if ( Style or PBS_VERTICAL = Style) then
   begin
    // we are Lazy here even if it costs more cpu
    // vertical scrollbars arent used very often
    Rotate90Degrees( Bild);
    StretchBlt(Bild.Canvas.handle, 0, 0, Bild.width, Bild.height, Bild.Canvas.handle, 0, Bild.height-1, Bild.width, Bild.height*-1, SRCCOPY);
   end;
 except end;
 Lock.Release;  
end;



end.
