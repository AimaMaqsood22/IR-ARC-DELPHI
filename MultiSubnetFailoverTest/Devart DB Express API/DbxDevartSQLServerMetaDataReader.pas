unit DbxDevartSQLServerMetaDataReader;

{$IFNDEF CLR}
{$I Dbx.inc}
{$ENDIF}

interface

uses
  DBXCommon,
  DBXCommonTable,
  DBXMetaDataReader,
  DBXPlatform,
  DBXSqlScanner;

type
  TDBXDevartMsSqlCustomMetaDataReader = class(TDBXBaseMetaDataReader)
  public
    type
      TDBXMsSqlSynonymTableCursor = class(TDBXCustomMetaDataTable)
      public
        constructor Create(const Context: TDBXProviderContext; const Scanner: TDBXSqlScanner; const Columns: TDBXValueTypeArray; const Cursor: TDBXTable);
        destructor Destroy; override;
        function Next: Boolean; override;
      protected
        function FindStringSize(const Ordinal: Integer; const SourceColumns: TDBXValueTypeArray): Integer; override;
        function GetWritableValue(const Ordinal: Integer): TDBXWritableValue; override;
      private
        procedure ParseBaseObject;
      private
        FScanner: TDBXSqlScanner;
        FCatalog: UnicodeString;
        FSchema: UnicodeString;
        FTable: UnicodeString;
        FRow: TDBXSingleValueRow;
      end;

  public
    destructor Destroy; override;
    function FetchSynonyms(const Catalog: UnicodeString; const Schema: UnicodeString; const Synonym: UnicodeString): TDBXTable; override;
  protected
    procedure SetContext(const Context: TDBXProviderContext); override;
  {$IFNDEF VER12}
    function IsSPReturnCodeSupported: Boolean; override;
  {$ENDIF}
  private
    function CreateScanner: TDBXSqlScanner;
  private
    FScanner: TDBXSqlScanner;
    FParamPrefix: boolean;
    FUseQuoteChar: Boolean;
  end;

  TDBXDevartMsSqlMetaDataReader = class(TDBXDevartMsSqlCustomMetaDataReader)
  private
    function NormalizeName(const Value: string): string;
  public
    function FetchProcedureParameters(const Catalog: UnicodeString; const Schema: UnicodeString; const &Procedure: UnicodeString; const Parameter: UnicodeString): TDBXTable; override;
    function FetchPackages(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString): TDBXTable; override;
    function FetchPackageProcedures(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString; const ProcedureName: UnicodeString; const ProcedureType: UnicodeString): TDBXTable; override;
    function FetchPackageProcedureParameters(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString; const ProcedureName: UnicodeString; const ParameterName: UnicodeString): TDBXTable; override;
    function FetchPackageSources(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString): TDBXTable; override;
  protected
  {$IFDEF VER17P}
  {$IFNDEF CLR}
    function AreCatalogsSupported: Boolean; override;
    function AreSchemasSupported: Boolean; override;
  {$ENDIF}
  {$ENDIF}
    function GetProductName: UnicodeString; override;
    function IsQuotedIdentifiersSupported: Boolean; override;
    function GetSqlIdentifierQuoteChar: UnicodeString; override;
    function GetSqlIdentifierQuotePrefix: UnicodeString; override;
    function GetSqlIdentifierQuoteSuffix: UnicodeString; override;
    function GetTableType: UnicodeString; override;
    function GetViewType: UnicodeString; override;
    function GetSystemTableType: UnicodeString; override;
    function GetSystemViewType: UnicodeString; override;
    function GetSynonymType: UnicodeString; override;
    function IsLowerCaseIdentifiersSupported: Boolean; override;
  {$IFDEF VER15P}
    function IsParameterMetadataSupported: Boolean; override;
  {$ELSE}
    function IsSetRowSizeSupported: Boolean; override;
  {$ENDIF}
    function GetSqlForCatalogs: UnicodeString; override;
    function GetSqlForSchemas: UnicodeString; override;
    function GetSqlForTables: UnicodeString; override;
    function GetSqlForViews: UnicodeString; override;
    function GetSqlForColumns: UnicodeString; override;
    function GetSqlForColumnConstraints: UnicodeString; override;
    function GetSqlForIndexes: UnicodeString; override;
    function GetSqlForIndexColumns: UnicodeString; override;
    function GetSqlForForeignKeys: UnicodeString; override;
    function GetSqlForForeignKeyColumns: UnicodeString; override;
    function GetSqlForSynonyms: UnicodeString; override;
    function GetSqlForProcedures: UnicodeString; override;
    function GetSqlForProcedureSources: UnicodeString; override;
    function GetSqlForProcedureParameters: UnicodeString; override;
    function GetSqlForSysProcedureParameters(const SchemaPrefix: string): UnicodeString;
    function GetSqlForUsers: UnicodeString; override;
    function GetSqlForRoles: UnicodeString; override;
    function GetDataTypeDescriptions: TDBXDataTypeDescriptionArray; override;
    function GetReservedWords: TDBXStringArray; override;
  end;

implementation

uses
  DBXMetaDataNames,
  SysUtils;

{$IFDEF VER18P}
function StringIsNil(const Str: UnicodeString): Boolean;
begin
  Result := {$IFDEF CLR}(TObject(Str) = nil) or{$ENDIF} (Str = NullString);
end;
{$ENDIF}

destructor TDBXDevartMsSqlCustomMetaDataReader.Destroy;
begin
  FreeAndNil(FScanner);
  inherited Destroy;
end;

procedure TDBXDevartMsSqlCustomMetaDataReader.SetContext(const Context: TDBXProviderContext);
begin
  inherited SetContext(Context);
  FParamPrefix := (LowerCase(Context.GetVendorProperty('ParamPrefix')) = 'true');
  FUseQuoteChar := {$IFDEF CLR}True{$ELSE}UpperCase(Trim(Context.GetVendorProperty('UseQuoteChar'))) = 'TRUE'{$ENDIF};
end;

function TDBXDevartMsSqlCustomMetaDataReader.FetchSynonyms(const Catalog: UnicodeString; const Schema: UnicodeString; const Synonym: UnicodeString): TDBXTable;
var
  ParameterNames: TDBXStringArray;
  ParameterValues: TDBXStringArray;
  Cursor: TDBXTable;
  Columns: TDBXValueTypeArray;
begin
  SetLength(ParameterNames,3);
  ParameterNames[0] := TDBXParameterName.CatalogName;
  ParameterNames[1] := TDBXParameterName.SchemaName;
  ParameterNames[2] := TDBXParameterName.SynonymName;
  SetLength(ParameterValues,3);
  ParameterValues[0] := Catalog;
  ParameterValues[1] := Schema;
  ParameterValues[2] := Synonym;
  Cursor := Context.ExecuteQuery(SqlForSynonyms, ParameterNames, ParameterValues);
  Columns := TDBXMetaDataCollectionColumns.CreateSynonymsColumns;
  Result := TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.Create(Context, CreateScanner, Columns, Cursor);
end;

function TDBXDevartMsSqlCustomMetaDataReader.CreateScanner: TDBXSqlScanner;
begin
  if FScanner = nil then
    FScanner := TDBXSqlScanner.Create(SqlIdentifierQuoteChar, SqlIdentifierQuotePrefix, SqlIdentifierQuoteSuffix);
  Result := FScanner;
end;

{$IFNDEF VER12}
function TDBXDevartMsSqlCustomMetaDataReader.IsSPReturnCodeSupported: Boolean;
begin
  Result := True;
end;
{$ENDIF}

constructor TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.Create(const Context: TDBXProviderContext; const Scanner: TDBXSqlScanner; const Columns: TDBXValueTypeArray; const Cursor: TDBXTable);
begin
  inherited Create(Context, TDBXMetaDataCollectionName.Synonyms, Columns, Cursor);
  self.FScanner := Scanner;
  FRow := TDBXSingleValueRow.Create;
  FRow.Columns := CopyColumns;
end;

destructor TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.Destroy;
begin
  FreeAndNil(FRow);
  inherited Destroy;
end;

function TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.FindStringSize(const Ordinal: Integer; const SourceColumns: TDBXValueTypeArray): Integer;
var
  UseOrdinal: Integer;
begin
  UseOrdinal := Ordinal;
  if Ordinal >= 3 then
    UseOrdinal := Ordinal - 3;
  Result := inherited FindStringSize(UseOrdinal, SourceColumns);
end;

function TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.Next: Boolean;
var
  ReturnValue: Boolean;
begin
  FCatalog := NullString;
  FSchema := NullString;
  FTable := NullString;
  ReturnValue := inherited Next;
  if ReturnValue then
  begin
    ParseBaseObject;
    if StringIsNil(FCatalog) then
      FRow.Value[3].SetNull
    else 
      FRow.Value[3].AsString := FCatalog;
    if StringIsNil(FSchema) then
      FRow.Value[4].SetNull
    else 
      FRow.Value[4].AsString := FSchema;
    if StringIsNil(FTable) then
      FRow.Value[5].SetNull
    else 
      FRow.Value[5].AsString := FTable;
  end;
  Result := ReturnValue;
end;

function TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.GetWritableValue(const Ordinal: Integer): TDBXWritableValue;
begin
  case Ordinal of
    3, 4, 5:
      Exit(FRow.Value[Ordinal]);
  end;
  Result := inherited GetWritableValue(Ordinal);
end;

procedure TDBXDevartMsSqlCustomMetaDataReader.TDBXMsSqlSynonymTableCursor.ParseBaseObject;
var
  Pattern: UnicodeString;
  Token: Integer;
begin
  Pattern := inherited GetWritableValue(3).AsString;
  FScanner.Init(Pattern);
  Token := FScanner.NextToken;
  while Token = TDBXSqlScanner.TokenId do
  begin
    FCatalog := FSchema;
    FSchema := FTable;
    FTable := FScanner.Id;
    Token := FScanner.NextToken;
    if (Token = TDBXSqlScanner.TokenSymbol) and (FScanner.Symbol = '.') then
      Token := FScanner.NextToken;
  end;
  if StringIsNil(FSchema) then
    FSchema := self.Value[1].AsString;
  if StringIsNil(FCatalog) then
    FCatalog := self.Value[0].AsString;
end;

{$IFDEF VER17P}
{$IFNDEF CLR}
function TDBXDevartMsSqlMetaDataReader.AreCatalogsSupported: Boolean;
begin
  Result := True;
end;

function TDBXDevartMsSqlMetaDataReader.AreSchemasSupported: Boolean;
begin
  Result := True;
end;
{$ENDIF}
{$ENDIF}

function TDBXDevartMsSqlMetaDataReader.GetProductName: UnicodeString;
begin
  Result := 'DevartSQLServer';
end;

function TDBXDevartMsSqlMetaDataReader.IsQuotedIdentifiersSupported: Boolean;
begin
  Result := FUseQuoteChar;
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlIdentifierQuoteChar: UnicodeString;
begin
  if FUseQuoteChar then
    Result := '"'
  else
    Result := '';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlIdentifierQuotePrefix: UnicodeString;
begin
  Result := '[';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlIdentifierQuoteSuffix: UnicodeString;
begin
  Result := ']';
end;

function TDBXDevartMsSqlMetaDataReader.GetTableType: UnicodeString;
begin
  Result := 'U';
end;

function TDBXDevartMsSqlMetaDataReader.GetViewType: UnicodeString;
begin
  Result := 'V';
end;

function TDBXDevartMsSqlMetaDataReader.GetSystemTableType: UnicodeString;
begin
  Result := 'S';
end;

function TDBXDevartMsSqlMetaDataReader.GetSystemViewType: UnicodeString;
begin
  Result := 'V';
end;

function TDBXDevartMsSqlMetaDataReader.GetSynonymType: UnicodeString;
begin
  Result := 'SN';
end;

function TDBXDevartMsSqlMetaDataReader.IsLowerCaseIdentifiersSupported: Boolean;
begin
  Result := True;
end;

{$IFDEF VER15P}
function TDBXDevartMsSqlMetaDataReader.IsParameterMetadataSupported: Boolean;
begin
  Result := True;
end;
{$ELSE}
function TDBXDevartMsSqlMetaDataReader.IsSetRowSizeSupported: Boolean;
begin
  Result := True;
end;
{$ENDIF}

function TDBXDevartMsSqlMetaDataReader.GetSqlForCatalogs: UnicodeString;
var
  IsSQLAzureEdition: boolean;
begin
  IsSQLAzureEdition := (LowerCase(Context.GetVendorProperty('IsSQLAzureEdition')) = 'true');
  if IsSQLAzureEdition then
    Result := 'SELECT name FROM sysdatabases'
  else
    Result := 'SELECT name FROM master..sysdatabases';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForSchemas: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DISTINCT DB_NAME(), SCHEMA_NAME(schema_id) ' +
              'FROM  sys.objects ' +
              'WHERE ' +
              '  type IN (''U'', ''V'', ''S'', ''P'', ''FN'', ''IF'', ''TF'') ' +
              'ORDER BY 1,2'
  else
    Result := 'SELECT DISTINCT DB_NAME(), USER_NAME(uid) ' +
              'FROM  dbo.sysobjects ' +
              'WHERE ' +
              '  type IN (''U'', ''V'', ''S'', ''P'', ''FN'', ''IF'', ''TF'') ' +
              'ORDER BY 1,2';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForTables: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(a.schema_id), a.name, ' +
              'CASE WHEN a.type=''U'' THEN ''TABLE'' WHEN s.type=''V'' THEN ''SYSTEM VIEW'' WHEN a.type=''V'' THEN ''VIEW'' WHEN a.type=''S'' THEN ''SYSTEM TABLE'' WHEN a.type=''SN'' THEN ''SYNONYM'' END ' +
              'FROM  sys.all_objects a LEFT OUTER JOIN sys.system_objects s ON a.object_id=s.object_id ' +
              'WHERE ' +
              '  (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(a.schema_id) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (a.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (a.type = :TABLES OR a.type = :VIEWS OR a.type = :SYSTEM_TABLES OR s.type = :SYSTEM_VIEWS OR a.type = :SYNONYMS) ' +
              'ORDER BY 1,2,3'
  else
    Result := 'SELECT DB_NAME(), USER_NAME(uid), name, ' +
              'CASE type WHEN ''U'' THEN ''TABLE'' WHEN ''V'' THEN ''VIEW'' WHEN ''S'' THEN ''SYSTEM TABLE'' WHEN ''SN'' THEN ''SYNONYM'' END ' +
              'FROM  dbo.sysobjects ' +
              'WHERE ' +
              '  (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (type = :TABLES OR type = :VIEWS OR type = :SYSTEM_TABLES OR type = :SYNONYMS) ' +
              'ORDER BY 1,2,3';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForViews: UnicodeString;
begin
  Result := 'SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, VIEW_DEFINITION ' +
            'FROM INFORMATION_SCHEMA.VIEWS ' +
            'WHERE ' +
            '  (TABLE_CATALOG = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
            '  AND (TABLE_SCHEMA = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
            '  AND (TABLE_NAME = :VIEW_NAME OR (:VIEW_NAME IS NULL)) ' +
            'ORDER BY 1,2,3';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForColumns: UnicodeString;
var
  IsSQLAzureEdition: boolean;
  CurrentVersion: UnicodeString;
begin
  IsSQLAzureEdition := (LowerCase(Context.GetVendorProperty('IsSQLAzureEdition')) = 'true');
  CurrentVersion := Version;

  if IsSQLAzureEdition then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(O.uid), O.name, C.name, T.name, ' +
              'CONVERT(INT,C.prec), CONVERT(INT,C.scale), CONVERT(INT,C.colid), NULL, ' +
              'CONVERT(BIT, C.isnullable), CONVERT(BIT, COLUMNPROPERTY(O.id, C.name, ''ISIDENTITY'')), NULL ' +
              'FROM sysobjects O INNER JOIN syscolumns C ON O.id=C.id ' +
              ' INNER JOIN systypes T ON C.xusertype = T.xusertype ' +
              'WHERE ' +
              '  OBJECTPROPERTY(O.id,''IsView'')+OBJECTPROPERTY(O.id,''IsUserTable'') > 0 ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,C.colid'
  else
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(O.uid), O.name, C.name, T.name, ' +
              'CONVERT(INT,C.prec), CONVERT(INT,C.scale), CONVERT(INT,C.colid), ' +
              'CASE WHEN COM.text LIKE ''((%))'' THEN SUBSTRING(COM.text,3,LEN(COM.text)-4) WHEN COM.text LIKE ''(''''%'''')'' ' +
              ' THEN SUBSTRING(COM.text,2,LEN(COM.text)-2) ELSE COM.text END AS DEFAULT_VALUE, ' +
              'CONVERT(BIT, C.isnullable), CONVERT(BIT, COLUMNPROPERTY(O.id, C.name, ''ISIDENTITY'')), NULL ' +
              'FROM sysobjects O INNER JOIN syscolumns C ON O.id=C.id ' +
              ' INNER JOIN systypes T ON C.xusertype = T.xusertype ' +
              ' LEFT OUTER JOIN syscomments COM ON CDEFAULT=COM.id ' +
              'WHERE ' +
              '  OBJECTPROPERTY(O.id,''IsView'')+OBJECTPROPERTY(O.id,''IsUserTable'') > 0 ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,C.colid'
  else
    Result := 'SELECT DB_NAME(), USER_NAME(O.uid), O.name, C.name, T.name, ' +
              'CONVERT(INT,C.prec), CONVERT(INT,C.scale), CONVERT(INT,C.colid), '+
              'CASE WHEN COM.text LIKE ''(%)'' THEN SUBSTRING(COM.text,2,LEN(COM.text)-2) WHEN COM.text LIKE ''(''''%'''')'' ' +
              ' THEN SUBSTRING(COM.text,2,LEN(COM.text)-2) ELSE COM.text END AS DEFAULT_VALUE, ' +
              'CONVERT(BIT, C.isnullable), CONVERT(BIT, COLUMNPROPERTY(O.id, C.name, ''ISIDENTITY'')), NULL ' +
              'FROM sysobjects O INNER JOIN syscolumns C ON O.id=C.id ' +
              ' INNER JOIN systypes T ON C.xusertype = T.xusertype ' +
              ' LEFT OUTER JOIN syscomments COM ON CDEFAULT=COM.id ' +
              'WHERE ' +
              '  OBJECTPROPERTY(O.id,''IsView'')+OBJECTPROPERTY(O.id,''IsUserTable'') > 0 ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,C.colid';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForColumnConstraints: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(T.uid), T.name, CON.name AS CONSTRAINT_NAME, ' +
              'COL.name AS COLUMN_NAME ' +
              'FROM sysobjects T, syscolumns COL, sysobjects CON ' +
              'WHERE ' +
              '  T.id=CON.parent_obj AND CON.id=COL.cdefault ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(T.uid)=:SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (T.name=:TABLE_NAME OR (:TABLE_NAME IS NULL))'
  else
    Result := 'SELECT DB_NAME(), USER_NAME(T.uid), T.name, CON.name AS CONSTRAINT_NAME, ' +
              'COL.name AS COLUMN_NAME ' +
              'FROM sysobjects T, syscolumns COL, sysobjects CON ' +
              'WHERE ' +
              '  T.id=CON.parent_obj AND CON.id=COL.cdefault ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(T.uid)=:SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (T.name=:TABLE_NAME OR (:TABLE_NAME IS NULL))';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForIndexes: UnicodeString;
var
  IsSQLAzureEdition: boolean;
  CurrentVersion: UnicodeString;
begin
  IsSQLAzureEdition := (LowerCase(Context.GetVendorProperty('IsSQLAzureEdition')) = 'true');
  CurrentVersion := Version;

  if CurrentVersion <= '05.00.0000' then
    Result := 'SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, INDEX_NAME, ' +
              'CASE [UNIQUE] WHEN 1 THEN INDEX_NAME ELSE NULL END, ' +
              'CONVERT(BIT, [PRIMARY_KEY]), ' +
              'CONVERT(BIT, [UNIQUE]), ' +
              'CONVERT(BIT, 1) ' +
              'FROM INFORMATION_SCHEMA.INDEXES ' +
              'WHERE ' +
              '  (TABLE_NAME = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY INDEX_NAME, ORDINAL_POSITION'
  else
  if IsSQLAzureEdition then
    Result := 'SELECT DISTINCT DB_NAME(), SCHEMA_NAME(O.uid), O.name, I.name, ' +
              'CASE WHEN INDEXPROPERTY(I.object_id, I.name,  ''IsUnique'') > 0 THEN I.name ELSE NULL END, ' +
              'CONVERT(BIT, COALESCE(OBJECTPROPERTY(object_id(I.name), ''IsPrimaryKey''), 0)), ' +
              'CONVERT(BIT, COALESCE(INDEXPROPERTY(I.object_id, I.name,  ''IsUnique''), 0)), ' +
              'CONVERT(BIT, 1) ' +
              'FROM sysobjects O, sys.indexes I, sys.index_columns IC ' +
              'WHERE ' +
              '  O.type IN (''U'') AND I.object_id = O.id AND O.id = IC.object_id AND I.index_id = IC.index_id ' +
              '  AND (DB_NAME() = :CATALOG_NAME or (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4'
  else
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DISTINCT DB_NAME(), SCHEMA_NAME(O.uid), O.name, I.name, ' +
              'CASE WHEN INDEXPROPERTY(I.id, I.name,  ''IsUnique'') > 0 THEN I.name ELSE NULL END, ' +
              'CONVERT(BIT, COALESCE(OBJECTPROPERTY(object_id(I.name), ''IsPrimaryKey''), 0)), ' +
              'CONVERT(BIT, COALESCE(INDEXPROPERTY(I.id, I.name,  ''IsUnique''), 0)), ' +
              'CONVERT(BIT, 1) ' +
              'FROM sysobjects O, sysindexes I, sysindexkeys IK ' +
              'WHERE ' +
              '  O.type IN (''U'') AND I.id = O.id AND O.id = IK.id AND I.indid = IK.indid ' +
              '  AND IK.keyno <= I.keycnt ' +
              '  AND (DB_NAME() = :CATALOG_NAME or (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4'
  else
    Result := 'SELECT DISTINCT DB_NAME(), USER_NAME(O.uid), O.name, I.name, ' +
              'CASE WHEN INDEXPROPERTY(I.id, I.name,  ''IsUnique'') > 0 THEN I.name ELSE NULL END, ' +
              'CONVERT(BIT, COALESCE(OBJECTPROPERTY(object_id(I.name), ''IsPrimaryKey''), 0)), ' +
              'CONVERT(BIT, COALESCE(INDEXPROPERTY(I.id, I.name,  ''IsUnique''), 0)), ' +
              'CONVERT(BIT, 1) ' +
              'FROM sysobjects O, sysindexes I, sysindexkeys IK ' +
              'WHERE ' +
              '  O.type IN (''U'') AND I.id = O.id AND O.id = IK.id AND I.indid = IK.indid ' +
              '  AND IK.keyno <= I.keycnt  AND I.status & 0x800000 = 0 ' +
              '  AND (DB_NAME() = :CATALOG_NAME or (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForIndexColumns: UnicodeString;
var
  IsSQLAzureEdition: boolean;
  CurrentVersion: UnicodeString;
begin
  IsSQLAzureEdition := (LowerCase(Context.GetVendorProperty('IsSQLAzureEdition')) = 'true');
  CurrentVersion := Version;

  if CurrentVersion <= '05.00.0000' then
    Result := 'SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, INDEX_NAME, ' +
              'COLUMN_NAME, ORDINAL_POSITION, ' +
              'CONVERT(BIT, 1) ' +
              'FROM INFORMATION_SCHEMA.INDEXES ' +
              'WHERE ' +
              '  (TABLE_NAME = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY INDEX_NAME, ORDINAL_POSITION'
  else
  if IsSQLAzureEdition then
    Result := 'SELECT DISTINCT DB_NAME(), SCHEMA_NAME(O.uid), O.name, I.name, C.name, ' +
              'CONVERT(INT, IC.key_ordinal), ' +
              'CONVERT(BIT, 1 - IC.is_descending_key) ' +
              'FROM sysobjects O, sys.indexes I, sys.index_columns IC, syscolumns C ' +
              'WHERE ' +
              '  O.type IN (''U'') AND I.object_id = O.id AND O.id = IC.object_id AND O.id = C.id ' +
              '  AND C.colid = IC.column_id AND I.index_id = IC.index_id ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (I.name = :INDEX_NAME OR (:INDEX_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4,6'
  else
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DISTINCT DB_NAME(), SCHEMA_NAME(O.uid), O.name, I.name, C.name, ' +
              'CONVERT(INT, IK.keyno), ' +
              'CONVERT(BIT, 1 - INDEXKEY_PROPERTY(O.id, I.indid, IK.keyno, ''IsDescending'')) ' +
              'FROM sysobjects O, sysindexes I, sysindexkeys IK, syscolumns C ' +
              'WHERE ' +
              '  O.type IN (''U'') AND I.id = O.id AND O.id = IK.id AND O.id = C.id ' +
              '  AND C.colid = IK.colid AND I.indid = IK.indid AND IK.keyno <= I.keycnt ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (I.name = :INDEX_NAME OR (:INDEX_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4,6'
  else
    Result := 'SELECT DISTINCT DB_NAME(), USER_NAME(O.uid), O.name, I.name, C.name, ' +
              'CONVERT(INT, IK.keyno), ' +
              'CONVERT(BIT, 1 - INDEXKEY_PROPERTY(O.id, I.indid, IK.keyno, ''IsDescending'')) ' +
              'FROM sysobjects O, sysindexes I, sysindexkeys IK, syscolumns C ' +
              'WHERE ' +
              '  O.type IN (''U'') AND I.id = O.id AND O.id = IK.id AND O.id = C.id ' +
              '  AND C.colid = IK.colid AND I.indid = IK.indid AND IK.keyno <= I.keycnt ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(O.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (O.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (I.name = :INDEX_NAME OR (:INDEX_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4,6';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForForeignKeys: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(FT.schema_id), FT.name, FK.name ' +
              'FROM sys.foreign_keys FK, sys.tables FT ' +
              'WHERE ' +
              '  FK.parent_object_id = FT.object_id ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(FT.schema_id) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (FT.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4'
  else
    Result := 'SELECT DB_NAME(), USER_NAME(FT.uid), FT.name, FK.name ' +
              'FROM sysreferences R, sysobjects FK, sysobjects FT ' +
              'WHERE ' +
              '  R.fkeyid=FT.id AND R.constid=FK.id ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(FT.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (FT.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              'ORDER BY 1,2,3,4';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForForeignKeyColumns: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(FT.schema_id), FT.name, FK.name, FC.name, ' +
              'DB_NAME(), SCHEMA_NAME(PT.schema_id), PT.name, I.name, PC.name, FKC.constraint_column_id ' +
              'FROM sys.foreign_keys FK, sys.foreign_key_columns FKC, sys.tables PT, sys.tables FT, sys.columns PC, sys.columns FC, sys.indexes I ' +
              'WHERE ' +
              '  FK.parent_object_id = FT.object_id ' +
              '  AND FK.referenced_object_id = PT.object_id ' +
              '  AND FKC.constraint_object_id = FK.object_id ' +
              '  AND FKC.referenced_column_id = PC.column_id ' +
              '  AND FKC.parent_object_id = FT.object_id ' +
              '  AND FKC.parent_column_id = FC.column_id ' +
              '  AND PC.object_id = PT.object_id ' +
              '  AND FC.object_id = FT.object_id ' +
              '  AND PC.object_id = I.object_id ' +
              '  AND FK.key_index_id = I.index_id ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(FT.schema_id) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (FT.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (FK.name = :FOREIGN_KEY_NAME OR (:FOREIGN_KEY_NAME IS NULL)) ' +
              '  AND (DB_NAME() = :PRIMARY_CATALOG_NAME OR (:PRIMARY_CATALOG_NAME IS NULL)) ' +
              '  AND (SCHEMA_NAME(PT.schema_id) = :PRIMARY_SCHEMA_NAME OR (:PRIMARY_SCHEMA_NAME IS NULL)) ' +
              '  AND (PT.name = :PRIMARY_TABLE_NAME OR (:PRIMARY_TABLE_NAME IS NULL)) ' +
              '  AND (I.name = :PRIMARY_KEY_NAME OR (:PRIMARY_KEY_NAME IS NULL)) ' +
              'ORDER BY 1, 2, 3, 4, FKC.constraint_column_id'
  else 
    Result := 'SELECT DB_NAME(), USER_NAME(FT.uid), FT.name, FK.name, FC.name, ' +
              'DB_NAME(), USER_NAME(PT.uid), PT.name, I.name, PC.name, F.keyno ' +
              'FROM sysforeignkeys F, sysobjects FK, sysobjects FT, syscolumns FC, sysobjects PT, syscolumns PC, sysreferences R, sysindexes I ' +
              'WHERE ' +
              '  F.constid=FK.id AND F.fkeyid=FT.id AND F.rkeyid=PT.id ' +
              '  AND F.fkeyid=FC.id AND F.fkey=FC.colid AND F.rkeyid=PC.id AND F.rkey=PC.colid ' +
              '  AND R.constid=F.constid AND F.rkeyid=I.id AND R.rkeyindid=I.indid ' +
              '  AND (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(FT.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (FT.name = :TABLE_NAME OR (:TABLE_NAME IS NULL)) ' +
              '  AND (FK.name = :FOREIGN_KEY_NAME OR (:FOREIGN_KEY_NAME IS NULL)) ' +
              '  AND (DB_NAME() = :PRIMARY_CATALOG_NAME OR (:PRIMARY_CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(PT.uid) = :PRIMARY_SCHEMA_NAME OR (:PRIMARY_SCHEMA_NAME IS NULL)) ' +
              '  AND (PT.name = :PRIMARY_TABLE_NAME OR (:PRIMARY_TABLE_NAME IS NULL)) ' +
              '  AND (I.name = :PRIMARY_KEY_NAME OR (:PRIMARY_KEY_NAME IS NULL)) ' +
              'ORDER BY 1, 2, 3, 4, F.keyno';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForSynonyms: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT DB_NAME(), SCHEMA_NAME(schema_id), name, base_object_name ' +
              'FROM sys.synonyms ' +
              'WHERE ' +
              '  (DB_NAME() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
              '  AND (USER_NAME(object_id) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (name = :SYNONYM_NAME OR (:SYNONYM_NAME IS NULL)) ' +
              'ORDER BY 1, 2, 3'
  else
    Result := 'SELECT NULL, NULL, NULL, NULL ' +
              'FROM sysobjects ' +
              'WHERE ' +
              '  (:CATALOG_NAME IS NULL) AND ' +
              '  (:SCHEMA_NAME IS NULL) AND ' +
              '  (:SYNONYM_NAME IS NULL)';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForProcedures: UnicodeString;
begin
  Result := 'SELECT SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_TYPE ' +
            'FROM INFORMATION_SCHEMA.ROUTINES ' +
            'WHERE ' +
            '  (SPECIFIC_CATALOG = :CATALOG_NAME or (:CATALOG_NAME IS NULL)) ' +
            '  AND (SPECIFIC_SCHEMA = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
            '  AND (SPECIFIC_NAME = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ' +
            '  AND (ROUTINE_TYPE = :PROCEDURE_TYPE OR (:PROCEDURE_TYPE IS NULL)) ' +
            'ORDER BY ROUTINE_CATALOG,ROUTINE_SCHEMA,ROUTINE_NAME';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForProcedureSources: UnicodeString;
var
  CurrentVersion: UnicodeString;
begin
  CurrentVersion := Version;
  if CurrentVersion >= '09.00.0000' then
    Result := 'SELECT SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_TYPE, ' +
              'CASE WHEN LEN(ROUTINE_DEFINITION) > 4000 THEN LEFT(ROUTINE_DEFINITION,4000)+'' ...'' ELSE ROUTINE_DEFINITION END, ' +
              'EXTERNAL_NAME ' +
              'FROM INFORMATION_SCHEMA.ROUTINES ' +
              'WHERE '  +
              '  (SPECIFIC_CATALOG = :CATALOG_NAME or (:CATALOG_NAME IS NULL)) ' +
              '  AND (SPECIFIC_SCHEMA = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (SPECIFIC_NAME = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ' +
              'ORDER BY ROUTINE_CATALOG,ROUTINE_SCHEMA,ROUTINE_NAME'
  else 
    Result := 'SELECT SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ROUTINE_TYPE, ' +
              'CASE WHEN LEN(ROUTINE_DEFINITION) > 2950 THEN LEFT(ROUTINE_DEFINITION,2950)+'' ...'' ELSE ROUTINE_DEFINITION END, ' +
              'EXTERNAL_NAME ' +
              'FROM INFORMATION_SCHEMA.ROUTINES ' +
              'WHERE ' +
              '  (SPECIFIC_CATALOG = :CATALOG_NAME or (:CATALOG_NAME IS NULL)) ' +
              '  AND (SPECIFIC_SCHEMA = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
              '  AND (SPECIFIC_NAME = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ' +
              'ORDER BY ROUTINE_CATALOG,ROUTINE_SCHEMA,ROUTINE_NAME';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForProcedureParameters: UnicodeString;
var
  PrefixStr: string;
begin
  if FParamPrefix then
    PrefixStr := '''@'' + '
  else
    PrefixStr := '';

  Result := 'SELECT SPECIFIC_CATALOG, SPECIFIC_SCHEMA, SPECIFIC_NAME, ' +
            PrefixStr + 'CAST(SUBSTRING(PARAMETER_NAME, 2, 1000) AS VARCHAR(128)) AS PARAMETER_NAME, ' +
            'CASE WHEN IS_RESULT=''YES'' THEN ''RESULT'' ELSE PARAMETER_MODE END, DATA_TYPE, ' +
            'CASE WHEN DATA_TYPE = ''timestamp'' THEN 8 ELSE COALESCE(CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION) END, ' +
            'NUMERIC_SCALE, ORDINAL_POSITION, CONVERT(BIT,1) ' +
            'FROM INFORMATION_SCHEMA.PARAMETERS ' +
            'WHERE ' +
            '  (SPECIFIC_CATALOG = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
            '  AND (SPECIFIC_SCHEMA = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
            '  AND (SPECIFIC_NAME = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ' +
            '  AND (PARAMETER_NAME = :PARAMETER_NAME OR (:PARAMETER_NAME IS NULL)) ' +
            'UNION ALL ' +
            'SELECT TOP 1 '''', '''', '''', ' +
            PrefixStr + '''RETURN_VALUE'', ''RESULT'', ''int'', 10, 0, 0, CONVERT(BIT,1) ' +
            'FROM INFORMATION_SCHEMA.PARAMETERS ' +
            'ORDER BY 3,9';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForSysProcedureParameters(const SchemaPrefix: string): UnicodeString;
var
  PrefixStr, ProcName: string;
begin
  if FParamPrefix then
    PrefixStr := '''@'' + '
  else
    PrefixStr := '';

  if Version >= '09.00.0000' then
    ProcName := 'schema_name'
  else
    ProcName := 'user_name';

  Result := Format('SELECT  ' +
            '  CAST(db_name() AS VARCHAR(128)) AS SPECIFIC_CATALOG, ' +
            '  CAST(%0:s(o.uid) AS VARCHAR(128)) AS SPECIFIC_SCHEMA, ' +
            '  CAST(o.name AS VARCHAR(128)) AS SPECIFIC_NAME, ' +
            '  %1:sCAST(SUBSTRING(c.name, 2, 1000) AS VARCHAR(128)) AS PARAMETER_NAME, ' +
            '  CAST(CASE c.isoutparam WHEN 0 THEN ''IN'' WHEN 1 THEN ''INOUT'' END AS VARCHAR(128)) AS PARAMETER_MODE, ' +
            '  CAST(t.name AS VARCHAR(128)) AS DATA_TYPE, ' +
            '  c.prec AS NUMERIC_PRECISION, c.scale AS NUMERIC_SCALE, c.colorder AS ORDINAL_POSITION, ' +
            '  CAST(c.isnullable AS BIT) AS IS_NULLABLE ' +
            'FROM %2:ssysobjects o, %2:ssyscolumns c, %2:ssystypes t ' +
            'WHERE ' +
            '  o.type IN (''P'', ''X'') AND o.id = c.id AND c.number <= 1 AND c.xusertype = t.xusertype ' +
            '  AND (db_name() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
            '  AND (%0:s(o.uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
            '  AND (o.name = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ' +
            '  AND (c.name = :PARAMETER_NAME OR (:PARAMETER_NAME IS NULL)) ' +
            'UNION ALL ' +
            'SELECT TOP 1 ' +
            '  CAST(db_name() AS VARCHAR(128)) AS SPECIFIC_CATALOG, ' +
            '  CAST(%0:s(o.uid) AS VARCHAR(128)) AS SPECIFIC_SCHEMA, ' +
            '  CAST(o.name AS VARCHAR(128)) AS SPECIFIC_NAME, ' +
            '  %1:s''RETURN_VALUE'', ''RESULT'', ''int'', 10, 0, 0, CONVERT(BIT,1) ' +
            'FROM %2:ssysobjects o ' +
            'WHERE ' +
            '  o.type IN (''P'', ''X'') ' +
            '  AND (o.name = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ' +
            'ORDER BY 3,9 ',
            [ProcName, PrefixStr, SchemaPrefix]);
end;

function TDBXDevartMsSqlMetaDataReader.NormalizeName(const Value: string): string;
var
  Len: Integer;
  QuoteChar, Prefix, Suffix: string;
begin
  Result := Trim(Value);
  Len := Length(Result);
  if Len = 0 then
    Exit;

  Prefix := GetSqlIdentifierQuotePrefix;
  Suffix := GetSqlIdentifierQuoteSuffix;
  QuoteChar := '"';
  if (Result[1] <> Prefix) and (Result[1] <> QuoteChar) and
     (Result[Len] <> Suffix) and (Result[Len] <> QuoteChar)
  then
    Result := Prefix + Value + Suffix;
end;

function TDBXDevartMsSqlMetaDataReader.FetchProcedureParameters(const Catalog: UnicodeString; const Schema: UnicodeString; const &Procedure: UnicodeString; const Parameter: UnicodeString): TDBXTable;
const
  SqlForProcedureExists =
    'SELECT COUNT(*) ' +
    'FROM INFORMATION_SCHEMA.PARAMETERS ' +
    'WHERE ' +
    '  (SPECIFIC_CATALOG = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
    '  AND (SPECIFIC_SCHEMA = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
    '  AND (SPECIFIC_NAME = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ';

  SqlForSysProcedureExists =
    'SELECT COUNT(*) ' +
    'FROM sysobjects ' +
    'WHERE ' +
    '  type IN (''P'', ''X'') ' +
    '  AND (db_name() = :CATALOG_NAME OR (:CATALOG_NAME IS NULL)) ' +
    '  AND (user_name(uid) = :SCHEMA_NAME OR (:SCHEMA_NAME IS NULL)) ' +
    '  AND (name = :PROCEDURE_NAME OR (:PROCEDURE_NAME IS NULL)) ';

var
  ParameterNames: TDBXStringArray;
  ParameterValues: TDBXStringArray;
  TmpCursor, Cursor: TDBXTable;
  Columns: TDBXValueTypeArray;
  s, SchemaPrefix: string;
begin
  DataTypeHash;
  SetLength(ParameterNames,4);
  ParameterNames[0] := TDBXParameterName.CatalogName;
  ParameterNames[1] := TDBXParameterName.SchemaName;
  ParameterNames[2] := TDBXParameterName.ProcedureName;
  ParameterNames[3] := TDBXParameterName.ParameterName;
  SetLength(ParameterValues,4);
  ParameterValues[0] := Catalog;
  ParameterValues[1] := Schema;
  ParameterValues[2] := &Procedure;
  ParameterValues[3] := Parameter;
  s := LowerCase(Copy(&Procedure, 1, 3));

  TmpCursor := GetContext.ExecuteQuery(SqlForProcedureExists, ParameterNames, ParameterValues);
  ParameterValues[0] := Catalog;
  ParameterValues[1] := Schema;
  ParameterValues[2] := &Procedure;
  ParameterValues[3] := Parameter;
  s := LowerCase(Copy(&Procedure, 1, 3));
  try
    if TmpCursor.Next and (TmpCursor.Value[0].GetInt32 > 0) then begin
      Cursor := GetContext.ExecuteQuery(SqlForProcedureParameters, ParameterNames, ParameterValues);
    end
    else begin
      FreeAndNil(TmpCursor);

      if (s = 'sp_') or (s = 'xp_') then
        TmpCursor := GetContext.ExecuteQuery(SqlForSysProcedureExists, ParameterNames, ParameterValues);

      if (TmpCursor = nil) or (TmpCursor.Next and (TmpCursor.Value[0].GetInt32 > 0)) then begin
        if Catalog <> '' then
          SchemaPrefix := NormalizeName(Catalog) + '.' + NormalizeName(Schema) + '.'
        else
          SchemaPrefix := '';
      end
      else
        SchemaPrefix := 'master.dbo.';

      ParameterValues[0] := '';
      ParameterValues[1] := '';
      ParameterValues[2] := &Procedure;
      ParameterValues[3] := Parameter;
      Cursor := GetContext.ExecuteQuery(GetSqlForSysProcedureParameters(SchemaPrefix), ParameterNames, ParameterValues);
    end;
  finally
    TmpCursor.Free;
  end;

  Columns := TDBXMetaDataCollectionColumns.CreateProcedureParametersColumns;
  Cursor := TDBXCustomMetaDataTable.Create(GetContext, TDBXMetaDataCollectionName.ProcedureParameters, Columns, Cursor);
  Result := TDBXColumnsTableCursor.Create(self, False, Cursor);
end;

function TDBXDevartMsSqlMetaDataReader.FetchPackages(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString): TDBXTable;
var
  Columns: TDBXValueTypeArray;
begin
  Columns := TDBXMetaDataCollectionColumns.CreatePackagesColumns;
  Result := TDBXEmptyTableCursor.Create(TDBXMetaDataCollectionName.Packages, Columns);
end;

function TDBXDevartMsSqlMetaDataReader.FetchPackageProcedures(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString; const ProcedureName: UnicodeString; const ProcedureType: UnicodeString): TDBXTable;
var
  Columns: TDBXValueTypeArray;
begin
  Columns := TDBXMetaDataCollectionColumns.CreatePackageProceduresColumns;
  Result := TDBXEmptyTableCursor.Create(TDBXMetaDataCollectionName.PackageProcedures, Columns);
end;

function TDBXDevartMsSqlMetaDataReader.FetchPackageProcedureParameters(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString; const ProcedureName: UnicodeString; const ParameterName: UnicodeString): TDBXTable;
var
  Columns: TDBXValueTypeArray;
begin
  Columns := TDBXMetaDataCollectionColumns.CreatePackageProcedureParametersColumns;
  Result := TDBXEmptyTableCursor.Create(TDBXMetaDataCollectionName.PackageProcedureParameters, Columns);
end;

function TDBXDevartMsSqlMetaDataReader.FetchPackageSources(const CatalogName: UnicodeString; const SchemaName: UnicodeString; const PackageName: UnicodeString): TDBXTable;
var
  Columns: TDBXValueTypeArray;
begin
  Columns := TDBXMetaDataCollectionColumns.CreatePackageSourcesColumns;
  Result := TDBXEmptyTableCursor.Create(TDBXMetaDataCollectionName.PackageSources, Columns);
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForUsers: UnicodeString;
begin
  Result := 'SELECT name FROM sysusers ' +
    'WHERE islogin=1 AND (sid IS NOT NULL) ORDER BY 1';
end;

function TDBXDevartMsSqlMetaDataReader.GetSqlForRoles: UnicodeString;
begin
  Result := 'SELECT name FROM sysusers ' +
    'WHERE uid != 0 AND (issqlrole=1 OR isapprole=1) ORDER BY 1';
end;

function TDBXDevartMsSqlMetaDataReader.GetDataTypeDescriptions: TDBXDataTypeDescriptionArray;
var
  Types: TDBXDataTypeDescriptionArray;
begin
  SetLength(Types, {$IFDEF VER12}31{$ELSE}38{$ENDIF});
  Types[0] := TDBXDataTypeDescription.Create('smallint', TDBXDataTypes.Int16Type, 5, 'smallint', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.AutoIncrementable or TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.FixedPrecisionScale or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[1] := TDBXDataTypeDescription.Create('int', TDBXDataTypes.Int32Type, 10, 'int', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.AutoIncrementable or TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.FixedPrecisionScale or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[2] := TDBXDataTypeDescription.Create('real', TDBXDataTypes.SingleType, 7, 'real', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[3] := TDBXDataTypeDescription.Create('float', TDBXDataTypes.DoubleType, 53, 'float({0})', 'Precision', -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[4] := TDBXDataTypeDescription.Create('money', TDBXDataTypes.BcdType, 19, 'money', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.FixedLength or TDBXTypeFlag.FixedPrecisionScale or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[5] := TDBXDataTypeDescription.Create('smallmoney', TDBXDataTypes.BcdType, 10, 'smallmoney', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.FixedLength or TDBXTypeFlag.FixedPrecisionScale or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[6] := TDBXDataTypeDescription.Create('bit', TDBXDataTypes.BooleanType, 1, 'bit', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[7] := TDBXDataTypeDescription.Create('tinyint', {$IFDEF VER12}TDBXDataTypes.Int16Type{$ELSE}TDBXDataTypes.UInt8Type{$ENDIF}, 3, 'tinyint', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.AutoIncrementable or TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.FixedPrecisionScale or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.Unsigned);
  Types[8] := TDBXDataTypeDescription.Create('bigint', TDBXDataTypes.Int64Type, 19, 'bigint', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.AutoIncrementable or TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.FixedPrecisionScale or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[9] := TDBXDataTypeDescription.Create('timestamp', TDBXDataTypes.BytesType, 8, 'timestamp', NullString, -1, -1, '0x', NullString, NullString, NullString, TDBXTypeFlag.FixedLength or TDBXTypeFlag.Searchable or TDBXTypeFlag.ConcurrencyType);
  Types[10] := TDBXDataTypeDescription.Create('binary', TDBXDataTypes.BytesType, 8000, 'binary({0})', 'Precision', -1, -1, '0x', NullString, NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[11] := TDBXDataTypeDescription.Create('image', TDBXDataTypes.BlobType, 2147483647, 'image', NullString, -1, -1, '0x', NullString, NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Long or TDBXTypeFlag.Nullable);
  Types[12] := TDBXDataTypeDescription.Create('text', TDBXDataTypes.AnsiStringType, 2147483647, 'text', NullString, -1, -1, '''', '''', NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Long or TDBXTypeFlag.Nullable or TDBXTypeFlag.SearchableWithLike);
  Types[13] := TDBXDataTypeDescription.Create('ntext', TDBXDataTypes.WideStringType, 1073741823, 'ntext', NullString, -1, -1, 'N''', '''', NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Long or TDBXTypeFlag.Nullable or TDBXTypeFlag.SearchableWithLike or TDBXTypeFlag.Unicode);
  Types[14] := TDBXDataTypeDescription.Create('decimal', TDBXDataTypes.BcdType, 38, 'decimal({0}, {1})', 'Precision, Scale', 38, 0, NullString, NullString, NullString, NullString, TDBXTypeFlag.AutoIncrementable or TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[15] := TDBXDataTypeDescription.Create('numeric', TDBXDataTypes.BcdType, 38, 'numeric({0}, {1})', 'Precision, Scale', 38, 0, NullString, NullString, NullString, NullString, TDBXTypeFlag.AutoIncrementable or TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[16] := TDBXDataTypeDescription.Create('datetime', TDBXDataTypes.TimeStampType, 23, 'datetime', NullString, -1, -1, '{ts ''', '''}', NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[17] := TDBXDataTypeDescription.Create('smalldatetime', TDBXDataTypes.TimeStampType, 16, 'smalldatetime', NullString, -1, -1, '{ts ''', '''}', NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[18] := TDBXDataTypeDescription.Create('sql_variant', TDBXDataTypes.WideStringType, 0, 'sql_variant', NullString, -1, -1, NullString, NullString, NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[19] := TDBXDataTypeDescription.Create('xml', TDBXDataTypes.WideStringType, 2147483647, 'xml', NullString, -1, -1, NullString, NullString, NullString, '09.00.0000', TDBXTypeFlag.Long or TDBXTypeFlag.Nullable);
  Types[20] := TDBXDataTypeDescription.Create('varchar', TDBXDataTypes.AnsiStringType, 8000, 'varchar({0})', 'Precision', -1, -1, '''', '''', '08.99.9999', NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[21] := TDBXDataTypeDescription.Create('varchar', TDBXDataTypes.AnsiStringType, 2147483647, 'varchar({0})', 'Precision', -1, -1, '''', '''', NullString, '09.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[22] := TDBXDataTypeDescription.Create('char', TDBXDataTypes.AnsiStringType, 8000, 'char({0})', 'Precision', -1, -1, '''', '''', '08.99.9999', NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[23] := TDBXDataTypeDescription.Create('char', TDBXDataTypes.AnsiStringType, 2147483647, 'char({0})', 'Precision', -1, -1, '''', '''', NullString, '09.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[24] := TDBXDataTypeDescription.Create('nchar', TDBXDataTypes.WideStringType, 4000, 'nchar({0})', 'Precision', -1, -1, 'N''', '''', '08.99.9999', NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike or TDBXTypeFlag.Unicode);
  Types[25] := TDBXDataTypeDescription.Create('nchar', TDBXDataTypes.WideStringType, 1073741823, 'nchar({0})', 'Precision', -1, -1, 'N''', '''', NullString, '09.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike or TDBXTypeFlag.Unicode);
  Types[26] := TDBXDataTypeDescription.Create('nvarchar', TDBXDataTypes.WideStringType, 4000, 'nvarchar({0})', 'Precision', -1, -1, 'N''', '''', '08.99.9999', NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike or TDBXTypeFlag.Unicode);
  Types[27] := TDBXDataTypeDescription.Create('nvarchar', TDBXDataTypes.WideStringType, 1073741823, 'nvarchar({0})', 'Precision', -1, -1, 'N''', '''', NullString, '09.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike or TDBXTypeFlag.Unicode);
  Types[28] := TDBXDataTypeDescription.Create('varbinary', TDBXDataTypes.VarBytesType, 8000, 'varbinary({0})', 'Precision', -1, -1, '0x', NullString, '08.99.9999', NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[29] := TDBXDataTypeDescription.Create('varbinary', TDBXDataTypes.VarBytesType, 1073741823, 'varbinary({0})', 'Precision', -1, -1, '0x', NullString, NullString, '09.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[30] := TDBXDataTypeDescription.Create('uniqueidentifier', TDBXDataTypes.AnsiStringType, 16, 'uniqueidentifier', NullString, -1, -1, '''', '''', NullString, NullString, TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
{$IFNDEF VER12}
  Types[31] := TDBXDataTypeDescription.Create('date', TDBXDataTypes.DateType, 10, 'date', NullString, -1, -1, '''', '''', NullString, '10.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[32] := TDBXDataTypeDescription.Create('datetime2', TDBXDataTypes.TimeStampType, 27, 'datetime2', NullString, -1, -1, '{ts ''', '''}', NullString, '10.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[33] := TDBXDataTypeDescription.Create('datetimeoffset', 36{TDBXDataTypes.TimeStampOffsetType}, 34, 'datetimeoffset', NullString, -1, -1, '{ts ''', '''}', NullString, '10.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[34] := TDBXDataTypeDescription.Create('time', TDBXDataTypes.TimeType, 16, 'time', NullString, -1, -1, '''', '''', NullString, '10.00.0000', TDBXTypeFlag.BestMatch or TDBXTypeFlag.FixedLength or TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable or TDBXTypeFlag.SearchableWithLike);
  Types[35] := TDBXDataTypeDescription.Create('hierarchyid', TDBXDataTypes.VarBytesType, 892, 'hierarchyid', NullString, -1, -1, '0x', NullString, NullString, '10.00.0000', TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[36] := TDBXDataTypeDescription.Create('geometry', TDBXDataTypes.VarBytesType, 1073741823, 'geometry', NullString, -1, -1, '0x', NullString, NullString, '10.00.0000', TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
  Types[37] := TDBXDataTypeDescription.Create('geography', TDBXDataTypes.VarBytesType, 1073741823, 'geography', NullString, -1, -1, '0x', NullString, NullString, '10.00.0000', TDBXTypeFlag.Nullable or TDBXTypeFlag.Searchable);
{$ENDIF}
  Result := Types;
end;

function TDBXDevartMsSqlMetaDataReader.GetReservedWords: TDBXStringArray;
var
  Words: TDBXStringArray;
begin
  SetLength(Words, 393);
  Words[0] := 'ADD';
  Words[1] := 'EXCEPT';
  Words[2] := 'PERCENT';
  Words[3] := 'ALL';
  Words[4] := 'EXEC';
  Words[5] := 'PLAN';
  Words[6] := 'ALTER';
  Words[7] := 'EXECUTE';
  Words[8] := 'PRECISION';
  Words[9] := 'AND';
  Words[10] := 'EXISTS';
  Words[11] := 'PRIMARY';
  Words[12] := 'ANY';
  Words[13] := 'EXIT';
  Words[14] := 'PRINT';
  Words[15] := 'AS';
  Words[16] := 'FETCH';
  Words[17] := 'PROC';
  Words[18] := 'ASC';
  Words[19] := 'FILE';
  Words[20] := 'PROCEDURE';
  Words[21] := 'AUTHORIZATION';
  Words[22] := 'FILLFACTOR';
  Words[23] := 'PUBLIC';
  Words[24] := 'BACKUP';
  Words[25] := 'FOR';
  Words[26] := 'RAISERROR';
  Words[27] := 'BEGIN';
  Words[28] := 'FOREIGN';
  Words[29] := 'READ';
  Words[30] := 'BETWEEN';
  Words[31] := 'FREETEXT';
  Words[32] := 'READTEXT';
  Words[33] := 'BREAK';
  Words[34] := 'FREETEXTTABLE';
  Words[35] := 'RECONFIGURE';
  Words[36] := 'BROWSE';
  Words[37] := 'FROM';
  Words[38] := 'REFERENCES';
  Words[39] := 'BULK';
  Words[40] := 'FULL';
  Words[41] := 'REPLICATION';
  Words[42] := 'BY';
  Words[43] := 'FUNCTION';
  Words[44] := 'RESTORE';
  Words[45] := 'CASCADE';
  Words[46] := 'GOTO';
  Words[47] := 'RESTRICT';
  Words[48] := 'CASE';
  Words[49] := 'GRANT';
  Words[50] := 'RETURN';
  Words[51] := 'CHECK';
  Words[52] := 'GROUP';
  Words[53] := 'REVOKE';
  Words[54] := 'CHECKPOINT';
  Words[55] := 'HAVING';
  Words[56] := 'RIGHT';
  Words[57] := 'CLOSE';
  Words[58] := 'HOLDLOCK';
  Words[59] := 'ROLLBACK';
  Words[60] := 'CLUSTERED';
  Words[61] := 'IDENTITY';
  Words[62] := 'ROWCOUNT';
  Words[63] := 'COALESCE';
  Words[64] := 'IDENTITY_INSERT';
  Words[65] := 'ROWGUIDCOL';
  Words[66] := 'COLLATE';
  Words[67] := 'IDENTITYCOL';
  Words[68] := 'RULE';
  Words[69] := 'COLUMN';
  Words[70] := 'IF';
  Words[71] := 'SAVE';
  Words[72] := 'COMMIT';
  Words[73] := 'IN';
  Words[74] := 'SCHEMA';
  Words[75] := 'COMPUTE';
  Words[76] := 'INDEX';
  Words[77] := 'SELECT';
  Words[78] := 'CONSTRAINT';
  Words[79] := 'INNER';
  Words[80] := 'SESSION_USER';
  Words[81] := 'CONTAINS';
  Words[82] := 'INSERT';
  Words[83] := 'SET';
  Words[84] := 'CONTAINSTABLE';
  Words[85] := 'INTERSECT';
  Words[86] := 'SETUSER';
  Words[87] := 'CONTINUE';
  Words[88] := 'INTO';
  Words[89] := 'SHUTDOWN';
  Words[90] := 'CONVERT';
  Words[91] := 'IS';
  Words[92] := 'SOME';
  Words[93] := 'CREATE';
  Words[94] := 'JOIN';
  Words[95] := 'STATISTICS';
  Words[96] := 'CROSS';
  Words[97] := 'KEY';
  Words[98] := 'SYSTEM_USER';
  Words[99] := 'CURRENT';
  Words[100] := 'KILL';
  Words[101] := 'TABLE';
  Words[102] := 'CURRENT_DATE';
  Words[103] := 'LEFT';
  Words[104] := 'TEXTSIZE';
  Words[105] := 'CURRENT_TIME';
  Words[106] := 'LIKE';
  Words[107] := 'THEN';
  Words[108] := 'CURRENT_TIMESTAMP';
  Words[109] := 'LINENO';
  Words[110] := 'TO';
  Words[111] := 'CURRENT_USER';
  Words[112] := 'LOAD';
  Words[113] := 'TOP';
  Words[114] := 'CURSOR';
  Words[115] := 'NATIONAL';
  Words[116] := 'TRAN';
  Words[117] := 'DATABASE';
  Words[118] := 'NOCHECK';
  Words[119] := 'TRANSACTION';
  Words[120] := 'DBCC';
  Words[121] := 'NONCLUSTERED';
  Words[122] := 'TRIGGER';
  Words[123] := 'DEALLOCATE';
  Words[124] := 'NOT';
  Words[125] := 'TRUNCATE';
  Words[126] := 'DECLARE';
  Words[127] := 'NULL';
  Words[128] := 'TSEQUAL';
  Words[129] := 'DEFAULT';
  Words[130] := 'NULLIF';
  Words[131] := 'UNION';
  Words[132] := 'DELETE';
  Words[133] := 'OF';
  Words[134] := 'UNIQUE';
  Words[135] := 'DENY';
  Words[136] := 'OFF';
  Words[137] := 'UPDATE';
  Words[138] := 'DESC';
  Words[139] := 'OFFSETS';
  Words[140] := 'UPDATETEXT';
  Words[141] := 'DISK';
  Words[142] := 'ON';
  Words[143] := 'USE';
  Words[144] := 'DISTINCT';
  Words[145] := 'OPEN';
  Words[146] := 'USER';
  Words[147] := 'DISTRIBUTED';
  Words[148] := 'OPENDATASOURCE';
  Words[149] := 'VALUES';
  Words[150] := 'DOUBLE';
  Words[151] := 'OPENQUERY';
  Words[152] := 'VARYING';
  Words[153] := 'DROP';
  Words[154] := 'OPENROWSET';
  Words[155] := 'VIEW';
  Words[156] := 'DUMMY';
  Words[157] := 'OPENXML';
  Words[158] := 'WAITFOR';
  Words[159] := 'DUMP';
  Words[160] := 'OPTION';
  Words[161] := 'WHEN';
  Words[162] := 'ELSE';
  Words[163] := 'OR';
  Words[164] := 'WHERE';
  Words[165] := 'END';
  Words[166] := 'ORDER';
  Words[167] := 'WHILE';
  Words[168] := 'ERRLVL';
  Words[169] := 'OUTER';
  Words[170] := 'WITH';
  Words[171] := 'ESCAPE';
  Words[172] := 'OVER';
  Words[173] := 'WRITETEXT';
  Words[174] := 'ABSOLUTE';
  Words[175] := 'FOUND';
  Words[176] := 'PRESERVE';
  Words[177] := 'ACTION';
  Words[178] := 'FREE';
  Words[179] := 'PRIOR';
  Words[180] := 'ADMIN';
  Words[181] := 'GENERAL';
  Words[182] := 'PRIVILEGES';
  Words[183] := 'AFTER';
  Words[184] := 'GET';
  Words[185] := 'READS';
  Words[186] := 'AGGREGATE';
  Words[187] := 'GLOBAL';
  Words[188] := 'REAL';
  Words[189] := 'ALIAS';
  Words[190] := 'GO';
  Words[191] := 'RECURSIVE';
  Words[192] := 'ALLOCATE';
  Words[193] := 'GROUPING';
  Words[194] := 'REF';
  Words[195] := 'ARE';
  Words[196] := 'HOST';
  Words[197] := 'REFERENCING';
  Words[198] := 'ARRAY';
  Words[199] := 'HOUR';
  Words[200] := 'RELATIVE';
  Words[201] := 'ASSERTION';
  Words[202] := 'IGNORE';
  Words[203] := 'RESULT';
  Words[204] := 'AT';
  Words[205] := 'IMMEDIATE';
  Words[206] := 'RETURNS';
  Words[207] := 'BEFORE';
  Words[208] := 'INDICATOR';
  Words[209] := 'ROLE';
  Words[210] := 'BINARY';
  Words[211] := 'INITIALIZE';
  Words[212] := 'ROLLUP';
  Words[213] := 'BIT';
  Words[214] := 'INITIALLY';
  Words[215] := 'ROUTINE';
  Words[216] := 'BLOB';
  Words[217] := 'INOUT';
  Words[218] := 'ROW';
  Words[219] := 'BOOLEAN';
  Words[220] := 'INPUT';
  Words[221] := 'ROWS';
  Words[222] := 'BOTH';
  Words[223] := 'INT';
  Words[224] := 'SAVEPOINT';
  Words[225] := 'BREADTH';
  Words[226] := 'INTEGER';
  Words[227] := 'SCROLL';
  Words[228] := 'CALL';
  Words[229] := 'INTERVAL';
  Words[230] := 'SCOPE';
  Words[231] := 'CASCADED';
  Words[232] := 'ISOLATION';
  Words[233] := 'SEARCH';
  Words[234] := 'CAST';
  Words[235] := 'ITERATE';
  Words[236] := 'SECOND';
  Words[237] := 'CATALOG';
  Words[238] := 'LANGUAGE';
  Words[239] := 'SECTION';
  Words[240] := 'CHAR';
  Words[241] := 'LARGE';
  Words[242] := 'SEQUENCE';
  Words[243] := 'CHARACTER';
  Words[244] := 'LAST';
  Words[245] := 'SESSION';
  Words[246] := 'CLASS';
  Words[247] := 'LATERAL';
  Words[248] := 'SETS';
  Words[249] := 'CLOB';
  Words[250] := 'LEADING';
  Words[251] := 'SIZE';
  Words[252] := 'COLLATION';
  Words[253] := 'LESS';
  Words[254] := 'SMALLINT';
  Words[255] := 'COMPLETION';
  Words[256] := 'LEVEL';
  Words[257] := 'SPACE';
  Words[258] := 'CONNECT';
  Words[259] := 'LIMIT';
  Words[260] := 'SPECIFIC';
  Words[261] := 'CONNECTION';
  Words[262] := 'LOCAL';
  Words[263] := 'SPECIFICTYPE';
  Words[264] := 'CONSTRAINTS';
  Words[265] := 'LOCALTIME';
  Words[266] := 'SQL';
  Words[267] := 'CONSTRUCTOR';
  Words[268] := 'LOCALTIMESTAMP';
  Words[269] := 'SQLEXCEPTION';
  Words[270] := 'CORRESPONDING';
  Words[271] := 'LOCATOR';
  Words[272] := 'SQLSTATE';
  Words[273] := 'CUBE';
  Words[274] := 'MAP';
  Words[275] := 'SQLWARNING';
  Words[276] := 'CURRENT_PATH';
  Words[277] := 'MATCH';
  Words[278] := 'START';
  Words[279] := 'CURRENT_ROLE';
  Words[280] := 'MINUTE';
  Words[281] := 'STATE';
  Words[282] := 'CYCLE';
  Words[283] := 'MODIFIES';
  Words[284] := 'STATEMENT';
  Words[285] := 'DATA';
  Words[286] := 'MODIFY';
  Words[287] := 'STATIC';
  Words[288] := 'DATE';
  Words[289] := 'MODULE';
  Words[290] := 'STRUCTURE';
  Words[291] := 'DAY';
  Words[292] := 'MONTH';
  Words[293] := 'TEMPORARY';
  Words[294] := 'DEC';
  Words[295] := 'NAMES';
  Words[296] := 'TERMINATE';
  Words[297] := 'DECIMAL';
  Words[298] := 'NATURAL';
  Words[299] := 'THAN';
  Words[300] := 'DEFERRABLE';
  Words[301] := 'NCHAR';
  Words[302] := 'TIME';
  Words[303] := 'DEFERRED';
  Words[304] := 'NCLOB';
  Words[305] := 'TIMESTAMP';
  Words[306] := 'DEPTH';
  Words[307] := 'NEW';
  Words[308] := 'TIMEZONE_HOUR';
  Words[309] := 'DEREF';
  Words[310] := 'NEXT';
  Words[311] := 'TIMEZONE_MINUTE';
  Words[312] := 'DESCRIBE';
  Words[313] := 'NO';
  Words[314] := 'TRAILING';
  Words[315] := 'DESCRIPTOR';
  Words[316] := 'NONE';
  Words[317] := 'TRANSLATION';
  Words[318] := 'DESTROY';
  Words[319] := 'NUMERIC';
  Words[320] := 'TREAT';
  Words[321] := 'DESTRUCTOR';
  Words[322] := 'OBJECT';
  Words[323] := 'TRUE';
  Words[324] := 'DETERMINISTIC';
  Words[325] := 'OLD';
  Words[326] := 'UNDER';
  Words[327] := 'DICTIONARY';
  Words[328] := 'ONLY';
  Words[329] := 'UNKNOWN';
  Words[330] := 'DIAGNOSTICS';
  Words[331] := 'OPERATION';
  Words[332] := 'UNNEST';
  Words[333] := 'DISCONNECT';
  Words[334] := 'ORDINALITY';
  Words[335] := 'USAGE';
  Words[336] := 'DOMAIN';
  Words[337] := 'OUT';
  Words[338] := 'USING';
  Words[339] := 'DYNAMIC';
  Words[340] := 'OUTPUT';
  Words[341] := 'VALUE';
  Words[342] := 'EACH';
  Words[343] := 'PAD';
  Words[344] := 'VARCHAR';
  Words[345] := 'END-EXEC';
  Words[346] := 'PARAMETER';
  Words[347] := 'VARIABLE';
  Words[348] := 'EQUALS';
  Words[349] := 'PARAMETERS';
  Words[350] := 'WHENEVER';
  Words[351] := 'EVERY';
  Words[352] := 'PARTIAL';
  Words[353] := 'WITHOUT';
  Words[354] := 'EXCEPTION';
  Words[355] := 'PATH';
  Words[356] := 'WORK';
  Words[357] := 'EXTERNAL';
  Words[358] := 'POSTFIX';
  Words[359] := 'WRITE';
  Words[360] := 'FALSE';
  Words[361] := 'PREFIX';
  Words[362] := 'YEAR';
  Words[363] := 'FIRST';
  Words[364] := 'PREORDER';
  Words[365] := 'ZONE';
  Words[366] := 'FLOAT';
  Words[367] := 'PREPARE';
  Words[368] := 'ADA';
  Words[369] := 'AVG';
  Words[370] := 'BIT_LENGTH';
  Words[371] := 'CHAR_LENGTH';
  Words[372] := 'CHARACTER_LENGTH';
  Words[373] := 'COUNT';
  Words[374] := 'EXTRACT';
  Words[375] := 'FORTRAN';
  Words[376] := 'INCLUDE';
  Words[377] := 'INSENSITIVE';
  Words[378] := 'LOWER';
  Words[379] := 'MAX';
  Words[380] := 'MIN';
  Words[381] := 'OCTET_LENGTH';
  Words[382] := 'OVERLAPS';
  Words[383] := 'PASCAL';
  Words[384] := 'POSITION';
  Words[385] := 'SQLCA';
  Words[386] := 'SQLCODE';
  Words[387] := 'SQLERROR';
  Words[388] := 'SUBSTRING';
  Words[389] := 'SUM';
  Words[390] := 'TRANSLATE';
  Words[391] := 'TRIM';
  Words[392] := 'UPPER';
  Result := Words;
end;

end.
