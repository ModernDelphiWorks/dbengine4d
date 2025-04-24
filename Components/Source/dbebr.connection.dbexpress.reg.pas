unit dbe.connection.dbexpress.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.dbexpress;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionDBExpress]);
end;

end.
