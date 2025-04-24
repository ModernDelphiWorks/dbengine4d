unit DBEngine.FactoryInterfaces;

interface

uses
  DB,
  Classes,
  SysUtils,
  Variants;

type
  TMonitorParam = record
    Command: String;
    Params: TParams;
    constructor Create(const ACommand: String; AParams: TParams);
  end;

  TMonitorProc = reference to procedure(const ACommand: TMonitorParam);

  // {$SCOPEDENUMS ON}
  TDBEngineDriver = (dnMSSQL, dnMySQL, dnFirebird, dnSQLite, dnInterbase, dnDB2,
                     dnOracle, dnInformix, dnPostgreSQL, dnADS, dnASA,
                     dnFirebase, dnFirebird3, dnAbsoluteDB, dnMongoDB,
                     dnElevateDB, dnNexusDB, dnMariaDB, dnMemory);
  // {$SCOPEDENUMS OFF}

  TFieldHelper = class helper for TField
  public
    function AsStringDef(const Def: String = ''): String;
    function AsIntegerDef(const Def: Integer = 0): Integer;
    function AsDateTimeDef(const Def: TDateTime = 0.0): TDateTime;
    function AsDoubleDef(const Def: Double = 0.0): Double;
    function AsFloatDef(const Def: Double = 0.0): Double;
    function AsCurrencyDef(const Def: Currency = 0.0): Currency;
    function AsBooleanDef(const Def: Boolean = False): Boolean;
    function AsVariantDef(const Def: Variant): Variant;
    function ValueDef(const Def: Variant): Variant;
  end;

  IDBDataSet = interface
    ['{AB044ADD-9E30-4ADA-92CF-DD75EC096981}']
    function _GetFilter: String;
    function _GetFiltered: Boolean;
    function _GetFilterOptions: TFilterOptions;
    function _GetActive: Boolean;
    function _GetCommandText: String;
    function _GetAfterCancel: TDataSetNotifyEvent;
    function _GetAfterClose: TDataSetNotifyEvent;
    function _GetAfterDelete: TDataSetNotifyEvent;
    function _GetAfterEdit: TDataSetNotifyEvent;
    function _GetAfterInsert: TDataSetNotifyEvent;
    function _GetAfterOpen: TDataSetNotifyEvent;
    function _GetAfterPost: TDataSetNotifyEvent;
    function _GetAfterRefresh: TDataSetNotifyEvent;
    function _GetAfterScroll: TDataSetNotifyEvent;
    function _GetAutoCalcFields: Boolean;
    function _GetBeforeCancel: TDataSetNotifyEvent;
    function _GetBeforeClose: TDataSetNotifyEvent;
    function _GetBeforeDelete: TDataSetNotifyEvent;
    function _GetBeforeEdit: TDataSetNotifyEvent;
    function _GetBeforeInsert: TDataSetNotifyEvent;
    function _GetBeforeOpen: TDataSetNotifyEvent;
    function _GetBeforePost: TDataSetNotifyEvent;
    function _GetBeforeRefresh: TDataSetNotifyEvent;
    function _GetBeforeScroll: TDataSetNotifyEvent;
    function _GetOnCalcFields: TDataSetNotifyEvent;
    function _GetOnDeleteError: TDataSetErrorEvent;
    function _GetOnEditError: TDataSetErrorEvent;
    function _GetOnFilterRecord: TFilterRecordEvent;
    function _GetOnNewRecord: TDataSetNotifyEvent;
    function _GetOnPostError: TDataSetErrorEvent;
    function _GetSortFields: String;
    function _GetBookmark: TBookmark;
    function _GetBlockReadSize: Integer;
    function _GetFieldValue(const FieldName: string): Variant;
    function _GetFetchingAll: Boolean;
    procedure _SetFilter(const Value: String);
    procedure _SetFiltered(const Value: Boolean);
    procedure _SetFilterOptions(Value: TFilterOptions);
    procedure _SetActive(const Value: Boolean);
    procedure _SetCommandText(const ACommandText: String);
    procedure _SetUniDirectional(const Value: Boolean);
    procedure _SetReadOnly(const Value: Boolean);
    procedure _SetCachedUpdates(const Value: Boolean);
    procedure _SetAfterCancel(const Value: TDataSetNotifyEvent);
    procedure _SetAfterOpen(const Value: TDataSetNotifyEvent);
    procedure _SetAfterClose(const Value: TDataSetNotifyEvent);
    procedure _SetAfterDelete(const Value: TDataSetNotifyEvent);
    procedure _SetAfterEdit(const Value: TDataSetNotifyEvent);
    procedure _SetAfterInsert(const Value: TDataSetNotifyEvent);
    procedure _SetAfterPost(const Value: TDataSetNotifyEvent);
    procedure _SetAfterRefresh(const Value: TDataSetNotifyEvent);
    procedure _SetAfterScroll(const Value: TDataSetNotifyEvent);
    procedure _SetAutoCalcFields(const Value: Boolean);
    procedure _SetBeforeCancel(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeDelete(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeEdit(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeInsert(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeOpen(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeClose(const Value: TDataSetNotifyEvent);
    procedure _SetBeforePost(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeRefresh(const Value: TDataSetNotifyEvent);
    procedure _SetBeforeScroll(const Value: TDataSetNotifyEvent);
    procedure _SetOnFilterRecord(const Value: TFilterRecordEvent);
    procedure _SetOnCalcFields(const Value: TDataSetNotifyEvent);
    procedure _SetOnDeleteError(const Value: TDataSetErrorEvent);
    procedure _SetOnEditError(const Value: TDataSetErrorEvent);
    procedure _SetOnNewRecord(const Value: TDataSetNotifyEvent);
    procedure _SetOnPostError(const Value: TDataSetErrorEvent);
    procedure _SetSortFields(const Value: String);
    procedure _SetBookmark(const Value: TBookmark);
    procedure _SetBlockReadSize(const Value: Integer);
    procedure _SetFieldValue(const FieldName: string; const Value: Variant);
    procedure _SetFetchingAll(const Value: Boolean);
    procedure Close;
    procedure Open;
    procedure Refresh;
    procedure Delete;
    procedure Cancel;
    procedure Clear;
    procedure DisableControls;
    procedure EnableControls;
    procedure Next;
    procedure Prior;
    procedure Append;
    procedure Insert;
    procedure Edit;
    procedure Post;
    procedure First;
    procedure Last;
    procedure MoveBy(Distance: Integer);
    procedure CheckRequiredFields;
    procedure FreeBookmark(Bookmark: TBookmark);
    procedure ClearFields;
    procedure ApplyUpdates;
    procedure CancelUpdates;
    function Locate(const KeyFields: String; const KeyValues: Variant; Options: TLocateOptions): Boolean;
    function Lookup(const KeyFields: String; const KeyValues: Variant; const ResultFields: String): Variant;
    function FieldCount: UInt16;
    function State: TDataSetState;
    function RecordCount: UInt32;
    function FieldDefs: TFieldDefs;
    function Eof: Boolean;
    function Bof: Boolean;
    function RecNo: Integer;
    function CanRefresh: Boolean;
    function DataSetField: TDataSetField;
    function DefaultFields: Boolean;
    function Designer: TDataSetDesigner;
    function FieldList: TFieldList;
    function Found: Boolean;
    function ObjectView: Boolean;
    function RecordSize: Word;
    function SparseArrays: Boolean;
    function FieldDefList: TFieldDefList;
    function Fields: TFields;
    function RowsAffected: UInt32;
    function Modified: Boolean;
    function FieldByName(const AFieldName: String): TField;
    function FindField(const AFieldName: string): TField;
    function FindFirst: Boolean;
    function FindLast: Boolean;
    function FindNext: Boolean;
    function FindPrior: Boolean;
    function AggFields: TFields;
    function UpdatesPending: Boolean;
    function UpdateStatus: TUpdateStatus;
    function CanModify: Boolean;
    function IsEmpty: Boolean;
    function IsUniDirectional: Boolean;
    function IsReadOnly: Boolean;
    function IsCachedUpdates: Boolean;
    function DataSource: TDataSource;
    function NormalizeFieldValue(const AFieldName: String; const AValue: Variant): Variant;
    function AsDataSet: TDataSet;
    //
    property FetchingAll: Boolean read _GetFetchingAll write _SetFetchingAll;
    property Filter: String read _GetFilter write _SetFilter;
    property FilterOptions: TFilterOptions read _GetFilterOptions write _SetFilterOptions;
    property Filtered: Boolean read _GetFiltered write _SetFiltered;
    property Active: Boolean read _GetActive write _SetActive;
    property CommandText: String read _GetCommandText write _SetCommandText;
    property UniDirectional: Boolean write _SetUniDirectional;
    property ReadOnly: Boolean write _SetReadOnly;
    property CachedUpdates: Boolean write _SetCachedUpdates;
    property AutoCalcFields: Boolean read _GetAutoCalcFields write _SetAutoCalcFields;
    property SortFields: String read _GetSortFields write _SetSortFields;
    property Bookmark: TBookmark read _GetBookmark write _SetBookmark;
    property BlockReadSize: Integer read _GetBlockReadSize write _SetBlockReadSize;
    property FieldValues[const FieldName: string]: Variant read _GetFieldValue write _SetFieldValue;
    property BeforeOpen: TDataSetNotifyEvent read _GetBeforeOpen write _SetBeforeOpen;
    property AfterOpen: TDataSetNotifyEvent read _GetAfterOpen write _SetAfterOpen;
    property BeforeClose: TDataSetNotifyEvent read _GetBeforeClose write _SetBeforeClose;
    property AfterClose: TDataSetNotifyEvent read _GetAfterClose write _SetAfterClose;
    property BeforeInsert: TDataSetNotifyEvent read _GetBeforeInsert write _SetBeforeInsert;
    property AfterInsert: TDataSetNotifyEvent read _GetAfterInsert write _SetAfterInsert;
    property BeforeEdit: TDataSetNotifyEvent read _GetBeforeEdit write _SetBeforeEdit;
    property AfterEdit: TDataSetNotifyEvent read _GetAfterEdit write _SetAfterEdit;
    property BeforePost: TDataSetNotifyEvent read _GetBeforePost write _SetBeforePost;
    property AfterPost: TDataSetNotifyEvent read _GetAfterPost write _SetAfterPost;
    property BeforeCancel: TDataSetNotifyEvent read _GetBeforeCancel write _SetBeforeCancel;
    property AfterCancel: TDataSetNotifyEvent read _GetAfterCancel write _SetAfterCancel;
    property BeforeDelete: TDataSetNotifyEvent read _GetBeforeDelete write _SetBeforeDelete;
    property AfterDelete: TDataSetNotifyEvent read _GetAfterDelete write _SetAfterDelete;
    property BeforeScroll: TDataSetNotifyEvent read _GetBeforeScroll write _SetBeforeScroll;
    property AfterScroll: TDataSetNotifyEvent read _GetAfterScroll write _SetAfterScroll;
    property BeforeRefresh: TDataSetNotifyEvent read _GetBeforeRefresh write _SetBeforeRefresh;
    property AfterRefresh: TDataSetNotifyEvent read _GetAfterRefresh write _SetAfterRefresh;
    property OnCalcFields: TDataSetNotifyEvent read _GetOnCalcFields write _SetOnCalcFields;
    property OnDeleteError: TDataSetErrorEvent read _GetOnDeleteError write _SetOnDeleteError;
    property OnEditError: TDataSetErrorEvent read _GetOnEditError write _SetOnEditError;
    property OnFilterRecord: TFilterRecordEvent read _GetOnFilterRecord write _SetOnFilterRecord;
    property OnNewRecord: TDataSetNotifyEvent read _GetOnNewRecord write _SetOnNewRecord;
    property OnPostError: TDataSetErrorEvent read _GetOnPostError write _SetOnPostError;
  end;

  IDBQuery = interface
    ['{C7934907-7D75-49B2-B11A-A12CDCE98862}']
    procedure _SetCommandText(const ACommandText: String);
    function _GetCommandText: String;
    procedure ExecuteDirect;
    function ExecuteQuery: IDBDataSet;
    function RowsAffected: UInt32;
    property CommandText: String read _GetCommandText write _SetCommandText;
  end;

  ICommandMonitor = interface
    ['{8BB25F68-91E0-469A-B8ED-0FE6AF4A2028}']
    procedure Command(const ASQL: String; AParams: TParams);
    procedure Show;
  end;

  IOptions = interface
    ['{37DFE79A-BA0A-41C9-9D7C-DF549068A2F0}']
    function StoreGUIDAsOctet(const AValue: Boolean): IOptions; overload;
    function StoreGUIDAsOctet: Boolean; overload;
  end;

  IDBTransaction = interface
    ['{F08CB640-4403-4E7B-A6B2-4D1D8607190A}']
    function _GetTransaction(const AKey: String): TComponent;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure AddTransaction(const AKey: String; const ATransaction: TComponent);
    procedure UseTransaction(const AKey: String);
    function TransactionActive: TComponent;
    function InTransaction: Boolean;
    property Transaction[const AKey: String]: TComponent read _GetTransaction;
  end;

  IDBConnection = interface(IDBTransaction)
    ['{5AF37B2C-65D1-4899-AAE9-866390E01DA4}']
    procedure Connect;
    procedure Disconnect;
    procedure ExecuteDirect(const ASQL: String); overload;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); overload;
    procedure ExecuteScript(const AScript: String);
    procedure AddScript(const AScript: String);
    procedure ExecuteScripts;
    procedure ApplyUpdates(const ADataSets: array of IDBDataSet);
    function IsConnected: Boolean;
    function CreateQuery: IDBQuery;
    function CreateDataSet(const ASQL: String = ''): IDBDataSet;
    function GetSQLScripts: String;
    function RowsAffected: UInt32;
    function GetDriver: TDBEngineDriver;
    function CommandMonitor: ICommandMonitor;
    function MonitorCallback: TMonitorProc;
    function Options: IOptions;
    procedure SetCommandMonitor(AMonitor: ICommandMonitor);
  end;

const
  TStrDBEngineDriver: array[TDBEngineDriver.dnMSSQL..TDBEngineDriver.dnMemory] of
                 string = ('MSSQL','MySQL','Firebird','SQLite','Interbase',
                           'DB2','Oracle','Informix','PostgreSQL','ADS','ASA',
                           'dnFirebase', 'dnFirebird3','AbsoluteDB','MongoDB',
                           'ElevateDB','NexusDB','MariaDB', 'Memory');

implementation

{ TMonitorParam }

constructor TMonitorParam.Create(const ACommand: String; AParams: TParams);
begin
  Command := ACommand;
  Params := AParams;
end;

{ TFieldHelper }

function TFieldHelper.AsStringDef(const Def: String): String;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsString;
    except
      Result := Def;
    end;
end;

function TFieldHelper.AsIntegerDef(const Def: Integer): Integer;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsInteger;
    except
      Result := Def;
    end;
end;

function TFieldHelper.AsDateTimeDef(const Def: TDateTime): TDateTime;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsDateTime;
    except
      Result := Def;
    end;
end;

function TFieldHelper.AsDoubleDef(const Def: Double): Double;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsFloat;
    except
      Result := Def;
    end;
end;

function TFieldHelper.AsFloatDef(const Def: Double): Double;
begin
  Result := AsDoubleDef(Def);
end;

function TFieldHelper.AsCurrencyDef(const Def: Currency): Currency;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsCurrency;
    except
      Result := Def;
    end;
end;

function TFieldHelper.AsBooleanDef(const Def: Boolean): Boolean;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsBoolean;
    except
      Result := Def;
    end;
end;

function TFieldHelper.AsVariantDef(const Def: Variant): Variant;
begin
  if IsNull then
    Result := Def
  else
    try
      Result := AsVariant;
    except
      Result := Def;
    end;
end;

function TFieldHelper.ValueDef(const Def: Variant): Variant;
begin
  Result := AsVariantDef(Def);
end;

end.
