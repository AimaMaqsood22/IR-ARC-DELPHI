unit DbxDevartSQLServerMetaDataWriter;

{$IFNDEF CLR}
{$I Dbx.inc}
{$ENDIF}

interface

uses
  DBXCommonTable,
  DBXMetaDataWriter,
  DBXPlatform,
  SysUtils;

type
{$IFDEF VER17P}
  TDBXStringBuffer = TStringBuilder;
{$ENDIF}

  TDBXDevartMsSqlCustomMetaDataWriter = class(TDBXBaseMetaDataWriter)
  protected
    procedure MakeSqlDropSecondaryIndex(const Buffer: TDBXStringBuffer; const Index: TDBXTableRow); override;
  end;

  TDBXDevartMsSqlMetaDataWriter = class(TDBXDevartMsSqlCustomMetaDataWriter)
  public
    constructor Create;
    procedure Open; override;
  protected
    function GetSqlAutoIncrementKeyword: UnicodeString; override;
    function GetSqlAutoIncrementInserts: UnicodeString; override;
    function GetSqlRenameTable: UnicodeString; override;
    function IsCatalogsSupported: Boolean; override;
    function IsSchemasSupported: Boolean; override;
    function IsMultipleStatementsSupported: Boolean; override;
  end;

implementation

uses
  DBXMetaDataNames,
  DbxDevartSQLServerMetaDataReader;

procedure TDBXDevartMsSqlCustomMetaDataWriter.MakeSqlDropSecondaryIndex(const Buffer: TDBXStringBuffer; const Index: TDBXTableRow);
var
  Version: UnicodeString;
  Original: TDBXTableRow;
begin
  Version := FReader.Version;
  if Version >= '09.00.0000' then
    inherited MakeSqlDropSecondaryIndex(Buffer, Index)
  else 
  begin
    Original := Index.OriginalRow;
    Buffer.Append(TDBXSQL.Drop);
    Buffer.Append(TDBXSQL.Space);
    Buffer.Append(TDBXSQL.Index);
    Buffer.Append(TDBXSQL.Space);
    MakeSqlIdentifier(Buffer, Original.Value[TDBXIndexesIndex.TableName].GetWideString(NullString));
    Buffer.Append(TDBXSQL.Dot);
    MakeSqlIdentifier(Buffer, Original.Value[TDBXIndexesIndex.IndexName].GetWideString(NullString));
    Buffer.Append(TDBXSQL.Semicolon);
    Buffer.Append(TDBXSQL.Nl);
  end;
end;

constructor TDBXDevartMsSqlMetaDataWriter.Create;
begin
  inherited Create;
  Open;
end;

procedure TDBXDevartMsSqlMetaDataWriter.Open;
begin
  if FReader = nil then
    FReader := TDBXDevartMsSqlMetaDataReader.Create;
end;

function TDBXDevartMsSqlMetaDataWriter.GetSqlAutoIncrementKeyword: UnicodeString;
begin
  Result := 'IDENTITY';
end;

function TDBXDevartMsSqlMetaDataWriter.GetSqlAutoIncrementInserts: UnicodeString;
begin
  Result := 'IDENTITY_INSERT';
end;

function TDBXDevartMsSqlMetaDataWriter.GetSqlRenameTable: UnicodeString;
begin
  Result := 'EXEC sp_rename '':SCHEMA_NAME.:TABLE_NAME'', '':NEW_TABLE_NAME'', ''OBJECT''';
end;

function TDBXDevartMsSqlMetaDataWriter.IsCatalogsSupported: Boolean;
begin
  Result := True;
end;

function TDBXDevartMsSqlMetaDataWriter.IsSchemasSupported: Boolean;
begin
  Result := True;
end;

function TDBXDevartMsSqlMetaDataWriter.IsMultipleStatementsSupported: Boolean;
begin
  Result := True;
end;

end.
