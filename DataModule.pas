unit DataModule;

interface

uses
  System.SysUtils, System.Classes, CB.AppStartup;

type
  TAppServices = class(TDataModule)
    CBAppStartup1: TCBAppStartup;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AppServices: TAppServices;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  main;

{$R *.dfm}

procedure TAppServices.DataModuleCreate(Sender: TObject);
begin
  cbAppstartup1.registerstep(Form1.DelayedStartup);
end;

end.
