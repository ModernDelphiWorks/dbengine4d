{
  DBE Brasil � um Engine de Conex�o simples e descomplicado for Delphi/Lazarus

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Vers�o 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos � permitido copiar e distribuir c�pias deste documento de
       licen�a, mas mud�-lo n�o � permitido.

       Esta vers�o da GNU Lesser General Public License incorpora
       os termos e condi��es da vers�o 3 da GNU General Public License
       Licen�a, complementado pelas permiss�es adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(DBE Framework)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <https://www.isaquepinheiro.com.br>)
}

unit DBEngine.DriverIBObjects;

interface

uses
  Classes,
  DB,
  Variants,
  SysUtils,

  IB_Components,
  IBODataset,
  IB_Access,

  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces,
  dbe.utils;

type
  // Classe de conex�o concreta com dbExpress
  TDriverIBObjects = class(TDriverConnection)
  protected
    FConnection: TIBODatabase;
    FSQLScript: TIBOQuery;
  public
    constructor Create(const AConnection: TComponent;
      const ADriverName: TDriverName); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure ExecuteDirect(const ASQL: String); overload; override;
    procedure ExecuteDirect(const ASQL: String;
      const AParams: TParams); overload; override;
    procedure ExecuteScript(const AScript: String); override;
    procedure AddScript(const AScript: String); override;
    procedure ExecuteScripts; override;
    function IsConnected: Boolean; override;
    function InTransaction: Boolean; override;
    function CreateQuery: IDBQuery; override;
    function CreateDataSet(const ASQL: String): IDBResultSet; override;
  end;

  TDriverQueryIBObjects = class(TDriverQuery)
  private
    FSQLQuery: TIBOQuery;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TIBODatabase);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetIBObjects = class(TDriverResultSet<TIBOQuery>)
  public
    constructor Create(ADataSet: TIBOQuery); override;
    destructor Destroy; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
  end;

implementation

{ TDriverIBObjects }

constructor TDriverIBObjects.Create(const AConnection: TComponent;
  const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TIBODatabase;
  FDriverName := ADriverName;
  FSQLScript := TIBOQuery.Create(nil);
  try
    FSQLScript.IB_Connection := FConnection;
    FSQLScript.IB_Transaction := FConnection.DefaultTransaction;
  except
    on E: Exception do
    begin
      FSQLScript.Free;
      raise Exception.Create(E.Message);
    end;
  end;
end;

destructor TDriverIBObjects.Destroy;
begin
  FConnection := nil;
  FSQLScript.Free;
  inherited;
end;

procedure TDriverIBObjects.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverIBObjects.ExecuteDirect(const ASQL: String);
begin
  inherited;
  ExecuteDirect(ASQL, nil);
end;

procedure TDriverIBObjects.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LExeSQL: TIBOQuery;
  LFor: UInt16;
begin
  LExeSQL := TIBOQuery.Create(nil);
  try
    LExeSQL.IB_Connection := FConnection;
    LExeSQL.IB_Transaction := FConnection.DefaultTransaction;
    LExeSQL.SQL.Text := ASQL;
    if AParams <> nil then
    begin
      for LFor := 0 to AParams.Count - 1 do
      begin
        LExeSQL.ParamByName(AParams[LFor].Name).DataType := AParams[LFor].DataType;
        LExeSQL.ParamByName(AParams[LFor].Name).Value    := AParams[LFor].Value;
      end;
    end;
    LExeSQL.ExecSQL;
  finally
    LExeSQL.Free;
  end;
end;

procedure TDriverIBObjects.ExecuteScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Text := AScript;
  FSQLScript.ExecSQL;
end;

procedure TDriverIBObjects.ExecuteScripts;
begin
  inherited;
  try
    FSQLScript.ExecSQL;
  finally
    FSQLScript.SQL.Clear;
  end;
end;

procedure TDriverIBObjects.AddScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Add(AScript);
end;

procedure TDriverIBObjects.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverIBObjects.InTransaction: Boolean;
begin
  inherited;
  Result := FConnection.DefaultTransaction.InTransaction;
end;

function TDriverIBObjects.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected;
end;

function TDriverIBObjects.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryIBObjects.Create(FConnection);
end;

function TDriverIBObjects.CreateDataSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryIBObjects.Create(FConnection);
  LDBQuery.CommandText := ASQL;
  Result   := LDBQuery.ExecuteQuery;
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryIBObjects.Create(AConnection: TIBODatabase);
begin
  if AConnection = nil then
    Exit;

  FSQLQuery := TIBOQuery.Create(nil);
  try
    FSQLQuery.IB_Connection := AConnection;
    FSQLQuery.IB_Transaction := AConnection.DefaultTransaction;
    FSQLQuery.UniDirectional := True;
  except
    on E: Exception do
    begin
      FSQLQuery.Free;
      raise Exception.Create(E.Message);
    end;
  end;
end;

destructor TDriverQueryIBObjects.Destroy;
begin
  FSQLQuery.Free;
  inherited;
end;

function TDriverQueryIBObjects.ExecuteQuery: IDBResultSet;
var
  LResultSet: TIBOQuery;
  LFor: UInt16;
begin
  LResultSet := TIBOQuery.Create(nil);
  try
    LResultSet.IB_Connection := FSQLQuery.IB_Connection;
    LResultSet.IB_Transaction := FSQLQuery.IB_Transaction;
    LResultSet.SQL.Text := FSQLQuery.SQL.Text;

    for LFor := 0 to FSQLQuery.Params.Count - 1 do
    begin
      LResultSet.Params[LFor].DataType := FSQLQuery.Params[LFor].DataType;
      LResultSet.Params[LFor].Value    := FSQLQuery.Params[LFor].Value;
    end;
    LResultSet.Open;
  except
    on E: Exception do
    begin
      LResultSet.Free;
      raise Exception.Create(E.Message);
    end;
  end;
  Result := TDriverResultSetIBObjects.Create(LResultSet);
  if LResultSet.RecordCount = 0 then
     Result.FetchingAll := True;
end;

function TDriverQueryIBObjects.GetCommandText: String;
begin
  Result := FSQLQuery.SQL.Text;
end;

procedure TDriverQueryIBObjects.SetCommandText(ACommandText: String);
begin
  inherited;
  FSQLQuery.SQL.Text := ACommandText;
end;

procedure TDriverQueryIBObjects.ExecuteDirect;
begin
  FSQLQuery.ExecSQL;
end;

{ TDriverResultSetIBObjects }

constructor TDriverResultSetIBObjects.Create(ADataSet: TIBOQuery);
begin
  FDataSet := ADataSet;
  inherited;
end;

destructor TDriverResultSetIBObjects.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetIBObjects.GetFieldValue(const AFieldName: String): Variant;
var
  LField: TField;
begin
  LField := FDataSet.FieldByName(AFieldName);
  Result := GetFieldValue(LField.Index);
end;

function TDriverResultSetIBObjects.GetField(const AFieldName: String): TField;
begin
  inherited;
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetIBObjects.GetFieldType(const AFieldName: String): TFieldType;
begin
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetIBObjects.GetFieldValue(const AFieldIndex: Integer): Variant;
begin
  if AFieldIndex > FDataSet.FieldCount -1  then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
    Result := Variants.Null
  else
    Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetIBObjects.NotEof: Boolean;
begin
  if not FFirstNext then
     FFirstNext := True
  else
     FDataSet.Next;

  Result := not FDataSet.Eof;
end;

end.