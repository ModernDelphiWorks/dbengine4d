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

unit DBEngine.DriverWireMongoDB;

interface

uses
  DB,
  Classes,
  SysUtils,
  DBClient,
  Variants,
  StrUtils,
  Math,
  /// MongoDB
  mongoWire,
  bsonTools,
  JsonDoc,
  MongoWireConnection,
  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  TMongoDBQuery = class(TCustomClientDataSet)
  private
    FConnection: TMongoWireConnection;
    FCollection: String;
    procedure SetConnection(AConnection: TMongoWireConnection);
    function GetSequence(AMongoCampo: String): Int64;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Find(ACommandText: String);
    property Collection: String read FCollection write FCollection;
  end;

  // Classe de conex�o concreta com dbExpress
  TDriverMongoWire = class(TDriverConnection)
  protected
    FConnection: TMongoWireConnection;
//    FScripts: TStrings;
    procedure CommandUpdateExecute(const ACommandText: String; const AParams: TParams);
    procedure CommandInsertExecute(const ACommandText: String; const AParams: TParams);
    procedure CommandDeleteExecute(const ACommandText: String; const AParams: TParams);
  public
    constructor Create(const AConnection: TComponent; const ADriverName: TDriverName); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure ExecuteDirect(const ASQL: String); override;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); override;
    procedure ExecuteScript(const AScript: String); override;
    procedure AddScript(const AScript: String); override;
    procedure ExecuteScripts; override;
    function IsConnected: Boolean; override;
    function InTransaction: Boolean; override;
    function CreateQuery: IDBQuery; override;
    function CreateDataSet(const ASQL: String): IDBResultSet; override;
  end;

  TDriverQueryMongoWire = class(TDriverQuery)
  private
    FConnection: TMongoWireConnection;
    FCommandText: String;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TMongoWireConnection);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetMongoWire = class(TDriverResultSet<TMongoDBQuery>)
  public
    constructor Create(ADataSet: TMongoDBQuery); override;
    destructor Destroy; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
  end;

implementation

uses
  ormbr.utils,
  ormbr.bind,
  ormbr.mapping.explorer,
  ormbr.rest.json,
  ormbr.mapping.rttiutils,
  ormbr.objects.helper;

{ TDriverMongoWire }

constructor TDriverMongoWire.Create(const AConnection: TComponent; const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TMongoWireConnection;
  FDriverName := ADriverName;
//  FScripts := TStrings.Create;
end;

destructor TDriverMongoWire.Destroy;
begin
//  FScripts.Free;
  FConnection := nil;
  inherited;
end;

procedure TDriverMongoWire.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverMongoWire.ExecuteDirect(const ASQL: String);
begin
  inherited;
  try
    FConnection.RunCommand(ASQL);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
end;

procedure TDriverMongoWire.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LCommand: String;
begin
  LCommand := TUtilSingleton
                .GetInstance
                  .ParseCommandNoSQL('command', ASQL);
  if LCommand = 'insert' then
    CommandInsertExecute(ASQL, Aparams)
  else
  if LCommand = 'update' then
    CommandUpdateExecute(ASQL, AParams)
  else
  if LCommand = 'delete' then
    CommandDeleteExecute(ASQL, AParams);
end;

procedure TDriverMongoWire.ExecuteScript(const AScript: String);
begin
  inherited;
  try
    FConnection.RunCommand(AScript);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
end;

procedure TDriverMongoWire.ExecuteScripts;
//var
//  LFor: UInt16;
begin
  inherited;
//  try
//    for LFor := 0 to FScripts.Count -1 do
//      FConnection.RunCommand(FScripts[LFor]);
//  finally
//    FScripts.Clear;
//  end;
end;

procedure TDriverMongoWire.AddScript(const AScript: String);
begin
  inherited;
//  FScripts.Add(ASQL);
end;

procedure TDriverMongoWire.CommandInsertExecute(const ACommandText: String;
  const AParams: TParams);
var
  LDoc: IJSONDocument;
  LQuery: String;
  LCollection: String;
  LUtil: IUtilSingleton;
begin
  LUtil := TUtilSingleton.GetInstance;
  LCollection := LUtil.ParseCommandNoSQL('collection', ACommandText);
  LQuery := LUtil.ParseCommandNoSQL('json', ACommandText);
  LDoc := JSON(LQuery);
  try
    FConnection
      .MongoWire
        .Insert(LCollection, LDoc);
  except
    raise EMongoException.Create('MongoWire: n�o foi poss�vel inserir o Documento');
  end;
end;

procedure TDriverMongoWire.CommandUpdateExecute(const ACommandText: String;
  const AParams: TParams);
var
  LDocQuery: IJSONDocument;
  LDocFilter: IJSONDocument;
  LFilter: String;
  LQuery: String;
  LCollection: String;
  LUtil: IUtilSingleton;
begin
  LUtil := TUtilSingleton.GetInstance;
  LCollection := LUtil.ParseCommandNoSQL('collection', ACommandText);
  LFilter := LUtil.ParseCommandNoSQL('filter', ACommandText);
  LQuery := LUtil.ParseCommandNoSQL('json', ACommandText);
  LDocQuery := JSON(LQuery);
  LDocFilter := JSON(LFilter);
  try
    FConnection
      .MongoWire
        .Update(LCollection, LDocFilter, LDocQuery);
  except
    raise EMongoException.Create('MongoWire: n�o foi poss�vel alterar o Documento');
  end;
end;

procedure TDriverMongoWire.CommandDeleteExecute(const ACommandText: String;
  const AParams: TParams);
var
  LDoc: IJSONDocument;
  LQuery: String;
  LCollection: String;
  LUtil: IUtilSingleton;
begin
  LUtil := TUtilSingleton.GetInstance;
  LCollection := LUtil.ParseCommandNoSQL('collection', ACommandText);
  LQuery := LUtil.ParseCommandNoSQL('json', ACommandText);
  LDoc := JSON(LQuery);
  try
    FConnection
      .MongoWire
        .Delete(LCollection, LDoc);
  except
    raise EMongoException.Create('MongoWire: n�o foi poss�vel remover o Documento');
  end;
end;

procedure TDriverMongoWire.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverMongoWire.InTransaction: Boolean;
begin
  Result := False;
end;

function TDriverMongoWire.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected = True;
end;

function TDriverMongoWire.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryMongoWire.Create(FConnection);
end;

function TDriverMongoWire.CreateDataSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryMongoWire.Create(FConnection);
  LDBQuery.CommandText := ASQL;
  Result := LDBQuery.ExecuteQuery;
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryMongoWire.Create(AConnection: TMongoWireConnection);
begin
  FConnection := AConnection;
end;

destructor TDriverQueryMongoWire.Destroy;
begin
  inherited;
end;

function TDriverQueryMongoWire.ExecuteQuery: IDBResultSet;
var
  LUtil: IUtilSingleton;
  LResultSet: TMongoDBQuery;
  LObject: TObject;
begin
  LUtil := TUtilSingleton.GetInstance;
  LResultSet := TMongoDBQuery.Create(nil);
  LResultSet.SetConnection(FConnection);
  LResultSet.Collection := LUTil.ParseCommandNoSQL('collection', FCommandText);
  LObject :=  TMappingExplorer
                .GetInstance
                  .Repository
                    .FindEntityByName('T' + LResultSet.Collection).Create;
  TBind.Instance
       .SetInternalInitFieldDefsObjectClass(LResultSet, LObject);
  LResultSet.CreateDataSet;
  LResultSet.LogChanges := False;
  try
    try
      LResultSet.Find(FCommandText);
    except
      on E: Exception do
      begin
        LResultSet.Free;
        raise Exception.Create(E.Message);
      end;
    end;
    Result := TDriverResultSetMongoWire.Create(LResultSet);
    if LResultSet.RecordCount = 0 then
       Result.FetchingAll := True;
  finally
    LObject.Free;
  end;
end;

function TDriverQueryMongoWire.GetCommandText: String;
begin
  Result := FCommandText;
end;

procedure TDriverQueryMongoWire.SetCommandText(ACommandText: String);
begin
  inherited;
  FCommandText := ACommandText;
end;

procedure TDriverQueryMongoWire.ExecuteDirect;
begin
  try
    FConnection.RunCommand(FCommandText);
  except
    on E: Exception do
      raise Exception.Create(E.Message);
  end;
end;

{ TDriverResultSetMongoWire }

constructor TDriverResultSetMongoWire.Create(ADataSet: TMongoDBQuery);
begin
  FDataSet := ADataSet;
  inherited;
end;

destructor TDriverResultSetMongoWire.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetMongoWire.GetFieldValue(const AFieldName: String): Variant;
var
  LField: TField;
begin
  LField := FDataSet.FieldByName(AFieldName);
  Result := GetFieldValue(LField.Index);
end;

function TDriverResultSetMongoWire.GetField(const AFieldName: String): TField;
begin
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetMongoWire.GetFieldType(const AFieldName: String): TFieldType;
begin
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetMongoWire.GetFieldValue(const AFieldIndex: UInt16): Variant;
begin
  if AFieldIndex > FDataSet.FieldCount - 1 then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
    Result := Variants.Null
  else
    Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetMongoWire.NotEof: Boolean;
begin
  if not FFirstNext then
    FFirstNext := True
  else
    FDataSet.Next;
  Result := not FDataSet.Eof;
end;

{ TMongoDBQuery }

constructor TMongoDBQuery.Create(AOwner: TComponent);
begin
  inherited;

end;

destructor TMongoDBQuery.Destroy;
begin

  inherited;
end;

procedure TMongoDBQuery.Find(ACommandText: String);
var
  LDocQuery: IJSONDocument;
  LDocRecord: IJSONDocument;
  LDocFields: IJSONDocument;
  LQuery: TMongoWireQuery;
  LUtil: IUtilSingleton;
  LObject: TObject;
  LFilter: String;
begin
  LUtil := TUtilSingleton.GetInstance;
  LFilter := LUtil.ParseCommandNoSQL('filter', ACommandText, '{}');
  LDocQuery  := JSON(LFilter);
  LDocFields := JSON('{_id:0}');
  LDocRecord := JSON;
  LQuery := TMongoWireQuery.Create(FConnection.MongoWire);
  DisableControls;
  try
    LQuery.Query(FCollection, LDocQuery, LDocFields);
    while LQuery.Next(LDocRecord) do
    begin
      LObject := TMappingExplorer
                   .GetInstance
                     .Repository
                       .FindEntityByName('T' + FCollection).Create;
      LObject.MethodCall('Create', []);
      try
        TORMBrJson
          .JsonToObject(LDocRecord.ToString, LObject);
        /// <summary>
        /// Popula do dataset usado pelo ORMBr
        /// </summary>
        Append;
        TBind.Instance
             .SetPropertyToField(LObject, Self);
        Post;
      finally
        LObject.Free;
      end;
    end;
  finally
    LQuery.Free;
    First;
    EnableControls;
  end;
end;

function TMongoDBQuery.GetSequence(AMongoCampo: String): Int64;
//Var
//  LDocD, LChave, LDocR: IJSONDocument;
//  LJsonObj: TJSONObject;
//  LField, LComandSave, LComandModify: TStringBuilder;
//  LCollectionSeq, sCollectionField: String;
//  LRetorno: Int64;
begin
//  LField := TStringBuilder.Create;
//  LComandSave := TStringBuilder.Create;
//  LComandModify := TStringBuilder.Create;
//  LJsonObj := TJSONObject.Create;
//  try
//    LComandSave.clear;
//    LComandModify.clear;
//    LField.clear;
//    LField.Append('_id_').Append(AnsiLowerCase( AMongoCampo ));
//
//    LCollectionSeq := '_sequence';
//    sCollectionField := '_id';
//
//    LComandSave.Append('{ findAndModify: "')
//                .Append(LCollectionSeq)
//                .Append('", query: { ')
//                .Append(sCollectionField)
//                .Append(': "')
//                .Append(FCollection)
//                .Append('" }, update: {')
//                .Append(sCollectionField)
//                .Append(': "')
//                .Append(FCollection)
//                .Append('", ')
//                .Append(LField.ToString)
//                .Append(': 0 }, upsert:True }');
//
//    LComandModify.Append('{ findAndModify: "')
//                  .Append(LCollectionSeq)
//                  .Append('", query: { ')
//                  .Append(sCollectionField)
//                  .Append(': "')
//                  .Append(FCollection)
//                  .Append('" }, update: { $inc: { ')
//                  .Append(LField.ToString)
//                  .Append(': 1 } }, new:True }');

//    LJsonObj.AddPair(sCollectionField, TJSONString.Create(FCollection));
//    LChave := LJsonObj.ToJSON;
//    try
//      LDocD := FConnection.FMongoWire.Get(LCollectionSeq, LChave);
//      LRetorno := StrToInt64(VarToStr(LDocD[LField.ToString]));
//    except
//      LDocD := JsonToBson(LComandSave.ToString);
//      LDocR := FConnection.FMongoWire.RunCommand(LDocD);
//    end;
//    try
//      LDocD := JsonToBson(LComandModify.ToString);
//      LDocR := FConnection.FMongoWire.RunCommand(LDocD);
//      Result := StrToInt(VarToStr(BSON(LDocR['value'])[LField.ToString]));
//    except
//      Result := -1;
//      raise EMongoException.Create('Mongo: n�o foi poss�vel gerar o AutoIncremento.');
//    end;
//  finally
//    LField.Free;
//    LComandSave.Free;
//    LComandModify.Free;
//    LJsonObj.Free;
//  end;
end;

procedure TMongoDBQuery.SetConnection(AConnection: TMongoWireConnection);
begin
  FConnection := AConnection;
end;

end.
