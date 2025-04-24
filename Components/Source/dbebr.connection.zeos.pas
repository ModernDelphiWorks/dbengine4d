unit dbe.connection.zeos;

interface

uses
  DB,
  Classes,
  ZConnection,
  dbe.connection.base,
  dbe.factory.zeos,
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
  TDBEConnectionZeos = class(TDBEConnectionBase)
  private
    FConnection: TZConnection;
    procedure SetConnection(const Value: TZConnection);
    function GetConnection: TZConnection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TZConnection read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionZeos }

constructor TDBEConnectionZeos.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionZeos.Destroy;
begin

  inherited;
end;

function TDBEConnectionZeos.GetConnection: TZConnection;
begin
  Result := FConnection;
end;

procedure TDBEConnectionZeos.SetConnection(const Value: TZConnection);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryZeos.Create(FConnection, FDriverName);
end;

end.
