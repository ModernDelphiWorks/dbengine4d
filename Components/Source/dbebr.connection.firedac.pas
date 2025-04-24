unit dbe.connection.firedac;

interface

uses
  DB,
  Classes,
  FireDAC.Comp.Client,
  dbe.connection.base,
  DBE.FactoryFireDac,
  DBE.FactoryInterfaces;

type
  {$IF CompilerVersion > 23}
  [ComponentPlatformsAttribute(pidWin32 or
                               pidWin64 or
                               pidWinArm64 or
                               pidOSX32 or
                               pidOSX64 or
                               pidOSXArm64 or
                               pidLinux32 or
                               pidLinux64 or
                               pidLinuxArm64)]
  {$IFEND}
  TDBEConnectionFireDAC = class(TDBEConnectionBase)
  private
    FConnection: TFDConnection;
    procedure SetConnection(const Value: TFDConnection);
    function GetConnection: TFDConnection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TFDConnection read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionFireDAC }

constructor TDBEConnectionFireDAC.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionFireDAC.Destroy;
begin

  inherited;
end;

function TDBEConnectionFireDAC.GetConnection: TFDConnection;
begin
  Result := FConnection;
end;

procedure TDBEConnectionFireDAC.SetConnection(const Value: TFDConnection);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryFireDAC.Create(FConnection, FDriverName);
end;

end.
