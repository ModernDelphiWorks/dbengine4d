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

unit DBEngine.DriverAbsoluteDB;

interface

uses
  DB,
  Classes,
  SysUtils,
  ABSMain,
  Variants,
  /// DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  // Classe de conex�o concreta com dbExpress
  TDriverAbsoluteDB = class(TDriverConnection)
  protected
    FConnection: TABSDatabase;
    FSQLScript: TABSQuery;
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

  TDriverQueryAbsoluteDB = class(TDriverQuery)
  private
    FSQLQuery: TABSQuery;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TABSDatabase);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetAbsoluteDB = class(TDriverResultSet<TABSQuery>)
  public
    constructor Create(ADataSet: TABSQuery); override;
    destructor Destroy; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
  end;

implementation

{ TDriverAbsoluteDB }

constructor TDriverAbsoluteDB.Create(const AConnection: TComponent;
  const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TABSDatabase;
  FDriverName := ADriverName;
  if not FileExists(FConnection.DatabaseFileName) then
    FConnection.CreateDatabase;

  FSQLScript := TABSQuery.Create(nil);
  try
    FSQLScript.DatabaseName := FConnection.DatabaseName;
  except
    FSQLScript.Free;
    raise;
  end;
end;

destructor TDriverAbsoluteDB.Destroy;
begin
  FConnection := nil;
  FSQLScript.Free;
  inherited;
end;

procedure TDriverAbsoluteDB.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverAbsoluteDB.ExecuteDirect(const ASQL: String);
begin
  inherited;
  ExecuteScript(ASQL);
end;

procedure TDriverAbsoluteDB.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LExeSQL: TABSQuery;
  LFor: Int16;
begin
  LExeSQL := TABSQuery.Create(nil);
  try
    LExeSQL.DatabaseName := FConnection.DatabaseName;
    LExeSQL.SQL.Text := ASQL;
    for LFor := 0 to AParams.Count - 1 do
    begin
      LExeSQL.ParamByName(AParams[LFor].Name).DataType := AParams[LFor].DataType;
      LExeSQL.ParamByName(AParams[LFor].Name).Value    := AParams[LFor].Value;
    end;
    try
      LExeSQL.ExecSQL;
    except
      raise;
    end;
  finally
    LExeSQL.Free;
  end;
end;

procedure TDriverAbsoluteDB.ExecuteScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Text := AScript;
  FSQLScript.ExecSQL;
end;

procedure TDriverAbsoluteDB.ExecuteScripts;
begin
  inherited;
  try
    FSQLScript.ExecSQL;
  finally
    FSQLScript.SQL.Clear;
  end;
end;

function TDriverAbsoluteDB.CreateDataSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryAbsoluteDB.Create(FConnection);
  LDBQuery.CommandText := ASQL;
  Result   := LDBQuery.ExecuteQuery;
end;

procedure TDriverAbsoluteDB.AddScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Add(AScript);
end;

procedure TDriverAbsoluteDB.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverAbsoluteDB.InTransaction: Boolean;
begin
  inherited;
  Result := FConnection.InTransaction;
end;

function TDriverAbsoluteDB.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected = True;
end;

function TDriverAbsoluteDB.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryAbsoluteDB.Create(FConnection);
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryAbsoluteDB.Create(AConnection: TABSDatabase);
begin
  if AConnection = nil then
    Exit;

  FSQLQuery := TABSQuery.Create(nil);
  try
    FSQLQuery.DatabaseName := AConnection.DatabaseName;
  except
    FSQLQuery.Free;
    raise;
  end;
end;

destructor TDriverQueryAbsoluteDB.Destroy;
begin
  FSQLQuery.Free;
  inherited;
end;

function TDriverQueryAbsoluteDB.ExecuteQuery: IDBResultSet;
var
  LResultSet: TABSQuery;
  LFor: Int16;
begin
  LResultSet := TABSQuery.Create(nil);
  try
    LResultSet.DatabaseName := FSQLQuery.DatabaseName;
    LResultSet.SQL.Text := FSQLQuery.SQL.Text;

    for LFor := 0 to FSQLQuery.Params.Count - 1 do
    begin
      LResultSet.Params[LFor].DataType := FSQLQuery.Params[LFor].DataType;
      LResultSet.Params[LFor].Value    := FSQLQuery.Params[LFor].Value;
    end;
    LResultSet.Open;
  except
    LResultSet.Free;
    raise;
  end;
  Result := TDriverResultSetAbsoluteDB.Create(LResultSet);
  if LResultSet.RecordCount = 0 then
     Result.FetchingAll := True;
end;

function TDriverQueryAbsoluteDB.GetCommandText: String;
begin
  Result := FSQLQuery.SQL.Text;
end;

procedure TDriverQueryAbsoluteDB.SetCommandText(ACommandText: String);
begin
  inherited;
  FSQLQuery.SQL.Text := ACommandText;
end;

procedure TDriverQueryAbsoluteDB.ExecuteDirect;
begin
  FSQLQuery.ExecSQL;
end;

{ TDriverResultSetAbsoluteDB }

constructor TDriverResultSetAbsoluteDB.Create(ADataSet: TABSQuery);
begin
  FDataSet:= ADataSet;
  inherited;
end;

destructor TDriverResultSetAbsoluteDB.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetAbsoluteDB.GetFieldValue(const AFieldName: String): Variant;
var
  LField: TField;
begin
  LField := FDataSet.FieldByName(AFieldName);
  Result := GetFieldValue(LField.Index);
end;

function TDriverResultSetAbsoluteDB.GetField(const AFieldName: String): TField;
begin
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetAbsoluteDB.GetFieldType(const AFieldName: String): TFieldType;
begin
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetAbsoluteDB.GetFieldValue(const AFieldIndex: UInt16): Variant;
begin
  if AFieldIndex > FDataSet.FieldCount -1  then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
     Result := Variants.Null
  else
     Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetAbsoluteDB.NotEof: Boolean;
begin
  if not FFirstNext then
     FFirstNext := True
  else
     FDataSet.Next;

  Result := not FDataSet.Eof;
end;

end.
