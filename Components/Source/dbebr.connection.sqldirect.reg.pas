unit dbe.connection.sqldirect.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.sqldirect;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionSQLDirect]);
end;

end.
