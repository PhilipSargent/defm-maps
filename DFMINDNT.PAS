Unit DfmIndnt;
{ PMS 29-November-2020 14:48:18 }
{---------------------------------------------------------------------------}
{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
   *************   Department, Cambridge, UK.       **************
   *************   P.M.Sargent and M.F.Ashby        **************
   *************   June 1993                        **************

   This is free software, you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 2 of the License,
   or (at your option) any later version.
	This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.
   The file COPYING enclosed with this software contains a copy of
   version 2 of the GNU General Public License which should not be
   altered in any way. If it is missing, write to the Free Software
   Foundation Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 ---------------------------------------------------------------------------}
{$DEFINE  debug} {	always on, pending removal of directive	}

{$R+}	{Range checking on}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Interface

PROCEDURE IDENTIFY_FIELDS_Indent;

PROCEDURE CALC_Indentation_MAP;

{===========================================================================}

Implementation

Uses
	Crt,
	Dos,
	Printer,
	Graph,
	StringIO,
	DfmGlbls,
	DfmPlots,
	DfmModls;

CONST

	C_1 = 0.193;	{	1/(3.sqrt(3))	}
	C_2 = 1;
	C_3 = 25.504;	{	Vickers indenters	}

VAR
	Lgt_first, Lgt_last, Lgt_step	:	a_real;
	LgHN			:	a_real;
	A, A_dot, Load	:	a_real;
	H, t, dt			:	a_real;

{---------------------------------------------------------------------------}
PROCEDURE Fields_Loop_Indent (temp_step: Word);
BEGIN
END;	{	Fields_Loop_Indent	procedure }
{---------------------------------------------------------------------------}
PROCEDURE PLOT_Indentation_BOX (t_first, t_last, LgHNfirst, LgHNlast: a_real);

{ ----- Constructs box for Indentation creep map and labels the axes ----- }

var
	xscale, yscale	:	INTEGER;
	Tinterval		:	REAL;
	t				:	REAL;
	xmark, ymark	:	INTEGER;
	scale			:	INTEGER;
	H, HNfirst, HNlast	:	a_real;
	Hfirst, Hlast		:	a_real;
	LgHfirst, LgHlast	:	a_real;
	minor				:	Byte;	{	The number of minor marks between big marks }

BEGIN
	BoxDefaults;

{ --------- Draw  Box ----------}
	writeln(db,'Draw box');
	myLine(xoffset,yoffset,xoffset,yend);
	myLine(xoffset,yoffset,xend,yoffset);
	myLine(xend,yend,xoffset,yend);
	myLine(xend,yend,xend,yoffset);

{ --------- Put on NORMALIZED STRESS scale --------- }
	writeln(db,'Put on NORMALIZED STRESS scale ');
	writeln(db,'Normalised temperature: t_first, t_last ',t_first:12:5,' ', t_last:12:5);
	writeln(db,'Log Hardness: LgHNfirst, LgHNlast ',LgHNfirst:8:1,' ', LgHNlast:8:1);

	minor   := 1;	{	because it's a log axis, so minor marks are not useful }

	yscale  := round(LgHNlast*minor - LgHNfirst*minor);

	writeln(db,'For loop from ',round(LgHNfirst*minor), ' to ', round(LgHNfirst*minor) + yscale - 1);
	writeln(db,'ylength, yscale ',ylength,' ', yscale);
	SetColor(yellow);
	FOR scale := (round(LgHNfirst*minor)) to (round(LgHNfirst*minor) + yscale - 1) DO
		BEGIN
			writeln(db,'scale:',scale);
			ymark := yoffset +
				ylength - round((scale - round(LgHNfirst*minor))/yscale*ylength);
			IF (frac(scale/minor) = 0)  THEN
				myLine(xoffset,ymark,xend,ymark)
			ELSE
				myLine(xoffset,ymark,xoffset+3,ymark);
		END;

{ --------- Put on ABSOLUTE STRESS scale ---------- }
	{	in Mpa, but shmod is in GPa so multiply by 1000	}
	HNfirst := exp(LgHNfirst);
	HNlast := exp(LgHNlast);
	Hfirst	:=	shmod*HNfirst*1.0e3;	{	shmod is at 300 K	}
	Hlast 	:=	shmod*HNlast *1.0e3;	{	shmod is at 300 K	}
	LgHfirst	:=	Ln(Hfirst)/Ln10;
	LgHlast 	:=	Ln(Hlast)/Ln10;

	IF (Hfirst <= 1.0e-9) THEN
		BEGIN
			WriteLn(db,'Error, low hardness limit too low!');
			WriteLn(db,'Hfirst: ', Hfirst,'shmod: ', shmod,'HNfirst: ', HNfirst );
			OurOutTextXY(xoffset+2,100,'Error, low hardness limit too low!');
			Str(Hfirst:4:1,st);
			OurOutTextXY(xoffset+2,106,st);
			Str(shmod:4:1,st);
			OurOutTextXY(xoffset+2,112,st);
			Str(HNfirst:4:1,st);
			OurOutTextXY(xoffset+2,118,st);
			
			{ ERROR detection... wait for a moment..}
			repeat until keypressed;
		END;
	H	:=	1.0e-9;
	REPEAT
		H := H * 10;
	UNTIL (H >= Hfirst);

	Str(H:4:1,st);
	IF (H < Hlast) THEN
		OurOutTextXY (585,189,st);

	ymark		:= 0;
	REPEAT
		IF (H > Hfirst) and (H < Hlast) THEN
			ymark := yoffset +
				round(ylength*(1 - (Ln(H)/Ln10 - LgHfirst)/
												(LgHlast - LgHfirst)));
		IF (ymark >= yoffset) AND (ymark <= yend) THEN
			myLine(xend,ymark,xend-6,ymark);

{ -----	Nested IFs because of BUG with 8087 chip if IFs too complicated	}
		Str(H:4:1,st);
		IF (H >= (Hlast/10)) THEN
			IF (H <= Hlast) THEN
				OurOutTextXY (585,10,st);
		H := H * 10;
	UNTIL (H  >= Hlast);

{ --------- Put on Log Time x-scale ---------- }
	t	:=	1.0e-9;
	REPEAT
		t := t * 10;
	UNTIL (t >= t_first);

	Str((Ln(t)/Ln10):4:1,st);
	IF (t < t_last) THEN
		OurOutTextXY (75,196,st);

	xmark		:= 0;
	REPEAT
		IF (t > t_first) and (t < t_last) THEN
			xmark := xoffset +
				round(xlength*(1 - (Ln(t)/Ln10 - Lgt_first)/
												(Lgt_last - Lgt_first)));
		IF (xmark >= xoffset) AND (xmark <= xend) THEN
			myLine(xmark,yend,xmark,yend-6);

{ -----	Nested IFs because of BUG with 8087 chip if IFs too complicated	}
		Str((Ln(t)/Ln10):4:1,st);
		IF (t >= (t_last/10)) THEN
			IF (t <= t_last) THEN
				OurOutTextXY (554,196,st);
		t := t * 10;
	UNTIL (t  >= t_last);

	Str(t_first:4:2,st);
	OurOutTextXY(75,5,st);
	Str(t_last:8,st);
	OurOutTextXY(554,5,st);

{ --------- Label Normalised Hardness Axes           ---------- }
	Str(LgHNlast:4:2,st);
	OurOutTextXY(42,10,st);
	Str(LgHNfirst:4:2,st);
	OurOutTextXY(42,189,st);

{ ----- Label horizontal and vertical axes of graph window ----- }

	OurOutTextXY(216,5,'          TIME   (s)      ');
	OurOutTextXY(200,196,'       Ln(TIME)  (s)      ');
	vertical_text(56,100,'NORM. HARDNESS  ');
	vertical_text(599,100,'HARDNESS (MPa)  ');

END;   {PLOT_Indentation_BOX.    }

{---------------------------------------------------------------------------}
PROCEDURE PLOT_Indentation_INFO;

{ ----- Label horizontal and vertical axes of graph window ----- }
VAR
	xof,yof,xl,yl	:	REAL;
	delta_x			:	REAL;
	delta_y			:	REAL;

BEGIN
	DATE_AND_TIME;

	xof    := xfac0 * MaxX;
	yof    := yfac0 * MaxY;
	xl     := xfacN * MaxX;
	yl     := yfacN * MaxY;

	delta_x := 6/xfactor;										{ avoid axes marks }
	delta_y := 6/yfactor;										{ avoid axes marks }

	SetColor(white);

	{ these calls to myLine use actual pixels in the viewport}
	myLine(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+xlength,yoffset+round(ylength/4));
	myLine(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+round(3*xlength/4),yoffset);

	{ these calls to ClearTextSpace and OurOutTextXY use 'notional 640x200 scaled pixels'}
	ClearTextSpace(85,122,306,130);
	OurOutTextXY(96,126,'Indentation Creep Trajectories');
	
	ClearTextSpace(456,12,630,55);
	OurOutTextXY(465,16,matlname);
	Str((Gsize*1.0e6):4:1,st);
	OurOutTextXY(465,24,'d = '+st+' um');
	Str(Load:4:0,st);
	OurOutTextXY(465,32,'L = '+st+' N');
	OurOutTextXY(465,48,date_string);

END;	{	PLOT_Indentation_INFO	}
{---------------------------------------------------------------------------}
procedure Creep_Calc (VAR 	field	:	E_mech);
VAR
	SN		:	a_real;

BEGIN
	t := t + dt; { t increases each iteration }
	
{	Area of indentation A is in sq.mm, Load is in N, so H is MPa	}
	A_dot := Rate * C_2 * C_3 * 0.5 /A;

{	We want dt to be such that the change in A is < 100%	}
	IF (A_dot*dt > {0.1*} A) THEN
		dt := 0.1*A/A_dot
	ELSE
		dt := dt * 2; {default is to double dt each iteration }
	A := A + A_dot*dt;
	H := Load/A;				{	MPa	}
{	shear_mod is in GPa, so convert H to GPa before dividing	}
	lgHN := Ln(H * 1.0e-3 /shear_mod)/Ln10;
{	Writeln(db,'< CreepCalc. T=',t:8,' dt=',dt:8,' LgHN=', LgHN:8:3,' A=', A:8,' A_dot=',A_dot:8);}
{	Flush(db);}

	Stress := C_1 * H;		{	MPa	}
{	shear_mod is in GPa, so convert Stress to GPa before dividing	}
	SN := Stress * 1.0e-3 /shear_mod;
	IF (SN >= 1) THEN	{	stress higher than shear modulus	}
		BEGIN
			Rate := 1e6;
			field := phn_drag;
		END
	ELSE
		BEGIN
			LgSN := Ln(SN)/Ln10;
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
		END;
END;	{	Creep_Calc	}
{---------------------------------------------------------------------------}
PROCEDURE Trajectory (LgHNfirst,lgHNlast: a_real);
{	Plots the line for any given temperature TN and load Load	}
CONST
	s1  =  2;
	s2  =  1;
VAR
	field1,field2	:	E_mech;
	x,y,x1,x2,y1,y2	:	Integer;
	Lgt				:	a_real;

BEGIN
	A := 2e-5;		{	mm^2	}
	dt := 1e-18;	{	s	}
	t := dt;
	Rate := 1e6;	{	Maximum strain rate possible	}
	x2 := xoffset;
	y2 := yoffset;
	field2 := null;
	skip := FALSE;

{	Writeln(db,'++Trajectory begin.');
	Writeln(db,'TN= ',TN:5:2,'  t(s)       dt(s)      LgHN',
		'        A(mm^2)   A_dot(mm^2)');}

	REPEAT
		x1 := x2;
		y1 := y2;
		field1 := field2;
		Creep_Calc(field2);
		Lgt := Ln(t)/Ln10;
		x2 := round(xlength*(Lgt - Lgt_first)/(Lgt_last - Lgt_first));
		y2 := round(ylength*(LgHNlast - LgHN)/(LgHNlast - LgHNfirst));

{		Write(db,'|');
		WRITE_FIELDNAME (field2);
		`(db,'|');
		Writeln(db);}

	{ ----- Draw the contours ----- }
		IF (Lgt > Lgt_first) THEN
			BEGIN
				Write(db,'+ x1:', x1,' y1:',y1,' x2:',x2,' y2:',y2);
				myLine(x1,y1,x2,y2);
				Writeln(db,' *');
				IF (field1 <> field2) THEN
					BEGIN
						Write(db,'^');
						x := round((x1+x2)/2);
						y := round((y1+y2)/2);
						myLine(x-s1, y, x+s1,y);
						myLine(x-s1, y+s2, x+s1,y+s2);
					END;
			END;
		DETECT_SKIP;
	UNTIL (Lgt > Lgt_last) OR skip;
{	Writeln(db,'++Trajectory end.');}

END;	{	Trajectory	}
{---------------------------------------------------------------------------}
PROCEDURE 	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high: a_real; trajnumber:integer);

VAR
	first, last	:	a_real;
{ ----- Identify the trajectories  ----- }

BEGIN
	Flush(db);
	SetColor(brown);

	ClearTextSpace(96,156,260,183);
	Str((trajnumber):3,st);
	OurOutTextXY(96,162,st+' TEMPERATURES');
	first := TNtraj_low*tmelt;
	last := TNtraj_high*tmelt;
	IF ((first < 99999 ) AND ( first >= 1 )) THEN
		Str(first:7:0,st)
	ELSE
		Str(first:7:2,st);
	OurOutTextXY(96,170,' First = '+st+' K');
	IF ((last < 99999 ) AND ( last >= 1 )) THEN
		Str(last:7:0,st)
	ELSE
		Str(last:7:2,st);
	OurOutTextXY(96,178,' Last  = '+st+' K');

END;    {IDENTIFY_TRAJECTORIES.    }
{---------------------------------------------------------------------------}
PROCEDURE IDENTIFY_FIELDS_Indent;
BEGIN
END;    {IDENTIFY_FIELDS_Indent.    }
{---------------------------------------------------------------------------}
PROCEDURE CALC_INDENTATION_MAP;

VAR
 	mech,
	field				:	E_mech;

	count				:	Integer;
	i, step			:	Word;
	c					:	Byte;

	t, t_last, t_first	:	a_real;
	epsilon					:	a_real;
	prev_eps					:	a_real;
	home_in					:	a_real;
	TNtraj_low			:	a_real;
	TNtraj_high			:	a_real;
	TNtraj_step			:	a_real;
	LgHNfirst 		:	a_real;
	LgHNlast			:	a_real;
	lastTN			:	a_real;
	BaseRate			:	a_real;
	trajnumber		:	Integer;

BEGIN	{Calc_Indentation_Map	}

	LgHNfirst	:= -7;
	LgHNlast	:= -1;

	Load := 0.1;	{	MN	}
	t_first := 0.005;
	t_last := 5e7;

	Lgt_first	:=	Ln(t_first)/Ln10;
	Lgt_last 	:=	Ln(t_last)/Ln10;
	Lgt_step		:= (Lgt_last - Lgt_first)/steps;

	trajnumber := 20;
	TNtraj_low := 0.15;
	TNtraj_high := 0.95;
	TNtraj_step		:= (TNtraj_high - TNtraj_low)/trajnumber;   		{Temperature interval}

	quit := FALSE;
	t := t_first;
	Load := 1;	{	in N, 1kgf. is 9.81 N, so 1 N is about 100gf.	}
	BaseRate := 1e-4;
	Writeln(db,'Calc_Indentation_Map ');
	Writeln(db,'BaseRate ',BaseRate:15);
	Writeln(db,'Load     ', Load:15:4);
	{	shmod is at 300 K	}
	TN := 300/tmelt;
	Writeln(db,'TN       ', TN:15:4);
	Writeln(db,'shtmp          ', shtmp:15);
	Writeln(db,'shmod  (300K)  ', shmod:15);
	shear_mod	:= shmod* (1 + shtmp*300/tmelt)*(1 - shtmp*TN);
	Writeln(db,'shear_mod  (0K)', (shmod* (1 + shtmp*300/tmelt)):15);
	Writeln(db,'shear_mod  (TN)', shear_mod:15);
	dt := 1;

{ ----- Calculate strain rate for Stress in middle of range ----- }
	LgSN := -4;
	Writeln(db,'LgSN     ', LgSN:15:4);

	DIFFUSION_RATES;
	Writeln(db);
	count := 0;
	skip := FALSE;
	prev_eps := 0;
	epsilon := 0;
	home_in := 1.05;
	Writeln(db,' Iterate to find strain rate for Stress in middle of range ');
	Writeln(db,' Stress Begin count   Rate      LgSN     epsilon');
	Flush(db);
	REPEAT
		count:= count + 1;
		STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
		prev_eps := epsilon;
		epsilon := Rate/BaseRate;
		Writeln(db,' Stress Begin ',count:4,' ',Rate:8,' ',
			LgSN:8:3,' ',epsilon:9);
		IF (Rate > BaseRate) THEN
			LgSN := LgSN*home_in	{	since LgSN is always -ve	}
		ELSE
			LgSN := LgSN/home_in;
		IF ((prev_eps > 1) AND (epsilon < 1))
		OR ((prev_eps < 1) AND (epsilon > 1)) THEN	{	over-shot	}
			home_in := 1+ 0.5*(home_in-1);
		Flush(db);

{ ----- Detect <CtrlC> key if pressed  ----- }
		DETECT_SKIP;
	UNTIL (( epsilon < 1.1) AND ( epsilon > 0.9)) OR skip;
	Writeln(db,'Finished TN=0.5 getting Rate = 1e-4 ',Rate:8);
	Flush(db);

{ ----- "Zero" field id counters ----- }

	FOR mech := null TO rel_drag DO
		BEGIN
			temp_position[mech]      := 0;
			stress_position[mech]      := 0;
			pointcount[mech]  := 0;
		END;

{ ----- Draw the Indentation box ----- }
	Writeln(db,' call PLOT_Indentation_BOX');
	Flush(db);

	PLOT_Indentation_BOX (t_first, t_last, LgHNfirst, LgHNlast);
	Flush(db);

	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high,trajnumber);

	SetViewPort(xoffset, yoffset, xend, yend, ClipOn);
	
{	Plot the 300K trajectory first	}
{	SetColor(white);}
{	SetLineStyle(DottedLn,0,NormWidth);}
{	Trajectory (LgHNfirst,lgHNlast);}
	
	SetLineStyle(SolidLn,0,NormWidth);
	SetColor(green);

{ ========== S T A R T == T H E == T E M P E R A T U R E == L O O P ========= }
	skip:=FALSE;
	i:=0;
	TN := TNtraj_low;
	REPEAT

{ ----- Calculate the diffusion rates at the new Temperature ------- }
		DIFFUSION_RATES;


{ ----- Calculate and Plot the Hardness/time trajectory ------- }
		Trajectory (LgHNfirst,lgHNlast);

{ ----- Calculate where the feld boundaries are ------- }
		Fields_Loop_Indent(i);	{ needs rewriting completely to work for the indentation map }

{ ----- Detect <CtrlC> key if pressed  ----- }
		DETECT_SKIP;

		TN := TN + TNtraj_step;
		i:=i+1;
	UNTIL (i=trajnumber+1) OR skip;

{ ============ E N D == T H E == T E M P E R A T U R E == L O O P =========== }

{	Plot the 300K trajectory AGAIN	}
	TN := 300/tmelt;
	DIFFUSION_RATES;
	SetColor(white);
	Trajectory (LgHNfirst,lgHNlast);

	SetViewPort(0, 0, MaxX, MaxY, ClipOn);

	IDENTIFY_FIELDS_Indent; { need a different procedure for this for the indentation map }
	
	PLOT_Indentation_INFO;	{again, in case it had been overwritten	}
	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high,trajnumber);
	CloseSVG;

END;       {CALC_INDENTATION_MAP.   }
{ =========================================================================== }
{---------------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
End.