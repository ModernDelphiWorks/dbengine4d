unit dbe.connection.ibobjects.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.ibobjects;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionIBObjects]);
end;

end.
