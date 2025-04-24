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

unit DBEngine.DriverFireDac;

interface

uses
  DB,
  Classes,
  SysUtils,
  StrUtils,
  Variants,
  FireDAC.Comp.Client,
  FireDAC.Comp.Script,
  FireDAC.Comp.ScriptCommands,
  FireDAC.DApt,
  FireDAC.Stan.Param,
  FireDAC.Phys.Intf,
  DBEngine.DriverConnection,
  DBEngine.FactoryInterfaces;

type
  TFDQueryHelper = class Helper for TFDQuery
  public
    function AsParams: TParams;
  end;

  TDriverFireDAC = class(TDriverConnection)
  private
    function _GetTransactionActive: TFDTransaction;
    procedure _DoMonitorLog(ASender, AInitiator: TObject; var AException: Exception);
  protected
    FConnection: TFDConnection;
    FSQLScript: TFDScript;
  public
    constructor Create(const AConnection: TComponent; const ADriverTransaction: TDriverTransaction;
      const ADriver: TDBEngineDriver; const AMonitorCallback: TMonitorProc); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure ExecuteDirect(const ASQL: String); override;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); override;
    procedure ExecuteScript(const AScript: String); override;
    procedure AddScript(const AScript: String); override;
    procedure ExecuteScripts; override;
    procedure ApplyUpdates(const ADataSets: array of IDBDataSet); override;
    function IsConnected: Boolean; override;
    function CreateQuery: IDBQuery; override;
    function CreateDataSet(const ASQL: String = ''): IDBDataSet; override;
    function GetSQLScripts: String; override;
  end;

  TDriverQueryFireDAC = class(TDriverQuery)
  private
    FFDQuery: TFDQuery;
    function _GetTransactionActive: TFDTransaction;
  protected
    procedure _SetCommandText(const ACommandText: String); override;
    function _GetCommandText: String; override;
  public
    constructor Create(const AConnection: TFDConnection;
      const ADriverTransaction: TDriverTransaction;
      const AMonitorCallback: TMonitorProc);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBDataSet; override;
    function RowsAffected: UInt32; override;
  end;

  TDriverDataSetFireDAC = class(TDriverDataSet<TFDQuery>)
  protected
    procedure _SetUniDirectional(const Value: Boolean); override;
    procedure _SetReadOnly(const Value: Boolean); override;
    procedure _SetCachedUpdates(const Value: Boolean); override;
    procedure _SetCommandText(const ACommandText: String); override;
    function _GetCommandText: String; override;
  public
    constructor Create(const ADataSet: TFDQuery; const AMonitorCallback: TMonitorProc); reintroduce;
    destructor Destroy; override;
    procedure Open; override;
    procedure ApplyUpdates; override;
    procedure CancelUpdates; override;
    function RowsAffected: UInt32; override;
    function IsUniDirectional: Boolean; override;
    function IsReadOnly: Boolean; override;
    function IsCachedUpdates: Boolean; override;
  end;

implementation

{ TFDQueryHelper }

function TFDQueryHelper.AsParams: TParams;
var
  LFor: Int16;
begin
  Result := TParams.Create;
  for LFor := 0 to Self.Params.Count - 1 do
  begin
    Result.Add;
    Result[LFor].DataType := Self.Params[LFor].DataType;
    Result[LFor].Value := Self.Params[LFor].Value;
  end;
end;

{ TDriverFireDAC }

procedure TDriverFireDAC._DoMonitorLog(ASender, AInitiator: TObject;
  var AException: Exception);
begin
  _SetMonitorLog(AException.Message, FSQLScript.CurrentCommand.EngineIntf.CommandIntf.SQLText, nil);
end;

constructor TDriverFireDAC.Create(const AConnection: TComponent; const ADriverTransaction: TDriverTransaction;
  const ADriver: TDBEngineDriver; const AMonitorCallback: TMonitorProc);
begin
  FConnection := AConnection as TFDConnection;
  FDriverTransaction := ADriverTransaction;
  FDriver := ADriver;
  FMonitorCallback := AMonitorCallback;
  FSQLScript := TFDScript.Create(nil);
  try
    FSQLScript.Connection := FConnection;
    FSQLScript.SQLScripts.Add;
    FSQLScript.ScriptOptions.Reset;
    FSQLScript.ScriptOptions.BreakOnError := True;
    FSQLScript.ScriptOptions.RaisePLSQLErrors := True;
    FSQLScript.ScriptOptions.EchoCommands := ecNone;
    FSQLScript.ScriptOptions.CommandSeparator := ';';
    FSQLScript.ScriptOptions.CommitEachNCommands := 1000;
    FSQLScript.ScriptOptions.DropNonexistObj := True;
  except
    FSQLScript.Free;
    raise;
  end;
end;

destructor TDriverFireDAC.Destroy;
begin
  FConnection := nil;
  FDriverTransaction := nil;
  FSQLScript.Free;
  inherited;
end;

procedure TDriverFireDAC.Disconnect;
begin
  FConnection.Connected := False;
end;

procedure TDriverFireDAC.ExecuteDirect(const ASQL: String);
var
  LExeSQL: TFDQuery;
  LParams: TParams;
begin
  LExeSQL := TFDQuery.Create(nil);
  LParams := nil;
  try
    if not Assigned(FConnection) then
      raise Exception.Create('Connection not assigned.');
    if _GetTransactionActive = nil then
      raise Exception.Create('Transaction not assigned.');

    LExeSQL.Connection := FConnection;
    LExeSQL.Transaction := _GetTransactionActive;
    if ASQL = '' then
      raise Exception.Create('SQL statement is empty. Cannot execute the query.');

    LExeSQL.SQL.Text := ASQL;
    try
      if not LExeSQL.Prepared then
        LExeSQL.Prepare;
      LExeSQL.Execute;
      LParams := LExeSQL.AsParams;
      FRowsAffected := LExeSQL.RowsAffected;
    except
      on E: EDatabaseError do
      begin
        _SetMonitorLog(ASQL, E.Message, nil);
        raise;
      end;
      on E: Exception do
      begin
        _SetMonitorLog('General error during direct execution', E.Message, nil);
        raise;
      end;
    end;
  finally
    if Assigned(LExeSQL) then
    begin
      if LExeSQL.Active then
        LExeSQL.Close;
      _SetMonitorLog(LExeSQL.SQL.Text, LExeSQL.Transaction.Name, LParams);
      LExeSQL.Free;
    end;
    if Assigned(LParams) then
    begin
      LParams.Clear;
      LParams.Free;
    end;
  end;
end;

procedure TDriverFireDAC.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LExeSQL: TFDQuery;
  LParams: TParams;
  LFor: Int16;
begin
  LExeSQL := TFDQuery.Create(nil);
  LParams := nil;
  try
    if not Assigned(FConnection) then
      raise Exception.Create('Connection not assigned.');
    if _GetTransactionActive = nil then
      raise Exception.Create('Transaction not assigned.');

    LExeSQL.Connection := FConnection;
    LExeSQL.Transaction := _GetTransactionActive;
    if ASQL = '' then
      raise Exception.Create('SQL statement is empty. Cannot execute the query.');

    LExeSQL.SQL.Text := ASQL;
    if AParams.Count > 0 then
    begin
      for LFor := 0 to AParams.Count - 1 do
      begin
        if not Assigned(AParams[LFor]) then
          raise Exception.Create(Format('Parameter "%s" is invalid or unassigned.', [AParams[LFor].Name]));

        LExeSQL.ParamByName(AParams[LFor].Name).DataType := AParams[LFor].DataType;
        LExeSQL.ParamByName(AParams[LFor].Name).Value := AParams[LFor].Value;
      end;
    end;
    try
      if not LExeSQL.Prepared then
        LExeSQL.Prepare;
      LExeSQL.Execute;
      LParams := LExeSQL.AsParams;
      FRowsAffected := LExeSQL.RowsAffected;
    except
      on E: EDatabaseError do
      begin
        _SetMonitorLog(ASQL, E.Message, nil);
        raise;
      end;
      on E: Exception do
      begin
        _SetMonitorLog('General error during direct execution', E.Message, nil);
        raise;
      end;
    end;
  finally
    if Assigned(LExeSQL) then
    begin
      if LExeSQL.Active then
        LExeSQL.Close;
      _SetMonitorLog(LExeSQL.SQL.Text, LExeSQL.Transaction.Name, LParams);
      LExeSQL.Free;
    end;
    if Assigned(LParams) then
    begin
      LParams.Clear;
      LParams.Free;
    end;
  end;
end;

procedure TDriverFireDAC.ExecuteScript(const AScript: String);
begin
  AddScript(AScript);
  ExecuteScripts;
end;

procedure TDriverFireDAC.ExecuteScripts;
var
  LErrorLogged: Boolean;
  LCommand: IFDPhysCommand;
begin
  if FSQLScript.SQLScripts.Count = 0 then
    raise Exception.Create('No SQL scripts found to execute.');

  FRowsAffected := 0;
  FSQLScript.OnError := _DoMonitorLog;
  try
    if _GetTransactionActive = nil then
      raise Exception.Create('Transaction not assigned.');

    FSQLScript.Transaction := _GetTransactionActive;
    if not FSQLScript.ValidateAll then
      raise Exception.Create('One or more SQL scripts are invalid. Execution stopped.');
    try
      while FSQLScript.ExecuteStep do
      begin
        if Assigned(FSQLScript.CurrentCommand) and
           Supports(FSQLScript.CurrentCommand.EngineIntf.CommandIntf, IFDPhysCommand) then
        begin
          LCommand := FSQLScript.CurrentCommand.EngineIntf.CommandIntf;
          if LCommand.RowsAffected >= 0 then
            FRowsAffected := FRowsAffected + UInt32(LCommand.RowsAffected);
        end;
      end;
    except
      on E: EDatabaseError do
      begin
        _SetMonitorLog('Database error during script execution', E.Message, nil);
        raise;
      end;
      on E: Exception do
      begin
        _SetMonitorLog('General error during script execution', E.Message, nil);
        raise;
      end;
    end;  
  finally
    if FSQLScript.TotalErrors = 0 then
    begin
      _SetMonitorLog(FSQLScript.SQLScripts.Items[0].SQL.Text, FSQLScript.Transaction.Name, nil);
      _SetMonitorLog(Format('Script completed: %.1f%% done', [FSQLScript.TotalPct10Done / 10.0]),
                     FSQLScript.Transaction.Name, nil);
    end
    else
      _SetMonitorLog('Script execution completed with errors.', '', nil);

    if FSQLScript.SQLScripts.Count > 0 then
      FSQLScript.SQLScripts[0].SQL.Clear;

    FSQLScript.OnError := nil;
  end;
end;

// código permanecerá até conseguir testar o acima que consegue me informa lishas afetadas.

//procedure TDriverFireDAC.ExecuteScripts;
//begin
//  if FSQLScript.SQLScripts.Count = 0 then
//    Exit;
//  FSQLScript.OnError := _DoMonitorLog;
//  try
//    FSQLScript.Transaction := _GetTransactionActive;
//    if FSQLScript.ValidateAll then
//      FSQLScript.ExecuteAll;
//  finally
//    if FSQLScript.TotalErrors = 0 then
//      _SetMonitorLog(FSQLScript.SQLScripts.Items[0].SQL.Text, FSQLScript.Transaction.Name, nil);
//    FRowsAffected := 0;
//    FSQLScript.SQLScripts[0].SQL.Clear;
//    FSQLScript.OnError := nil;
//  end;
//end;

function TDriverFireDAC.GetSQLScripts: String;
begin
  Result := 'Transaction: ' + FSQLScript.Transaction.Name + ' ' + FSQLScript.SQLScripts.Items[0].SQL.Text;
end;

procedure TDriverFireDAC.AddScript(const AScript: String);
var
  LSQLScript: TFDSQLScript;
begin
  if Self.GetDriver in [TDBEngineDriver.dnInterbase,
                        TDBEngineDriver.dnFirebird,
                        TDBEngineDriver.dnFirebird3] then
  begin
    LSQLScript := FSQLScript.SQLScripts.Items[0];
    if LSQLScript.SQL.Count = 0 then
      LSQLScript.SQL.Add('SET AUTOCOMMIT OFF');
  end;
  FSQLScript.SQLScripts[0].SQL.Add(AScript);
end;

procedure TDriverFireDAC.ApplyUpdates(const ADataSets: array of IDBDataSet);
var
  LDataSet: IDBDataSet;
begin
  for LDataSet in ADataSets do
    LDataSet.ApplyUpdates;
end;

procedure TDriverFireDAC.Connect;
begin
  FConnection.Connected := True;
end;

function TDriverFireDAC.IsConnected: Boolean;
begin
  Result := FConnection.Connected = True;
end;

function TDriverFireDAC._GetTransactionActive: TFDTransaction;
begin
  Result := FDriverTransaction.TransactionActive as TFDTransaction;
end;

function TDriverFireDAC.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryFireDAC.Create(FConnection,
                                       FDriverTransaction,
                                       FMonitorCallback);
end;

function TDriverFireDAC.CreateDataSet(const ASQL: String): IDBDataSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryFireDAC.Create(FConnection,
                                         FDriverTransaction,
                                         FMonitorCallback);
  LDBQuery.CommandText := ASQL;
  Result := LDBQuery.ExecuteQuery;
end;

{ TDriverQueryFireDAC }

constructor TDriverQueryFireDAC.Create(const AConnection: TFDConnection;
  const ADriverTransaction: TDriverTransaction;
  const AMonitorCallback: TMonitorProc);
begin
  if AConnection = nil then
    raise EArgumentNilException.Create('AConnection cannot be nil');
  if ADriverTransaction = nil then
    raise EArgumentNilException.Create('ADriverTransaction cannot be nil');

  FDriverTransaction := ADriverTransaction;
  FMonitorCallback := AMonitorCallback;
  FFDQuery := TFDQuery.Create(nil);
  try
    FFDQuery.Connection := AConnection;
  except
    if Assigned(FFDQuery) then
      FFDQuery.Free;
    raise;
  end;
end;

destructor TDriverQueryFireDAC.Destroy;
begin
  FFDQuery.Free;
  inherited;
end;

function TDriverQueryFireDAC.ExecuteQuery: IDBDataSet;
var
  LDataSet: TFDQuery;
  LParams: TParams;
  LFor: Int16;
begin
  LDataSet := TFDQuery.Create(nil);
  LParams := nil;
  try
    if not Assigned(FFDQuery.Connection) then
      raise Exception.Create('Connection not assigned.');
    if _GetTransactionActive = nil then
      raise Exception.Create('Transaction not assigned.');

    LDataSet.Connection := FFDQuery.Connection;
    LDataSet.Transaction := _GetTransactionActive;
    LDataSet.SQL.Text := FFDQuery.SQL.Text;
    try
      if FFDQuery.Params.Count > 0 then
      begin
        for LFor := 0 to FFDQuery.Params.Count - 1 do
        begin
          if not Assigned(FFDQuery.Params[LFor]) then
            raise Exception.Create('Invalid or unassigned parameter.');

          LDataSet.Params[LFor].DataType := FFDQuery.Params[LFor].DataType;
          LDataSet.Params[LFor].Value := FFDQuery.Params[LFor].Value;
        end;
      end;
      if LDataSet.SQL.Text = '' then
        raise Exception.Create('SQL statement is empty. Cannot execute the query.');      if LDataSet.SQL.Text = '' then

      try
        if not LDataSet.Prepared then
          LDataSet.Prepare;
      except
        on E: Exception do
        begin
          _SetMonitorLog('Error preparing query', E.Message, LParams);
          raise;
        end;
      end;
      LDataSet.Open;
      Result := TDriverDataSetFireDAC.Create(LDataSet, FMonitorCallback);
      if LDataSet.Active then
      begin
        if LDataSet.RecordCount = 0 then
          Result.FetchingAll := True;
      end;
      LParams := LDataSet.AsParams;
    except
      on E: EDatabaseError do
      begin
        _SetMonitorLog(LDataSet.SQL.Text, E.Message, LParams);
        FreeAndNil(LDataSet);
        raise;
      end;
      on E: Exception do
      begin
        _SetMonitorLog('General error', E.Message, nil);
        FreeAndNil(LDataSet);
        raise;
      end;
    end;
  finally
    if Assigned(LDataSet) then
    begin
      if LDataSet.Active then
        LDataSet.Close;
      if LDataSet.SQL.Text <> '' then
        _SetMonitorLog(LDataSet.SQL.Text, LDataSet.Transaction.Name, LParams);
    end;
    if Assigned(LParams) then
    begin
      LParams.Clear;
      LParams.Free;
    end;
  end;
end;

function TDriverQueryFireDAC.RowsAffected: UInt32;
begin
  Result := FRowsAffected;
end;

function TDriverQueryFireDAC._GetCommandText: String;
begin
  Result := FFDQuery.SQL.Text;
end;

function TDriverQueryFireDAC._GetTransactionActive: TFDTransaction;
begin
  Result := FDriverTransaction.TransactionActive as TFDTransaction;
end;

procedure TDriverQueryFireDAC._SetCommandText(const ACommandText: String);
begin
  FFDQuery.SQL.Text := ACommandText;
end;

procedure TDriverQueryFireDAC.ExecuteDirect;
var
  LExeSQL: TFDQuery;
  LParams: TParams;
  LFor: Int16;
begin
  LExeSQL := TFDQuery.Create(nil);
  LParams := nil;
  try
    if not Assigned(FFDQuery.Connection) then
      raise Exception.Create('Connection not assigned.');
    if _GetTransactionActive = nil then
      raise Exception.Create('Transaction not assigned.');

    LExeSQL.Connection := FFDQuery.Connection;
    LExeSQL.Transaction := _GetTransactionActive;
    if FFDQuery.SQL.Text = '' then
      raise Exception.Create('SQL statement is empty. Cannot execute the query.');

    LExeSQL.SQL.Text := FFDQuery.SQL.Text;
    if FFDQuery.Params.Count > 0 then
    begin
      for LFor := 0 to FFDQuery.Params.Count - 1 do
      begin
        if not Assigned(FFDQuery.Params[LFor]) then
          raise Exception.Create('Invalid or unassigned parameter.');

        LExeSQL.Params[LFor].DataType := FFDQuery.Params[LFor].DataType;
        LExeSQL.Params[LFor].Value := FFDQuery.Params[LFor].Value;
      end;
    end;
    try
      if not LExeSQL.Prepared then
        LExeSQL.Prepare;
      LExeSQL.Execute;
    except
      on E: EDatabaseError do
      begin
        _SetMonitorLog(LExeSQL.SQL.Text, E.Message, LParams);
        raise;
      end;
      on E: Exception do
      begin
        _SetMonitorLog('General error', E.Message, nil);
        raise;
      end;
    end;
    LParams := LExeSQL.AsParams;
    FRowsAffected := LExeSQL.RowsAffected;
  finally
    if Assigned(LExeSQL) then
    begin
      if LExeSQL.Active then
        LExeSQL.Close;
      if LExeSQL.SQL.Text <> '' then
        _SetMonitorLog(LExeSQL.SQL.Text, LExeSQL.Transaction.Name, LParams);
      LExeSQL.Free;
    end;
    if Assigned(LParams) then
    begin
      LParams.Clear;
      LParams.Free;
    end;
  end;
end;

{ TDriverDataSetFireDAC }

procedure TDriverDataSetFireDAC.ApplyUpdates;
begin
  FDataSet.ApplyUpdates;
end;

procedure TDriverDataSetFireDAC.CancelUpdates;
begin
  FDataSet.CancelUpdates;
end;

constructor TDriverDataSetFireDAC.Create(const ADataSet: TFDQuery;
  const AMonitorCallback: TMonitorProc);
begin
  inherited Create(ADataSet, AMonitorCallback);
end;

destructor TDriverDataSetFireDAC.Destroy;
begin
  inherited;
end;

function TDriverDataSetFireDAC.IsCachedUpdates: Boolean;
begin
  Result := FDataSet.CachedUpdates;
end;

function TDriverDataSetFireDAC.IsReadOnly: Boolean;
begin
  Result := FDataSet.FetchOptions.Unidirectional;
end;

function TDriverDataSetFireDAC.IsUniDirectional: Boolean;
begin
  Result := FDataSet.IsUniDirectional;
end;

procedure TDriverDataSetFireDAC.Open;
var
  LParams: TParams;
begin
  try
    inherited Open;
    LParams := FDataSet.AsParams;
  finally
    _SetMonitorLog(FDataSet.SQL.Text, FDataSet.Transaction.Name, LParams);
    if Assigned(LParams) then
    begin
      LParams.Clear;
      LParams.Free;
    end;
  end;
end;

function TDriverDataSetFireDAC.RowsAffected: UInt32;
begin
  Result := FDataSet.RowsAffected;
end;

function TDriverDataSetFireDAC._GetCommandText: String;
begin
  Result := FDataSet.SQL.Text;
end;

procedure TDriverDataSetFireDAC._SetCachedUpdates(const Value: Boolean);
begin
  FDataSet.CachedUpdates := Value;
end;

procedure TDriverDataSetFireDAC._SetCommandText(const ACommandText: String);
begin
  FDataSet.SQL.Text := ACommandText;
end;

procedure TDriverDataSetFireDAC._SetReadOnly(const Value: Boolean);
begin
  FDataSet.FetchOptions.Unidirectional := Value;
end;

procedure TDriverDataSetFireDAC._SetUniDirectional(const Value: Boolean);
begin
  FDataSet.FetchOptions.Unidirectional := Value;
end;

end.
