unit dbe.connection.firedac.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.firedac;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionFireDAC]);
end;

end.
