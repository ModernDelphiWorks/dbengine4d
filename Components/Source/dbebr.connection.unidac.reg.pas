unit dbe.connection.unidac.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.unidac;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionUniDAC]);
end;

end.
