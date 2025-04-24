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

unit DBEngine.FactoryConnection;

interface

uses
  DB,
  Classes,
  SysUtils,
  DBEngine.FactoryInterfaces,
  DBEngine.DriverConnection;

type
  TFactoryConnection = class abstract(TInterfacedObject, IDBConnection, IDBTransaction)
  protected
    FOptions: IOptions;
    FAutoTransaction: Boolean;
    FDriverConnection: TDriverConnection;
    FDriverTransaction: TDriverTransaction;
    FCommandMonitor: ICommandMonitor;
    FMonitorCallback: TMonitorProc;
    function _GetTransaction(const AKey: String): TComponent; virtual;
  public
    procedure Connect; virtual;
    procedure Disconnect; virtual;
    procedure ExecuteDirect(const ASQL: String); overload; virtual;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); overload; virtual;
    procedure ExecuteScript(const AScript: String); virtual;
    procedure AddScript(const AScript: String); virtual;
    procedure ExecuteScripts; virtual;
    procedure ApplyUpdates(const ADataSets: array of IDBDataSet); virtual;
    procedure SetCommandMonitor(AMonitor: ICommandMonitor); virtual;
      deprecated 'use Create(AConnection, ADriverName, AMonitor)';
    function IsConnected: Boolean; virtual;
    function CreateQuery: IDBQuery; virtual;
    function CreateDataSet(const ASQL: String = ''): IDBDataSet; virtual;
    function GetSQLScripts: String; virtual;
    function RowsAffected: UInt32; virtual;
    function GetDriver: TDBEngineDriver; virtual;
    function CommandMonitor: ICommandMonitor; virtual;
    function MonitorCallback: TMonitorProc; virtual;
    function Options: IOptions; virtual;
    // Transactions
    procedure StartTransaction; virtual;
    procedure Commit; virtual;
    procedure Rollback; virtual;
    procedure AddTransaction(const AKey: String; const ATransaction: TComponent); virtual;
    procedure UseTransaction(const AKey: String); virtual;
    function TransactionActive: TComponent; virtual;
    function InTransaction: Boolean; virtual;
  end;

  TDriverTransactionHacker = class(TDriverTransaction)
  end;

implementation

{ TFactoryConnection }

procedure TFactoryConnection.AddScript(const AScript: String);
begin
  FDriverConnection.AddScript(AScript);
end;

procedure TFactoryConnection.AddTransaction(const AKey: String;
  const ATransaction: TComponent);
begin
  FDriverTransaction.AddTransaction(AKey, ATransaction);
end;

procedure TFactoryConnection.ApplyUpdates(const ADataSets: array of IDBDataSet);
begin
  FDriverConnection.ApplyUpdates(ADataSets);
end;

function TFactoryConnection.CommandMonitor: ICommandMonitor;
begin
  Result := FCommandMonitor;
end;

procedure TFactoryConnection.Commit;
begin
  FDriverTransaction.Commit;
  if FAutoTransaction then
    Disconnect;
end;

procedure TFactoryConnection.Connect;
begin
  if not IsConnected then
    FDriverConnection.Connect;
end;

function TFactoryConnection.CreateQuery: IDBQuery;
begin
  Result := FDriverConnection.CreateQuery;
end;

function TFactoryConnection.CreateDataSet(const ASQL: String): IDBDataSet;
begin
  Result := FDriverConnection.CreateDataSet(ASQL);
end;

procedure TFactoryConnection.Disconnect;
begin
  if IsConnected then
    FDriverConnection.Disconnect;
end;

function TFactoryConnection.Options: IOptions;
begin
  if not Assigned(FOptions) then
    FOptions := TOptions.Create;
  Result := FOptions;
end;

procedure TFactoryConnection.ExecuteDirect(const ASQL: String;
  const AParams: TParams);
var
  LInTransaction: Boolean;
  LIsConnected: Boolean;
begin
  LInTransaction := InTransaction;
  LIsConnected := IsConnected;
  if not LIsConnected then
    Connect;
  try
    try
      if not LInTransaction then
        StartTransaction;
      FDriverConnection.ExecuteDirect(ASQL, AParams);
      if not LInTransaction then
        Commit;
    except
      on E: Exception do
      begin
        if not LInTransaction then
          Rollback;
        raise Exception.Create(E.Message);
      end;
    end;
  finally
    if not LIsConnected then
      Disconnect;
  end;
end;

procedure TFactoryConnection.ExecuteDirect(const ASQL: String);
var
  LInTransaction: Boolean;
  LIsConnected: Boolean;
begin
  LInTransaction := InTransaction;
  LIsConnected := IsConnected;
  if not LIsConnected then
    Connect;
  try
    if not LInTransaction then
      StartTransaction;
    try
      FDriverConnection.ExecuteDirect(ASQL);
      if not LInTransaction then
        Commit;
    except
      on E: Exception do
      begin
        if not LInTransaction then
          Rollback;
        raise Exception.Create(E.Message);
      end;
    end;
  finally
    if not LIsConnected then
      Disconnect;
  end;
end;

procedure TFactoryConnection.ExecuteScript(const AScript: String);
var
  LInTransaction: Boolean;
  LIsConnected: Boolean;
begin
  LInTransaction := InTransaction;
  LIsConnected := IsConnected;
  if not LIsConnected then
    Connect;
  try
    if not LInTransaction then
      StartTransaction;
    try
      FDriverConnection.ExecuteScript(AScript);
      if not LInTransaction then
        Commit;
    except
      on E: Exception do
      begin
        if not LInTransaction then
          Rollback;
        raise Exception.Create(E.Message);
      end;
    end;
  finally
    if not LIsConnected then
      Disconnect;
  end;
end;

procedure TFactoryConnection.ExecuteScripts;
var
  LInTransaction: Boolean;
  LIsConnected: Boolean;
begin
  LInTransaction := InTransaction;
  LIsConnected := IsConnected;
  if not LIsConnected then
    Connect;
  try
    if not LInTransaction then
      StartTransaction;
    try
      FDriverConnection.ExecuteScripts;
      if not LInTransaction then
        Commit;
    except
      on E: Exception do
      begin
        if not LInTransaction then
          Rollback;
        raise Exception.Create(E.Message);
      end;
    end;
  finally
    if not LIsConnected then
      Disconnect;
  end;
end;

function TFactoryConnection.GetDriver: TDBEngineDriver;
begin
  Result := FDriverConnection.GetDriver;
end;

function TFactoryConnection.GetSQLScripts: String;
begin
  Result := FDriverConnection.GetSQLScripts;
end;

function TFactoryConnection.InTransaction: Boolean;
begin
  Result := False;
  if not IsConnected then
    Exit;
  Result := FDriverTransaction.InTransaction;
end;

function TFactoryConnection.IsConnected: Boolean;
begin
  Result := FDriverConnection.IsConnected;
end;

function TFactoryConnection.MonitorCallback: TMonitorProc;
begin
  Result := FMonitorCallback;
end;

procedure TFactoryConnection.Rollback;
begin
  FDriverTransaction.Rollback;
  if FAutoTransaction then
    Disconnect;
end;

function TFactoryConnection.RowsAffected: UInt32;
begin
  Result := FDriverConnection.RowsAffected;
end;

procedure TFactoryConnection.SetCommandMonitor(AMonitor: ICommandMonitor);
begin
  FCommandMonitor := AMonitor;
end;

procedure TFactoryConnection.StartTransaction;
begin
  if FDriverTransaction.TransactionActive = nil then
    raise Exception.Create('No active transaction selected. Call UseTransaction first.');
  if not IsConnected then
  begin
    Connect;
    FAutoTransaction := True;
  end;
  FDriverTransaction.StartTransaction;
end;

function TFactoryConnection.TransactionActive: TComponent;
begin
  Result := FDriverTransaction.TransactionActive;
end;

procedure TFactoryConnection.UseTransaction(const AKey: String);
begin
  FDriverTransaction.UseTransaction(AKey);
end;

function TFactoryConnection._GetTransaction(const AKey: String): TComponent;
begin
  Result := TDriverTransactionHacker(FDriverTransaction)._GetTransaction(AKey);
end;

end.


