object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'LiteXplorer'
  ClientHeight = 829
  ClientWidth = 1021
  Color = clBtnFace
  CustomTitleBar.Control = TitleBarPanel1
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 31
  CustomTitleBar.BackgroundColor = clWhite
  CustomTitleBar.ForegroundColor = 65793
  CustomTitleBar.InactiveBackgroundColor = clWhite
  CustomTitleBar.InactiveForegroundColor = 10066329
  CustomTitleBar.ButtonForegroundColor = 65793
  CustomTitleBar.ButtonBackgroundColor = clWhite
  CustomTitleBar.ButtonHoverForegroundColor = 65793
  CustomTitleBar.ButtonHoverBackgroundColor = 16053492
  CustomTitleBar.ButtonPressedForegroundColor = 65793
  CustomTitleBar.ButtonPressedBackgroundColor = 15395562
  CustomTitleBar.ButtonInactiveForegroundColor = 10066329
  CustomTitleBar.ButtonInactiveBackgroundColor = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.Top = 31
  StyleElements = [seFont, seClient]
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 15
  object ACLSplitter1: TACLSplitter
    Left = 768
    Top = 30
    Width = 8
    Height = 764
    Control = gbPreview
    ExplicitLeft = 760
    ExplicitTop = 55
    ExplicitHeight = 739
  end
  object ACLSplitter2: TACLSplitter
    Left = 200
    Top = 30
    Width = 8
    Height = 764
    Control = gbSidebar
    ExplicitLeft = 225
    ExplicitTop = 55
    ExplicitHeight = 739
  end
  object TitleBarPanel1: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 1021
    Height = 30
    CustomButtons = <>
    object rkAeroTabs1: TrkAeroTabs
      AlignWithMargins = True
      Left = 32
      Top = 3
      Width = 851
      Height = 25
      Margins.Left = 32
      Margins.Right = 138
      Align = alClient
      Color = 2960685
      ColorBackground = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ShowButton = False
      Tabs.Strings = (
        'Projects'
        'Documents'
        'Favorites')
      OnMouseDown = rkAeroTabs1MouseDown
    end
  end
  object rkView1: TrkView
    Left = 208
    Top = 30
    Width = 560
    Height = 764
    ShowHint = True
    Visible = False
    TabOrder = 1
    MultipleSelection = True
    HotTracking = True
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    OnMouseDown = rkView1MouseDown
    OnMouseUp = rkView1MouseUp
    OnDblClick = rkView1DblClick
    OnSelecting = rkView1Selecting
    CellWidth = 0
    CellAutoAdj = True
    CenterView = True
    CellSelect = True
    Columns = ''
    Color = 2960685
    ColorSel = 14120960
    OnCellPaint = rkView1CellPaint
  end
  object JvStatusBar1: TJvStatusBar
    Left = 0
    Top = 794
    Width = 1021
    Height = 35
    Panels = <>
    object Label1: TLabel
      Left = 0
      Top = 0
      Width = 34
      Height = 35
      Align = alLeft
      Caption = 'Label1'
      ExplicitHeight = 15
    end
    object Label2: TLabel
      Left = 34
      Top = 0
      Width = 34
      Height = 35
      Align = alLeft
      Caption = 'Label2'
      ExplicitHeight = 15
    end
    object TrackBar1: TTrackBar
      Left = 871
      Top = 0
      Width = 150
      Height = 35
      Align = alRight
      TabOrder = 0
      OnChange = TrackBar1Change
    end
  end
  object gbPreview: TACLGroupBox
    Left = 776
    Top = 30
    Width = 245
    Height = 764
    Align = alRight
    TabOrder = 3
    Caption = ''
    object cardViewers: TCardPanel
      Left = 10
      Top = 10
      Width = 225
      Height = 744
      Align = alClient
      ActiveCard = crdAudiovisual
      Caption = 'cardViewers'
      TabOrder = 0
      ExplicitLeft = 112
      ExplicitTop = 336
      ExplicitWidth = 300
      ExplicitHeight = 200
      object crdImages: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdImages'
        CardIndex = 0
        TabOrder = 0
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
        object ImgView321: TImgView32
          Left = 0
          Top = 0
          Width = 223
          Height = 742
          Align = alClient
          Bitmap.ResamplerClassName = 'TNearestResampler'
          BitmapAlign = baCustom
          Color = clBackground
          ParentColor = False
          Scale = 1.00000000000000000
          ScaleMode = smScale
          Background.CheckersStyle = bcsDark
          ScrollBars.Increment = 0
          OverSize = 0
          TabOrder = 0
          OnMouseDown = ImgView321MouseDown
          OnMouseMove = ImgView321MouseMove
          OnMouseUp = ImgView321MouseUp
          OnMouseWheel = ImgView321MouseWheel
          ExplicitHeight = 706
        end
      end
      object crdAudiovisual: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdAudiovisual'
        CardIndex = 1
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
        object pnlMPV: TPanel
          Left = 0
          Top = 0
          Width = 223
          Height = 706
          Align = alClient
          Caption = 'pnlMPV'
          TabOrder = 0
        end
        object ACLSliderMPV: TACLSlider
          Left = 0
          Top = 706
          Width = 223
          Height = 36
          Align = alBottom
          TabOrder = 1
          OnMouseDown = ACLSliderMPVMouseDown
          OnMouseUp = ACLSliderMPVMouseUp
          Orientation = oHorizontal
        end
      end
      object crdPDFs: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdPDFs'
        CardIndex = 2
        TabOrder = 2
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
        object PDFiumControl1: TPDFiumControl
          Left = 0
          Top = 0
          Width = 223
          Height = 742
          HorzScrollBar.Range = 12
          HorzScrollBar.Smooth = True
          HorzScrollBar.Tracking = True
          VertScrollBar.Range = 6
          VertScrollBar.Smooth = True
          VertScrollBar.Tracking = True
          Align = alClient
          Color = clWhite
          PrintJobTitle = 'Print PDF'
          SearchHighlightAll = False
          SearchMatchCase = False
          SearchWholeWords = False
          Visible = False
          ZoomPercent = 100.00000000000000000
          ExplicitHeight = 706
        end
      end
      object crdTexts: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdTexts'
        CardIndex = 3
        TabOrder = 3
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
      end
      object crdHTML: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdHTML'
        CardIndex = 4
        TabOrder = 4
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
      end
      object crdHex: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdHex'
        CardIndex = 5
        TabOrder = 5
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
      end
      object crdProperties: TCard
        Left = 1
        Top = 1
        Width = 223
        Height = 742
        Caption = 'crdProperties'
        CardIndex = 6
        TabOrder = 6
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 185
        ExplicitHeight = 41
      end
    end
  end
  object gbSidebar: TACLGroupBox
    Left = 0
    Top = 30
    Width = 200
    Height = 764
    Align = alLeft
    TabOrder = 4
    Caption = ''
    object ACLShellTreeView1: TACLShellTreeView
      Left = 10
      Top = 10
      Width = 225
      Height = 744
      Align = alLeft
      TabOrder = 0
      OnClick = ACLShellTreeView1Click
      OptionsBehavior.AllowLibraryPaths = True
      OptionsView.ShowFavorites = True
      OptionsView.ShowHidden = False
    end
  end
  object CardPanel1: TCardPanel
    Left = 208
    Top = 30
    Width = 560
    Height = 764
    Align = alClient
    ActiveCard = crdExplorer
    BevelOuter = bvNone
    Caption = 'CardPanel1'
    TabOrder = 5
    ExplicitLeft = 8
    ExplicitTop = 59
    ExplicitWidth = 544
    ExplicitHeight = 697
    object crdExplorer: TCard
      Left = 0
      Top = 0
      Width = 560
      Height = 764
      Caption = 'crdExplorer'
      CardIndex = 0
      TabOrder = 0
      ExplicitWidth = 544
      ExplicitHeight = 697
      object gbMainContent: TACLGroupBox
        Left = 0
        Top = 0
        Width = 560
        Height = 764
        Align = alClient
        TabOrder = 0
        Borders = []
        Caption = ''
        ExplicitLeft = 208
        ExplicitTop = 30
        object VirtualShellToolbar1: TVirtualShellToolbar
          Left = 8
          Top = 8
          Width = 544
          Height = 26
          AutoSize = True
          BkGndParent = gbMainContent
          Options = [toThemeAware, toTransparent]
          Visible = False
          WideText = 'VirtualShellToolbar1'
        end
        object VirtualExplorerEasyListview1: TVirtualExplorerEasyListview
          Left = 8
          Top = 59
          Width = 544
          Height = 697
          Align = alClient
          CompressedFile.Color = clRed
          CompressedFile.Font.Charset = DEFAULT_CHARSET
          CompressedFile.Font.Color = clWindowText
          CompressedFile.Font.Height = -12
          CompressedFile.Font.Name = 'Segoe UI'
          CompressedFile.Font.Style = []
          DefaultSortColumn = 0
          EditManager.Enabled = True
          EditManager.Font.Charset = DEFAULT_CHARSET
          EditManager.Font.Color = clWindowText
          EditManager.Font.Height = -12
          EditManager.Font.Name = 'Segoe UI'
          EditManager.Font.Style = []
          EncryptedFile.Color = 32832
          EncryptedFile.Font.Charset = DEFAULT_CHARSET
          EncryptedFile.Font.Color = clWindowText
          EncryptedFile.Font.Height = -12
          EncryptedFile.Font.Name = 'Segoe UI'
          EncryptedFile.Font.Style = []
          DragManager.Enabled = True
          FileObjects = [foFolders, foNonFolders, foEnableAsync]
          FileSizeFormat = vfsfDefault
          Grouped = False
          GroupingColumn = 0
          Header.Height = 23
          Options = [eloBrowseExecuteFolder, eloBrowseExecuteFolderShortcut, eloBrowseExecuteZipFolder, eloExecuteOnDblClick, eloThreadedEnumeration, eloThreadedImages, eloThreadedDetails, eloShellContextMenus, eloChangeNotifierThread, eloTrackChangesInMappedDrives, eloGhostHiddenFiles]
          PaintInfoGroup.MarginBottom.CaptionIndent = 4
          Sort.Algorithm = esaQuickSort
          Sort.AutoSort = True
          SortFolderFirstAlways = True
          Selection.MultiSelect = True
          TabOrder = 1
          ThumbsManager.AutoLoad = True
          ThumbsManager.AutoSave = True
          ThumbsManager.StorageFilename = 'Thumbnails.album'
          View = elsThumbnail
          OnItemSelectionChanged = VirtualExplorerEasyListview1ItemSelectionChanged
          OnKeyAction = VirtualExplorerEasyListview1KeyAction
          OnRootChange = VirtualExplorerEasyListview1RootChange
        end
        object rkSmartPath1: TrkSmartPath
          Left = 8
          Top = 34
          Width = 544
          Height = 25
          Align = alTop
          BorderColor = clBlack
          BtnGreyGrad1 = 2960685
          BtnGreyGrad2 = 2960685
          BtnNormGrad1 = 2960685
          BtnNormGrad2 = 2960685
          BtnHotGrad1 = 2960685
          BtnHotGrad2 = 2960685
          BtnPenGray = 9408399
          BtnPenNorm = 11632444
          BtnPenShade1 = 2960685
          BtnPenShade2 = 2960685
          BtnPenArrow = clBlack
          ComputerAsDefault = True
          DirMustExist = True
          EmptyPathIcon = -1
          EmptyPathText = 'Este equipo'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          NewFolderName = 'NewFolder'
          ParentColor = False
          ParentBackground = False
          ParentFont = False
          Path = 'C:\Users\vhanla\Documents\'
          SpecialFolders = [spDesktop, spDocuments]
          TabOrder = 2
          Transparent = True
          OnPathChanged = rkSmartPath1PathChanged
        end
        object ACLGroupBox2: TACLGroupBox
          Left = 8
          Top = 59
          Width = 544
          Height = 697
          Align = alClient
          TabOrder = 3
          Visible = False
          Caption = ''
          object ACLSearchEdit1: TACLSearchEdit
            Left = 10
            Top = 10
            Width = 524
            Height = 23
            Align = alTop
            TabOrder = 0
            OnChange = ACLSearchEdit1Change
            Text = ''
          end
          object VirtualMultiPathExplorerEasyListview1: TVirtualMultiPathExplorerEasyListview
            Left = 10
            Top = 33
            Width = 524
            Height = 654
            Align = alClient
            CompressedFile.Color = clRed
            CompressedFile.Font.Charset = DEFAULT_CHARSET
            CompressedFile.Font.Color = clWindowText
            CompressedFile.Font.Height = -12
            CompressedFile.Font.Name = 'Segoe UI'
            CompressedFile.Font.Style = []
            DefaultSortColumn = 0
            EditManager.Font.Charset = DEFAULT_CHARSET
            EditManager.Font.Color = clWindowText
            EditManager.Font.Height = -12
            EditManager.Font.Name = 'Segoe UI'
            EditManager.Font.Style = []
            EncryptedFile.Color = 32832
            EncryptedFile.Font.Charset = DEFAULT_CHARSET
            EncryptedFile.Font.Color = clWindowText
            EncryptedFile.Font.Height = -12
            EncryptedFile.Font.Name = 'Segoe UI'
            EncryptedFile.Font.Style = []
            FileSizeFormat = vfsfDefault
            Grouped = False
            GroupingColumn = 0
            Header.Height = 23
            PaintInfoGroup.MarginBottom.CaptionIndent = 4
            PaintInfoGroup.MarginTop.Visible = False
            Sort.Algorithm = esaQuickSort
            Sort.AutoSort = True
            TabOrder = 1
            ThumbsManager.AutoLoad = True
            ThumbsManager.AutoSave = True
            ThumbsManager.StorageFilename = 'Thumbnails.album'
            View = elsReportThumb
            OnCustomColumnGetCaption = VirtualMultiPathExplorerEasyListview1CustomColumnGetCaption
          end
        end
      end
    end
    object crdSettings: TCard
      Left = 0
      Top = 0
      Width = 560
      Height = 764
      Caption = 'crdSettings'
      CardIndex = 1
      TabOrder = 1
    end
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoPickFolders]
    Left = 608
    Top = 408
  end
  object ActionList1: TActionList
    Left = 680
    Top = 217
    object acCloseWindow: TAction
      Caption = 'acCloseWindow'
      ShortCut = 16471
      OnExecute = acCloseWindowExecute
    end
    object acFuzzyFinder: TAction
      Caption = 'acFuzzyFinder'
      ShortCut = 16454
      OnExecute = acFuzzyFinderExecute
    end
    object acToggleSidebar: TAction
      Caption = 'acToggleSidebar'
      ShortCut = 16452
      OnExecute = acToggleSidebarExecute
    end
    object acTogglePreview: TAction
      Caption = 'acTogglePreview'
      ShortCut = 32848
      OnExecute = acTogglePreviewExecute
    end
  end
end
