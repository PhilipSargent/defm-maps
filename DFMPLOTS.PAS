Unit DfmPlots;
{ PMS 26-March-1990 15:06 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   P.M.Sargent and M.F.Ashby        **************
   *************   February 1990                    **************
}
{$IFDEF  contour}		{	ensure compiler directives are consistent	}
{$DEFINE  detail}
{$ENDIF}
{$IFDEF  detail}
{$DEFINE  debug}
{$ENDIF}
{.$R+}    {Range checking on}  {      all these options set in command line }
{.$B+}    {Boolean complete evaluation on}
{.$S+}    {Stack checking on}
{.$I+}    {I/O checking on}
{.$N+}    {Use numeric coprocessor}
{.$E+}	  {Include copy of 8087 Emulator - default anyway}

Interface

PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }

PROCEDURE PLOT_STRAIN_RATES_BOX (LgSNfirst, LgSNlast: real);

{ ----- Constructs box for temperature DFM-map and labels the axes ----- }

PROCEDURE IDENTIFY_CONTOURS;

{ ----- Identify the time contours and add the date ----- }

PROCEDURE IDENTIFY_FIELDS;

PROCEDURE CALC_STRAIN_RATES_MAP;

{$IFDEF indent}
PROCEDURE CALC_Indentation_MAP;
{$ENDIF}

{===========================================================================}

Implementation

Uses
	Crt,
	Dos,
	Printer,
	Graph,
{	Drivers, }{ all the BGI drivers }
	StringIO,
	DfmGlbls,
	DfmModls;

CONST
	C_num_cntrs			=	maxcontournumber+1;
TYPE
	TP_zone_list	=	^T_zone_list;
	T_zone_list		=	RECORD
								x1,y1,x2,y2	:	Word;
								next			:	TP_zone_list;
							END;

	T_all_contours		= ARRAY [1..maxcontournumber,0..max_steps] OF Integer;
	T_contour_reals	= ARRAY [0..maxcontournumber] OF a_real;
	T_stress_fields	= ARRAY [1..max_steps] OF E_mech;

	E_n_bndrys		=	1..numberofmechanisms*2;	{	estimate	}
	T_bndry_item	=	RECORD
								stress_hi	:	a_real;
								id_hi			:	E_mech;
								stress_lo	:	a_real;
								id_lo			:	E_mech;
								stress_mn	:	a_real;
							END;
	T_bndry_table	=	ARRAY [E_n_bndrys] OF T_bndry_item;

	E_n_stress		=	0..C_num_cntrs;	{	Will need to increase this..	}
	T_field_stress	=	RECORD
								stress	:	a_real;
								id			:	E_mech;
							END;
	T_field_ids		=	ARRAY [E_n_stress] OF T_field_stress;

CONST
	{ The names of the various device drivers supported }
	DriverNames : array[0..10] of string[8] =
	('Detect', 'CGA', 'MCGA', 'EGA', 'EGA64', 'EGAMono',
	'RESERVED', 'HercMono', 'ATT400', 'VGA', 'PC3270');

	{ The two text directions available }
	TextDirect : array[0..1] of string[8] = ('HorizDir', 'VertDir');

	{ The Horizontal text justifications available }
	HorizJust  : array[0..2] of string[10] = ('LeftText', 'CenterText', 'RightText');

	{ The vertical text justifications available }
	VertJust   : array[0..2] of string[10] = ('BottomText', 'CenterText', 'TopText');

{$IFDEF indent}
	C_1 = 0.193;	{	1/(3.sqrt(3))	}
	C_2 = 1;
	C_3 = 25.504;	{	Vickers indenters	}
{$ENDIF}

VAR
	GraphDriver :	INTEGER;  { The Graphics device driver }
	GraphMode   :	INTEGER;  { The Graphics mode value }
	Error			:	INTEGER;
	MaxX, MaxY  : word;     { The maximum resolution of the screen }
	HalfX, HalfY: word;
	ErrorCode   :	INTEGER;  { Reports any graphics errors }
	MaxColor    : word;     { The maximum color value available }
	st          : String;   { Dummy string used with Str() and OutText() }
	xoffset,yoffset,xlength,ylength,xend,yend	:	integer;
	xfactor, yfactor	:	REAL;
	Ch          : CHAR;
	skip        : BOOLEAN;
	empty_zones	:	TP_zone_list;

	pointcount		:  T_mecharray;
	temp_position, stress_position	:  T_mecharray;
	contour			:  T_contour_reals;
	contourmark		:	T_contour_reals;
	last_temp_fields	:	T_stress_fields;

	LgSNfirst		:	a_real;
	LgSNlast			:	a_real;
	LgSNstep			:	a_real;
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
	n_actual			:	E_n_stress;
	field_ids		:	T_field_ids;

	n_bndrys, last_n_bndrys			:	E_n_bndrys;
	bndry_tabl, last_bndry_tabl	:	T_bndry_table;

{---------------------------------------------------------------------------}
procedure Abort(Msg : string);
begin
  Writeln(Msg, 'driver: ', GraphErrorMsg(GraphResult));
  Halt(10);
end;
{---------------------------------------------------------------------------}
PROCEDURE Defaults;
{ Select the maximum color in the Palette for the drawing color }
BEGIN
{	GraphMode := GetGraphMode;
	IF ((GraphDriver = HercMono) OR (GraphDriver = EGAMono)) THEN
			SetColor(MaxColor)
	ELSE BEGIN
		SetColor(9 Mod MaxColor);
		SetBkColor(14 Mod MaxColor);
	END;
}
	SetColor(MaxColor);

	SetTextJustify(LeftText, CenterText);
	SetTextStyle(DefaultFont, HorizDir, 1);
	SetViewPort(0, 0, MaxX, MaxY, ClipOn);

	empty_zones:=NIL;	{	should really DISPOSE of the list first..	}
END; { Defaults }

{---------------------------------------------------------------------------}
Function Max(a,b:Real): Real;
begin
	IF (a>b) THEN
		Max := a
	ELSE
		Max := b;
end;	{	function Max	}
{---------------------------------------------------------------------------}
PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }
VAR
	st	:	STRING;
	newmode	:	integer;
BEGIN
	DirectVideo := False;

	IF mode400 THEN
		BEGIN
			GraphDriver:=ATT400;
			GraphMode := ATT400Hi;
			InitGraph(GraphDriver, GraphMode, '');  { activate graphics }
			ErrorCode:=GraphResult;
			{ Leave the error visible, don't fix with autodetect..}
		END
	ELSE	{	NOT mode400	}
		IF modeCGA THEN
			BEGIN
				GraphDriver:=CGA;
				GraphMode := CGAHi;
				InitGraph(GraphDriver, GraphMode, '');  { activate graphics }
				ErrorCode:=GraphResult;
			{	error? try auto-detection }
			{	Leave the error visible, don't fix with autodetect..}
			END
		ELSE	{	neither mode400 nor modeCGA	}
			BEGIN
				GraphDriver := Detect;                  { use autodetection }
				InitGraph(GraphDriver, GraphMode, '');  { activate graphics }
				ErrorCode := GraphResult;               { error? }
			END;

	IF ErrorCode <> grOk THEN
		BEGIN
			CloseGraph;
			Writeln('Graphics initialization error: ',
				GraphErrorMsg(ErrorCode));
			IF (ErrorCode = grFileNotFound) THEN
				BEGIN
					Writeln('=> Ensure that this file is put in the current directory <=');
				END;
			Writeln('This program cannot continue.');
			Finish(6);
		END;

	Randomize;                { init random number generator }
	MaxColor := GetMaxColor;  { Get the maximum allowable drawing color }
	MaxX := GetMaxX;          { Get screen resolution values }
	MaxY := GetMaxY;
	HalfX := Round(MaxX);
	HalfY := Round(MaxY);

	xoffset     := Round(0.125196 * MaxX);
	yoffset     := Round(0.050251 * MaxY);
	xlength     := Round(0.782473 * MaxX);
	ylength     := Round(0.904523 * MaxY);
	xend        := xoffset+xlength;
	yend        := yoffset+ylength;
	xfactor		:= MaxX/639;
	yfactor		:= MaxY/199;

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

BEGIN
	xx1:= Round(xfactor*x1);
	yy1:= Round(yfactor*y1);
	xx2:= Round(xfactor*x2);
	yy2:= Round(yfactor*y2);

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
	Line(xx1,yy1,xx1,yy2);
	Line(xx1,yy1,xx2,yy1);
	Line(xx2,yy2,xx2,yy1);
	Line(xx2,yy2,xx1,yy2);

{	Now add the cleared zone to (the front of) the global list
	of empty zones, but FIRST we SHOULD really check whether we
	are clearing an already-cleard zone! i.e. a label which overlaps
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

	IF ErrorCode <> grOk THEN
		BEGIN
{			SetViewPort(0,0,MaxX,MaxY,ClipOn);
			Str(xx2,ErrorStr);
			ErrorStr:='Graphics SetViewPort error: '+GraphErrorMsg(ErrorCode);
			GetViewSettings(vp);
			Line(vp.x1,vp.y1,vp.x1,vp.y2);
			Line(vp.x1,vp.y1,vp.x2,vp.y1);
			Line(vp.x2,vp.y2,vp.x2,vp.y1);
			Line(vp.x2,vp.y2,vp.x1,vp.y2);

			REPEAT UNTIL keypressed; Ch:=ReadKey;
			CloseGraph;
			WRITELN(ErrorStr);
			WRITELN(x1,'|',xfactor*x1);
			WRITELN(xx1,' ',yy1,' ',xx2,' ',yy2);
			REPEAT UNTIL keypressed; Ch:=ReadKey;
			Initialize;
}
		END
	ELSE
		BEGIN
 			ClearViewPort;
		END;
	SetViewPort(0,0,MaxX,MaxY,ClipOn);

END;	{	ClearTextSpace	}
{---------------------------------------------------------------------------}
PROCEDURE OurOutTextXY(x,y: INTEGER; s: String);
	{	This is to intercept plotting instructions such
		that we can write HPGL and PIC files.	}
VAR
	xx, yy	:	integer;
BEGIN
	xx:= Round(xfactor*x);
	yy:= Round(yfactor*y);
	Graph.OutTextXY(xx,yy,s);
END;	{	OurOutTextXY	}

{---------------------------------------------------------------------------}
PROCEDURE vertical_text(xstart,ystart:integer; lbl:lblstring);

{ Writes a string label vertically in graphics}
VAR
	i	:	Byte;

BEGIN
{  SetTextStyle(DefaultFont, VertDir, 1);
	OurOutTextXY(xstart,ystart+lbllength,lbl);
}
	FOR i:= 0 to lbllength-1 DO
		BEGIN
			OurOutTextXY(xstart,ystart+i*(TextHeight('M')+1),copy(lbl,i+1,1));
		END;

{  SetTextStyle(DefaultFont, HorizDir, 1); }
END;

{---------------------------------------------------------------------------}
PROCEDURE PLOT_STRAIN_RATES_BOX (LgSNfirst, LgSNlast: real);

{ ----- Constructs box for temperature DFM-map and labels the axes ----- }

var
	xscale, yscale   :	INTEGER;
	Tinterval        :	REAL;
	xmark, ymark     :	INTEGER;
	scale					:	INTEGER;
	T, Tnormalised		:	Real;
	S, Sfirst, Slast	:	Real;
	LgSfirst, LgSlast	:	Real;
	minor					:	Byte;	{	The number of minor marks between big marks }

BEGIN
	SetGraphMode(GraphMode);
	Defaults;

{ --------- Draw  Box ----------}

	Line(xoffset,yoffset,xoffset,yend);
	Line(xoffset,yoffset,xend,yoffset);
	Line(xend,yend,xoffset,yend);
	Line(xend,yend,xend,yoffset);

{ --------- Put on NORMALIZED STRESS scale --------- }
	minor   := 1;	{	because it's a log axis, so minor marks are not useful }

	yscale  := round(LgSNlast*minor - LgSNfirst*minor);

	FOR scale := (round(LgSNfirst*minor)) to (round(LgSNfirst*minor) + yscale - 1) DO
		BEGIN
			ymark := yoffset +
				ylength - round((scale - round(LgSNfirst*minor))/yscale*ylength);
			IF (frac(scale/minor) = 0)  THEN
				Line(xoffset,ymark,xend,ymark)
			ELSE
				Line(xoffset,ymark,xoffset+3,ymark);
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
			Line(xend,ymark,xend-6,ymark);

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

	FOR scale := (round(TNfirst*100)) to (round(TNfirst*100) + xscale - 1) DO
		BEGIN
			xmark :=  xoffset +
				round((scale- round(TNfirst*100))/xscale*xlength);
			IF (frac(scale/20) = 0) THEN
			Line(xmark, yend,xmark,yoffset);
			IF (frac(scale/10) = 0) THEN
			Line(xmark, yend,xmark,(yend - 4));
		END;

{ --------- Put on the CENTIGRADE TEMPERATURE scale ---------- }

	xmark     := 0;
	T         := -400;
	Tinterval := 100;
	IF round((TNlast - TNfirst)*tmelt/200) > 10 THEN Tinterval := 200;

	repeat
		T  := T + Tinterval;
		Tnormalised := (T + 273)/tmelt;
		IF (Tnormalised > TNfirst) and (Tnormalised < TNlast) THEN
			xmark := xoffset +
				round((Tnormalised - TNfirst)/(TNlast - TNfirst)*xlength);
		IF (xmark >= xoffset) AND (xmark <= xend) THEN
			Line(xmark,yoffset,xmark,yoffset+3);

		Str(round(T):6,st);
		IF (Tnormalised>=TNfirst) THEN
			IF (Tnormalised<(TNfirst+(Tinterval/tmelt))) THEN
				OurOutTextXY(80,5,st);
	until (Tnormalised > TNlast);

	Str(TNfirst:4:2,st);
	OurOutTextXY(70,196,st);
	Str(TNlast:4:2,st);
	OurOutTextXY(559,196,st);

	Str(round(T - Tinterval):6,st);
	OurOutTextXY(511,5,st);

{ ----- Label horizontal and vertical axes of graph window ----- }

	OurOutTextXY(200,196,' NORMALISED TEMPERATURE T/Tm');
	OurOutTextXY(216,5,'     TEMPERATURE  (C)     ');
	vertical_text(56,32,'NORM SHEARSTRESS');
	vertical_text(599,32,'STRESS   (MPa)  ');

END;   {PLOT_STRAIN_RATES_BOX.    }

{---------------------------------------------------------------------------}
PROCEDURE PLOT_STRAIN_RATES_INFO;

{ ----- Label horizontal and vertical axes of graph window ----- }
VAR
	xof,yof,xl,yl	:	REAL;
	delta_x			:	REAL;
	delta_y			:	REAL;

BEGIN
	DATE_AND_TIME;

	xof    := 0.125196 * 640;
	yof    := 0.050251 * 200;
	xl     := 0.782473 * 640;
	yl     := 0.904523 * 200;

	delta_x := 6/xfactor;										{ avoid axes marks }
	delta_y := 6/yfactor;										{ avoid axes marks }
	ClearTextSpace(xof+3*xl/4,yof+delta_y,xof+xl-delta_x,yof+yl/4);

	Line(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+xlength,yoffset+round(ylength/4));
	Line(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+round(3*xlength/4),yoffset);

	OurOutTextXY(465,16,matlname);
	Str((Gsize*1.0e6):4:1,st);
	OurOutTextXY(465,24,'d = '+st+' um');
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

	Line(x-s1, y, x+s1,y);
	Line(x-s1, y+s2, x+s1,y+s2);

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
	Line(x_last, y_last, x_now, y_now);
	SetLineStyle(SolidLn,0,NormWidth);

END;   {DRAW_FIELD_LINE   }
{---------------------------------------------------------------------------}
PROCEDURE IDENTIFY_CONTOURS;

{ ----- Identify the time contours and add the date ----- }

BEGIN

	ClearTextSpace(96,156,257,183);
	OurOutTextXY(96,162,'    CONTOURS     ');
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

{	local versions of these..	}
CONST
	xoffset	=	0.125196*639;
	yoffset	=	0.050251*199;
	xend		=	xoffset + 0.782473*639;
	yend		=	yoffset + 0.904523*199;
VAR
	P1,P2				:	integer;
	r1,r2				:	a_real;
	x1,y1,x2,y2		:	a_real;
	x_shift			:	a_real;
	y_shift			:	a_real;
	x0,y0				:	Word;
	mech				:	E_mech;
BEGIN
{ This procedure had the implicit assumption that there were 80
	lines to the screen, even though it was general with respect to
	the number of graphics pixels on the screen.
}
{ ----- Position and print the remaining field labels ----- }

	FOR mech := null TO rel_drag DO
		IF (pointcount[mech] > (steps*steps/100)) and (pointcount[mech] > 4) THEN
			BEGIN
				r1  := ((temp_position[mech]/steps)/pointcount[mech]*64) + 7;
				r2  := (1 - stress_position[mech]/(pointcount[mech]*steps))*22 + 2;

{ ----- Don't check for validity here in character co-ords, but in
			graphics co-ords after conversion. PMS 4-February-1988 10:50 	}
				CASE { mechID[mech] } mech OF
					null:  		st:='ELASTIC';
					re_cryst	:	st:='RECRYST';
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
PROCEDURE Contours_Loop (temp_step: Word);
VAR
	k, field,
	lastfield 	:	E_mech;

	c				:	E_n_stress;
	x_half, y_half, y_now:	Integer;
	Rate			:	a_real;
	LgSN			:	a_real;
	hint_stress	:	a_real;
	last_Rate	:	a_real;
	mark			:	a_real;
	last_mark	:	a_real;
	mark_step	:	a_real;
	increment	:	a_real;
	min_rate_on_plot	:	a_real;
	max_rate_on_plot	:	a_real;

BEGIN
	last_Rate	:=	0.0;
	last_mark	:=	0.0;
	stress_step := 1;	{	to stress_stash crashing...	}

	mark_step := LgSNstep/(LgSNlast - LgSNfirst);

	lastfield  := null;
	n_actual	:= contournumber+1;

	STRAIN_RATES (TN, LgSNfirst, Rate, field, hint_stress);
	field_ids[0].stress := LgSNfirst;
	field_ids[0].id     := field;
	min_rate_on_plot := Rate;
{$IFDEF detail}
	Writeln(db);
{$ENDIF}
	STRAIN_RATES (TN, LgSNlast, Rate, field, hint_stress);
	field_ids[n_actual].stress := LgSNlast;
	field_ids[n_actual].id     := field;
	max_rate_on_plot := Rate;
{$IFDEF detail}
	Writeln(db);
	Writeln(db);
{$ENDIF}
	memory_enable := FALSE;	{	not using memory function, uneeded.	}
{ ========== S T A R T == T H E == S T R E S S == L O O P ========= }
	FOR stress_step := steps DOWNTO 1 DO
		BEGIN
		{ ----- Calculate strain rates for LgSN > LgSNfirst ----- }

			LgSN := LgSNfirst + LgSNstep*(stress_step - 0.5);
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);

			mark := (LgSN - LgSNfirst)/(LgSNlast - LgSNfirst);
		{ ----- Identify the appropriate contour ----- }
{$IFDEF contour}
			Writeln(db);
{$ENDIF}
			FOR c := 1 TO contournumber DO
				BEGIN
{$IFDEF contour}
					Write(db,c:2,' ');
{$ENDIF}
					IF (( Rate >= contour[c]/sqrt_factor)
					AND ( Rate <  contour[c]*sqrt_factor )) THEN
					{ ---	Now we know that the strain rate is closer
							to this particular contour than to any other --- }
						BEGIN
							contourmark[c] := mark;

							{	We don't want the interpolation for the fields id	}
							field_ids[c].id     := field;
							field_ids[c].stress := LgSN;

						{ ---	Now some interpolation to shift the position
								of the contour in the right direction --- }
	                  IF (Rate <> 0.0) THEN
   	                  IF (Rate < contour[c]) THEN
									contourmark[c] := mark + mark_step*0.3*
										(contour[c]/Rate)/sqrt_factor
								ELSE
									contourmark[c] := mark - mark_step*0.3*
										(contour[c]/Rate)/sqrt_factor;
						{ ---	End of little interpolation section	--- }

{$IFDEF contour}
							Writeln(db,'within sqrt range, OK ');
{$ENDIF}
						END
					ELSE
					{ ---	Now we check if we have skipped a contour --- }
						BEGIN
{$IFDEF contour}
							Write(db,'NOT within sqrt range ');
{$ENDIF}
							IF ((last_Rate > contour[c]*sqrt_factor)
							AND (Rate < contour[c]/sqrt_factor)) THEN
							{	Descending stress	}
								BEGIN
								{	We don't want the interpolation for the fields id	}
									field_ids[c].id     := field;
									field_ids[c].stress := LgSN;
									IF ((last_Rate <> 0.0)
     			            	AND (Rate <> 0.0)) THEN
										contourmark[c] := last_mark - mark_step*
											(Ln(last_Rate) - Ln(contour[c]))/
											(Ln(last_Rate) - Ln(Rate))
									ELSE
										contourmark[c] := last_mark - mark_step*0.5;
{$IFDEF contour}
									Writeln(db,' but skipped, OK ');
{$ENDIF}
								END
							ELSE	{	unset contours are off the plot	}
								BEGIN
{$IFDEF contour}
									Write(db,' but off the plot.. ');
{$ENDIF}
									IF (Rate <= min_rate_on_plot) THEN
										BEGIN
											field_ids[c].id     := field_ids[0].id;
											field_ids[c].stress := field_ids[0].stress;
{$IFDEF contour}
											Writeln(db,' under the bottom, OK ');
{$ENDIF}
										END
									ELSE IF (Rate >= max_rate_on_plot) THEN
										BEGIN
											field_ids[c].id     :=
												field_ids[n_actual].id;
											field_ids[c].stress :=
												field_ids[n_actual].stress;
{$IFDEF contour}
											Writeln(db,' over the top, OK ');
{$ENDIF}
										END
									ELSE
										BEGIN
{$IFDEF contour}
											Writeln(db,' missed this time, OK ');
{$ENDIF}
										END;	{	catchall Else block	}
								END;	{	unset contours off plot	}
						END;		{	check if we missed a contour	}

				END;	{	For loop c: 1 -> contournumber	}

			last_Rate	:=	Rate;
			last_mark	:= mark;

			{ ----- Identify changes of mechanism ----- }
			IF (lastfield  <> field) THEN
				BEGIN
					lastfield := field;
{$IFDEF detail}
					IF (stress_step < steps) THEN
							Write(db,'  x');
{$ENDIF}
				END;

{$IFDEF detail}
			Writeln(db);
{$ENDIF}

		END;	{	stress_step For loop	}
{ ========== E N D == T H E == S T R E S S == L O O P ========= }

{$IFDEF detail}
	Writeln(db);
	Write(db, '                    ',
		field_ids[n_actual].stress:8:3,' ');
	WRITE_FIELDNAME(field_ids[n_actual].id);
	WriteLn(db);
	FOR c := contournumber DOWNTO 1 DO
		BEGIN
			Write(db, (Ln(contour[c])/Ln10):8:1,
				'  ',contourmark[c]:8:3,
				'  ',field_ids[c].stress:8:3,' ');
			WRITE_FIELDNAME(field_ids[c].id);
			WriteLn(db);
		END;
	Write(db, '                    ',
		field_ids[0].stress:8:3,' ');
	WRITE_FIELDNAME(field_ids[0].id);
{$ENDIF}

END;	{	Contours_Loop	procedure }
{---------------------------------------------------------------------------}
PROCEDURE Fields_Loop (temp_step: Word);

CONST
	C_num_cntrs			=	maxcontournumber+1;
VAR
	field,
	field_now,
	field_last,
	next_down_now,
	next_up_now	:	E_mech;
	centroid	:	T_mecharray;
	spread	:	T_mecharray;
	Rate			:	a_real;
	LgSN			:	a_real;
	hint_stress	:	a_real;
	weight		:	a_real;
	re_do			:	BOOLEAN;
	x_half, y_half, y_now:	Integer;
	c, i, j, item	:	E_n_stress;
	s		:	Word;	{	stress_step	}

BEGIN
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
	n_bndrys := i;

	{ ----- Find the Field boundaries more accurately  ----- }
	{	Note the trouble we go to in order to keep the table sorted,
		so that we don't have to sort it later.	22-March-1990 }
	i := 0;
	REPEAT
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
	{ ----- Keep track of mean position of field  ----- }
	FOR field := null TO rel_drag DO
		BEGIN
			spread[field]:= 0;
			centroid[field]:= 0;
		END;

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

	x_now := round(xlength*(TN - TNfirst)/	(TNlast - TNfirst));

	{ ----- Draw a thick, dashed line for the field boundary  ----- }

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

	IF NOT (TN <= 0) THEN
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
		WITH bndry_tabl[i] DO
			BEGIN
				last_bndry_tabl[i].stress_lo	:= stress_lo;
				last_bndry_tabl[i].id_lo 		:= id_lo;
				last_bndry_tabl[i].stress_hi	:= stress_hi;
				last_bndry_tabl[i].id_hi 		:= id_hi;
				last_bndry_tabl[i].stress_mn	:= stress_mn;
			END;	{	With block and For loop	}

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
{		contourlevels	:	T_all_contours;		SAVE SPACE for DEBUGGING	}

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

	FOR step := steps DOWNTO 1 DO
		last_temp_fields [step] := null;

	lastTN		:= TNfirst;

{ ----- Draw the temperature box ----- }

	PLOT_STRAIN_RATES_BOX (LgSNfirst, LgSnlast);

	PLOT_STRAIN_RATES_INFO;

	SetViewPort(xoffset, yoffset, xend, yend, ClipOn);

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
							Line(x1,y1,x2,y2);
						IF (y1 > ylength/4) THEN
							Line(x1,y1,x2,y2);
					END;
{				Writeln(db);	}
			END;

{ ----- Set values of last_contour ----- }

		lastTN       := TN;
		FOR c := 1 to contournumber DO
			BEGIN
				last_contour[c] := contourmark[c];
			END;
{$IFDEF debug}
		Flush(db);
{$ENDIF}
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
{$IFDEF indent}
PROCEDURE 	IDENTIFY_TRAJECTORIES (TNtraj_low,TNtraj_high: a_real; trajnumber:integer);

VAR
	first, last	:	a_real;
{ ----- Identify the trajectories and add the date ----- }

BEGIN

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
	xscale, yscale   :	INTEGER;
	Tinterval        :	REAL;
	t						:	REAL;
	xmark, ymark     :	INTEGER;
	scale					:	INTEGER;
	H, HNfirst, HNlast	:	a_real;
	Hfirst, Hlast		:	a_real;
	LgHfirst, LgHlast	:	a_real;
	minor					:	Byte;	{	The number of minor marks between big marks }

BEGIN
	SetGraphMode(GraphMode);
	Defaults;

{ --------- Draw  Box ----------}

	Line(xoffset,yoffset,xoffset,yend);
	Line(xoffset,yoffset,xend,yoffset);
	Line(xend,yend,xoffset,yend);
	Line(xend,yend,xend,yoffset);

{ --------- Put on NORMALIZED STRESS scale --------- }
	minor   := 1;	{	because it's a log axis, so minor marks are not useful }

	yscale  := round(LgHNlast*minor - LgHNfirst*minor);

	FOR scale := (round(LgHNfirst*minor)) to (round(LgHNfirst*minor) + yscale - 1) DO
		BEGIN
			ymark := yoffset +
				ylength - round((scale - round(LgHNfirst*minor))/yscale*ylength);
			IF (frac(scale/minor) = 0)  THEN
				Line(xoffset,ymark,xend,ymark)
			ELSE
				Line(xoffset,ymark,xoffset+3,ymark);
		END;

{ --------- Put on ABSOLUTE STRESS scale ---------- }
	{	in Mpa, but shmod is in GPa so multiply by 1000	}

	Hfirst	:=	shmod*HNfirst*1.0e3;	{	shmod is at 300 K	}
	Hlast 	:=	shmod*HNlast *1.0e3;	{	shmod is at 300 K	}
	LgHfirst	:=	Ln(Hfirst)/Ln10;
	LgHlast 	:=	Ln(Hlast)/Ln10;

	IF (Hfirst <= 1.0e-9) THEN
		BEGIN
			OurOutTextXY(xoffset+2,100,'Error, low hardness limit too low!');
			Str(Hfirst:4:1,st);
			OurOutTextXY(xoffset+2,105,st);
			IF NOT modefast THEN
				Repeat Until Keypressed;
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
			Line(xend,ymark,xend-6,ymark);

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
			Line(xmark,yend,xmark,yend-6);

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
	vertical_text(56,32,'NORM. HARDNESS  ');
	vertical_text(599,32,'HARDNESS (MPa)  ');

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

	xof    := 0.125196 * 640;
	yof    := 0.050251 * 200;
	xl     := 0.782473 * 640;
	yl     := 0.904523 * 200;

	delta_x := 6/xfactor;										{ avoid axes marks }
	delta_y := 6/yfactor;										{ avoid axes marks }
	ClearTextSpace(xof+3*xl/4,yof+delta_y,xof+xl-delta_x,yof+yl/4);

	Line(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+xlength,yoffset+round(ylength/4));
	Line(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+round(3*xlength/4),yoffset);

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
{	Area of indentation A is in sq.mm, Load is in N, so H is MPa	}
	t := t + dt;
	A_dot := Rate * C_2 * C_3 * 0.5 /A;

{	We want dt to be such that the change in A is < 100%	}
	IF (A_dot*dt > {0.1*} A) THEN
		dt := 0.1*A/A_dot
	ELSE
		dt := dt * 2;
	A := A + A_dot*dt;
	H := Load/A;				{	MPa	}
{	shear_mod is in GPa, so convert H to GPa before dividing	}
	lgHN := Ln(H * 1.0e-3 /shear_mod)/Ln10;

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
	Write(db,'CreepCalc ',t:8,' ',dt:8,' ', LgHN:8:3,' ', A:8,' ',A_dot:8,' ');
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
{$IFDEF debug}
	Writeln(db,'TN= ',TN:5:2,'  t(s)       dt(s)      LgHN',
		'        A(mm^2)   A_dot(mm^2)');
{$ENDIF}
	REPEAT
		x1 := x2;
		y1 := y2;
		field1 := field2;
		Creep_Calc(field2);
		Lgt := Ln(t)/Ln10;
		x2 := round(xlength*(Lgt - Lgt_first)/(Lgt_last - Lgt_first));
		y2 := round(ylength*(LgHNlast - LgHN)/(LgHNlast - LgHNfirst));

{$IFDEF debug}
		WRITE_FIELDNAME (field2);
{$ENDIF}

	{ ----- Draw the contours ----- }
		IF (Lgt <= Lgt_first) THEN
{$IFDEF debug}
			Writeln(db)
{$ENDIF}
		ELSE
			BEGIN
				Line(x1,y1,x2,y2);
{$IFDEF debug}
				Writeln(db,' *');
{$ENDIF}
				IF (field1 <> field2) THEN
					BEGIN
						x := round((x1+x2)/2);
						y := round((y1+y2)/2);
						Line(x-s1, y, x+s1,y);
						Line(x-s1, y+s2, x+s1,y+s2);
					END;
			END;
		DETECT_SKIP;
	UNTIL (Lgt > Lgt_last) OR skip;

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
	LgHNlast		:= -1;

	Load := 0.1;	{	MN	}
	t_first := 0.005;
	t_last := 5e7;

	Lgt_first	:=	Ln(t_first)/Ln10;
	Lgt_last 	:=	Ln(t_last)/Ln10;
	Lgt_step		:= (Lgt_last - Lgt_first)/steps;

	stress_step := steps div 2;	{	needed by StressFunction	}

	trajnumber := 35;
	TNtraj_low := 0.15;
	TNtraj_high := 0.95;
	TNtraj_step		:= (TNtraj_high - TNtraj_low)/trajnumber;   		{Temperature interval}

	quit := FALSE;
	t := t_first;
	Load := 1;	{	in N, 1kgf. is 9.81 N, so 1 N is about 100gf.	}
	BaseRate := 1e-4;
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
	Writeln(db,' Stress Begin count   Rate      LgSN     epsilon');
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

{ ----- "Zero" field id counters ----- }

	FOR mech := null TO rel_drag DO
		BEGIN
			temp_position[mech]      := 0;
			stress_position[mech]      := 0;
			pointcount[mech]  := 0;
		END;

{ ----- Draw the Indentation box ----- }

	PLOT_Indentation_BOX (t_first, t_last, LgHNfirst, LgHNlast);

	PLOT_Indentation_INFO;

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
{$ENDIF}	{ indent }
{---------------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
	SRcount := 0;
End.
