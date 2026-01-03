program LiteXplorer;

uses
  FastMM5,
  Vcl.Forms,
  main in 'main.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
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
  JpegLoader in 'JpegLoader.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows11 Modern Dark');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
