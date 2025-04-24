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

unit DBEngine.DriverMemoryTransaction;

interface

uses
  DB,
  Classes,
  SysUtils,
  Generics.Collections,
  DBEngine.DriverConnection,
  DBEngine.FactoryInterfaces;

type
  TDriverMemoryTransaction = class(TDriverTransaction)
  private
    FConnection: TComponent;
    FActive: Boolean;
  public
    constructor Create(const AConnection: TComponent); override;
    destructor Destroy; override;
    procedure StartTransaction; override;
    procedure Commit; override;
    procedure Rollback; override;
    function InTransaction: Boolean; override;
  end;

implementation

{ TDriverMemoryTransaction }

constructor TDriverMemoryTransaction.Create(const AConnection: TComponent);
begin
  inherited Create(AConnection);
  FConnection := AConnection;
  FActive := False;
  FTransactionList.Add('DEFAULT', FConnection);
  FTransactionActive := FConnection;
end;

destructor TDriverMemoryTransaction.Destroy;
begin
  FConnection := nil;
  inherited;
end;

procedure TDriverMemoryTransaction.StartTransaction;
begin
  if FActive then
    raise Exception.Create('Transaction already active.');
  FActive := True;
end;

procedure TDriverMemoryTransaction.Commit;
begin
  if FActive then
    FActive := False;
end;

procedure TDriverMemoryTransaction.Rollback;
begin
  if FActive then
    FActive := False;
end;

function TDriverMemoryTransaction.InTransaction: Boolean;
begin
  if not Assigned(FTransactionActive) then
    raise Exception.Create('The active transaction is not defined.');
  Result := FActive;
end;

end.
