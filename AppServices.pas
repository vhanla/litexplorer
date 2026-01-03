unit AppServices;

interface

uses
  System.SysUtils, System.Classes, CB.AppStartup;

type
  TDataModule1 = class(TDataModule)
    CBAppStartup1: TCBAppStartup;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  CBAppStartup1.RegisterStep()
end;

end.
