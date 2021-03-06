unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdExplicitTLSClientServerBase,
  IdMessageClient, IdPOP3, IdMessage, Idmessagecollection, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdIMAP4;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure b1click111(Sender: TObject);
   private
    { Private declarations }
  public
procedure Log( LogMsg: string );
    { Public declarations }
  end;


var
  Form1: TForm1;
  b1 : Tbutton;
 implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  MsgCount : Integer;
  i        : Integer;
  FMailMessage :  TIdMessage;
  OpenSSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  IdPOP31 : TIdPOP3;
begin
  IdPOP31:=TIdPOP3.Create(Nil);
  OpenSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create( nil );
  OpenSSLHandler.SSLOptions.Method := sslvSSLv3;
  IdPOP31.IOHandler := OpenSSLHandler;
  IdPOP31.UseTLS := utUseImplicitTLS;
  Memo1.Lines.Clear;
  //The IdPop31 is on the form so it is constructing when the
  //form is created and so is Memo1.
  IdPOP31.Host      := 'pop.yandex.com'; //Setting the HostName;
  IdPOP31.Username  := 'vladarkad7@yandex.com';//Setting UserName;
  IdPOP31.Password  := '011168a011168';//Setting Password;
  IdPOP31.Port      := 995;//Setting Port;

  IdPOP31.Host      := 'pop.yandex.ru'; //Setting the HostName;
  IdPOP31.Username  := 'arcad1968@tut.by';//Setting UserName;
  IdPOP31.Password  := '011168a011168';//Setting Password;
  IdPOP31.Port      := 995;//Setting Port;
// IDpop31.login;
  try
    IdPOP31.Connect();
   //Getting the number of the messages that server has.
    MsgCount := IdPOP31.CheckMessages;
    for i:= 0 to Pred(MsgCount) do
    begin
      try
        FMailMessage := TIdMessage.Create(nil);
        IdPOP31.Retrieve(i,FMailMessage);
        Memo1.Lines.Add('=================================================');
        Memo1.Lines.Add(FMailMessage.From.Address);
        Memo1.Lines.Add(FMailMessage.Recipients.EMailAddresses);
        Memo1.Lines.Add(FMailMessage.Subject);
        Memo1.Lines.Add(FMailMessage.Sender.Address);
        Memo1.Lines.Add(FMailMessage.Body.Text);
        Memo1.Lines.Add('=================================================');
      finally
        FMailMessage.Free;
      end;
    end;
  finally
    IdPOP31.Disconnect;
  end;
  IdPOP31.free;
  OpenSSLHandler.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  IMAPClient: TIdIMAP4;
  UsersFolders: TStringList;
  OpenSSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  res: Boolean;
  i: integer;
  inbox, currUID: string;
  cntMsg: integer;
  msg, msg2: TIdMessage;
  BodyTexts: TStringList;
  flags: TIdMessageFlagsSet;
  fileName_MailSource, TmpFolder: string;
begin
  Memo1.Lines.Clear;

  IMAPClient := TIdIMAP4.Create( nil );
  try
    OpenSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create( nil );
    try
  IMAPClient.Host      := 'imap.yandex.com'; //Setting the HostName;
  IMAPClient.Username  := 'vladarkad7@yandex.com';//Setting UserName;
  IMAPClient.Password  := '011168a011168';//Setting Password;
  IMAPClient.Port      := 993;//Setting Port;

      if (Pos( 'gmail.com', IMAPClient.Host ) > 0) or true then begin
        OpenSSLHandler.SSLOptions.Method := sslvSSLv3;
        IMAPClient.IOHandler := OpenSSLHandler;
        IMAPClient.UseTLS := utUseImplicitTLS;
      end;

      try
        res := IMAPClient.Connect;
        if not res then begin
          Log( '  Unsuccessful connection.' );
          exit;
        end;

      except
        on e: Exception do begin
          Log( '   Unsuccessful connection.' );
          Log( '  (' + Trim( e.Message ) + ')' );
          exit;
        end;
      end;

      try
        UsersFolders := TStringList.Create;
        try
          res := IMAPClient.ListMailBoxes( UsersFolders );
          if not res then begin
            Log( '  ListMailBoxes error.' );
            exit
          end;
        except
          on e: Exception do begin
            Log( '  ListMailBoxes error.' );
            Log( '  (' + Trim( e.Message ) + ')' );
            exit;
          end;

        end;

        Log( 'User folders: ' + IntToStr( UsersFolders.Count ) );
        for i := 0 to UsersFolders.Count - 1 do begin
          Log( '  [' + inttostr( i + 1 ) + '/' + inttostr( UsersFolders.Count ) + '] Folder: "' + UsersFolders[ i ] + '"' );
        end;

        IMAPClient.RetrieveOnSelect := rsDisabled;
        inbox := 'INBOX';
        Log( 'Opening folder "' + inbox + '"...' );
        res := IMAPClient.SelectMailBox( inbox );
        cntMsg := IMAPClient.MailBox.TotalMsgs;
        Log( 'E-mails to read: ' + IntToStr( cntMsg ) );

    //    res := IMAPClient.RetrieveAllEnvelopes( AMsgList );

        msg := TIdMessage.Create( nil );
        msg2 := TIdMessage.Create( nil );
        BodyTexts := TStringList.Create;
        TmpFolder := 'c:\';
        TmpFolder := ExtractFilePath(application.ExeName);
        res := IMAPClient.CreateMailBox( 'Temp2' );
        try

          for I := 0 to cntMsg - 1 do begin

            Log( '  [' + inttostr( i + 1 ) + '/' + inttostr( cntMsg ) + '] E-mail...' );

            IMAPClient.GetUID( i + 1, currUID );

            Log( '(Downloading message...)' );
            IMAPClient.UIDRetrieve( currUID, msg );

            fileName_MailSource := TmpFolder + 'Log_Mail_' + currUID + '.eml';
            msg.SaveToFile( fileName_MailSource, false );

            // In the final version I will delete the original message
            // so I have to recreate it from the archived file

            msg2.LoadFromFile( fileName_MailSource );

            res := IMAPClient.AppendMsg( 'Temp2', msg2, msg2.Headers, [] );
          end;
        finally
          FreeAndNil( msg );
          FreeAndNil( msg2 );
          FreeAndNil( BodyTexts )
        end;

      finally
        IMAPClient.Disconnect;
      end;
    finally
      OpenSSLHandler.Free;
    end;
  finally
    IMAPClient.Free;
  end;
end;

 procedure TForm1.b1click111(Sender: TObject);
 begin
   showmessage('hello!');
 end;
 procedure TForm1.FormCreate(Sender: TObject);
begin

  b1:=Tbutton.Create(Form1);
  b1.Parent:=Form1;
  b1.Top:=button2.Top+button2.Height+10;
  b1.left:=button2.left;
  b1.Caption:='New button';
  b1.OnClick:=form1.b1click111;
  b1.Show;
end;

procedure TForm1.Log( LogMsg: string );
begin
  memo1.Lines.Add( LogMsg );
  Application.ProcessMessages;
end;

end.
