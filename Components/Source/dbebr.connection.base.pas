{
      ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Versão 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos é permitido copiar e distribuir cópias deste documento de
       licença, mas mudá-lo não é permitido.

       Esta versão da GNU Lesser General Public License incorpora
       os termos e condições da versão 3 da GNU General Public License
       Licença, complementado pelas permissões adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(ORMBr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)
  @abstract(Website : http://www.ormbr.com.br)
  @abstract(Telagram : https://t.me/ormbr)
}

unit dbe.connection.base;

interface

uses
  DB,
  SysUtils,
  Classes,
  DBE.DriverConnection,
  DBE.FactoryConnection,
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
  TDBEConnectionBase = class(TComponent)
  protected
    FDBConnection: IDBConnection;
    FDriverName: TDriverName;
    function GetDBConnection: IDBConnection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Connect;
    procedure Disconnect;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure ExecuteDirect(const ASQL: String); overload;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); overload;
    procedure ExecuteScript(const AScript: String);
    procedure AddScript(const AScript: String);
    procedure ExecuteScripts;
    procedure SetCommandMonitor(AMonitor: ICommandMonitor);
    function InTransaction: Boolean;
    function IsConnected: Boolean;
    function CreateQuery: IDBQuery;
    function CreateDataSet(const ASQL: String): IDBResultSet;
    function CommandMonitor: ICommandMonitor;
    function DBConnection: IDBConnection;
  published
    property DriverName: TDriverName read FDriverName write FDriverName;
  end;

implementation

{ TDBEConnectionBase }

constructor TDBEConnectionBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TDBEConnectionBase.Destroy;
begin

  inherited;
end;

procedure TDBEConnectionBase.AddScript(const AScript: String);
begin
  GetDBConnection.AddScript(AScript);
end;

function TDBEConnectionBase.CommandMonitor: ICommandMonitor;
begin
  Result := GetDBConnection.CommandMonitor;
end;

procedure TDBEConnectionBase.Commit;
begin
  GetDBConnection.Commit;
end;

procedure TDBEConnectionBase.Connect;
begin
  GetDBConnection.Connect;
end;

function TDBEConnectionBase.DBConnection: IDBConnection;
begin
  Result := GetDBConnection;
end;

function TDBEConnectionBase.CreateQuery: IDBQuery;
begin
  Result := GetDBConnection.CreateQuery;
end;

function TDBEConnectionBase.CreateDataSet(
  const ASQL: String): IDBResultSet;
begin
  Result := GetDBConnection.CreateDataSet(ASQL);
end;

procedure TDBEConnectionBase.Disconnect;
begin
  GetDBConnection.Disconnect;
end;

procedure TDBEConnectionBase.ExecuteDirect(const ASQL: String);
begin
  GetDBConnection.ExecuteDirect(ASQL);
end;

procedure TDBEConnectionBase.ExecuteDirect(const ASQL: String;
  const AParams: TParams);
begin
  GetDBConnection.ExecuteDirect(ASQL, AParams);
end;

procedure TDBEConnectionBase.ExecuteScript(const AScript: String);
begin
  GetDBConnection.ExecuteScript(AScript);
end;

procedure TDBEConnectionBase.ExecuteScripts;
begin
  GetDBConnection.ExecuteScripts;
end;

function TDBEConnectionBase.GetDBConnection: IDBConnection;
begin
//  if FDBConnection = nil then
//    raise Exception.Create('Connection property not set!');
  Result := FDBConnection;
end;

function TDBEConnectionBase.InTransaction: Boolean;
begin
  Result := GetDBConnection.InTransaction;
end;

function TDBEConnectionBase.IsConnected: Boolean;
begin
  Result := GetDBConnection.IsConnected;
end;

procedure TDBEConnectionBase.Rollback;
begin
  GetDBConnection.Rollback;
end;

procedure TDBEConnectionBase.SetCommandMonitor(AMonitor: ICommandMonitor);
begin
  GetDBConnection.SetCommandMonitor(AMonitor);
end;

procedure TDBEConnectionBase.StartTransaction;
begin
  GetDBConnection.StartTransaction;
end;

end.
