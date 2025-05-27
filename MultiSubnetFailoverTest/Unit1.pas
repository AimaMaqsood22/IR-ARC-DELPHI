unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SQLExpr, StdCtrls, Registry, FMTBcd, DB, WideStrings;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    Button3: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Button4: TButton;
    Memo1: TMemo;
    Edit5: TEdit;
    CheckBox1: TCheckBox;
    SQLConnection1: TSQLConnection;
    Button7: TButton;
    Button1: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    SQLDB : TSQLConnection;
    SQLDBDSN : TSQLConnection;
    SQLQuery : TSQLQuery;

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}



procedure TForm1.Button1Click(Sender: TObject);
var
  ldate : TDateTime;
begin
  ldate := Now+(365*20);
  //ldate := StrToDateTime('12/20/2038 12:00:00 AM');

  ShowMessage(DateTimetoStr(ldate));

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  try

     SQLDB := TSQLConnection.Create(nil);
     SQLDB.LoginPrompt := False;
     SQLDBDSN := TSQLConnection.Create(nil);
     SQLDB.LoginPrompt := False;
     SQLDB.ConnectionName := 'MSSQLConnection';
     SQLDB.DriverName := 'DevartSQLServer';
     SQLDB.GetDriverFunc := 'getSQLDriverSQLServer';
     SQLDB.LibraryName := 'dbexpsda40.dll';
     //SQLDB.VendorLib := 'sqlncli11';
     SQLDB.Params.Values['Database'] := Edit2.Text;
     SQLDB.Params.Values['Hostname'] := Edit1.Text;
     //SQLDB.Params.Values['VendorLib'] := 'sqlncli11';
     //SQLDB.Params.Add('VendorLib=msoledbsql');
     SQLDB.Params.Add('VendorLib=msoledbsql');

     if Edit3.Text <> '' then
     begin
      SQLDB.Params.Values['User_name'] := Edit3.Text;
      SQLDB.Params.Values['Password'] := Edit4.Text;
     end
     else
       SQLDB.Params.Add('OS Authentication=True');

     if CheckBox1.Checked then
     begin
       SQLDB.Params.Add('MultiSubnetFailover=True');
       SQLDB.Params.Add('ApplicationIntent=aireadonly');
     end;

      Memo1.Lines.Add( SQLDB.Params.Text );

     //SQLDB.Open;
     //SQLDBDSN.DriverName := 'DevartSQLServer';
     //SQLDBDSN.GetDriverFunc := 'getSQLDriverSQLServer';
     //SQLDBDSN.Params.Add('DSN=Test');
     //SQLDBDSN.Params.Add('uid=sa');
     //SQLDBDSN.Params.Add('pwd=Mett0n1#');
     Memo1.Lines.Add( SQLDB.Params.Text );
     SQLDB.Open;



  Except
    on E : Exception do
    begin
      ShowMessage(E.Message);
      SQLQuery.Close;
    end;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  try
    SQLQuery := TSQLQuery.Create(nil);
    SQLQuery.SQLConnection := SQLDB;

    SQLQuery.SQL.Clear;
    SQLQuery.SQL.Add(Edit5.Text) ;
    SQLQuery.Open;
    SQLQuery.First;

        while not SQLQuery.Eof do
        begin
          With
           SQLQuery do
          begin
            Memo1.Lines.Add(FieldByName('servername').AsString)
          end;

          SQLQuery.Next;
        end;

    SQLQuery.Close;

  Except
    on E : Exception do
    begin
      ShowMessage(E.Message);
      SQLQuery.Close;
    end;
  end;
end;


end.
