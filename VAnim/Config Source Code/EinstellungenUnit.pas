unit EinstellungenUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  XPMan, Dialogs, StdCtrls, ComCtrls, ExtCtrls, IniFiles, Spin,
  JvFullColorSpaces, JvFullColorCtrls, JvDialogs;

const
 WM_MYCREATE = WM_USER + 1;

type
  TEinstellungenForm = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    FontDialog1: TFontDialog;
    TabSheet2: TTabSheet;
    CheckBox1: TCheckBox;
    Button5: TButton;
    CheckBox2: TCheckBox;
    TabSheet3: TTabSheet;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    SpinEdit3: TSpinEdit;
    CheckBox5: TCheckBox;
    Label7: TLabel;
    SpinEdit4: TSpinEdit;
    TabSheet5: TTabSheet;
    ListBox1: TListBox;
    Label11: TLabel;
    Button7: TButton;
    Button8: TButton;
    Label12: TLabel;
    TabSheet6: TTabSheet;
    CheckBox7: TCheckBox;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label3: TLabel;
    Shape1: TShape;
    JvColorDialog1: TJvColorDialog;
    Label6: TLabel;
    Label8: TLabel;
    Button6: TButton;
    Button9: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure CheckBox7Click(Sender: TObject);
    procedure TabSheet6Show(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private-Deklarationen }
    ProgressBar: TProgressBar;
    DemoEdit1, DemoEdit2: TEdit;
    procedure getWindowsButtonPicture( const bgStatus: integer; const Bild: TBitmap);
    procedure setFontProperties(const Font: TFont);
    procedure loadSettings;
    procedure save;
    procedure WMMYCREATE( var Message: TMessage); message WM_MYCREATE;
  public
    { Public-Deklarationen }
    DLLHandle: integer;
    FontActive, FontInActive: TFont;
    procedure animateControl( const handle: integer);
    procedure deAnimateControl( const handle: integer);

  end;

var
  EinstellungenForm: TEinstellungenForm;

implementation

uses ButtonGeneratorUnit, UpdateButtonFormUnit, CommDlg, MainFunc;

{$R *.dfm}


procedure TEinstellungenForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 freeAndNIL( DemoEdit1);
 freeAndNIL( DemoEdit2);
 freeAndNIL( ProgressBar);
 FontActive.free;
 FontInActive.free;
 Action:= caFree;
 freeLibrary( DLLHandle);
 EinstellungenForm:= NIL;
end;

procedure TEinstellungenForm.FormCreate(Sender: TObject);
begin
 DLLHandle:= loadLibrary('VAnimHook.dll');
 PageControl1.ActivePageIndex := 0;
 FontActive:= TFont.create;
 FontInActive:= TFont.create;
 postMessage(handle, WM_MYCREATE, 0, 0);
 left:= -999;
end;

procedure TEinstellungenForm.getWindowsButtonPicture(
  const bgStatus: integer; const Bild: TBitmap);

  function getDiff( const b1, b2: byte): byte;
  begin
   if b1 > b2 then result:= b1-b2
   else result := b2-b1;
  end;

  function limitbyte( const i1: integer): byte;
  begin
   if i1 < 0 then result:= 0
   else if i1 > 255 then result:= 255
   else result:= i1;
  end;

var
 BTemp: TBitmap;
 dc: HDC;
 x,y: integer;
 PRGB1: ^TRGBTriple;
begin
 Application.CreateForm(TUpdateButtonForm, UpdateButtonForm);
 Application.ProcessMessages;
 with UpdateButtonForm do
 begin

   case bgStatus of
    bgActive, bgMouseOver, bgPulsed: begin
               setActiveWindow( UpdateButtonForm.handle);
               UpdateButtonForm.SetFocus;
               UpdateButtonForm.ActiveControl := UpdateButton;
               UpdateButton.Default:= true;
               UpdateButton.SetFocus;
               postMessage(UpdateButton.Handle, WM_LBUTTONDOWN, 0, 0);
               postMessage(UpdateButton.Handle, WM_LBUTTONUP, 0, 0);
              end;
    bgInactive: UpdateButtonForm.ActiveControl := Button1;
    bgDisabled: UpdateButton.Enabled:= false;
    bgClicked: sendMessage(UpdateButton.Handle, WM_LBUTTONDOWN, 0, 0);
   end;

  // UpdateButtonForm.Color := clBtnF;
   Application.ProcessMessages;

   BTemp:= TBitmap.create;
   BTemp.PixelFormat := pf24Bit;
   BTemp.Width := UpdateButton.Width;
   BTemp.Height := UpdateButton.Height;
   dc:= getDC( UpdateButton.Handle);
   bitBlt(BTemp.Canvas.Handle, 0, 0, BTemp.width, BTemp.height, dc, 0, 0, SRCCOPY);
   releaseDC( UpdateButton.Handle, dc);
   Bild.Assign( BTemp);

   if bgPulsed = bgStatus then
   begin
    for y:= 0 to Bild.height-1 do
    begin
     PRGB1:= Bild.ScanLine[y];
     for x:= 0 to Bild.width-1 do
     begin
      pRGB1.rgbtRed := limitByte( integer( pRGB1.rgbtRed)-70);
      pRGB1.rgbtGreen := limitbyte( integer(pRGB1.rgbtGreen)-70);
      pRGB1.rgbtBlue := limitbyte( integer(pRGB1.rgbtBlue)-70);
      inc( PRGB1);
     end;
    end;
   end;

   BTemp.free;

 end;
 UpdateButtonForm.close;
end;

procedure TEinstellungenForm.Button2Click(Sender: TObject);
var
 Bi1: TBitmap;
 wdh: integer;
 s1, path: string;

 function calc( r,r2,a: integer): integer;
 begin
  if a>255 then a:=255;
  if a= 0 then result:=r2
  else if a=255 then result:=r
  else
  result:= round( (r2*(255-a)/255)+(r*a/255) );
 end;

begin
 if MessageBox(handle, 'This function replaces the VAnim©®® - Buttonimages with the ones currently used in your Windows(Style).'#13'If you changed something on the VAnim©®®©®® - Buttonimages, the changes will be overwritten!'#13#13'Continue anyway?', 'Warning', MB_ICONSTOP or MB_YESNO) = ID_NO then exit;

 path:= extractFilePath( paramStr(0)) + 'ButtonAnimator\';
 forceDirectories( path);

 Bi1:= TBitmap.create;
 for wdh:= 1 to 6 do
 begin
  getWindowsButtonPicture(wdh, Bi1);
  case wdh of
   bgActive: s1:= 'button_active';
   bgMouseOver: s1:= 'button_mouseover';
   bgInactive: s1:= 'button_inactive';
   bgDisabled: s1:= 'button_disabled';
   bgClicked: s1:= 'button_clicked';
   bgPulsed: s1:= 'button_pulsed';
  end;
  Bi1.SaveToFile(path+s1+'.bmp');
 end;
 Bi1.free;
end;

procedure TEinstellungenForm.Button1Click(Sender: TObject);
begin
 close;
end;

procedure TEinstellungenForm.Button4Click(Sender: TObject);
begin
 setFontProperties( FontInActive);
end;

procedure TEinstellungenForm.setFontProperties( const Font: TFont);
begin
 FontDialog1.Font.Assign( Font);
 if FontDialog1.Execute then
 begin
  Font.Assign( FontDialog1.Font);
 end;
end;

procedure TEinstellungenForm.CheckBox2Click(Sender: TObject);
begin
 ProgressBar.free;
 ProgressBar := TProgressBar.create( self);
 ProgressBar.Parent := TabSheet2;
 ProgressBar.BoundsRect := Label3.BoundsRect;
 ProgressBar.Position := 50;
 if CheckBox2.checked then animateControl( ProgressBar.Handle );

 ProgressBar.show;
 ProgressBar.Invalidate;
end;

procedure TEinstellungenForm.CheckBox1Click(Sender: TObject);
var
 wdh: integer;
begin
 for wdh:= 0 to ComponentCount-1 do
  if TWinCOntrol(Components[wdh]).Parent = TabSheet1 then
  begin
   if Components[wdh] <> Sender then TWinControl(Components[wdh]).Enabled:= TCheckBox(sender).Checked;
  end;
end;

procedure TEinstellungenForm.loadSettings;
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
 Ini:= TIniFile.create( extractFilePath( paramStr(0)) + 'settings.ini');
 CheckBox1.Checked := Ini.ReadBool('active', 'buttonpulser', false);
 CheckBox2.Checked := Ini.ReadBool('active', 'progressbaranimator', false);
 CheckBox7.Checked := Ini.ReadBool('active', 'haloeffects', false);
 if not CheckBox1.checked then CheckBox1Click( CheckBox1);
 if not CheckBox2.checked then CheckBox2Click( CheckBox2);
 ListBox1.clear;
 vGetThatInSepsList( Ini.ReadString('exclusions', 'processnames', ''), ListBox1.Items);

 Ini.free;

 Ini:= TIniFile.create( extractFilePath( paramStr(0)) + 'buttonanimator\settings.ini');
 SpinEdit1.Value := Ini.ReadInteger('def', 'transparentx', 0);
 SpinEdit2.Value := Ini.ReadInteger('def', 'transparenty', 0);
 CheckBox3.Checked := Ini.ReadBool('def', 'transparent', false);
 CheckBox4.Checked := Ini.ReadBool('def', 'scaledownfont', false);
 SpinEdit3.Value := Ini.ReadInteger('def', 'scaledownfontwidth', 0);
 CheckBox5.Checked := Ini.ReadBool('def', 'multipulsing', true);
 SpinEdit4.Value := Ini.ReadInteger('def', 'pulsespeed', 50);
 readFont(Ini, 'fontactive', FontActive);
 readFont(Ini, 'fontinactive', FontInActive);
 Ini.free;
end;

procedure TEinstellungenForm.save;
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
 Ini:= TIniFile.create( extractFilePath( paramStr(0)) + 'settings.ini');
 Ini.WriteBool('active', 'buttonpulser', CheckBox1.Checked);
 Ini.WriteBool('active', 'progressbaranimator', CheckBox2.Checked);
 Ini.WriteBool('active', 'haloeffects', CheckBox7.Checked);
 Ini.writeString('exclusions', 'processnames', vGetInSeps( ListBox1.Items));

 Ini.free;

 Ini:= TIniFile.create( extractFilePath( paramStr(0)) + 'buttonanimator\settings.ini');
 Ini.WriteInteger('def', 'transparentx', SpinEdit1.Value);
 Ini.WriteInteger('def', 'transparenty', SpinEdit2.Value);
 Ini.WriteBool('def', 'transparent', CheckBox3.Checked);
 Ini.WriteBool('def', 'scaledownfont', CheckBox4.Checked);
 Ini.WriteInteger('def', 'scaledownfontwidth', SpinEdit3.Value);
 Ini.WriteBool('def', 'multipulsing', CheckBox5.Checked);
 Ini.WriteInteger('def', 'pulsespeed', SpinEdit4.Value);
 writeFont(Ini, 'fontactive', FontActive);
 writeFont(Ini, 'fontinactive', FontInActive);
 Ini.free;

end;

procedure TEinstellungenForm.Button5Click(Sender: TObject);
begin
 save;
 close;
end;

procedure TEinstellungenForm.WMMYCREATE(var Message: TMessage);
begin
 ClientWidth:= PageControl1.Width + PageControl1.left*2;
 ClientHeight:= Button5.top + Button5.height + PageControl1.Top div 2;
 loadSettings;
 top := (Screen.height - height) div 2;
 left := (Screen.width - width) div 2;
 PageControl1.ActivePageIndex := 0;
end;

procedure TEinstellungenForm.Button3Click(Sender: TObject);
begin
 setFontProperties( FontActive);
end;

procedure TEinstellungenForm.Button6Click(Sender: TObject);
begin
 JvColorDialog1.Color := FontActive.Color;
 if JvColorDialog1.Execute then FontActive.Color := JvColorDialog1.Color;
end;

procedure TEinstellungenForm.Button7Click(Sender: TObject);
var
 s1: string;
begin
 if InputQuery('Settings', 'Please enter the Name of the application, example: explorer.exe', s1) then
 begin
  ListBox1.Items.Add(s1);
 end;
end;

procedure TEinstellungenForm.Button8Click(Sender: TObject);
begin
 if ListBox1.ItemIndex = -1 then showMessage('Please select the Application, you want to delete')
 else
 begin
  ListBox1.Items.Delete( ListBox1.ItemIndex);
 end;
end;

procedure TEinstellungenForm.animateControl(const handle: integer);
type
 TFunc = procedure(const handle: integer); stdcall;
var
 Func: TFunc;
begin
 if DLLHandle = 0 then exit;
 @Func:= getProcAddress(DLLHandle, 'animateControl');
 Func( Handle);
end;

procedure TEinstellungenForm.deAnimateControl(const handle: integer);
type
 TFunc = procedure(const handle: integer); stdcall;
var
 Func: TFunc;
begin
 if DLLHandle = 0 then exit;
 @Func:= getProcAddress(DLLHandle, 'deAnimateControl');
 Func( Handle);
end;

procedure TEinstellungenForm.CheckBox7Click(Sender: TObject);
begin
 if CheckBox7.checked then
 begin
  DemoEdit1 := TEdit.create( self);
  DemoEdit1.Parent := Edit2.Parent;
  DemoEdit1.BoundsRect := Edit2.BoundsRect;
  DemoEdit1.Text := Edit2.Text;
  DemoEdit1.show;
  animateControl( DemoEdit1.Handle);
  DemoEdit2 := TEdit.create( self);
  DemoEdit2.Parent := Edit3.Parent;
  DemoEdit2.BoundsRect := Edit3.BoundsRect;
  DemoEdit2.Text := Edit3.Text;
  DemoEdit2.show;
  animateControl( DemoEdit2.Handle);

  if DemoEdit1.visible then
  if TabSheet6.TabIndex = PageControl1.ActivePageIndex then FocusControl( DemoEdit1);
 end
 else
 begin
  freeAndNIL( DemoEdit1);
  freeAndNIL( DemoEdit2);
 end;
end;

procedure TEinstellungenForm.TabSheet6Show(Sender: TObject);
begin
 if CheckBox7.checked then FocusControl( DemoEdit1);
end;

procedure TEinstellungenForm.Button9Click(Sender: TObject);
begin
 JvColorDialog1.Color := FontInActive.Color;
 if JvColorDialog1.Execute then FontInActive.Color := JvColorDialog1.Color;
end;

end.
