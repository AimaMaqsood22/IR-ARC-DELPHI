{$HPPEMIT '#pragma link "DBXDevartSQLServer"'}
unit DBXDevartSQLServer;

{$IFNDEF CLR}
{$I Dbx.inc}
{$ENDIF}

interface

uses
  Classes, SysUtils,
{$IFDEF CLR}
  Borland.Data.DBXDynalinkManaged,
{$ELSE}
  DBXDynalinkNative,
{$ENDIF}
  DbxDynalink, DBXCommon,
  DbxDevartSQLServerReadOnlyMetaData, DbxDevartSQLServerMetaData;

const
  sDriverName = 'DevartSQLServer';
  sDriverNameDirect = 'DevartSQLServerDirect';
  sDriverNameCompact = 'DevartSQLServerCompact';

  sIPVersion = 'IPVersion';
  sEnableBCD = 'EnableBCD';
  sFetchAll = 'FetchAll';
  sLongStrings = 'LongStrings';
  sParamPrefix = 'ParamPrefix';
  sUseUnicode = 'UseUnicode';
  sUseQuoteChar = 'UseQuoteChar';

type
{$IFDEF CLR}
  TDBXDevartSQLServerDriver = class(TDBXDynalinkDriverManaged)
{$ELSE}
  TDBXDevartSQLServerDriver = class(TDBXDynalinkDriverNative)
{$ENDIF}
  protected
    function GetDriverLoaderClass: TDBXDynalinkDriverCommonLoaderClass; virtual;
  public
    constructor Create(DBXDriverDef: TDBXDriverDef); override;
  end;

  TDBXDevartSQLServerDirectDriver = class(TDBXDevartSQLServerDriver)
  public
    constructor Create(DBXDriverDef: TDBXDriverDef); override;
  end;

  TDBXDevartSQLServerCompactDriver = class(TDBXDevartSQLServerDriver)
  public
    constructor Create(DBXDriverDef: TDBXDriverDef); override;
  end;

  TDBXDevartSQLServerProperties = class(TDBXProperties)
  strict private
    function GetSchemaOverride: string;
    procedure SetSchemaOverride(const Value: string);
    function GetHostName: string;
    procedure SetHostName(const Value: string);
    function GetDataBase: string;
    procedure SetDataBase(const Value: string);
    function GetUserName: string;
    procedure SetUserName(const Value: string);
    function GetPassword: string;
    procedure SetPassword(const Value: string);

    function GetBlobSize: Integer;
    procedure SetBlobSize(const Value: Integer);
    function GetLongStrings: Boolean;
    procedure SetLongStrings(const Value: Boolean);
    function GetEnableBCD: Boolean;
    procedure SetEnableBCD(const Value: Boolean);
    function GetFetchAll: Boolean;
    procedure SetFetchAll(const Value: Boolean);
    function GetParamPrefix: Boolean;
    procedure SetParamPrefix(const Value: Boolean);

    function GetUseUnicode: Boolean;
    procedure SetUseUnicode(const Value: Boolean);

    function GetIPVersion: string;
    procedure SetIPVersion(const Value: string);

    function GetUseQuoteChar: Boolean;
    procedure SetUseQuoteChar(const Value: Boolean);

    function GetPort: Integer;
    procedure SetPort(const Value: Integer);

  public
    // cannot fill driver properties in the constructor
    // because TDBXProperties.Clone will duplicate all properties
    //constructor Create(DBXContext: TDBXContext); override;

  published
    property SchemaOverride: string read GetSchemaOverride write SetSchemaOverride;
    property HostName: string read GetHostName write SetHostName;
    property DataBase: string read GetDataBase write SetDataBase;
    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
    property Port: Integer read GetPort write SetPort;

    property IPVersion: string read GetIPVersion write SetIPVersion;
    property BlobSize: Integer read GetBlobSize write SetBlobSize;
    property LongStrings: Boolean read GetLongStrings write SetLongStrings;
    property EnableBCD: Boolean read GetEnableBCD write SetEnableBCD;
    property FetchAll: Boolean read GetFetchAll write SetFetchAll;
    property ParamPrefix: Boolean read GetParamPrefix write SetParamPrefix;

    property UseUnicode: Boolean read GetUseUnicode write SetUseUnicode;
    property UseQuoteChar: Boolean read GetUseQuoteChar write SetUseQuoteChar;
  end;

implementation

uses
{$IFDEF VER20P}
  SqlExpr,
{$ENDIF}
  DbxPlatform;

{$UNDEF AUTO_UNLOAD_DRIVER}

{$IFNDEF CLR}
{$IFDEF VER15P}
  {$DEFINE AUTO_UNLOAD_DRIVER}
{$ENDIF}
{$ENDIF}

{ TDBXSQLServerDevartDriver }

constructor TDBXDevartSQLServerDriver.Create(DBXDriverDef: TDBXDriverDef);
{$I IdeConsts.inc}
var
  Props: TDBXProperties;
begin
{$IFNDEF AUTO_UNLOAD_DRIVER}
  inherited Create(DBXDriverDef, {$IFNDEF CLR}GetDriverLoaderClass{$ELSE}TDBXDynalinkDriverLoader{$ENDIF});

  Props := TDBXDevartSQLServerProperties.Create(DBXDriverDef.FDBXContext);
  InitDriverProperties(Props);
{$ELSE}
  // AUTO UNLOAD DRIVER
  Props := TDBXDevartSQLServerProperties.Create(DBXDriverDef.FDBXContext);
  if (DBXDriverDef.FDriverProperties <> nil) and
     (DBXDriverDef.FDriverProperties.Properties.IndexOfName(TDBXPropertyNames.AutoUnloadDriver) > - 1)
  then
    Props[TDBXPropertyNames.AutoUnloadDriver] := DBXDriverDef.FDriverProperties.Properties.Values[TDBXPropertyNames.AutoUnloadDriver];

  inherited Create(DBXDriverDef, {$IFNDEF CLR}GetDriverLoaderClass{$ELSE}TDBXDynalinkDriverLoader{$ENDIF}, Props);
{$ENDIF}

  Props[TDBXPropertyNames.SchemaOverride] := '%.dbo';
  Props[TDBXPropertyNames.DriverUnit] := 'DBXDevartSQLServer';
{$IFNDEF VER17P}
  Props[TDBXPropertyNames.DriverAssemblyLoader] := 'Devart.DbxSda.DriverLoader.TCRDynalinkDriverLoader,Devart.DbxSda.DriverLoader,Version=' + IntToStr(IDEInfos[IDEVer].Version) + '.0.0.1,Culture=neutral,PublicKeyToken=09af7300eec23701';
  Props[TDBXPropertyNames.MetaDataAssemblyLoader] := 'Devart.DbxSda.DriverLoader.TDBXDevartMSSQLMetaDataCommandFactory,Devart.DbxSda.DriverLoader,Version=' + IntToStr(IDEInfos[IDEVer].Version) + '.0.0.1,Culture=neutral,PublicKeyToken=09af7300eec23701';
{$ENDIF}
  Props[TDBXPropertyNames.DriverPackageLoader] := 'TDBXDynalinkDriverLoader,DBXCommonDriver' + IDEInfos[IDEVer].PackageSuffix + '.bpl';
  Props[TDBXPropertyNames.MetaDataPackageLoader] := 'TDBXDevartMSSQLMetaDataCommandFactory,DbxDevartSQLServerDriver' + IDEInfos[IDEVer].PackageSuffix + '.bpl';

  Props[TDBXPropertyNames.ProductName] := 'DevartSQLServer';

  Props[TDBXPropertyNames.GetDriverFunc] := 'getSQLDriverSQLServer';
{$IFDEF LINUX}
  {$IFDEF VER26P}
  Props[TDBXPropertyNames.LibraryName] := 'libdbexpsda41.so';
  {$ELSE}
  Props[TDBXPropertyNames.LibraryName] := 'libdbexpsda40.so';
  {$ENDIF}
  Props[TDBXPropertyNames.VendorLib] := 'sqloledb.so';
{$ELSE}
  {$IFDEF VER26P}
  Props[TDBXPropertyNames.LibraryName] := 'dbexpsda41.dll';
  {$ELSE}
  Props[TDBXPropertyNames.LibraryName] := 'dbexpsda40.dll';
  {$ENDIF}
  Props[TDBXPropertyNames.VendorLib] := 'sqloledb.dll';
{$ENDIF}
{$IFDEF VER17P}
  {$IFDEF VER26P}
  Props[TDBXPropertyNames.LibraryNameOsx] := 'libdbexpsda41.dylib';
  {$ELSE}
  Props[TDBXPropertyNames.LibraryNameOsx] := 'libdbexpsda40.dylib';
  {$ENDIF}
  Props[TDBXPropertyNames.VendorLibOsx] := 'sqloledb.dylib';
{$ENDIF}

  Props[TDBXPropertyNames.HostName] := '';
  Props[TDBXPropertyNames.Database] := '';
  Props[TDBXPropertyNames.UserName] := '';
  Props[TDBXPropertyNames.Password] := '';
  Props[TDBXPropertyNames.Port] := '1433';

  Props[TDBXPropertyNames.ErrorResourceFile] := '';
  Props[TDBXDynalinkPropertyNames.LocaleCode] := '0000';
  Props[TDBXPropertyNames.IsolationLevel] := 'ReadCommitted';

  Props[TDBXPropertyNames.MaxBlobSize] := '-1';
  Props[sLongStrings] := 'True';
  Props[sEnableBCD] := 'True';
  Props[sFetchAll] := 'True';
  Props[sParamPrefix] := 'False';

  Props[sUseUnicode] := 'True';
  Props[sIPVersion] := 'IPv4';
  Props[sUseQuoteChar] := 'True';
end;

function TDBXDevartSQLServerDriver.GetDriverLoaderClass: TDBXDynalinkDriverCommonLoaderClass;
begin
  Result := TDBXDynalinkDriverLoader;
end;

{ TDBXDevartSQLServerDirectDriver  }

constructor TDBXDevartSQLServerDirectDriver.Create(DBXDriverDef: TDBXDriverDef);
begin
  inherited;

  DriverProperties[TDBXPropertyNames.GetDriverFunc] := 'getSQLDriverSQLServerDirect';
  DriverProperties[TDBXPropertyNames.VendorLib] := 'not used';
{$IFDEF VER17P}
  DriverProperties[TDBXPropertyNames.VendorLibOsx] := 'not used';
{$ENDIF}
end;

{ TDBXDevartSQLServerCompactDriver  }

constructor TDBXDevartSQLServerCompactDriver.Create(DBXDriverDef: TDBXDriverDef);
begin
  inherited;

  DriverProperties[TDBXPropertyNames.GetDriverFunc] := 'getSQLDriverSQLServerCompact';
{$IFDEF LINUX}
  DriverProperties[TDBXPropertyNames.VendorLib] := 'sqlceoledb30.so';
{$ELSE}
  DriverProperties[TDBXPropertyNames.VendorLib] := 'sqlceoledb30.dll';
{$ENDIF}
{$IFDEF VER17P}
  DriverProperties[TDBXPropertyNames.VendorLibOsx] := 'sqlceoledb30.dylib';
{$ENDIF}
end;

{ TDBXDevartSQLServerProperties }

function TDBXDevartSQLServerProperties.GetSchemaOverride: string;
begin
  Result := Values[TDBXPropertyNames.SchemaOverride];
end;

procedure TDBXDevartSQLServerProperties.SetSchemaOverride(const Value: string);
begin
  Values[TDBXPropertyNames.SchemaOverride] := Value;
end;

function TDBXDevartSQLServerProperties.GetHostName: string;
begin
  Result := Values[TDBXPropertyNames.HostName];
end;

procedure TDBXDevartSQLServerProperties.SetHostName(const Value: string);
begin
  Values[TDBXPropertyNames.HostName] := Value;
end;

function TDBXDevartSQLServerProperties.GetDataBase: string;
begin
  Result := Values[TDBXPropertyNames.Database];
end;

procedure TDBXDevartSQLServerProperties.SetDataBase(const Value: string);
begin
  Values[TDBXPropertyNames.Database] := Value;
end;

function TDBXDevartSQLServerProperties.GetUserName: string;
begin
  Result := Values[TDBXPropertyNames.UserName];
end;

procedure TDBXDevartSQLServerProperties.SetUserName(const Value: string);
begin
  Values[TDBXPropertyNames.UserName] := Value;
end;

function TDBXDevartSQLServerProperties.GetPassword: string;
begin
  Result := Values[TDBXPropertyNames.Password];
end;

procedure TDBXDevartSQLServerProperties.SetPassword(const Value: string);
begin
  Values[TDBXPropertyNames.Password] := Value;
end;

function TDBXDevartSQLServerProperties.GetBlobSize: Integer;
begin
  Result := StrToIntDef(Values[TDBXPropertyNames.MaxBlobSize], -1);
end;

procedure TDBXDevartSQLServerProperties.SetBlobSize(const Value: Integer);
begin
  Values[TDBXPropertyNames.MaxBlobSize] := IntToStr(Value);
end;

function TDBXDevartSQLServerProperties.GetEnableBCD: Boolean;
begin
  Result := StrToBoolDef(Values[sEnableBCD], True);
end;

function TDBXDevartSQLServerProperties.GetLongStrings: Boolean;
begin
  Result := StrToBoolDef(Values[sLongStrings], True);
end;

procedure TDBXDevartSQLServerProperties.SetLongStrings(const Value: Boolean);
begin
  Values[sLongStrings] := BoolToStr(Value, True);
end;

procedure TDBXDevartSQLServerProperties.SetEnableBCD(const Value: Boolean);
begin
  Values[sEnableBCD] := BoolToStr(Value, True);
end;

function TDBXDevartSQLServerProperties.GetFetchAll: Boolean;
begin
  Result := StrToBoolDef(Values[sFetchAll], True);
end;

procedure TDBXDevartSQLServerProperties.SetFetchAll(const Value: Boolean);
begin
  Values[sFetchAll] := BoolToStr(Value, True);
end;

function TDBXDevartSQLServerProperties.GetParamPrefix: Boolean;
begin
  Result := StrToBoolDef(Values[sParamPrefix], False);
end;

procedure TDBXDevartSQLServerProperties.SetParamPrefix(const Value: Boolean);
begin
  Values[sParamPrefix] := BoolToStr(Value, True);
end;

function TDBXDevartSQLServerProperties.GetUseUnicode: Boolean;
begin
  Result := StrToBoolDef(Values[sUseUnicode], True);
end;

procedure TDBXDevartSQLServerProperties.SetUseUnicode(const Value: Boolean);
begin
  Values[sUseUnicode] := BoolToStr(Value, True);
end;

function TDBXDevartSQLServerProperties.GetIPVersion: string;
begin
  Result := Values[sIPVersion];
end;

procedure TDBXDevartSQLServerProperties.SetIPVersion(const Value: string);
begin
  Values[sIPVersion] := Value;
end;

function TDBXDevartSQLServerProperties.GetUseQuoteChar: Boolean;
begin
  Result := StrToBoolDef(Values[sUseQuoteChar], True);
end;

procedure TDBXDevartSQLServerProperties.SetUseQuoteChar(const Value: Boolean);
begin
  Values[sUseQuoteChar] := BoolToStr(Value, True);
end;

function TDBXDevartSQLServerProperties.GetPort: Integer;
begin
  Result := StrToIntDef(Values[TDBXPropertyNames.Port], 1433);
end;

procedure TDBXDevartSQLServerProperties.SetPort(const Value: Integer);
begin
  Values[TDBXPropertyNames.Port] := IntToStr(Value);
end;

initialization
  TDBXDriverRegistry.RegisterDriverClass(sDriverName, TDBXDevartSQLServerDriver);
  TDBXDriverRegistry.RegisterDriverClass(sDriverNameDirect, TDBXDevartSQLServerDirectDriver);
  TDBXDriverRegistry.RegisterDriverClass(sDriverNameCompact, TDBXDevartSQLServerCompactDriver);
{$IFDEF VER20P}
  RegisterDriver(sDriverName);
  RegisterDriver(sDriverNameDirect);
  RegisterDriver(sDriverNameCompact);

finalization
  TDBXDriverRegistry.UnloadDriver(sDriverName);
  TDBXDriverRegistry.UnloadDriver(sDriverNameDirect);
  TDBXDriverRegistry.UnloadDriver(sDriverNameCompact);
{$ENDIF}

end.
