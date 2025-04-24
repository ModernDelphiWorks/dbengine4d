unit dbe.connection.dbexpress;

interface

uses
  DB,
  SqlExpr,
  Classes,
  dbe.connection.base,
  dbe.factory.dbexpress,
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
  TDBEConnectionDBExpress = class(TDBEConnectionBase)
  private
    FConnection: TSQLConnection;
    procedure SetConnection(const Value: TSQLConnection);
    function GetConnection: TSQLConnection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TSQLConnection read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionDBExpress }

constructor TDBEConnectionDBExpress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionDBExpress.Destroy;
begin

  inherited;
end;

function TDBEConnectionDBExpress.GetConnection: TSQLConnection;
begin
  Result := FConnection;
end;

procedure TDBEConnectionDBExpress.SetConnection(const Value: TSQLConnection);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryDBExpress.Create(FConnection, FDriverName);
end;

end.
