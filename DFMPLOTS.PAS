Unit DfmPlots;
{ PMS 24-June-1988 23:18 }

{  *************   COPYRIGHT (C) Materials Group,   **************
   *************   Cambridge University Engineering **************
	*************     Department, Cambridge, UK.     **************
   *************   M.F.Ashby and P.M.Sargent        **************
   *************   April 1988                       **************
}
{$R-}    {Range checking off}
{$B+}    {Boolean complete evaluation on}
{$S+}    {Stack checking on}
{$I+}    {I/O checking on}

Interface

Uses
	Crt,
	Dos,
	Printer,
	Graph,
{	Drivers, }{ all the BGI drivers }
	DfmGlbls,
	DfmModls;

PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }

PROCEDURE CheckDeviceMono;
{ Checks whether the graphics adapter is mono }

PROCEDURE PLOT_TEMPERATURE_BOX (LgSNfirst, LgSNlast: real);

{ ----- Constructs box for temperature DFM-map and labels the axes ----- }

PROCEDURE DRAW_FIELD_BOUNDARY (x,y : Integer);

PROCEDURE IDENTIFY_CONTOURS;

{ ----- Identify the time contours and add the date ----- }

PROCEDURE IDENTIFY_FIELDS;

PROCEDURE CALC_TEMPERATURE_MAP;

{===========================================================================}

Implementation

TYPE
	TP_zone_list	=	^T_zone_list;
	T_zone_list		=	RECORD
								x1,y1,x2,y2	:	Word;
								next			:	TP_zone_list;
							END;

	T_all_contours		= ARRAY [1..maxcontournumber,0..max_steps] OF Integer;
	T_contour_reals	= ARRAY [0..maxcontournumber] OF a_real;
	T_stress_fields	= ARRAY [1..max_steps] OF T_mech;

CONST
	{ The names of the various device drivers supported }
	DriverNames : array[0..10] of string[8] =
	('Detect', 'CGA', 'MCGA', 'EGA', 'EGA64', 'EGAMono',
	'RESERVED', 'HercMono', 'ATT400', 'VGA', 'PC3270');

	{ The five fonts available }
	Fonts : array[0..4] of string[13] =
	('DefaultFont', 'TriplexFont', 'SmallFont', 'SansSerifFont', 'GothicFont');

	{ The five predefined line styles supported }
	LineStyles : array[0..4] of string[9] =
	('SolidLn', 'DottedLn', 'CenterLn', 'DashedLn', 'UserBitLn');

	{ The twelve predefined fill styles supported }
	FillStyles : array[0..11] of string[14] =
	('EmptyFill', 'SolidFill', 'LineFill', 'LtSlashFill', 'SlashFill',
	'BkSlashFill', 'LtBkSlashFill', 'HatchFill', 'XHatchFill',
	'InterleaveFill', 'WideDotFill', 'CloseDotFill');

	{ The two text directions available }
	TextDirect : array[0..1] of string[8] = ('HorizDir', 'VertDir');

	{ The Horizontal text justifications available }
	HorizJust  : array[0..2] of string[10] = ('LeftText', 'CenterText', 'RightText');

	{ The vertical text justifications available }
	VertJust   : array[0..2] of string[10] = ('BottomText', 'CenterText', 'TopText');

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
	sumofI, sumofJ	:  T_mecharray;
	contour			:  T_contour_reals;
	contourmark		:	T_contour_reals;
	last_temp_fields	:	T_stress_fields;
	LgSNfirst		:	a_real;
	LgSNlast			:	a_real;
	LgSNstep			:	a_real;
	TNstep			:	a_real;
	sqrt_factor		:	a_real;

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
			IF ErrorCode <> grOK THEN	{ error? try auto-detection }
				BEGIN
					CloseGraph;
					GraphDriver:=Detect;
					InitGraph(GraphDriver, GraphMode, '');
					ErrorCode := GraphResult;               { error? }
				END;
		END
	ELSE	{	NOT mode400	}
		IF modeCGA THEN
			BEGIN
				GraphDriver:=CGA;
				GraphMode := CGAHi;
				InitGraph(GraphDriver, GraphMode, '');  { activate graphics }
				ErrorCode:=GraphResult;
				IF ErrorCode <> grOK THEN	{ error? try auto-detection }
					BEGIN
						CloseGraph;
						GraphDriver:=Detect;
						InitGraph(GraphDriver, GraphMode, '');
						ErrorCode := GraphResult;               { error? }
					END;
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
			Writeln('Graphics init error: ',
				GraphErrorMsg(ErrorCode));
			Halt(6);
		END;

	Randomize;                { init random number generator }
	MaxColor := GetMaxColor;  { Get the maximum allowable drawing color }
	MaxX := GetMaxX;          { Get screen resolution values }
	MaxY := GetMaxY;
	HalfX := Round(MaxX);
	HalfY := Round(MaxY);

{	ReportStatus;	}

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
PROCEDURE CheckDeviceMono;
{	Checks whether the graphics adapter is mono }
BEGIN
	modemono:=False;
	INITIALIZE;		{	graphics display	}
	GraphMode := GetGraphMode;
	IF (GraphDriver = HercMono) OR (GraphDriver = EGAMono) THEN
			modemono := True;
	DirectVideo := True;
	textmode(LastMode);

END;	{	CheckDeviceMono	}
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
PROCEDURE PLOT_TEMPERATURE_BOX (LgSNfirst, LgSNlast: real);

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

	Sfirst	:=	shmod*SNfirst*1.0e3;
	Slast 	:=	shmod*SNlast *1.0e3;
	LgSfirst	:=	Ln(Sfirst)/Ln10;	
	LgSlast 	:=	Ln(Slast)/Ln10;
	
	IF (Sfirst <= 1.0e-9) THEN 
		BEGIN
			OurOutTextXY(xoffset+2,100,'Error, low stress limit too low!');
			Str(Sfirst:4:1,st);
			OurOutTextXY(xoffset+2,105,st);
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

END;   {PLOT_TEMPERATURE_BOX.    }

{---------------------------------------------------------------------------}
PROCEDURE PLOT_TEMPERATURE_INFO;

{ ----- Label horizontal and vertical axes of graph window ----- }
VAR
	xof,yof,xl,yl	:	REAL;

BEGIN
	DATE_AND_TIME;

	xof    := 0.125196 * 640;
	yof    := 0.050251 * 200;
	xl     := 0.782473 * 640;
	yl     := 0.904523 * 200;
	ClearTextSpace(xof+3*xl/4,yof,xof+xl,yof+yl/4);

	Line(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+xlength,yoffset+round(ylength/4));
	Line(xoffset+round(3*xlength/4),yoffset+round(ylength/4),
		xoffset+round(3*xlength/4),yoffset);

	OurOutTextXY(465,16,matlname);
	Str((Gsize*1.0e6):4:1,st);
	OurOutTextXY(465,24,'d = '+st+' um');
	OurOutTextXY(465,48,date_string);


END;	{	PLOT_TEMPERATURE_INFO	}
{---------------------------------------------------------------------------}
PROCEDURE DRAW_FIELD_BOUNDARY (x,y : Integer);

CONST
	s1  =  2;
	s2  =  1;

BEGIN
	{	This is called within the Stress-Loop, within the Temperature-Loop,
			so the plotting window is already set to the graph axes	}
	{	Nested IFs too deep for Turbo4 with 8087 chip ! Compiler BUG !! I had to
		separate the two halves of the IF statement because the OR option
		failed to work correctly: if the first condition was false it failed
		to check the second condition.	}

	IF (x < 3*xlength/4) THEN 	     {Leave name-box blank}
		BEGIN
			Line(x-s1, y, x+s1,y);
			Line(x-s1, y+s2, x+s1,y+s2);
		END;
	IF (y > ylength/4) THEN 	     {Leave name-box blank}
		BEGIN
			Line(x-s1, y, x+s1,y);
			Line(x-s1, y+s2, x+s1,y+s2);
		END;

END;   {DRAW_FIELD_BOUNDARY.   }
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
	OurOutTextXY(96,170,' First = '+st+' /s ');
	IF ((contour[contournumber] < 99999 ) AND ( contour[contournumber] >= 1 )) THEN
		Str(contour[contournumber]:7:0,st)
	ELSE
		Str(contour[contournumber]:7,st);
	OurOutTextXY(96,178,' Last  = '+st+' /s ');

END;    {IDENTIFY_CONTOURS.    }
{---------------------------------------------------------------------------}
PROCEDURE IDENTIFY_FIELDS;

var
	P1,P2				:	integer;
	r1,r2				:	a_real;
	x1,y1,x2,y2		:	a_real;
	x_shift			:	a_real;
	y_shift			:	a_real;
	x0,y0				:	Word;
	mech				:	T_mech;

BEGIN
{ This procedure had the implicit assumption that there were 80
	lines to the screen, even though it was general with respect to
	the number of graphics pixels on the screen.
}


{ ----- Position and print the remaining field labels ----- }

	FOR mech := null TO rel_drag DO
		IF (pointcount[mech] > (steps*steps/100)) and (pointcount[mech] > 4) THEN
			BEGIN
				r1  := ((sumofI[mech]/steps)/pointcount[mech]*64) + 7;
				r2  := (1 - sumofJ[mech]/(pointcount[mech]*steps))*22 + 2;

{ ----- Don't check for validity here in character co-ords, but in
			graphics co-ords after conversion. PMS 4-February-1988 10:50 	}
				CASE mechID[mech] OF
					null:  st:='null';
					re_cryst	:	st:='RE-CRYST';
					b_diff:  st:='B-DIFF';
					v_diff:  st:='V-DIFF';
					plc_ht:  st:='PL-CRP(HT)';
					plc_lt:  st:='PL-CRP(LT)';
					o_glide:  st:='OBSTCLE';
					pls_drag:  st:='PEIERLS';
					phn_drag:  st:='PHONON';
					rel_drag:  st:='PHONON-2';
					ELSE
						st:='ERROR';
				END;	{	Case	}

				x1:=(r1-1)*639/80;
				y1:=(r2-0.7)*199/25;
				x2:=(r1+Length(st)+0.2)*639/80;
				y2:=(r2+0.5)*199/25;

				x_shift := 0.0;
				IF (x1 < xoffset ) THEN
					x_shift := xoffset - x1 + 1.6;
				IF (x2 > xend ) THEN
					x_shift := xend - x2 - 1.6;

				y_shift := 0.0;
				IF (y1 < yoffset ) THEN
					y_shift := yoffset - y1 + 4;
				IF (y2 > yend ) THEN
					y_shift := yend - y2 - 4;

				x0:=Round(r1*639/80 + x_shift);
				y0:=Round(r2*199/25 + y_shift);
				ClearTextSpace(x1+x_shift,y1+y_shift, x2+x_shift,y2+y_shift);
				OurOutTextXY(x0, y0, st);
			END;

END;    {IDENTIFY_FIELDS.    }
{---------------------------------------------------------------------------}
PROCEDURE Stress_Loop (temp_step: Word);

VAR
	k, field,
	lastfield		:	T_mech;

	c, cc			:	Byte;
	x1, y1		:	Integer;
	Rate			:	a_real;
	LgSN			:	a_real;
	hint_stress	:	a_real;
	last_Rate	:	a_real;
	mark			:	a_real;
	last_mark	:	a_real;
	mark_step	:	a_real;
	increment	:	a_real;
	oldmark		:	T_contour_reals;
	midmark		:	T_contour_reals;
	endmark		:	T_contour_reals;

BEGIN
	last_Rate	:=	0.0;
	last_mark	:=	0.0;

	mark_step := LgSNstep/(LgSNlast - LgSNfirst);

	lastfield  := null;

	FOR c := 1 TO contournumber DO
		oldmark[c] := contourmark[c];

	FOR stress_step := steps DOWNTO 1 DO
		BEGIN
		{ ----- Calculate strain rates for LgSN > LgSNfirst ----- }

			LgSN := LgSNfirst + LgSNstep*(stress_step - 0.5);
			STRAIN_RATES (TN, LgSN, Rate, field, hint_stress);

			mark := (LgSN - LgSNfirst)/(LgSNlast - LgSNfirst);

		{ ----- Identify the appropriate contour ----- }

		{	Writeln(db, 'Rate=',Rate:9);	}
			FOR c := 1 TO contournumber DO
				BEGIN
					IF (( Rate >= contour[c]/sqrt_factor)
					AND ( Rate <  contour[c]*sqrt_factor )) THEN
					{ ---	Now we know that the strain rate is closer
							to this particular contour than to any other --- }
						BEGIN
							contourmark[c] := mark;

						{ ---	Now some interpolation to shift the position
								of the contour in the right direction --- }
	                  IF (Rate <> 0.0) THEN
   	                  IF (Rate < contour[c]) THEN
									contourmark[c] := mark + mark_step*
										(contour[c]/Rate)/sqrt_factor
								ELSE
									contourmark[c] := mark - mark_step*
										(contour[c]/Rate)/sqrt_factor;
						{ ---	End of little interpolation section	--- }

	 						midmark[c] := contourmark[c];
						END
					ELSE
					{ ---	Now we check if we have skipped a contour --- }
						BEGIN
							IF ((last_Rate > contour[c]*sqrt_factor)
							AND (Rate < contour[c]/sqrt_factor)) THEN
							{	Descending stress	}
								IF ((last_Rate <> 0.0)
     			            AND (Rate <> 0.0)) THEN
									contourmark[c] := last_mark - mark_step*
										(Ln(last_Rate) - Ln(contour[c]))/
										(Ln(last_Rate) - Ln(Rate))
								ELSE
									contourmark[c] := last_mark - mark_step*0.5;

							endmark[c] := contourmark[c];

							IF ((last_Rate < contour[c]/sqrt_factor)
							AND (Rate > contour[c]*sqrt_factor)) THEN
							{	Ascending stress	}
								IF ((last_Rate <> 0.0)
     			            AND (Rate <> 0.0)) THEN
									contourmark[c] := last_mark + mark_step*
										(Ln(contour[c]) - Ln(last_Rate))/
										(Ln(Rate) - Ln(last_Rate))
								ELSE
									contourmark[c] := last_mark + mark_step*0.5;
						END;	

				END;

			last_Rate	:=	Rate;
			last_mark	:= mark;

		{ ----- Identify changes of mechanism and plot field boundaries ----- }

			IF (lastfield  <> field) THEN
				BEGIN
					IF ((lastfield <> null)
					AND (field <> null )) THEN
						BEGIN
							x1 := round(xlength*(TN - TNfirst)/
									(TNlast - TNfirst));
							y1 := round(ylength*(1 - (LgSN - LgSNfirst)/
									(LgSNlast - LgSNfirst)));

							DRAW_FIELD_BOUNDARY (x1,y1);
{							Write(db,'  x');	}
						END;
					lastfield := field;
				END;

			IF (last_temp_fields[stress_step]  <> field) THEN
				BEGIN
					IF ((last_temp_fields[stress_step] <> null)
					AND (field <> null )) THEN
						BEGIN
							x1 := round(xlength*(
									(TN - TNfirst)/(TNlast - TNfirst) - 0.5/steps) 
											);
							y1 := round(ylength*(1 - (LgSN - LgSNfirst)/
									(LgSNlast - LgSNfirst)));

							DRAW_FIELD_BOUNDARY (x1,y1);
						END;
					last_temp_fields[stress_step]:=field;
				END;

{			Writeln(db);	}

		{ ----- Find centre of gravity of each field for later identification ----- }

			FOR k := null TO rel_drag DO
				BEGIN
					IF  (field = k)  and  (Rate > LowRate)  THEN BEGIN
						sumofI[k]      := sumofI[k] + temp_step;	{ temperatures }
						sumofJ[k]      := sumofJ[k] + stress_step;	{ stresses	}
						pointcount[k]  := pointcount[k] + 1;
					END;
				END;
		END;	{	stress_step For Loop	}


{	Writeln(db);
	FOR c := contournumber DOWNTO 1 DO
		Writeln(db, (Ln(contour[c])/Ln10):8:1,
			'  ',oldmark[c]:8:3,
			'  ',midmark[c]:8:3,
			'  ',endmark[c]:8:3,
			'    ',contourmark[c]:8:3);
}
{	FOR stress_step := steps DOWNTO 1 DO
		BEGIN
			LgSN := LgSNfirst + LgSNstep*(stress_step - 0.5);
			mark := (LgSN - LgSNfirst)/(LgSNlast - LgSNfirst);
			Write(db,mark:8:3,' ');
			FOR c := 1 TO contournumber DO
				Write(db, oldmark[c]:8:3,'  ',contourmark[c]:8:3);
			Writeln(db);
		END;
}
END;	{	Stress_Loop	procedure }
{---------------------------------------------------------------------------}
PROCEDURE CALC_TEMPERATURE_MAP;

VAR
 	mech,
	field				:	T_mech;

	x1,x2,y1,y2		:	Integer;
	i, step			:	Word;
	c					:	Byte;

	lastTN			:	a_real;
	last_contour	:	T_contour_reals;
	contourlevels	:	T_all_contours;

BEGIN	{Calc_Temperature_Map	}

	DEFINE_UNITS;

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
			sumofI[mech]      := 0;
			sumofJ[mech]      := 0;
			pointcount[mech]  := 0;
		END;

	FOR step := steps DOWNTO 1 DO
		last_temp_fields [step] := null;

	lastTN		:= TNfirst;

{ ----- Draw the temperature box ----- }

	PLOT_TEMPERATURE_BOX (LgSNfirst, LgSnlast);

	PLOT_TEMPERATURE_INFO;

	SetViewPort(xoffset, yoffset, xend, yend, ClipOn);

{ ========== S T A R T == T H E == T E M P E R A T U R E == L O O P ========= }
	skip:=FALSE;
	i:=0;
	REPEAT
		TN         := TNfirst + i*TNstep;	

{ ----- Calculate the diffusion rates at the new Temperature ------- }

		DIFFUSION_RATES;

{ ============== S T A R T == T H E == S T R E S S == L O O P ========= }
		Stress_Loop (i);	
{ ============== E N D == T H E == S T R E S S == L O O P ============= }

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
						contourlevels [c, i] := x1;
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

{ ----- Detect <Esc> key if pressed  ----- }
		IF Keypressed THEN
			BEGIN
				Ch := ReadKey;
				IF Ch = Esc THEN
					skip:=TRUE;                           { skip }
			END;

		i:=i+1;
	UNTIL (i=steps {+1} +2) OR skip;
{  END;	}

{ ============ E N D == T H E == T E M P E R A T U R E == L O O P =========== }

	SetViewPort(0, 0, MaxX, MaxY, ClipOn);

{	Close(db);	}

	IDENTIFY_FIELDS;

	IDENTIFY_CONTOURS;

	PLOT_TEMPERATURE_INFO;	{again, in case it had been overwritten	}

END;       {CALC_TEMPERATURE_MAP.   }

{ =========================================================================== }

End.
