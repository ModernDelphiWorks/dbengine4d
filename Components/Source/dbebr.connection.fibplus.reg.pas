unit dbe.connection.fibplus.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.fibplus;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionFIBPlus]);
end;

end.
