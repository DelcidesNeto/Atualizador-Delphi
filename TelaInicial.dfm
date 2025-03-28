object frmTelaInicial: TfrmTelaInicial
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Atualizar NSCobran'#231'as'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object LabelStatus: TLabel
    Left = 280
    Top = 239
    Width = 18
    Height = 37
    Caption = '...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object Atualizar: TButton
    Left = 200
    Top = 128
    Width = 201
    Height = 65
    Caption = 'Vincular Banco de Dados'
    TabOrder = 0
    OnClick = AtualizarClick
  end
  object ProgressBar: TProgressBar
    Left = 24
    Top = 208
    Width = 561
    Height = 25
    Style = pbstMarquee
    TabOrder = 1
    Visible = False
  end
  object Button1: TButton
    Left = 184
    Top = 328
    Width = 75
    Height = 25
    Caption = 'Teste'
    TabOrder = 2
    Visible = False
    OnClick = Button1Click
  end
  object Query: TFDQuery
    Connection = Banco
    Left = 216
    Top = 64
  end
  object Banco: TFDConnection
    Params.Strings = (
      'DriverID=FB'
      'User_Name=sysdba'
      'Password=masterkey')
    Left = 280
    Top = 16
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    Left = 408
    Top = 40
  end
end
