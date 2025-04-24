unit dbe.connection.ado;

interface

uses
  DB,
  Classes,
  ADODB,
  dbe.connection.base,
  DBE.FactoryADO,
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
  TDBEConnectionADO = class(TDBEConnectionBase)
  private
    FConnection: TADOConnection;
    procedure SetConnection(const Value: TADOConnection);
    function GetConnection: TADOConnection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TADOConnection read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionADO }

constructor TDBEConnectionADO.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionADO.Destroy;
begin

  inherited;
end;

function TDBEConnectionADO.GetConnection: TADOConnection;
begin
  Result := FConnection;
end;

procedure TDBEConnectionADO.SetConnection(const Value: TADOConnection);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryADO.Create(FConnection, FDriverName);
end;

end.
