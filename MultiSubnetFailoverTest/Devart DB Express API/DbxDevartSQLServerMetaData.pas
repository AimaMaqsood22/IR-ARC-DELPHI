{$HPPEMIT '#pragma link "DbxDevartSQLServerMetaData"'}
unit DbxDevartSQLServerMetaData;

{$IFNDEF CLR}
{$I Dbx.inc}
{$ENDIF}

interface

uses
  DBXMetaDataWriterFactory,
  DbxDevartSQLServerMetaDataWriter;

{$IFDEF CLR}
type
  TDBXDevartMetaDataWriterFactory = class
  public
    class procedure RegisterWriter(DialectName: String; WriterClass: TClass);
    class procedure UnRegisterWriter(DialectName: String; WriterClass: TClass);
  end;
{$ENDIF}

implementation

uses
{$IFDEF VER16P}
  DBXClassRegistry;
{$ELSE}
  ClassRegistry;
{$ENDIF}

{$IFDEF CLR}
class procedure TDBXDevartMetaDataWriterFactory.RegisterWriter(
  DialectName: String; WriterClass: TClass);
var
  ClassRegistry: TClassRegistry;
begin
  ClassRegistry := TClassRegistry.GetClassRegistry;
  ClassRegistry.RegisterClass('Devart.DbxSda.DriverLoader.' + WriterClass.ClassName, WriterClass, System.Reflection.Assembly.GetCallingAssembly); { Do not resource }
end;

class procedure TDBXDevartMetaDataWriterFactory.UnRegisterWriter(
  DialectName: String; WriterClass: TClass);
begin
  TClassRegistry.GetClassRegistry.UnregisterClass('Devart.DbxSda.DriverLoader.' + WriterClass.ClassName);
end;
{$ENDIF}

initialization
{$IFDEF CLR}
  TDBXDevartMetaDataWriterFactory.RegisterWriter('DevartSQLServer', TDBXDevartMsSqlMetaDataWriter);
{$ELSE}
  TDBXMetaDataWriterFactory.RegisterWriter('DevartSQLServer', TDBXDevartMsSqlMetaDataWriter);
{$ENDIF}
finalization
{$IFDEF CLR}
  TDBXDevartMetaDataWriterFactory.UnRegisterWriter('DevartSQLServer', TDBXDevartMsSqlMetaDataWriter);
{$ELSE}
  TDBXMetaDataWriterFactory.UnRegisterWriter('DevartSQLServer', TDBXDevartMsSqlMetaDataWriter);
{$ENDIF}
end.
