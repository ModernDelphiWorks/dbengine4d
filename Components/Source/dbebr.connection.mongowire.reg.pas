unit dbe.connection.mongowire.reg;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  dbe.connection.mongowire;

procedure register;

implementation

{$R 'dbe.connection.mongowire.res' 'dbe.connection.mongowire.rc'}

procedure register;
begin
  RegisterComponents('DBE-NoSQL', [TDBEConnectionMongoWire]);
end;

end.
