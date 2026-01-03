unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CB.DarkMode,
  VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL,
  VirtualTrees, VirtualExplorerTree, rkAeroTabs, Vcl.TitleBarCtrls,
  MPCommonObjects, EasyListview, VirtualExplorerEasyListview, rkSmartPath,
  rkView, jpeg, GIFImg, pngimage, Cod.Imaging.WebP, Math, CommCtrl, ShellApi,
  ShlObj, ActiveX, ComObj, rkIntegerList, Vcl.ComCtrls, JvExComCtrls,
  JvStatusBar, Vcl.StdCtrls, ACL.UI.Controls.Base, ACL.UI.Controls.Splitter,
  ACL.UI.Controls.GroupBox, ES.BaseControls, ES.Images,
  ACL.UI.Controls.CompoundControl, ACL.UI.Controls.TreeList,
  ACL.UI.Controls.ShellTreeView, MPVBasePlayer, Vcl.ExtCtrls, System.IOUtils,
  RzTabs, Vcl.ToolWin, VirtualShellToolBar, MPCommonUtilities,
  ACL.UI.Controls.Slider, ACL.UI.Controls.ProgressBar, System.Actions,
  Vcl.ActnList, System.Threading,
  FuzzyFileFinder, ACL.UI.DropSource, ACL.UI.DropTarget,
  ACL.UI.Controls.TreeList.Options, ACL.UI.Controls.TreeList.SubClass,
  ACL.UI.Controls.TreeList.Types, ACL.UI.Controls.BaseEditors,
  ACL.UI.Controls.TextEdit, ACL.UI.Controls.SearchBox, MPShellUtilities,
  rkSmartTabs, GR32_Image, GR32_Layers, PDFium.Control,
  Helpers, libpng, pngloader, LibTurboJPEG, jpegloader, Vcl.WinXPanels,
  CB.AppStartup, DataModule;

const
  CM_UpdateView = WM_USER + 2102; // Custom Message...
  CM_Progress = WM_USER + 2112; // Custom Message...
  MinSize = 52;
  MaxSize = 256;
  ColorFormat: DWord = 24;
  IEIFLAG_ASYNC = $001; // ask the extractor if it supports ASYNC extract
  // (free threaded)
  IEIFLAG_CACHE = $002; // returned from the extractor if it does NOT cache
  // the thumbnail
  IEIFLAG_ASPECT = $004; // passed to the extractor to beg it to render to
  // the aspect ratio of the supplied rect
  IEIFLAG_OFFLINE = $008; // if the extractor shouldn't hit the net to get
  // any content needs for the rendering
  IEIFLAG_GLEAM = $010; // does the image have a gleam? this will be
  // returned if it does
  IEIFLAG_SCREEN = $020; // render as if for the screen  (this is exlusive
  // with IEIFLAG_ASPECT )
  IEIFLAG_ORIGSIZE = $040; // render to the approx size passed, but crop if
  // neccessary
  IEIFLAG_NOSTAMP = $080; // returned from the extractor if it does NOT want
  // an icon stamp on the thumbnail
  IEIFLAG_NOBORDER = $100; // returned from the extractor if it does NOT want
  // an a border around the thumbnail
  IEIFLAG_QUALITY = $200; // passed to the Extract method to indicate that
  // a slower, higher quality image is desired,
  // re-compute the thumbnail

  SHIL_LARGE = $00; // The image size is normally 32x32 pixels. However, if the Use large icons option is selected from the Effects section of the Appearance tab in Display Properties, the image is 48x48 pixels.
  SHIL_SMALL = $01; // These images are the Shell standard small icon size of 16x16, but the size can be customized by the user.
  SHIL_EXTRALARGE = $02; // These images are the Shell standard extra-large icon size. This is typically 48x48, but the size can be customized by the user.
  SHIL_SYSSMALL = $03; // These images are the size specified by GetSystemMetrics called with SM_CXSMICON and GetSystemMetrics called with SM_CYSMICON.
  SHIL_JUMBO = $04; // Windows Vista and later. The image is normally 256x256 pixels.
  IID_IImageList: TGUID = '{46EB5926-582E-4017-9FDF-E8998DAA0950}';
  SID_IExtractImage2 = '{953BB1EE-93B4-11D1-98A3-00C04FB687DA}';
  IID_IExtractImage2: TGUID = SID_IExtractImage2;

const
  SEER_CLASS_NAME           = 'SeerWindowClass';

  SEER_REQUEST_PATH         = 4000;
  SEER_RESPONSE_PATH        = 4001;

  SEER_INVOKE_W32           = 5000;
  SEER_INVOKE_W32_SEP       = 5001;
  SEER_INVOKE_QT            = 5002;
  SEER_INVOKE_QT_SEP        = 5003;

  SEER_IS_VISIBLE           = 5004;
  SEER_IS_VISIBLE_TRUE      = 1;
  SEER_IS_VISIBLE_FALSE     = 0;

  SEER_HIDE                 = 5005;

  SEER_EXPLORER_FOLDER      = 'explorers';
  SEER_JSON_KEY_CLASSNAME   = 'classname';
  SEER_JSON_KEY_WINDOWTEXT  = 'windowtext';
  SEER_JSON_KEY_APPNAME     = 'appname';

  APP_WINDOW_CLASS = 'LXPLORERWND';
const
  SEER_TIMEOUT_MS = 100; // < 150ms, leave margin


type
{$HPPEMIT 'DECLARE_DINTERFACE_TYPE_UUID("953BB1EE-93B4-11D1-98A3-00C04FB687DA", IExtractImage2)'}
  IRunnableTask = interface
    ['{85788D00-6807-11D0-B810-00C04FD706EC}']
    function Run: HResult; stdcall;
    function Kill(fWait: BOOL): HResult; stdcall;
    function Suspend: HResult; stdcall;
    function Resume: HResult; stdcall;
    function IsRunning: Longint; stdcall;
  end;

  IExtractImage = interface
    ['{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}']
    function GetLocation(pszwPathBuffer: PWideChar; cch: DWord;
      var dwPriority: DWord; var rgSize: TSize; dwRecClrDepth: DWord;
      var dwFlags: DWord): HResult; stdcall;
    function Extract(var hBmpThumb: HBITMAP): HResult; stdcall;
  end;

  IExtractImage2 = interface(IExtractImage)
    [SID_IExtractImage2]
    function GetDateStamp(var pDateStamp: TFileTime): HResult; stdcall;
  end;

  PCacheItem = ^TCacheItem;

  TCacheItem = record
    Idx: Integer;
    Size: Integer;
    Age: TDateTime;
    Scale: Integer;
    Bmp: TBitmap;
  end;

  PItemData = ^TItemData;

  TItemData = record
    Name: string;
    ThumbWidth: Word;
    ThumbHeight: Word;
    Size: Integer;
    Modified: TDateTime;
    Dir: Boolean;
    GotThumb: Boolean;
    IWidth, IHeight: Word;
    ImgIdx: Integer;
    IsIcon: Boolean;
    ImgState: Byte;
    Image: TObject;
  end;

  ThumbThread = class(TThread)
  private
    { Private declarations }
    ViewLink: TrkView;
    ItemsLink: TList;
  protected
    procedure Execute; override;
  public
    constructor Create(View: TrkView; Items: TList);
  end;

type
  TFileKind = (
    fkUnknown,
    fkJpeg,
    fkPng,
    fkGif,
    fkBmp,
    fkWebp,
    fkMp4
  );

  TMpvContainer = (
    mcUnknown,
    mcMp4,
    mcMov,
    mcMkv,
    mcWebm,
    mcAvi,
    mcMpegPs,
    mcFlv,
    mcWmv,
    mcOgg
  );

  TMpvAudioKind = (
    akUnknown,
    akMp3,
    akWav,
    akFlac,
    akOgg,
    akOpus,
    akAac,
    akAiff,
    akApe,
    akWma,
    akM4a
  );


  TFileDetectResult = record
    Kind: TFileKind;
    ExtensionMatches: Boolean;
  end;


type
  TForm1 = class(TForm)
    TitleBarPanel1: TTitleBarPanel;
    rkSmartPath1: TrkSmartPath;
    rkView1: TrkView;
    TrackBar1: TTrackBar;
    JvStatusBar1: TJvStatusBar;
    Label1: TLabel;
    FileOpenDialog1: TFileOpenDialog;
    Label2: TLabel;
    gbPreview: TACLGroupBox;
    ACLSplitter1: TACLSplitter;
    ACLShellTreeView1: TACLShellTreeView;
    pnlMPV: TPanel;
    VirtualExplorerEasyListview1: TVirtualExplorerEasyListview;
    ACLSplitter2: TACLSplitter;
    VirtualShellToolbar1: TVirtualShellToolbar;
    ACLSliderMPV: TACLSlider;
    ActionList1: TActionList;
    acCloseWindow: TAction;
    ACLSearchEdit1: TACLSearchEdit;
    ACLGroupBox2: TACLGroupBox;
    acFuzzyFinder: TAction;
    VirtualMultiPathExplorerEasyListview1: TVirtualMultiPathExplorerEasyListview;
    gbSidebar: TACLGroupBox;
    gbMainContent: TACLGroupBox;
    rkAeroTabs1: TrkAeroTabs;
    acToggleSidebar: TAction;
    acTogglePreview: TAction;
    ImgView321: TImgView32;
    PDFiumControl1: TPDFiumControl;
    CardPanel1: TCardPanel;
    crdExplorer: TCard;
    crdSettings: TCard;
    cardViewers: TCardPanel;
    crdImages: TCard;
    crdAudiovisual: TCard;
    crdPDFs: TCard;
    crdTexts: TCard;
    crdHTML: TCard;
    crdHex: TCard;
    crdProperties: TCard;
    procedure FormCreate(Sender: TObject);
    procedure rkAeroTabs1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    procedure UpdateStatus;
    procedure BiResample(Src, Dest: TBitmap; Sharpen: Boolean);
    procedure OpenDir(path: string = '');
    procedure CMProgress(var message: TMessage); message CM_Progress;
    procedure CMUpdateView(var message: TMessage); message CM_UpdateView;
    procedure ItemPaintBasic(Canvas: TCanvas; R: TRect; State: TsvItemState);
    procedure GenCellColors;
    function Running: Boolean;
    procedure Start;
    procedure Stop;
    procedure DoSort;
    procedure TrackBar1Change(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure rkView1CellPaint(Sender: TObject; Canvas: TCanvas; Cell: TRect;
      IdxA, Idx: Integer; State: TsvItemState);
    procedure rkView1Selecting(Sender: TObject; Count: Integer);
    procedure rkView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure rkAeroTabs1AddClick(Sender: TObject);
    procedure rkSmartPath1PathChanged(Sender: TObject);
    procedure rkView1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure rkView1DblClick(Sender: TObject);
    procedure ACLShellTreeView1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure VirtualExplorerEasyListview1ItemSelectionChanged(
      Sender: TCustomEasyListview; Item: TEasyItem);
    procedure VirtualExplorerEasyListview1RootChange(
      Sender: TCustomVirtualExplorerEasyListview);
    procedure ACLSliderMPVMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ACLSliderMPVMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure acCloseWindowExecute(Sender: TObject);
    procedure acFuzzyFinderExecute(Sender: TObject);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure ACLSearchEdit1Change(Sender: TObject);
    procedure VirtualMultiPathExplorerEasyListview1CustomColumnGetCaption(
      Sender: TCustomVirtualExplorerEasyListview; Column: TExplorerColumn;
      Item: TExplorerItem; var ACaption: string);
    procedure VirtualExplorerEasyListview1KeyAction(Sender: TCustomEasyListview;
      var CharCode: Word; var Shift: TShiftState; var DoDefault: Boolean);
    procedure FormResize(Sender: TObject);
    procedure acToggleSidebarExecute(Sender: TObject);
    procedure acTogglePreviewExecute(Sender: TObject);
    procedure ImgView321MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImgView321MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer; Layer: TCustomLayer);
    procedure ImgView321MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure ImgView321MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private declarations }
    Items: TList;
    ThumbSizeW, ThumbSizeH: Integer;
    FhImageList48: NativeUInt;
    FIconSize: Integer;
    FMouseDownItemIndex: Integer;
    FCurrentDir: string;
    FIsSeeking: Boolean; // Prevents update loops while dragging

    // GR32 viewer
    FDragging: Boolean;
    FLastX, FLastY: Integer;
    FZoomFactor: Single;

    // Fuzzy Search
    FFF: TDelphiFFF;
    FBridge: TFFFUIBridge;
    FDebounceTask: ITask;
    FLastQuery: string;
    FCachedResults: TArray<TSearchResult>;
    FCurrentSelectedItem: string;
    procedure OnSearchUpdate(const AResults: TArray<TSearchResult>);
    procedure DebouncedSearch(const AText: string);
    procedure DirectoryScan(const APath: string);

    procedure SetThumbSize(Value: Integer; UpdateTrackbar: Boolean);
    function ThumbBmp(Idx: Integer): TBitmap;
    procedure ClearThumbs;
    procedure ClearThumbsPool;

    procedure OnMPlayerProgress(cSender: TObject; fCurSec, fTotalSec: Double);
    procedure OnMPlayerStateChanged(cSender: TObject; eState: TMPVPlayerState);

    // GR32 preview
    procedure UpdateZoom(Delta: Integer);
    procedure UpdatePan(DX, DY: Integer);

    procedure SendPathToSeer;

  protected
    ThumbThr: ThumbThread;
    ThreadDone: Boolean;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
  public
    { Public declarations }
    Directory: string;
    MPlayer: TMPVBasePlayer;
    // Colors
    cGSelectedStart, cGSelectedEnd, cGHotStart, cGHotEnd, cGDisabledStart,
      cGDisabledEnd, cGHeaderStart, cGHeaderEnd, cGHeaderHotStart,
      cGHeaderHotEnd, cGHeaderSelStart, cGHeaderSelEnd, cHot, cSelected,
      cDisabled, cBackground, cLineHighLight: TColor;
    cShadeSelect: TColor;
    cShadeDisabled: TColor;
    CellShade0: TColor;
    CellShade1: TColor;
    CellShade2: TColor;
    CellShade3: TColor;
    CellShade4: TColor;
    CellBkgColor: TColor;
    CellBrdColor: array [Boolean, Boolean] of TColor;
    procedure DelayedStartup;
  end;

var
  Form1: TForm1;
  CellJpeg: TJPEGImage;
  WI, HI, TW, TH, HSX, vIdx: Integer;
  CellScale: Integer;
  CellStyle: Integer;
  ThumbsPool: TList;
  PoolSize, MaxPool: Integer;
  dummy: string;

implementation

{$R *.dfm}

{ Helper functions }

procedure OldHackAlpha(ABitmap: TBitmap; Color: TColor);
// Fast alpha remove hack... bitmap must be 32bit
type
  PRGB32 = ^TRGB32;

  TRGB32 = record
    B, G, R, A: Byte;
  end;

  PPixel32 = ^TPixel32;
  TPixel32 = array [0 .. 0] of TRGB32;
var
  Row: PPixel32;
  X, Y, slMain, slSize: Integer;
  R, G, B: Byte;
  c: Integer;
begin
  ABitmap.PixelFormat := pf32bit;
  c := ColorToRGB(Color);
  R := Byte(c);
  G := Byte(c shr 8);
  B := Byte(c shr 16);
  slMain := Integer(ABitmap.ScanLine[0]);
  slSize := Integer(ABitmap.ScanLine[1]) - slMain;
  for Y := 0 to ABitmap.Height - 1 do
  begin
    Row := PPixel32(slMain);
    for X := 0 to ABitmap.Width - 1 do
    begin
      Row[X].R := Row[X].A * (Row[X].R - R) shr 8 + R;
      Row[X].G := Row[X].A * (Row[X].G - G) shr 8 + G;
      Row[X].B := Row[X].A * (Row[X].B - B) shr 8 + B;
    end;
    slMain := slMain + slSize;
  end;
end;

procedure HackAlpha(ABitmap: TBitmap; Color: TColor);
// Fast alpha remove hack... bitmap must be 32bit
type
  // Define record for 32-bit pixel (Blue, Green, Red, Alpha)
  TRGB32 = record
    B, G, R, A: Byte;
  end;

  // FIX 1: Change array bound from [0..0] to a large size.
  // This prevents "Range Check Error" when accessing Row[X] where X > 0.
  TPixel32Array = array [0 .. MaxInt div SizeOf(TRGB32) - 1] of TRGB32;
  PPixel32Array = ^TPixel32Array;

var
  Row: PPixel32Array;
  X, Y: Integer;
  BackR, BackG, BackB: Integer; // Use Integer to avoid byte overflow
  c: Integer;
  Alpha, InvAlpha: Integer;
begin
  if ABitmap = nil then Exit;

  ABitmap.PixelFormat := pf32bit;
  c := ColorToRGB(Color);

  // Extract background color components safely
  BackR := c and $FF;
  BackG := (c shr 8) and $FF;
  BackB := (c shr 16) and $FF;

  for Y := 0 to ABitmap.Height - 1 do
  begin
    // Use ScanLine. It is safer and handles memory alignment (stride) automatically.
    Row := PPixel32Array(ABitmap.ScanLine[Y]);

    for X := 0 to ABitmap.Width - 1 do
    begin
      Alpha := Row[X].A;

      // FIX 2: Use the standard blending formula: (Src * Alpha + Bg * (255-Alpha)) / 256
      // The previous formula (Src - Bg) caused negative numbers which broke 'shr'.
      if Alpha = 255 then
      begin
        // Already opaque, do nothing (optimization)
      end
      else if Alpha = 0 then
      begin
        // Fully transparent? Just set to background color
        Row[X].R := BackR;
        Row[X].G := BackG;
        Row[X].B := BackB;
        Row[X].A := 255; // Set to opaque
      end
      else
      begin
        InvAlpha := 255 - Alpha;

        // This calculation stays positive and fits within Integer range.
        // 'shr 8' is a fast approximation of 'div 255'.
        Row[X].R := (Row[X].R * Alpha + BackR * InvAlpha) shr 8;
        Row[X].G := (Row[X].G * Alpha + BackG * InvAlpha) shr 8;
        Row[X].B := (Row[X].B * Alpha + BackB * InvAlpha) shr 8;

        Row[X].A := 255; // Mark as opaque
      end;
    end;
  end;
end;

function OldHackIconSize(ABitmap: TBitmap): TPoint;
// Fast iconsize hack... bitmap must be 32bit
type
  PPixel32 = ^TPixel32;
  TPixel32 = array [0 .. 0] of Cardinal;
var
  Row: PPixel32;
  X, Y, i, j, slMain, slSize: Integer;
begin
  ABitmap.PixelFormat := pf32bit;
  Result.X := ABitmap.Width;
  Result.Y := ABitmap.Height;
  if (Result.X < 1) or (Result.Y < 1) then
    Exit;
  slMain := Integer(ABitmap.ScanLine[0]);
  slSize := Integer(ABitmap.ScanLine[1]) - slMain;
  Result.X := 0;
  Result.Y := 0;
  for Y := 0 to ABitmap.Height - 1 do
  begin
    Row := PPixel32(slMain);
    for X := 0 to ABitmap.Width - 1 do
    begin
      if (Row[X] and $FF000000) <> 0 then
      begin
        if X > Result.X then
          Result.X := X;
        if Y > Result.Y then
          Result.Y := Y;
      end;
    end;
    slMain := slMain + slSize;
  end;
  i := Max(Result.X, Result.Y);
  j := 0;
  while i > j do
    j := j + 8;
  if j > 256 then
    j := 256;
  Result.X := j;
  Result.Y := Result.X;
end;

function HackIconSize(ABitmap: TBitmap): TPoint; // 64-bit memory safe
type
  PPixel32 = ^TPixel32;
  TPixel32 = array[0..MaxInt div SizeOf(Cardinal) - 1] of Cardinal;
var
  Row: PPixel32;
  X, Y: Integer;
  MaxX, MaxY: Integer;
  Size: Integer;
begin
  Result := Point(0, 0);

  if (ABitmap = nil) or (ABitmap.Width < 1) or (ABitmap.Height < 1) then
    Exit;

  ABitmap.PixelFormat := pf32bit;

  MaxX := -1;
  MaxY := -1;

  for Y := 0 to ABitmap.Height - 1 do
  begin
    Row := ABitmap.ScanLine[Y];
    for X := 0 to ABitmap.Width - 1 do
    begin
      // Alpha channel non-zero?
      if (Row[X] and $FF000000) <> 0 then
      begin
        if X > MaxX then MaxX := X;
        if Y > MaxY then MaxY := Y;
      end;
    end;
  end;

  if (MaxX < 0) or (MaxY < 0) then
    Exit;

  Size := Max(MaxX, MaxY) + 1;

  // Round up to next multiple of 8
  Result.X := ((Size + 7) div 8) * 8;

  if Result.X > 256 then
    Result.X := 256;

  Result.Y := Result.X;
end;


function GetImageListSH(SHIL_FLAG: Cardinal): HIMAGELIST;
type
  _SHGetImageList = function(iImageList: Integer; const riid: TGUID;
    var ppv: Pointer): HResult; stdcall;
var
  Handle: THandle;
  SHGetImageList: _SHGetImageList;
begin
  Result := 0;
  Handle := LoadLibrary('Shell32.dll');
  if Handle <> S_OK then
    try
      SHGetImageList := GetProcAddress(Handle, PChar(727));
      if Assigned(SHGetImageList) and (Win32Platform = VER_PLATFORM_WIN32_NT)
        then
        SHGetImageList(SHIL_FLAG, IID_IImageList, Pointer(Result));
    finally
      FreeLibrary(Handle);
    end;
end;

procedure GetIconFromFile(aFile: string; var aIcon: TIcon; SHIL_FLAG: Cardinal);
var
  aImgList: HIMAGELIST;
  SFI: TSHFileInfo;
  aIndex: Integer;
begin // Get the index of the imagelist
  SHGetFileInfo(PChar(aFile), FILE_ATTRIBUTE_NORMAL, SFI, SizeOf(TSHFileInfo),
    SHGFI_ICON or { SHGFI_LARGEICON or } SHGFI_SHELLICONSIZE or
      SHGFI_SYSICONINDEX or SHGFI_TYPENAME or SHGFI_DISPLAYNAME);
  if not Assigned(aIcon) then
    aIcon := TIcon.Create;
  aImgList := GetImageListSH(SHIL_FLAG); // get the imagelist
  aIndex := SFI.iIcon; // get index
  // OBS! Use ILD_IMAGE since ILD_NORMAL gives bad result in Windows 7
  aIcon.Handle := ImageList_GetIcon(aImgList, aIndex, ILD_IMAGE);
end;

procedure GraphicToBitmap(const Src: Vcl.Graphics.TGraphic;
  const Dest: Vcl.Graphics.TBitmap; const TransparentColor: Vcl.Graphics.TColor);
{ Copies a graphic object to a bitmap, which is set to the same size as the source object. }
{ If the source graphic is transparent then the bitmap is set to transparent and, if TransparentColor is not clNone, it is used as the bitmap's transparent colour. }
{ TransparentColor is ignored if the source is not transparent. }
var
  Crop: TPoint;
begin
  // Do nothing if either source or destination are nil
  if not Assigned(Src) or not Assigned(Dest) then
    Exit;

  if (Src.Width = 0) or (Src.Height = 0) then
    Exit;
  // Size the bitmap
  Dest.Width := Src.Width;
  Dest.Height := Src.Height;
  if Src.Transparent then
  begin
    // Source graphic is transparent, make bitmap behave transparently
    Dest.Transparent := true;
    if (TransparentColor <> Vcl.Graphics.clNone) then
    begin
      // Set destination as transparent using required colour key
      Dest.TransparentColor := TransparentColor;
      Dest.TransparentMode := Vcl.Graphics.tmFixed;
      // Set background colour of bitmap to transparent colour
      Dest.Canvas.Brush.Color := TransparentColor;
    end
    else
      // No transparent colour: set transparency to automatic
      Dest.TransparentMode := Vcl.Graphics.tmAuto;
  end;
  // Clear bitmap to required background colour and draw bitmap
  Dest.Canvas.FillRect(System.Classes.Rect(0, 0, Dest.Width, Dest.Height));
  Dest.Canvas.Draw(0, 0, Src);
  Crop := HackIconSize(Dest);
  Dest.Width := Crop.X;
  Dest.Height := Crop.Y;
end;

function BytesToStr(const i64Size: Int64): string;
const
  i64GB = 1024 * 1024 * 1024;
  i64MB = 1024 * 1024;
  i64KB = 1024;
begin
  if i64Size div i64GB > 0 then
    Result := Format('%.1f GB', [i64Size / i64GB])
  else if i64Size div i64MB > 0 then
    Result := Format('%.2f MB', [i64Size / i64MB])
  else if i64Size div i64KB > 0 then
    Result := Format('%.0f kB', [i64Size / i64KB])
  else
    Result := IntToStr(i64Size) + ' byte';
end;

function DetectFileKind(const FileName: string): TFileDetectResult;
const
  MaxHeaderSize = 32;
const
  PNG_SIG: array[0..7] of Byte =
    ($89, $50, $4E, $47, $0D, $0A, $1A, $0A);

  GIF87_SIG: array[0..5] of AnsiChar = ('G','I','F','8','7','a');
  GIF89_SIG: array[0..5] of AnsiChar = ('G','I','F','8','9','a');

  RIFF_SIG: array[0..3] of AnsiChar = ('R','I','F','F');
  WEBP_SIG: array[0..3] of AnsiChar = ('W','E','B','P');
  FTYP_SIG: array[0..3] of AnsiChar = ('f','t','y','p');

var
  FS: TFileStream;
  Buf: array[0..MaxHeaderSize - 1] of Byte;
  ReadBytes: Integer;
  Ext: string;

  function ExtMatches(Kind: TFileKind): Boolean;
  begin
    case Kind of
      fkJpeg: Result := (Ext = '.jpg') or (Ext = '.jpeg');
      fkPng:  Result := Ext = '.png';
      fkGif:  Result := Ext = '.gif';
      fkBmp:  Result := Ext = '.bmp';
      fkWebp: Result := Ext = '.webp';
      fkMp4:  Result := Ext = '.mp4';
    else
      Result := False;
    end;
  end;

begin
  Result.Kind := fkUnknown;
  Result.ExtensionMatches := False;

  Ext := LowerCase(ExtractFileExt(FileName));

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    ReadBytes := FS.Read(Buf, SizeOf(Buf));
    if ReadBytes < 12 then Exit;

    // JPEG
    if (Buf[0] = $FF) and (Buf[1] = $D8) and (Buf[2] = $FF) then
      Result.Kind := fkJpeg

    // PNG
    else if CompareMem(@Buf[0], @PNG_SIG[0], 8) then
      Result.Kind := fkPng

    // GIF
    else if CompareMem(@Buf[0], @GIF87_SIG[0], 6) or
        CompareMem(@Buf[0], @GIF89_SIG[0], 6) then
      Result.Kind := fkGif

    // BMP
    else if (Buf[0] = Ord('B')) and (Buf[1] = Ord('M')) then
      Result.Kind := fkBmp

    // WEBP
    else if CompareMem(@Buf[0], @RIFF_SIG[0], 4) and
        CompareMem(@Buf[8], @WEBP_SIG[0], 4) then
      Result.Kind := fkWebp

    // MP4
    else if CompareMem(@Buf[4], @FTYP_SIG[0], 4) then
      Result.Kind := fkMp4;

    Result.ExtensionMatches := ExtMatches(Result.Kind);
  finally
    FS.Free;
  end;
end;

function DetectMpvContainer(const FileName: string): TMpvContainer;
const
  EBML_SIG: array[0..3] of Byte = ($1A, $45, $DF, $A3); // MKV / WEBM
  RIFF_SIG: array[0..3] of AnsiChar = ('R','I','F','F');
  AVI_SIG:  array[0..3] of AnsiChar = ('A','V','I',' ');
  FTYP_SIG: array[0..3] of AnsiChar = ('f','t','y','p');
  FLV_SIG:  array[0..2] of AnsiChar = ('F','L','V');
  OGG_SIG:  array[0..3] of AnsiChar = ('O','g','g','S');

  MPEG_PS_SIG: array[0..3] of Byte = ($00, $00, $01, $BA);

  ASF_SIG: array[0..15] of Byte = (
    $30,$26,$B2,$75,$8E,$66,$CF,$11,
    $A6,$D9,$00,$AA,$00,$62,$CE,$6C
  );

var
  FS: TFileStream;
  Buf: array[0..63] of Byte;
  ReadBytes: Integer;
begin
  Result := mcUnknown;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    ReadBytes := FS.Read(Buf, SizeOf(Buf));
    if ReadBytes < 16 then Exit;

    // MKV / WEBM (EBML)
    if CompareMem(@Buf[0], @EBML_SIG[0], 4) then
      Exit(mcMkv);

    // MP4 / MOV (ftyp at offset 4)
    if CompareMem(@Buf[4], @FTYP_SIG[0], 4) then
      Exit(mcMp4);

    // AVI (RIFF + AVI )
    if CompareMem(@Buf[0], @RIFF_SIG[0], 4) and
       CompareMem(@Buf[8], @AVI_SIG[0], 4) then
      Exit(mcAvi);

    // MPEG Program Stream (.mpg, .mpeg)
    if CompareMem(@Buf[0], @MPEG_PS_SIG[0], 4) then
      Exit(mcMpegPs);

    // FLV
    if CompareMem(@Buf[0], @FLV_SIG[0], 3) then
      Exit(mcFlv);

    // OGG
    if CompareMem(@Buf[0], @OGG_SIG[0], 4) then
      Exit(mcOgg);

    // WMV / ASF
    if CompareMem(@Buf[0], @ASF_SIG[0], 16) then
      Exit(mcWmv);

  finally
    FS.Free;
  end;
end;

function IsPdfFile(const FileName: string): Boolean;
const
  PDF_SIG: array[0..4] of AnsiChar = ('%','P','D','F','-');
var
  FS: TFileStream;
  Buf: array[0..7] of Byte;
  ReadBytes: Integer;
begin
  Result := False;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    ReadBytes := FS.Read(Buf, SizeOf(Buf));
    if ReadBytes < Length(PDF_SIG) then
      Exit;

    Result := CompareMem(@Buf[0], @PDF_SIG[0], Length(PDF_SIG));
  finally
    FS.Free;
  end;
end;


function DetectMpvAudio(const FileName: string): TMpvAudioKind;
const
  ID3_SIG: array[0..2] of AnsiChar = ('I','D','3');

  RIFF_SIG: array[0..3] of AnsiChar = ('R','I','F','F');
  WAVE_SIG: array[0..3] of AnsiChar = ('W','A','V','E');

  FLAC_SIG: array[0..3] of AnsiChar = ('f','L','a','C');
  OGG_SIG:  array[0..3] of AnsiChar = ('O','g','g','S');
  OPUS_SIG: array[0..7] of AnsiChar = ('O','p','u','s','H','e','a','d');

  FORM_SIG: array[0..3] of AnsiChar = ('F','O','R','M');
  AIFF_SIG: array[0..3] of AnsiChar = ('A','I','F','F');

  APE_SIG:  array[0..3] of AnsiChar = ('M','A','C',' ');

  FTYP_SIG: array[0..3] of AnsiChar = ('f','t','y','p');

  ASF_SIG: array[0..15] of Byte = (
    $30,$26,$B2,$75,$8E,$66,$CF,$11,
    $A6,$D9,$00,$AA,$00,$62,$CE,$6C
  );

var
  FS: TFileStream;
  Buf: array[0..63] of Byte;
  ReadBytes: Integer;
begin
  Result := akUnknown;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    ReadBytes := FS.Read(Buf, SizeOf(Buf));
    if ReadBytes < 12 then Exit;

    // MP3 (ID3 or MPEG sync)
    if CompareMem(@Buf[0], @ID3_SIG[0], 3) or
       ((Buf[0] = $FF) and ((Buf[1] and $E0) = $E0)) then
      Exit(akMp3);

    // WAV
    if CompareMem(@Buf[0], @RIFF_SIG[0], 4) and
       CompareMem(@Buf[8], @WAVE_SIG[0], 4) then
      Exit(akWav);

    // FLAC
    if CompareMem(@Buf[0], @FLAC_SIG[0], 4) then
      Exit(akFlac);

    // OGG / OPUS
    if CompareMem(@Buf[0], @OGG_SIG[0], 4) then
    begin
      if CompareMem(@Buf[28], @OPUS_SIG[0], 8) then
        Exit(akOpus)
      else
        Exit(akOgg);
    end;

    // AAC (ADTS)
    if (Buf[0] = $FF) and ((Buf[1] and $F6) = $F0) then
      Exit(akAac);

    // AIFF
    if CompareMem(@Buf[0], @FORM_SIG[0], 4) and
       CompareMem(@Buf[8], @AIFF_SIG[0], 4) then
      Exit(akAiff);

    // Monkey's Audio
    if CompareMem(@Buf[0], @APE_SIG[0], 4) then
      Exit(akApe);

    // WMA / ASF
    if CompareMem(@Buf[0], @ASF_SIG[0], 16) then
      Exit(akWma);

    // M4A / ALAC / AAC (MP4 audio)
    if CompareMem(@Buf[4], @FTYP_SIG[0], 4) then
      Exit(akM4a);

  finally
    FS.Free;
  end;
end;


// SEER
procedure RegisterWithSeer;
var
  DocsPath, JsonDir, JsonFile: string;
  Json: string;
begin
  SetLength(DocsPath, MAX_PATH);
  SHGetFolderPath(0, CSIDL_MYDOCUMENTS, 0, 0, PChar(DocsPath));
  DocsPath := PChar(DocsPath);

  JsonDir := TPath.Combine(DocsPath, 'Seer\' + SEER_EXPLORER_FOLDER);
  if not DirectoryExists(JsonDir) then
    Exit; // Seer not installed or never run

  JsonFile := TPath.Combine(JsonDir, 'litexplorer.json');
  if FileExists(JsonFile) then
    Exit;

  Json :=
    Format('{"%s":"%s"}',
      [SEER_JSON_KEY_CLASSNAME, APP_WINDOW_CLASS]);

  TFile.WriteAllText(JsonFile, Json, TEncoding.UTF8);
end;


procedure TForm1.UpdatePan(DX, DY: Integer);
begin
  ImgView321.OffsetHorz := ImgView321.OffsetHorz + DX / FZoomFactor;
  ImgView321.OffsetVert := ImgView321.OffsetVert + DY / FZoomFactor;
  ImgView321.Invalidate;
end;

{ Form1 }

procedure TForm1.UpdateStatus;
var
  i: Integer;
  n: Int64;
begin
  n := 0;
  for i := 0 to rkView1.Selection.Count - 1 do
    n := n + PItemData(Items[rkView1.Selection[i]]).Size;
  label1.Caption := IntToStr(rkView1.Items.Count) + ' items, ' + IntToStr
    (rkView1.Selection.Count) + ' selected (' + BytesToStr(n) + ')';
end;

procedure TForm1.UpdateZoom(Delta: Integer);
var
  OldZoom, NewZoom: Single;
  CenterX, CenterY: Single;
begin
  OldZoom := ImgView321.Scale;

  if Delta > 0 then
    NewZoom := OldZoom * 1.1
  else
    NewZoom := OldZoom / 1.1;

  NewZoom := Max(0.1, Min(10.0, NewZoom)); // Limit zoom range

  // Calculate the center of the visible area
  CenterX := ImgView321.OffsetHorz + (ImgView321.Width / 2) / OldZoom;
  CenterY := ImgView321.OffsetVert + (ImgView321.Height / 2) / OldZoom;

  ImgView321.Scale := NewZoom;

  // Adjust offset to keep the center point at the same position
  ImgView321.OffsetHorz := CenterX - (ImgView321.Width / 2) / NewZoom;
  ImgView321.OffsetVert := CenterY - (ImgView321.Height / 2) / NewZoom;

  ImgView321.Invalidate;
end;

procedure ShowSeer(const wpath: widestring);
begin
  var SeerWnd := FindWindow(PChar('SeerWindowClass'), nil);
  if seerWnd <> 0 then
  begin
//    IsWindowVisible(SeerWnd)
    var cd: TCopyDataStruct;

    cd.dwData := 5000;
    cd.cbData := Length(wpath) * SizeOf(widechar);
    cd.lpData := PWideChar(wpath);

    SendMessage(seerWnd, WM_COPYDATA, wparam(0), lparam(@cd));
  end;
end;


procedure TForm1.VirtualExplorerEasyListview1ItemSelectionChanged(
  Sender: TCustomEasyListview; Item: TEasyItem);
begin

    var afile := PChar( VirtualExplorerEasyListview1.SelectedPath) ;
    if not FileExists(afile) then Exit;

    FCurrentSelectedItem := afile;

    if not DirectoryExists(afile) then
    begin

      var ft := DetectFileKind(afile);
      if (ft.Kind = fkPng) or (ft.Kind = fkJpeg) or (ft.Kind = fkBmp) or (ft.Kind = fkGif) or (ft.Kind = fkWebp) then
      begin
        cardViewers.ActiveCard := crdImages;
        MPlayer.Pause;


        if DetectFileKind(afile).ExtensionMatches then
        try
          //EsImage1.Picture.LoadFromFile(afile);
          //ImgView321.Bitmap.LoadFromFile(aFile);
          if ft.Kind = fkPng then
            LoadPngFast(afile, ImgView321.Bitmap)
          else if ft.Kind = fkJpeg then
            LoadJpegFast(afile, ImgView321.Bitmap)
          else
            ImgView321.Bitmap.LoadFromFile(aFile);
        except
          ImgView321.Bitmap.Assign(nil);
        end;
      end
      else
      begin
        var vt := DetectMpvContainer(aFile);
        if (vt = mcMp4) or (vt = mcMov) or (vt = mcMkv) or (vt = mcWebm) or (vt = mcAvi) or (vt = mcMpegPs) or (vt = mcFlv) or (vt = mcWmv) or (vt = mcOgg)
         then
         begin
            cardViewers.ActiveCard := crdAudiovisual;

            MPlayer.Stop;
            MPlayer.OpenFile(afile);
         end
        else if IsPdfFile(aFile) then
        begin
          cardViewers.ActiveCard := crdPDFs;
          MPlayer.Pause;
          PDFiumControl1.Visible := True;
          PDFiumControl1.LoadFromFile(aFile);
        end
        else
        begin
          var at := DetectMpvAudio(aFile);
          if at = akMp3 then
          begin
            cardViewers.ActiveCard := crdAudiovisual;
            MPlayer.OpenFile(afile);
          end;
        end;
      end;
    end;

    //seer support
//    if IsWindowVisible(FindWindow(PChar('SeerWindowClass'), nil)) then
//      ShowSeer(afile);
end;


procedure TForm1.VirtualExplorerEasyListview1KeyAction(
  Sender: TCustomEasyListview; var CharCode: Word; var Shift: TShiftState;
  var DoDefault: Boolean);
begin
  case CharCode of
    VK_UP:
      if ssAlt in Shift then
      begin
        VirtualExplorerEasyListview1.BrowseToPrevLevel;
      end;
    VK_DOWN:
      if ssAlt in Shift then
      begin
        VirtualExplorerEasyListview1.BrowseToNextLevel;
      end;
    VK_SPACE:
    begin
      var wpath: widestring;
      wpath := IncludeTrailingPathDelimiter(VirtualExplorerEasyListview1.RootFolderNamespace.NameForParsing) + VirtualExplorerEasyListview1.SelectedFile + #0;
      //ShowSeer(wpath);
      FCurrentSelectedItem := wpath;
    end;
  end;
end;

procedure TForm1.VirtualExplorerEasyListview1RootChange(
  Sender: TCustomVirtualExplorerEasyListview);
begin
  var curPath := VirtualExplorerEasyListview1.RootFolderNamespace.NameForParsing;
  if (FCurrentDir <> curPath) and Assigned(FFF) then
  begin
    FCurrentDir := curPath;
    rkSmartPath1.Path := FCurrentDir;
    if Assigned(FFF) then
      DirectoryScan(FCurrentDir);
  end;
end;

procedure TForm1.VirtualMultiPathExplorerEasyListview1CustomColumnGetCaption(
  Sender: TCustomVirtualExplorerEasyListview; Column: TExplorerColumn;
  Item: TExplorerItem; var ACaption: string);
begin
  // this component usees Tag to Map back to our cache
  if (Item.Tag >= 0) and (Item.Tag < Length(FCachedResults)) then
  begin
    // assuming score is the first custom column (after the shell columns)
    if Column.IsCustom then
      Caption := FCachedResults[Item.Tag].Score.ToString;
  end;
end;

procedure TForm1.WMCopyData(var Msg: TWMCopyData);
begin
  if Msg.CopyDataStruct.dwData = SEER_REQUEST_PATH then
  begin
    SendPathToSeer;
    Msg.Result := 1;
    Exit;
  end;

  inherited;
end;

//procedure TForm1.BiResample(Src, Dest: TBitmap; Sharpen: Boolean);
//// Fast bilinear resampling procedure found at Swiss Delphi Center + my mods...
//type
//  PRGB24 = ^TRGB24;
//
//  TRGB24 = record
//    B, G, R: Byte;
//  end;
//
//  PRGBArray = ^TRGBArray;
//  TRGBArray = array [0 .. 0] of TRGB24;
//var
//  X, Y, px, py: Integer;
//  i, x1, x2, z, z2, iz2: Integer;
//  w1, w2, w3, w4: Integer;
//  Ratio: Integer;
//  sDst, sDstOff: Integer;
//  sScanLine: array [0 .. 255] of PRGBArray;
//  Src1, Src2: PRGBArray;
//  c, C1, C2: TRGB24;
//  y1, y2, y3, x3, iRed, iGrn, iBlu: Integer;
//  p1, p2, p3, p4, p5: PRGB24;
//begin
//  // ScanLine buffer for Source
//  sDst := Integer(Src.ScanLine[0]);
//  sDstOff := Integer(Src.ScanLine[1]) - sDst;
//  for i := 0 to Src.Height - 1 do
//  begin
//    sScanLine[i] := PRGBArray(sDst);
//    sDst := sDst + sDstOff;
//  end;
//  // ScanLine for Destiantion
//  sDst := NativeInt(Dest.ScanLine[0]);
//  y1 := sDst; // only for sharpening...
//  sDstOff := NativeInt(Dest.ScanLine[1]) - sDst;
//  // Ratio is same for width and height
//  Ratio := ((Src.Width - 1) shl 15) div Dest.Width;
//  py := 0;
//  for Y := 0 to Dest.Height - 1 do
//  begin
//    i := py shr 15;
//    if i > Src.Height - 1 then
//      i := Src.Height - 1;
//    Src1 := sScanLine[i];
//    if i < Src.Height - 1 then
//      Src2 := sScanLine[i + 1]
//    else
//      Src2 := Src1;
//    z2 := py and $7FFF;
//    iz2 := $8000 - z2;
//    px := 0;
//    for X := 0 to Dest.Width - 1 do
//    begin
//      x1 := px shr 15;
//
//      if x1 >= Src.Width - 1 then
//        x2 := x1
//      else
//        x2 := x1 + 1;
//      //x2 := x1 + 1;
//
//      C1 := Src1[x1];
//      C2 := Src2[x1];
//      z := px and $7FFF;
//      w2 := (z * iz2) shr 15;
//      w1 := iz2 - w2;
//      w4 := (z * z2) shr 15;
//      w3 := z2 - w4;
//      c.R := (C1.R * w1 + Src1[x2].R * w2 + C2.R * w3 + Src2[x2].R * w4) shr 15;
//      c.G := (C1.G * w1 + Src1[x2].G * w2 + C2.G * w3 + Src2[x2].G * w4) shr 15;
//      c.B := (C1.B * w1 + Src1[x2].B * w2 + C2.B * w3 + Src2[x2].B * w4) shr 15;
//      // Set destination pixel
//      PRGBArray(sDst)[X] := c;
//      inc(px, Ratio);
//    end;
//    sDst := sDst + sDstOff;
//    inc(py, Ratio);
//  end;
//
//  Exit; // Remove this to enable sharpening
//
//  // Sharpening...
//  y2 := y1 + sDstOff;
//  y3 := y2 + sDstOff;
//  for Y := 1 to Dest.Height - 2 do
//  begin
//    for X := 0 to Dest.Width - 3 do
//    begin
//      x1 := X * 3;
//      x2 := x1 + 3;
//      x3 := x1 + 6;
//      p1 := PRGB24(y1 + x1);
//      p2 := PRGB24(y1 + x3);
//      p3 := PRGB24(y2 + x2);
//      p4 := PRGB24(y3 + x1);
//      p5 := PRGB24(y3 + x3);
//      // -15 -11                       // -17 - 13
//      iRed := (p1.R + p2.R + (p3.R * -15) + p4.R + p5.R) div -11;
//      iGrn := (p1.G + p2.G + (p3.G * -15) + p4.G + p5.G) div -11;
//      iBlu := (p1.B + p2.B + (p3.B * -15) + p4.B + p5.B) div -11;
//      if iRed < 0 then
//        iRed := 0
//      else if iRed > 255 then
//        iRed := 255;
//      if iGrn < 0 then
//        iGrn := 0
//      else if iGrn > 255 then
//        iGrn := 255;
//      if iBlu < 0 then
//        iBlu := 0
//      else if iBlu > 255 then
//        iBlu := 255;
//      PRGB24(y2 + x2).R := iRed;
//      PRGB24(y2 + x2).G := iGrn;
//      PRGB24(y2 + x2).B := iBlu;
//    end;
//    inc(y1, sDstOff);
//    inc(y2, sDstOff);
//    inc(y3, sDstOff);
//  end;
//end;

procedure TForm1.acCloseWindowExecute(Sender: TObject);
begin
  Close;
end;

procedure TForm1.acFuzzyFinderExecute(Sender: TObject);
begin
  ACLGroupBox2.Visible := not ACLGroupBox2.Visible;
  if ACLGroupBox2.Visible then
    ACLSearchEdit1.SetFocus;
end;

procedure TForm1.ACLSearchEdit1Change(Sender: TObject);
begin
  if DirectoryExists(FCurrentDir) then
  begin
    DebouncedSearch(ACLSearchEdit1.Text);
  end;
end;

procedure TForm1.DebouncedSearch(const AText: string);
begin
  FLastQuery := AText;

  if Assigned(FDebounceTask) then
    FDebounceTask.Cancel;

  FDebounceTask := TTask.Run(procedure
  begin
    TThread.Sleep(150); // debounce delay

    if TTask.CurrentTask.Status = TTaskStatus.Canceled then
      Exit;

    TThread.Queue(nil, procedure
    begin
      // ensure user didn't type more meanwhile
      if FLastQuery = AText then
        FBridge.AsyncSearch(AText);
    end);
  end);
end;

procedure TForm1.DelayedStartup;
var
  hImagList16, hImagList32: NativeUInt;
  ShInfo1: TSHFileInfo;
  icHgt, icWid: Integer;
  repoPath: string;
begin
  hImagList32 := SHGetFileInfo('file.txt', FILE_ATTRIBUTE_NORMAL, ShInfo1,
    SizeOf(ShInfo1),
    SHGFI_LARGEICON or SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES);

  hImagList16 := SHGetFileInfo('file.txt', FILE_ATTRIBUTE_NORMAL, ShInfo1,
    SizeOf(ShInfo1),
    SHGFI_SMALLICON or SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES);

  FhImageList48 := hImagList16 + (hImagList16 - hImagList32);
  if ImageList_GetIconSize(FhImageList48, icHgt, icWid) and (icHgt = 48) then
    FIconSize := 48
  else
  begin
    FhImageList48 := hImagList32;
    if ImageList_GetIconSize(hImagList32, icHgt, icWid) then
      FIconSize := icHgt
    else
      FIconSize := 32;
  end;

  Items := TList.Create;
  // Max thumbnail size...
  ThumbSizeW := 255;
  ThumbSizeH := 255;
  rkView1.CellWidth := ThumbSizeW + 20;
  rkView1.CellHeight := ThumbSizeH + 40;
  CellJpeg := TJpegImage.Create;
  CellJpeg.Performance := jpBestSpeed;
  GenCellColors;
  CellStyle := -1;
  PoolSize := 0;
  MaxPool := Round(((Screen.Width * Screen.Height) * 3) * 1.5);
  Items := TList.Create;
  ThumbsPool := TList.Create;

  TrackBar1.Min := 31;
  TrackBar1.Max := 255;
  TrackBar1.Position := 127;

  OpenDir('t:\users\vhanl\pictures\kaliman\firefly');

  MPlayer := TMPVBasePlayer.Create;
  MPlayer.OnProgress := OnMPlayerProgress;
  MPlayer.OnStateChged := OnMPlayerStateChanged;
  MPlayer.InitPlayer(IntToStr(pnlMPV.Handle), '', '', '', True, 0.05); //0.05 for smooth 20fps progress events


  // thumbnails repo
  repoPath := TPath.Combine(TPath.GetCachePath, 'ThumbCache');

  if not DirectoryExists(repoPath) then
    ForceDirectories(repoPath);

  VirtualExplorerEasyListview1.ThumbsManager.StorageRepositoryFolder := IncludeTrailingPathDelimiter(repoPath);
  VirtualMultiPathExplorerEasyListview1.ThumbsManager.StorageRepositoryFolder := IncludeTrailingPathDelimiter(repoPath);

  VirtualExplorerEasyListview1.IncrementalSearch.Enabled  := True;     // for selecting/jumping to a file that matches

  // sort by date
//  VirtualExplorerEasyListview1.Header.Columns[3].SortDirection := esdDescending;
//  VirtualExplorerEasyListview1.Sort.SortAll;
  VirtualExplorerEasyListview1.DefaultSortColumn := 3;
  VirtualExplorerEasyListview1.DefaultSortDir := esdDescending;

  // Fuzzy Search
  FFF := TDelphiFFF.Create;
  FBridge := TFFFUIBridge.Create(FFF, OnSearchUpdate);

//  ListView1.OwnerData := True;
//  ListView1.ViewStyle := vsReport;
//  ListView1.Columns.Clear;
//  ListView1.Columns.Add.Caption := 'Name';
//  ListView1.Columns.Add.Caption := 'Path';
//  ListView1.Columns.Add.Caption := 'Score';
  SetLength(FCachedResults, 0);

  VirtualMultiPathExplorerEasyListview1.BeginUpdate;
  try
    VirtualMultiPathExplorerEasyListview1.Active := True;
//    VirtualMultiPathExplorerEasyListview1.Options := VirtualMultiPathExplorerEasyListview1.Options + [elothre
    with VirtualMultiPathExplorerEasyListview1.Header.Columns.AddCustom(TExplorerColumn) as TExplorerColumn do
    begin
      Caption := 'Score';
      Width := 80;
    end;
  finally
    VirtualMultiPathExplorerEasyListview1.EndUpdate();
  end;

  rkAeroTabs1.tabstyle := tsModernRect;
//  rkAeroTabs1.TitleBar := True;

  RegisterWithSeer;
end;

procedure TForm1.DirectoryScan(const APath: string);
begin
  if not DirectoryExists(APath) then
    Exit;

//  FCurrentDir := APath;

  SetLength(FCachedResults, 0);
//  ListView1.Items.Count := 0;
//  ListView1.Invalidate;
  VirtualMultiPathExplorerEasyListview1.BeginUpdate;
  try
    VirtualMultiPathExplorerEasyListview1.Clear;
  finally
    VirtualMultiPathExplorerEasyListview1.EndUpdate();
  end;

  FFF.ScanDirectoryAsync(APath);
end;

procedure TForm1.ACLShellTreeView1Click(Sender: TObject);
begin
  if Directory <> IncludeTrailingPathDelimiter(ACLShellTreeView1.SelectedPath)  then
    OpenDir(ACLShellTreeView1.SelectedPath);
end;

procedure TForm1.ACLSliderMPVMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FIsSeeking := True;
end;

procedure TForm1.ACLSliderMPVMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(MPlayer) then
    MPlayer.CurrentSeconds := ACLSliderMPV.Position;

  FIsSeeking := False;
end;

procedure TForm1.acTogglePreviewExecute(Sender: TObject);
begin
  gbPreview.Visible := not gbPreview.Visible;
end;

procedure TForm1.acToggleSidebarExecute(Sender: TObject);
begin
  gbSidebar.Visible := not gbSidebar.Visible;
end;

procedure TForm1.BiResample(Src, Dest: TBitmap; Sharpen: Boolean);
type
  // Define pointer to a single RGB pixel
  PRGB24 = ^TRGB24;
  TRGB24 = record
    B, G, R: Byte;
  end;

  // FIX 1: Change array bound to a large value to prevent Range Check Errors
  // This allows accessing indices > 0 without disabling Range Checking.
  PRGBArray = ^TRGBArray;
  TRGBArray = array [0 .. MaxInt div SizeOf(TRGB24) - 1] of TRGB24;

var
  X, Y, px, py: Integer;
  i, x1, x2: Integer;
  z, z2, iz2: Integer;
  w1, w2, w3, w4: Integer;
  Ratio: Integer;

  // FIX 2: Use a dynamic array instead of fixed [0..255]
  // This supports images of ANY height and avoids stack corruption.
  SrcScanLines: array of PRGBArray;
  DestScanLines: array of PRGBArray;

  Src1, Src2: PRGBArray;
  DestRow: PRGBArray;
  c, C1, C2: TRGB24;

  // Variables for sharpening
  Row1, Row2, Row3: PRGBArray;
  iRed, iGrn, iBlu: Integer;
begin
  // Basic validation
  if (Src = nil) or (Dest = nil) or
     (Src.Width < 1) or (Src.Height < 1) or
     (Dest.Width < 1) or (Dest.Height < 1) then Exit;

  Src.PixelFormat := pf24bit;
  Dest.PixelFormat := pf24bit;

  // FIX 3: Safely cache Source ScanLines
  // Using ScanLine[i] is safer than manual pointer arithmetic for compatibility
  // with top-down vs bottom-up bitmaps and 64-bit pointers.
  SetLength(SrcScanLines, Src.Height);
  for i := 0 to Src.Height - 1 do
    SrcScanLines[i] := Src.ScanLine[i];

  // Ratio calculation
  Ratio := ((Src.Width - 1) shl 15) div Dest.Width;
  py := 0;

  for Y := 0 to Dest.Height - 1 do
  begin
    // Calculate Y index in source
    i := py shr 15;
    if i > Src.Height - 1 then i := Src.Height - 1;

    Src1 := SrcScanLines[i];

    // Get next row for interpolation
    if i < Src.Height - 1 then
      Src2 := SrcScanLines[i + 1]
    else
      Src2 := Src1;

    z2 := py and $7FFF;
    iz2 := $8000 - z2;

    // Get direct pointer to Destination row
    DestRow := Dest.ScanLine[Y];

    px := 0;
    for X := 0 to Dest.Width - 1 do
    begin
      // Calculate X index
      x1 := px shr 15;

      // Boundary check
      if x1 >= Src.Width - 1 then
      begin
        x1 := Src.Width - 1;
        x2 := x1;
      end
      else
        x2 := x1 + 1;

      // Fetch pixels (No Range Check Error due to FIX 1)
      C1 := Src1[x1];
      C2 := Src2[x1];

      // Calculate weights
      z := px and $7FFF;
      w2 := (z * iz2) shr 15;
      w1 := iz2 - w2;
      w4 := (z * z2) shr 15;
      w3 := z2 - w4;

      // Bilinear Interpolation Formula
      c.R := (C1.R * w1 + Src1[x2].R * w2 + C2.R * w3 + Src2[x2].R * w4) shr 15;
      c.G := (C1.G * w1 + Src1[x2].G * w2 + C2.G * w3 + Src2[x2].G * w4) shr 15;
      c.B := (C1.B * w1 + Src1[x2].B * w2 + C2.B * w3 + Src2[x2].B * w4) shr 15;

      DestRow[X] := c;
      Inc(px, Ratio);
    end;
    Inc(py, Ratio);
  end;

  // ---------------------------------------------------------
  // Sharpening Logic
  // ---------------------------------------------------------
  if not Sharpen then Exit;

  // Cache Destination lines for random access
  SetLength(DestScanLines, Dest.Height);
  for i := 0 to Dest.Height - 1 do
    DestScanLines[i] := Dest.ScanLine[i];

  // Apply 3x3 Sharpen Kernel
  for Y := 1 to Dest.Height - 2 do
  begin
    Row1 := DestScanLines[Y - 1];
    Row2 := DestScanLines[Y];
    Row3 := DestScanLines[Y + 1];

    for X := 0 to Dest.Width - 3 do
    begin
      // The original logic used byte offsets X*3, X*3+3, X*3+6.
      // This maps to array indices X, X+1, X+2.
      // The kernel centers on Row2[X+1].

      iRed := (Row1[X].R + Row1[X+2].R + (Row2[X+1].R * -15) + Row3[X].R + Row3[X+2].R) div -11;
      iGrn := (Row1[X].G + Row1[X+2].G + (Row2[X+1].G * -15) + Row3[X].G + Row3[X+2].G) div -11;
      iBlu := (Row1[X].B + Row1[X+2].B + (Row2[X+1].B * -15) + Row3[X].B + Row3[X+2].B) div -11;

      // Clamp values to Byte range 0..255
      if iRed < 0 then iRed := 0 else if iRed > 255 then iRed := 255;
      if iGrn < 0 then iGrn := 0 else if iGrn > 255 then iGrn := 255;
      if iBlu < 0 then iBlu := 0 else if iBlu > 255 then iBlu := 255;

      // Write result back to the center pixel
      Row2[X+1].R := iRed;
      Row2[X+1].G := iGrn;
      Row2[X+1].B := iBlu;
    end;
  end;
end;

procedure TForm1.OpenDir(path: string = '');
var
  Entry: PItemData;
  SR: TSearchRec;
  n: Integer;
  SFI: TSHFileInfo;
  FName: string;
begin
  Directory  := path;

  if Directory.IsEmpty and FileOpenDialog1.Execute then
  begin
    Directory := FileOpenDialog1.FileName;
  end;

  if Directory <> '' then
  begin
      if Directory[Length(Directory)] <> '\' then
      Directory := Directory + '\';
    VirtualExplorerEasyListview1.RootFolderCustomPath := Directory;
  end;

  Exit;

  if Directory <> '' then
  begin
    Stop;
    ClearThumbs;
    ClearThumbsPool;
    rkView1.ViewIdx := -1;
    rkView1.Clear;
    rkView1.BeginUpdate;
    Vcl.Forms.Application.ProcessMessages;
    if Directory[Length(Directory)] <> '\' then
      Directory := Directory + '\';
    if FindFirst(Directory + '*.*', faAnyFile { - faDirectory } , SR) = 0 then
    begin
      Items.Capacity := 1000;
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          New(Entry);
          Entry.Name := SR.Name;
          Entry.Size := SR.Size;
          Entry.Modified := FileDateToDateTime(SR.Time);
          Entry.IWidth := 0;
          Entry.IHeight := 0;
          Entry.ThumbWidth := 0;
          Entry.ThumbHeight := 0;
          Entry.Dir := ((SR.Attr and faDirectory) <> 0);
          Entry.GotThumb := False;
          Entry.Image := nil;
          FName := Directory + SR.Name;
          SHGetFileInfo(PChar(FName), FILE_ATTRIBUTE_NORMAL, SFI,
            SizeOf(TSHFileInfo), SHGFI_LARGEICON or SHGFI_SYSICONINDEX);
          Entry.ImgIdx := SFI.iIcon;
          n := Items.Add(Entry);
          if n <> -1 then
            rkView1.Items.Add(n);
        end;
      until FindNext(SR) <> 0;
      FindClose(SR);
      Items.Capacity := Items.Count;
    end;
    FCurrentDir := Directory;
    DirectoryScan(FCurrentDir);
  end;
  rkView1.EndUpdate;
  DoSort;
  SetThumbSize(TrackBar1.Position, False);
  if ThumbThr = nil then
  begin
    ThreadDone := False;
    ThumbThr := ThumbThread.Create(rkView1, Items);
  end;
  UpdateStatus;
end;

procedure TForm1.CMProgress(var message: TMessage);
begin
  if message.LParam = 100 then
    message.LParam := 0;
  // vprothumbs.Visible := message.LParam > 0;
  // vprothumbs.Position := message.LParam;
end;

procedure TForm1.CMUpdateView(var message: TMessage);
begin
  rkView1.Invalidate;
end;


procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  // Override the Win32 window class name
  Params.WinClassName := APP_WINDOW_CLASS;
end;

procedure WinGradient(DC: HDC; ARect: TRect; AColor2, AColor1: TColor);
var
  Vertexs: array [0 .. 1] of TTriVertex;
  GRect: TGradientRect;
begin
  Vertexs[0].X := ARect.Left;
  Vertexs[0].Y := ARect.Top;
  Vertexs[0].Red := (AColor1 and $000000FF) shl 8;
  Vertexs[0].Green := (AColor1 and $0000FF00);
  Vertexs[0].Blue := (AColor1 and $00FF0000) shr 8;
  Vertexs[0].alpha := 0;
  Vertexs[1].X := ARect.Right;
  Vertexs[1].Y := ARect.Bottom;
  Vertexs[1].Red := (AColor2 and $000000FF) shl 8;
  Vertexs[1].Green := (AColor2 and $0000FF00);
  Vertexs[1].Blue := (AColor2 and $00FF0000) shr 8;
  Vertexs[1].alpha := 0;
  GRect.UpperLeft := 0;
  GRect.LowerRight := 1;
  GradientFill(DC, @Vertexs, 2, @GRect, 1, GRADIENT_FILL_RECT_V);
end;
procedure TForm1.ImgView321MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Button = mbLeft then
  begin
    FDragging := True;
    FLastX := X;
    FLastY := Y;
    ImgView321.Cursor := crSizeAll;
  end;
end;

procedure TForm1.ImgView321MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer; Layer: TCustomLayer);
begin
  if FDragging then
  begin
    UpdatePan(X - FLastX, Y - FLastY);
    FLastX := X;
    FLastY := Y;
  end;
end;

procedure TForm1.ImgView321MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Button = mbLeft then
  begin
    FDragging := False;
    ImgView321.Cursor := crHandPoint;
  end;
end;

procedure TForm1.ImgView321MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if ssCtrl in Shift then
  begin
    UpdateZoom(WheelDelta);
    Handled := True;
  end;
end;

procedure TForm1.ItemPaintBasic(Canvas: TCanvas; R: TRect;
  State: TsvItemState);
var
  c: TColor;
begin
  Canvas.Brush.Style := bsClear;
  if (State = svSelected) or (State = svHot) then
  begin
    if (rkView1.Focused) and (State = svSelected) then
    begin
      Canvas.Pen.Color := cSelected;
      WinGradient(Canvas.Handle, R, cGSelectedStart, cGSelectedEnd);
    end
    else if (State = svHot) then
    begin
      Canvas.Pen.Color := cHot;
      WinGradient(Canvas.Handle, R, cGHotStart, cGHotEnd);
    end
    else
    begin
      Canvas.Pen.Color := cDisabled;
      WinGradient(Canvas.Handle, R, cGDisabledStart, cGDisabledEnd);
    end;
    Canvas.Rectangle(R);
    if (rkView1.Focused) then
      c := cShadeSelect
    else
      c := cShadeDisabled;
    Canvas.Pen.Color := c;
    Canvas.MoveTo(R.Left + 1, R.Top + 2);
    Canvas.LineTo(R.Left + 1, R.Bottom - 2);
    Canvas.LineTo(R.Right - 2, R.Bottom - 2);
    Canvas.LineTo(R.Right - 2, R.Top + 1);
    Canvas.Pen.Style := psSolid;
    Canvas.Pixels[R.Left, R.Top] := c;
    Canvas.Pixels[R.Left, R.Bottom - 1] := c;
    Canvas.Pixels[R.Right - 1, R.Top] := c;
    Canvas.Pixels[R.Right - 1, R.Bottom - 1] := c;
  end;
end;

procedure TForm1.ListView1Data(Sender: TObject; Item: TListItem);
var
  R: TSearchResult;
begin

  if (Item.Index < 0) or (Item.Index >= Length(FCachedResults)) then
    Exit;

  R := FCachedResults[Item.Index];

  Item.Caption := ExtractFileName(R.Path);
  Item.SubItems.Add(ExtractFilePath(R.Path));
  Item.SubItems.Add(R.Score.ToString);
end;

procedure TForm1.OnSearchUpdate(const AResults: TArray<TSearchResult>);
var
  I: Integer;
  NS: TNameSpace; //MPShellUtillities
begin
//  if Assigned(AResults) then
//    FCachedResults := Copy(AResults)
//  else
//    SetLength(FCachedResults, 0);
//
//  ListView1.Items.Count := Length(FCachedResults);
//  ListView1.Invalidate;

// Let's move to VirtualMultiPathExplorerEasyListview1
  VirtualMultiPathExplorerEasyListview1.BeginUpdate;
  try
    VirtualMultiPathExplorerEasyListview1.Clear;
    if Assigned(AResults) then
    begin
      FCachedResults := Copy(AResults);
      // Disable sorting while adding for efficiency
      VirtualMultiPathExplorerEasyListview1.Sort.LockoutSort := True;
      for I := 0 to High(FCachedResults) do
      begin
        NS := TNameSpace.Create(PathToPIDL(FCachedResults[I].Path), nil);
        VirtualMultiPathExplorerEasyListview1.AddCustomItem(nil, NS, True).Tag := I;
      end;
    end
    else
      SetLength(FCachedResults, 0);
  finally
    VirtualMultiPathExplorerEasyListview1.Sort.LockoutSort := False;
    VirtualMultiPathExplorerEasyListview1.EndUpdate();
  end;
end;

procedure TForm1.GenCellColors;
begin
  cHot := $00FDDE99;
  cGHotStart := $00FDF5E6;
  cGHotEnd := $00FDFBF6;
  cSelected := $00FDCE99;
  cGSelectedStart := $00FCEFC4;
  cGSelectedEnd := $00FDF8EF;
  cShadeSelect := $00F8F3EA;
  cDisabled := $00D9D9D9;
  cGDisabledStart := $00EAE9E9;
  cGDisabledEnd := $00FCFBFB;
  cShadeDisabled := $00F6F5F5;
  cGHeaderStart := $00F9F9F9;
  cGHeaderEnd := $00FEFEFE;
  cGHeaderHotStart := $00FFEDBD;
  cGHeaderHotEnd := $00FFF7E3;
  cGHeaderSelStart := $00FCEABA;
  cGHeaderSelEnd := $00FCF4E0;
  cBackground := clWindow; ;
  cLineHighLight := $00FEFBF6;
  CellBkgColor := clWindow;
  CellBrdColor[False, False] := cDisabled;
  CellBrdColor[False, true] := cDisabled;
  CellBrdColor[true, False] := $00B5B5B5;
  CellBrdColor[true, true] := cSelected;
end;

function TForm1.Running: Boolean;
begin
  Result := ThumbThr <> nil;
end;

procedure TForm1.Start;
begin
  if Running then
    Exit;
  ThreadDone := False;
  ThumbThr := ThumbThread.Create(rkView1, Items);
end;

procedure TForm1.Stop;
begin
  if ThumbThr <> nil then
  begin
    ThumbThr.Terminate;
    ThumbThr.WaitFor;
    ThumbThr.Free;
    ThumbThr := nil;
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  SetThumbSize(TrackBar1.Position, False);
end;

function CompareNatural(s1, s2: string): Integer;
  function ExtractNr(n: Integer; var Txt: string): Int64;
  begin
    while (n <= Length(Txt)) and (Txt[n] >= '0') and (Txt[n] <= '9') do
      n := n + 1;
    Result := StrToInt64Def(Copy(Txt, 1, n - 1), 0);
    Delete(Txt, 1, (n - 1));
  end;

var
  B: Boolean;
begin
  Result := 0;
  s1 := LowerCase(s1);
  s2 := LowerCase(s2);
  if (s1 <> s2) and (s1 <> '') and (s2 <> '') then
  begin
    B := False;
    while (not B) do
    begin
      if ((s1[1] >= '0') and (s1[1] <= '9')) and
        ((s2[1] >= '0') and (s2[1] <= '9')) then
        Result := Sign(ExtractNr(1, s1) - ExtractNr(1, s2))
      else
        Result := Sign(Integer(s1[1]) - Integer(s2[1]));
      B := (Result <> 0) or (Min(Length(s1), Length(s2)) < 2);
      if not B then
      begin
        Delete(s1, 1, 1);
        Delete(s2, 1, 1);
      end;
    end;
  end;
  if Result = 0 then
  begin
    if (Length(s1) = 1) and (Length(s2) = 1) then
      Result := Sign(Integer(s1[1]) - Integer(s2[1]))
    else
      Result := Sign(Length(s1) - Length(s2));
  end;
end;

function SortItem(List: TIntList; Index1, Index2: Integer): Integer;
var
  Item1, Item2: PItemData;
begin
  Item1 := Form1.Items[List[Index1]];
  Item2 := Form1.Items[List[Index2]];
  if Item1.Dir and Item2.Dir then
    Result := CompareNatural(Item1.Name, Item2.Name)
  else if Item1.Dir then
    Result := -1
  else if Item2.Dir then
    Result := 1
  else
    Result := CompareNatural(Item1.Name, Item2.Name);
end;

procedure TForm1.DoSort;
begin
  rkView1.Items.CustomSort(SortItem);
  rkView1.UpdateView;
  rkView1.Invalidate;
end;

procedure TForm1.SendPathToSeer;
var
  SeerWnd: HWND;
  CDS: TCOPYDATASTRUCT;
  Path: string;
  ResultPtr: NativeUInt;
begin
  SeerWnd := FindWindow(PChar(SEER_CLASS_NAME), nil);
  if SeerWnd = 0 then
    Exit;

  Path := FCurrentSelectedItem;// GetSelectedFilePath;

  CDS.dwData := SEER_RESPONSE_PATH;
  CDS.cbData := (Length(Path) + 1) * SizeOf(Char);
  CDS.lpData := PChar(Path);

  if SendMessageTimeout(
       SeerWnd,
       WM_COPYDATA,
       0,
       LPARAM(@CDS),
       SMTO_ABORTIFHUNG or SMTO_BLOCK,
       SEER_TIMEOUT_MS,
       @ResultPtr
     ) = 0 then
  begin
    // Timeout or hung Seer — do nothing
    // DO NOT retry
    OutputDebugString('Seer WM_COPYDATA timeout');
  end;
end;

procedure TForm1.SetThumbSize(Value: Integer; UpdateTrackbar: Boolean);
var
  W, H: Integer;
begin
  case Value of
    32 .. 63:
      CellJpeg.Scale := jsQuarter;
    64 .. 127:
      CellJpeg.Scale := jsHalf;
    128 .. 255:
      CellJpeg.Scale := jsFullSize;
  else
    CellJpeg.Scale := jsEighth;
  end;
  W := Value + 10;
  H:= Value + 10 + 16;
  HSX := (W - 70) shr 1;
  rkView1.CellWidth := W;
  rkView1.CellHeight := H;
  CellScale := Value;
  if UpdateTrackbar then
  begin
    TrackBar1.OnChange := nil;
    TrackBar1.Position := CellScale;
//    TrackBar1.OnChange := tbSizeChange;
  end;
  rkView1.CalcView(False);
  if not UpdateTrackbar then
    rkView1.SetAtTop(-1, vIdx);
end;

function CalcThumbSize(W, H, TW, TH: Cardinal): Cardinal;
begin
  Result := 0;
  if (W = 0) or (H = 0) then
    Exit;
  if (W < TW) and (H < TH) then
    Result := (W shl 16) + H
  else
  begin
    if W > H then
    begin
      if W < TW then
        TW := W;
      Result := (TW shl 16) + Trunc(TW * H / W);
      if (Result and $FFFF) > TH then
        Result := (Trunc(TH * W / H) shl 16) + TH;
    end
    else
    begin
      if H < TH then
        TH := H;
      Result := (Trunc(TH * W / H) shl 16) + TH;
      if ((Result shr 16) and $FFFF) > TW then
        Result := (TW shl 16) + Trunc(TW * H / W);
    end;
  end;
end;
function TForm1.ThumbBmp(Idx: Integer): TBitmap;
var
  i, n, sf: Integer;
  p: PCacheItem;
  T: PItemData;
  Bmp, tmp: TBitmap;
  pt: TPoint;
  c: Cardinal;
  Oldest: TDateTime;
begin
  Result := nil;
  // if we have thumbs, see if we can find it...
  if ThumbsPool.Count > 0 then
  begin
    i := ThumbsPool.Count - 1;
    while (i >= 0) and (PCacheItem(ThumbsPool[i]).Idx <> Idx) do
      i := i - 1;
    if i <> -1 then
    begin
      p := ThumbsPool[i];
      if (p.Idx = Idx) then
      begin
        if (p.Scale = CellScale) then
        begin
          p.Age := Now;
          Result := p.Bmp
        end
        else
        begin
          PoolSize := PoolSize - p.Size;
          p.Bmp.Free;
          Dispose(p);
          ThumbsPool.Delete(i);
        end;
      end;
    end;
  end;
  // if we dont have a thumb, make one...
  if Result = nil then
  begin
    T := Items[Idx];
    if T.Image <> nil then
    begin
      TMemoryStream(T.Image).Position := 0;

      sf := Trunc(Min(T.ThumbWidth / CellScale, T.ThumbHeight / CellScale));
      if sf < 0 then
        sf := 0;
      case sf of
        0 .. 1:
          CellJpeg.Scale := jsFullSize;
        2 .. 3:
          CellJpeg.Scale := jsHalf;
        4 .. 7:
          CellJpeg.Scale := jsQuarter;
      else
        CellJpeg.Scale := jsEighth;
      end;
      CellJpeg.LoadFromStream(TMemoryStream(T.Image));

      Bmp := TBitmap.Create;
      Bmp.PixelFormat := pf24bit;
      c := CalcThumbSize(CellJpeg.Width, CellJpeg.Height, CellScale, CellScale);
      pt.X := c shr 16;
      pt.Y := c and $FFFF;
      if pt.X <> CellJpeg.Width then
      begin
        tmp := TBitmap.Create;
        tmp.PixelFormat := pf24bit;
        tmp.Width := CellJpeg.Width;
        tmp.Height := CellJpeg.Height;
        tmp.Canvas.Draw(0, 0, CellJpeg);
        Bmp.Width := pt.X;
        Bmp.Height := pt.Y;
        if (Bmp.Width > 4) and (Bmp.Height > 4) then
          BiResample(tmp, Bmp, False)
        else
          Bmp.Canvas.StretchDraw(Rect(0, 0, pt.X, pt.Y), tmp);
        tmp.Free;
      end
      else
      begin
        Bmp.Width := CellJpeg.Width;
        Bmp.Height := CellJpeg.Height;
        Bmp.Canvas.Draw(0, 0, CellJpeg);
      end;
      New(p);
      p.Idx := Idx;
      p.Size := (Bmp.Width * Bmp.Height) * 3;
      p.Age := Now;
      p.Scale := CellScale;
      p.Bmp := Bmp;
      ThumbsPool.Add(p);
      PoolSize := PoolSize + p.Size;
      Result := p.Bmp;
      // Purge thumbs if needed
      while (PoolSize > MaxPool) and (ThumbsPool.Count > 0) do
      begin
        Oldest := Now;
        n := 0;
        for i := 0 to ThumbsPool.Count - 1 do
        begin
          p := ThumbsPool[i];
          if p.Age <= Oldest then
          begin
            Oldest := p.Age;
            n := i;
          end;
        end;
        Assert(n >= 0);
        p := ThumbsPool[n];
        PoolSize := PoolSize - p.Size;
        p.Bmp.Free;
        Dispose(p);
        ThumbsPool.Delete(n);
      end;
    end;
  end;
end;

procedure TForm1.ClearThumbs;
var
  i: Integer;
  Item: PItemData;
begin
  rkView1.Items.Clear;
  for i := Items.Count - 1 downto 0 do
  begin
    Item := Items[i];
    if Assigned(Item) then
      if Item.Size <> 0 then
        Item.Image.Free;
    Dispose(Item);
  end;
  Items.Clear;
end;

procedure TForm1.ClearThumbsPool;
var
  i: Integer;
  Thumb: PCacheItem;
begin
  for i := ThumbsPool.Count - 1 downto 0 do
  begin
    Thumb := ThumbsPool[i];
    if Thumb.Bmp <> nil then
      Thumb.Bmp.Free;
    Dispose(Thumb);
  end;
  ThumbsPool.Clear;
  PoolSize := 0;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  AppServices.CBAppStartup1.NotifyUIVisible;

  SetDarkMode(Handle, True);

  //DelayedStartup is triggered to initialize delayed things
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  i: Integer;
  Item: PItemData;
begin
  if Assigned(FDebounceTask) then
    FDebounceTask.Cancel;
  FBridge.Free;
  FFF.Free;

  MPlayer.Free;
  CellJpeg.Free;
  for i := Items.Count - 1 downto 0 do
  begin
    Item := Items[i];
    if Item.Size <> 0 then
      Item.Image.Free;
    Dispose(Item);
  end;
  ThumbsPool.Free;
  Items.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
var
  ImW, ImH: Integer;
begin
  ImH := ClientHeight;
  ImW := MulDiv(ImH, 3, 4);

  gbPreview.SetBounds(ClientWidth - ImW, 0, ImW, ImH);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  VirtualExplorerEasyListview1.Active := True;
  VirtualExplorerEasyListview1.SetFocus;
end;

procedure TForm1.rkAeroTabs1AddClick(Sender: TObject);
begin
  OpenDir;
end;

procedure TForm1.rkAeroTabs1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
  SC_DRAGMOVE = $F012;
begin
  ReleaseCapture;
  Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
end;

procedure TForm1.rkSmartPath1PathChanged(Sender: TObject);
begin
  OpenDir(rkSmartPath1.Path);
end;

procedure TForm1.rkView1CellPaint(Sender: TObject; Canvas: TCanvas; Cell: TRect;
  IdxA, Idx: Integer; State: TsvItemState);
var
  X, Y: Integer;
  f, s: Boolean;
  R: TRect;
  TW, TH: Integer;
  Txt: string;
  Item: PItemData;
  c: Cardinal;
begin
  Item := PItemData(Items[Idx]);
  if (Item.ImgIdx <> -1) and (Item.Image = nil) then
    c := CalcThumbSize(FIconSize, FIconSize, CellScale, CellScale)
  else
    c := CalcThumbSize(Item.ThumbWidth, Item.ThumbHeight, CellScale, CellScale);
  TW := c shr 16;
  TH := c and $FFFF;
  ItemPaintBasic(Canvas, Cell, State);
  f := rkView1.Focused;
  s := State = svSelected;

  X := Cell.Left + ((Cell.Right - (Cell.Left + TW)) shr 1);
  if Item.IsIcon then
    Y := Cell.Top + ((Cell.Right - (Cell.Left + TW)) shr 1)
  else
    Y := (Cell.Bottom - TH) - 21;

  if (Item.IsIcon) and (Item.ImgState = 0) then
  begin
    R := Cell;
    R.Bottom := R.Bottom - 16;
    InflateRect(R, -5, -5);
    Canvas.Pen.Color := CellBrdColor[f, s];
    Canvas.Brush.Color := $2d2d2d; // background color
    Canvas.Brush.Style := bsSolid;
    Canvas.Rectangle(R);
    Canvas.Brush.Style := bsClear;
  end;

  if (Item.Image <> nil) and (Item.GotThumb) then
    Canvas.Draw(X, Y, ThumbBmp(Idx))
  else
    ImageList_Draw(FhImageList48, Item.ImgIdx, Canvas.Handle, X, Y,
      ILD_TRANSPARENT);

  if (not Item.IsIcon) and (not Item.Dir) then
  begin
    R.Left := X;
    R.Top := Y;
    R.Right := X + TW;
    R.Bottom := Y + TH;
    Canvas.Pen.Color := CellBrdColor[f, s];
    InflateRect(R, 2, 2);
    Canvas.Rectangle(R);
    Canvas.Pen.Color := clWhite;
    InflateRect(R, -1, -1);
    Canvas.Rectangle(R);
  end;

  Canvas.Font.Color := clWhite;//Black;
  R := Cell;
  R.Top := R.Bottom - (16);
  Txt := Item.Name;
  DrawText(Canvas.Handle, PChar(Txt), Length(Txt), R,
    DT_END_ELLIPSIS or DT_SINGLELINE or DT_NOPREFIX or DT_CENTER);
end;

procedure TForm1.rkView1DblClick(Sender: TObject);
var
  Thumb: PItemData;
  Pt: TPoint;
begin
  GetCursorPos(Pt);
  Pt := rkView1.ScreenToClient(Pt);

  var i := rkView1.ItemAtXY(Point(Pt.X, Pt.Y), False);
  if (i <> - 1) then
  begin
      Thumb := Items[rkView1.Items[i]];
      if DirectoryExists(IncludeTrailingPathDelimiter(FCurrentDir) + Thumb.Name) then
        OpenDir(IncludeTrailingPathDelimiter(FCurrentDir) + Thumb.Name)
      else
        ShellExecute(0, 'OPEN', PChar(IncludeTrailingPathDelimiter(FCurrentDir) + Thumb.Name), nil, nil , SW_SHOWNORMAL);

  end;

end;

procedure TForm1.rkView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  Thumb: PItemData;
begin
  vIdx := rkView1.ViewIdx;
  i := rkView1.ItemAtXY(Point(X, Y), False);

//  if i <> -1 then
//  begin
//    Thumb := Items[rkView1.Items[i]];
//    Label2.Caption := Thumb.Name;
//
//    if Button <> TMouseButton.mbLeft then Exit;
//    FMouseDownItemIndex := i;
//
//  // preview images
//    var afile := PChar(IncludeTrailingPathDelimiter(FCurrentDir) + Thumb.Name);
//    if not DirectoryExists(afile) then
//    begin
//
//      var ft := DetectFileKind(afile);
//      if (ft.Kind = fkPng) or (ft.Kind = fkJpeg) or (ft.Kind = fkBmp) or (ft.Kind = fkGif) or (ft.Kind = fkWebp) then
//      begin
//        if Panel1.Visible then
//          Panel1.Visible := False;
//        try
//          //EsImage1.Picture.LoadFromFile(afile);
//          ImgView321.Bitmap.LoadFromFile(aFile);
//        except
//          ImgView321.Bitmap.Assign(nil);
//        end;
//      end
//      else
//      begin
//        var vt := DetectMpvContainer(aFile);
//        if (vt = mcMp4) or (vt = mcMov) or (vt = mcMkv) or (vt = mcWebm) or (vt = mcAvi) or (vt = mcMpegPs) or (vt = mcFlv) or (vt = mcWmv) or (vt = mcOgg)
//         then
//         begin
//            if not Panel1.Visible then Panel1.Visible := True;
//            MPlayer.OpenFile(afile);
//         end
//        else
//        begin
//          var at := DetectMpvAudio(aFile);
//          if at = akMp3 then
//          begin
//            if not Panel1.Visible then Panel1.Visible := True;
//            MPlayer.OpenFile(afile);
//          end;
//        end;
//      end;
//    end;
//
//
//
//  end
//  else
//    Label2.Caption := '';

end;

procedure TForm1.rkView1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Thumb: PItemData;
begin
  if Button <> TMouseButton.mbLeft then Exit;

  var i := rkView1.ItemAtXY(Point(X, Y), False);
  if (i <> - 1) and (FMouseDownItemIndex = i) then
  begin
    // double click on item
    if ssDouble in Shift then
    begin
      Thumb := Items[rkView1.Items[i]];
      ShellExecute(0, 'OPEN', PChar(IncludeTrailingPathDelimiter(FCurrentDir) + Thumb.Name), nil, nil , SW_SHOWNORMAL);
    end;
  end;


  FMouseDownItemIndex := -1;
end;

procedure TForm1.rkView1Selecting(Sender: TObject; Count: Integer);
begin
  UpdateStatus;
end;

{ ThumbThread }

constructor ThumbThread.Create(View: TrkView; Items: TList);
begin
  ViewLink := View;
  ItemsLink := Items;
  FreeOnTerminate := False;
  inherited Create(False);
  Priority := tpLower;
end;

//procedure ThumbThread.Execute;
//var
//  Cnt, i: Integer;
//  PThumb: PItemData;
//  Old: Integer;
//  InView: Integer;
//  ShellFolder, DesktopShellFolder: IShellFolder;
//  XtractImage: IExtractImage;
//  XtractImage2: IExtractImage2;
//  XtractIcon: IExtractIcon;
//  fileShellItemImage: IShellItemImageFactory;
//  ImageFactory: IShellItemImageFactory;
//  Bmp: TBitmap;
//  Path: string;
//  Eaten: DWord;
//  PIDL: PItemIDList;
//  RunnableTask: IRunnableTask;
//  Flags: DWord;
//  Buf: array [0 .. MAX_PATH * 4] of WideChar;
//  BmpHandle: HBITMAP;
//  Atribute, Priority: DWord;
//  GetLocationRes: HResult;
//  ThumbJPEG: TJpegImage;
//  MS: TMemoryStream;
//  ASize: TSize;
//  FName: string;
//  p, pro: Integer;
//  PV: Single;
//  IIdx: Integer;
//  IFlags: Cardinal;
//  SIcon, LIcon: HIcon;
//  IconS, IconL: TIcon;
//  Done: Boolean;
//  Res: HResult;
//  Colordepth: Cardinal;
//  IsVistaOrLater: Boolean;
//begin
//  inherited;
//  if (ViewLink.Items.Count = 0) then
//    Exit;
//
//  IsVistaOrLater := CheckWin32Version(6);
//
//  CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);
//  try
//    ThumbJPEG := TJpegImage.Create;
//    ThumbJPEG.CompressionQuality := 80;
//    ThumbJPEG.Performance := jpBestSpeed;
//    Path := Form1.Directory;
//
//    OleCheck(SHGetDesktopFolder(DesktopShellFolder));
//    OleCheck(DesktopShellFolder.ParseDisplayName(0, nil, StringToOleStr(Path),
//        Eaten, PIDL, Atribute));
//    OleCheck(DesktopShellFolder.BindToObject(PIDL, nil, IID_IShellFolder,
//        Pointer(ShellFolder)));
//    CoTaskMemFree(PIDL);
//
//    Cnt := 0;
//    Old := ViewLink.ViewIdx;
//    pro := 0;
//    PV := 100 / ViewLink.Items.Count;
//    repeat
//      while (not Terminated) and (Cnt < ViewLink.Items.Count) do
//      begin
//        if Old <> ViewLink.ViewIdx then
//        begin
//          Cnt := ViewLink.ViewIdx - 1;
//          if Cnt = -1 then
//            Cnt := 0;
//          Old := ViewLink.ViewIdx;
//        end;
//
//        PThumb := PItemData(ItemsLink.Items[ViewLink.Items[Cnt]]);
//        Done := PThumb.GotThumb;
//        PThumb.ImgState := 0;
//
//        if IsVistaOrLater then
//        begin
//          if not Done then
//          begin
//            Bmp := TBitmap.Create;
//            Bmp.PixelFormat := pf32Bit;
//            Bmp.HandleType := bmDIB; // Use DIB sections for thread safety and speed
//            Bmp.Canvas.Lock;
//            FName := Path + PThumb.Name;
//            Res := SHCreateItemFromParsingName(PChar(FName), nil,
//              IShellItemImageFactory, fileShellItemImage);
//            if Succeeded(Res) then
//            begin
//              ASize.cx := 256;
//              ASize.cy := 256;
//              Res := fileShellItemImage.GetImage(ASize, SIIGBF_THUMBNAILONLY or SIIGBF_RESIZETOFIT,
//                BmpHandle);
//              if Succeeded(Res) then
//              begin
//                Bmp.Canvas.UnLock;
//                Bmp.Handle := BmpHandle;
//                Bmp.Canvas.Lock;
//                HackAlpha(Bmp, clWhite);
//                PThumb.IsIcon := False;
//                Done := true;
//              end;
//            end;
//          end;
//        end
//        else
//        begin
//          if not Done then
//          begin
//            Bmp := TBitmap.Create;
//            Bmp.Canvas.Lock;
//            OleCheck(ShellFolder.ParseDisplayName(0, nil,
//                StringToOleStr(PThumb.Name), Eaten, PIDL, Atribute));
//            ShellFolder.GetUIObjectOf(0, 1, PIDL, IExtractImage, nil,
//              XtractImage);
//            CoTaskMemFree(PIDL);
//            if Assigned(XtractImage) then
//            begin
//              if XtractImage.QueryInterface(IID_IExtractImage2,
//                Pointer(XtractImage2)) <> E_NOINTERFACE then
//              else
//                XtractImage2 := nil;
//              RunnableTask := nil;
//              ASize.cx := 256;
//              ASize.cy := 256;
//              Priority := 0;
//              Flags :=
//                IEIFLAG_SCREEN or IEIFLAG_OFFLINE or IEIFLAG_ORIGSIZE
//                or IEIFLAG_QUALITY;
//              Colordepth := 32;
//              GetLocationRes := XtractImage.GetLocation(Buf, MAX_PATH,
//                Priority, ASize, Colordepth, Flags);
//              if (GetLocationRes = NOERROR) or (GetLocationRes = E_PENDING) then
//              begin
//                if GetLocationRes = E_PENDING then
//                  if XtractImage.QueryInterface(IRunnableTask, RunnableTask)
//                    <> S_OK then
//                    RunnableTask := nil;
//                try
//                  if Succeeded(XtractImage.Extract(BmpHandle)) then
//                  begin
//                    Bmp.Canvas.UnLock;
//                    Bmp.Handle := BmpHandle;
//                    Bmp.Canvas.Lock;
//                    HackAlpha(Bmp, clWhite);
//                    PThumb.IsIcon := False;
//                    Done := true;
//                  end;
//                except
//                  on E: EOleSysError do
//                    OutputDebugString
//                      (PChar(string(E.ClassName) + ': ' + E.message))
//                  else
//                    raise ;
//                end; // try/except
//              end;
//            end;
//          end;
//        end;
//
//        if (not Done) and (not IsVistaOrLater) then // we did not get a thumbnail, try getting a icon
//        begin
//          OleCheck(ShellFolder.ParseDisplayName(0, nil,
//              StringToOleStr(PThumb.Name), Eaten, PIDL, Atribute));
//          ShellFolder.GetUIObjectOf(0, 1, PIDL, IExtractIcon, nil, XtractIcon);
//          CoTaskMemFree(PIDL);
//          if Assigned(XtractIcon) then
//          begin
//            GetLocationRes := XtractIcon.GetIconLocation(GIL_FORSHELL, @Buf,
//              SizeOf(Buf), IIdx, IFlags);
//            if (GetLocationRes = NOERROR) or (GetLocationRes = E_PENDING) then
//            begin
//              try
//                OleCheck(XtractIcon.Extract(@Buf, IIdx, LIcon, SIcon,
//                    256 + (48 shl 16)));
//                if (LIcon <> 0) then
//                begin
//                  IconL := TIcon.Create;
//                  try
//                    IconL.Handle := LIcon;
//                    if (IconL.Width > 32) then
//                    begin
//                      Bmp.Canvas.Lock;
//                      GraphicToBitmap(IconL, Bmp, clNone);
//                      PThumb.IsIcon := true;
//                      if Bmp.Width >= 248 then
//                        PThumb.ImgState := 1;
//                      Done := true;
//                    end;
//                  finally
//                    IconL.Free;
//                  end;
//                end;
//                if (SIcon <> 0) then
//                begin
//                  IconS := TIcon.Create;
//                  try
//                    IconS.Handle := SIcon;
//                    if (IconS.Width > 32) and (not Done) then
//                    begin
//                      Bmp.Canvas.Lock;
//                      GraphicToBitmap(IconS, Bmp, clNone);
//                      PThumb.IsIcon := true;
//                      if Bmp.Width >= 248 then
//                        PThumb.ImgState := 1;
//                      Done := true;
//                    end;
//                  finally
//                    IconS.Free;
//                  end;
//                end;
//                if Done then
//                begin
//
//                end;
//              except
//                on E: EOleSysError do
//                  OutputDebugString
//                    (PChar(string(E.ClassName) + ': ' + E.message))
//                else
//                  raise ;
//              end; // try/except
//            end;
//          end;
//        end;
//
//        if not Done then
//        begin
//          IconL := TIcon.Create;
//          try
//            FName := Path + PThumb.Name;
//            GetIconFromFile(FName, IconL, SHIL_JUMBO);
//            Bmp.Canvas.Lock;
//            GraphicToBitmap(IconL, Bmp, clNone);
//            Done := true;
//            PThumb.IsIcon := true;
//            if Bmp.Width >= 248 then
//              PThumb.ImgState := 1;
//          finally
//            IconL.Free;
//          end;
//        end;
//
//        if Done and not Terminated then
//        begin
//          if (Bmp <> nil) then
//          begin
//            if (Bmp.Width > 0) and (Bmp.Height > 0) then
//            begin
//              ThumbJPEG.Assign(Bmp);
//              ThumbJPEG.Compress;
//              MS := TMemoryStream.Create;
//              MS.Position := 0;
//              try
//                ThumbJPEG.SaveToStream(MS);
//                PThumb.Image := MS;
//              except
//                MS.Free;
//                raise ;
//              end;
//            end;
//            PThumb.ThumbWidth := Bmp.Width;
//            PThumb.ThumbHeight := Bmp.Height;
//            PThumb.GotThumb := true;
//          end;
//        end
//        else
//          PThumb.Image := nil;
//
//        if Assigned(Bmp) then
//        begin
//          Bmp.Canvas.UnLock;
//          FreeAndNil(Bmp);
//        end;
//
//        if (Done) and (not Terminated) then
//        begin
//          InView := ViewLink.ViewIdx +
//            (ViewLink.ViewColumns * (ViewLink.ViewRows));
//          // check to only update the UI every X items or based on timing
//          if (Cnt mod 5 = 0) or (Cnt >= ViewLink.ViewIdx) and (Cnt <= InView) then
//            PostMessage(Form1.Handle, CM_UpdateView, 0, 0);
//          if (Cnt = 0) then
//            p := 0
//          else
//            p := Round(PV * Cnt);
//          if (pro <> p) then
//          begin
//            PostMessage(Form1.Handle, CM_Progress, 0, p);
//            pro := p;
//          end;
//        end;
//        inc(Cnt);
//      end;
//
//      Cnt := 0;
//      for i := 0 to ViewLink.Items.Count - 1 do
//        if not PItemData(ItemsLink.Items[i]).GotThumb then
//          inc(Cnt);
//    until (Cnt = 0) or (Terminated);
//
//    if not Terminated then
//      PostMessage(Form1.Handle, CM_UpdateView, 0, 0);
//
//    PostMessage(Form1.Handle, CM_Progress, 0, 100);
//    ThumbJPEG.Free;
//  finally
//    CoUninitialize;
//  end;
//end;

procedure ThumbThread.Execute;
var
  Cnt, i: Integer;
  PThumb: PItemData;
  Old: Integer;
  InView: Integer;

  // Shell Interfaces
  ShellItem: IShellItem; // <--- ADDED: We create this first
  fileShellItemImage: IShellItemImageFactory;

  // Bitmaps
  Bmp, TempBmp: TBitmap;
  BmpHandle: HBITMAP;

  Path, FName: string;
  Res: HResult;
  TargetSize: Integer;

  // Flags & Sizes
  ASize: TSize;
  ImageFlags: SIIGBF; // or DWORD depending on your import units

  // Legacy/Fallback variables
  DesktopShellFolder: IShellFolder; // Kept only if you need legacy fallback
  IconL: TIcon;
  Done: Boolean;
  ThumbJPEG: TJpegImage;
  MS: TMemoryStream;
  p, pro: Integer;
  PV: Single;
  IsVistaOrLater: Boolean;
begin
  inherited;
  if (ViewLink.Items.Count = 0) then Exit;

  IsVistaOrLater := CheckWin32Version(6);

  CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);
  try
    ThumbJPEG := TJpegImage.Create;
    ThumbJPEG.CompressionQuality := 80;
    ThumbJPEG.Performance := jpBestSpeed;

    // FIX 1: Ensure path has trailing delimiter
    Path := IncludeTrailingPathDelimiter(Form1.Directory);

    // Setup Reusable Bitmaps
    Bmp := TBitmap.Create;
    Bmp.PixelFormat := pf24bit;
    TempBmp := TBitmap.Create;
    TempBmp.PixelFormat := pf24bit;

    TargetSize := 256;
    ASize.cx := TargetSize;
    ASize.cy := TargetSize;

    Cnt := 0;
    Old := ViewLink.ViewIdx;
    pro := 0;
    PV := 100 / ViewLink.Items.Count;

    repeat
      while (not Terminated) and (Cnt < ViewLink.Items.Count) do
      begin
        // --- View Tracking ---
        if Old <> ViewLink.ViewIdx then
        begin
          Cnt := ViewLink.ViewIdx - 1;
          if Cnt = -1 then Cnt := 0;
          Old := ViewLink.ViewIdx;
        end;

        PThumb := PItemData(ItemsLink.Items[ViewLink.Items[Cnt]]);

        if PThumb.GotThumb then
        begin
          Inc(Cnt);
          Continue;
        end;

        Done := False;
        PThumb.ImgState := 0;
        FName := Path + PThumb.Name; // e.g. "C:\Photos\SubFolder"

        // ---------------------------------------------------------
        // METHOD 1: Vista+ IShellItemImageFactory (Optimized)
        // ---------------------------------------------------------
        if IsVistaOrLater then
        begin
          // FIX 2: Create IShellItem FIRST.
          // Direct creation of IShellItemImageFactory fails on many folder types.
          Res := SHCreateItemFromParsingName(PChar(FName), nil, IShellItem, ShellItem);
          OleCheck(Res);

          if Succeeded(Res) then
          begin
            // Now ask the item for the factory
            if Succeeded(ShellItem.QueryInterface(IShellItemImageFactory, fileShellItemImage)) then
            begin
              // FIX 3: Flags Strategy
              // - Always try Cache first.
              // - NEVER use SIIGBF_THUMBNAILONLY for directories (it fails if no preview exists).

              // Attempt 1: Cache Only (Fastest)
              Res := fileShellItemImage.GetImage(ASize, SIIGBF_INCACHEONLY, BmpHandle);

              // Attempt 2: Extract from Disk (if cache missed)
              if not Succeeded(Res) then
              begin
                 ImageFlags := SIIGBF_BIGGERSIZEOK;
                 // IMPORTANT: Do NOT add SIIGBF_THUMBNAILONLY here.
                 // Omitting it allows Windows to return the default Folder Icon
                 // if it can't generate a "Thumbnail" (preview).

                 Res := fileShellItemImage.GetImage(ASize, ImageFlags, BmpHandle);
              end;

              if Succeeded(Res) then
              begin
                Bmp.Handle := BmpHandle;

                // STEP 3: Manual Resize (if Shell gave us a huge image)
                if (Bmp.Width > TargetSize) or (Bmp.Height > TargetSize) then
                begin
                  if Bmp.Width > Bmp.Height then
                  begin
                     TempBmp.Width := TargetSize;
                     TempBmp.Height := MulDiv(Bmp.Height, TargetSize, Bmp.Width);
                  end
                  else
                  begin
                     TempBmp.Height := TargetSize;
                     TempBmp.Width := MulDiv(Bmp.Width, TargetSize, Bmp.Height);
                  end;
                  Form1.BiResample(Bmp, TempBmp, False);
                  Bmp.Assign(TempBmp);
                end;

                // STEP 4: HackAlpha
                // Only needed for icons/transparent images.
                // For standard JPG thumbnails, this is harmless but unnecessary.
                HackAlpha(Bmp, clWhite);

                PThumb.IsIcon := False;
                Done := True;
              end;
            end;
          end;
        end;

        // ---------------------------------------------------------
        // METHOD 2: Fallback (Legacy Icon Extraction)
        // ---------------------------------------------------------
        if not Done then
        begin
           IconL := TIcon.Create;
           try
             // SHIL_JUMBO = $4 (256x256)
             GetIconFromFile(FName, IconL, $4);
             if (IconL.Handle <> 0) and (IconL.Width > 0) then
             begin
               // Draw Icon onto white background
               Bmp.Width := TargetSize;
               Bmp.Height := TargetSize;
               Bmp.Canvas.Brush.Color := clWhite;
               Bmp.Canvas.FillRect(Rect(0, 0, TargetSize, TargetSize));

               // Center the icon if it's smaller than 256
               // or stretch it? Usually GraphicToBitmap handles this,
               // but let's assume standard draw:
               Bmp.Canvas.Draw((TargetSize - IconL.Width) div 2,
                               (TargetSize - IconL.Height) div 2, IconL);

               PThumb.IsIcon := True;
               Done := True;
             end;
           finally
             IconL.Free;
           end;
        end;

        // ---------------------------------------------------------
        // Finalize
        // ---------------------------------------------------------
        if Done and not Terminated and (Bmp.Width > 0) then
        begin
          ThumbJPEG.Assign(Bmp);
          ThumbJPEG.Compress;
          MS := TMemoryStream.Create;
          try
            ThumbJPEG.SaveToStream(MS);
            PThumb.Image := MS;
            PThumb.ThumbWidth := Bmp.Width;
            PThumb.ThumbHeight := Bmp.Height;
            PThumb.GotThumb := True;
          except
            MS.Free;
          end;
        end;

        Bmp.Handle := 0; // Release GDI handle

        // --- Progress Update Logic ---
        if (Done) and (not Terminated) then
        begin
          InView := ViewLink.ViewIdx + (ViewLink.ViewColumns * ViewLink.ViewRows);
          if (Cnt >= ViewLink.ViewIdx) and (Cnt <= InView) or (Cnt mod 5 = 0) then
            PostMessage(Form1.Handle, CM_UpdateView, 0, 0);

          if (Cnt = 0) then p := 0 else p := Round(PV * Cnt);
          if (pro <> p) then
          begin
            PostMessage(Form1.Handle, CM_Progress, 0, p);
            pro := p;
          end;
        end;

        inc(Cnt);
      end;

      // Restart loop for skipped items
      Cnt := 0;
      for i := 0 to ViewLink.Items.Count - 1 do
        if not PItemData(ItemsLink.Items[i]).GotThumb then
        begin
          Cnt := i;
          Break;
        end;

    until (Cnt = 0) or (Terminated);

    if not Terminated then
      PostMessage(Form1.Handle, CM_UpdateView, 0, 0);
    PostMessage(Form1.Handle, CM_Progress, 0, 100);

  finally
    Bmp.Free;
    TempBmp.Free;
    ThumbJPEG.Free;
    CoUninitialize;
  end;
end;

{ MPlayer}


// This event runs in MPV's background thread.
// We MUST use TThread.Queue (preferred over Synchronize) to update UI.
procedure TForm1.OnMPlayerProgress(cSender: TObject; fCurSec, fTotalSec: Double);
begin
  // Don't update tracker if user is currently dragging it
  if FIsSeeking then Exit;

  TThread.Queue(nil, procedure
  begin
    // Check if form/player still exists to avoid Access Violation on close
    if (MPlayer = nil) or (csDestroying in ComponentState) then Exit;

//    TrackBar1.Max := Round(fTotalSec);
//    TrackBar1.Position := Round(fCurSec);
    ACLSliderMPV.OptionsValue.Max := Round(fTotalSec);
    ACLSliderMPV.Position :=  Round(fCurSec);
  end);
end;

// Release memory after playing (if not looped)
procedure TForm1.OnMPlayerStateChanged(cSender: TObject; eState: TMPVPlayerState);
begin
  // eState runs in background thread. Sync if you touch UI.
  if eState = mpsEnd then
  begin
    TThread.Queue(nil, procedure
    begin
       // If loop is 'no', this triggers at end of file.
       // logic to release memory or close file:
       MPlayer.CommandStr('stop');
       // Optionally: MPlayer.NotifyFree; MPlayer.Free; MPlayer := nil;
    end);
  end;
end;

end.
