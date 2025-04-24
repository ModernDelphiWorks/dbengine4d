{
  DBE Brasil � um Engine de Conex�o simples e descomplicado for Delphi/Lazarus

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Vers�o 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos � permitido copiar e distribuir c�pias deste documento de
       licen�a, mas mud�-lo n�o � permitido.

       Esta vers�o da GNU Lesser General Public License incorpora
       os termos e condi��es da vers�o 3 da GNU General Public License
       Licen�a, complementado pelas permiss�es adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(DBE Framework)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <https://www.isaquepinheiro.com.br>)
}

unit DBEngine.FactoryWireMongoDB;

interface

uses
  DB,
  Classes,
  SysUtils,
  // DBE
  DBE.FactoryConnection,
  DBE.FactoryInterfaces;

type
  // F�brica de conex�o concreta com dbExpress
  TFactoryMongoWire = class(TFactoryConnection)
  public
    constructor Create(const AConnection: TComponent;
      const ADriverName: TDriverName); overload;
    constructor Create(const AConnection: TComponent;
      const ADriverName: TDriverName;
      const AMonitor: ICommandMonitor); overload;
    constructor Create(const AConnection: TComponent;
      const ADriverName: TDriverName;
      const AMonitorCallback: TMonitorProc); overload;
    destructor Destroy; override;
    procedure AddTransaction(const AKey: String; const ATransaction: TComponent); override;
  end;

implementation

uses
  dbe.driver.wire.mongodb,
  dbe.driver.wire.mongodb.transaction;

{ TFactoryMongoWire }

constructor TFactoryMongoWire.Create(AConnection: TComponent; ADriverName: TDriverName);
begin
  FDriverTransaction := TDriverMongoWireTransaction.Create(AConnection);
  FDriverConnection  := TDriverMongoWire.Create(AConnection,
                                                FDriverTransaction,
                                                ADriverName,
                                                FCommandMonitor,
                                                FMonitorCallback);
  FAutoTransaction := False;
end;

constructor TFactoryMongoWire.Create(const AConnection: TZConnection;
  const ADriverName: TDriverName; const AMonitorCallback: TMonitorProc);
begin
  Create(AConnection, ADriverName);
  FCommandMonitor := AMonitor;
end;

procedure TFactoryMongoWire.AddTransaction(const AKey: String;
  const ATransaction: TComponent);
begin
  if not (ATransaction is TComponent) then
    raise Exception.Create('Invalid transaction type. Expected TComponent.');

  inherited AddTransaction(AKey, ATransaction);
end;

constructor TFactoryMongoWire.Create(const AConnection: TComponent;
  const ADriverName: TDriverName; const AMonitorCallback: TMonitorProc);
begin
  Create(AConnection, ADriverName);
  FMonitorCallback := AMonitorCallback;
end;

destructor TFactoryMongoWire.Destroy;
begin
  FDriverConnection.Free;
  FDriverTransaction.Free;
  inherited;
end;

end.
