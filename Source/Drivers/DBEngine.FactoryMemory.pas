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

unit DBEngine.FactoryMemory;

interface

uses
  Classes,
  SysUtils,
  DBEngine.FactoryInterfaces,
  DBEngine.FactoryConnection,
  DBEngine.DriverMemory;

type
  TFactoryMemory = class(TFactoryConnection)
  public
    constructor Create(const AConnection: TComponent; const ADriverName: TDBEDriver); overload;
    constructor Create(const AConnection: TComponent; const ADriverName: TDBEDriver;
      const AMonitor: ICommandMonitor); overload;
    constructor Create(const AConnection: TComponent; const ADriverName: TDBEDriver;
      const AMonitorCallback: TMonitorProc); overload;
    destructor Destroy; override;
  end;

implementation

uses
  DBEngine.DriverMemoryTransaction;

constructor TFactoryMemory.Create(const AConnection: TComponent; const ADriverName: TDBEDriver);
begin
  FDriverTransaction := TDriverMemoryTransaction.Create(AConnection);
  FDriverConnection := TMemoryDriver.Create(AConnection,
                                            FDriverTransaction,
                                            ADriverName,
                                            FMonitorCallback);
end;

constructor TFactoryMemory.Create(const AConnection: TComponent;
  const ADriverName: TDBEDriver; const AMonitorCallback: TMonitorProc);
begin
  FMonitorCallback := AMonitorCallback;
  Create(AConnection, ADriverName);
end;

constructor TFactoryMemory.Create(const AConnection: TComponent;
  const ADriverName: TDBEDriver; const AMonitor: ICommandMonitor);
begin
  Create(AConnection, ADriverName);
  FCommandMonitor := AMonitor;
end;

destructor TFactoryMemory.Destroy;
begin
  if Assigned(FDriverConnection) then
    FDriverConnection.Free;
  if Assigned(FDriverTransaction) then
    FDriverTransaction.Free;
  inherited;
end;

end.
