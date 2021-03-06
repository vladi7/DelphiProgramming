unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, Spin, ComObj, types;

type
  TForm1 = class(TForm)
    __spin: TSpinEdit;
    Label1: TLabel;
    __grid: TStringGrid;
    Button1: TButton;
    Button2: TButton;
    __Rgrid: TStringGrid;
    Button3: TButton;
    procedure __spinChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure __RgridDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  __mas, __masoper : array [1..1000,1..1000] of real;
  Order : integer;

implementation

{$R *.dfm}

procedure TForm1.__spinChange(Sender: TObject);
begin
 Order:=__spin.Value;
 __grid.RowCount:=Order;
 __grid.ColCount:=Order+1;
 __Rgrid.RowCount:=Order;
 __Rgrid.ColCount:=Order+1;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 __spinChange(nil);
end;

Function __preobr(__str : ansistring):real;
begin
 if Pos('.',__str)>0 then __str[Pos('.',__str)]:=',';
 try
   Result:=StrToFloat(__str);
 except
   Result:=0;
 end;
end;{__preobr}

Procedure assign_grid_to_array;
var
   i, j : integer;
begin
 with Form1 do
 for i:=0 to Order do
   for j:=0 to Order-1 do
    begin
     __mas[i+1,j+1]:=__preobr(__grid.cells[i,j]);
     __masoper[i+1,j+1]:=__preobr(__grid.cells[i,j]);
    end;
end;{assign_grid_to_array}


Procedure assign_array_to_grid(__grid:Tstringgrid);
var
   i, j : integer;
begin
 for i:=0 to Order do
   for j:=0 to Order-1 do
      begin
        if i<Order then  __grid.cells[i,j]:=floattostr(__mas[i+1,j+1])+'*'+floattostr(__masoper[Order+1,i+1])
        else __grid.cells[i,j]:='    ='+floattostr(__mas[i+1,j+1]);
      end;{with for for}
 __grid.repaint;
 __grid.setfocus;
end;{assign_array_to_grid}


Procedure __change(a, b : integer);
var
   i : integer;
   __r : real;
begin
   for i:=1 to order+1 do
     begin
       __r:=__masoper[i,a];
       __masoper[i,a]:=__masoper[i,b];
       __masoper[i,b]:=__r;
     end;{for}
end;{__change}

Function __simplex(re : integer):boolean;
var
   i, j : integer;
begin
 Result:=False;
 if __masoper[re,re]=0 then Exit;
 for i:=1 to Order+1 do
   for j:=1 to Order do
    if (i<>re) and (j<>re) then
     begin
      __masoper[i,j]:=(__masoper[i,j]*__masoper[re,re]-__masoper[i,re]*__masoper[re,j])/__masoper[re,re];
     end;{for}
 for i:=1 to Order+1 do if (i<>re) then __masoper[i,re]:=__masoper[i,re]/__masoper[re,re];
 for j:=1 to Order do __masoper[re,j]:=0;
 __masoper[re,re]:=1;
 Result:=True;
end;{__simplex}

Function Solver:boolean;
var
   i, j : integer;
begin
  Result:=False;
  for j:=1 to order do
    begin
      i:=j;
      while not __simplex(i) do
       begin
        if (i+1)> order then Exit;
        __change(i, i+1);
        inc(i);
       end;{while}
    end;
  Result:=True;
  assign_array_to_grid(form1.__Rgrid);
end;{Solver}


procedure TForm1.Button1Click(Sender: TObject);
begin
 assign_grid_to_array;
 if not Solver  then ShowMessage('Error!');
end;

Procedure out_to_excel(__grid : Tstringgrid);
var
  v : variant;
  i,  j, SheetOffsRow : integer;
  __s1, fname : ansistring;

begin
 V:=CreateOleObject('excel.sheet');
 v.saved:=true;
 v.Application.DisplayAlerts:= False;
 fname:=Extractfilepath(Application.exename)+'Noname.xls';
 DeleteFile(fname);
 V.application.sheets[1].activate;
 SheetOffsRow:=2;
 for i:=0 to Order do
   for j:=0 to Order-1 do
    begin
         __s1:=char(ord('B')+i)+inttostr(j+SheetOffsRow);
         if i>=26 then __s1:=char(ord('A')+(i div 26)-1)+char(ord('B')+(i mod 26))+inttostr(j+SheetOffsRow);
         V.application.Range[__s1].Select;
         V.application.selection:=__grid.Cells[i,j];
    end;
 V.Saveas(fname{,18});
 V.application.Quit;
 V:=CreateOleObject('excel.sheet');
 V.application.visible:=true;
 V.application.Workbooks.open(fname);
end;{out_to_excel}

Procedure from_excel_to_grid(__grid : Tstringgrid);
var
    Excel : Variant;
    i,  j, SheetOffsRow : integer;
    __s1 : ansistring;
begin
 Excel:=CreateOleObject('Excel.Application');
 Excel.Visible:=False;
 Excel.WorkBooks.Open(ExtractFilePath(Application.ExeName)+'1.xls');
 SheetOffsRow:=2;
 for i:=0 to Order do
   for j:=0 to Order-1 do
    begin
         __s1:=char(ord('B')+i)+inttostr(j+SheetOffsRow);
         if i>=26 then __s1:=char(ord('A')+(i div 26)-1)+char(ord('B')+(i mod 26))+inttostr(j+SheetOffsRow);
         Excel.application.Range[__s1].Select;
         __grid.Cells[i,j]:=Excel.application.selection;
    end;
 Excel.quit;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 out_to_excel(__rgrid);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  from_excel_to_grid(__grid);
end;

procedure TForm1.__RgridDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  __str : ansistring;
  __str1, __str2, __str3 : ansistring;
  Rect1, Rect2, Rect3 : Trect;
begin
  with __Rgrid do
    begin
      __str:=cells[Acol, Arow];
      if Pos('*',__str)>0 then
       begin
          canvas.brush.color:=clyellow;
          canvas.Font.style:=canvas.Font.style+[fsbold];
          __str1:=Copy(__str, 1, Pos('*',__str)-1);
          __str2:='x';
          Delete(__str, 1, Length(__str1)+Length(__str2));
          __str3:=__str;
//          __str1:='abc'+inttostr(Arow);
          Canvas.fillrect(rect);

          Rect1.Left:=Rect.Left;
          Rect1.Top:=Rect.Top;
          Rect1.Right:=Rect1.Left+canvas.TextWidth(__str1)+5;
          Rect1.Bottom:=Rect.Bottom;
          Canvas.Pen.Color:=clblack;
          Canvas.font.Color:=clblack;
          Canvas.TextRect(Rect1,Rect1.Left,Rect1.top,__str1);

          Rect2.Left:=Rect1.right+2;
          Rect2.Top:=Rect1.Top+2;
          Rect2.Right:=Rect2.Left+canvas.TextWidth(__str2)+5;
          Rect2.Bottom:=Rect1.Bottom-2;
          Canvas.Pen.Color:=clred;
          Canvas.font.Color:=clgreen;
          Canvas.Rectangle(Rect2.Left-1,Rect2.Top-1,Rect2.Right+1,Rect2.Bottom+1);
          Canvas.TextRect(Rect2,Rect2.Left,Rect2.top-1,__str2);

          Rect3.Left:=Rect2.right+2;
          Rect3.Top:=Rect1.Top+2;
          Rect3.Right:=Rect3.Left+canvas.TextWidth(__str3)+5;
          Rect3.Bottom:=Rect1.Bottom-2;
          Canvas.Pen.Color:=clred;
          Canvas.font.Color:=clblue;
          //Canvas.Rectangle(Rect3.Left-1,Rect3.Top-1,Rect3.Right+1,Rect3.Bottom+1);
          Canvas.TextRect(Rect3,Rect3.Left,Rect3.top-1,__str3);

       end;{if}
      if Pos('=',__str)>0 then
       begin
          canvas.brush.color:=clgreen;
          canvas.Font.style:=canvas.Font.style+[fsbold];
          __str1:=__str;
          Canvas.fillrect(rect);

          Rect1.Left:=Rect.Left;
          Rect1.Top:=Rect.Top;
          Rect1.Right:=Rect1.Left+canvas.TextWidth(__str1)+5;
          Rect1.Bottom:=Rect.Bottom;
          Canvas.Pen.Color:=clblack;
          Canvas.font.Color:=clblack;
          Canvas.TextRect(Rect1,Rect1.Left,Rect1.top,__str1);
       end;{if}
    end;{with}
end;

end.
