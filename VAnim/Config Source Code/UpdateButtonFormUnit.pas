unit UpdateButtonFormUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TUpdateButtonForm = class(TForm)
    UpdateButton: TButton;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  UpdateButtonForm: TUpdateButtonForm;

implementation

{$R *.dfm}

procedure TUpdateButtonForm.FormCreate(Sender: TObject);
begin
 show;
end;

procedure TUpdateButtonForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 Action:= caFree;
end;

end.
