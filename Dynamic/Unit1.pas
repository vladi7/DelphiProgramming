unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, StdCtrls, CheckLst, ExtCtrls, TeEngine, Series, TeeProcs,
  Chart;

type
  TForm1 = class(TForm)
    __grid: TStringGrid;
    Button1: TButton;
    __chk: TCheckListBox;
    Timer1: TTimer;
    Label1: TLabel;
    Button2: TButton;
    Chart1: TChart;
    Series1: TLineSeries;
    Series2: TLineSeries;
    Series3: TLineSeries;
    Series4: TLineSeries;
    Series5: TLineSeries;
    Series6: TLineSeries;
    Series7: TLineSeries;
    Series8: TLineSeries;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Procedure output_grid_graph;
    function calcul_mask:word;

  end;

var
  Form1: TForm1;

implementation

uses Unit_data, U_thread;
var
   potok : Tcalcthread;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
   i, j : integer;
begin
 Label1.Caption:='';
 with __chk do
   begin
    items.Clear;
    for i:=1 to 8 do items.add('����� '+inttostr(i));
    for i:=1 to 8 do
      begin
       checked[i-1]:=True;
       ItemEnabled[i-1]:=True;
      end;{for}
    Columns:=8;
   end;{if}
 with __grid do
   begin
    cells[0,0]:='��������';
    rowcount:=__max*16+1;
    for i:=1 to colcount-1 do
      begin
       colwidths[i]:=96;
       if i<colcount-1 then cells[i,0]:=format('%20s',['����� '+inttostr(i)])
       else cells[i,0]:=format('%20s',['���������']);
      end;
    for j:=1 to rowcount-1 do cells[0,j]:=format('%7d',[j]);
   end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 label1.caption:='';
 potok:=Tcalcthread.create(True);
 potok.flag_t:=false;
// potok.resume;
// while not potok.flag_t do;
 GLobal_optimization;
 output_grid_graph;
 potok.Free;
end;

procedure TForm1.output_grid_graph;
var
  i, j : integer;
  a : real;
begin
    a:=-2e38;
    for i:=1 to __grid.colcount-2 do
      begin
       chart1.Series[i-1].Clear;
       chart1.Series[i-1].Title:=__grid.Cells[i,0];
      end;{for}

    for i:=1 to __grid.colcount-2 do
     if __chk.Checked[i-1] then __grid.Colwidths[i]:=96
     else __grid.Colwidths[i]:=-1;
    for j:=1 to __min-1 do __grid.rowheights[j]:=-1;
    for j:=__min to __max*16 do
      if result_massiv._data[j].mask<>0 then
       begin
        __grid.rowheights[j]:=__grid.DefaultRowHeight;
        for i:=1 to __grid.colcount-2 do
         begin
           if result_massiv._data[j]._nagr[i]>0 then
           begin
             __grid.Cells[i,j]:=
             format('%20s',
           [
inttostr(result_massiv._data[j]._nagr[i])+', B=('+inttostr(result_massiv._data[j]._topl[i])+')'
           ]
             );
           chart1.Series[i-1].AddXY(j, result_massiv._data[j]._nagr[i]);
           if result_massiv._data[j]._nagr[i]>a then a:=result_massiv._data[j]._nagr[i];
           end{if}
           else
             begin
               __grid.Cells[i,j]:='';
               chart1.Series[i-1].AddXY(j, 0);
             end;
         end;{for i}
        __grid.Cells[__grid.colcount-1,j]:=
          format('%16.4f',[result_massiv._data[j].sum_topl/1000]);
       end {for if}
      else
          __grid.rowheights[j]:=-1;
 if resinfo.__time=0 then resinfo.__time:=1e-4/86400;
 Label1.Caption:=
 'Iterations: '+
 format('%10.4e',[resinfo.iterations])+
 '; '+
 'General time: '+
 format('%8.4f',[resinfo.__time*86400])+
 ' sec; '+
 'Power: '+
 format('%8.4f',[resinfo.iterations/(resinfo.__time*86400)*1e-9])+
 ' oper/nsec; '+
 'Iteration time : '+
 format('%8.4f',[(resinfo.__time*86400)/resinfo.iterations*1e9])+
 ' nsec.';
 chart1.LeftAxis.AutomaticMaximum:=False;
 chart1.LeftAxis.Maximum:=1.1*a;
end;

function TForm1.calcul_mask: word;
var
  i : integer;
begin
 Result:=0;
 for i:=0 to __chk.Count-1 do
   if __chk.Checked[i] then   Result:=Result+Num_to_Un(i+1);

end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
 general_mask:=calcul_mask;
 Button1.Enabled:=not (general_mask=0);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 label1.caption:='';
 perebor;
 output_grid_graph;

end;

end.
