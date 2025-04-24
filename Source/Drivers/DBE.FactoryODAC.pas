{
  DBE Brasil é um Engine de Conexão simples e descomplicado for Delphi/Lazarus

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Versão 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos é permitido copiar e distribuir cópias deste documento de
       licença, mas mudá-lo não é permitido.

       Esta versão da GNU Lesser General Public License incorpora
       os termos e condições da versão 3 da GNU General Public License
       Licença, complementado pelas permissões adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{
  @abstract(DBE Framework)
  @created(25 julho 2017)
  @author(Isaque Pinheiro <https://www.isaquepinheiro.com.br>)
}

unit DBE.FactoryODAC;

interface

uses
  DB,
  Classes,
  SysUtils,
  Ora,
  // DBE
  DBE.FactoryConnection,
  DBE.FactoryInterfaces;

type

  TFactoryODAC = class(TFactoryConnection)
  public
    constructor Create(const AConnection: TOraSession;
      const ADriverName: TDriverName); overload;
    constructor Create(const AConnection: TOraSession;
      const ADriverName: TDriverName;
      const AMonitor: ICommandMonitor); overload;
    constructor Create(const AConnection: TOraSession;
      const ADriverName: TDriverName;
      const AMonitorCallback: TMonitorProc); overload;
    destructor Destroy; override;
  end;

implementation

uses
  dbe.driver.odac,
  dbe.driver.odac.transaction;


{ TFactoryODAC }

constructor TFactoryODAC.Create(const AConnection: TOraSession;
  const ADriverName: TDriverName);
begin
  FDriverTransaction := TDriverODACTransaction.Create(AConnection);
  FDriverConnection  := TDriverODAC.Create(AConnection,
                                           FDriverTransaction,
                                           ADriverName,
                                           FCommandMonitor,
                                           FMonitorCallback);
  FAutoTransaction := False;
end;

constructor TFactoryODAC.Create(const AConnection: TOraSession;
  const ADriverName: TDriverName; const AMonitor: ICommandMonitor);
begin
  Create(AConnection, ADriverName);
  FCommandMonitor := AMonitor;
end;

procedure TFactoryODAC.AddTransaction(const AKey: String;
  const ATransaction: TComponent);
begin
  if not (ATransaction is TOraSession) then
    raise Exception.Create('Invalid transaction type. Expected TOraSession.');

  inherited AddTransaction(AKey, ATransaction);
end;

constructor TFactoryODAC.Create(const AConnection: TUniConnection;
  const ADriverName: TDriverName; const AMonitorCallback: TMonitorProc);
begin
  Create(AConnection, ADriverName);
  FMonitorCallback := AMonitorCallback;
end;

destructor TFactoryODAC.Destroy;
begin
  FDriverConnection.Free;
  FDriverTransaction.Free;
  inherited;
end;

end.
