unit dbe.connection.zeos.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.zeos;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionZeos]);
end;

end.
