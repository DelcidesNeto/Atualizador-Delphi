program Atualizar;

uses
  Vcl.Forms,
  TelaInicial in 'TelaInicial.pas' {frmTelaInicial},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Cyan Dusk');
  Application.CreateForm(TfrmTelaInicial, frmTelaInicial);
  Application.Run;
end.
