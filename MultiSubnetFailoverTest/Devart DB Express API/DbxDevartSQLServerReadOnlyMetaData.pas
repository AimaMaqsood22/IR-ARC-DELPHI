{$HPPEMIT '#pragma link "DbxDevartSQLServerReadOnlyMetaData"'}
unit DbxDevartSQLServerReadOnlyMetaData;

{$IFNDEF CLR}
{$I Dbx.inc}
{$ENDIF}

interface

uses
{$IFDEF CLR}
  System.Reflection,
{$ENDIF}
  DBXMetaDataReader,
  DBXMetaDataCommandFactory;

type
  TDBXDevartMSSQLMetaDataCommandFactory = class(TDBXMetaDataCommandFactory)
  public
    function CreateMetaDataReader: TDBXMetaDataReader; override;
    class procedure RegisterMetaDataCommandFactory(const ObjectClass: TClass); static;
    class procedure UnRegisterMetaDataCommandFactory(const ObjectClass: TClass); static;
  end;

implementation

uses
{$IFDEF VER16P}
  DBXClassRegistry,
{$ELSE}
  ClassRegistry,
{$ENDIF}
  DbxDevartSQLServerMetaDataReader;

function TDBXDevartMSSQLMetaDataCommandFactory.CreateMetaDataReader: TDBXMetaDataReader;
begin
  Result := TDBXDevartMsSqlMetaDataReader.Create;
end;

class procedure TDBXDevartMSSQLMetaDataCommandFactory.RegisterMetaDataCommandFactory(const ObjectClass: TClass);
var
  ClassRegistry: TClassRegistry;
  ClassName: UnicodeString;
begin
  ClassRegistry := TClassRegistry.GetClassRegistry;
{$IFDEF CLR}
  ClassName := 'Devart.DbxSda.DriverLoader.' + ObjectClass.ClassName;  { Do not resource }
  ClassRegistry.RegisterClass(ClassName, ObjectClass, System.Reflection.Assembly.GetCallingAssembly); { Do not resource }
{$ELSE}
  ClassName := ObjectClass.ClassName;
  ClassRegistry.RegisterClass(ClassName, ObjectClass{$IFNDEF VER17P}, nil{$ENDIF}); { Do not resource }
{$ENDIF}
end;

class procedure TDBXDevartMSSQLMetaDataCommandFactory.UnRegisterMetaDataCommandFactory(
  const ObjectClass: TClass);
var
  ClassName: UnicodeString;
begin
{$IFDEF CLR}
  ClassName := 'Devart.DbxSda.DriverLoader.' + ObjectClass.ClassName;  { Do not resource }
{$ELSE}
  ClassName := ObjectClass.ClassName;
{$ENDIF}
  TClassRegistry.GetClassRegistry.UnRegisterClass(ClassName);
end;

initialization
  TDBXDevartMSSQLMetaDataCommandFactory.RegisterMetaDataCommandFactory(TDBXDevartMSSQLMetaDataCommandFactory);
finalization
  TDBXDevartMSSQLMetaDataCommandFactory.UnRegisterMetaDataCommandFactory(TDBXDevartMSSQLMetaDataCommandFactory);
end.
