unit TelaInicial;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, IdHTTP, IdSSLOpenSSL, RESTRequest4D, JSON, System.Threading, System.IOUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.UI.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait, FireDAC.Phys.IBBase, Data.DB, FireDAC.Comp.Client,
  FireDAC.Comp.DataSet, StrUtils;

type
  TfrmTelaInicial = class(TForm)
    Atualizar: TButton;
    ProgressBar: TProgressBar;
    LabelStatus: TLabel;
    Query: TFDQuery;
    Banco: TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    procedure FormDestroy(Sender: TObject);
    procedure AtualizarClick(Sender: TObject);
  private
    { Private declarations }
    function AtualizarDelphi(AUrl, ACaminho: String): Boolean;
    function GetLinkDownload: String;
    procedure MoverExecutavel(ACaminhoOrigem, ANovoCaminho: String);
    function DeletarDiretorio(ACaminho: String): Boolean;
    function IsConnected: Boolean;
    procedure AtualizarBancoDeDados;
    function GetQueries: TArray<String>;
    procedure ExecutarCmd(ACmd: String);
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

procedure TfrmTelaInicial.AtualizarBancoDeDados;
begin

end;

procedure TfrmTelaInicial.AtualizarClick(Sender: TObject);
begin
  if IsConnected then
    begin
      TTask.Run(procedure
        var
          Link: String;
          Caminho: String;
          Atualizou: Boolean;
          AtualizacoesBanco: TArray<String>;
          
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
              if not Assigned(frmTelaInicial) then
                exit;
              Atualizou := AtualizarDelphi(Link, Caminho);
              if Atualizou then
                begin
                  TThread.Synchronize(nil,
                  procedure
                  begin
                    LabelStatus.Left := 121;
                    LabelStatus.Caption := 'Atualizando Banco de Dados...';
                  end);
                  AtualizacoesBanco := GetQueries;
                  for var cmd in AtualizacoesBanco do
                    begin
                      try
                        ExecutarCmd(cmd);
                      except
                      end;
                    end;
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
              DeletarDiretorio(ExtractFilePath(Application.ExeName)+'Updates');
              TThread.Synchronize(nil, procedure begin ShowMessage('Houve um erro ao obter o link de download!'); end);
            end;
        end);
    end
  else
    begin
      var BancoAtualizar := TOpenDialog.Create(nil);
      try
        BancoAtualizar.Title := 'Selecione a Base de Dados que ser� Atualizada';
        BancoAtualizar.Filter := '(*.fdb)|*.fdb';
        BancoAtualizar.Execute();
        Banco.Params.Database := BancoAtualizar.FileName;
      finally
        BancoAtualizar.Free;
      end;
    end;

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
  if not Assigned(frmTelaInicial) then
    exit;
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

procedure TfrmTelaInicial.ExecutarCmd(ACmd: String);
begin
  Query.SQL.Text := ACmd;
  Query.ExecSQL;
  Banco.Commit;
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

function TfrmTelaInicial.GetQueries: TArray<String>;
var 
  Rest4: IResponse;
  Response: TJSONObject;
  AtualizarBanco: TArray<String>;
  Queries: String;
begin
  Rest4 := TRequest.New.BaseURL('https://neto.pythonanywhere.com/UpdateDatabaseDelphi')
  .Get;
  Response := TJSONObject.ParseJSONValue(Rest4.Content) as TJSONObject;
  try
    Queries := Response.GetValue<String>('query');
    AtualizarBanco := SplitString(Queries, '�');
  finally
    Response.Free;
  end;
  Result := AtualizarBanco;
end;

function TfrmTelaInicial.IsConnected: Boolean;
begin
 if Banco.Params.Database <> '' then
  Result := True
 else
  Result := False;

end;

procedure TfrmTelaInicial.MoverExecutavel(ACaminhoOrigem, ANovoCaminho: String);
begin
  try
    TFile.Move(ACaminhoOrigem, ANovoCaminho);
    DeletarDiretorio(ExtractFilePath(Application.ExeName)+'Updates');
  except
    on E: Exception do
      begin
        TThread.Synchronize(nil, procedure begin ShowMessage('Erro ao Mover Execut�vel: '+E.Message); end);
      end;
  end;


end;

end.
