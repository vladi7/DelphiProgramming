unit U_Ftp;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPServer, IdFTPList,
  StdCtrls, jpeg, ExtCtrls, Menus, ShellApi, IdFTPServer;
  
const
  LogName='LogFile.txt';
  Max_log_count=10;
  WM_NOTIFYTRAYICON = WM_USER + 1;

type
  TForm1 = class(TForm)
    IdFTPServer1: TIdFTPServer;
    Memo1: TMemo;
    Memo2: TMemo;
    Panel1: TPanel;
    Image1: TImage;
    Label1: TLabel;
    my_Pmenu : TpopupMenu;

   procedure IdFTPServer1AfterUserLogin(ASender: TIdFTPServerThread);
    procedure IdFTPServer1ChangeDirectory(ASender: TIdFTPServerThread;
      var VDirectory: String);
    procedure FormCreate(Sender: TObject);
    procedure IdFTPServer1DeleteFile(ASender: TIdFTPServerThread;
      const APathName: String);
    procedure IdFTPServer1GetFileSize(ASender: TIdFTPServerThread;
      const AFilename: String; var VFileSize: Int64);
    procedure IdFTPServer1MakeDirectory(ASender: TIdFTPServerThread;
      var VDirectory: String);
    procedure IdFTPServer1RemoveDirectory(ASender: TIdFTPServerThread;
      var VDirectory: String);
    procedure IdFTPServer1RenameFile(ASender: TIdFTPServerThread;
      const ARenameFromFile, ARenameToFile: String);
    procedure IdFTPServer1RetrieveFile(ASender: TIdFTPServerThread;
      const AFileName: String; var VStream: TStream);
    procedure IdFTPServer1StoreFile(ASender: TIdFTPServerThread;
      const AFileName: String; AAppend: Boolean; var VStream: TStream);
    procedure IdFTPServer1UserLogin(ASender: TIdFTPServerThread;
      const AUsername, APassword: String; var AAuthenticated: Boolean);
    procedure IdFTPServer1ListDirectory(ASender: TIdFTPServerThread;
      const APath: String; ADirectoryListing: TIdFTPListItems);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Main_popup_MenuClick(Sender: TObject);
    procedure m_exitClick(Sender: TObject);
    procedure IdFTPServer1Disconnect(AThread: TIdPeerThread);
    procedure IdFTPServer1Execute(AThread: TIdPeerThread);
    procedure IdFTPServer1Connect(AThread: TIdPeerThread);
  private
    function ReplaceChars(APath: String): String;
    function GetSizeOfFile(AFile : String) : Integer;
    { Private declarations }
  public
    procedure WMTRAYICONNOTIFY(var Msg: TMessage); message WM_NOTIFYTRAYICON;
    procedure WMNCLBUTTONDOWN(var msg: TMessage); message WM_NCLBUTTONDOWN;

    { Public declarations }
  end;

var
  Form1: TForm1;
  AppDir      : String;
  Flag_busy : boolean;

implementation
uses DateUtils;
{$R *.dfm}

Procedure Init_Tray(_Vid:integer;_Wnd:Thandle;_hicon:hicon;_mes:word;my_text : string);
 var
   pnid:TNOTIFYICONDATA;
   i : integer;
begin

pnid.Wnd:=_Wnd;
pnid.hIcon:=_hicon;
for i:=0 to 63 do pnid.szTip[i]:=#0;
for i:=0 to Length(my_text)-1 do pnid.szTip[i]:=my_text[i+1];
pnid.uFlags:=NIF_ICON or NIF_MESSAGE or NIF_TIP;
pnid.cbSize:=sizeof(pnid);
pnid.uCallbackMessage:= WM_NOTIFYTRAYICON;
pnid.uID:=1;
Shell_NotifyIcon(
     _Vid,	// message identifier
     @pnid	// pointer to structure
   );
end;{Init_Tray}

procedure TForm1.WMNCLBUTTONDOWN(var msg: TMessage);
begin
if msg.wParam = HTMINBUTTON then
begin
  Application.Minimize;
  ShowWindow(Application.Handle, SW_HIDE);
end;
inherited;
end;


procedure TForm1.WMTRAYICONNOTIFY(var Msg: TMessage);
var
foo: TPoint;
begin
  case Msg.LParam of
    WM_LBUTTONUP:
    begin
     ShowWindow(Application.Handle, SW_Restore);
     form1.Top:=top;
    end;

    WM_RBUTTONUP:
    begin
     GetCursorPos(foo);
     my_PMenu.Popup(foo.X-70,foo.Y);
    end
  end;
end;

Function Int64toDateTime(a : int64):TdateTime;
var
   vspom, days : int64;
   Times : real;
   lt : TSYSTEMTIME;
   st : TSYSTEMTIME;

begin
 GetSystemTime(st);
 GetLocalTime(lt);
 days:= a div 86400 div 10000000;
 vspom:=(a - days*86400*10000000);
 Times:=vspom/86400/10000000;
 Result:=EncodeDate(1601,1,1)+days+Times+
 EncodeDateTime(lt.wYear, lt.wMonth, lt.wDay, lt.wHour, lt.wMinute, lt.wSecond, lt.wMilliseconds)-
 EncodeDateTime(st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
// if Result<0 then Result:=Result-EncodeDate(1601,1,1)+EncodeDate(1884,6,2);

end;{Int64toDateTime}

Procedure __TimeDelaySet;
begin
// if Flag_busy then sleep(1000);
 Flag_busy:=True;
end;{__TimeDelaySet}

Procedure __TimeDelayReSet;
begin
// sleep(500);
 Flag_busy:=False;
end;{__TimeDelayReSet}

Procedure Add_to_Memo(__str : ansistring; Memo1 : Tmemo);
var
   __str1, __strs : ansistring;
begin
 __str1:=__str+' '+DateTimeToStr(Now);
 /////////////////////////////
 if Memo1.Lines.count>1000 then  Memo1.Lines.clear;
 Memo1.Lines.Add(__str1);
 Exit;
 /////////////////////////////
 if Memo1.Lines.count=Max_log_count then
   begin
    __strs:=Memo1.Lines.strings[Memo1.Lines.count-1];
    Memo1.Lines.Insert(0, __str1);
    Memo1.Lines.Insert(0, __strs);
    Memo1.Lines.Delete(Memo1.Lines.count-1);
    Memo1.Lines.Delete(Memo1.Lines.count-1);
   end {if}
 else Memo1.Lines.Add(__str1);
end;{Add_to_Memo}

function TForm1.ReplaceChars(APath:String):String;
var
 s:string;
begin
  s := StringReplace(APath, '/', '\', [rfReplaceAll]);
  s := StringReplace(s, '\\', '\', [rfReplaceAll]);
  s := StringReplace(s, '\\', '\', [rfReplaceAll]);
  s := StringReplace(s, '\\', '\', [rfReplaceAll]);
  s := StringReplace(s, '\\', '\', [rfReplaceAll]);
  Result := s;
end;

function TForm1.GetSizeOfFile(AFile : String) : Integer;
var
 FStream : TFileStream;
begin
  Try
    FStream := TFileStream.Create(AFile, fmOpenRead);
    Try
      Result := FStream.Size;
    Finally
      FreeAndNil(FStream);
    End;
  Except
    Result := 0;
  End;
end;

procedure TForm1.IdFTPServer1AfterUserLogin(ASender: TIdFTPServerThread);
begin
 //important - you really do need to set a currect directory it will drive
//some GUI FTP clients bonkers.
  ASender.CurrentDir := '/';
  ASender.HomeDir := '/';

end;

procedure TForm1.IdFTPServer1ChangeDirectory(ASender: TIdFTPServerThread;
  var VDirectory: String);
var Msg : String;
begin
  __TimeDelaySet;
   //Note that you really should have a way a way of preventing
  //a CWD command from accessing something higher than your intended hiearchy.
  //
  //That's a BIG security flaw that some attackers will exploit.
  //
  //You also should have a way of preventing the "VDirectory" from reflecting
  //your real computer directory structure.

  if  SysUtils.DirectoryExists(ReplaceChars(AppDir+'\'+VDirectory)) then
  begin
   Add_to_Memo('CD '+ReplaceChars(AppDir+'\'+VDirectory), Memo1);
  end
  else
  begin
    //You do NOT want to expose the directory name if an error happens.
    //Sometimes, that can tell a trouble maker quite a bit about your system.
    //On other hand, durring development, you probably want to know.
    Msg :=  VDirectory;
    VDirectory := ASender.CurrentDir;
//    raise Exception.Create('Directory '+Msg+' not found');
  end;
  __TimeDelayReSet;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 Flag_busy:=False;
 AppDir := ExtractFilePath(Application.Exename);
 Init_Tray(NIM_ADD,form1.Handle,Application.Icon.Handle,WM_NOTIFYTRAYICON,Application.Title);
 if not FileExists (AppDir+LogName) then Memo1.Lines.SaveToFile(AppDir+LogName)
 else Memo1.Lines.LoadFromFile(AppDir+LogName);
 IdFTPServer1.Active:=True;
end;

procedure TForm1.IdFTPServer1DeleteFile(ASender: TIdFTPServerThread;
  const APathName: String);
begin
  __TimeDelaySet;
   DeleteFile(ReplaceChars(AppDir+'\'+APathname));
   Add_to_Memo('DELETE '+ReplaceChars(AppDir+'\'+APathname), Memo1);
  __TimeDelayReSet;

end;

procedure TForm1.IdFTPServer1GetFileSize(ASender: TIdFTPServerThread;
  const AFilename: String; var VFileSize: Int64);
Var
 LFile : String;
begin
  //we return -1 for an error
  LFile := ReplaceChars( AppDir + AFilename );
  try
    If FileExists(LFile) then
      VFileSize :=  GetSizeOfFile(LFile)
    else
      VFileSize := -1;
    except
      VFileSize := -1;
   end;
end;


procedure TForm1.IdFTPServer1MakeDirectory(ASender: TIdFTPServerThread;
  var VDirectory: String);
begin
  __TimeDelaySet;
   if not ForceDirectories(ReplaceChars(AppDir+'\'+ VDirectory)) then
  begin
//    Raise Exception.Create('Unable to create directory');
  end
  else
  begin
   Add_to_Memo('MD '+ReplaceChars(AppDir+'\'+ VDirectory), Memo1);
  end;{else}
  __TimeDelayReSet;

end;

procedure TForm1.IdFTPServer1RemoveDirectory(ASender: TIdFTPServerThread;
  var VDirectory: String);
Var
 LFile : String;
begin
  __TimeDelaySet;
  LFile := ReplaceChars(AppDir+'\'+VDirectory);
  // You should delete the directory here.
  // TODO
  if not RemoveDir(LFile) then
  begin
//    Raise Exception.Create('Unable to remove directory');
  end
  else
    begin
     Add_to_Memo('RD '+ReplaceChars(AppDir+'\'+ VDirectory), Memo1);
    end;{else}
  __TimeDelayReSet;

end;

procedure TForm1.IdFTPServer1RenameFile(ASender: TIdFTPServerThread;
  const ARenameFromFile, ARenameToFile: String);
var
   __str : string;
begin
  __TimeDelaySet;
  __str:=Asender.CurrentDir;
//   SysUtils.RenameFile(ReplaceChars(AppDir+__str + '/'+ ARenameFromFile),ReplaceChars(AppDir+__str +'/'+ARenameToFile));
   CopyFile(Pchar(ReplaceChars(AppDir+__str + '/'+ ARenameFromFile)),Pchar(ReplaceChars(AppDir+__str +'/'+ARenameToFile)), False);
   DeleteFile(ReplaceChars(AppDir+__str + '/'+ ARenameFromFile));
   Add_to_Memo('RENAME '+ReplaceChars(AppDir +__str+ '/'+ ARenameFromFile)+' '+ReplaceChars(AppDir +__str+'/'+ARenameToFile), Memo1);
//   ASender.returnvalue:=226;
  __TimeDelayReSet;
end;

procedure TForm1.IdFTPServer1RetrieveFile(ASender: TIdFTPServerThread;
  const AFileName: String; var VStream: TStream);
begin
  __TimeDelaySet;
  VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmOpenRead);
  Add_to_Memo('RETRIEVE '+ReplaceChars(AppDir+AFilename), Memo1);
  __TimeDelayReSet;

end;

procedure TForm1.IdFTPServer1StoreFile(ASender: TIdFTPServerThread;
  const AFileName: String; AAppend: Boolean; var VStream: TStream);
begin
  __TimeDelaySet;
 if not Aappend then
 begin
   VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmCreate)
 end
 else
 begin
   VStream := TFileStream.Create(ReplaceChars(AppDir+AFilename),fmOpenWrite)
 end;
   Add_to_Memo('STORE '+ReplaceChars(AppDir+'\'+AFilename), Memo1);
  __TimeDelayReSet;

end;

procedure TForm1.IdFTPServer1UserLogin(ASender: TIdFTPServerThread;
  const AUsername, APassword: String; var AAuthenticated: Boolean);
begin
__TimeDelaySet;
  // We just set AAuthenticated to true so any username / password is accepted
 // You should check them here - AUsername and APassword
  AAuthenticated := False;
  if AUsername<>'BELKA' then Exit;
  if APassword<>'04102004' then Exit;
  AAuthenticated := True;
  Add_to_Memo('CONNECT '+AUsername, Memo1);
__TimeDelayReSet;

end;

procedure TForm1.IdFTPServer1ListDirectory(ASender: TIdFTPServerThread;
  const APath: String; ADirectoryListing: TIdFTPListItems);
var
 LFTPItem :TIdFTPListItem;
 SR : TSearchRec;
 SRI : Integer;
 LTmpPath : String;
 a1, a2 : Int64;

begin
 //You should at least honor the laT switches because are listed in the FEAT
 //reply.
 //

(*
  if Pos('s',ASwitches)>0 then
  begin
    ADirectoryListing.Switches := ADirectoryListing.Switches + 's';
  end;
*)
    // we do it this way because if a dir such as /pub is passed as a parameter,
    //You probably want the contents of it.
  __TimeDelaySet;
    LTmpPath := ReplaceChars(AppDir +ASender.HomeDir + APath);

    if DirectoryExists(LTmpPath) then
    begin
      LTmpPath := LTmpPath + '\*.*';
    end
    else
    begin
      LTmpPath := LTmpPath + '*.*';
    end;

  SRI := FindFirst(LTmpPath, faAnyFile , SR);// - faHidden - faSysFile, SR);

  While SRI = 0 do
  begin
    LFTPItem := ADirectoryListing.Add;
    LFTPItem.FileName := SR.Name;
    
    a1:= sr.FindData.ftLastWriteTime.dwLowDateTime;
    a2:=sr.FindData.ftLastWriteTime.dwHighDateTime;
    a2:=a2*65536;
    a2:=a2*65536;

    LFTPItem.ModifiedDate:=Int64toDateTime(a1+a2);
    //This is necessary because the Borland RTL FindData Size is an Integer and can't handle
    //anything greater than 2GB.
    LFTPItem.Size := Int64(SR.FindData.nFileSizeHigh shl 32) + SR.FindData.nFileSizeLow;
    //for Unix lists, you should get a block count.  In Win32 with CygWin, that's
    //the size of the file div 1024 and rounded up.
    //not only do need to support it with the -s switch but it's listed in the "total" header
    //in a Unix listing
    (*
    LFTPItem.NumberBlocks := LFTPItem.Size div 1024;
    if LFTPItem.Size mod 1024 > 0 then
    begin

      LFTPItem.NumberBlocks := LFTPItem.NumberBlocks + 1;
    end;
    *)
    //We don't use the DosDate from Borland's FindFirst, FindNext for two reasons:
    //1: We should be dealing with GMT time in all cases.  For Unix and WinNT style lists,
    //   it will be converted to LocalTime.
    //2: The Win32_FIND_DATA record has more information than simply the last modified date
    //   and the MLSD/MLST command permits us to return all of this in a standardized way.
    //   Indy can support a "Create", "Modified" and "windows.lastaccess" fact.
    //   For Linux, the POSIX filesystem, you would want to support only the Modified fact
    //   for file dates.
//    LFTPItem.ModifiedDateGMT := FileTimeToTDateTime( SR.FindData.ftLastWriteTime);
//    LFTPItem.CreationDateGMT := FileTimeToTDateTime( SR.FindData.ftCreationTime);
//    LFTPItem.LastAccessDateGMT := FileTimeToTDateTime( SR.FindData.ftLastAccessTime);
//    LFTPItem.WinAttribs := SR.FindData.dwFileAttributes;

      LFTPItem.ItemType   := ditFile;
      if (SR.Attr and faDirectory <> 0) then LFTPItem.ItemType   := ditDirectory
      else LFTPItem.ItemType   := ditFile;
    (*
    if SR.Attr and faDirectory > 0 then
    begin
      LFTPItem.ItemType   := ditDirectory;
      (*
      if SR.Attr and faReadOnly=faReadOnly then
      begin
        LFTPItem.UnixOwnerPermissions := 'r-x';
        LFTPItem.UnixGroupPermissions := 'r-x';
        LFTPItem.UnixOtherPermissions := 'r-x';
      end
      else
      begin
        LFTPItem.UnixOwnerPermissions := 'rwx';
        LFTPItem.UnixGroupPermissions := 'rwx';
        LFTPItem.UnixOtherPermissions := 'rwx';
      end;
    end
    else
    begin
      LFTPItem.ItemType   := ditFile;
      if SR.Attr and faReadOnly=faReadOnly then
      begin
        LFTPItem.UnixOwnerPermissions := 'r--';
        LFTPItem.UnixGroupPermissions := 'r--';
        LFTPItem.UnixOtherPermissions := 'r--';
      end
      else
      begin
        LFTPItem.UnixOwnerPermissions := 'rw-';
        LFTPItem.UnixGroupPermissions := 'rw-';
        LFTPItem.UnixOtherPermissions := 'rw-';
      end;
    end;
      *)

    SRI := FindNext(SR);
  end;
  FindClose(SR);
  __TimeDelayReSet;
//  SetCurrentDir(AppDir + APath + '\..');
 Add_to_Memo('Read Directory '+LTmpPath, Memo1);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if MessageDlg('Are You sure?',mtconfirmation,[mbYes, mbNo],0)<>mrYes then
  begin
   Application.Minimize;
   ShowWindow(Application.Handle, SW_HIDE);
   Action:=CaNone;
   Exit;
  end;
 Memo1.Lines.SaveToFile(AppDir+LogName);
 try
 IdFTPServer1.Active:=False;
 except
 end;
end;

procedure TForm1.Main_popup_MenuClick(Sender: TObject);
begin
   ShowWindow(Application.Handle, SW_restore);
end;

procedure TForm1.m_exitClick(Sender: TObject);
begin
 Close;
end;

procedure TForm1.IdFTPServer1Disconnect(AThread: TIdPeerThread);
begin
 __TimeDelayReSet;
end;

procedure TForm1.IdFTPServer1Execute(AThread: TIdPeerThread);

begin
   if AThread=Nil then Exit;
end;

procedure TForm1.IdFTPServer1Connect(AThread: TIdPeerThread);
var
   i : integer;
begin
 if i=0 then;
end;

end.

