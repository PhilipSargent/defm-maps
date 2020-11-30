Unit DfmGraph;
{ PMS 30-November-2020 15:41:16 }
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

Uses
	DfmGlbls;

PROCEDURE GraphicsErrorDump;
	
PROCEDURE myLine(xx1,yy1,xx2,yy2: Integer);

PROCEDURE myRectangle(xx1,yy1,xx2,yy2: Integer);

PROCEDURE myCircle(x,y,r: Integer);

PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }

PROCEDURE CloseSVG;

PROCEDURE Range_Check (s:String);

PROCEDURE ClearTextSpace(x1,y1,x2,y2: REAL);

PROCEDURE vertical_text(xstart,ystart:integer; lbl:lblstring);

PROCEDURE OurOutTextXY(x,y: INTEGER; s: String);

PROCEDURE MySetColor(color: INTEGER);

FUNCTION MyGetColor:  INTEGER;

FUNCTION MyGetBitColor(color: INTEGER): String;

PROCEDURE BoxDefaults;


VAR
	MaxX  		:	word;     { The maximum resolution of the device m800x600 0..699}
	MaxY  		:	word;     { The maximum resolution of the device m800x600 0..599}

	lastcolor,
	nowcolor	:	INTEGER;
	
	xend,yend	:	INTEGER;
	xfactor, 
	yfactor		:	REAL;

	xoffset,
	yoffset,
	xlength,
	ylength		:	INTEGER;


CONST
	xfac0	: a_real	= 0.125196; { x-axis origin }
	yfac0	: a_real	= 0.050251; { y-axis origin } 
	xfacN	: a_real	= 0.782473; { x-axis limit }
	yfacN	: a_real	= 0.904523; { y-axis limit }

{===========================================================================}

Implementation

Uses
	Crt,
	Dos,
	Printer,
	Graph,
	StringIO,
	DfmModls;

CONST
	xVGA = 640;	{	x width  of original Turbo Pascal graphics device }
	yVGA = 200; {	y height of original Turbo Pascal graphics device }

	{ The two text directions available }
	TextDirect : array[0..1] of string[8] = ('HorizDir', 'VertDir');

	{ The Horizontal text justifications available }
	HorizJust  : array[0..2] of string[10] = ('LeftText', 'CenterText', 'RightText');

	{ The vertical text justifications available }
	VertJust   : array[0..2] of string[10] = ('BottomText', 'CenterText', 'TopText');

VAR
	GraphDriver :	INTEGER;  { The Graphics device driver }
	GraphMode   :	INTEGER;  { The Graphics mode value }
	Error		:	INTEGER;
	ErrorCode   :	INTEGER;  { Reports any graphics errors }
	MaxColor    :	word;     { The maximum color value available }


{---------------------------------------------------------------------------}
PROCEDURE Abort(Msg : string);
begin
	Writeln(Msg, 'GraphErrorMsg(GraphResult): ', GraphErrorMsg(GraphResult));
	Writeln(db,Msg, 'GraphErrorMsg(GraphResult): ', GraphErrorMsg(GraphResult));
  Halt(10);
end;
{---------------------------------------------------------------------------}
PROCEDURE GraphicsErrorDump;
begin
	ErrorCode := GraphResult;               { error? }
	Writeln('Graphics  error: ',
		GraphErrorMsg(ErrorCode));
	Writeln(db,'Graphics  error: ',
		GraphErrorMsg(ErrorCode));
	CloseGraph;
	
	CloseSVG;
	Close(db);
	Finish(6);

end;
{---------------------------------------------------------------------------}
PROCEDURE MySetColor(color: INTEGER);
BEGIN
	lastcolor := nowcolor;
	nowcolor := color;
	SetColor(nowcolor);

END; { MySetColor }
{---------------------------------------------------------------------------}
FUNCTION MyGetColor:  INTEGER;
BEGIN
	IF GetColor <> nowcolor THEN
		BEGIN
			writeln(db,'!nowcolor <> GetColor !');
			nowcolor := GetColor;
		END;
	MyGetColor := nowcolor;

END; { MyGetColor }
{---------------------------------------------------------------------------}
FUNCTION MyGetBitColor(color: SmallInt): String;
VAR
	RedValue, 
	GreenValue, 
	BlueValue	:	SmallInt;
	r, g, b		:	String;

BEGIN 
	GetRGBPalette(color, RedValue, GreenValue, BlueValue);
	Str(RedValue,r);
	Str(GreenValue,g);
	Str(BlueValue,b);
	MyGetBitColor := 'rgb(' + r + ',' + g + ',' + b + ')';

END; { Function MyGetBitColor() }
{---------------------------------------------------------------------------}
procedure 	myLine(xx1,yy1,xx2,yy2: Integer);
{ Procedure in the original TurboPascal but unaccountably not documented in fpc }
VAR
	rgb:	String;
begin
	IF xx1 < 0 THEN 
		BEGIN
			WriteLn(db,'mLine xx1 less than zero! ',xx1);
			xx1 := 0;
		END;
	IF xx2 < 0 THEN 
		BEGIN
			WriteLn(db,'mLine xx2 less than zero! ',xx2);
			xx2 := 0;
		END;
	IF yy1 < 0 THEN 
		BEGIN
			WriteLn(db,'mLine yy1 less than zero! ',yy1);
			yy1 := 0;
		END;
	IF yy2 < 0 THEN 
		BEGIN
			WriteLn(db,'mLine yy2 less than zero! ',yy2);
			yy2 := 0;
		END;
	MoveTo(xx1,yy1);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

	{	using current nowcolor }
	LineTo(xx2,yy2);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	IF (nowcolor <> white) THEN 
		rgb := MyGetBitColor(nowcolor)
	ELSE
		rgb := MyGetBitColor(black);
	writeln(svg,'<line x1="',xx1,'" y1="',yy1,'" x2="',xx2,'" y2="',yy2,'"  style="stroke:',rgb,';"/>');

end; { MyLine }
{---------------------------------------------------------------------------}
PROCEDURE MyRectangle(xx1,yy1,xx2,yy2: Integer);
VAR
	rgb:	String;

BEGIN 
	Rectangle(xx1,yy1,xx2,yy2);
	
	IF (nowcolor <> white) THEN 
		rgb := MyGetBitColor(nowcolor)
	ELSE
		rgb := MyGetBitColor(black);
	{SVG equivalent is an opaque white filled, red-edged rectangle}
	writeln(svg,'<rect x="',xx1,'" y="',yy1,'" width="',xx2-xx1,'" height="',yy2-yy1,'"');
	writeln(svg,'    style="stroke: ',rgb,'; fill: #ffffff; fill-opacity: 1.0;" />');


END; { MyRectangle }
{---------------------------------------------------------------------------}
PROCEDURE MyCircle(x,y,r: Integer);
VAR
	rgb:	String;

BEGIN 
	Circle(x,y,r);
	
	IF (nowcolor <> white) THEN 
		rgb := MyGetBitColor(nowcolor)
	ELSE
		rgb := MyGetBitColor(black);
	{SVG equivalent is an opaque red-filled circle}
	writeln(svg,'<circle cx="',x,'" cy="',y,'" r="',r,'"');
	writeln(svg,'    style="fill: ',rgb,'; fill-opacity: 0.5" />');

END; { MyRectangle }
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
PROCEDURE InitSVG (x,y: integer);

VAR
	svgfilename:	string;
BEGIN
	svgfilename := matlname + '.svg';
	IF CannotOpen(svgfilename) THEN
		BEGIN
			Writeln(' *** Cannot Open SVG File ***');
			Halt(4); 
		END;

	Assign(svg,svgfilename);
	Rewrite(svg);
	Writeln(svg,'<?xml version="1.0"?>');
	Writeln(svg,'<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
	Writeln(svg,'    "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
	Writeln(svg,'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="',x,'" height="',y,'">');
END;	{	InitSVG	}
{---------------------------------------------------------------------------}
PROCEDURE CloseSVG;
BEGIN
	Writeln(svg,'</svg>');
	Flush(svg);
	Close(svg);
END;	{	CloseSVG;	}
{---------------------------------------------------------------------------}
PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }
VAR
	st	:	STRING;
	newmode	:	INTEGER;

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

	xoffset     := Round(xfac0 * MaxX);
	yoffset     := Round(yfac0 * MaxY);
	xlength     := Round(xfacN * MaxX);
	ylength     := Round(yfacN * MaxY);
	xend        := xoffset+xlength;
	yend        := yoffset+ylength;
	xfactor		:= MaxX/(MaxX-1);
	yfactor		:= MaxY/(MaxY-1);
	
	MySetColor(white);

	InitSVG (MaxX+1, MaxY+1); {800x600 not 799x599 }
END; { Initialize }
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
	oldcol		:	ColorType;
	bitcolor	:	String;

BEGIN
	oldcol := GetColor;

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

	MySetColor(green);
	MyRectangle(xx1,yy1,xx2,yy2);

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
	
	MySetColor(red);
	MyRectangle(xx1,yy1,xx2,yy2);
	MySetColor(oldcol);

	WRITELN(db,'Exiting ClearTextSpace: ',round(x1),' ',round(y1),' ',round(x2),' ',round(y2));

END;	{	ClearTextSpace	}
{---------------------------------------------------------------------------}
PROCEDURE OurOutTextXY(x,y: INTEGER; s: String);
	{	This converts 640x200 original coords to current pixel x/y coordinates }

VAR
	xx, yy	:	INTEGER;
	TextInfo: TextSettingsType; { fpc pascal graphics extenson }
BEGIN
	xx:= Round(xfactor*x*MaxX/xVGA);
	yy:= Round(yfactor*y*MaxY/yVGA);
	Graph.OutTextXY(xx,yy,s);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	GetTextSettings(TextInfo);
	
	write(svg,'<text x="',xx,'" y="',yy,'"');
	IF TextInfo.direction = VertDir THEN
		write(svg,' transform="rotate(-90 ',xx,' ',yy,')"');
	writeln(svg,'>',s,'</text>');

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
PROCEDURE BoxDefaults;
{ This is the first time we actually draw graphics on screen }
VAR
	vp: ViewPortType;
BEGIN
	MySetColor(white);
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

END; { BoxDefaults }
{---------------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
	lastcolor := cyan;
	nowcolor  := magenta;
End.
