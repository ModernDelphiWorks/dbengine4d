unit dbe.connection.ibobjects;

interface

uses
  DB,
  Classes,
  IB_Components,
  IBODataset,
  IB_Access,
  dbe.connection.base,
  dbe.factory.ibobjects,
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
  TDBEConnectionIBObjects = class(TDBEConnectionBase)
  private
    FConnection: TIBODatabase;
    procedure SetConnection(const Value: TIBODatabase);
    function GetConnection: TIBODatabase;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Connection: TIBODatabase read GetConnection write SetConnection;
  end;

implementation

{ TDBEConnectionIBObjects }

constructor TDBEConnectionIBObjects.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionIBObjects.Destroy;
begin

  inherited;
end;

function TDBEConnectionIBObjects.GetConnection: TIBODatabase;
begin
  Result := FConnection;
end;

procedure TDBEConnectionIBObjects.SetConnection(const Value: TIBODatabase);
begin
  FConnection := Value;
  if not Assigned(FDBConnection) then
    FDBConnection := TFactoryIBObjects.Create(FConnection, FDriverName);
end;

end.
