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

unit DBEngine.DriverFireDacTransaction;

interface

uses
  DB,
  Classes,
  SysUtils,
  Generics.Collections,
  FireDAC.Comp.Client,
  DBEngine.DriverConnection,
  DBEngine.FactoryInterfaces;

type
  TDriverFireDACTransaction = class(TDriverTransaction)
  private
    FConnection: TFDConnection;
    FTransaction: TFDTransaction;
  public
    constructor Create(const AConnection: TComponent); override;
    destructor Destroy; override;
    procedure StartTransaction; override;
    procedure Commit; override;
    procedure Rollback; override;
    function InTransaction: Boolean; override;
  end;

implementation

{ TDriverFireDACTransaction }

constructor TDriverFireDACTransaction.Create(const AConnection: TComponent);
begin
  inherited;
  FConnection := AConnection as TFDConnection;
  if FConnection.Transaction = nil then
  begin
    FTransaction := TFDTransaction.Create(nil);
    FTransaction.Connection := FConnection;
    FConnection.Transaction := FTransaction;
  end;
  FConnection.Transaction.Name := 'DEFAULT';
  FTransactionList.Add('DEFAULT', FConnection.Transaction);
  FTransactionActive := FConnection.Transaction;
end;

destructor TDriverFireDACTransaction.Destroy;
begin
  inherited;
  if Assigned(FTransaction) then
  begin
    FTransaction.Connection := nil;
    FTransaction.Free;
  end;
  FConnection := nil;
end;

procedure TDriverFireDACTransaction.StartTransaction;
begin
  (FTransactionActive as TFDTransaction).StartTransaction;
end;

procedure TDriverFireDACTransaction.Commit;
begin
  (FTransactionActive as TFDTransaction).Commit;
end;

procedure TDriverFireDACTransaction.Rollback;
begin
  (FTransactionActive as TFDTransaction).Rollback;
end;

function TDriverFireDACTransaction.InTransaction: Boolean;
begin
  if not Assigned(FTransactionActive) then
    raise Exception.Create('The active transaction is not defined. Please make sure to start a transaction before checking if it is in progress.');
  Result := (FTransactionActive as TFDTransaction).Active;
end;

end.

