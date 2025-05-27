program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  DBXDevartSQLServer in 'Devart DB Express API\DBXDevartSQLServer.pas',
  DbxDevartSQLServerMetaData in 'Devart DB Express API\DbxDevartSQLServerMetaData.pas',
  DbxDevartSQLServerMetaDataReader in 'Devart DB Express API\DbxDevartSQLServerMetaDataReader.pas',
  DbxDevartSQLServerMetaDataWriter in 'Devart DB Express API\DbxDevartSQLServerMetaDataWriter.pas',
  DbxDevartSQLServerReadOnlyMetaData in 'Devart DB Express API\DbxDevartSQLServerReadOnlyMetaData.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
