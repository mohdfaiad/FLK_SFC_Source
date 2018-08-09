unit Login;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, DBClient, MConnect, SConnect, ObjBrkr,IniFiles;

type
  TfLogin = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    edtUser: TEdit;
    edtPwd: TEdit;
    Button1: TButton;
    Button2: TButton;
    SimpleObjectBroker1: TSimpleObjectBroker;
    SocketConnection1: TSocketConnection;
    qrytemp: TClientDataSet;
    sproc: TClientDataSet;
    ClientDataSet1: TClientDataSet;
    ClientDataSet2: TClientDataSet;
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure edtPwdKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
    IsStart:boolean;
    C_LINEID,C_STAGEID,C_PROCESSID,C_TERMINALID:string;
    Function LoadApServer : Boolean;
  end;
  //function SajetTransData(f_iCommandNo : integer;f_pData,f_pLen : pointer) : byte; stdcall; external 'SajetConnect.dll';
  //function SajetTransStart : boolean; stdcall;external 'SajetConnect.dll';
  //function SajetTransClose : boolean; stdcall;external 'SajetConnect.dll';

var
  fLogin: TfLogin;

implementation

{$R *.dfm}
uses uMain;

Function TfLogin.LoadApServer : Boolean;
Var F : TextFile;
    S : String;
begin
  Result := False;
  SocketConnection1.Connected := False;
  SimpleObjectBroker1.Servers.Clear;
  If not FileExists(GetCurrentDir+'\ApServer.cfg') Then
     Exit;
  AssignFile(F,GetCurrentDir+'\ApServer.cfg');
  Reset(F);
  While True do
  begin
    Readln(F, S);
    If S <> '' Then
    begin
      SimpleObjectBroker1.Servers.Add;
      SimpleObjectBroker1.Servers[SimpleObjectBroker1.Servers.Count-1].ComputerName := Trim(S);
      SimpleObjectBroker1.Servers[SimpleObjectBroker1.Servers.Count-1].Enabled := True;
    end Else
      Break;
  end;
  CloseFile(F);
  Result := True;
end;



procedure TfLogin.FormShow(Sender: TObject);
var  CFgIniFile:TIniFile;
begin
     CFgIniFile:=TIniFile.Create(ExtractFilePath(Application.ExeName)+'SFCS_ConFig.Ini');
     C_TERMINALID:=CFGIniFile.ReadString('Settings','TerminalID','');
     CFgIniFile.Free;
     if  C_TERMINALID ='' then
     begin
         MessageDlg('Not Set Terminal ID,Please Check SFCS_ConFig.Ini',mtError,[mbYes],0 ) ;
         Application.Terminate;
         Exit;
     end;
     LoadApServer ;

     with fLogin.qrytemp do
     begin
         Close;
         Params.Clear;
         Params.CreateParam(ftString,'iTerminal',ptInput);
         CommandText :='SELECT * FROM SAJET.SYS_TERMINAL WHERE TERMINAL_ID =:iTerminal';
         Params.ParamByName('iTerminal').AsString := C_TERMINALID;
         Open;
         if IsEmpty then  begin
             MessageDlg('Error Terminal ID,Please Check SFCS_ConFig.Ini',mtError,[mbYes],0 ) ;
             Application.Terminate;
              Exit;
         end;

         C_LINEID := fieldbyname('PDLINE_ID').AsString;
         C_STAGEID :=  fieldbyname('STAGE_ID').AsString;
         C_PROCESSID := fieldbyname('PROCESS_ID').AsString;

     end;

end;

procedure TfLogin.Button2Click(Sender: TObject);
begin
    Application.Terminate;
end;

procedure TfLogin.Button1Click(Sender: TObject);
var sData ,sSendData: string;
    fMain :TFmain;
begin

    with Qrytemp   do
    begin
        Close;
        Params.Clear;
        Params.CreateParam(ftstring,'user_no',ptInput);
        CommandText :='SELECT SAJET.PASSWORD.decrypt(PASSWD) myPwd FROM SAJET.SYS_EMP WHERE EMP_NO =:user_no';
        Params.ParamByName('user_no').AsString :=edtUser.Text;
        Open;

        if IsEmpty then begin
           MessageDlg('Login Fail,User No error ',mtError,[mbOK],0);
           exit;
        end;

        if edtPwd.Text  <>  trim( FieldByName('myPwd').AsString) then
        begin
            MessageDlg('Login Fail,Pwd  error :'+ FieldByName('myPwd').AsString ,mtError,[mbOK],0);
            exit;
        end;
    end;

    fMain :=TfMain.Create(self);
    fMain.Show;
    fLogin.Hide;

end;

procedure TfLogin.edtPwdKeyPress(Sender: TObject; var Key: Char);
begin
  if Key =#13 then begin
     Button1.Click; 
  end;
end;

end.