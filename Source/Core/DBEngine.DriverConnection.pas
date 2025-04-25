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

unit DBEngine.DriverConnection;

interface

uses
  DB,
  Math,
  Classes,
  SysUtils,
  Variants,
  SyncObjs,
  Generics.Collections,
  DBEngine.Consts,
  DBEngine.FactoryInterfaces;

type
  TDriverTransaction = class;

  TDriverConnection = class abstract
  protected
    FDriverTransaction: TDriverTransaction;
    FMonitorCallback: TMonitorProc;
    FDriver: TDBEngineDriver;
    FRowsAffected: UInt32;
    procedure _SetMonitorLog(const ASQL: String; const ATransactionName: String;
      const AParams: TParams);
  public
    constructor Create(const AConnection: TComponent; const ADriverTransaction: TDriverTransaction;
      const ADriverName: TDBEngineDriver; const AMonitorCallback: TMonitorProc); virtual;
    procedure Connect; virtual;
    procedure Disconnect; virtual;
    procedure ExecuteDirect(const ASQL: String); overload; virtual;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); overload; virtual;
    procedure ExecuteScript(const AScript: String); virtual;
    procedure AddScript(const AScript: String); virtual;
    procedure ExecuteScripts; virtual;
    procedure ApplyUpdates(const ADataSets: array of IDBDataSet); virtual;
    function IsConnected: Boolean; virtual;
    function CreateQuery: IDBQuery; virtual;
    function CreateDataSet(const ASQL: String): IDBDataSet; virtual;
    function GetSQLScripts: String; virtual;
    function RowsAffected: UInt32; virtual;
    function GetDriver: TDBEngineDriver; virtual;
    function MonitorCallback: TMonitorProc; virtual;
    function Options: IOptions; virtual; abstract;
  end;

  TDriverTransaction = class abstract(TInterfacedObject, IDBTransaction)
  protected
    FTransactionList: TDictionary<String, TComponent>;
    FTransactionActive: TComponent;
    FLock: TCriticalSection;
    function _GetTransaction(const AKey: String): TComponent; virtual;
  public
    constructor Create(const AConnection: TComponent); virtual;
    destructor Destroy; override;
    procedure StartTransaction; virtual;
    procedure Commit; virtual;
    procedure Rollback; virtual;
    procedure AddTransaction(const AKey: String; const ATransaction: TComponent); virtual;
    procedure UseTransaction(const AKey: String); virtual;
    function TransactionActive: TComponent; virtual;
    function InTransaction: Boolean; virtual;
  end;

  TOptions = class(TInterfacedObject, IOptions)
  strict private
    FStoreGUIDAsOctet: Boolean;
  public
    constructor Create;
    function StoreGUIDAsOctet(const AValue: Boolean): IOptions; overload;
    function StoreGUIDAsOctet: Boolean; overload;
  end;

  TDriverQuery = class(TInterfacedObject, IDBQuery)
  protected
    FDriverTransaction: TDriverTransaction;
    FMonitorCallback: TMonitorProc;
    FRowsAffected: UInt32;
    procedure _SetMonitorLog(const ASQL: String; const ATransactionName: String;
      const AParams: TParams);
    procedure _SetCommandText(const ACommandText: String); virtual;
    function _GetCommandText: String; virtual;
  public
    procedure ExecuteDirect; virtual;
    function ExecuteQuery: IDBDataSet; virtual;
    function RowsAffected: UInt32; virtual;
  end;

  TDriverDataSetBase = class abstract(TInterfacedObject, IDBDataSet)
  protected
    FRecordCount: UInt32;
    FMonitorCallback: TMonitorProc;
    function _GetFilter: String; virtual; abstract;
    function _GetFiltered: Boolean; virtual; abstract;
    function _GetFilterOptions: TFilterOptions; virtual; abstract;
    function _GetActive: Boolean; virtual; abstract;
    function _GetCommandText: String; virtual; abstract;
    function _GetAfterCancel: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterClose: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterDelete: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterEdit: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterInsert: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterOpen: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterPost: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterRefresh: TDataSetNotifyEvent; virtual; abstract;
    function _GetAfterScroll: TDataSetNotifyEvent; virtual; abstract;
    function _GetAutoCalcFields: Boolean; virtual; abstract;
    function _GetBeforeCancel: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeClose: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeDelete: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeEdit: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeInsert: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeOpen: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforePost: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeRefresh: TDataSetNotifyEvent; virtual; abstract;
    function _GetBeforeScroll: TDataSetNotifyEvent; virtual; abstract;
    function _GetOnCalcFields: TDataSetNotifyEvent; virtual; abstract;
    function _GetOnDeleteError: TDataSetErrorEvent; virtual; abstract;
    function _GetOnEditError: TDataSetErrorEvent; virtual; abstract;
    function _GetOnFilterRecord: TFilterRecordEvent; virtual; abstract;
    function _GetOnNewRecord: TDataSetNotifyEvent; virtual; abstract;
    function _GetOnPostError: TDataSetErrorEvent; virtual; abstract;
    function _GetSortFields: String; virtual; abstract;
    function _GetBookmark: TBookmark; virtual; abstract;
    function _GetBlockReadSize: Integer; virtual; abstract;
    function _GetFieldValue(const FieldName: string): Variant; virtual; abstract;
    function _GetFetchingAll: Boolean; virtual; abstract;
    procedure _SetFilter(const Value: String); virtual; abstract;
    procedure _SetFiltered(const Value: Boolean); virtual; abstract;
    procedure _SetFilterOptions(Value: TFilterOptions); virtual; abstract;
    procedure _SetActive(const Value: Boolean); virtual; abstract;
    procedure _SetCommandText(const ACommandText: String); virtual; abstract;
    procedure _SetUniDirectional(const Value: Boolean); virtual; abstract;
    procedure _SetReadOnly(const Value: Boolean); virtual; abstract;
    procedure _SetCachedUpdates(const Value: Boolean); virtual; abstract;
    procedure _SetAfterCancel(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterOpen(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterClose(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterDelete(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterEdit(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterInsert(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterPost(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterRefresh(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAfterScroll(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetAutoCalcFields(const Value: Boolean); virtual; abstract;
    procedure _SetBeforeCancel(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeDelete(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeEdit(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeInsert(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeOpen(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeClose(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforePost(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeRefresh(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetBeforeScroll(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetOnFilterRecord(const Value: TFilterRecordEvent); virtual; abstract;
    procedure _SetOnCalcFields(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetOnDeleteError(const Value: TDataSetErrorEvent); virtual; abstract;
    procedure _SetOnEditError(const Value: TDataSetErrorEvent); virtual; abstract;
    procedure _SetOnNewRecord(const Value: TDataSetNotifyEvent); virtual; abstract;
    procedure _SetOnPostError(const Value: TDataSetErrorEvent); virtual; abstract;
    procedure _SetSortFields(const Value: String); virtual; abstract;
    procedure _SetBookmark(const Value: TBookmark); virtual; abstract;
    procedure _SetBlockReadSize(const Value: Integer); virtual; abstract;
    procedure _SetFieldValue(const FieldName: string; const Value: Variant); virtual; abstract;
    procedure _SetFetchingAll(const Value: Boolean); virtual; abstract;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Close; virtual; abstract;
    procedure Open; virtual; abstract;
    procedure Refresh; virtual; abstract;
    procedure Delete; virtual; abstract;
    procedure Cancel; virtual; abstract;
    procedure Clear; virtual; abstract;
    procedure DisableControls; virtual; abstract;
    procedure EnableControls; virtual; abstract;
    procedure Next; virtual; abstract;
    procedure Prior; virtual; abstract;
    procedure Append; virtual; abstract;
    procedure Insert; virtual; abstract;
    procedure Edit; virtual; abstract;
    procedure Post; virtual; abstract;
    procedure First; virtual; abstract;
    procedure Last; virtual; abstract;
    procedure MoveBy(Distance: Integer); virtual; abstract;
    procedure CheckRequiredFields; virtual; abstract;
    procedure FreeBookmark(Bookmark: TBookmark); virtual; abstract;
    procedure ClearFields; virtual; abstract;
    procedure ApplyUpdates; virtual; abstract;
    procedure CancelUpdates; virtual; abstract;
    function Locate(const KeyFields: String; const KeyValues: Variant; Options: TLocateOptions): Boolean; virtual; abstract;
    function Lookup(const KeyFields: String; const KeyValues: Variant; const ResultFields: String): Variant; virtual; abstract;
    function FieldCount: UInt16; virtual; abstract;
    function State: TDataSetState; virtual; abstract;
    function Modified: Boolean; virtual; abstract;
    function FieldByName(const AFieldName: String): TField; virtual; abstract;
    function FindField(const AFieldName: string): TField; virtual; abstract;
    function FindFirst: Boolean; virtual; abstract;
    function FindLast: Boolean; virtual; abstract;
    function FindNext: Boolean; virtual; abstract;
    function FindPrior: Boolean; virtual; abstract;
    function RecordCount: UInt32; virtual; abstract;
    function FieldDefs: TFieldDefs; virtual; abstract;
    function Eof: Boolean; virtual; abstract;
    function Bof: Boolean; virtual; abstract;
    function RecNo: Integer; virtual; abstract;
    function CanRefresh: Boolean; virtual; abstract;
    function DataSetField: TDataSetField; virtual; abstract;
    function DefaultFields: Boolean; virtual; abstract;
    function Designer: TDataSetDesigner; virtual; abstract;
    function FieldList: TFieldList; virtual; abstract;
    function Found: Boolean; virtual; abstract;
    function ObjectView: Boolean; virtual; abstract;
    function RecordSize: Word; virtual; abstract;
    function SparseArrays: Boolean; virtual; abstract;
    function FieldDefList: TFieldDefList; virtual; abstract;
    function Fields: TFields; virtual; abstract;
    function AggFields: TFields; virtual; abstract;
    function UpdatesPending: Boolean; virtual; abstract;
    function UpdateStatus: TUpdateStatus; virtual; abstract;
    function CanModify: Boolean; virtual; abstract;
    function IsEmpty: Boolean; virtual; abstract;
    function DataSource: TDataSource; virtual; abstract;
    function AsDataSet: TDataSet; virtual; abstract;
    function IsUniDirectional: Boolean; virtual; abstract;
    function IsReadOnly: Boolean; virtual; abstract;
    function IsCachedUpdates: Boolean; virtual; abstract;
    function RowsAffected: UInt32; virtual; abstract;
    function NormalizeFieldValue(const AFieldName: String; const AValue: Variant): Variant; virtual; abstract;
  end;

  TDriverDataSet<T: TDataSet> = class(TDriverDataSetBase)
  protected
    FDataSet: T;
    procedure _SetMonitorLog(const ASQL: String; ATransactionName: String;
      const AParams: TParams);
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
    function _GetBlockReadSize: Integer; override;
    function _GetFieldValue(const FieldName: string): Variant; override;
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
    procedure _SetFieldValue(const FieldName: string; const Value: Variant); override;
    procedure _SetFetchingAll(const Value: Boolean); override;
  public
    constructor Create(const ADataSet: T; const AMonitorCallback: TMonitorProc); overload;
    destructor Destroy; override;
    procedure Close; override;
    procedure Open; override;
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
    function Locate(const KeyFields: String; const KeyValues: Variant; Options: TLocateOptions): Boolean; override;
    function Lookup(const KeyFields: String; const KeyValues: Variant; const ResultFields: String): Variant; override;
    function FieldCount: UInt16; override;
    function State: TDataSetState; override;
    function Modified: Boolean; override;
    function FieldByName(const AFieldName: String): TField; override;
    function FindField(const AFieldName: string): TField; override;
    function FindFirst: Boolean; override;
    function FindLast: Boolean; override;
    function FindNext: Boolean; override;
    function FindPrior: Boolean; override;
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

{ TDriverDataSetBase }

constructor TDriverDataSetBase.Create;
begin
  inherited Create;
  FRecordCount := 0;
  FMonitorCallback := nil;
end;

destructor TDriverDataSetBase.Destroy;
begin
  inherited;
end;

{ TDriverDataSet<T> }

constructor TDriverDataSet<T>.Create(const ADataSet: T; const AMonitorCallback: TMonitorProc);
begin
  Create;
  FDataSet := ADataSet;
  FMonitorCallback := AMonitorCallback;
  FRecordCount := 0;
  if Assigned(FDataSet) then
  begin
    try
      FRecordCount := FDataSet.RecordCount;
    except
      FRecordCount := 0;
    end;
  end;
end;

function TDriverDataSet<T>.Designer: TDataSetDesigner;
begin
  Result := FDataSet.Designer;
end;

destructor TDriverDataSet<T>.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverDataSet<T>.AsDataSet: TDataSet;
begin
  Result := FDataSet;
end;

function TDriverDataSet<T>.Bof: Boolean;
begin
  Result := FDataSet.Bof;
end;

function TDriverDataSet<T>.DataSetField: TDataSetField;
begin
  Result := FDataSet.DataSetField;
end;

function TDriverDataSet<T>.DataSource: TDataSource;
begin
  Result := FDataSet.DataSource;
end;

function TDriverDataSet<T>.AggFields: TFields;
begin
  Result := FDataSet.AggFields;
end;

procedure TDriverDataSet<T>.Append;
begin
  FDataSet.Append;
end;

procedure TDriverDataSet<T>.ApplyUpdates;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ApplyUpdates', Self.ClassName]);
end;

procedure TDriverDataSet<T>.Cancel;
begin
  FDataSet.Cancel;
end;

procedure TDriverDataSet<T>.CancelUpdates;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CancelUpdates', Self.ClassName]);
end;

function TDriverDataSet<T>.CanModify: Boolean;
begin
  Result := FDataSet.CanModify;
end;

function TDriverDataSet<T>.CanRefresh: Boolean;
begin
  Result := FDataSet.CanRefresh;
end;

procedure TDriverDataSet<T>.CheckRequiredFields;
var
  LField: TField;
begin
  for LField in FDataSet.Fields do
    if LField.Required and LField.IsNull then
      raise EDatabaseError.CreateFmt('Field %s is required', [LField.FieldName]);
end;

procedure TDriverDataSet<T>.Clear;
begin
  if FDataSet.IsEmpty then
    Exit;
  FDataSet.DisableControls;
  try
    FDataSet.First;
    while not FDataSet.Eof do
      FDataSet.Delete;
  finally
    FDataSet.EnableControls;
  end;
end;

procedure TDriverDataSet<T>.ClearFields;
begin
  FDataSet.ClearFields;
end;

procedure TDriverDataSet<T>.Close;
begin
  FDataSet.Close;
end;

function TDriverDataSet<T>.DefaultFields: Boolean;
begin
  Result := FDataSet.DefaultFields;
end;

procedure TDriverDataSet<T>.Delete;
begin
  FDataSet.Delete;
end;

procedure TDriverDataSet<T>.DisableControls;
begin
  FDataSet.DisableControls;
end;

procedure TDriverDataSet<T>.Edit;
begin
  FDataSet.Edit;
end;

procedure TDriverDataSet<T>.EnableControls;
begin
  FDataSet.EnableControls;
end;

function TDriverDataSet<T>.Eof: Boolean;
begin
  Result := FDataSet.Eof;
end;

function TDriverDataSet<T>.FieldByName(const AFieldName: String): TField;
begin
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverDataSet<T>.FieldCount: UInt16;
begin
  Result := FDataSet.FieldCount;
end;

function TDriverDataSet<T>.FieldDefList: TFieldDefList;
begin
  Result := FDataSet.FieldDefList;
end;

function TDriverDataSet<T>.FieldDefs: TFieldDefs;
begin
  Result := FDataSet.FieldDefs;
end;

function TDriverDataSet<T>.FieldList: TFieldList;
begin
  Result := FDataSet.FieldList;
end;

function TDriverDataSet<T>.Fields: TFields;
begin
  Result := FDataSet.Fields;
end;

function TDriverDataSet<T>.FindField(const AFieldName: string): TField;
begin
  Result := FDataSet.FindField(AFieldName);
end;

function TDriverDataSet<T>.FindFirst: Boolean;
begin
  Result := FDataSet.FindFirst;
end;

function TDriverDataSet<T>.FindLast: Boolean;
begin
  Result := FDataSet.FindLast;
end;

function TDriverDataSet<T>.FindNext: Boolean;
begin
  Result := FDataSet.FindNext;
end;

function TDriverDataSet<T>.FindPrior: Boolean;
begin
  Result := FDataSet.FindPrior;
end;

procedure TDriverDataSet<T>.First;
begin
  FDataSet.First;
end;

function TDriverDataSet<T>.Found: Boolean;
begin
  Result := FDataSet.Found;
end;

procedure TDriverDataSet<T>.FreeBookmark(Bookmark: TBookmark);
begin
  FDataSet.FreeBookmark(Bookmark);
end;

procedure TDriverDataSet<T>.Insert;
begin
  FDataSet.Insert;
end;

function TDriverDataSet<T>.IsCachedUpdates: Boolean;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['IsCachedUpdates', Self.ClassName]);
end;

function TDriverDataSet<T>.IsEmpty: Boolean;
begin
  Result := FDataSet.IsEmpty;
end;

function TDriverDataSet<T>.IsReadOnly: Boolean;
begin
  Result := not FDataSet.CanModify;
end;

function TDriverDataSet<T>.IsUniDirectional: Boolean;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['IsUniDirectional', Self.ClassName]);
end;

procedure TDriverDataSet<T>.Last;
begin
  FDataSet.Last;
end;

function TDriverDataSet<T>.Locate(const KeyFields: String; const KeyValues: Variant;
  Options: TLocateOptions): Boolean;
begin
  Result := FDataSet.Locate(KeyFields, KeyValues, Options);
end;

function TDriverDataSet<T>.Lookup(const KeyFields: String; const KeyValues: Variant;
  const ResultFields: String): Variant;
begin
  Result := FDataSet.Lookup(KeyFields, KeyValues, ResultFields);
end;

function TDriverDataSet<T>.Modified: Boolean;
begin
  Result := FDataSet.Modified;
end;

procedure TDriverDataSet<T>.MoveBy(Distance: Integer);
begin
  FDataSet.MoveBy(Distance);
end;

procedure TDriverDataSet<T>.Next;
begin
  FDataSet.Next;
end;

function TDriverDataSet<T>.NormalizeFieldValue(const AFieldName: String; const AValue: Variant): Variant;
begin
  // Implementação padrão: retorna o valor sem modificação
  // Drivers específicos (ex.: FireDAC) podem sobrescrever para normalizar BLOBs, nulos, etc.
  Result := AValue;
end;

function TDriverDataSet<T>.ObjectView: Boolean;
begin
  Result := FDataSet.ObjectView;
end;

procedure TDriverDataSet<T>.Open;
begin
  FDataSet.Open;
end;

procedure TDriverDataSet<T>.Post;
begin
  FDataSet.Post;
end;

procedure TDriverDataSet<T>.Prior;
begin
  FDataSet.Prior;
end;

procedure TDriverDataSet<T>.Refresh;
begin
  FDataSet.Refresh;
end;

function TDriverDataSet<T>.RecNo: Integer;
begin
  Result := FDataSet.RecNo;
end;

function TDriverDataSet<T>.RecordCount: UInt32;
begin
  Result := FDataSet.RecordCount;
end;

function TDriverDataSet<T>.RecordSize: Word;
begin
  Result := FDataSet.RecordSize;
end;

function TDriverDataSet<T>.RowsAffected: UInt32;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['RowsAffected', Self.ClassName]);
end;

function TDriverDataSet<T>.SparseArrays: Boolean;
begin
  Result := FDataSet.SparseArrays;
end;

function TDriverDataSet<T>.State: TDataSetState;
begin
  Result := FDataSet.State;
end;

function TDriverDataSet<T>.UpdateStatus: TUpdateStatus;
begin
  Result := FDataSet.UpdateStatus;
end;

function TDriverDataSet<T>._GetActive: Boolean;
begin
  Result := FDataSet.Active;
end;

function TDriverDataSet<T>._GetAfterCancel: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterCancel;
end;

function TDriverDataSet<T>._GetAfterClose: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterClose;
end;

function TDriverDataSet<T>._GetAfterDelete: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterDelete;
end;

function TDriverDataSet<T>._GetAfterEdit: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterEdit;
end;

function TDriverDataSet<T>._GetAfterInsert: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterInsert;
end;

function TDriverDataSet<T>._GetAfterOpen: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterOpen;
end;

function TDriverDataSet<T>._GetAfterPost: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterPost;
end;

function TDriverDataSet<T>._GetAfterRefresh: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterRefresh;
end;

function TDriverDataSet<T>._GetAfterScroll: TDataSetNotifyEvent;
begin
  Result := FDataSet.AfterScroll;
end;

function TDriverDataSet<T>._GetAutoCalcFields: Boolean;
begin
  Result := FDataSet.AutoCalcFields;
end;

function TDriverDataSet<T>._GetBeforeCancel: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeCancel;
end;

function TDriverDataSet<T>._GetBeforeClose: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeClose;
end;

function TDriverDataSet<T>._GetBeforeDelete: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeDelete;
end;

function TDriverDataSet<T>._GetBeforeEdit: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeEdit;
end;

function TDriverDataSet<T>._GetBeforeInsert: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeInsert;
end;

function TDriverDataSet<T>._GetBeforeOpen: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeOpen;
end;

function TDriverDataSet<T>._GetBeforePost: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforePost;
end;

function TDriverDataSet<T>._GetBeforeRefresh: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeRefresh;
end;

function TDriverDataSet<T>._GetBeforeScroll: TDataSetNotifyEvent;
begin
  Result := FDataSet.BeforeScroll;
end;

function TDriverDataSet<T>._GetBlockReadSize: Integer;
begin
  Result := FDataSet.BlockReadSize;
end;

function TDriverDataSet<T>._GetBookmark: TBookmark;
begin
  Result := FDataSet.Bookmark;
end;

function TDriverDataSet<T>._GetCommandText: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_GetCommandText', Self.ClassName]);
end;

function TDriverDataSet<T>._GetFetchingAll: Boolean;
begin
  Result := True;
end;

function TDriverDataSet<T>._GetFieldValue(const FieldName: string): Variant;
begin
  Result := FDataSet.FieldValues[FieldName];
end;

function TDriverDataSet<T>._GetFilter: String;
begin
  Result := FDataSet.Filter;
end;

function TDriverDataSet<T>._GetFiltered: Boolean;
begin
  Result := FDataSet.Filtered;
end;

function TDriverDataSet<T>._GetFilterOptions: TFilterOptions;
begin
  Result := FDataSet.FilterOptions;
end;

function TDriverDataSet<T>._GetOnCalcFields: TDataSetNotifyEvent;
begin
  Result := FDataSet.OnCalcFields;
end;

function TDriverDataSet<T>._GetOnDeleteError: TDataSetErrorEvent;
begin
  Result := FDataSet.OnDeleteError;
end;

function TDriverDataSet<T>._GetOnEditError: TDataSetErrorEvent;
begin
  Result := FDataSet.OnEditError;
end;

function TDriverDataSet<T>._GetOnFilterRecord: TFilterRecordEvent;
begin
  Result := FDataSet.OnFilterRecord;
end;

function TDriverDataSet<T>._GetOnNewRecord: TDataSetNotifyEvent;
begin
  Result := FDataSet.OnNewRecord;
end;

function TDriverDataSet<T>._GetOnPostError: TDataSetErrorEvent;
begin
  Result := FDataSet.OnPostError;
end;

function TDriverDataSet<T>._GetSortFields: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_GetSortFields', Self.ClassName]);
end;

procedure TDriverDataSet<T>._SetActive(const Value: Boolean);
begin
  FDataSet.Active := Value;
end;

procedure TDriverDataSet<T>._SetAfterCancel(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterCancel := Value;
end;

procedure TDriverDataSet<T>._SetAfterClose(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterClose := Value;
end;

procedure TDriverDataSet<T>._SetAfterDelete(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterDelete := Value;
end;

procedure TDriverDataSet<T>._SetAfterEdit(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterEdit := Value;
end;

procedure TDriverDataSet<T>._SetAfterInsert(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterInsert := Value;
end;

procedure TDriverDataSet<T>._SetAfterOpen(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterOpen := Value;
end;

procedure TDriverDataSet<T>._SetAfterPost(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterPost := Value;
end;

procedure TDriverDataSet<T>._SetAfterRefresh(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterRefresh := Value;
end;

procedure TDriverDataSet<T>._SetAfterScroll(const Value: TDataSetNotifyEvent);
begin
  FDataSet.AfterScroll := Value;
end;

procedure TDriverDataSet<T>._SetAutoCalcFields(const Value: Boolean);
begin
  FDataSet.AutoCalcFields := Value;
end;

procedure TDriverDataSet<T>._SetBeforeCancel(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeCancel := Value;
end;

procedure TDriverDataSet<T>._SetBeforeClose(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeClose := Value;
end;

procedure TDriverDataSet<T>._SetBeforeDelete(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeDelete := Value;
end;

procedure TDriverDataSet<T>._SetBeforeEdit(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeEdit := Value;
end;

procedure TDriverDataSet<T>._SetBeforeInsert(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeInsert := Value;
end;

procedure TDriverDataSet<T>._SetBeforeOpen(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeOpen := Value;
end;

procedure TDriverDataSet<T>._SetBeforePost(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforePost := Value;
end;

procedure TDriverDataSet<T>._SetBeforeRefresh(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeRefresh := Value;
end;

procedure TDriverDataSet<T>._SetBeforeScroll(const Value: TDataSetNotifyEvent);
begin
  FDataSet.BeforeScroll := Value;
end;

procedure TDriverDataSet<T>._SetCachedUpdates(const Value: Boolean);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetCachedUpdates', Self.ClassName]);
end;

procedure TDriverDataSet<T>._SetCommandText(const ACommandText: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetCommandText', Self.ClassName]);
end;

procedure TDriverDataSet<T>._SetFetchingAll(const Value: Boolean);
begin

end;

procedure TDriverDataSet<T>._SetFieldValue(const FieldName: string; const Value: Variant);
begin
  FDataSet.FieldValues[FieldName] := Value;
end;

procedure TDriverDataSet<T>._SetFilter(const Value: String);
begin
  FDataSet.Filter := Value;
end;

procedure TDriverDataSet<T>._SetFiltered(const Value: Boolean);
begin
  FDataSet.Filtered := Value;
end;

procedure TDriverDataSet<T>._SetFilterOptions(Value: TFilterOptions);
begin
  FDataSet.FilterOptions := Value;
end;

procedure TDriverDataSet<T>._SetMonitorLog(const ASQL: String; ATransactionName: String;
  const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

procedure TDriverDataSet<T>._SetOnCalcFields(const Value: TDataSetNotifyEvent);
begin
  FDataSet.OnCalcFields := Value;
end;

procedure TDriverDataSet<T>._SetOnDeleteError(const Value: TDataSetErrorEvent);
begin
  FDataSet.OnDeleteError := Value;
end;

procedure TDriverDataSet<T>._SetOnEditError(const Value: TDataSetErrorEvent);
begin
  FDataSet.OnEditError := Value;
end;

procedure TDriverDataSet<T>._SetOnFilterRecord(const Value: TFilterRecordEvent);
begin
  FDataSet.OnFilterRecord := Value;
end;

procedure TDriverDataSet<T>._SetOnNewRecord(const Value: TDataSetNotifyEvent);
begin
  FDataSet.OnNewRecord := Value;
end;

procedure TDriverDataSet<T>._SetOnPostError(const Value: TDataSetErrorEvent);
begin
  FDataSet.OnPostError := Value;
end;

procedure TDriverDataSet<T>._SetReadOnly(const Value: Boolean);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetReadOnly', Self.ClassName]);
end;

procedure TDriverDataSet<T>._SetSortFields(const Value: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetSortFields', Self.ClassName]);
end;

procedure TDriverDataSet<T>._SetUniDirectional(const Value: Boolean);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetUniDirectional', Self.ClassName]);
end;

{ TOptions }

constructor TOptions.Create;
begin
  FStoreGUIDAsOctet := False;
end;

function TOptions.StoreGUIDAsOctet(const AValue: Boolean): IOptions;
begin
  Result := Self;
  FStoreGUIDAsOctet := AValue;
end;

function TOptions.StoreGUIDAsOctet: Boolean;
begin
  Result := FStoreGUIDAsOctet;
end;

{ TDriverQuery }

procedure TDriverQuery.ExecuteDirect;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ExecuteDirect', Self.ClassName]);
end;

function TDriverQuery.ExecuteQuery: IDBDataSet;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ExecuteQuery', Self.ClassName]);
end;

function TDriverQuery.RowsAffected: UInt32;
begin
  Result := FRowsAffected;
end;

function TDriverQuery._GetCommandText: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_GetCommandText', Self.ClassName]);
end;

procedure TDriverQuery._SetCommandText(const ACommandText: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['_SetCommandText', Self.ClassName]);
end;

procedure TDriverQuery._SetMonitorLog(const ASQL, ATransactionName: String; const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

{ TDriverConnection }

procedure TDriverConnection.Connect;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Connect', Self.ClassName]);
end;

procedure TDriverConnection.Disconnect;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Disconnect', Self.ClassName]);
end;

procedure TDriverConnection.ExecuteDirect(const ASQL: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ExecuteDirect', Self.ClassName]);
end;

procedure TDriverConnection.ExecuteDirect(const ASQL: String; const AParams: TParams);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ExecuteDirect', Self.ClassName]);
end;

procedure TDriverConnection.ExecuteScript(const AScript: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ExecuteScript', Self.ClassName]);
end;

procedure TDriverConnection.AddScript(const AScript: String);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['AddScript', Self.ClassName]);
end;

procedure TDriverConnection.ExecuteScripts;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ExecuteScripts', Self.ClassName]);
end;

procedure TDriverConnection.ApplyUpdates(const ADataSets: array of IDBDataSet);
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['ApplyUpdates', Self.ClassName]);
end;

function TDriverConnection.IsConnected: Boolean;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['IsConnected', Self.ClassName]);
end;

function TDriverConnection.MonitorCallback: TMonitorProc;
begin
  Result := FMonitorCallback;
end;

function TDriverConnection.CreateQuery: IDBQuery;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CreateQuery', Self.ClassName]);
end;

function TDriverConnection.CreateDataSet(const ASQL: String): IDBDataSet;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['CreateDataSet', Self.ClassName]);
end;

function TDriverConnection.GetSQLScripts: String;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['GetSQLScripts', Self.ClassName]);
end;

constructor TDriverConnection.Create(const AConnection: TComponent;
  const ADriverTransaction: TDriverTransaction; const ADriverName: TDBEngineDriver;
  const AMonitorCallback: TMonitorProc);
begin
  FDriverTransaction := ADriverTransaction;
  FMonitorCallback := AMonitorCallback;
  FDriver := ADriverName;
  FRowsAffected := 0;
end;

function TDriverConnection.GetDriver: TDBEngineDriver;
begin
  Result := FDriver;
end;

function TDriverConnection.RowsAffected: UInt32;
begin
  Result := FRowsAffected;
end;

procedure TDriverConnection._SetMonitorLog(const ASQL, ATransactionName: String;
  const AParams: TParams);
begin
  if Assigned(FMonitorCallback) then
    FMonitorCallback(TMonitorParam.Create('[Transaction: ' + ATransactionName + '] - ' + TrimRight(ASQL), AParams));
end;

{ TDriverTransaction }

procedure TDriverTransaction.AddTransaction(const AKey: String; const ATransaction: TComponent);
var
  LKeyUC: String;
begin
  LKeyUC := UpperCase(AKey);
  FLock.Enter;
  try
    if FTransactionList.ContainsKey(LKeyUC) then
      raise Exception.Create('Transaction with the same name already exists.');
    if ATransaction.Name = EmptyStr then
      ATransaction.Name := AKey;
    FTransactionList.Add(LKeyUC, ATransaction);
  finally
    FLock.Leave;
  end;
end;

constructor TDriverTransaction.Create(const AConnection: TComponent);
begin
  FLock := TCriticalSection.Create;
  FTransactionList := TDictionary<String, TComponent>.Create;
end;

destructor TDriverTransaction.Destroy;
begin
  FTransactionActive := nil;
  FTransactionList.Clear;
  FTransactionList.Free;
  FLock.Free;
  inherited;
end;

procedure TDriverTransaction.StartTransaction;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['StartTransaction', Self.ClassName]);
end;

procedure TDriverTransaction.Commit;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Commit', Self.ClassName]);
end;

procedure TDriverTransaction.Rollback;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['Rollback', Self.ClassName]);
end;

function TDriverTransaction.InTransaction: Boolean;
begin
  raise EAbstractError.CreateFmt(ABSTRACT_METHOD_ERROR, ['InTransaction', Self.ClassName]);
end;

function TDriverTransaction.TransactionActive: TComponent;
begin
  Result := FTransactionActive;
end;

procedure TDriverTransaction.UseTransaction(const AKey: String);
var
  LKeyUC: String;
begin
  LKeyUC := UpperCase(AKey);
  FLock.Enter;
  try
    if not FTransactionList.TryGetValue(LKeyUC, FTransactionActive) then
      raise Exception.Create('Transaction not found.');
  finally
    FLock.Leave;
  end;
end;

function TDriverTransaction._GetTransaction(const AKey: String): TComponent;
var
  LKeyUC: String;
begin
  LKeyUC := UpperCase(AKey);
  FLock.Enter;
  try
    if not FTransactionList.TryGetValue(LKeyUC, Result) then
      raise Exception.Create('Transaction not found.');
  finally
    FLock.Leave;
  end;
end;

end.
