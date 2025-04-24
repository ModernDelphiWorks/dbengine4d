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

{ @abstract(DBE Framework)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <https://www.isaquepinheiro.com.br>)
}

unit DBEngine.DriverADOTransaction;

interface

uses
  Classes,
  DB,
  ADODB,
  /// DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  // Classe de conexão concreta com dbExpress
  TDriverADOTransaction = class(TDriverTransaction)
  protected
    FConnection: TADOConnection;
  public
    constructor Create(const AConnection: TComponent); override;
    destructor Destroy; override;
    procedure StartTransaction; override;
    procedure Commit; override;
    procedure Rollback; override;
    function InTransaction: Boolean; override;
  end;

implementation

{ TDriverADOTransaction }

constructor TDriverADOTransaction.Create(const AConnection: TComponent);
begin
  FConnection := AConnection as TADOConnection;
end;

destructor TDriverADOTransaction.Destroy;
begin
  FConnection := nil;
  inherited;
end;

function TDriverADOTransaction.InTransaction: Boolean;
begin
  Result := FConnection.InTransaction;
end;

procedure TDriverADOTransaction.StartTransaction;
begin
  inherited;
  FConnection.BeginTrans;
end;

procedure TDriverADOTransaction.Commit;
begin
  inherited;
  FConnection.CommitTrans;
end;

procedure TDriverADOTransaction.Rollback;
begin
  inherited;
  FConnection.RollbackTrans;
end;

end.
