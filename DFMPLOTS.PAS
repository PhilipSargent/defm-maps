Unit DfmPlots;
{ PMS 28 Nov 2020 00:17 }
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

PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }

PROCEDURE PLOT_STRAIN_RATES_BOX (LgSNfirst, LgSNlast: real);
{ ----- Constructs box for temperature DFM-map and labels the axes ----- }

PROCEDURE IDENTIFY_CONTOURS;
{ ----- Identify the time contours and add the date ----- }

PROCEDURE IDENTIFY_FIELDS;

PROCEDURE CALC_STRAIN_RATES_MAP;

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
	DfmModls;

CONST
	C_num_cntrs			=	maxcontournumber+1;
	C_num_bndrys		=	numberofmechanisms*2;	{	estimate	}

	xVGA = 640;	{	x width  of original Turbo Pascal graphics device }
	yVGA = 200; {	y height of original Turbo Pascal graphics device }

TYPE
	TP_zone_list	=	^T_zone_list;
	T_zone_list		=	RECORD
								x1,y1,x2,y2	:	Word;
								next			:	TP_zone_list;
							END;

	T_all_contours		= ARRAY [1..maxcontournumber,0..max_steps] OF Integer;
	T_contour_reals	= ARRAY [0..maxcontournumber] OF a_real;

	E_n_bndrys		=	1..C_num_bndrys;
	T_bndry_item	=	RECORD
								stress_hi	:	a_real;
								id_hi			:	E_mech;
								stress_lo	:	a_real;
								id_lo			:	E_mech;
								stress_mn	:	a_real;
							END;
	T_bndry_table	=	ARRAY [E_n_bndrys] OF T_bndry_item;

	E_n_stress		=	0..C_num_cntrs;	
	T_field_stress	=	RECORD
								stress	:	a_real;
								id			:	E_mech;
								rate		:	a_real;
								visible	:	BOOLEAN;
								converged:	BOOLEAN;
							END;
	T_field_ids		=	ARRAY [E_n_stress] OF T_field_stress;

CONST

	xfac0	: a_real	= 0.125196; { x-axis origin }
	yfac0	: a_real	= 0.050251; { y-axis origin } 
	xfacN	: a_real	= 0.782473; { x-axis limit }
	yfacN	: a_real	= 0.904523; { y-axis limit }

	{ The two text directions available }
	TextDirect : array[0..1] of string[8] = ('HorizDir', 'VertDir');

	{ The Horizontal text justifications available }
	HorizJust  : array[0..2] of string[10] = ('LeftText', 'CenterText', 'RightText');

	{ The vertical text justifications available }
	VertJust   : array[0..2] of string[10] = ('BottomText', 'CenterText', 'TopText');

	C_1 = 0.193;	{	1/(3.sqrt(3))	}
	C_2 = 1;
	C_3 = 25.504;	{	Vickers indenters	}

VAR
	GraphDriver :	INTEGER;  { The Graphics device driver }
	GraphMode   :	INTEGER;  { The Graphics mode value }
	Error		:	INTEGER;
	MaxX  		:	word;     { The maximum resolution of the device m800x600 }
	MaxY  		:	word;     { The maximum resolution of the device m800x600 }
	HalfX, HalfY:	word;
	ErrorCode   :	INTEGER;  { Reports any graphics errors }
	MaxColor    :	word;     { The maximum color value available }
	st          :	String;   { Dummy string used with Str() and OutText() }
	xoffset,yoffset,xlength,ylength,xend,yend	:	integer;
	xfactor, 
	yfactor		:	REAL;
	Ch          :	CHAR;
	skip        :	BOOLEAN;
	empty_zones	:	TP_zone_list;

	pointcount						:  T_mecharray;
	temp_position, stress_position	:  T_mecharray;
	contour			:	T_contour_reals;
	contourmark		:	T_contour_reals;

	LgSNfirst		:	a_real;
	LgSNlast		:	a_real;
	LgSNstep		:	a_real;
	Lgt_first, Lgt_last, Lgt_step	:	a_real;
	sqrt_factor		:	a_real;

	last_Rate	:	a_real;
	Rate			:	a_real;
	LgS			:	a_real;
	LgHN			:	a_real;
	hint_stress	:	a_real;
	Stress		:	a_real;
	xr, yr			:	a_real;
	A, A_dot, Load	:	a_real;
	H, t, dt			:	a_real;
	shear_mod		:	a_real;

	code	:	INTEGER;
	quit	:	BOOLEAN;
	c		:	Char;
	s	:	String;
	f	:	Text;

	x_last, x_now	:	INTEGER;
	field_ids		:	T_field_ids;

	n_bndrys, last_n_bndrys			:	E_n_bndrys;
	bndry_tabl, last_bndry_tabl	:	T_bndry_table;

{---------------------------------------------------------------------------}
procedure Abort(Msg : string);
begin
	Writeln(Msg, 'GraphErrorMsg(GraphResult): ', GraphErrorMsg(GraphResult));
	Writeln(db,Msg, 'GraphErrorMsg(GraphResult): ', GraphErrorMsg(GraphResult));
  Halt(10);
end;
{---------------------------------------------------------------------------}
procedure GraphicsErrorDump;
begin
	ErrorCode := GraphResult;               { error? }
	Writeln('Graphics  error: ',
		GraphErrorMsg(ErrorCode));
	Writeln(db,'Graphics  error: ',
		GraphErrorMsg(ErrorCode));
	CloseGraph;
	Close(db);
	Finish(6);

end;
{---------------------------------------------------------------------------}
procedure 	myLine(xx1,yy1,xx2,yy2: Integer);
{ Procedure in the original TurboPascal but unaccountably not documented in fpc }
begin
	IF xx1 < 0 THEN 
		BEGIN
			WriteLn(db,'xx1 less than zero! ',xx1);
			xx1 := 0;
		END;
	IF xx2 < 0 THEN 
		BEGIN
			WriteLn(db,'xx2 less than zero! ',xx2);
			xx2 := 0;
		END;
	IF yy1 < 0 THEN 
		BEGIN
			WriteLn(db,'yy1 less than zero! ',yy1);
			yy1 := 0;
		END;
	IF yy2 < 0 THEN 
		BEGIN
			WriteLn(db,'yy2 less than zero! ',yy2);
			yy2 := 0;
		END;
	MoveTo(xx1,yy1);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

	LineTo(xx2,yy2);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
end;
{---------------------------------------------------------------------------}
PROCEDURE BoxDefaults;
{ Select the maximum color in the Palette for the drawing color }
{ This is the first time we actually draw graphics on screen }
VAR
	vp: ViewPortType;
BEGIN
	SetColor(white);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	SetTextJustify(LeftText, CenterText);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	SetTextStyle(DefaultFont, HorizDir, 1);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	SetViewPort(0, 0, MaxX, MaxY, ClipOn);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	Writeln(db,'No obvious Graphics  errors in BoxDefaults().');

	GetViewSettings(vp);
	IF vp.x1 <>0 THEN
		Writeln(db,'viewport error x1: ',vp.x1);
	IF vp.y1 <>0 THEN
		Writeln(db,'viewport error y1: ',vp.x2);
	IF vp.x2 <>MaxX THEN
		Writeln(db,'viewport error x2: ',vp.x2);
	IF vp.y2 <>MaxY THEN
		Writeln(db,'viewport error y2: ',vp.y2);
	IF vp.clip <>ClipOn THEN
		Writeln(db,'viewport error clip: ',vp.Clip);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	Writeln(db,'No obvious ViewPort  errors in BoxDefaults().');


	empty_zones:=NIL;	{	should really DISPOSE of the list first..	}
END; { BoxDefaults }

{---------------------------------------------------------------------------}
Function Max(a,b:Real): Real;
begin
	IF (a>b) THEN
		Max := a
	ELSE
		Max := b;
end;	{	function Max	}
{---------------------------------------------------------------------------}
PROCEDURE Range_Check (s:String);
BEGIN
	Writeln(db,s);
	Graph.OutTextXY(0,0,s);
END;	{	Range_Check	}
{---------------------------------------------------------------------------}
PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }
VAR
	st	:	STRING;
	newmode	:	integer;

	lo, hi, tw, th: integer;
	found: boolean;
CONST
  Line2 = 'We are now in 800 x 600 x 256 colors! - Press [Return] ';

BEGIN
	{ We want an 8 bit mode }
	GraphDriver := D8bit;
	GraphMode := m800x600; 	{ 0..599 x 0..799 x 0..255 }
	
	InitGraph(GraphDriver,GraphMode,'');
	{ Make sure you always check graphresult! }
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN
		BEGIN
			CloseGraph;
			Writeln('Initializing.. 800x600x256 is not supported!');
			Writeln('Graphics initialization error: ',
				GraphErrorMsg(ErrorCode));
			Writeln(db,'Initializing.. 800x600x256 is not supported!');
			Writeln(db,'Graphics initialization error: ',
				GraphErrorMsg(ErrorCode));
			Writeln('This program cannot continue.');
			Finish(6);
		END;
	MaxX := getMaxX;          { Get screen resolution values only after Initgraph() }
	MaxY := getMaxY;

	Randomize;                { init random number generator }
	HalfX := Round(MaxX);
	HalfY := Round(MaxY);

	xoffset     := Round(xfac0 * MaxX);
	yoffset     := Round(yfac0 * MaxY);
	xlength     := Round(xfacN * MaxX);
	ylength     := Round(yfacN * MaxY);
	xend        := xoffset+xlength;
	yend        := yoffset+ylength;
	xfactor		:= MaxX/(MaxX-1);
	yfactor		:= MaxY/(MaxY-1);

	empty_zones:=NIL;

END; { Initialize }
{---------------------------------------------------------------------------}
PROCEDURE DETECT_SKIP;
BEGIN
{ ----- Detect <Esc> key if pressed  ----- }
	IF modefast THEN
		Exit;		{	i.e. quit this procedure	}

	IF Keypressed THEN
		BEGIN
			Ch := ReadKey;
			IF Ch = Esc THEN
				skip:=TRUE                       { skip }
			ELSE IF (Ch = #0 ) THEN			{ function key, throw away }
				Ch := Readkey
			ELSE IF (Ch = ' ') THEN					{	pause	}
				BEGIN
					REPEAT UNTIL Keypressed;
					Ch := Readkey;
					IF (Ch = #0 ) THEN			{ function key, throw away }
						Ch := Readkey
				END;
		END;
END;	{	DETECT_SKIP	}
{---------------------------------------------------------------------------}
PROCEDURE ClearTextSpace(x1,y1,x2,y2: REAL);
VAR
	xx1,
	xx2		:	Word;
	yy1,
	yy2		:	Word;
	Ch			:	CHAR;
	vp			:	ViewPortType;
	ErrorStr	:	String;
	z			:	TP_zone_list;
	oldcol		:	ColorType;

BEGIN
	oldcol := GetColor;
	SetColor(green);
	xx1:= Round(xfactor*x1*MaxX/xVGA);
	yy1:= Round(yfactor*y1*MaxY/yVGA);
	xx2:= Round(xfactor*x2*MaxX/xVGA);
	yy2:= Round(yfactor*y2*MaxY/yVGA);

{	Check that we are inside GRAPH plotting area, not full screen.	}
	IF yy2 > yend-1 THEN
		yy2:=yend-1;
	IF xx2 > xend-1 THEN
		xx2:=xend-1;
	IF yy1 < yoffset+1 THEN
		yy1:=yoffset+1;
	IF xx1 < xoffset+1 THEN
		xx1:=xoffset+1;

	IF yy1 > yend-1 THEN
		yy1:=yend-1;
	IF xx1 > xend-1 THEN
		xx1:=xend-1;
	IF yy2 < yoffset+1 THEN
		yy2:=yoffset+1;
	IF xx2 < xoffset+1 THEN
		xx2:=xoffset+1;
	
	myLine(xx1,yy1,xx1,yy2);
	myLine(xx1,yy1,xx2,yy1);
	myLine(xx2,yy2,xx2,yy1);
	myLine(xx2,yy2,xx1,yy2);

{	Now add the cleared zone to (the front of) the global list
	of empty zones, but FIRST we SHOULD really check whether we
	are clearing an already-cleared zone! i.e. a label which overlaps
	with the info box in the top left of the graph in the case of TIN.
	If we get an overlap then we should abort - but how do we then stop
	the string being written there anyway ??? PMS 4-February-1988 11:15
}
	New(z);
	z^.x1:=xx1; z^.y1:=yy1;
	z^.x2:=xx2; z^.y2:=yy2;
	z^.next:=empty_zones;
	empty_zones:=z;

{	Now clear the zone	}
	SetViewPort(xx1,yy1,xx2,yy2,ClipOn);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	ClearViewPort;
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	SetViewPort(0,0,MaxX,MaxY,ClipOn);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	SetColor(red);
	Rectangle(xx1,yy1,xx2,yy2);


	SetColor(oldcol);

	WRITELN(db,'Exiting ClearTextSpace: ',round(x1),' ',round(y1),' ',round(x2),' ',round(y2));

END;	{	ClearTextSpace	}
{---------------------------------------------------------------------------}
PROCEDURE OurOutTextXY(x,y: INTEGER; s: String);
	{	This converts 640x200 original coords to current pixel x/y coordinates }

	{	This is to intercept plotting instructions such
		that we can write HPGL files in a future extension.	}
VAR
	xx, yy	:	integer;
	
BEGIN
	xx:= Round(xfactor*x*MaxX/xVGA);
	yy:= Round(yfactor*y*MaxY/yVGA);
	Graph.OutTextXY(xx,yy,s);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

END;	{	OurOutTextXY	}

{---------------------------------------------------------------------------}
PROCEDURE vertical_text(xstart,ystart:integer; lbl:lblstring);

{ Writes a string label vertically in graphics}
VAR
	i	:	Byte;

BEGIN
	SetTextStyle(DefaultFont, VertDir, 1);
	OurOutTextXY(xstart,Round(ystart+ 0.5*lbllength),lbl);

	SetTextStyle(DefaultFont, HorizDir, 1); 
END;

{---------------------------------------------------------------------------}
PROCEDURE PLOT_STRAIN_RATES_BOX (LgSNfirst, LgSNlast: real);

{ ----- Constructs box for temperature DFM-map and labels the axes ----- }

var
	xscale, yscale   :	INTEGER;
	Tinterval        :	REAL;
	xmark, ymark     :	INTEGER;
	scale			:	INTEGER;
	TW, TH			: Integer;
	T, Tnormalised		:	Real;
	S, Sfirst, Slast	:	Real;
	LgSfirst, LgSlast	:	Real;
	minor				:	Byte;	{	The number of minor marks between big marks }

BEGIN
	{SetGraphMode(GraphMode);}
	BoxDefaults;

{ --------- Draw  Box ----------}
	SetColor(white);

	myLine(xoffset,yoffset,xoffset,yend);
	myLine(xoffset,yoffset,xend,yoffset);
	myLine(xend,yend,xoffset,yend);
	myLine(xend,yend,xend,yoffset);

{ --------- Put on NORMALIZED STRESS scale --------- }
	minor   := 1;	{	because it's a log axis, so minor marks are not useful }

	yscale  := round(LgSNlast*minor - LgSNfirst*minor);
	
	SetColor(yellow);
	FOR scale := (round(LgSNfirst*minor)) to (round(LgSNfirst*minor) + yscale - 1) DO
		BEGIN
			ymark := yoffset +
				ylength - round((scale - round(LgSNfirst*minor))/yscale*ylength);
			IF (frac(scale/minor) = 0)  THEN
				myLine(xoffset,ymark,xend,ymark)
			ELSE
				myLine(xoffset,ymark,xoffset+3,ymark);
		END;

{ --------- Put on ABSOLUTE STRESS scale ---------- }
	{	in Mpa, but shmod is in GPa so multiply by 1000	}

	Sfirst	:=	shmod*SNfirst*1.0e3;	{	shmod is at 300 K	}
	Slast 	:=	shmod*SNlast *1.0e3;	{	shmod is at 300 K	}
	LgSfirst	:=	Ln(Sfirst)/Ln10;
	LgSlast 	:=	Ln(Slast)/Ln10;

	IF (Sfirst <= 1.0e-9) THEN
		BEGIN
			OurOutTextXY(xoffset+2,100,'Error, low stress limit too low!');
			Str(Sfirst:4:1,st);
			OurOutTextXY(xoffset+2,105,st);
			IF NOT modefast THEN
				Repeat Until Keypressed;
		END;
	S	:=	1.0e-9;
	REPEAT
		S := S * 10;
	UNTIL (S >= Sfirst);

	Str(S:4:1,st);
	IF (S < Slast) THEN
		OurOutTextXY (585,189,st);

	ymark		:= 0;
	REPEAT
		IF (S > Sfirst) and (S < Slast) THEN
			ymark := yoffset +
				round(ylength*(1 - (Ln(S)/Ln10 - LgSfirst)/
												(LgSlast - LgSfirst)));
		IF (ymark >= yoffset) AND (ymark <= yend) THEN
			myLine(xend,ymark,xend-6,ymark);

{ -----	Nested IFs because of BUG with 8087 chip if IFs too complicated	}
		Str(S:4:1,st);
		IF (S >= (Slast/10)) THEN
			IF (S <= Slast) THEN
				OurOutTextXY (585,10,st);
		S := S * 10;
	UNTIL (S  >= Slast);

{ --------- Label Normalised Stress Axes           ---------- }
	Str(LgSNlast:4:2,st);
	OurOutTextXY(42,10,st);
	Str(LgSNfirst:4:2,st);
	OurOutTextXY(42,189,st);

{ --------- Put on NORMALIZED TEMPERATURE scale ---------- }

	xscale  := round((TNlast - TNfirst)*100);
	SetColor(yellow);
	FOR scale := (round(TNfirst*100)) to (round(TNfirst*100) + xscale - 1) DO
		BEGIN
			xmark :=  xoffset +
				round((scale- round(TNfirst*100))/xscale*xlength);
			IF (frac(scale/20) = 0) THEN
			myLine(xmark, yend,xmark,yoffset);
			IF (frac(scale/10) = 0) THEN
			myLine(xmark, yend,xmark,(yend - 4));
		END;

{ --------- Put on the CENTIGRADE TEMPERATURE scale ---------- }

	xmark     := 0;
	T         := -400;
	Tinterval := 100;
	IF round((TNlast - TNfirst)*tmelt/200) > 10 THEN Tinterval := 200;
	SetColor(yellow);
	repeat
		T  := T + Tinterval;
		Tnormalised := (T + 273)/tmelt;
		IF (Tnormalised > TNfirst) and (Tnormalised < TNlast) THEN
			xmark := xoffset +
				round((Tnormalised - TNfirst)/(TNlast - TNfirst)*xlength);
		IF (xmark >= xoffset) AND (xmark <= xend) THEN
			myLine(xmark,yoffset,xmark,yoffset+3);

		Str(round(T):6,st);
		IF (Tnormalised>=TNfirst) THEN
			IF (Tnormalised<(TNfirst+(Tinterval/tmelt))) THEN
				OurOutTextXY(80,5,st);
	until (Tnormalised > TNlast);

	Str(TNfirst:4:2,st);
	OurOutTextXY(70,196,st);
	Str(TNlast:4:2,st);
	OurOutTextXY(569,196,st);

	Str(round(T - Tinterval):6,st);
	OurOutTextXY(511,5,st);

{ ----- Label horizontal and vertical axes of graph window ----- }

	OurOutTextXY(200,196,' NORMALISED TEMPERATURE T/Tm');
	OurOutTextXY(216,5,'     TEMPERATURE  (C)     ');
	vertical_text(56,100,'NORM SHEARSTRESS');
	vertical_text(599,100,'STRESS   (MPa)  ');

END;   {PLOT_STRAIN_RATES_BOX.    }

{---------------------------------------------------------------------------}
PROCEDURE PLOT_STRAIN_RATES_INFO;

{ ----- Information box in top-right corner ----- }
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
	ClearTextSpace(456,12,630,55);
	OurOutTextXY(465,16,matlname);
	IF (Gsize*1.0e6 < 0.1) THEN	{	less than 0.1 microns, do in nm	}
		BEGIN
			Str((Gsize*1.0e9):4:1,st);
			OurOutTextXY(465,24,'d = '+st+' nm');
		END
	ELSE
		BEGIN
			Str((Gsize*1.0e6):4:1,st);
			OurOutTextXY(465,24,'d = '+st+' um');
		END;
	OurOutTextXY(465,48,date_string);

END;	{	PLOT_STRAIN_RATES_INFO	}
{---------------------------------------------------------------------------}
PROCEDURE DRAW_FIELD_BOUNDARY (x,y : Integer);

CONST
	s1  =  2;
	s2  =  1;

BEGIN
	{	This is called within the Stress-Loop, within the Temperature-Loop,
			so the plotting window is already set to the graph axes	}

	myLine(x-s1, y, x+s1,y);
	myLine(x-s1, y+s2, x+s1,y+s2);

END;   {DRAW_FIELD_BOUNDARY.   }
{---------------------------------------------------------------------------}
PROCEDURE DRAW_FIELD_LINE(i, j: E_n_stress);
VAR
	y_last, y_now		:	Integer;

BEGIN
	{	This is called within the Stress-Loop, within the Temperature-Loop,
			so the plotting window is already set to the graph axes	}

	WITH bndry_tabl[i] DO
		y_now := round(ylength*(1 - (stress_mn - LgSNfirst)/(LgSNlast - LgSNfirst)));
	WITH last_bndry_tabl[j] DO
		y_last := round(ylength*(1 - (stress_mn - LgSNfirst)/(LgSNlast - LgSNfirst)));

	SetLineStyle(DashedLn,0,ThickWidth);
	myLine(x_last, y_last, x_now, y_now);
	SetLineStyle(SolidLn,0,NormWidth);

END;   {DRAW_FIELD_LINE   }
{---------------------------------------------------------------------------}
PROCEDURE IDENTIFY_CONTOURS;

{ ----- Identify the time contours and add the date ----- }

BEGIN
	Flush(db);

	ClearTextSpace(96,159,257,183);
	OurOutTextXY(96,165,'    CONTOURS     ');
	IF ((contour[1] < 99999 ) AND ( contour[1] >= 1 )) THEN
		Str(contour[1]:7:0,st)
	ELSE
		Str(contour[1]:7,st);
	convert_number (contour[1], st, -1);
	OurOutTextXY(96,170,' First = '+st+' /s ');
	IF ((contour[contournumber] < 99999 ) AND ( contour[contournumber] >= 1 )) THEN
		Str(contour[contournumber]:7:0,st)
	ELSE
		Str(contour[contournumber]:7,st);
	convert_number (contour[contournumber], st, -1);
	OurOutTextXY(96,178,' Last  = '+st+' /s ');

END;    {IDENTIFY_CONTOURS.    }
{---------------------------------------------------------------------------}
PROCEDURE IDENTIFY_FIELDS;


	
VAR
	P1,P2				:	integer;
	r1,r2				:	a_real;
	x1,y1,x2,y2			:	a_real;
	x_shift				:	a_real;
	y_shift				:	a_real;
	x0,y0				:	Word;
	mech				:	E_mech;
	
	{	local versions of these..	}
	xoffset, yoffset	:	a_real;
	xend, yend			:	a_real;

BEGIN
{ This procedure had the implicit assumption that there were 80
	lines to the screen, even though it was general with respect to
	the number of graphics pixels on the screen.
}
	Flush(db);

	xoffset	:=	xfac0*(MaxX-1);
	yoffset	:=	yfac0*(MaxY-1);
	xend	:=	xoffset + xfacN*(MaxX-1);
	yend	:=	yoffset + yfacN*(MaxY-1);

{ ----- Position and print the remaining field labels ----- }
	SetColor(brown);

	FOR mech := null TO rel_drag DO
		IF (pointcount[mech] > (steps*steps/100)) and (pointcount[mech] > 4) THEN
			BEGIN
				r1  := ((temp_position[mech]/steps)/pointcount[mech]*64) + 7;
				r2  := (1 - stress_position[mech]/(pointcount[mech]*steps))*22 + 2;

{ ----- Don't check for validity here in character co-ords, but in
			graphics co-ords after conversion. PMS 4-February-1988 10:50 	}
				CASE { mechID[mech] } mech OF
					null:  		st:='ELASTIC';
					re_cryst:	st:='RECRYST';
					b_diff:  	st:='DIFF-B';
					v_diff:  	st:='DIFF-V';
					plc_ht:  	st:='PL-(HT)';
					plc_lt:  	st:='PL-(LT)';
					o_glide:  	st:='OBSTCLE';
					pls_drag:  	st:='PEIERLS';
					phn_drag:  	st:='PHONON';
					rel_drag:  	st:='RLTVSTC';
					ELSE
						st:='ERROR';
				END;	{	Case	}
{$IFDEF debug}
				writeln(db,st,' ',temp_position[mech]:5:0,stress_position[mech]:5:0,pointcount[mech]:5:0);
{$ENDIF}

				x1:=(r1-1)*639/80;
				y1:=(r2-0.7)*199/25;
				x2:=(r1+Length(st)+0.2)*639/80;
				y2:=(r2+0.5)*199/25;

				x_shift := 0.0;
				IF (x1 < xoffset ) THEN
					x_shift := xoffset - x1 + 1.6;
				IF (x2 > xend ) THEN
					x_shift := xend - x2 + 1.6;

				y_shift := 0.0;
				IF (y1 < yoffset ) THEN
					y_shift := yoffset - y1 + 4;
				IF (y2 > yend ) THEN
					y_shift := yend - y2 + 4;

				x0:=Round(r1*639/80 + x_shift);
				y0:=Round(r2*199/25 + y_shift);
				ClearTextSpace(x1+x_shift,y1+y_shift, x2+x_shift,y2+y_shift);
				OurOutTextXY(x0, y0, st);
			END;

END;    {IDENTIFY_FIELDS.    }
{---------------------------------------------------------------------------}
PROCEDURE Contours_Init;
VAR
	c	:	E_n_stress;
BEGIN
	FOR c := 0 TO C_num_cntrs DO
		BEGIN
			field_ids[c].stress := -1.0;
			field_ids[c].id     := null;
			field_ids[c].rate   := 1.0e-20;
			field_ids[c].visible:= FALSE;
			field_ids[c].converged:= FALSE;
		END;
END;	{	Contours_Init	procedure }
{---------------------------------------------------------------------------}
{$IFDEF cntrfix }
{$I \dfmap\old_cntr.pas	}
{$ELSE}
PROCEDURE Contours_Loop (temp_step: Word);
VAR
	field			:	E_mech;

	c,cc,
	n_actual		:	E_n_stress;
	root_factor	:	a_real;
	Rate			:	a_real;
	LgSN			:	a_real;
	LgRatio	  	:	a_real;
	hint_stress	:	a_real;
	mark_step	:	a_real;
	min_rate_on_plot	:	a_real;
	max_rate_on_plot	:	a_real;
	prev_stress, prev_rate	:	a_real;

	{------------------------------------------------------------------------}
PROCEDURE Contours_debug;
VAR
	c	:	E_n_stress;
BEGIN
	Writeln(db,'[c]   LgCntr    C''mark     stress    rate        visible field');
	FOR c := n_actual DOWNTO 0 DO
		WITH field_ids[c] DO
		BEGIN	{	For loop & With block	}
			IF (c>=n_actual) OR (c<=0) THEN
				Write(db, c:3,'     --limit--        ',stress:8:3,' ')
			ELSE
				Write(db, c:3,' ',(Ln(contour[c])/Ln10):8:1,
					'  ',contourmark[c]:9:5,
					'  ',stress:8:3,' ');
			Write(db, rate:12,' ');
			IF visible THEN 
				Write(db,'  Visible ') 
			ELSE 
				Write(db,'Invisible ');
			WRITE_FIELDNAME(id);
			IF converged THEN 
				Write(db,'  ') 
			ELSE 
				Write(db,' *');
			WriteLn(db);
		END;	{	For loop & With block	}
	WriteLn(db);
END;	{	Contours_debug	}
	{------------------------------------------------------------------------}
PROCEDURE Iterate_One_Contour(previous_stress, previous_rate, LgSN: a_real; 
																				c: E_n_stress);
CONST
	iter_limit	=	13;
VAR
	RateRatio, SNdiff, strain_rate		:	a_real;
	step, factor	:	a_real;
	n	:	Byte;
		{---------------------------------------------------------------------}
PROCEDURE Bisect;
VAR
	Rate_ratio	:	a_real;
BEGIN
	LgSN := (LgSN + previous_stress)/2.0;
	SNdiff := LgSN - previous_stress;

{	Another (better) estimate, if everything is NOT weird	}
	IF ((previous_rate > contour[1]) 
		AND (previous_rate < contour[contournumber]))
 	AND ((strain_rate > contour[1]) 
		AND (strain_rate < contour[contournumber])) THEN
		BEGIN
			Rate_ratio	:= (contour[c] - previous_rate)/(strain_rate - previous_rate);
			LgSN := previous_stress + (LgSN - previous_stress)*Rate_ratio;
{$IFDEF contour}
			Write(db,' !!');
{$ENDIF}
		END;

	SNdiff := LgSN - previous_stress;
END;	{	Bisect	}
		{---------------------------------------------------------------------}
BEGIN		{	Iterate_One_Contour	}
{$IFDEF contour}
		WriteLn(db);
{$ENDIF}
	step := 1.0;
	n := 0;
	SNdiff := LgSN - previous_stress;
	REPEAT	

		STRAIN_RATES (TN, LgSN, strain_rate, field, hint_stress);
		RateRatio := (strain_rate/contour[c]);
		IF (RateRatio < 1) THEN
			RateRatio := 1/RateRatio;
		Inc(n);
		Flush(db);

{$IFDEF contour}
		WriteLn(db);
		WriteLn(db,
			' c =',c:2,
			' Rates:   ',previous_rate:12,'->',field_ids[c].rate:12,' ->',strain_rate:12,
			' LgSN :   ',previous_stress:8:3,'->',field_ids[c].stress:8:3,' ->',LgSN:8:3);
		Write(db,
			' SNdiff =',SNdiff:8:3,
			' factor =',factor:8:3,
			' (rate/contour)=',(strain_rate/contour[c]):12,
			' inv.=',RateRatio:12);
{$ENDIF}
		field_ids[c].id		:= field;				{	and update..	}

		IF ((contour[c] > strain_rate) AND (contour[c] < previous_rate)) 
		OR ((contour[c] < strain_rate) AND (contour[c] > previous_rate)) THEN
			BEGIN
			{	Throw away the field_ids[c].stress, keep previous (& current)	}
				field_ids[c].rate			:= strain_rate;
				field_ids[c].stress		:= LgSN;
				Bisect;
{$IFDEF contour}
				WriteLn(db,' BISECT- ');
{$ENDIF}
			END
		ELSE
		IF ((contour[c] > strain_rate) AND (contour[c] < field_ids[c].rate)) 
		OR ((contour[c] < strain_rate) AND (contour[c] > field_ids[c].rate)) THEN
			BEGIN
			{	Throw away the previous_stress, keep field_ids[c].stress (& current)	}
				previous_rate			:= field_ids[c].rate;
				previous_stress		:= field_ids[c].stress;
				field_ids[c].rate			:= strain_rate;
				field_ids[c].stress		:= LgSN;
				{	previous is now 'really' field_ids[c].stress	}
				Bisect;
{$IFDEF contour}
				WriteLn(db,' BISECT+ ');
{$ENDIF}
			END
	{		Split to the limits of the plot (if the contour is going to appear on
			the plot, biasing heavily towards the current value of stress.	}
		ELSE 
			BEGIN		{ ==========	extrapolation options ==========	}
				{	'previous' values are not relevant or interesting here	}
				previous_rate			:= field_ids[c].rate;
				field_ids[c].rate		:= strain_rate;

				previous_stress		:= field_ids[c].stress;
				field_ids[c].stress	:= LgSN;

				IF ((strain_rate > contour[c]) AND (contour[c] > field_ids[0].rate)) THEN
					BEGIN
						LgSN := (5 * field_ids[c].stress + field_ids[0].stress)/6.0;
{$IFDEF contour}
						WriteLn(db,' DROP    ');
{$ENDIF}
					END
				ELSE IF ((strain_rate < contour[c]) AND (contour[c] < field_ids[n_actual].rate)) THEN
					BEGIN
						LgSN := (5 * field_ids[c].stress + field_ids[n_actual].stress)/6.0;
{$IFDEF contour}
						WriteLn(db,' PUSH UP ');
{$ENDIF}
					END
				ELSE	{	catchall - very slow	}
					BEGIN
						factor := 1.0 + step;
						step := step/1.3;
						IF (strain_rate > contour[c]) THEN
							LgSN := field_ids[c].stress * factor	{	since it is -ve	}
						ELSE
							LgSN := field_ids[c].stress / factor;	{	since it is -ve	}
{$IFDEF detail}
						WriteLn(db,' FACTOR  ');
{$ENDIF}
					END;
				SNdiff := LgSN - field_ids[c].stress;
			END;	{ ==========	extrapolation options ==========	}

	UNTIL	
		{	((Abs(SNdiff) < 0.5*mark_step) 
		AND (RateRatio < root_factor))	}
	(RateRatio < root_factor)
	OR (n >= iter_limit);
	{	Convergence when we are closer in strain rate than any other
		contour (for low temperatures), or closer in stress than the
		'step length' on the map (high temperatures).

		Note that we have to be quite careful that the values of .stress
		and .rate in field_ids[c] are the ones that the loop actually
		converged on, and not the values set up for the 'next' iteration.
		30-April-1990 23:34 PMS
	}
		IF (n >= iter_limit) THEN		{	exit this loop	}
			BEGIN
				field_ids[c].converged := FALSE;
{$IFDEF contour}
				Writeln(db,' EXIT LOOP');
{$ENDIF}
			END
		ELSE
			field_ids[c].converged := TRUE;

END;	{	Iterate_One_Contour	}
	{------------------------------------------------------------------------}
PROCEDURE Iterate_All_Contours;
{	This procedure assumes that field_ids contains some kind of estimate
	of the stress and strain rate, but a very poor one.  The main routine
	Contours_Loop assumes that we have a very good estimate.	
	PMS 27-April-1990 00:45 }
VAR
	c	:	E_n_stress;
	previous_stress, previous_rate	:	a_real;
BEGIN
{$IFDEF contour}
	Writeln(db,'Stress incr.target:',{0.5*}mark_step:8:3,
					' RateRatio target: ',root_factor:8:3);
	Writeln(db);
{$ENDIF}
	FOR c := contournumber DOWNTO 1 DO
		BEGIN
		{	start them off at a self-consistent point, either the top limit
			or the previous (solved) contour	}

			previous_stress := field_ids[c+1].stress;		
			previous_rate := field_ids[c+1].rate;			
			LgSn := previous_stress * 1.01 ;	{	guess, larger -ve so lower stress	}

			Iterate_One_Contour(previous_stress, previous_rate, LgSN, c);
		END;
END;	{	Iterate_All_Contours	}
	{------------------------------------------------------------------------}
PROCEDURE Finish_Contours;
VAR
	c	:	E_n_stress;
BEGIN
	Writeln(db,'Finish_Contours called.');

	FOR c := contournumber DOWNTO 1 DO
		Writeln(db,'contournumber: ',c);
		Writeln(db,'contournumber: ',c, 'fields_id: ',field_ids[c].id);
		contourmark[c] := (field_ids[c].stress - LgSNfirst)/(LgSNlast - LgSNfirst);
{$IFDEF detail}
	Writeln(db,'Final values for this call to Contours_Loop');
	Contours_debug;
{$ENDIF}
	Writeln(db,'Finish_Contours ended.');
END;	{	Finish_Contours	}
	{------------------------------------------------------------------------}
BEGIN	{	Procedure Contours_Loop	}
	
	n_actual := contournumber + 1;
	root_factor := sqrt(cntrfactor);
	mark_step := LgSNstep/(LgSNlast - LgSNfirst);

	STRAIN_RATES (TN, LgSNlast, Rate, field, hint_stress);
	field_ids[n_actual].stress := LgSNlast;
	field_ids[n_actual].id     := field;
	field_ids[n_actual].rate   := Rate;
	max_rate_on_plot := Rate;

	Writeln(db);


	STRAIN_RATES (TN, LgSNfirst, Rate, field, hint_stress);
	field_ids[0].stress := LgSNfirst;
	field_ids[0].id     := field;
	field_ids[0].rate   := Rate;
	min_rate_on_plot := Rate;

	Writeln(db);

{$IFDEF contour}
	Writeln(db);
	Writeln(db,'Values with LIMITS overwritten');
	Contours_debug;
{$ENDIF}

	IF (TN <= 0.0) THEN	{	at 0 K	}
		BEGIN

			STRAIN_RATES (TN, (LgSNfirst+LgSNlast)/2, Rate, field, hint_stress);

	Writeln(db);
	Writeln(db,'  <- 0 K HINT CALC');
	Writeln(db,'TN=',TN:8:3,'  (0 K) hint stress is',hint_stress:8:3);

			FOR c := 1 TO contournumber DO
				BEGIN
					field_ids[c].stress := hint_stress;		{	Obst or Peierls stress	}
					field_ids[c].id     := field;
					field_ids[c].rate   := contour[c];
					field_ids[c].visible:= TRUE;
				END;
{			field_ids[n_actual].rate   := field_ids[n_actual-1].rate;	}
			Finish_Contours;
			Exit;					{	***	return from Contours_Loop here	***	}
		END;

	IF (TN > 0.0) 
	AND (temp_step < 1) THEN		{	No previous calcs., but not at 0 K	}
		BEGIN
			LgSN := (LgSNfirst+LgSNlast)/2;
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
{$IFDEF detail}
			Writeln(db,'  <- HINT ');
{$ENDIF}
{			FOR c := 0 TO n_actual DO	}
			FOR c := 1 TO contournumber DO	
				BEGIN
					field_ids[c].stress := LgSN;		
					field_ids[c].id     := field;
					field_ids[c].rate   := Rate;
					field_ids[c].visible:= TRUE;
				END;
			Iterate_All_Contours;
			Finish_Contours;
			Exit;					{	***	return from Contours_Loop here	***	}
		END

	ELSE IF (temp_step = 1) 
	AND (TNfirst <= 0.0) THEN		{	previous step was at 0 K	}
		BEGIN
			Iterate_All_Contours;
			Finish_Contours;
			Exit;					{	***	return from Contours_Loop here	***	}
		END;
{%%%%%%%%%%%%%%%%%%%%%%%%%%%finish%%%%%%%%%%%%%%%%%%%%}
{	IF (temp_step >= 15) THEN Halt(1);						}
	
{ ========== S T A R T == T H E == S E T U P == L O O P ========= }
	{	Do a first pass, using the LgSN values for the PREVIOUS temperature,
		first, check which contours were visible at the PREVIOUS temperature.	}

{	Only bother if we are not on the first temp.	which is temp_step = 0	}
	IF (temp_step >= 1) THEN	
	FOR c := 1 TO contournumber DO
		BEGIN	
			{	This assumes that the last temp. got consistent stresses & strain_rates	}
			IF (field_ids[c].stress <= LgSNlast)
			AND (field_ids[c].stress >= LgSNfirst) THEN
				field_ids[c].visible := TRUE
			ELSE
				field_ids[c].visible := FALSE;

			LgSN := field_ids[c].stress;				{	previous value	}
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
			field_ids[c].id     := field;				{	and update..	}
			field_ids[c].rate   := Rate;
{$IFDEF detail}
			Writeln(db);
{$ENDIF}
		END;

{	Set id for those that dropped off the bottom	}
	FOR c := contournumber DOWNTO 1 DO
		BEGIN
			IF NOT field_ids[c].visible THEN
				field_ids[c].id :=  field_ids[c+1].id; 	{	OK, n_actual preset }
		END;

{	Set id for those that popped off the top	}
	FOR c := 1 TO contournumber DO
		BEGIN
			IF NOT field_ids[c].visible THEN
				field_ids[c].id :=  field_ids[c-1].id; 	{	OK, 0 is preset	}
		END;
{ ========== E N D == T H E == S E T U P == L O O P ========= }
{$IFDEF contour}
	Writeln(db);
	Writeln(db,'Values after the SETUP loop');
	Contours_debug;
{$ENDIF}

{ ========== S T A R T == T H E == C O N T O U R == L O O P ========= }
{	Find stress which gives Rate closest to the required contour	}
	FOR c := 1 TO contournumber DO
		IF field_ids[c].visible THEN
			BEGIN
				cc := n_actual;
				REPEAT
					Dec(cc);
{$IFDEF contour}
					Writeln(db,'c:cc Loop',c:3,cc:3,' ',contour[c]:12,' ',field_ids[cc].rate:12);
{$ENDIF}
				UNTIL (contour[c] >= field_ids[cc].rate) OR (cc = 0);

				IF (contour[c] <= field_ids[0].rate) THEN
				{	contour is off the bottom..	}
					BEGIN
						field_ids[c].id     := field_ids[0].id;	{	and update..	}
						field_ids[c].rate   := field_ids[0].rate;
						field_ids[c].stress := field_ids[0].stress;
{$IFDEF contour}
						Writeln(db,' Contour ',c:2,' under the bottom, OK ');
{$ENDIF}
					END
				ELSE IF (contour[c] >= field_ids[n_actual].rate) THEN
				{	contour is off the top..	}
					BEGIN
						field_ids[c].id     := field_ids[n_actual].id;	{	and update..	}
						field_ids[c].rate   := field_ids[n_actual].rate;
						field_ids[c].stress := field_ids[n_actual].stress;
{$IFDEF contour}
						Writeln(db,' Contour ',c:2,' off the top, OK ');
{$ENDIF}
					END
				ELSE IF (contour[c] = field_ids[cc].rate) THEN
				{	easy, but have to check for it explicitly	}
					BEGIN
						field_ids[c].id     := field_ids[cc].id;	{	and update..	}
						field_ids[c].rate   := field_ids[cc].rate;
						field_ids[c].stress := field_ids[cc].stress;
{$IFDEF contour}
						Writeln(db,' Contour ',c:2,' exact ! OK ');
{$ENDIF}
					END
				ELSE IF (contour[c] > field_ids[cc].rate) THEN
				{	Now interpolate	}
					BEGIN
						prev_rate		:= field_ids[cc].rate;
						prev_stress		:= field_ids[cc].stress;
						LgRatio	:= (contour[c] - prev_rate)/(field_ids[cc+1].rate - prev_rate);
						LgSN := prev_stress + (field_ids[cc+1].stress - prev_stress)*LgRatio;
						Iterate_One_Contour(prev_stress, prev_rate, LgSN, c);
					END
				ELSE
					BEGIN
{$IFDEF debug}
						Writeln(db,' Should never get here ! In DfmPlots.Contour_Loops');
{$ENDIF}
					END;
				contourmark[c] := (field_ids[c].stress - LgSNfirst)/(LgSNlast - LgSNfirst);
			END;	{	For c loop	}

{	It converges EACH contour individually before going on to the next.
	This is inefficient, it should do one pass over all contours, then
	continue passing and updating until all are converged since it uses
	adjacent contours to get an estimate.	}
{ ========== E N D == T H E == C O N T O U R == L O O P ========= }

{$IFDEF detail}
	Writeln(db,'Final values for this call to Contours_Loop');
	Contours_debug;
{$ENDIF}

END;	{	Contours_Loop	procedure }
{$ENDIF}		{	end of IFDEF cntrfix section	}
{---------------------------------------------------------------------------}
PROCEDURE Fields_Loop (temp_step: Word);

VAR
	field,
	field_now,
	field_last,
	next_down_now,
	next_up_now	:	E_mech;
	n_actual		:	E_n_stress;
	centroid	:	T_mecharray;
	spread	:	T_mecharray;
	Rate			:	a_real;
	LgSN			:	a_real;
	hint_stress	:	a_real;
	weight		:	a_real;
	top, bot		:	a_real;
	re_do			:	BOOLEAN;
	boundaries_exist	:	BOOLEAN;
	x_half, y_half, y_now:	Integer;
	c, i, j	 	:	E_n_stress;
	k				:	E_n_bndrys;
	s		:	Word;	{	stress_step	}

	{------------------------------------------------------------------------}
PROCEDURE Find_Boundaries;
VAR
	i, j, item 	:	E_n_stress;
BEGIN
	{ ----- Find the Field boundaries more accurately  ----- }
	{	Note the trouble we go to in order to keep the table sorted,
		so that we don't have to sort it later.	22-March-1990 }
	i := 0;				
	REPEAT
		IF (i+1 > C_num_cntrs) THEN
			Range_Check('Too many boundaries found on first pass')
		ELSE
			Inc(i);
		re_do := FALSE;
		WITH bndry_tabl[i] DO
			BEGIN
				IF ((Abs(stress_hi - stress_lo)/LgSNstep) > 0.5) THEN
					BEGIN
						re_do := TRUE;
						LgSN := stress_mn;
{$IFDEF detail}
						Writeln(db);
{$ENDIF}
						STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);
						IF (field =id_hi) THEN
							stress_hi := LgSN
						ELSE IF(field =id_lo) THEN
							stress_lo := LgSN;
						IF (field <> id_hi)
						AND (field <> id_lo) THEN
							BEGIN	{	a new field in the middle ! }
								IF (n_bndrys+1 > C_num_bndrys) THEN
									Range_Check('Too many boundaries found on interpolation')
								ELSE
									Inc(n_bndrys);						{	make array bigger	}
								FOR item := n_bndrys DOWNTO i+1 DO
									BEGIN	{	Budge up..	happens infrequently	}
										bndry_tabl[item].stress_lo := bndry_tabl[item-1].stress_lo;
										bndry_tabl[item].id_lo 		:= bndry_tabl[item-1].id_lo;
										bndry_tabl[item].stress_hi := bndry_tabl[item-1].stress_hi;
										bndry_tabl[item].id_hi 		:= bndry_tabl[item-1].id_hi;
										bndry_tabl[item].stress_mn := bndry_tabl[item-1].stress_mn;
									END;
								{	..and now overwrite i+1	}
								bndry_tabl[i+1].stress_lo := LgSN;
								bndry_tabl[i+1].id_lo := field;
								bndry_tabl[i+1].stress_hi := stress_hi;
								bndry_tabl[i+1].id_hi := id_hi;
								bndry_tabl[i+1].stress_mn := (stress_hi + LgSN)/2.0;
								{	..and overwrite i	}
								stress_hi := LgSN;
								id_hi := field;
							END;
						stress_mn := (stress_hi + stress_lo)/2.0;
					END;
			END;	{	With block	}
		IF re_do THEN Dec(i);	{	re-do the last one..	}
	UNTIL ( i >= n_bndrys );	{	INCLUDING the new ones..	}

{$IFDEF detail}
	IF NOT (TN <= 0) THEN
		BEGIN
			Writeln(db);
			Writeln(db,'x_last=',x_last:4);
			IF (i >= 1) THEN
				FOR i := 1 to last_n_bndrys DO
					WITH last_bndry_tabl[i] DO
					BEGIN
						write(db,'Boundary:',i:2,' ');
						WRITE_FIELDNAME(id_lo);
						write(db,': ');
						WRITE_FIELDNAME(id_hi);
						write(db,' ',stress_lo:8:3);
						write(db,' ',stress_hi:8:3);
						write(db,' ',stress_mn:8:3);
						write(db,' ',(Abs(stress_hi - stress_lo)/LgSNstep):8:3);
						IF ((Abs(stress_hi - stress_lo)/LgSNstep) > 1.0) THEN
							BEGIN
								write(db,' FIX !');
							END;
						Writeln(db);
					END;
		END;
{$ENDIF}
{$IFDEF debug}
	Writeln(db);
	FOR i := 1 to n_bndrys DO
		WITH bndry_tabl[i] DO
			BEGIN
				write(db,'Boundary#',i:2,' ');
				WRITE_FIELDNAME(id_lo);
				write(db,': ');
				WRITE_FIELDNAME(id_hi);
				write(db,' ',stress_lo:8:3);
				write(db,' ',stress_hi:8:3);
				write(db,' ',stress_mn:8:3);
				write(db,' ',(Abs(stress_hi - stress_lo)/LgSNstep):8:3);
				IF ((Abs(stress_hi - stress_lo)/LgSNstep) > 1.0) THEN
					BEGIN
						write(db,' FIX !');
					END;
				Writeln(db);
			END;
{$ENDIF}

	{ ----- Draw a thick, dashed line for the field boundary  ----- }

	x_now := round(xlength*(TN - TNfirst)/	(TNlast - TNfirst));

	IF (TN <= 0) THEN
		x_last := 0
	ELSE
		FOR i := 1 TO n_bndrys DO
			FOR j := 1 TO last_n_bndrys DO
				WITH bndry_tabl[i] DO
					BEGIN
					{	XOR & AND so that even if both same, only draw once	}
						IF (id_lo = last_bndry_tabl[j].id_lo)
						XOR (id_hi = last_bndry_tabl[j].id_hi) THEN
							DRAW_FIELD_LINE(i,j);
						IF (id_lo = last_bndry_tabl[j].id_lo)
						AND (id_hi = last_bndry_tabl[j].id_hi) THEN
							DRAW_FIELD_LINE(i,j);
					END;
END;	{	Find_Boundaries	}
	{------------------------------------------------------------------------}
PROCEDURE Update_Centroids;
VAR
	i	 	:	E_n_stress;
	field	:	E_mech;
BEGIN
	{ ----- Keep track of mean position of field on the plot ----- }
	FOR field := null TO rel_drag DO
		BEGIN
			spread[field]:= 0;
			centroid[field]:= 0;
		END;

	{	Note that the stress limits on the plot, LgSNfirst & LgSNlast are used EXPLICITLY	}
	WITH bndry_tabl[1] DO
		BEGIN
			spread[id_lo]:= stress_mn - LgSNfirst;
			centroid[id_lo]:= spread[id_lo]/2 + LgSNfirst;
		END;
	FOR i := 2 to n_bndrys DO
		WITH bndry_tabl[i] DO
			BEGIN
				spread[id_lo]:= stress_mn - bndry_tabl[i-1].stress_mn;
				centroid[id_lo]:= spread[id_lo]/2 + bndry_tabl[i-1].stress_mn;
			END;
	WITH bndry_tabl[n_bndrys] DO
		BEGIN
			spread[id_hi]:= LgSNlast - stress_mn;
			centroid[id_hi]:= spread[id_lo]/2 + stress_mn;
		END;

	FOR field := null TO rel_drag DO
		BEGIN
			weight := steps * (spread[field]/(LgSNlast-LgSNfirst));
			temp_position[field]		:= temp_position[field] +
				temp_step *
					weight;	{ temperatures }
			stress_position[field]	:= stress_position[field] +
				((centroid[field] - LgSNfirst)/(LgSNlast-LgSNfirst)) *
					weight*steps;	{ stresses	}
			pointcount[field]			:= pointcount[field] + weight;
		END;

END;	{	Update_Centroids	}
	{------------------------------------------------------------------------}
BEGIN	{	Fields_Loop	}
	n_actual := contournumber + 1;

	FOR k := 1 to C_num_bndrys DO
		WITH bndry_tabl[k] DO
			BEGIN
				id_lo := null;
				id_hi := null;
				stress_lo := SNfirst;
				stress_hi := SNlast;
				stress_mn := (stress_hi + stress_lo)/2.0;
			END;

{	The algorithm assumes that the field_ids[] array is IN ORDER with respect
	to its .stress values, but this is not necessarily true since one or more
	of the contours may be off the plot, in which case its .stress value will
	be above the top-of-plot [n_actual].stress value, or below the [0].stress
	value.
	The solution is to RE-SET these 'sentinel' values [0] and [n_actual] to be
	equal to the highest and lowest contour values IFF they are off the plot.
	This has to be carefully documented because THIS PARTICULAR ALGORITHM as
	used in the rest of this procedure does not need these sentinel values to
	be correctly set to the values at the limits of the plot, whereas the
	algorithm which searched for the contours in the first place DID RELY on
	this.  
	Remember, all the stresses are Lg(normalised) and so -ve, hence the 
	comparison operators are the 'wrong' way round. 24-May-1990 17:00 PMS	}

	IF (field_ids[0].stress >= field_ids[1].stress) THEN
		field_ids[0] := field_ids[1];								{	ALL values	}

	IF (field_ids[n_actual].stress <= field_ids[contournumber].stress) THEN
		field_ids[n_actual] := field_ids[contournumber];	{	ALL values	}

	{ ----- Find the Field boundaries from the field_ids list  ----- }
	i := 0;

	FOR c := 1 to contournumber+1 DO
		BEGIN
			IF (field_ids[c].id <> field_ids[c-1].id) THEN
				BEGIN
					Inc(i);
					WITH bndry_tabl[i] DO
						BEGIN
							id_lo := field_ids[c-1].id;
							id_hi := field_ids[c].id;
							stress_lo := field_ids[c-1].stress;
							stress_hi := field_ids[c].stress;
							stress_mn := (stress_hi + stress_lo)/2.0;
						END;
				END;
		END;
	IF (i > 0) THEN
		BEGIN
			n_bndrys := i;
			boundaries_exist := TRUE;
		END
	ELSE						{	no boundaries !	}
		BEGIN
			n_bndrys := 1;
			boundaries_exist := FALSE;
{$IFDEF debug}
			Writeln(db, 'No field boundaries at this temperature');
{$ENDIF}
			{	Exit;	}	{	Cowards' way out ! Must still check for vertical boundary	}
		END;

	IF boundaries_exist THEN
		BEGIN
			Find_Boundaries;

			{	Should really write a proc. to do this update when there are
				no boundaries too, but a single step off all over for only
				one (pretty big) field should make no big difference.  If the
				whole map is only one field then it won't be labelled at all
				I would guess...24-May-1990 18:05 PMS	}
			Update_Centroids;	
		END;

	{ ----- Find and Mark VERTICAL field boundaries on the plot  ----- }

	{	This algorithm is based on matching up two arrays of boundaries
		each with hi and lo fields and the stress (stress_mn) of the
		boundary; one for this temp. and one for the previous temp. step.
		We increment stress and check each time if the field is the same
		here as it was last temp. If it is not, AND if the previous field
		is NOT one there is a transition to at a lower stress at the
		current temp., then we make a mark.  The reason for that refinement
		is to prevent the vertical algorithm stomping all over some nice
		smooth but steep curves. 22-March-1990 23:46 PMS	}

	{	The algorithm assumes that there is at least one boundary, since we
		removed the Exit statement, this may no longer be true, so we insert
		an sentinel value to catch this special case. 24-May-1990 17:12 PMS	}
	IF NOT boundaries_exist THEN
		BEGIN
			bndry_tabl[1].stress_mn := LgSNfirst;
			bndry_tabl[1].id_hi := field_ids[0].id;
			bndry_tabl[1].id_lo := field_ids[0].id;
			n_bndrys := 1;
		END;

	IF (TN <= 0) THEN
		x_last := 0
	ELSE
		BEGIN
			x_half := round((x_last + x_now)/2);
			i := 1;
			j := 1;
			FOR s := 1 TO steps*2 DO	{	2 * finer mesh	}
				BEGIN
					LgSN := LgSNfirst + 0.5*LgSNstep*(s - 0.5);
					y_half := round(ylength*(1 - (LgSN - LgSNfirst)/
								(LgSNlast - LgSNfirst)));
{$IFDEF detail}
					Write(db,s:3,' ',LgSN:8:3,' ');
					write(db,' ',i:3,j:3,' ');
{$ENDIF}
				{	stress starts low, almost certainly below the first boundary	}
					WHILE (LgSN > bndry_tabl[i].stress_mn) DO
						Inc(i);
					IF (i > n_bndrys) THEN	{	popped off the top	}
						BEGIN
							i := n_bndrys;
							field_now := bndry_tabl[i].id_hi;
							next_down_now := bndry_tabl[i].id_lo;
							next_up_now := field_now;
						END
					ELSE
						BEGIN
							field_now := bndry_tabl[i].id_lo;
							next_up_now := bndry_tabl[i].id_hi;
							IF (i > 1) THEN
								next_down_now := bndry_tabl[i-1].id_lo
							ELSE
								next_down_now := field_now;
						END;
{$IFDEF detail}
					write(db,' ');
					WRITE_FIELDNAME(field_now);
					WRITE_FIELDNAME(next_down_now);
					write(db,i:3);
{$ENDIF}

					WHILE (LgSN > last_bndry_tabl[j].stress_mn) DO
						Inc(j);
					IF (j > last_n_bndrys) THEN	{	popped off the top	}
						BEGIN
							j := last_n_bndrys;
							field_last := last_bndry_tabl[j].id_hi
						END
					ELSE
						field_last := last_bndry_tabl[j].id_lo;
{$IFDEF detail}
					write(db,' ');
					WRITE_FIELDNAME(field_last);
					write(db,j:3);
{$ENDIF}

					IF ( field_now	<> field_last)
					AND (next_down_now <> field_last)
					AND (next_up_now <> field_last) THEN
						{	try to NOT draw on genly sloping boundaries	}
						BEGIN
							DRAW_FIELD_BOUNDARY (x_half,y_half);
{$IFDEF detail}
							write(db,' **');
{$ENDIF}
						END;
{$IFDEF detail}
					writeln(db);
{$ENDIF}
				END;
	END;
	{ ----- Copy the table of boundary points to be used next time  ----- }

	x_last := x_now;
	last_n_bndrys := n_bndrys;
	FOR i := 1 to n_bndrys DO
		last_bndry_tabl[i] :=bndry_tabl[i];

END;	{	Fields_Loop	procedure }
{---------------------------------------------------------------------------}
PROCEDURE CALC_STRAIN_RATES_MAP;

VAR
 	mech,
	field				:	E_mech;

	x1,x2,y1,y2		:	Integer;
	i, step			:	Word;
	c					:	Byte;

	lastTN			:	a_real;
	TNstep			:	a_real;
	last_contour	:	T_contour_reals;
{	contourlevels	:	T_all_contours;		SAVE SPACE for DEBUGGING	}

BEGIN	{Calc_STRAIN_RATES_Map	}

	TNstep		:= (TNlast - TNfirst)/steps;   		{Temperature interval}

	LgSNfirst	:= Ln(SNfirst)/Ln10;
	LgSNlast		:= Ln(SNlast)/Ln10;
	LgSNstep		:= (LgSNlast - LgSNfirst)/steps;			{stress interval}

{ ----- Set up the time contours and markers ----- }

	contour[0]	:= cntrfirst/cntrfactor;
	FOR      c   := 1 to contournumber DO
		contour[c] := contour[c-1]*cntrfactor;

	IF ( contour[0] < 1.0e-20 ) THEN			{base strain rate}
		LowRate		:= contour[0]
	ELSE
		LowRate		:= 1.0e-20;

	sqrt_factor := SQRT(cntrfactor);

{ ----- "Zero" the contour markers and field id counters ----- }

	FOR c := 1 to contournumber DO
		BEGIN
			contourmark[c] := 1.0;
			last_contour[c] := 1.0;
		END;

	FOR mech := null TO rel_drag DO
		BEGIN
			temp_position[mech]      := 0;
			stress_position[mech]      := 0;
			pointcount[mech]  := 0;
		END;

	lastTN		:= TNfirst;

{ ----- Draw the temperature box ----- }

	PLOT_STRAIN_RATES_BOX (LgSNfirst, LgSnlast);

{	PLOT_STRAIN_RATES_INFO;  }
	SetColor(white);

	SetViewPort(xoffset, yoffset, xend, yend, ClipOn);

	Contours_Init;

{ ========== S T A R T == T H E == T E M P E R A T U R E == L O O P ========= }
	skip:=FALSE;
	i:=0;
	REPEAT
		TN         := TNfirst + i*TNstep;

{ ----- Calculate the diffusion rates at the new Temperature ------- }

		DIFFUSION_RATES;

		Contours_Loop (i);
		Fields_Loop (i);	
{ ----- Draw the contours ----- }

		IF i > 0 THEN
			BEGIN
				x1 := round(xlength*(TN - TNfirst)/(TNlast - TNfirst));
				x2 := round(xlength*(lastTN - TNfirst)/(TNlast - TNfirst));
				FOR c := 1 to contournumber DO
					BEGIN
						IF (contourmark[c] < 1/steps) THEN 	{ lowest stress }
							contourmark[c]:=0.0;
						IF (contourmark[c]=0.0) THEN
							y1 := ylength
						ELSE
							y1 := round(ylength*(1 - contourmark[c]));
						IF (last_contour[c]=0.0) THEN
							y2 := ylength
						ELSE
							y2 := round(ylength*(1 - last_contour[c]));
	{	Nested IFs too deep for Turbo4 with 8087 chip ! Compiler BUG !! I had to
		separate the two halves of the IF statement because the OR option
		failed to work correctly: if the first condition was false it failed
		to check the second condition.	}
{						contourlevels [c, i] := x1;		SAVE SPACE	}
						IF (x1 < 3*xlength/4) THEN
							myLine(x1,y1,x2,y2);
						IF (y1 > ylength/4) THEN
							myLine(x1,y1,x2,y2);
					END;
{				Writeln(db);	}
			END;

{ ----- Set values of last_contour ----- }

		lastTN       := TN;
		FOR c := 1 to contournumber DO
			BEGIN
				last_contour[c] := contourmark[c];
			END;

		Flush(db);
		DETECT_SKIP;

		i:=i+1;
	UNTIL (i=steps +1 {+2} ) OR skip;
{  END;	}

{ ============ E N D == T H E == T E M P E R A T U R E == L O O P =========== }

	SetViewPort(0, 0, MaxX, MaxY, ClipOn);

{$IFDEF debug}
	writeln(db);
	writeln(db,'SRcount =',SRcount);
{$ENDIF}

	IDENTIFY_FIELDS;

	IDENTIFY_CONTOURS;

	PLOT_STRAIN_RATES_INFO;	{again, in case it had been overwritten	}

END;       {CALC_STRAIN_RATES_MAP.   }
{---------------------------------------------------------------------------}
PROCEDURE 	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high: a_real; trajnumber:integer);

VAR
	first, last	:	a_real;
{ ----- Identify the trajectories and add the date ----- }

BEGIN
	Flush(db);

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
PROCEDURE PLOT_Indentation_BOX (t_first,t_last,LgHNfirst, LgHNlast: a_real);

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
	{SetGraphMode(GraphMode);}
	BoxDefaults;

{ --------- Draw  Box ----------}

	myLine(xoffset,yoffset,xoffset,yend);
	myLine(xoffset,yoffset,xend,yoffset);
	myLine(xend,yend,xoffset,yend);
	myLine(xend,yend,xend,yoffset);

{ --------- Put on NORMALIZED STRESS scale --------- }
	minor   := 1;	{	because it's a log axis, so minor marks are not useful }

	yscale  := round(LgHNlast*minor - LgHNfirst*minor);

	FOR scale := (round(LgHNfirst*minor)) to (round(LgHNfirst*minor) + yscale - 1) DO
		BEGIN
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
	ClearTextSpace(xof+3*xl/4,yof+delta_y,xof+xl-delta_x,yof+yl/4);

	myLine(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+xlength,yoffset+round(ylength/4));
	myLine(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+round(3*xlength/4),yoffset);
	SetColor(white);

	OurOutTextXY(96,20,'Indentation Creep Trajectories');
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
	Writeln(db,'< CreepCalc. T=',t:8,' dt=',dt:8,' LgHN=', LgHN:8:3,' A=', A:8,' A_dot=',A_dot:8);
	Flush(db);

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
	Writeln(db,'> CreepCalc. T=',t:8,' dt=',dt:8,' LgHN=', LgHN:8:3,' A=', A:8,' A_dot=',A_dot:8);
	Flush(db);
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

	Writeln(db,'++Trajectory begin.');
	Writeln(db,'TN= ',TN:5:2,'  t(s)       dt(s)      LgHN',
		'        A(mm^2)   A_dot(mm^2)');

	REPEAT
		x1 := x2;
		y1 := y2;
		field1 := field2;
		Writeln(db, 'calling Creep_Calc...');
		Creep_Calc(field2);
		Lgt := Ln(t)/Ln10;
		x2 := round(xlength*(Lgt - Lgt_first)/(Lgt_last - Lgt_first));
		y2 := round(ylength*(LgHNlast - LgHN)/(LgHNlast - LgHNfirst));

		Write(db,'|');
		WRITE_FIELDNAME (field2);
		Write(db,'|');
		Writeln(db);

	{ ----- Draw the contours ----- }
		IF (Lgt <= Lgt_first) THEN
			Writeln(db, 'Lgt <= Lgt_first')
		ELSE
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
	Writeln(db,'++Trajectory end.');

END;	{	Trajectory	}
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

	trajnumber := 35;
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

	PLOT_Indentation_INFO;
	SetColor(white);

	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high,trajnumber);

	SetViewPort(xoffset, yoffset, xend, yend, ClipOn);

{	Plot the 300K trajectory first	}
	SetLineStyle(DottedLn,0,NormWidth);
	Trajectory (LgHNfirst,lgHNlast);
	SetLineStyle(SolidLn,0,NormWidth);

{ ========== S T A R T == T H E == T E M P E R A T U R E == L O O P ========= }
	skip:=FALSE;
	i:=0;
	TN := TNtraj_low;
	REPEAT

{ ----- Calculate the diffusion rates at the new Temperature ------- }

		DIFFUSION_RATES;

{ ----- Calculate and Plot the Hardness/time trajectory ------- }
		Trajectory (LgHNfirst,lgHNlast);

{ ----- Detect <CtrlC> key if pressed  ----- }
		DETECT_SKIP;

		TN := TN + TNtraj_step;
		i:=i+1;
	UNTIL (i=trajnumber+1) OR skip;

{ ============ E N D == T H E == T E M P E R A T U R E == L O O P =========== }

	SetViewPort(0, 0, MaxX, MaxY, ClipOn);

	IDENTIFY_FIELDS;

	PLOT_Indentation_INFO;	{again, in case it had been overwritten	}
	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high,trajnumber);

END;       {CALC_INDENTATION_MAP.   }
{ =========================================================================== }
{---------------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
End.
