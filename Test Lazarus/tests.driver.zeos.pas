unit tests.driver.zeos;

{$mode objfpc}{$H+}

interface

uses
  DB,
  Classes, SysUtils, fpcunit, testutils, testregistry,

  ZConnection,
  DBE.FactoryInterfaces;

type

  { TTestDBEZeos }

  TTestDBEZeos= class(TTestCase)
  strict private
    FConnection: TZConnection;
    FDBConnection: IDBConnection;
    FDBQuery: IDBQuery;
    FDBResultSet: IDBResultSet;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConnect;
    procedure TestDisconnect;
    procedure TestExecuteDirect;
    procedure TestExecuteDirectParams;
    procedure TestExecuteScript;
    procedure TestAddScript;
    procedure TestExecuteScripts;
    procedure TestIsConnected;
    procedure TestInTransaction;
    procedure TestCreateQuery;
    procedure TestCreateDataSet;
    procedure TestStartTransaction;
    procedure TestCommit;
    procedure TestRollback;
  end;

implementation

uses
  dbe.factory.zeos,
  Tests.Consts;

procedure TTestDBEZeos.TestConnect;
begin
  FDBConnection.Connect;
  AssertEquals('FConnection.IsConnected = True', True, FDBConnection.IsConnected);
end;

procedure TTestDBEZeos.TestDisconnect;
begin
  FDBConnection.Disconnect;
  AssertEquals('FConnection.IsConnected = False', False, FDBConnection.IsConnected);
end;

procedure TTestDBEZeos.TestExecuteDirect;
var
  LValue: String;
  LRandon: String;
begin
  LRandon := IntToStr( Random(9999) );

  FDBConnection.ExecuteDirect( Format(cSQLUPDATE, [QuotedStr(cDESCRIPTION + LRandon), '1']) );

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := Format(cSQLSELECT, ['1']);
  LValue := FDBQuery.ExecuteQuery.FieldByName('CLIENT_NAME').AsString;

  AssertEquals(LValue + ' <> ' + cDESCRIPTION + LRandon, LValue, cDESCRIPTION + LRandon);
end;

procedure TTestDBEZeos.TestExecuteDirectParams;
var
  LParams: TParams;
  LRandon: String;
  LValue: String;
begin
  LRandon := IntToStr( Random(9999) );

  LParams := TParams.Create(nil);
  try
    with LParams.Add as TParam do
    begin
      Name := 'CLIENT_NAME';
      DataType := ftString;
      Value := cDESCRIPTION + LRandon;
      ParamType := ptInput;
    end;
    with LParams.Add as TParam do
    begin
      Name := 'CLIENT_ID';
      DataType := ftInteger;
      Value := 1;
      ParamType := ptInput;
    end;
    FDBConnection.ExecuteDirect(cSQLUPDATEPARAM, LParams);

    FDBResultSet := FDBConnection.CreateDataSet(Format(cSQLSELECT, ['1']));
    LValue := FDBResultSet.FieldByName('CLIENT_NAME').AsString;

    AssertEquals(LValue + ' <> ' + cDESCRIPTION + LRandon, LValue, cDESCRIPTION + LRandon);
  finally
    LParams.Free;
  end;
end;

procedure TTestDBEZeos.TestExecuteScript;
begin

end;

procedure TTestDBEZeos.TestAddScript;
begin

end;

procedure TTestDBEZeos.TestExecuteScripts;
begin

end;

procedure TTestDBEZeos.TestIsConnected;
begin
  AssertEquals('FConnection.IsConnected = False', False, FDBConnection.IsConnected);
end;

procedure TTestDBEZeos.TestInTransaction;
begin
  FDBConnection.Connect;
  FDBConnection.StartTransaction;

  AssertEquals('FConnection.InTransaction <> FFDConnection.InTransaction', FDBConnection.InTransaction, FConnection.InTransaction);

  FDBConnection.Rollback;
  FDBConnection.Disconnect;
end;

procedure TTestDBEZeos.TestCreateQuery;
var
  LValue: String;
  LRandon: String;
begin
  LRandon := IntToStr( Random(9999) );

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := Format(cSQLUPDATE, [QuotedStr(cDESCRIPTION + LRandon), '1']);
  FDBQuery.ExecuteDirect;

  FDBQuery.CommandText := Format(cSQLSELECT, ['1']);
  LValue := FDBQuery.ExecuteQuery.FieldByName('CLIENT_NAME').AsString;

  AssertEquals(LValue + ' <> ' + cDESCRIPTION + LRandon, LValue, cDESCRIPTION + LRandon);
end;

procedure TTestDBEZeos.TestCreateDataSet;
begin
  FDBResultSet := FDBConnection.CreateDataSet(Format(cSQLSELECT, ['1']));

  AssertEquals('FDBResultSet.RecordCount = ' + IntToStr(FDBResultSet.RecordCount), 1, FDBResultSet.RecordCount);
end;

procedure TTestDBEZeos.TestStartTransaction;
begin
  FDBConnection.StartTransaction;
  AssertEquals('FConnection.InTransaction = True', True, FDBConnection.InTransaction);
end;

procedure TTestDBEZeos.TestCommit;
begin
  TestStartTransaction;

  FDBConnection.Commit;
  AssertEquals('FConnection.InTransaction = False', False, FDBConnection.InTransaction);
end;

procedure TTestDBEZeos.TestRollback;
begin
  TestStartTransaction;

  FDBConnection.Rollback;
  AssertEquals('FConnection.InTransaction = False', False, FDBConnection.InTransaction);
end;

procedure TTestDBEZeos.SetUp;
begin
  FConnection := TZConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FConnection.Protocol := 'sqlite';
  FConnection.Database := 'database.db3';

  FDBConnection := TFactoryUniDAC.Create(FConnection, dnSQLite);
end;

procedure TTestDBEZeos.TearDown;
begin
  if Assigned(FConnection) then
    FreeAndNil(FConnection);
end;

initialization
  RegisterTest(TTestDBEZeos);

end.

