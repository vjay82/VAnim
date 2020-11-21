object EinstellungenForm: TEinstellungenForm
  Left = 466
  Top = 337
  Width = 558
  Height = 408
  BorderStyle = bsSizeToolWin
  Caption = 'Settings'
  Color = clBtnFace
  DefaultMonitor = dmPrimary
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefault
  ScreenSnap = True
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 16
    Top = 16
    Width = 513
    Height = 305
    ActivePage = TabSheet1
    TabOrder = 0
    object TabSheet3: TTabSheet
      Caption = 'Info'
      ImageIndex = 2
      object Label2: TLabel
        Left = 0
        Top = 96
        Width = 505
        Height = 113
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'New settings will be applied on new windows, created after you p' +
          'ressed ok.'#13#10#13#10'VAnim is disabled while you are in this configdial' +
          'og'
        WordWrap = True
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'Buttonpulser'
      object Label4: TLabel
        Left = 320
        Top = 16
        Width = 10
        Height = 13
        Caption = 'X:'
      end
      object Label5: TLabel
        Left = 384
        Top = 16
        Width = 10
        Height = 13
        Caption = 'Y:'
      end
      object Label7: TLabel
        Left = 152
        Top = 144
        Width = 66
        Height = 13
        Caption = 'Pulsingspeed:'
      end
      object Label1: TLabel
        Left = 228
        Top = 82
        Width = 186
        Height = 13
        Caption = '*2 Pixels (fixes the famous font problem)'
      end
      object Label6: TLabel
        Left = 24
        Top = 176
        Width = 67
        Height = 13
        Caption = 'Active Button:'
      end
      object Label8: TLabel
        Left = 24
        Top = 216
        Width = 75
        Height = 13
        Caption = 'Inactive Button:'
      end
      object Button2: TButton
        Left = 152
        Top = 248
        Width = 289
        Height = 25
        Caption = 'Update Buttonpictures from Windows'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = Button2Click
      end
      object Button3: TButton
        Left = 152
        Top = 176
        Width = 57
        Height = 25
        Caption = 'Set Font'
        TabOrder = 1
        OnClick = Button3Click
      end
      object Button4: TButton
        Left = 152
        Top = 216
        Width = 57
        Height = 25
        Caption = 'Set Font'
        TabOrder = 2
        OnClick = Button4Click
      end
      object CheckBox1: TCheckBox
        Left = 24
        Top = 16
        Width = 81
        Height = 17
        Caption = 'Active'
        TabOrder = 3
        OnClick = CheckBox1Click
      end
      object SpinEdit1: TSpinEdit
        Left = 336
        Top = 16
        Width = 41
        Height = 22
        MaxValue = 100
        MinValue = 0
        TabOrder = 4
        Value = 0
      end
      object SpinEdit2: TSpinEdit
        Left = 400
        Top = 16
        Width = 41
        Height = 22
        MaxValue = 100
        MinValue = 0
        TabOrder = 5
        Value = 0
      end
      object CheckBox3: TCheckBox
        Left = 152
        Top = 16
        Width = 129
        Height = 17
        Caption = 'Use Transparentpixel'
        TabOrder = 6
      end
      object CheckBox4: TCheckBox
        Left = 152
        Top = 56
        Width = 273
        Height = 17
        Caption = 'Scale down the Buttonfont if it exceeds the buttonwidth minus'
        TabOrder = 7
      end
      object SpinEdit3: TSpinEdit
        Left = 176
        Top = 80
        Width = 41
        Height = 22
        MaxValue = 500
        MinValue = 0
        TabOrder = 8
        Value = 0
      end
      object CheckBox5: TCheckBox
        Left = 152
        Top = 112
        Width = 113
        Height = 17
        Caption = 'Multipulsing'#160' '
        TabOrder = 9
      end
      object SpinEdit4: TSpinEdit
        Left = 336
        Top = 136
        Width = 105
        Height = 22
        MaxValue = 500
        MinValue = 25
        TabOrder = 10
        Value = 25
      end
      object Button6: TButton
        Left = 216
        Top = 176
        Width = 97
        Height = 25
        Caption = 'Set Font Color'
        TabOrder = 11
        OnClick = Button6Click
      end
      object Button9: TButton
        Left = 216
        Top = 216
        Width = 97
        Height = 25
        Caption = 'Set Font Color'
        TabOrder = 12
        OnClick = Button9Click
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'ProgressBarAnimator'
      ImageIndex = 1
      object Label3: TLabel
        Left = 168
        Top = 128
        Width = 249
        Height = 16
        AutoSize = False
        Caption = 'Label3'
      end
      object CheckBox2: TCheckBox
        Left = 24
        Top = 16
        Width = 81
        Height = 17
        Caption = 'Active'
        TabOrder = 0
        OnClick = CheckBox2Click
      end
    end
    object TabSheet6: TTabSheet
      Caption = 'Halo Effects'
      ImageIndex = 5
      OnShow = TabSheet6Show
      object Shape1: TShape
        Left = 320
        Top = 56
        Width = 161
        Height = 161
        Pen.Color = clRed
        Pen.Style = psDash
        Shape = stCircle
      end
      object CheckBox7: TCheckBox
        Left = 24
        Top = 16
        Width = 81
        Height = 17
        Caption = 'Active'
        TabOrder = 0
        OnClick = CheckBox7Click
      end
      object Edit2: TEdit
        Left = 216
        Top = 80
        Width = 137
        Height = 21
        TabOrder = 1
        Text = 'This is an editbox.'
      end
      object Edit3: TEdit
        Left = 216
        Top = 168
        Width = 137
        Height = 21
        TabOrder = 2
        Text = 'This is also an editbox.'
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'Exclusions'
      ImageIndex = 4
      object Label11: TLabel
        Left = 16
        Top = 16
        Width = 189
        Height = 13
        Caption = 'The apps in the Listbox are not skinned.'
      end
      object Label12: TLabel
        Left = 16
        Top = 72
        Width = 249
        Height = 161
        AutoSize = False
        Caption = 
          'Please enter the whole processname, like: Explorer.exe, nexplore' +
          'r.exe, itunes.exe or whatever. '#13#10#13#10'When you are a programmer, it' +
          ' would be a good idea to add your ide.'#13#10#13#10'The comparing is not c' +
          'ase-sensitive.'#13#10#13#10'The settings will only applied on applications' +
          ' startet after the settings have been saved.'
        WordWrap = True
      end
      object ListBox1: TListBox
        Left = 272
        Top = 16
        Width = 201
        Height = 249
        ItemHeight = 13
        TabOrder = 0
      end
      object Button7: TButton
        Left = 112
        Top = 240
        Width = 75
        Height = 25
        Caption = 'Add'
        TabOrder = 1
        OnClick = Button7Click
      end
      object Button8: TButton
        Left = 192
        Top = 240
        Width = 75
        Height = 25
        Caption = 'Delete'
        TabOrder = 2
        OnClick = Button8Click
      end
    end
  end
  object Button1: TButton
    Left = 432
    Top = 336
    Width = 83
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ModalResult = 3
    ParentFont = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button5: TButton
    Left = 344
    Top = 336
    Width = 79
    Height = 25
    Caption = 'Ok'
    Default = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ModalResult = 1
    ParentFont = False
    TabOrder = 2
    OnClick = Button5Click
  end
  object FontDialog1: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    MinFontSize = 50
    MaxFontSize = 8
    Options = []
    Left = 300
    Top = 24
  end
  object JvColorDialog1: TJvColorDialog
    Options = [cdFullOpen]
    Left = 36
    Top = 120
  end
end
