program VAnimConfig;

uses
  Forms,
  Windows,
  EinstellungenUnit in 'EinstellungenUnit.pas' {EinstellungenForm},
  UpdateButtonFormUnit in 'UpdateButtonFormUnit.pas' {UpdateButtonForm};

{$R *.res}

begin
 Application.Initialize;
 Application.CreateForm(TEinstellungenForm, EinstellungenForm);
 Application.Run;
end.
