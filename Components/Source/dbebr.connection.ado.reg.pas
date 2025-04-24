unit dbe.connection.ado.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.ado;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionADO]);
end;

end.
