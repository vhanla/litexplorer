program LiteXplorer;

uses
  FastMM5,
  Vcl.Forms,
  main in 'main.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  Classes,
  VirtualExplorerEasyListview in 'VirtualExplorerEasyListview.pas',
  VirtualThumbnails in 'VirtualThumbnails.pas',
  MPCommonUtilities in 'MPCommonUtilities.pas',
  MPVBasePlayer in 'MPVBasePlayer.pas',
  FuzzyFileFinder in 'FuzzyFileFinder.pas',
  MPVClient in 'MPVClient.pas',
  Helpers in 'Helpers.pas',
  libpng in 'libpng.pas',
  pngloader in 'pngloader.pas',
  LibTurboJPEG in 'LibTurboJPEG.pas',
  JpegLoader in 'JpegLoader.pas',
  DataModule in 'DataModule.pas' {AppServices: TDataModule};

{$R *.res}

begin

  Application.Initialize;
  Application.MainFormOnTaskbar := True;

    // apply style
  TThread.Queue(nil,
    procedure
    begin
      TStyleManager.TrySetStyle('Windows11 Modern Dark');
    end);

  Application.CreateForm(TAppServices, AppServices);
  // Create main form first
  Application.CreateForm(TForm1, Form1);
  Form1.Show;
  Form1.Update; // force first paint

  AppServices.CBAppStartup1.StartOnce;
  Application.Run;
end.
