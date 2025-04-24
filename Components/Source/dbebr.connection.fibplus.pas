unit dbe.connection.fibplus;

interface

uses
  DB,
  Classes,
  FIBQuery,
  FIBDataSet,
  FIBDatabase,
  dbe.connection.base,
  dbe.factory.fibplus,
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
  TDBEConnectionFIBPlus = class(TDBEConnectionBase)
  private
    FConnection: TFIBDatabase;
    procedure SetConnection(const Value: TFIBDatabase);
    function GetConnection: TFIBDatabase;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TFIBDatabase read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionFIBPlus }

constructor TDBEConnectionFIBPlus.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionFIBPlus.Destroy;
begin

  inherited;
end;

function TDBEConnectionFIBPlus.GetConnection: TFIBDatabase;
begin
  Result := FConnection;
end;

procedure TDBEConnectionFIBPlus.SetConnection(const Value: TFIBDatabase);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryFIBPlus.Create(FConnection, FDriverName);
end;

end.
