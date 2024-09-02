unit HPUNIT;                       { HRS - 26/9/89, 10:30 am }

{$R+}    {Range checking on}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}
{$N+}    {uses 8087 co-processor}

{=============================================================}

interface

(*-----*)

uses
   Crt,
   Auxinout;

const
   lbllength = 16;


type
   lblstring = string[lbllength];
   graphstring = string[4];
   SIstring = string[12];

var
   answer : char;

   I, J, K, L, M,
  n,xtype, ytype,
   figtype,
   plottype,
   xinc, yinc,
   XP, YP,
   XPmin, YPmin,
   XPmax, YPmax,
   XPfac, YPfac,
   XPrange, YPrange,
   plot_axes         : integer;

   XNfirst, XNlast,
   YNfirst, YNlast,
   XLBmin, XLBmax,
   YLBmin, YLBmax,
   xstep, ystep,
   XNrange, YNrange,
   subxpos, subypos,
   xconv, yconv,
   xpos, ypos        : double;

  desk, aux : text;
  ch  : char;

   X_st, Y_st : lblstring; {these strings must be <= 16 chars}

   SI_st10,
   SI_stexp,
   SI_stnum,
   SI_stlab   : SIstring;

   st : graphstring;

   xcurv,
   ycurv : array [1..100] of double;

(*-----------------------------------------------------------*)

procedure InitAux;
   { Initialises aux as file }

procedure Label_plotter_axes;
   { Labels axes }

procedure Open_plotter_graphics;
   { Initaializes plotter, draws box, ticks and labels axes }

procedure Plotter_chosen_plot;
   { Draws calculated curves, and/or datapoints }

procedure Plotter_IW (xp1,yp1,xp2,yp2 : integer);
   { Allows window to be defined - inc. from main program }

{=============================================================}

implementation

(*----------*)

type
   plotterstring = string[50];

var
   PU_st, PD_st, PR_st,
   CI_st, LB_st, IW_st,
   xp1_st, yp1_st,
   xp2_st, yp2_st,
   xp_st, yp_st,
   rad_st, ang_st 	 : plotterstring;

   I_st, L_st : graphstring;

(*-----------------------------------------------------------*)

procedure InitAux;

begin
   AssignAux(aux,0,$83);

end;  {InitAux}

(*-----------------------------------------------------------*)

procedure User_to_Plotter_Units (XU,YU : double; var XP,YP : integer);

{ converts given user (XU,YU) into integer plotter (XP,YP) }

begin
   XP := XPmin + round(XPrange*(XU-XNfirst)/XNrange);
   YP := YPmin + round(YPrange*(YU-YNfirst)/YNrange);

end; {User_to_Plotter_Units}

(*-----------------------------------------------------------*)

procedure Plotter_PU (hpx,hpy : integer);

begin
   Str(hpx,xp_st); Str(hpy,yp_st);
   PU_st := 'PU'+xp_st+','+yp_st;
   writeln(aux,PU_st);

end; {Plotter_PU}

(*-----------------------------------------------------------*)

procedure Plotter_PD (hpx,hpy : integer);

begin
   Str(hpx,xp_st); Str(hpy,yp_st);
   PD_st := 'PD'+xp_st+','+yp_st;
   writeln(aux,PD_st);

end; {Plotter_PD}

(*-----------------------------------------------------------*)

procedure Plotter_PR (hpx,hpy : integer);

begin
   Str(hpx,xp_st); Str(hpy,yp_st);
   PR_st := 'PR'+xp_st+','+yp_st;
   writeln(aux,PR_st);

end; {Plotter_PR}

(*-----------------------------------------------------------*)

procedure Plotter_LB (my_label : lblstring);

begin
   LB_st := 'LB'+my_label+' '+Chr(3);
   writeln(aux,LB_st);

end; {Plotter_LB}

(*-----------------------------------------------------------*)

procedure Plotter_IW (xp1,yp1,xp2,yp2 : integer);

begin
   Str(xp1,xp1_st); Str(yp1,yp1_st);
   Str(xp2,xp2_st); Str(yp2,yp2_st);
   IW_st := 'IW'+xp1_st+','+yp1_st+','+xp2_st+','+yp2_st;
   writeln(aux,IW_st);

end; {Plotter_IW}

(*-----------------------------------------------------------*)

procedure HP_Lin_X;

begin
   {Bottom axis}
   for I := 0 to xinc do begin
      xpos := XNfirst + xstep*I;
      User_to_Plotter_Units(xpos,YNfirst,XP,YP);
      Plotter_PU(XP,YP);
      writeln(aux,'TL1,0;XT',SI_stnum,'CP-3.0,-1.0');
      case xtype of
         0: Str(xpos:4:0,I_st);
         1: Str(xpos:4:1,I_st);
      end;
      Plotter_LB(I_st);
   end;

   {Top axis}
   for K := xinc downto 0 do begin
      xpos := XNfirst + xstep*K;
      User_to_Plotter_Units(xpos,YNlast,XP,YP);
      Plotter_PU(XP,YP);
      writeln(aux,'TL0,1;XT');
   end;

end; {HP_Lin_X}

(*-----------------------------------------------------------*)

procedure HP_Lin_Y;

begin
   {RH axis}
   for J := 0 to yinc do begin
      ypos := YNfirst + ystep*J;
      User_to_Plotter_Units(XNlast,ypos,XP,YP);
      Plotter_PU(XP,YP);
      writeln(aux,'TL0,1;YT');
   end;

   {LH axis}
   for L := yinc downto 0 do begin
      ypos := YNfirst + ystep*L;
      User_to_Plotter_Units(XNfirst,ypos,XP,YP);
      Plotter_PU(XP,YP);
      writeln(aux,'TL1,0;YT;',SI_stnum,'CP-6.1,-0.2');
      case ytype of
         0: Str(ypos:5:0,L_st);
         1: Str(ypos:6:1,L_st);
      end;
      Plotter_LB(L_st);
   end;

end; {HP_Lin_Y}

(*-----------------------------------------------------------*)

procedure Label_plotter_axes;

begin
   writeln(aux,SI_stlab);
     {draw box}
   Plotter_PU(XPmin,YPmin); Plotter_PD(XPmax,YPmin); Plotter_PD(XPmax,YPmax);
   Plotter_PD(XPmin,YPmax); Plotter_PD(XPmin,YPmin);

     {tick box: X axes then Y axes}
     {xinc, yinc: number of ticks on x & y axes}
   xinc := round(XNrange/xstep);
   HP_Lin_X;
   writeln(YNrange,'    ',ystep);
   yinc := round(YNrange/ystep);
   HP_Lin_Y;

   writeln(aux,SI_stlab);
   Plotter_PU(XPmin+3000,YPmin-800); Plotter_LB(X_st);
   Plotter_PU(XPmin-1000,YPmin+2000); writeln(aux,'DI0,1;'); Plotter_LB(Y_st);

end; {Label_plotter_axes}

(*----------------------------------------------------------*)

procedure Open_plotter_graphics;

begin
   writeln; writeln; TextColor(LightCyan);
   repeat
      write('Plot axes ? (y/n) .... ');
      repeat until keypressed; answer := ReadKey;
   until answer in ['Y','y','n','N'];
   if (answer in ['y','Y']) then plot_axes := 1 else plot_axes := 0;
   writeln; writeln;

   XPrange := XPmax-XPmin; {plotter unit ranges}
   YPrange := YPmax-YPmin;
   XPfac := round(XPrange/XNrange); {plotter units per user unit on x & y axis}
   YPfac := round(YPrange/YNrange);
     {initialise plotter}
   writeln(aux,'IN;');
     {select pen speed}
   writeln(aux,'VS;');
   if (plot_axes = 1) then begin
      repeat
         write('Select pen ? (1 - 6) .... ');
         repeat until keypressed; answer := ReadKey;
      until answer in ['1','2','3','4','5','6'];
      writeln;
      writeln(aux,'SP'+answer);
      Label_plotter_axes;
   end;

end;  {Open_plotter_graphics}

(*----------------------------------------------------------*)

procedure Plotter_chosen_plot;

begin
   assign(desk,'tope');
   reset(desk);
   readln(desk,n);
   close(desk);
   repeat
      write('Select pen ? (1 - 6) .... ');
      repeat until keypressed; answer := ReadKey;
   until answer in ['1','2','3','4','5','6'];
	writeln;
   writeln(aux,'SP'+answer);
   for I := 1 to n do begin
      User_to_Plotter_Units(xcurv[I],ycurv[I],XP,YP);
      if (I=1) then Plotter_PU(XP,YP) else Plotter_PD(XP,YP);
   end;
   Plotter_IW(0,0,11040,7721); Plotter_PU(0,7721); writeln(aux,'SP0;');

end; {Plotter_chosen_plot}

(*-------------------*)

end.  {UNIT HPUNIT.PAS}