unit TelaInicial;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, IdHTTP, IdSSLOpenSSL, RESTRequest4D, JSON, System.Threading, System.IOUtils;

type
  TfrmTelaInicial = class(TForm)
    Atualizar: TButton;
    ProgressBar: TProgressBar;
    LabelStatus: TLabel;
    procedure FormDestroy(Sender: TObject);
    procedure AtualizarClick(Sender: TObject);
  private
    { Private declarations }
    function AtualizarDelphi(AUrl, ACaminho: String): Boolean;
    function GetLinkDownload: String;
    function MoverExecutavel(ACaminhoOrigem, ANovoCaminho: String): Boolean;
    function DeletarDiretorio(ACaminho: String): Boolean;
  public
    { Public declarations }
  end;

var
  frmTelaInicial: TfrmTelaInicial;

implementation

{$R *.dfm}

procedure TfrmTelaInicial.FormDestroy(Sender: TObject);
begin
  frmTelaInicial := nil;
end;

procedure TfrmTelaInicial.AtualizarClick(Sender: TObject);
var
  Link: String;
  Caminho: String;
  Atualizou: Boolean;
begin
  TTask.Run(procedure
  begin
    TThread.Synchronize(nil,
    procedure
    begin
      LabelStatus.Left := 120;
      LabelStatus.Caption := 'Obtendo link de Download...';
    end);
    Link := GetLinkDownload;
    if not TDirectory.Exists(ExtractFilePath(Application.ExeName)+'Updates') then
      TDirectory.CreateDirectory(ExtractFilePath(Application.ExeName)+'Updates');
    Caminho := ExtractFilePath(Application.ExeName)+'Updates/NSCobran�as.exe';

    if Link <> '' then
      begin
        TThread.Synchronize(nil,
        procedure
        begin
          LabelStatus.Left := 8;
          LabelStatus.Caption := 'Link obtido com sucesso, iniciando o download...';
          ProgressBar.Visible := True;
        end);
        Atualizou := AtualizarDelphi(Link, Caminho);
        if Atualizou then
          begin
            TThread.Synchronize(nil,
            procedure
            begin
              ProgressBar.Visible := False;
              LabelStatus.Left := 72;
              LabelStatus.Caption := 'Atualiza��o conclu�da com Sucesso!';
            end);
          end
        else
          begin
            TThread.Synchronize(nil,
            procedure
            begin
              ProgressBar.Visible := False;
              LabelStatus.Left := 72;
              LabelStatus.Caption := 'N�o foi poss�vel concluir a atualiza��o!';
            end);
          end;
      end
    else
      begin
        TThread.Synchronize(nil, procedure begin ShowMessage('Houve um erro ao obter o link de download!'); end);
      end;
  end);
end;

function TfrmTelaInicial.AtualizarDelphi(AUrl, ACaminho: String): Boolean; //T� deletando, mas n�o t� movendo o novo execut�vel
var
  HTTP: TIdHTTP;
  ArquivoExe: TFileStream;
  Ssl: TIdSSLIOHandlerSocketOpenSSL;
begin
  Result := False;
  HTTP := TIdHTTP.Create(nil);
  HTTP.Request.UserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
  HTTP.HandleRedirects := True;
  Ssl := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Ssl.SSLOptions.Method := sslvTLSv1_2;  // For�a o uso do TLS 1.2
  HTTP.IOHandler := Ssl;
  ArquivoExe := TFileStream.Create(ACaminho, fmCreate);
  try
    try
      HTTP.Get(AUrl, ArquivoExe); // Faz o download do arquivo
      Result := True;
    except
      on E: Exception do
        begin
          if Assigned(frmTelaInicial) then
            begin
              DeleteFile(ACaminho);
              DeletarDiretorio(ExtractFilePath(Application.ExeName)+'Updates');
              TThread.Synchronize(nil, procedure begin ShowMessage('Erro ao fazer o download: ' + E.Message); end);
            end;
        end;
    end;
  finally
    ArquivoExe.Free;
    HTTP.Free;
    Ssl.Free;
    if Result then
      begin
        DeleteFile(ExtractFilePath(Application.ExeName)+'NSCobran�as.exe');
        MoverExecutavel(ACaminho, ExtractFilePath(Application.ExeName)+'NSCobran�as.exe');
      end;
  end;
end;

function TfrmTelaInicial.DeletarDiretorio(ACaminho: String): Boolean;
begin
  TDirectory.Delete(ACaminho);
end;

function TfrmTelaInicial.GetLinkDownload: String;
var
  Rest4: IResponse;
  Response: TJSONObject;
  Link: String;
begin
  try
    try
      Rest4 := TRequest.New.BaseURL('https://neto.pythonanywhere.com/UpdateDelphi')
      .Get;
      Response := TJSONObject.ParseJSONValue(Rest4.Content) as TJSONObject;
      Link := Response.GetValue<String>('download');
      Result := Link;
    except
      on E: Exception do
        begin
          TThread.Synchronize(nil, procedure begin ShowMessage('Erro ao obter link: '+E.Message); end);
        end;
    end;
  finally
    Response.Free;
  end;


end;

function TfrmTelaInicial.MoverExecutavel(ACaminhoOrigem, ANovoCaminho: String): Boolean;
begin
  Result := False;
  try
    TFile.Move(ACaminhoOrigem, ANovoCaminho);
    DeletarDiretorio(ExtractFilePath(Application.ExeName)+'Updates');
    Result := True;
  except
    on E: Exception do
      begin
        TThread.Synchronize(nil, procedure begin ShowMessage('Erro ao Mover Execut�vel: '+E.Message); end);
      end;
  end;


end;

end.
