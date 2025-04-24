unit dbe.connection.nexusdb.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.nexusdb;

procedure register;

implementation

procedure register;
begin
  RegisterComponents('DBE', [TDBEConnectionNexusDB]);
end;

end.
