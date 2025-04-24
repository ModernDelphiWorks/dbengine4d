unit Tests.Driver.Memory;

interface

uses
  DUnitX.TestFramework,
  Classes,
  SysUtils,
  Data.DB,
  DBEngine.FactoryInterfaces,
  DBEngine.DriverMemory,
  DBEngine.DriverMemoryTransaction,
  DBEngine.FactoryMemory;

type
  [TestFixture]
  TTestMemoryDriverConnection = class(TObject)
  strict private
    FConnection: TComponent;
    FDBConnection: IDBConnection;
    FDBQuery: IDBQuery;
    FDBDataSet: IDBDataSet;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestConnect;
    [Test]
    procedure TestDisconnect;
    [Test]
    procedure TestExecuteDirect;
    [Test]
    procedure TestExecuteDirectParams;
    [Test]
    procedure TestExecuteScript;
    [Test]
    procedure TestAddScript;
    [Test]
    procedure TestExecuteScripts;
    [Test]
    procedure TestIsConnected;
    [Test]
    procedure TestInTransaction;
    [Test]
    procedure TestCreateQuery;
    [Test]
    procedure TestCreateDataSet;
    [Test]
    procedure TestStartTransaction;
    [Test]
    procedure TestCommit;
    [Test]
    procedure TestRollback;
    [Test]
    procedure TestFluentQuery;
  end;

implementation

const
  cSQLUPDATE = 'UPDATE CLIENTES SET CLIENT_NAME = %s WHERE CLIENT_ID = %s';
  cSQLUPDATEPARAM = 'UPDATE CLIENTES SET CLIENT_NAME = :CLIENT_NAME WHERE CLIENT_ID = :CLIENT_ID';
  cSQLSELECT = 'SELECT * FROM CLIENTES WHERE CLIENT_ID = %s';
  cDESCRIPTION = 'TestClient_';

{ TTestMemoryDriverConnection }

procedure TTestMemoryDriverConnection.Setup;
begin
  FConnection := TComponent.Create(nil);
  FDBConnection := TFactoryMemory.Create(FConnection, dnMemory,
                   procedure (const ACommand: TMonitorParam)
                   begin
                     WriteLn(ACommand.Command)
                   end);
  FDBConnection.ExecuteDirect('INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (1, ''InitialClient'')');
end;

procedure TTestMemoryDriverConnection.TearDown;
begin
  if Assigned(FDBConnection) then
    FDBConnection.Disconnect;
  if Assigned(FConnection) then
    FreeAndNil(FConnection);
  FDBQuery := nil;
  FDBDataSet := nil;
  FDBConnection := nil;
end;

procedure TTestMemoryDriverConnection.TestConnect;
begin
  FDBConnection.Connect;
  Assert.IsTrue(FDBConnection.IsConnected, 'FConnection.IsConnected = True');
end;

procedure TTestMemoryDriverConnection.TestDisconnect;
begin
  FDBConnection.Disconnect;
  Assert.IsFalse(FDBConnection.IsConnected, 'FConnection.IsConnected = False');
end;

procedure TTestMemoryDriverConnection.TestExecuteDirect;
var
  LValue: String;
  LRandon: String;
begin
  LRandon := IntToStr(Random(9999));
  FDBConnection.ExecuteDirect(Format(cSQLUPDATE, [QuotedStr(cDESCRIPTION + LRandon), '1']));

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := Format(cSQLSELECT, ['1']);
  FDBDataSet := FDBQuery.ExecuteQuery;
  FDBDataSet.Open;
  LValue := FDBDataSet.FieldByName('CLIENT_NAME').AsString;

  Assert.AreEqual(cDESCRIPTION + LRandon, LValue, 'Expected ' + cDESCRIPTION + LRandon + ' but got ' + LValue);
end;

procedure TTestMemoryDriverConnection.TestExecuteDirectParams;
var
  LParams: TParams;
  LRandon: String;
  LValue: String;
begin
  LRandon := IntToStr(Random(9999));

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

    FDBDataSet := FDBConnection.CreateDataSet(Format(cSQLSELECT, ['1']));
    FDBDataSet.Open;
    LValue := FDBDataSet.FieldByName('CLIENT_NAME').AsString;

    Assert.AreEqual(cDESCRIPTION + LRandon, LValue, 'Expected ' + cDESCRIPTION + LRandon + ' but got ' + LValue);
  finally
    LParams.Free;
  end;
end;

procedure TTestMemoryDriverConnection.TestExecuteScript;
var
  LScript: string;
  LValue: string;
begin
  LScript := 'INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (2, ''ScriptClient'');' +
             'UPDATE CLIENTES SET CLIENT_NAME = ''UpdatedScript'' WHERE CLIENT_ID = 2';
  FDBConnection.ExecuteScript(LScript);

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := 'SELECT * FROM CLIENTES WHERE CLIENT_ID = 2';
  FDBDataSet := FDBQuery.ExecuteQuery;
  FDBDataSet.Open;
  LValue := FDBDataSet.FieldByName('CLIENT_NAME').AsString;
  Assert.AreEqual('UpdatedScript', LValue, 'Expected UpdatedScript but got ' + LValue);
end;

procedure TTestMemoryDriverConnection.TestAddScript;
begin
  FDBConnection.AddScript('INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (3, ''AddedScript'')');
  Assert.AreEqual(Trim(FDBConnection.GetSQLScripts), 'INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (3, ''AddedScript'')', 'Script not added correctly');
end;

procedure TTestMemoryDriverConnection.TestExecuteScripts;
var
  LValue: string;
begin
  FDBConnection.AddScript('INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (4, ''ScriptTest'')');
  FDBConnection.ExecuteScripts;

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := 'SELECT * FROM CLIENTES WHERE CLIENT_ID = 4';
  FDBDataSet := FDBQuery.ExecuteQuery;
  FDBDataSet.Open;
  LValue := FDBDataSet.FieldByName('CLIENT_NAME').AsString;
  Assert.AreEqual('ScriptTest', LValue, 'Expected ScriptTest but got ' + LValue);
end;

procedure TTestMemoryDriverConnection.TestIsConnected;
begin
  Assert.IsFalse(FDBConnection.IsConnected, 'FConnection.IsConnected = False');
  FDBConnection.Connect;
  Assert.IsTrue(FDBConnection.IsConnected, 'FConnection.IsConnected = True');
end;

procedure TTestMemoryDriverConnection.TestInTransaction;
begin
  FDBConnection.Connect;
  FDBConnection.StartTransaction;

  Assert.IsTrue(FDBConnection.InTransaction, 'FConnection.InTransaction = True');

  FDBConnection.Rollback;
  FDBConnection.Disconnect;
end;

procedure TTestMemoryDriverConnection.TestCreateQuery;
var
  LValue: String;
  LRandon: String;
begin
  LRandon := IntToStr(Random(9999));

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := Format(cSQLUPDATE, [QuotedStr(cDESCRIPTION + LRandon), '1']);
  FDBQuery.ExecuteDirect;

  FDBQuery.CommandText := Format(cSQLSELECT, ['1']);
  FDBDataSet := FDBQuery.ExecuteQuery;
  FDBDataSet.Open;
  LValue := FDBDataSet.FieldByName('CLIENT_NAME').AsString;

  Assert.AreEqual(cDESCRIPTION + LRandon, LValue, 'Expected ' + cDESCRIPTION + LRandon + ' but got ' + LValue);
end;

procedure TTestMemoryDriverConnection.TestCreateDataSet;
begin
  FDBDataSet := FDBConnection.CreateDataSet(Format(cSQLSELECT, ['1']));
  FDBDataSet.Open;

  Assert.IsTrue(FDBDataSet.RecordCount = 1, 'FDBDataSet.RecordCount = ' + IntToStr(FDBDataSet.RecordCount));
end;

procedure TTestMemoryDriverConnection.TestStartTransaction;
begin
  FDBConnection.StartTransaction;
  Assert.IsTrue(FDBConnection.InTransaction, 'FConnection.InTransaction = True');
end;

procedure TTestMemoryDriverConnection.TestCommit;
begin
  TestStartTransaction;

  FDBConnection.Commit;
  Assert.IsFalse(FDBConnection.InTransaction, 'FConnection.InTransaction = False');
end;

procedure TTestMemoryDriverConnection.TestRollback;
begin
  TestStartTransaction;

  FDBConnection.Rollback;
  Assert.IsFalse(FDBConnection.InTransaction, 'FConnection.InTransaction = False');
end;

procedure TTestMemoryDriverConnection.TestFluentQuery;
var
  LDataSet: IDBDataSet;
  LValue: String;
  LQuery: IDBQuery;
begin
  // Dados já são inseridos na mesma conexão mantida por FDBConnection
  FDBConnection.ExecuteDirect('INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (1, ''TestClient1'')');
  FDBConnection.ExecuteDirect('INSERT INTO CLIENTES (CLIENT_ID, CLIENT_NAME) VALUES (2, ''TestClient2'')');
  FDBConnection.ExecuteDirect('INSERT INTO PEDIDOS (PEDIDO_ID, CLIENT_ID, PEDIDO_VALOR) VALUES (1, 1, 150.00)');
  FDBConnection.ExecuteDirect('INSERT INTO PEDIDOS (PEDIDO_ID, CLIENT_ID, PEDIDO_VALOR) VALUES (2, 2, 80.00)');

  // Criar query fluida
  LQuery := FDBConnection.CreateQuery;
  LQuery.CommandText := 'SELECT CLIENTES.CLIENT_NAME, PEDIDOS.PEDIDO_VALOR ' +
                        'FROM CLIENTES INNER JOIN PEDIDOS ON CLIENTES.CLIENT_ID = PEDIDOS.CLIENT_ID ' +
                        'WHERE CLIENTES.CLIENT_NAME LIKE ''Test%'' AND PEDIDOS.PEDIDO_VALOR > 100.00';
  LDataSet := LQuery.ExecuteQuery;
  try
    LDataSet.Open;
    Assert.IsFalse(LDataSet.Eof, 'Result set is not empty');
    LValue := LDataSet.FieldByName('CLIENTES.CLIENT_NAME').AsVariant;
    Assert.AreEqual('TestClient1', LValue, 'Expected TestClient1 but got ' + LValue);
    Assert.AreEqual(Double(150.00), LDataSet.FieldByName('PEDIDOS.PEDIDO_VALOR').AsFloat,
                    'Expected 150.00 but got ' + FloatToStr(LDataSet.FieldByName('PEDIDOS.PEDIDO_VALOR').AsVariant));
    WriteLn(Format('TestFluentQuery: CLIENT_NAME=%s, PEDIDO_VALOR=%s',
                   [LValue, FloatToStr(LDataSet.FieldByName('PEDIDOS.PEDIDO_VALOR').AsFloat)]));
  finally
    LDataSet.Close;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMemoryDriverConnection);

end.

