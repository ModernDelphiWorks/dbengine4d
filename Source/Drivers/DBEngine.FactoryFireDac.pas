{
                          Apache License
                      Version 2.0, January 2004
                   http://www.apache.org/licenses/

       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

             http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.
}

{
  @abstract(DBEngine4D: Database Engine Framework for Delphi)
  @description(A flexible and modular database engine framework for Delphi applications)
  @created(03 Abr 2025)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @Discord(https://discord.gg/T2zJC8zX)
}

unit DBEngine.FactoryFireDac;

interface

uses
  DB,
  Classes,
  SysUtils,
  FireDAC.Comp.Client,
  DBEngine.FactoryConnection,
  DBEngine.FactoryInterfaces;

type
  TFactoryFireDAC = class(TFactoryConnection)
  public
    constructor Create(const AConnection: TFDConnection;
      const ADriver: TDBEngineDriver); overload;
    constructor Create(const AConnection: TFDConnection; const ADriver: TDBEngineDriver;
      const AMonitor: ICommandMonitor); overload;
    constructor Create(const AConnection: TFDConnection; const ADriver: TDBEngineDriver;
      const AMonitorCallback: TMonitorProc); overload;
    destructor Destroy; override;
    procedure AddTransaction(const AKey: String; const ATransaction: TComponent); override;
  end;

implementation

uses
  DBEngine.DriverFireDac,
  DBEngine.DriverFireDacTransaction;

{ TFactoryFireDAC }

constructor TFactoryFireDAC.Create(const AConnection: TFDConnection;
  const ADriver: TDBEngineDriver);
begin
  FDriverTransaction := TDriverFireDACTransaction.Create(AConnection);
  FDriverConnection  := TDriverFireDAC.Create(AConnection,
                                              FDriverTransaction,
                                              ADriver,
                                              FMonitorCallback);
  FAutoTransaction := False;
end;

constructor TFactoryFireDAC.Create(const AConnection: TFDConnection;
  const ADriver: TDBEngineDriver; const AMonitor: ICommandMonitor);
begin
  FCommandMonitor := AMonitor;
  Create(AConnection, ADriver);
end;

destructor TFactoryFireDAC.Destroy;
begin
  FDriverConnection.Free;
  FDriverTransaction.Free;
  inherited;
end;

procedure TFactoryFireDAC.AddTransaction(const AKey: String;
  const ATransaction: TComponent);
begin
  if not (ATransaction is TFDTransaction) then
    raise Exception.Create('Invalid transaction type. Expected TFDTransaction.');

  inherited AddTransaction(AKey, ATransaction);
end;

constructor TFactoryFireDAC.Create(const AConnection: TFDConnection;
  const ADriver: TDBEngineDriver; const AMonitorCallback: TMonitorProc);
begin
  FMonitorCallback := AMonitorCallback;
  Create(AConnection, ADriver);
end;

end.



