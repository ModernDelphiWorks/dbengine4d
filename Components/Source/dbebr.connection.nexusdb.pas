unit dbe.connection.nexusdb;

interface

uses
  DB,
  Classes,
  nxdb,
  nxllComponent,
  dbe.connection.base,
  dbe.factory.nexusdb,
  DBE.FactoryInterfaces;

type
  {$IF CompilerVersion > 23}
  [ComponentPlatformsAttribute(pidWin32 or
                               pidWin64 or
                               pidOSX32 or
                               pidiOSSimulator or
                               pidiOSDevice or
                               pidAndroid)]
  {$IFEND}
  TDBEConnectionNexusDB = class(TDBEConnectionBase)
  private
    FConnection: TnxDatabase;
    procedure SetConnection(const Value: TnxDatabase);
    function GetConnection: TnxDatabase;
  public
    constructor Create(const AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TnxDatabase read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionNexusDB }

constructor TDBEConnectionNexusDB.Create(const AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionNexusDB.Destroy;
begin

  inherited;
end;

function TDBEConnectionNexusDB.GetConnection: TnxDatabase;
begin
  Result := FConnection;
end;

procedure TDBEConnectionNexusDB.SetConnection(const Value: TnxDatabase);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryNexusDB.Create(FConnection, FDriverName);
end;

end.
