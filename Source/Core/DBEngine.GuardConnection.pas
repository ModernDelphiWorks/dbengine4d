{
                          Apache License
                      Version 2.0, January 2004
                   http://www.apache.org/licenses/

       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

             http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.
}

{
  @abstract(DBEngine4D: Database Engine Framework for Delphi)
  @description(A flexible and modular database engine framework for Delphi applications)
  @created(03 Abr 2025)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @Discord(https://discord.gg/T2zJC8zX)
}

{$ifdef fpc}
  {$mode delphi}{$H+}
{$endif}

unit DBEngine.GuardConnection;

interface

uses
  SysUtils,
  DBEngine.FactoryInterfaces,
  DBEngine.PoolConnection;

type
  TConnectionGuardBuilder = class;

  TGuardConnection = class
  private
    FPool: TPoolConnection;
  public
    constructor Create(const ABuilder: TConnectionGuardBuilder);
    destructor Destroy; override;
    procedure UseConnection(const AAction: TProc<IDBConnection>);
  end;

  TConnectionGuardBuilder = class
  private
    FMaxConnections: Integer;
    FConnectionLifeCycle: Integer;
    FConnectionFactory: TFunc<IDBConnection>;
    class var FGuardConnection: TGuardConnection;
  public
    function Limit(const AValue: Integer): TConnectionGuardBuilder;
    function LifeCycle(const AValue: Integer): TConnectionGuardBuilder;
    function WithFactory(const AFactory: TFunc<IDBConnection>): TConnectionGuardBuilder;
    function Build: TGuardConnection;
  end;

function SetupGuard: TConnectionGuardBuilder;
procedure UseConnection(const AAction: TProc<IDBConnection>);

implementation

function SetupGuard: TConnectionGuardBuilder;
begin
  Result := TConnectionGuardBuilder.Create;
end;

procedure UseConnection(const AAction: TProc<IDBConnection>);
begin
  TConnectionGuardBuilder.FGuardConnection.UseConnection(AAction);
end;

{ TConnectionGuard }

constructor TGuardConnection.Create(const ABuilder: TConnectionGuardBuilder);
begin
  FPool := TPoolConnection.Create(ABuilder.FMaxConnections,
                                  ABuilder.FConnectionLifeCycle,
                                  ABuilder.FConnectionFactory);
end;

destructor TGuardConnection.Destroy;
begin
  FPool.Free;
  inherited;
end;

procedure TGuardConnection.UseConnection(const AAction: TProc<IDBConnection>);
var
  LConnection: IDBConnection;
begin
  LConnection := FPool.AcquireConnection;
  try
    AAction(LConnection);
  finally
    FPool.ReleaseConnection(LConnection);
  end;
end;

{ TConnectionGuardBuilder }

function TConnectionGuardBuilder.Limit(const AValue: Integer): TConnectionGuardBuilder;
begin
  FMaxConnections := AValue;
  Result := Self;
end;

function TConnectionGuardBuilder.LifeCycle(const AValue: Integer): TConnectionGuardBuilder;
begin
  FConnectionLifeCycle := AValue;
  Result := Self;
end;

function TConnectionGuardBuilder.WithFactory(const AFactory: TFunc<IDBConnection>): TConnectionGuardBuilder;
begin
  FConnectionFactory := AFactory;
  Result := Self;
end;

function TConnectionGuardBuilder.Build: TGuardConnection;
begin
  FGuardConnection := TGuardConnection.Create(Self);
  Result := FGuardConnection;
end;

end.
