unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdUDPServer, XPMan, IdBaseComponent, IdComponent, IdUDPBase,
  IdUDPClient, StdCtrls, IdSocketHandle;

type
  TMainForm = class(TForm)
    UDPClient: TIdUDPClient;
    UDPServer: TIdUDPServer;
    GroupText: TGroupBox;
    FileGroup: TGroupBox;
    SendEdit: TEdit;
    SendBtn: TButton;
    Memo: TMemo;
    SendFileBtn: TButton;
    FileEdit: TEdit;
    SetFile: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure SetFileClick(Sender: TObject);
    procedure SendBtnClick(Sender: TObject);
    procedure UDPServerUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure SendFileBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

(***************** ������ �� ������� ������� **********************************)

procedure TMainForm.FormCreate(Sender: TObject);
var
 s: string;
begin
  // ����� �� ������ ������ IP �����, �� ��������� ����� "localhost", ��� ��� ����
  // �� �� ���� �� ������, �� �������� ����� �������� ���� � �����, �� � ����
  // ������, �� ��������� ����������� � ������� �� ��������� ����������
  // ���������� ����� ����� ���������, ��� �������� �����������������
  if InputQuery('���������-������ �� UDP',
  '������� IP ����� ��������� ������, ����� ������ ������������� ���� � ����� :)',s)=true then
  UDPClient.Host:=s;
end;


procedure TMainForm.SetFileClick(Sender: TObject);
begin
  // ����� ������ ��������� ���� ��� ��������
  if OpenDialog.Execute then  FileEdit.Text:=OpenDialog.FileName;
end;

procedure TMainForm.SendBtnClick(Sender: TObject);
begin
  // ����� ������ ���������� ��������� ���������
  UDPClient.Send('text'+SendEdit.Text);
  SendEdit.Clear;
end;

procedure TMainForm.SendFileBtnClick(Sender: TObject);
var
  MemStream  : TMemoryStream;
begin
  // ����� ���������� ����
  // ������� ����� � ������
  MemStream:= TMemoryStream.Create;
  // ��������� ���� � ��� �����
  MemStream.LoadFromFile(FileEdit.Text);
  //

  // ���������� ��� �����
  UDPClient.SendBuffer(MemStream.Memory^,MemStream.Size);
  // ����������� ������
  MemStream.Free;
end;

(***************** ������ �� ������� ������� **********************************)

procedure TMainForm.UDPServerUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  // ��������� 2 ������, ���� ��� �����, ������ ��� ����� ������ ����������
  // � ����� ������ ��� ������ (��� �� ����� ���������� ��� ������)
  StrStream  : TStringStream;
  MemStream  : TMemoryStream;
begin
  // ����� ���������� ��������� ������ ��������� �� �������
  // �� ������ ����� ���� ��������� ���������� �����, ��� ��� ������� �� 255
  // � ������ ������� (����������� ����������� ��������� ����������) , � ���
  // ������ 255, �� ��� ��� ����, �� ����� ���� � ���� ����� ������ 255,
  // ��� ������� �������� �� ����� ����, ��� ��� ��������� ������� ��� (��� ����) :)
  if AData.Size<=255 then
  begin
    // ���� � ��� ������ �����, �������� � ������� �����
    // ������� ��������� �����
    StrStream:=TStringStream.Create('');
    // ������ ������ � ���� ����� �� ���������� ������
    StrStream.CopyFrom(AData, AData.Size);
    // ��������� ������ � ��������, �������� ����� ���� �� ���� ���� �����
    Memo.Lines.Add(ABinding.PeerIP+': '+copy(StrStream.DataString,5,length(StrStream.DataString)));
    // ����������� ������
    StrStream.Free;
  end else
  begin
    // ���� � ��� ������ ����, �������� � ������� � ������
    MemStream:= TMemoryStream.Create;
    // ��������� ���� � ��� �����
    MemStream.CopyFrom(AData, AData.Size);
    // ������� ������ ���������� �����
    if SaveDialog.Execute then MemStream.SaveToFile(SaveDialog.FileName);
    // ����������� ������
    MemStream.Free;
  end;
end;


end.
