unit MovingControlsUnit;

interface

uses Windows, Messages, Classes, SysUtils, IniFiles;

const
 mrNone   = -1;
 mrXY     =  0;
 mrWidth  =  1;
 mrHeight =  2;
 mrWidthAndHeight = 3;
 mrX      = 4;
 mrY      = 5;

type
 PMovingStruct = ^TMovingStruct;
 TMovingStruct = record
  sizingRegion: integer;
  xMod, yMod: integer;
 end;

 TMovingControl = class
 private
  procedure setMovingCursor(const movingRegion: integer);
  procedure initMovingStruct;
  procedure moveControl;
  procedure loadMCData;

 protected
  MCLoaded: Boolean;
  MovingStruct: PMovingStruct;
  BoundsRect: TRect;
  ClientRect: TRect;
  function Caption: string;
  procedure updateRects;
  function getMovingRegion( const x,y: integer): Integer;
 public
  handle: integer;
  constructor create;
  function MovingControlWndProc( const handle: dWord; const Msg: cardinal; const wParam, lParam: dWord): Boolean;
 end;

 TMC = class
 public
  caption: string;
  x,y,width,height: integer;
  constructor create;
  destructor destroy; override;
 end;


 TMovedControls = class
 private
  Liste: TList;
  function Get(Index: Integer): TMC;
  procedure Put(Index: Integer; const Value: TMC);
 public
  datei: string;
  function add: TMC; overload;
  procedure add( const Obj: TMC); overload;
  procedure delete( const index: integer);
  procedure clear;
  function count: integer;
  function indexOf( const Obj: TMC): integer;
  procedure insert( const index: integer; const Obj: TMC);
  procedure loadFromFile( const datei: string);
  procedure save;
  function getAddMovedControl( const caption: string): TMC;
  function getControl( const caption: string): TMC;

  constructor create;
  destructor destroy; override;
  property Items[Index: Integer]: TMC read Get write Put; default;
 end;

implementation

uses GlobalVarUnit;

{ TMC }

constructor TMC.create;
begin
 inherited;
end;

destructor TMC.destroy;
begin
 inherited;
end;



{ TMovedControls }

function TMovedControls.add: TMC;
begin
 result:= TMC.create;
 add( result);
end;

procedure TMovedControls.add(const Obj: TMC);
begin
 Liste.Add( Obj);
end;

procedure TMovedControls.clear;
var
 wdh: integer;
begin
 for wdh:= 0 to Liste.count-1 do
  TObject(Liste[wdh]).Free;
 Liste.Clear;
end;

function TMovedControls.count: integer;
begin
 result:= Liste.count;
end;

constructor TMovedControls.create;
begin
 inherited;
 Liste:= TList.create;
end;

procedure TMovedControls.delete(const index: integer);
begin
 Items[index].free;
 Liste.delete( index);
end;

destructor TMovedControls.destroy;
begin
 clear;
 Liste.free;
 inherited;
end;

function TMovedControls.Get(Index: Integer): TMC;
begin
 Result:= Liste[Index];
end;

function TMovedControls.getAddMovedControl(const caption: string): TMC;
var
 wdh: integer;
begin
 for wdh:= 0 to count-1 do
  if Items[wdh].caption = caption then
  begin
   result:= Items[wdh];
   exit;
  end;
 result:= add;
end;

function TMovedControls.getControl(const caption: string): TMC;
var
 wdh: integer;
begin
 for wdh:= 0 to count-1 do
  if Items[wdh].caption = caption then
  begin
   result:= Items[wdh];
   exit;
  end;
 result:= NIL;
end;

function TMovedControls.indexOf( const Obj: TMC): integer;
var
 wdh: integer;
begin
 for wdh:= 0 to count-1 do
  if Items[wdh] = Obj then
  begin
   result:= wdh;
   exit;
  end;
 result:= -1;
end;

procedure TMovedControls.insert( const index: integer; const Obj: TMC);
begin
 Liste.insert( index, Obj);
end;


procedure TMovedControls.loadFromFile(const datei: string);
var
 wdh: integer;
 Ini: TIniFile;
 s1: string;
 MC: TMC;
begin
 self.datei:= datei;
 clear;
 if fileExists( datei) then
 begin
  Ini:= TIniFile.create( datei);
  wdh:= 0;
  while Ini.SectionExists( intToStr(wdh)) do
  begin
   s1:= intToStr(wdh);
   MC:= add;
   MC.caption := Ini.ReadString(s1, 'caption', '');
   MC.x := Ini.ReadInteger(s1, 'x', -1);
   MC.y := Ini.ReadInteger(s1, 'y', -1);
   MC.width := Ini.ReadInteger(s1, 'width', -1);
   MC.height := Ini.ReadInteger(s1, 'height', -1);
   inc( wdh);
  end;
  Ini.free;
 end;
end;

procedure TMovedControls.Put(Index: Integer; const Value: TMC);
begin
 Liste[Index]:= Value;
end;


procedure TMovedControls.save;
var
 wdh: integer;
 Ini: TIniFile;
 s1: string;
begin
 forceDirectories( extractFilePath( datei));
 Ini:= TIniFile.create( datei);
 for wdh:= 0 to count-1 do
 begin
  s1:= intToStr(wdh);
  Ini.WriteString(s1, 'caption', Items[wdh].caption);
  Ini.WriteInteger(s1, 'x', Items[wdh].x);
  Ini.WriteInteger(s1, 'y', Items[wdh].y);
  Ini.WriteInteger(s1, 'width', Items[wdh].width);
  Ini.WriteInteger(s1, 'height', Items[wdh].height);
 end;
 Ini.free;
end;

{ TMovingControl }

function TMovingControl.getMovingRegion(const x, y: integer): Integer;
begin
 if (x > ClientRect.Right - 9) and (y > ClientRect.Bottom - 9) then result:= mrWidthAndHeight
 else if (y < ClientRect.bottom - 8) and (x > ClientRect.Right - 9) then result:= mrWidth
 else if (x < 9) then result:= mrX
 else if (x < ClientRect.Right - 8) and (y > ClientRect.Bottom - 9) then result:= mrHeight
 else if (x > 8) and (y < 9) then result:= mrY
 else result:= mrXY;
end;

procedure TMovingControl.setMovingCursor( const movingRegion: integer);
begin
 case movingRegion of
  mrX: setCursor( LoadCursor( 0, IDC_SIZEWE));
  mrY: setCursor( LoadCursor( 0, IDC_SIZENS));
  mrXY: setCursor( LoadCursor( 0, IDC_SIZEALL));
  mrWidth: setCursor( LoadCursor( 0, IDC_SIZEWE));
  mrHeight: setCursor( LoadCursor( 0, IDC_SIZENS));
  mrWidthAndHeight: setCursor( LoadCursor( 0, IDC_SIZENWSE));
 end;
end;

procedure TMovingControl.initMovingStruct;
var
 p1: TPoint;
begin
 p1:= Point( 0, 0);
 Windows.ClientToScreen( getParent( handle), p1);

 MovingStruct.xMod := MovingStruct.xMod + p1.X;
 MovingStruct.yMod := MovingStruct.yMod + p1.Y;
end;

procedure TMovingControl.moveControl;
var
 p1: TPoint;
 xMod, yMod: integer;
 MC: TMC;
begin
 getCursorPos( p1);
 xMod:= p1.x - MovingStruct.xMod;
 yMod:= p1.y - MovingStruct.yMod;
 updateRects;

 case MovingStruct.sizingRegion of
  mrX: begin
        p1:= Point(0, 0);
        Windows.ClientToScreen( getParent(handle), p1);
        setWindowPos( handle, 0, xMod, BoundsRect.top - p1.Y, ClientRect.Right - xMod + BoundsRect.left - p1.x, ClientRect.bottom, SWP_NOZORDER or SWP_NOACTIVATE);
       end;
  mrY: begin
        p1:= Point(0, 0);
        Windows.ClientToScreen( getParent(handle), p1);
        setWindowPos( handle, 0, BoundsRect.left - p1.x, yMod, ClientRect.Right, ClientRect.bottom - yMod + BoundsRect.top - p1.y, SWP_NOZORDER or SWP_NOACTIVATE);
       end;
  mrXY: setWindowPos( handle, 0, xMod, yMod, 0, 0, SWP_NOZORDER or SWP_NOSIZE);
  mrWidth: setWindowPos( handle, 0, 0, 0, p1.x - BoundsRect.Left, ClientRect.Bottom, SWP_NOZORDER or SWP_NOMOVE);
  mrHeight: setWindowPos( handle, 0, 0, 0, ClientRect.Right, p1.y - BoundsRect.top, SWP_NOZORDER or SWP_NOMOVE);
  mrWidthAndHeight: setWindowPos( handle, 0, 0, 0, p1.x - BoundsRect.Left, p1.y - BoundsRect.top, SWP_NOZORDER or SWP_NOMOVE);
 end;

 updateRects;
 p1:= Point(0, 0);
 Windows.ClientToScreen( getParent(handle), p1);
 MC:= MovedControls.getAddMovedControl( Caption);
 MC.caption := Caption;
 MC.x := BoundsRect.left - p1.x;
 MC.y := BoundsRect.top - p1.y;
 MC.width := ClientRect.Right;
 MC.height := ClientRect.Bottom;
 MovedControls.save;

end;

function TMovingControl.Caption: string;
var
 i1: integer;
begin
 i1:= sendMessage(handle, WM_GETTEXTLENGTH, 0, 0)+1 {fucking c uses #0 as terminator};
 setLength(result, i1);
 sendMessage(handle, WM_GETTEXT, i1, integer(pchar(result)));
 setLength(result, i1-1); // c!
end;

function TMovingControl.MovingControlWndProc(const handle: dWord;
  const Msg: cardinal; const wParam, lParam: dWord): Boolean;
begin
 result:= false;

 case Msg of
  WM_TIMER: begin
             if wParam = 901 then
             begin
              killTimer(handle, 901);
              InvalidateRect(handle, NIL, false);
              result:= true;
             end;
            end;
  WM_PAINT: begin
             if not MCLoaded and isWindowVisible( handle) then loadMCData;
            end;
  WM_MOUSEMOVE: begin
                 if MovingStruct <> NIL then
                 begin
                  moveControl;
                  setMovingCursor( MovingStruct.sizingRegion);
                  result:= true;
                 end
                 else if MK_SHIFT and wParam = MK_SHIFT then
                 begin
                  setMovingCursor( getMovingRegion( loWord( lParam), hiWord( lParam)));
                  result:= true;
                 end;
                end;
  WM_LBUTTONDOWN: begin
                   if MK_SHIFT and wParam = MK_SHIFT then
                   begin
                    new( MovingStruct);
                    MovingStruct.sizingRegion := getMovingRegion( loWord( lParam), hiWord( lParam));
                    MovingStruct.xMod := loWord( lParam);
                    MovingStruct.yMod := hiWord( lParam);
                    initMovingStruct;
                    setCapture( handle);
                    result:= true;
                   end;
                  end;
  WM_LBUTTONUP: begin
                 if MovingStruct <> NIL then
                 begin
                  dispose( MovingStruct);
                  MovingStruct:= NIL;
                  releaseCapture;
                  result:= true;
                 end;
                end;
 end;

end;

procedure TMovingControl.updateRects;
begin
 getWindowRect( handle, BoundsRect);
 ClientRect := Rect(0, 0, BoundsRect.right - BoundsRect.left, BoundsRect.bottom - BoundsRect.top);
end;

procedure TMovingControl.loadMCData;
var
 MC: TMC;
begin
 MCLoaded:= true;
 MC:= MovedControls.getControl( Caption);
 if MC <> NIL then
 begin
  setWindowPos(handle, 0, MC.x, MC.y, MC.width, MC.height, SWP_NOZORDER or SWP_NOACTIVATE);
  setTimer(handle, 901, 0, 0);
 end;
end;

constructor TMovingControl.create;
begin
 inherited;
end;

end.
