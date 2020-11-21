unit ButtonGeneratorUnit;

interface

uses Windows, Messages, Classes, SysUtils, Graphics, IniFiles;

const
 bgActive    = 1;
 bgMouseOver = 2;
 bgInactive  = 3;
 bgDisabled  = 4;
 bgClicked   = 5;
 bgPulsed    = 6;

type
 TButtonGenerator = class
 private
  ButtonPath: string;
  FRightBorder: integer;
  FLeftBorder: integer;
  procedure SetLeftBorder(const Value: integer);
  procedure SetRightBorder(const Value: integer);
 public
  FontActive: TFont;
  FontInActive: TFont;
  procedure generateButton( const bgStatus: integer; Caption: string; const Bitmap: TBitmap);
  procedure readSettings;
  procedure writeSettings;

  constructor create;
  destructor destroy; override;

  property LeftBorder: integer read FLeftBorder write SetLeftBorder;
  property RightBorder: integer read FRightBorder write SetRightBorder;
 end;

implementation

{ TButtonGenerator }

constructor TButtonGenerator.create;
begin
 inherited;
 FontActive:= TFont.create;
 FontInActive:= TFont.create;
 ButtonPath:= extractFilePath( paramStr(0)) + 'ButtonGenerator\';
 forceDirectories( ButtonPath);
 readSettings;
end;

destructor TButtonGenerator.destroy;
begin
 FontActive.free;
 FontInActive.free;
 inherited;
end;

procedure TButtonGenerator.generateButton(const bgStatus: integer; Caption: string; const Bitmap: TBitmap);

 function calc( r,r2,a: Byte): integer;
 begin
  if a= 0 then result:=r2
  else if a=255 then result:=r
  else
  result:= round( (r2*(255-a)/255)+(r*a/255) );
 end;

var
 s1, sourceFile: string;
 Button, Mask, Mask2, Temp: TBitmap;
 Rect1, Rect2: TRect;
 wdh, copyWidth: integer;
 x,y: integer;
 PRGB1: ^TRGBTriple;
 PRGB2: ^TRGBTriple;
begin

 case bgStatus of
  bgActive: s1:= 'button_active';
  bgMouseOver: s1:= 'button_mouseover';
  bgInactive: s1:= 'button_inactive';
  bgDisabled: s1:= 'button_disabled';
  bgClicked: s1:= 'button_clicked';
  bgPulsed: s1:= 'button_pulsed';
 end;
 sourceFile:= buttonPath + s1 + '.bmp';

 if fileExists( sourceFile) then
 begin
  Temp:= TBitmap.create;
  Temp.PixelFormat := pf24Bit;
  Temp.Width := Bitmap.width;
  Temp.Height := Bitmap.height;

  Button:= TBitmap.create;
  Mask:= TBitmap.create;
  Button.loadFromFile( sourceFile);
  Mask.LoadFromFile( buttonPath + s1 + '_mask.bmp');

  Mask2:= TBitmap.create;
  Mask2.PixelFormat := Mask.PixelFormat;
  Mask2.Width := Temp.Width;
  Mask2.Height := Temp.Height;


  wdh:= FLeftBorder;
  copyWidth:= Button.Width - FRightBorder - FLeftBorder;
  Rect2:= Rect(FLeftBorder, 0, Button.width-FRightBorder, Button.Height);
  repeat
   Rect1:= Rect(wdh, 0, wdh+CopyWidth, Temp.Height);
   Temp.Canvas.CopyRect(Rect1, Button.Canvas, Rect2);
   Mask2.Canvas.CopyRect(Rect1, Mask.Canvas, Rect2);
   inc(wdh, copyWidth);
  until wdh > Temp.width - FRightBorder;

  Temp.Canvas.CopyRect(Rect(0, 0, FLeftBorder, Temp.Height), Button.Canvas, Rect(0, 0, FLeftBorder, Button.Height));
  Temp.Canvas.CopyRect(Rect(Temp.width - FRightBorder, 0, Temp.width, Temp.Height), Button.Canvas, Rect(Button.width - FRightBorder, 0, Button.width, Button.Height));

  Mask2.Canvas.CopyRect(Rect(0, 0, FLeftBorder, Temp.Height), Mask.Canvas, Rect(0, 0, FLeftBorder, Button.Height));
  Mask2.Canvas.CopyRect(Rect(Temp.width - FRightBorder, 0, Temp.width, Temp.Height), Mask.Canvas, Rect(Button.width - FRightBorder, 0, Button.width, Button.Height));
  Button.free;
  Mask.free;


  for y:= 0 to Bitmap.Height-1 do
  begin
   PRGB1:= Bitmap.ScanLine[y];
   PRGB2:= Temp.ScanLine[y];
   for x:=0 to Bitmap.width-1 do
   begin
    if Mask2.Canvas.Pixels[x,y] = clWhite then
    begin
     copyMemory(PRGB1, PRGB2, 3);
    end;
    inc( PRGB1);
    inc( PRGB2);
   end;

  end;

  Mask2.free;
  Temp.free;

  if bgDisabled = bgStatus then Bitmap.Canvas.Font.Assign( FontInActive)
  else Bitmap.Canvas.Font.Assign( FontActive);

  with Bitmap.Canvas do
  begin
   Brush.Style := bsClear;
   Rect1:= Rect(0, 0, Bitmap.width, Bitmap.height-1);
   for wdh:= length(Caption) downto 0 do
    if Caption[wdh]= '&' then delete(Caption, wdh, 1);
   TextOut( (Bitmap.width - Textwidth( Caption)) div 2, (Bitmap.Height - TextHeight( Caption)) div 2 -1, Caption);
   //drawText(Handle, pchar( Caption), length( Caption), Rect1, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;


 end;
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
 FLeftBorder:= Ini.ReadInteger('def', 'leftborder', 15);
 FRightBorder:= Ini.ReadInteger('def', 'rightborder', 15);

 readFont(Ini, 'fontactive', FontActive);
 readFont(Ini, 'fontinactive', FontInActive);

 Ini.free;
end;

procedure TButtonGenerator.SetLeftBorder(const Value: integer);
begin
  FLeftBorder := Value;
end;

procedure TButtonGenerator.SetRightBorder(const Value: integer);
begin
  FRightBorder := Value;
end;

procedure TButtonGenerator.writeSettings;
 procedure writeFont(const Ini: TIniFile; const Sektion: string; const Font: TFont);
 begin
  Ini.WriteString(Sektion, 'name', Font.Name);
  Ini.WriteInteger(Sektion, 'size', Font.Size);
  Ini.WriteInteger(Sektion, 'color', Font.Color);
  Ini.WriteBool(Sektion, 'bold', fsBold in Font.Style);
  Ini.WriteBool(Sektion, 'italic', fsItalic in Font.Style);
 end;
var
 Ini: TIniFile;
begin
 Ini:= TIniFile.Create( ButtonPath + 'Settings.ini');
 Ini.WriteInteger('def', 'leftborder', FLeftBorder);
 Ini.writeInteger('def', 'rightborder', FRightBorder);
 writeFont(Ini, 'fontactive', FontActive);
 writeFont(Ini, 'fontinactive', FontInActive);
 Ini.free;
end;

end.
