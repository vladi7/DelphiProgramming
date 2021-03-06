unit Unit_data;

interface
uses SysUtils;
const
__multipl=1;
__min=50*__multipl;
__max=2*__min;
Max_integer=1000000000;

type
   trextract=record
    one, two : word;
   end;{trextract}

   telementtype=record
    mask : word;
    _topl : array[1..16] of integer;
    _nagr : array[1..16] of integer;
    sum_topl : integer;
   end;{telementtype}

   trmassivtype=record
    _data : array [__min*0..__max*16] of telementtype;
   end;{trmassivtype}

   tresultinfo=record
    iterations : double;
    __time : TdateTime;
   end;{tresultinfo}

  Procedure GLobal_optimization;
  function Num_to_Un(a:word):word;
  procedure perebor;

var
   result_massiv : trmassivtype;
   general_mask : word;
   resinfo : tresultinfo;
implementation

var
   oper_mask : trextract;
   dec_massiv : array[1..256] of trmassivtype;
   iters : double;

   Function __topl(vid : integer; x : real):integer;
   begin
     Result:=0;
     x:=x/__multipl;
     case vid of
       1 : Result:=Round(-1.3593E-02*x*sqr(x) + 3.5524E+00*x*x - 1.5115E+02*x + 8.6706E+03);
       2 : Result:=Round(-1.8354E-03*x*sqr(x) + 6.9561E-01*x*x + 8.1260E+01*x + 2.4491E+03);
       3 : Result:=Round(8.0685E-04*x*sqr(x) + 2.0774E-01*x*x + 1.0639E+02*x + 2.1748E+03);
       4 : Result:=Round(2.8613E-03*x*sqr(x) - 1.7243E-01*x*x + 1.2553E+02*x + 2.0034E+03);

     end;{case}
   end;{__topl}

   function un_to_Num(a:word):word;
   var
     i : integer;
   begin
    Result:=1;
    for i:=1 to 16 do
      begin
       if a mod 2>0 then exit;
       a:=a div 2;
       inc(Result);
      end;
   end;{un_to_Num}

   function Num_to_Un(a:word):word;
   var
     i : integer;
   begin
    Result:=1;
    for i:=1 to a-1 do  inc(Result, Result)
   end;{Num_to_Un}

  Function Extract_mask(a : word):trextract;
    begin
      Result.two:=Num_to_Un(un_to_num(a));
      Result.one:=a - Result.two;
    end;{Extract_mask}


  Procedure Init_massiv;
  var
     i : integer;
  begin
    for i:=1 to 256 do if Extract_mask(i).one<>0 then fillchar(dec_massiv[i], sizeof(trmassivtype), #0);
  end;{Init_massiv}

  Procedure Init_massiv_1;
  var
     i, j : integer;
  begin
    for i:=1 to 256 do if Extract_mask(i).one<>0 then
        for j:=__min to __max*16 do dec_massiv[i]._data[j].sum_topl:=Max_Integer;
    fillchar(result_massiv, sizeof(trmassivtype), #0);
    for j:=__min to __max*16 do result_massiv._data[j].sum_topl:=Max_integer;
  end;{Init_massiv_1}


  Procedure Assign_massiv;
  var
     i, j, num_func : integer;
     _mask : word;
  begin
    Init_massiv;
    Init_massiv_1;
    for i:=1 to 8 do
      begin
       num_func:=(i+1) div 2;
       _mask:=Num_to_Un(i);
       fillchar(dec_massiv[_mask], sizeof(trmassivtype), #0);
       for j:= __min to __max do
         begin
           dec_massiv[_mask]._data[j].mask:=_mask;
           dec_massiv[_mask]._data[j]._topl[i]:=__topl(num_func,j);
           dec_massiv[_mask]._data[j]._nagr[i]:=j;
           dec_massiv[_mask]._data[j].sum_topl:=__topl(num_func,j);
         end;{for}
      end;{for}
  end;{Assign_massiv}

  Procedure element_optimization(one, two : word);
  var
    i, j, res_mask, num_two, max_i, max_j, oper_perem : integer;

  function calcul_max_limit(a:word):integer;
  var
     i : integer;
  begin
   Result:=__max*16;
   for i:=__min to __max*16 do
     begin
      if dec_massiv[a]._data[i].mask=0 then
        begin
         Result:=i-1;
         Exit;
        end;{if}
     end;{for}
  end;{calcul_max_limit}

  begin
    if one*two=0 then Exit;
    res_mask:=one+two;
    num_two:=un_to_Num(two);
    max_i:=calcul_max_limit(one);
    max_j:=calcul_max_limit(two);
    for i:=__min to max_i do
        if dec_massiv[one]._data[i].sum_topl<dec_massiv[res_mask]._data[i].sum_topl
        then dec_massiv[res_mask]._data[i]:=dec_massiv[one]._data[i];
   for j:=__min to max_j do
        if dec_massiv[two]._data[j].sum_topl<dec_massiv[res_mask]._data[j].sum_topl
        then dec_massiv[res_mask]._data[j]:=dec_massiv[two]._data[j];


    for i:=__min to max_i do for j:=__min to max_j do
      begin
        iters:=iters+1;
        oper_perem:=dec_massiv[one]._data[i].sum_topl+dec_massiv[two]._data[j].sum_topl;
        if
                                   oper_perem
                                        <
                 dec_massiv[res_mask]._data[i+j].sum_topl
        then
          begin
           dec_massiv[res_mask]._data[i+j]:=dec_massiv[one]._data[i];
           dec_massiv[res_mask]._data[i+j].mask:=dec_massiv[res_mask]._data[i+j].mask or two;
           dec_massiv[res_mask]._data[i+j]._topl[num_two]:=dec_massiv[two]._data[j].sum_topl;
           dec_massiv[res_mask]._data[i+j]._nagr[num_two]:=j;
           dec_massiv[res_mask]._data[i+j].sum_topl:=oper_perem;
          end;{if}
      end;{for if for if}

  end;{element_optimization}

  Procedure Gen_optimization;
  var
     i : integer;
  begin
    for i:=1 to 256 do if (not general_mask) and i = 0 then
      begin
       oper_mask:=Extract_mask(i);
       element_optimization(oper_mask.one, oper_mask.two);
      end;{for}

  end;{Gen_optimization}

  Procedure GLobal_optimization;
  var
    i, j : integer;
    beg_time : TdateTime;
  begin
   iters:=0;
   beg_time:=Now;
   Init_massiv_1;
   Gen_optimization;
   for j:=__min to __max*16 do
    for i:=1 to 256 do if (not general_mask) and i = 0 then
      if dec_massiv[i]._data[j].sum_topl<result_massiv._data[j].sum_topl then
        if dec_massiv[i]._data[j].sum_topl>0 then
           result_massiv._data[j]:=dec_massiv[i]._data[j];
    resinfo.iterations:=iters;
    resinfo.__time:=Now-beg_time;
  end;{GLobal_optimization}


  procedure perebor;
  var
     i1, i2,i3,i4,i5,i6,i7,i8, k :integer;
     maxi1, maxi2,maxi3,maxi4,maxi5,maxi6,maxi7,maxi8 :integer;
     a, b : array [1..8] of integer;
     nakop_a, nakop_b, nakop_mask : integer;
     beg_time : Tdatetime;
  begin
   iters:=0;
   beg_time:=Now;
   Init_massiv_1;
   if general_mask and Num_to_un(1)=0 then maxi1:=__min-1 else maxi1:=__max;
   if general_mask and Num_to_un(2)=0 then maxi2:=__min-1 else maxi2:=__max;
   if general_mask and Num_to_un(3)=0 then maxi3:=__min-1 else maxi3:=__max;
   if general_mask and Num_to_un(4)=0 then maxi4:=__min-1 else maxi4:=__max;
   if general_mask and Num_to_un(5)=0 then maxi5:=__min-1 else maxi5:=__max;
   if general_mask and Num_to_un(6)=0 then maxi6:=__min-1 else maxi6:=__max;
   if general_mask and Num_to_un(7)=0 then maxi7:=__min-1 else maxi7:=__max;
   if general_mask and Num_to_un(8)=0 then maxi8:=__min-1 else maxi8:=__max;


   for i1:=__min-1 to maxi1 do
   for i2:=__min-1 to maxi2 do
   for i3:=__min-1 to maxi3 do
   for i4:=__min-1 to maxi4 do
   for i5:=__min-1 to maxi5 do
   for i6:=__min-1 to maxi6 do
   for i7:=__min-1 to maxi7 do
   for i8:=__min-1 to maxi8 do
     begin
     iters:=iters+1;
      for k:=1 to 8 do
        begin
         a[k]:=0;
         b[k]:=0;
        end;{for}
      nakop_a:=0;
      nakop_b:=0;
      nakop_mask:=0;

      if i1>=__min then if general_mask and Num_to_un(1)<>0 then
        begin
         a[1]:=dec_massiv[Num_to_un(1)]._data[i1]._nagr[1];
         b[1]:=dec_massiv[Num_to_un(1)]._data[i1].sum_topl;
         nakop_a:=nakop_a+a[1];
         nakop_b:=nakop_b+b[1];
         nakop_mask:=nakop_mask or Num_to_un(1);
        end;{if i1}

      if i2>=__min then if general_mask and Num_to_un(2)<>0 then
        begin
         a[2]:=dec_massiv[Num_to_un(2)]._data[i2]._nagr[2];
         b[2]:=dec_massiv[Num_to_un(2)]._data[i2].sum_topl;
         nakop_a:=nakop_a+a[2];
         nakop_b:=nakop_b+b[2];
         nakop_mask:=nakop_mask or Num_to_un(2);
        end;{if i2}

      if i3>=__min then if general_mask and Num_to_un(3)<>0 then
        begin
         a[3]:=dec_massiv[Num_to_un(3)]._data[i3]._nagr[3];
         b[3]:=dec_massiv[Num_to_un(3)]._data[i3].sum_topl;
         nakop_a:=nakop_a+a[3];
         nakop_b:=nakop_b+b[3];
         nakop_mask:=nakop_mask or Num_to_un(3);
        end;{if i3}

      if i4>=__min then if general_mask and Num_to_un(4)<>0 then
        begin
         a[4]:=dec_massiv[Num_to_un(4)]._data[i4]._nagr[4];
         b[4]:=dec_massiv[Num_to_un(4)]._data[i4].sum_topl;
         nakop_a:=nakop_a+a[4];
         nakop_b:=nakop_b+b[4];
         nakop_mask:=nakop_mask or Num_to_un(4);
        end;{if i4}

      if i5>=__min then if general_mask and Num_to_un(5)<>0 then
        begin
         a[5]:=dec_massiv[Num_to_un(5)]._data[i5]._nagr[5];
         b[5]:=dec_massiv[Num_to_un(5)]._data[i5].sum_topl;
         nakop_a:=nakop_a+a[5];
         nakop_b:=nakop_b+b[5];
         nakop_mask:=nakop_mask or Num_to_un(5);
        end;{if i5}

      if i6>=__min then if general_mask and Num_to_un(6)<>0 then
        begin
         a[6]:=dec_massiv[Num_to_un(6)]._data[i6]._nagr[6];
         b[6]:=dec_massiv[Num_to_un(6)]._data[i6].sum_topl;
         nakop_a:=nakop_a+a[6];
         nakop_b:=nakop_b+b[6];
         nakop_mask:=nakop_mask or Num_to_un(6);
        end;{if i6}

      if i7>=__min then if general_mask and Num_to_un(7)<>0 then
        begin
         a[7]:=dec_massiv[Num_to_un(7)]._data[i7]._nagr[7];
         b[7]:=dec_massiv[Num_to_un(7)]._data[i7].sum_topl;
         nakop_a:=nakop_a+a[7];
         nakop_b:=nakop_b+b[7];
         nakop_mask:=nakop_mask or Num_to_un(7);
        end;{if i7}

      if i8>=__min then if general_mask and Num_to_un(8)<>0 then
        begin
         a[8]:=dec_massiv[Num_to_un(8)]._data[i8]._nagr[8];
         b[8]:=dec_massiv[Num_to_un(8)]._data[i8].sum_topl;
         nakop_a:=nakop_a+a[8];
         nakop_b:=nakop_b+b[8];
         nakop_mask:=nakop_mask or Num_to_un(8);
        end;{if i8}

       if nakop_b<result_massiv._data[nakop_a].sum_topl then if nakop_b>0 then
         begin
           result_massiv._data[nakop_a].mask:=nakop_mask;
           for k:= 1 to 8 do result_massiv._data[nakop_a]._nagr[k]:=a[k];
           result_massiv._data[nakop_a].sum_topl:=nakop_b;
         end;{if}
     end;{for}
    resinfo.iterations:=iters;
    resinfo.__time:=Now-beg_time;

  end;{perebor}


   Procedure __test;
   var
      a : integer;
   begin

    GLobal_optimization;

    oper_mask:=Extract_mask(56);
    if oper_mask.one=0 then;

    a:=un_to_Num(128);
    if a=0 then;
    a:=Num_to_un(8);
    if a=0 then;

    a:=__topl(1,50);
    if a=0 then;
    a:=__topl(2,50);
    if a=0 then;
    a:=__topl(3,50);
    if a=0 then;
    a:=__topl(4,50);
    if a=0 then;
   end;{__test}




begin
// __Test;
  Assign_massiv;
end.
