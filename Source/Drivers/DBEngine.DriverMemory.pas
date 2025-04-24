{
  @abstract(DBEngine4D: In-Memory Driver for Delphi)
  @description(In-memory database driver for the DBEngine4D framework)
  @created(03 Abr 2025)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @Discord(https://discord.gg/T2zJC8zX)
}

unit DBEngine.DriverMemory;

interface

uses
  DB,
  Math,
  Classes,
  SysUtils,
  StrUtils,
  Variants,
  Generics.Collections,
  DBEngine.Consts,
  DBEngine.DriverConnection,
  DBEngine.FactoryInterfaces,
  System.Fluent,
  System.Fluent.Collections,
  System.Fluent.Helpers;

type
  TMemoryRecord = class;

  IEntityCollection<T: class> = interface
    ['{C58080A0-5196-412E-9ABD-356AD42CEADF}']
    procedure Add(const AEntity: T);
    function AsEnumerable: IFluentEnumerable<T>;
    function Count: Integer;
  end;

  TEntityCollectionAdapter<T: class> = class(TInterfacedObject, IEntityCollection<T>)
  private
    FList: TFluentList<T>;
  public
    constructor Create(const AList: TFluentList<T>);
    destructor Destroy; override;
    procedure Add(const AEntity: T);
    function AsEnumerable: IFluentEnumerable<T>;
    function Count: Integer;
  end;

  TJoins = record
    TableName: string;
    Join: string;
    JoinCondition: string;
    Where: string;
  end;

  TJoinFields = record
    LeftField: string;
    RightField: string;
  end;

  TJoinConditionParser = class
  private
    FMonitorCallback: TMonitorProc;
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
  public
    constructor Create(const AMonitorCallback: TMonitorProc);
    function Parse(const AJoinCondition: string): TJoinFields;
  end;

  TJoinExecutor = class
  private
    FMonitorCallback: TMonitorProc;
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
    function _ExtractFieldName(const FullFieldName: string): string;
  public
    constructor Create(const AMonitorCallback: TMonitorProc);
    function ExecuteJoin(const ATable, AJoinTable: IEntityCollection<TMemoryRecord>;
      const ATableName, AJoinTableName: string; const AJoinFields: TJoinFields): TFluentList<TMemoryRecord>;
  end;

  TWhereFilter = class
  private
    FMonitorCallback: TMonitorProc;
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
  public
    constructor Create(const AMonitorCallback: TMonitorProc);
    function ApplyWhere(const ARecords: TFluentList<TMemoryRecord>; const AWhere: string): TFluentList<TMemoryRecord>;
  end;

  ISqlParser = interface
    ['{FA1CA4A8-803D-4D70-BB80-EEE60231CD26}']
    function ParseSelect(const ASQL: string): TJoins;
  end;

  IQueryExecutor = interface
    ['{EA32C54B-11F0-479F-A98F-EA70C5B696D6}']
    function ExecuteSelect(const ATable: IEntityCollection<TMemoryRecord>;
      const AJoinTable: IEntityCollection<TMemoryRecord>;
      const ATableName, AJoinTableName, AJoinCondition, AWhere: string): TFluentList<TMemoryRecord>;
  end;

  TSqlParser = class(TInterfacedObject, ISqlParser)
  private
    FCommandMonitor: ICommandMonitor;
    FMonitorCallback: TMonitorProc;
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
  public
    constructor Create(const AMonitorCallback: TMonitorProc);
    function ParseSelect(const ASQL: string): TJoins;
  end;

  TQueryExecutor = class(TInterfacedObject, IQueryExecutor)
  private
    FJoinConditionParser: TJoinConditionParser;
    FJoinExecutor: TJoinExecutor;
    FWhereFilter: TWhereFilter;
    FCommandMonitor: ICommandMonitor;
    FMonitorCallback: TMonitorProc;
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
  public
    constructor Create(const AMonitorCallback: TMonitorProc);
    destructor Destroy; override;
    function ExecuteSelect(const ATable: IEntityCollection<TMemoryRecord>;
      const AJoinTable: IEntityCollection<TMemoryRecord>;
      const ATableName, AJoinTableName, AJoinCondition, AWhere: string): TFluentList<TMemoryRecord>;
  end;

  TMemoryRecord = class
  private
    FFields: TFluentDictionary<string, Variant>;
  public
    constructor Create;
    destructor Destroy; override;
    property Fields: TFluentDictionary<string, Variant> read FFields;
  end;

  TMemoryField = class(TField)
  private
    FRecord: TMemoryRecord;
    FFieldName: string;
  protected
    function GetAsVariant: Variant; override;
    procedure SetAsVariant(const Value: Variant); override;
    function GetIsNull: Boolean; override;
    function GetAsString: string; override;
    function GetAsFloat: Double; override;
    function GetAsInteger: Longint; override;
    function GetAsBoolean: Boolean; override;
  public
    constructor Create(AOwner: TComponent; ARecord: TMemoryRecord; AFieldName: string); reintroduce;
  end;

  TMemoryDriver = class(TDriverConnection)
  private
    FTables: TFluentDictionary<string, TFluentList<TMemoryRecord>>;
    FConnection: TComponent;
    FConnected: Boolean;
    FSQLScripts: TStringList;
    FSqlParser: ISqlParser;
    FQueryExecutor: IQueryExecutor;
    function _ExecuteSelect(const ASQL: string; const AParams: TParams): IDBDataSet;
    procedure _ParseAndExecuteSQL(const ASQL: string; const AParams: TParams = nil);
    procedure _ExecuteInsert(const ASQL: string; const AParams: TParams);
    procedure _ExecuteUpdate(const ASQL: string; const AParams: TParams);
    procedure _ExecuteDelete(const ASQL: string; const AParams: TParams);
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
    procedure _ClearTables;
  public
    constructor Create(const AConnection: TComponent; const ADriverTransaction: TDriverTransaction;
      const ADriver: TDBEDriver; const AMonitorCallback: TMonitorProc); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure ExecuteDirect(const ASQL: String); overload; override;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); overload; override;
    procedure ExecuteScript(const AScript: String); override;
    procedure AddScript(const AScript: String); override;
    procedure ExecuteScripts; override;
    procedure ApplyUpdates(const ADataSets: array of IDBDataSet); override;
    function IsConnected: Boolean; override;
    function CreateQuery: IDBQuery; override;
    function CreateDataSet(const ASQL: String): IDBDataSet; override;
    function GetSQLScripts: String; override;
  end;

  TMemoryQuery = class(TDriverQuery)
  private
    FSQL: string;
    FParams: TParams;
    FDriver: TMemoryDriver;
  protected
    procedure _SetCommandText(const ACommandText: String); override;
    function _GetCommandText: String; override;
  public
    constructor Create(const ADriver: TMemoryDriver; const ADriverTransaction: TDriverTransaction;
      const AMonitorCallback: TMonitorProc);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBDataSet; override;
    function RowsAffected: UInt32; override;
  end;

  TMemoryDataSet = class(TDriverDataSetBase)
  private
    FRecords: TFluentList<TMemoryRecord>;
    FCurrentIndex: Integer;
    FActive: Boolean;
    FSQL: string;
    FFields: TList<TMemoryField>;
    FState: TDataSetState;
    FModified: Boolean;
    FBookmarks: TList<Integer>;
    procedure _SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
    procedure UpdateFields;
  protected
    function _GetFilter: String; override;
    function _GetFiltered: Boolean; override;
    function _GetFilterOptions: TFilterOptions; override;
    function _GetActive: Boolean; override;
    function _GetCommandText: String; override;
    function _GetAfterCancel: TDataSetNotifyEvent; override;
    function _GetAfterClose: TDataSetNotifyEvent; override;
    function _GetAfterDelete: TDataSetNotifyEvent; override;
    function _GetAfterEdit: TDataSetNotifyEvent; override;
    function _GetAfterInsert: TDataSetNotifyEvent; override;
    function _GetAfterOpen: TDataSetNotifyEvent; override;
    function _GetAfterPost: TDataSetNotifyEvent; override;
    function _GetAfterRefresh: TDataSetNotifyEvent; override;
    function _GetAfterScroll: TDataSetNotifyEvent; override;
    function _GetAutoCalcFields: Boolean; override;
    function _GetBeforeCancel: TDataSetNotifyEvent; override;
    function _GetBeforeClose: TDataSetNotifyEvent; override;
    function _GetBeforeDelete: TDataSetNotifyEvent; override;
    function _GetBeforeEdit: TDataSetNotifyEvent; override;
    function _GetBeforeInsert: TDataSetNotifyEvent; override;
    function _GetBeforeOpen: TDataSetNotifyEvent; override;
    function _GetBeforePost: TDataSetNotifyEvent; override;
    function _GetBeforeRefresh: TDataSetNotifyEvent; override;
    function _GetBeforeScroll: TDataSetNotifyEvent; override;
    function _GetOnCalcFields: TDataSetNotifyEvent; override;
    function _GetOnDeleteError: TDataSetErrorEvent; override;
    function _GetOnEditError: TDataSetErrorEvent; override;
    function _GetOnFilterRecord: TFilterRecordEvent; override;
    function _GetOnNewRecord: TDataSetNotifyEvent; override;
    function _GetOnPostError: TDataSetErrorEvent; override;
    function _GetSortFields: String; override;
    function _GetBookmark: TBookmark; override;
    function _GetFetchingAll: Boolean; override;
    procedure _SetFilter(const Value: String); override;
    procedure _SetFiltered(const Value: Boolean); override;
    procedure _SetFilterOptions(Value: TFilterOptions); override;
    procedure _SetActive(const Value: Boolean); override;
    procedure _SetCommandText(const ACommandText: String); override;
    procedure _SetUniDirectional(const Value: Boolean); override;
    procedure _SetReadOnly(const Value: Boolean); override;
    procedure _SetCachedUpdates(const Value: Boolean); override;
    procedure _SetAfterCancel(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterOpen(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterClose(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterDelete(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterEdit(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterInsert(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterPost(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterRefresh(const Value: TDataSetNotifyEvent); override;
    procedure _SetAfterScroll(const Value: TDataSetNotifyEvent); override;
    procedure _SetAutoCalcFields(const Value: Boolean); override;
    procedure _SetBeforeCancel(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeDelete(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeEdit(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeInsert(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeOpen(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeClose(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforePost(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeRefresh(const Value: TDataSetNotifyEvent); override;
    procedure _SetBeforeScroll(const Value: TDataSetNotifyEvent); override;
    procedure _SetOnFilterRecord(const Value: TFilterRecordEvent); override;
    procedure _SetOnCalcFields(const Value: TDataSetNotifyEvent); override;
    procedure _SetOnDeleteError(const Value: TDataSetErrorEvent); override;
    procedure _SetOnEditError(const Value: TDataSetErrorEvent); override;
    procedure _SetOnNewRecord(const Value: TDataSetNotifyEvent); override;
    procedure _SetOnPostError(const Value: TDataSetErrorEvent); override;
    procedure _SetSortFields(const Value: String); override;
    procedure _SetFetchingAll(const Value: Boolean); override;
  public
    constructor Create(const ARecords: TFluentList<TMemoryRecord>; const ASQL: string;
      const AMonitorCallback: TMonitorProc);
    destructor Destroy; override;
    procedure Open; override;
    procedure Close; override;
    procedure Refresh; override;
    procedure Delete; override;
    procedure Cancel; override;
    procedure Clear; override;
    procedure DisableControls; override;
    procedure EnableControls; override;
    procedure Next; override;
    procedure Prior; override;
    procedure Append; override;
    procedure Insert; override;
    procedure Edit; override;
    procedure Post; override;
    procedure First; override;
    procedure Last; override;
    procedure MoveBy(Distance: Integer); override;
    procedure CheckRequiredFields; override;
    procedure FreeBookmark(Bookmark: TBookmark); override;
    procedure ClearFields; override;
    procedure ApplyUpdates; override;
    procedure CancelUpdates; override;
    function Locate(const KeyFields: String; const KeyValues: Variant;
      Options: TLocateOptions): Boolean; override;
    function Lookup(const KeyFields: String; const KeyValues: Variant;
      const ResultFields: String): Variant; override;
    function FieldCount: UInt16; override;
    function State: TDataSetState; override;
    function Modified: Boolean; override;
    function FieldByName(const AFieldName: String): TField; override;
    function RecordCount: UInt32; override;
    function FieldDefs: TFieldDefs; override;
    function Eof: Boolean; override;
    function Bof: Boolean; override;
    function RecNo: Integer; override;
    function CanRefresh: Boolean; override;
    function DataSetField: TDataSetField; override;
    function DefaultFields: Boolean; override;
    function Designer: TDataSetDesigner; override;
    function FieldList: TFieldList; override;
    function Found: Boolean; override;
    function ObjectView: Boolean; override;
    function RecordSize: Word; override;
    function SparseArrays: Boolean; override;
    function FieldDefList: TFieldDefList; override;
    function Fields: TFields; override;
    function AggFields: TFields; override;
    function UpdateStatus: TUpdateStatus; override;
    function CanModify: Boolean; override;
    function IsEmpty: Boolean; override;
    function DataSource: TDataSource; override;
    function AsDataSet: TDataSet; override;
    function IsUniDirectional: Boolean; override;
    function IsReadOnly: Boolean; override;
    function IsCachedUpdates: Boolean; override;
    function RowsAffected: UInt32; override;
    function NormalizeFieldValue(const AFieldName: String; const AValue: Variant): Variant; override;
  end;

implementation

{ TEntityCollectionAdapter<T> }

constructor TEntityCollectionAdapter<T>.Create(const AList: TFluentList<T>);
begin
  inherited Create;
  FList := AList;
end;

destructor TEntityCollectionAdapter<T>.Destroy;
begin
  FList := nil;
  inherited;
end;

procedure TEntityCollectionAdapter<T>.Add(const AEntity: T);
begin
  if Assigned(FList) then
    FList.Add(AEntity);
end;

function TEntityCollectionAdapter<T>.AsEnumerable: IFluentEnumerable<T>;
begin
  if Assigned(FList) then
    Result := FList.AsEnumerable
  else
    Result := TFluentList<T>.Create.AsEnumerable;
end;

function TEntityCollectionAdapter<T>.Count: Integer;
begin
  if Assigned(FList) then
    Result := FList.Count
  else
    Result := 0;
end;

{ TJoinConditionParser }

constructor TJoinConditionParser.Create(const AMonitorCallback: TMonitorProc);
begin
  FMonitorCallback := AMonitorCallback;
end;

procedure TJoinConditionParser._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

function TJoinConditionParser.Parse(const AJoinCondition: string): TJoinFields;
begin
  _SetMonitorLog(Format('Parsing join condition: %s', [AJoinCondition]), '', nil);
  Result.LeftField := Trim(Copy(AJoinCondition, 1, Pos('=', AJoinCondition) - 1));
  if Pos('.', Result.LeftField) > 0 then
    Result.LeftField := Copy(Result.LeftField, Pos('.', Result.LeftField) + 1);
  Result.RightField := Trim(Copy(AJoinCondition, Pos('=', AJoinCondition) + 1, Length(AJoinCondition)));
  if Pos('.', Result.RightField) > 0 then
    Result.RightField := Copy(Result.RightField, Pos('.', Result.RightField) + 1);
  _SetMonitorLog(Format('Parsed join: Left=%s, Right=%s', [Result.LeftField, Result.RightField]), '', nil);
end;

{ TJoinExecutor }

constructor TJoinExecutor.Create(const AMonitorCallback: TMonitorProc);
begin
  FMonitorCallback := AMonitorCallback;
end;

function TJoinExecutor.ExecuteJoin(const ATable, AJoinTable: IEntityCollection<TMemoryRecord>;
  const ATableName, AJoinTableName: string; const AJoinFields: TJoinFields): TFluentList<TMemoryRecord>;
var
  LResult: TFluentList<TMemoryRecord>;
  LNewRecord: TMemoryRecord;
  LPair: TPair<string, Variant>;
  LLeftValue, LRightValue: Variant;
  LLeft, LRight: TMemoryRecord;
begin
  LResult := TFluentList<TMemoryRecord>.Create;
  try
    if (ATable = nil) or (AJoinTable = nil) then
    begin
      _SetMonitorLog(Format('Join failed: ATable=%s, AJoinTable=%s',
        [IfThen(ATable = nil, 'nil', 'not nil'), IfThen(AJoinTable = nil, 'nil', 'not nil')]), '', nil);
      Exit(LResult);
    end;

    _SetMonitorLog(Format('Join condition: %s = %s', [AJoinFields.LeftField, AJoinFields.RightField]), '', nil);

    for LLeft in ATable.AsEnumerable do
    begin
      if (LLeft = nil) or (not LLeft.Fields.TryGetValue(AJoinFields.LeftField, LLeftValue)) then
      begin
        _SetMonitorLog(Format('Skipping LLeft: nil or %s not found', [AJoinFields.LeftField]), '', nil);
        Continue;
      end;
      for LRight in AJoinTable.AsEnumerable do
      begin
        if (LRight = nil) or (not LRight.Fields.TryGetValue(AJoinFields.RightField, LRightValue)) then
        begin
          _SetMonitorLog(Format('Skipping LRight: nil or %s not found', [AJoinFields.RightField]), '', nil);
          Continue;
        end;
        if VarToStr(LLeftValue) = VarToStr(LRightValue) then
        begin
          LNewRecord := TMemoryRecord.Create;
          try
            for LPair in LLeft.Fields do
              LNewRecord.Fields.Add(ATableName + '.' + LPair.Key, LPair.Value);
            for LPair in LRight.Fields do
              LNewRecord.Fields.Add(AJoinTableName + '.' + LPair.Key, LPair.Value);
            LResult.Add(LNewRecord);
            _SetMonitorLog(Format('Join match: %s=%s, %s=%s',
              [AJoinFields.LeftField, VarToStr(LLeftValue), AJoinFields.RightField, VarToStr(LRightValue)]), '', nil);
          except
            LNewRecord.Free;
            raise;
          end;
        end;
      end;
    end;
  finally
    Result := LResult;
  end;
end;

function TJoinExecutor._ExtractFieldName(const FullFieldName: string): string;
begin
  Result := FullFieldName.Substring(FullFieldName.LastIndexOf('.') + 1);
end;

procedure TJoinExecutor._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

{ TWhereFilter }

constructor TWhereFilter.Create(const AMonitorCallback: TMonitorProc);
begin
  FMonitorCallback := AMonitorCallback;
end;

procedure TWhereFilter._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

function TWhereFilter.ApplyWhere(const ARecords: TFluentList<TMemoryRecord>; const AWhere: string): TFluentList<TMemoryRecord>;
var
  LResult: TFluentList<TMemoryRecord>;
  LWhereParts: TArray<string>;
begin
  LResult := TFluentList<TMemoryRecord>.Create;
  try
    if (ARecords = nil) or (AWhere = '') then
    begin
      if ARecords <> nil then
        LResult.AddRange(ARecords.ToArray);
      Exit(LResult);
    end;

    LWhereParts := AWhere.Split([' AND ']);
    LResult.AddRange(
      ARecords.AsEnumerable.Where(
        function(R: TMemoryRecord): Boolean
        var
          LWhere: string;
          LMatch: Boolean;
          LVariant: Variant;
          LTryVariant: Variant;
          LWhereCondition, LField, LValue, LOperator: string;
        begin
          LMatch := True;
          for LWhere in LWhereParts do
          begin
            LWhereCondition := Trim(LWhere);
            if Pos('LIKE', UpperCase(LWhereCondition)) > 0 then
            begin
              LField := Trim(Copy(LWhereCondition, 1, Pos('LIKE', UpperCase(LWhereCondition)) - 1));
              LValue := Trim(Copy(LWhereCondition, Pos('LIKE', UpperCase(LWhereCondition)) + 5, Length(LWhereCondition)));
              LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);
              LValue := UpperCase(LValue);
              if R.Fields.TryGetValue(LField, LTryVariant) then
              begin
                LVariant := LTryVariant;
                if LValue.StartsWith('%') and LValue.EndsWith('%') then
                  LMatch := LMatch and (Pos(UpperCase(LValue.Trim(['%'])), UpperCase(VarToStr(LVariant))) > 0)
                else if LValue.EndsWith('%') then
                  LMatch := LMatch and UpperCase(LVariant).StartsWith(UpperCase(LValue.Trim(['%'])))
                else
                  LMatch := LMatch and (UpperCase(LVariant) = UpperCase(LValue));
                _SetMonitorLog(Format('WHERE LIKE: %s LIKE %s, Match=%s',
                  [LField, LValue, BoolToStr(LMatch, True)]), '', nil);
              end
              else
              begin
                LMatch := False;
                _SetMonitorLog(Format('WHERE LIKE: %s not found', [LField]), '', nil);
              end;
            end
            else
            begin
              LOperator := IfThen(Pos('=', LWhereCondition) > 0, '=', IfThen(Pos('>', LWhereCondition) > 0, '>', '<'));
              LField := Trim(Copy(LWhereCondition, 1, Pos(LOperator, LWhereCondition) - 1));
              LValue := Trim(Copy(LWhereCondition, Pos(LOperator, LWhereCondition) + 1, Length(LWhereCondition)));
              LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);
              LValue := StringReplace(LValue, '.', ',', [rfReplaceAll]);
              LValue := UpperCase(LValue);
              if R.Fields.TryGetValue(LField, LTryVariant) then
              begin
                LVariant := StringReplace(LTryVariant, '.', ',', [rfReplaceAll]);
                if LOperator = '>' then
                  LMatch := LMatch and (StrToFloatDef(LVariant, 0) > StrToFloatDef(LValue, 0))
                else if LOperator = '=' then
                  LMatch := LMatch and (LVariant = LValue);
                _SetMonitorLog(Format('WHERE %s: %s %s %s, Match=%s',
                  [LField, VarToStr(LVariant), LOperator, LValue, BoolToStr(LMatch, True)]), '', nil);
              end
              else
              begin
                LMatch := False;
                _SetMonitorLog(Format('WHERE %s: %s not found', [LField]), '', nil);
              end;
            end;
          end;
          Result := LMatch;
        end).ToArray
      );
    _SetMonitorLog(Format('WHERE result count: %d', [LResult.Count]), '', nil);
  finally
    Result := LResult;
  end;
end;

{ TSqlParser }

constructor TSqlParser.Create(const AMonitorCallback: TMonitorProc);
begin
  FMonitorCallback := AMonitorCallback;
end;

procedure TSqlParser._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FCommandMonitor) then
    FCommandMonitor.Command('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams);
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

function TSqlParser.ParseSelect(const ASQL: string): TJoins;
begin
  _SetMonitorLog(Format('Parsing SQL: %s', [ASQL]), '', nil);
  Result.TableName := Trim(Copy(ASQL, Pos('FROM', UpperCase(ASQL)) + 5, Pos(' ', ASQL + ' ', Pos('FROM', UpperCase(ASQL)) + 5) - Pos('FROM', UpperCase(ASQL)) - 5));
  Result.Where := IfThen(Pos('WHERE', UpperCase(ASQL)) > 0, Trim(Copy(ASQL, Pos('WHERE', UpperCase(ASQL)) + 6, Length(ASQL))), '');
  Result.Join := IfThen(Pos('INNER JOIN', UpperCase(ASQL)) > 0, Trim(Copy(ASQL, Pos('INNER JOIN', UpperCase(ASQL)) + 10, Pos(' ON ', UpperCase(ASQL)) - Pos('INNER JOIN', UpperCase(ASQL)) - 10)), '');
  Result.JoinCondition := IfThen(Result.Join <> '', Trim(Copy(ASQL, Pos(' ON ', UpperCase(ASQL)) + 4, Pos(' WHERE ', ASQL + ' ') - Pos(' ON ', UpperCase(ASQL)) - 4)), '');
  _SetMonitorLog(Format('Parsed: Table=%s, Join=%s, Condition=%s, Where=%s',
    [Result.TableName, Result.Join, Result.JoinCondition, Result.Where]), '', nil);
end;

{ TQueryExecutor }

constructor TQueryExecutor.Create(const AMonitorCallback: TMonitorProc);
begin
  inherited Create;
  FMonitorCallback := AMonitorCallback;
  FJoinConditionParser := TJoinConditionParser.Create(AMonitorCallback);
  FJoinExecutor := TJoinExecutor.Create(AMonitorCallback);
  FWhereFilter := TWhereFilter.Create(AMonitorCallback);
end;

destructor TQueryExecutor.Destroy;
begin
  FJoinConditionParser.Free;
  FJoinExecutor.Free;
  FWhereFilter.Free;
  inherited;
end;

function TQueryExecutor.ExecuteSelect(const ATable: IEntityCollection<TMemoryRecord>;
  const AJoinTable: IEntityCollection<TMemoryRecord>;
  const ATableName, AJoinTableName, AJoinCondition, AWhere: string): TFluentList<TMemoryRecord>;
var
  LResult: TFluentList<TMemoryRecord>;
  LJoinFields: TJoinFields;
  LTempList: TFluentList<TMemoryRecord>;
  LRecord: TMemoryRecord;
  LIndex: NativeInt;
begin
  try
    if (AJoinTable <> nil) and (AJoinCondition <> '') then
    begin
      LJoinFields := FJoinConditionParser.Parse(AJoinCondition);
      LTempList := FJoinExecutor.ExecuteJoin(ATable, AJoinTable, ATableName, AJoinTableName, LJoinFields);
      try
        LResult := FWhereFilter.ApplyWhere(LTempList, AWhere);
      finally
        for LIndex := LTempList.Count - 1 downto 0 do
        begin
          if LResult.IndexOf(LTempList[LIndex]) = -1 then
          begin
            LTempList[LIndex].Free;
            LTempList.Delete(LIndex);
          end;
        end;
        LTempList.Free;
      end;
    end
    else
    begin
      LResult := TFluentList<TMemoryRecord>.Create;
      if ATable <> nil then
      begin
        for LRecord in ATable.AsEnumerable do
        begin
          if LRecord <> nil then
          begin
            LResult.Add(TMemoryRecord.Create);
            for var LPair in LRecord.Fields do
              LResult[LResult.Count - 1].Fields.Add(LPair.Key, LPair.Value);
          end;
        end;
      end;
      LTempList := FWhereFilter.ApplyWhere(LResult, AWhere);
      try
        for LIndex := LResult.Count - 1 downto 0 do
        begin
          if LTempList.IndexOf(LResult[LIndex]) = -1 then
          begin
            LResult[LIndex].Free;
            LResult.Delete(LIndex);
          end;
        end;
      finally
        LTempList.Free;
      end;
    end;
    _SetMonitorLog(Format('Select result count: %d', [LResult.Count]), '', nil);
  finally
    Result := LResult;
  end;
end;

procedure TQueryExecutor._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FCommandMonitor) then
    FCommandMonitor.Command('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams);
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

{ TMemoryRecord }

constructor TMemoryRecord.Create;
begin
  FFields := TFluentDictionary<string, Variant>.Create;
end;

destructor TMemoryRecord.Destroy;
begin
  FFields.Clear;
  FFields.Free;
  inherited;
end;

{ TMemoryField }

constructor TMemoryField.Create(AOwner: TComponent; ARecord: TMemoryRecord; AFieldName: string);
begin
  inherited Create(AOwner);
  FRecord := ARecord;
  FFieldName := AFieldName;
  FieldKind := fkData;
  Name := 'MemoryField_' + StringReplace(AFieldName, '.', '_', [rfReplaceAll]);
end;

function TMemoryField.GetAsString: string;
begin
  Result := VarToStr(GetAsVariant);
end;

function TMemoryField.GetAsFloat: Double;
begin
  Result := VarAsType(GetAsVariant, varDouble);
end;

function TMemoryField.GetAsInteger: Longint;
begin
  Result := VarAsType(GetAsVariant, varInteger);
end;

function TMemoryField.GetAsBoolean: Boolean;
begin
  Result := VarAsType(GetAsVariant, varBoolean);
end;

function TMemoryField.GetAsVariant: Variant;
begin
  if Assigned(FRecord) and FRecord.Fields.TryGetValue(FFieldName, Result) then
  begin
    Result := StringReplace(VarToStr(Result), '.', ',', [rfReplaceAll]);
    Exit;
  end;
  Result := Null;
end;

procedure TMemoryField.SetAsVariant(const Value: Variant);
begin
  if Assigned(FRecord) then
    FRecord.Fields[FFieldName] := Value
  else
    raise EDatabaseError.Create('Cannot set value: No active record');
end;

function TMemoryField.GetIsNull: Boolean;
begin
  Result := (not Assigned(FRecord)) or (not FRecord.Fields.ContainsKey(FFieldName)) or (VarIsNull(FRecord.Fields[FFieldName]));
end;

{ TMemoryDriver }

procedure TMemoryDriver._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

constructor TMemoryDriver.Create(const AConnection: TComponent;
  const ADriverTransaction: TDriverTransaction; const ADriver: TDBEDriver;
  const AMonitorCallback: TMonitorProc);
begin
  inherited Create(AConnection, ADriverTransaction, ADriver, AMonitorCallback);
  FConnection := AConnection;
  FTables := TFluentDictionary<string, TFluentList<TMemoryRecord>>.Create([doOwnsValues]);
  FSQLScripts := TStringList.Create;
  FConnected := False;
  FRowsAffected := 0;
  FSqlParser := TSqlParser.Create(AMonitorCallback);
  FQueryExecutor := TQueryExecutor.Create(AMonitorCallback);
end;

destructor TMemoryDriver.Destroy;
begin
  _ClearTables;
  FConnection := nil;
  FDriverTransaction := nil;
  FSQLScripts.Free;
  FTables.Free;
  inherited;
end;

procedure TMemoryDriver.Connect;
begin
  FConnected := True;
  _SetMonitorLog('Connected to Memory DB', '', nil);
end;

procedure TMemoryDriver.Disconnect;
begin
  FConnected := False;
  _SetMonitorLog('Disconnected from Memory DB', '', nil);
end;

procedure TMemoryDriver.ExecuteDirect(const ASQL: String);
begin
  ExecuteDirect(ASQL, nil);
end;

procedure TMemoryDriver.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LSQL: string;
  LFor: Integer;
begin
  if not FConnected then
    Connect;
  if not FDriverTransaction.InTransaction then
    FDriverTransaction.StartTransaction;
  try
    LSQL := ASQL;
    if Assigned(AParams) then
    begin
      for LFor := 0 to AParams.Count - 1 do
      begin
        if AParams.Items[LFor].DataType in [ftString, ftMemo, ftWideString] then
          LSQL := StringReplace(LSQL, ':' + AParams.Items[LFor].Name, QuotedStr(VarToStr(AParams.Items[LFor].Value)), [rfReplaceAll])
        else
          LSQL := StringReplace(LSQL, ':' + AParams.Items[LFor].Name, VarToStr(AParams.Items[LFor].Value), [rfReplaceAll]);
      end;
    end;
    _SetMonitorLog(Format('Executing SQL: %s', [LSQL]), '', nil);
    _ParseAndExecuteSQL(LSQL, AParams);
    _SetMonitorLog(LSQL, 'MemoryTransaction', AParams);
    FDriverTransaction.Commit;
  except
    FDriverTransaction.Rollback;
    raise;
  end;
end;

procedure TMemoryDriver.ExecuteScript(const AScript: String);
var
  LScript: TStringList;
  LCommand: string;
  LCurrent: string;
  LFor: Integer;
  LInQuote: Boolean;
  LChar: Char;
begin
  LScript := TStringList.Create;
  try
    LCurrent := '';
    LInQuote := False;
    for LFor := 1 to Length(AScript) do
    begin
      LChar := AScript[LFor];
      if LChar = '''' then
        LInQuote := not LInQuote;
      if (LChar = ';') and not LInQuote then
      begin
        if Trim(LCurrent) <> '' then
          LScript.Add(Trim(LCurrent));
        LCurrent := '';
      end
      else
        LCurrent := LCurrent + LChar;
    end;
    if Trim(LCurrent) <> '' then
      LScript.Add(Trim(LCurrent));

    for LFor := 0 to LScript.Count - 1 do
    begin
      LCommand := Trim(LScript[LFor]);
      if LCommand <> '' then
      begin
        _SetMonitorLog(Format('Executing script command: %s', [LCommand]), '', nil);
        ExecuteDirect(LCommand);
      end;
    end;
  finally
    LScript.Free;
  end;
end;

procedure TMemoryDriver.AddScript(const AScript: String);
begin
  FSQLScripts.Add(AScript);
end;

procedure TMemoryDriver.ExecuteScripts;
var
  LFor: Integer;
begin
  for LFor := 0 to FSQLScripts.Count - 1 do
    ExecuteDirect(FSQLScripts[LFor]);
  FSQLScripts.Clear;
end;

procedure TMemoryDriver.ApplyUpdates(const ADataSets: array of IDBDataSet);
begin
  // Simulação: nada a fazer em memória
end;

function TMemoryDriver.IsConnected: Boolean;
begin
  Result := FConnected;
end;

function TMemoryDriver.CreateQuery: IDBQuery;
begin
  Result := TMemoryQuery.Create(Self,
                                FDriverTransaction,
                                FMonitorCallback);
end;

function TMemoryDriver.CreateDataSet(const ASQL: String): IDBDataSet;
begin
  Result := _ExecuteSelect(ASQL, nil);
end;

function TMemoryDriver.GetSQLScripts: String;
begin
  Result := FSQLScripts.Text;
end;

procedure TMemoryDriver._ParseAndExecuteSQL(const ASQL: string; const AParams: TParams);
var
  LSQL: string;
begin
  LSQL := UpperCase(Trim(ASQL));

  if LSQL.StartsWith('SELECT') then
    _ExecuteSelect(LSQL, AParams)
  else if LSQL.StartsWith('INSERT INTO') then
    _ExecuteInsert(LSQL, AParams)
  else if LSQL.StartsWith('UPDATE') then
    _ExecuteUpdate(LSQL, AParams)
  else if LSQL.StartsWith('DELETE') then
    _ExecuteDelete(LSQL, AParams);
end;

procedure TMemoryDriver._ExecuteInsert(const ASQL: string; const AParams: TParams);
var
  LTableName: string;
  LFields: TArray<string>;
  LValues: TArray<string>;
  LRecord: TMemoryRecord;
  LFor: Integer;
  LField: string;
  LValue: string;
  LIntValue: Integer;
  LTable: TFluentList<TMemoryRecord>;
begin
  LTableName := Trim(Copy(ASQL, Pos('INTO', UpperCase(ASQL)) + 5, Pos('(', ASQL) - Pos('INTO', UpperCase(ASQL)) - 5));
  if not FTables.TryGetValue(LTableName, LTable) then
  begin
    LTable := TFluentList<TMemoryRecord>.Create;
    FTables.Add(LTableName, LTable);
  end;

  LRecord := TMemoryRecord.Create;
  try
    LFields := Copy(ASQL, Pos('(', ASQL) + 1, Pos(')', ASQL) - Pos('(', ASQL) - 1).Split([',']);
    LValues := Copy(ASQL, Pos('VALUES', UpperCase(ASQL)) + 7, Pos(')', ASQL, Pos('VALUES', UpperCase(ASQL))) - Pos('VALUES', UpperCase(ASQL)) - 7).Split([',']);

    for LFor := 0 to Min(Length(LFields), Length(LValues)) - 1 do
    begin
      LField := Trim(LFields[LFor]);
      LValue := Trim(LValues[LFor]);
      LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);
      LValue := StringReplace(LValue, '(', '', [rfReplaceAll]);
      LValue := StringReplace(LValue, ')', '', [rfReplaceAll]);
      if UpperCase(LField) = 'CLIENT_ID' then
      begin
        LIntValue := StrToIntDef(LValue, 0);
        LRecord.Fields.Add(LField, LIntValue);
        _SetMonitorLog(Format('Insert %s: %s -> %d', [LField, LValue, LIntValue]), '', nil);
      end
      else
      begin
        LRecord.Fields.Add(LField, LValue);
        _SetMonitorLog(Format('Insert %s: %s', [LField, LValue]), '', nil);
      end;
    end;
    LTable.Add(LRecord);
    FRowsAffected := 1;
    _SetMonitorLog(Format('Inserted record in %s, count = %d', [LTableName, LTable.Count]), '', nil);
  except
    LRecord.Free;
    raise;
  end;
end;

procedure TMemoryDriver._ExecuteUpdate(const ASQL: string; const AParams: TParams);
var
  LTableName: string;
  LSetClause: string;
  LWhere: string;
  LTable: TFluentList<TMemoryRecord>;
  LSetPairs: TArray<string>;
  LField: string;
  LValue: string;
  LRecord: TMemoryRecord;
  LFor: Integer;
  LIndex: Integer;
  LV: Variant;
  LUpdated: Boolean;
begin
  LTableName := Trim(Copy(ASQL, 7, Pos('SET', ASQL) - 7));
  LSetClause := Trim(Copy(ASQL, Pos('SET', ASQL) + 4, Pos('WHERE', ASQL + ' ') - Pos('SET', ASQL) - 4));
  LWhere := Trim(Copy(ASQL, Pos('WHERE', ASQL) + 6, Length(ASQL)));

  _SetMonitorLog(Format('Update SQL: %s', [ASQL]), '', nil);

  if FTables.TryGetValue(LTableName, LTable) then
  begin
    LSetPairs := LSetClause.Split([',']);
    FRowsAffected := 0;
    if LWhere <> '' then
    begin
      LField := Trim(Copy(LWhere, 1, Pos('=', LWhere) - 1));
      LValue := Trim(Copy(LWhere, Pos('=', LWhere) + 1, Length(LWhere)));
      LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);

      _SetMonitorLog(Format('Where: %s = %s', [LField, LValue]), '', nil);

      for LIndex := 0 to LTable.Count - 1 do
      begin
        LRecord := LTable[LIndex];
        LUpdated := False;
        if LRecord.Fields.TryGetValue(LField, LV) then
        begin
          _SetMonitorLog(Format('Record %d: %s = %s', [LIndex, LField, VarToStr(LV)]), '', nil);

          if UpperCase(LField) = 'CLIENT_ID' then
          begin
            if (VarType(LV) in [varInteger, varSmallInt, varInt64]) and (IntToStr(LV) = LValue) then
            begin
              for LFor := 0 to Length(LSetPairs) - 1 do
              begin
                LField := Trim(Copy(LSetPairs[LFor], 1, Pos('=', LSetPairs[LFor]) - 1));
                LValue := Trim(Copy(LSetPairs[LFor], Pos('=', LSetPairs[LFor]) + 1, Length(LSetPairs[LFor])));
                LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);
                LRecord.Fields[LField] := LValue;
                _SetMonitorLog(Format('Updated: %s = %s', [LField, LValue]), '', nil);
              end;
              LUpdated := True;
            end;
          end
          else if VarToStr(LV) = LValue then
          begin
            for LFor := 0 to Length(LSetPairs) - 1 do
            begin
              LField := Trim(Copy(LSetPairs[LFor], 1, Pos('=', LSetPairs[LFor]) - 1));
              LValue := Trim(Copy(LSetPairs[LFor], Pos('=', LSetPairs[LFor]) + 1, Length(LSetPairs[LFor])));
              LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);
              LRecord.Fields[LField] := LValue;
              _SetMonitorLog(Format('Updated: %s = %s', [LField, LValue]), '', nil);
            end;
            LUpdated := True;
          end;
        end;
        if LUpdated then
        begin
          Inc(FRowsAffected);
          Break;
        end;
      end;
    end;
    _SetMonitorLog(Format('Rows affected: %d', [FRowsAffected]), '', nil);
  end;
end;

procedure TMemoryDriver._ExecuteDelete(const ASQL: string; const AParams: TParams);
var
  LTableName: string;
  LWhere: string;
  LTable: TFluentList<TMemoryRecord>;
  LRecords: IFluentEnumerable<TMemoryRecord>;
  LField: string;
  LValue: string;
  LRecord: TMemoryRecord;
begin
  LTableName := Trim(Copy(ASQL, 7, Pos('WHERE', ASQL + ' ') - 7));
  LWhere := Trim(Copy(ASQL, Pos('WHERE', ASQL) + 6, Length(ASQL)));

  if FTables.TryGetValue(LTableName, LTable) then
  begin
    if LWhere <> '' then
    begin
      LField := Trim(Copy(LWhere, 1, Pos('=', LWhere) - 1));
      LValue := Trim(Copy(LWhere, Pos('=', LWhere) + 1, Length(LWhere)));
      LValue := StringReplace(LValue, '''', '', [rfReplaceAll]);
      LRecords := LTable.AsEnumerable.Where(
        function(R: TMemoryRecord): Boolean
        var
          LV: Variant;
        begin
          Result := R.Fields.TryGetValue(LField, LV) and (VarToStr(LV) = LValue);
        end);
      for LRecord in LRecords do
      begin
        LTable.Remove(LRecord);
        Inc(FRowsAffected);
      end;
    end;
  end;
end;

function TMemoryDriver._ExecuteSelect(const ASQL: string; const AParams: TParams): IDBDataSet;
var
  LParseResult: TJoins;
  LTable: TFluentList<TMemoryRecord>;
  LJoinTable: TFluentList<TMemoryRecord>;
  LTableAdapter: IEntityCollection<TMemoryRecord>;
  LJoinTableAdapter: IEntityCollection<TMemoryRecord>;
  LResultList: TFluentList<TMemoryRecord>;
begin
  LParseResult := FSqlParser.ParseSelect(ASQL);
  LTable := nil;
  LJoinTable := nil;

  if FTables.TryGetValue(LParseResult.TableName, LTable) then
  begin
    LTableAdapter := TEntityCollectionAdapter<TMemoryRecord>.Create(LTable);
    try
      if LParseResult.Join <> '' then
      begin
        if FTables.TryGetValue(LParseResult.Join, LJoinTable) then
          LJoinTableAdapter := TEntityCollectionAdapter<TMemoryRecord>.Create(LJoinTable)
        else
          LJoinTableAdapter := TEntityCollectionAdapter<TMemoryRecord>.Create(nil);
      end
      else
        LJoinTableAdapter := TEntityCollectionAdapter<TMemoryRecord>.Create(nil);

      try
        LResultList := FQueryExecutor.ExecuteSelect(
          LTableAdapter,
          LJoinTableAdapter,
          LParseResult.TableName,
          LParseResult.Join,
          LParseResult.JoinCondition,
          LParseResult.Where
        );
        Result := TMemoryDataSet.Create(LResultList,
                                        ASQL,
                                        FMonitorCallback);
      finally
        LJoinTableAdapter := nil;
      end;
    finally
      LTableAdapter := nil;
    end;
  end
  else
  begin
    LResultList := TFluentList<TMemoryRecord>.Create;
    Result := TMemoryDataSet.Create(LResultList,
                                    ASQL,
                                    FMonitorCallback);
  end;
end;

procedure TMemoryDriver._ClearTables;
var
  LTable: TFluentList<TMemoryRecord>;
  LRecord: TMemoryRecord;
begin
  for LTable in FTables.Values do
  begin
    for LRecord in LTable do
      LRecord.Free;
    LTable.Clear;
  end;
end;

{ TMemoryQuery }

constructor TMemoryQuery.Create(const ADriver: TMemoryDriver;
  const ADriverTransaction: TDriverTransaction;
  const AMonitorCallback: TMonitorProc);
begin
  inherited Create;
  FDriver := ADriver;
  FDriverTransaction := ADriverTransaction;
  FMonitorCallback := AMonitorCallback;
  FParams := TParams.Create;
end;

destructor TMemoryQuery.Destroy;
begin
  FDriver := nil;
  FParams.Free;
  inherited;
end;

procedure TMemoryQuery.ExecuteDirect;
begin
  if not FDriverTransaction.InTransaction then
    FDriverTransaction.StartTransaction;
  try
    FDriver.ExecuteDirect(FSQL, FParams);
    FRowsAffected := FDriver.RowsAffected;
    FDriverTransaction.Commit;
  except
    FDriverTransaction.Rollback;
    raise;
  end;
end;

function TMemoryQuery.ExecuteQuery: IDBDataSet;
begin
  if not FDriverTransaction.InTransaction then
    FDriverTransaction.StartTransaction;
  try
    Result := FDriver._ExecuteSelect(FSQL, FParams);
    FDriverTransaction.Commit;
  except
    FDriverTransaction.Rollback;
    raise;
  end;
end;

function TMemoryQuery.RowsAffected: UInt32;
begin
  Result := FRowsAffected;
end;

procedure TMemoryQuery._SetCommandText(const ACommandText: String);
begin
  FSQL := ACommandText;
end;

function TMemoryQuery._GetCommandText: String;
begin
  Result := FSQL;
end;

{ TMemoryDataSet }

procedure TMemoryDataSet._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

constructor TMemoryDataSet.Create(const ARecords: TFluentList<TMemoryRecord>;
  const ASQL: string; const AMonitorCallback: TMonitorProc);
begin
  inherited Create;
  FRecords := ARecords;
  FSQL := ASQL;
  FCurrentIndex := -1;
  FActive := False;
  FMonitorCallback := AMonitorCallback;
  FFields := TList<TMemoryField>.Create;
  FState := dsInactive;
  FModified := False;
  FBookmarks := TList<Integer>.Create;
  UpdateFields;
end;

function TMemoryDataSet.Designer: TDataSetDesigner;
begin

end;

destructor TMemoryDataSet.Destroy;
var
  LField: TMemoryField;
  LRecord: TMemoryRecord;
begin
  for LField in FFields do
    LField.Free;
  FFields.Free;
  if Assigned(FRecords) then
  begin
    _SetMonitorLog(Format('Destroying TMemoryDataSet, RecordCount=%d', [FRecords.Count]), '', nil);
    for LRecord in FRecords do
    begin
      if Assigned(LRecord) then
      begin
        _SetMonitorLog(Format('Freeing TMemoryRecord with %d fields', [LRecord.Fields.Count]), '', nil);
        LRecord.Free;
      end;
    end;
    FRecords.Clear;
    FRecords.Free;
  end;
  FBookmarks.Free;
  inherited;
end;

procedure TMemoryDataSet.UpdateFields;
var
  LField: TMemoryField;
  LKey: string;
begin
  for LField in FFields do
    LField.Free;
  FFields.Clear;
  if (FRecords.Count > 0) and Assigned(FRecords[0]) then
  begin
    for LKey in FRecords[0].Fields.Keys do
    begin
      LField := TMemoryField.Create(nil, nil, LKey);
      LField.FieldName := LKey;
      FFields.Add(LField);
    end;
  end;
end;

function TMemoryDataSet.ObjectView: Boolean;
begin

end;

procedure TMemoryDataSet.Open;
begin
  FActive := True;
  FState := dsBrowse;
  FCurrentIndex := -1;
  if FRecords.Count > 0 then
  begin
    First;
    _SetMonitorLog(Format('DataSet opened, moved to first record, Index=%d', [FCurrentIndex]), '', nil);
  end;
end;

procedure TMemoryDataSet.Close;
begin
  FActive := False;
  FCurrentIndex := -1;
  FState := dsInactive;
  _SetMonitorLog('DataSet closed', '', nil);
end;

procedure TMemoryDataSet.Refresh;
begin
  if FActive then
  begin
    Close;
    Open;
  end;
end;

function TMemoryDataSet.DefaultFields: Boolean;
begin

end;

procedure TMemoryDataSet.Delete;
begin
  if FActive and (FCurrentIndex >= 0) and (FCurrentIndex < FRecords.Count) then
  begin
    FRecords.Delete(FCurrentIndex);
    if FCurrentIndex >= FRecords.Count then
      FCurrentIndex := FRecords.Count - 1;
    FState := dsBrowse;
    UpdateFields;
    _SetMonitorLog('Record deleted', '', nil);
  end;
end;

procedure TMemoryDataSet.Cancel;
begin
  if FState in [dsInsert, dsEdit] then
  begin
    FState := dsBrowse;
    FModified := False;
    _SetMonitorLog('Changes canceled', '', nil);
  end;
end;

procedure TMemoryDataSet.Clear;
begin
  if FActive then
  begin
    FRecords.Clear;
    FCurrentIndex := -1;
    FState := dsBrowse;
    UpdateFields;
    _SetMonitorLog('DataSet cleared', '', nil);
  end;
end;

procedure TMemoryDataSet.DisableControls;
begin
  // Não aplicável em memória
end;

procedure TMemoryDataSet.EnableControls;
begin
  // Não aplicável em memória
end;

function TMemoryDataSet.Eof: Boolean;
begin
  Result := not FActive or (FCurrentIndex >= FRecords.Count);
  _SetMonitorLog(Format('Eof checked: Active=%s, Index=%d, Count=%d, Result=%s',
    [BoolToStr(FActive, True), FCurrentIndex, FRecords.Count, BoolToStr(Result, True)]), '', nil);
end;

procedure TMemoryDataSet.Next;
begin
  if FActive and (FCurrentIndex <= FRecords.Count - 1) then
  begin
    Inc(FCurrentIndex);
    _SetMonitorLog(Format('Moved to next record, Index=%d', [FCurrentIndex]), '', nil);
  end;
end;

procedure TMemoryDataSet.Prior;
begin
  if FActive and (FCurrentIndex > 0) then
  begin
    Dec(FCurrentIndex);
    _SetMonitorLog(Format('Moved to prior record, Index=%d', [FCurrentIndex]), '', nil);
  end;
end;

procedure TMemoryDataSet.First;
begin
  if FActive and (FRecords.Count > 0) then
  begin
    FCurrentIndex := 0;
    _SetMonitorLog('Moved to first record', '', nil);
  end;
end;

function TMemoryDataSet.Found: Boolean;
begin

end;

procedure TMemoryDataSet.Last;
begin
  if FActive and (FRecords.Count > 0) then
  begin
    FCurrentIndex := FRecords.Count - 1;
    _SetMonitorLog('Moved to last record', '', nil);
  end;
end;

procedure TMemoryDataSet.MoveBy(Distance: Integer);
begin
  if FActive then
  begin
    FCurrentIndex := EnsureRange(FCurrentIndex + Distance, 0, FRecords.Count - 1);
    _SetMonitorLog(Format('Moved by %d, Index=%d', [Distance, FCurrentIndex]), '', nil);
  end;
end;

procedure TMemoryDataSet.CheckRequiredFields;
begin
  // Não aplicável em memória
end;

procedure TMemoryDataSet.Append;
begin
  if FActive then
  begin
    FRecords.Add(TMemoryRecord.Create);
    FCurrentIndex := FRecords.Count - 1;
    FState := dsInsert;
    FModified := True;
    UpdateFields;
    _SetMonitorLog('New record appended', '', nil);
  end;
end;

procedure TMemoryDataSet.Insert;
begin
  if FActive then
  begin
    FRecords.Insert(FCurrentIndex, TMemoryRecord.Create);
    FState := dsInsert;
    FModified := True;
    UpdateFields;
    _SetMonitorLog('New record inserted', '', nil);
  end;
end;

procedure TMemoryDataSet.Edit;
begin
  if FActive and (FCurrentIndex >= 0) and (FCurrentIndex < FRecords.Count) then
  begin
    FState := dsEdit;
    FModified := True;
    _SetMonitorLog('Editing record', '', nil);
  end;
end;

procedure TMemoryDataSet.Post;
begin
  if FState in [dsInsert, dsEdit] then
  begin
    FState := dsBrowse;
    FModified := False;
    UpdateFields;
    _SetMonitorLog('Changes posted', '', nil);
  end;
end;

procedure TMemoryDataSet.FreeBookmark(Bookmark: TBookmark);
begin
  _SetMonitorLog('Bookmark freed', '', nil);
end;

procedure TMemoryDataSet.ClearFields;
begin
  if FActive and (FCurrentIndex >= 0) and (FCurrentIndex < FRecords.Count) then
  begin
    FRecords[FCurrentIndex].Fields.Clear;
    UpdateFields;
    _SetMonitorLog('Fields cleared', '', nil);
  end;
end;

procedure TMemoryDataSet.ApplyUpdates;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ApplyUpdates', Self.ClassName]);
end;

procedure TMemoryDataSet.CancelUpdates;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CancelUpdates', Self.ClassName]);
end;

function TMemoryDataSet.Locate(const KeyFields: String; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
var
  LField: string;
  LValue: Variant;
  LVariant: Variant;
  LFor: Integer;
begin
  Result := False;
  if FActive and (FRecords.Count > 0) then
  begin
    LField := UpperCase(KeyFields);
    if VarIsArray(KeyValues) then
      LValue := KeyValues[0]
    else
      LValue := KeyValues;
    for LFor := 0 to FRecords.Count - 1 do
    begin
      if FRecords[LFor].Fields.TryGetValue(LField, LVariant) and (VarToStr(LVariant) = VarToStr(LValue)) then
      begin
        FCurrentIndex := LFor;
        Result := True;
        _SetMonitorLog(Format('Located record: %s=%s', [LField, VarToStr(LValue)]), '', nil);
        Break;
      end;
    end;
  end;
end;

function TMemoryDataSet.Lookup(const KeyFields: String; const KeyValues: Variant;
  const ResultFields: String): Variant;
var
  LField: string;
  LValue: Variant;
  LVariant: Variant;
  LFor: Integer;
begin
  Result := Null;
  if FActive and (FRecords.Count > 0) then
  begin
    LField := UpperCase(KeyFields);
    if VarIsArray(KeyValues) then
      LValue := KeyValues[0]
    else
      LValue := KeyValues;
    for LFor := 0 to FRecords.Count - 1 do
    begin
      if FRecords[LFor].Fields.TryGetValue(LField, LVariant) and (VarToStr(LVariant) = VarToStr(LValue)) then
      begin
        if FRecords[LFor].Fields.TryGetValue(UpperCase(ResultFields), Result) then
        begin
          _SetMonitorLog(Format('Lookup: %s=%s, Result=%s', [LField, VarToStr(LValue), VarToStr(Result)]), '', nil);
          Break;
        end;
      end;
    end;
  end;
end;

function TMemoryDataSet._GetBookmark: TBookmark;
var
  LIndexBytes: TBytes;
begin
  if FActive and (FCurrentIndex >= 0) and (FCurrentIndex < FRecords.Count) then
  begin
    SetLength(LIndexBytes, SizeOf(Integer));
    Move(FCurrentIndex, LIndexBytes[0], SizeOf(Integer));
    Result := LIndexBytes;
    FBookmarks.Add(FCurrentIndex);
    _SetMonitorLog(Format('Bookmark created: %d', [FCurrentIndex]), '', nil);
  end
  else
    Result := nil;
end;

function TMemoryDataSet.FieldCount: UInt16;
begin
  if FActive and (FCurrentIndex >= 0) and (FCurrentIndex < FRecords.Count) then
    Result := FRecords[FCurrentIndex].Fields.Count
  else
    Result := FFields.Count;
end;

function TMemoryDataSet.SparseArrays: Boolean;
begin

end;

function TMemoryDataSet.State: TDataSetState;
begin
  Result := FState;
end;

function TMemoryDataSet.Modified: Boolean;
begin
  Result := FModified;
end;

function TMemoryDataSet.FieldByName(const AFieldName: String): TField;
var
  LField: TMemoryField;
begin
  for LField in FFields do
  begin
    if SameText(LField.FieldName, AFieldName) then
    begin
      if FActive and (FCurrentIndex >= 0) and (FCurrentIndex < FRecords.Count) then
        LField.FRecord := FRecords[FCurrentIndex]
      else
        LField.FRecord := nil;
      Exit(LField);
    end;
  end;
  raise EDatabaseError.CreateFmt('Field %s not found', [AFieldName]);
end;

function TMemoryDataSet.RecNo: Integer;
begin
  Result := FCurrentIndex + 1;
end;

function TMemoryDataSet.RecordCount: UInt32;
begin
  Result := FRecords.Count;
end;

function TMemoryDataSet.FieldDefList: TFieldDefList;
begin

end;

function TMemoryDataSet.RecordSize: Word;
begin

end;

function TMemoryDataSet.FieldDefs: TFieldDefs;
begin
  Result := TFieldDefs.Create(nil);
  for var LField in FFields do
  begin
    var LDef := Result.AddFieldDef;
    LDef.Name := LField.FieldName;
    LDef.DataType := ftVariant;
  end;
end;

function TMemoryDataSet.FieldList: TFieldList;
begin

end;

function TMemoryDataSet.Fields: TFields;
begin

end;

function TMemoryDataSet.AggFields: TFields;
begin
  Result := TFields.Create(AsDataSet);
end;

function TMemoryDataSet.UpdateStatus: TUpdateStatus;
begin
  Result := usUnmodified;
end;

function TMemoryDataSet.CanModify: Boolean;
begin
  Result := True;
end;

function TMemoryDataSet.CanRefresh: Boolean;
begin

end;

function TMemoryDataSet.IsEmpty: Boolean;
begin
  Result := FRecords.Count = 0;
end;

function TMemoryDataSet.DataSetField: TDataSetField;
begin

end;

function TMemoryDataSet.DataSource: TDataSource;
begin
  Result := nil;
end;

function TMemoryDataSet.AsDataSet: TDataSet;
begin
  Result := nil;
end;

function TMemoryDataSet.Bof: Boolean;
begin
  Result := FActive and (FCurrentIndex <= 0);
end;

function TMemoryDataSet.IsUniDirectional: Boolean;
begin
  Result := False;
end;

function TMemoryDataSet.IsReadOnly: Boolean;
begin
  Result := False;
end;

function TMemoryDataSet.IsCachedUpdates: Boolean;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['IsCachedUpdates', Self.ClassName]);
end;

function TMemoryDataSet.RowsAffected: UInt32;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['RowsAffected', Self.ClassName]);
end;

function TMemoryDataSet.NormalizeFieldValue(const AFieldName: String; const AValue: Variant): Variant;
begin
  Result := AValue;
end;

function TMemoryDataSet._GetFilter: String;
begin
  Result := '';
end;

function TMemoryDataSet._GetFiltered: Boolean;
begin
  Result := False;
end;

function TMemoryDataSet._GetFilterOptions: TFilterOptions;
begin
  Result := [];
end;

function TMemoryDataSet._GetActive: Boolean;
begin
  Result := FActive;
end;

function TMemoryDataSet._GetCommandText: String;
begin
  Result := FSQL;
end;

function TMemoryDataSet._GetAfterCancel: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterClose: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterDelete: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterEdit: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterInsert: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterOpen: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterPost: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterRefresh: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAfterScroll: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetAutoCalcFields: Boolean;
begin
  Result := False;
end;

function TMemoryDataSet._GetBeforeCancel: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeClose: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeDelete: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeEdit: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeInsert: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeOpen: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforePost: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeRefresh: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetBeforeScroll: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetOnCalcFields: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetOnDeleteError: TDataSetErrorEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetOnEditError: TDataSetErrorEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetOnFilterRecord: TFilterRecordEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetOnNewRecord: TDataSetNotifyEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetOnPostError: TDataSetErrorEvent;
begin
  Result := nil;
end;

function TMemoryDataSet._GetSortFields: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_GetSortFields', Self.ClassName]);
end;

function TMemoryDataSet._GetFetchingAll: Boolean;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_GetFetchingAll', Self.ClassName]);
end;

procedure TMemoryDataSet._SetFilter(const Value: String);
begin
  _SetMonitorLog('Filter not supported in memory', '', nil);
end;

procedure TMemoryDataSet._SetFiltered(const Value: Boolean);
begin
  _SetMonitorLog('Filtered not supported in memory', '', nil);
end;

procedure TMemoryDataSet._SetFilterOptions(Value: TFilterOptions);
begin
  _SetMonitorLog('FilterOptions not supported in memory', '', nil);
end;

procedure TMemoryDataSet._SetActive(const Value: Boolean);
begin
  if Value then
    Open
  else
    Close;
end;

procedure TMemoryDataSet._SetCommandText(const ACommandText: String);
begin
  FSQL := ACommandText;
end;

procedure TMemoryDataSet._SetUniDirectional(const Value: Boolean);
begin
  _SetMonitorLog('UniDirectional not supported in memory', '', nil);
end;

procedure TMemoryDataSet._SetReadOnly(const Value: Boolean);
begin
  _SetMonitorLog('ReadOnly not supported in memory', '', nil);
end;

procedure TMemoryDataSet._SetCachedUpdates(const Value: Boolean);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetCachedUpdates', Self.ClassName]);
end;

procedure TMemoryDataSet._SetAfterCancel(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterOpen(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterClose(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterDelete(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterEdit(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterInsert(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterPost(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterRefresh(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAfterScroll(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetAutoCalcFields(const Value: Boolean);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeCancel(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeDelete(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeEdit(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeInsert(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeOpen(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeClose(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforePost(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeRefresh(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetBeforeScroll(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetOnFilterRecord(const Value: TFilterRecordEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetOnCalcFields(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetOnDeleteError(const Value: TDataSetErrorEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetOnEditError(const Value: TDataSetErrorEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetOnNewRecord(const Value: TDataSetNotifyEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetOnPostError(const Value: TDataSetErrorEvent);
begin
  // Não suportado
end;

procedure TMemoryDataSet._SetSortFields(const Value: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetSortFields', Self.ClassName]);
end;

procedure TMemoryDataSet._SetFetchingAll(const Value: Boolean);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetFetchingAll', Self.ClassName]);
end;

end.
