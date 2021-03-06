unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdHTTP, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdServerIOHandler, IdSSLOpenSSL, Sockets, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStream, IdIOHandlerThrottle;

type
  TForm1 = class(TForm)
    Button1: TButton;
    IdHTTP1: TIdHTTP;
    Button2: TButton;
    __httpcl: TTcpClient;
    Button3: TButton;
    IdTCPClient1: TIdTCPClient;
    IdSSLIOHandlerSocket2: TIdSSLIOHandlerSocket;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
   buffer : array[0..10000000] of byte;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  __tsl : TstringList;
  Fnames, Fnamed : ansistring;
begin
    Fnames:=ExtractFilepath(Application.exename)+'request.txt';
    Fnamed:=ExtractFilepath(Application.exename)+'result.txt';
    if not FileExists(Fnames) then Halt(0);
    __Tsl:=TstringList.Create;
    __Tsl.LoadFromFile(Fnames);
//    idhttp1.IOHandler := TIdSSLIOHandlerSocket.Create(idhttp1);
    try
    With {TIdHTTP.Create(Nil)}idhttp1 do __Tsl.strings[0]:=get(__Tsl.strings[0]);
    except
      __tsl.clear;
      __tsl.Add('ERROR');
    end;
    __Tsl.SaveToFile(Fnamed);
    __Tsl.Destroy;
    Halt(0);
end;


(*    HTTPHeader :=
      'GET / HTTP/1.0' + CRLF +
      'Host: ' + Host + ':443' + CRLF +
      'Keep-Alive: 300' + CRLF +
      'Connection: keep-alive' + CRLF +
      'User-Agent: Mozilla/4.0' + CRLF + CRLF;

*)




procedure TForm1.Button2Click(Sender: TObject);


function HTTPGetText(Host : ansistring): ansistring;
var
   HTTPHeader, HTTPReader : ansistring;
begin
    __httpcl.RemoteHost:=Host;
    __httpcl.RemotePort:='443';
    __httpcl.Connect;
    HTTPHeader :=
      'GET / HTTP/1.1' + CRLF +
      'Host: ' + Host + ':443' + CRLF +
      'Keep-Alive: 300' + CRLF +
      'Connection: keep-alive' + CRLF +
      'User-Agent: Mozilla/3.0' + CRLF + CRLF;
    HTTPHeader :=
      'GET /esta/ HTTP/1.1' + CRLF +
      'Host: ' + Host + ':443' + CRLF +
      'Accept: text/html, */*'+ CRLF +
      'Accept-Encoding: identity'+ CRLF +
      'User-Agent: Mozilla/3.0' + CRLF + CRLF;
    __httpcl.Sendln(HTTPHeader);
//    __httpcl.ReceiveBuf(buffer, 100000);
    HTTPReader:=__httpcl.receiveln;
    if HTTPReader='' then;
    __httpcl.disConnect;
end;{HTTPGetText}

begin
  HTTPGetText('esta.cbp.dhs.gov');
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  s: String;
begin
//IdTCPClient1.Host := 'https://www.esta.cbp.dhs.gov/esta/';
IdTCPClient1.Host := 'tut.by';
  IdTCPClient1.Port := 443;
  IdTCPClient1.Connect;
  IdTCPClient1.WriteLn('GET / HTTP/1.1');
  IdTCPClient1.WriteLn('Host: tut.by');
  IdTCPClient1.WriteLn('');
  // Retrieve all the data until the server closes the connection
  s := IdTCPClient1.AllData;
  if s='' then;
//  Memo1.Lines.Add(s);
end;

end.
