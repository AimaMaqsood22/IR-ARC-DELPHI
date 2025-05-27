object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 374
  ClientWidth = 790
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 25
    Top = 8
    Width = 408
    Height = 201
    Caption = 'Connect'
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 27
      Width = 32
      Height = 13
      Caption = 'Server'
    end
    object Label2: TLabel
      Left = 16
      Top = 54
      Width = 43
      Height = 13
      Caption = 'DB Name'
    end
    object Label3: TLabel
      Left = 16
      Top = 81
      Width = 22
      Height = 13
      Caption = 'User'
    end
    object Label4: TLabel
      Left = 16
      Top = 108
      Width = 46
      Height = 13
      Caption = 'Password'
    end
    object Button3: TButton
      Left = 246
      Top = 173
      Width = 75
      Height = 25
      Caption = 'Connect'
      TabOrder = 0
      OnClick = Button3Click
    end
    object Edit1: TEdit
      Left = 72
      Top = 23
      Width = 121
      Height = 21
      TabOrder = 1
      Text = 'Arc_Listener.Ad2016.rd.uk.eilab.biz,1444'
    end
    object Edit2: TEdit
      Left = 72
      Top = 48
      Width = 121
      Height = 21
      TabOrder = 2
      Text = 'testdb'
    end
    object Edit3: TEdit
      Left = 72
      Top = 78
      Width = 121
      Height = 21
      TabOrder = 3
      Text = 'sa'
    end
    object Edit4: TEdit
      Left = 72
      Top = 105
      Width = 121
      Height = 21
      TabOrder = 4
      Text = 'Z1ppyf0rever'
    end
    object CheckBox1: TCheckBox
      Left = 16
      Top = 132
      Width = 153
      Height = 17
      Caption = 'Set MultiSubnetFailover'
      TabOrder = 5
    end
  end
  object Button4: TButton
    Left = 25
    Top = 239
    Width = 75
    Height = 25
    Caption = 'Run SQL'
    TabOrder = 1
    OnClick = Button4Click
  end
  object Memo1: TMemo
    Left = 439
    Top = 8
    Width = 343
    Height = 348
    TabOrder = 2
  end
  object Edit5: TEdit
    Left = 25
    Top = 212
    Width = 408
    Height = 21
    TabOrder = 3
    Text = 'Select @@Servername as servername'
  end
  object Button7: TButton
    Left = 352
    Top = 181
    Width = 75
    Height = 25
    Caption = 'Disonnect'
    TabOrder = 4
  end
  object Button1: TButton
    Left = 25
    Top = 270
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 5
    OnClick = Button1Click
  end
  object SQLConnection1: TSQLConnection
    Left = 352
    Top = 296
  end
end
