Unit DfmGraph;
{ PMS 01-December-2020 16:30:48 }
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
{$R+}	{Range checking on}
{$B+}	{Boolean complete evaluation on}
{$S+}	{Stack checking on}
{$I+}	{I/O checking on}

Interface

USES
	DfmGlbls,
	Graph;

CONST
	xVGA = 640;	{	x width  of original Turbo Pascal graphics device }
	yVGA = 200; {	y height of original Turbo Pascal graphics device }

VAR
	MaxX		:	word;     { The maximum resolution of the device m800x600 0..699}
	MaxY		:	word;     { The maximum resolution of the device m800x600 0..599}

	lastcolor,
	nowcolor	:	INTEGER;
	
	xoffset,
	yoffset		:	SMALLINT;
	xlength,
	ylength		:	SMALLINT;
	xend,yend	:	SMALLINT;
	xfactor, 
	yfactor		:	REAL;
	
	TextDir		:	INTEGER;

PROCEDURE GraphicsErrorDump;
	
PROCEDURE myLine(xx1,yy1,xx2,yy2: SMALLINT);

PROCEDURE myRectangle(xx1,yy1,xx2,yy2: SMALLINT);

PROCEDURE myCircle(x,y,r: SMALLINT);

PROCEDURE Initialize;

PROCEDURE CloseSVG;

PROCEDURE Show_Msg (s:String);

PROCEDURE ClearTextSpace(x1,y1,x2,y2: SMALLINT; border:BOOLEAN);

PROCEDURE MyPlotText(x,y: SMALLINT; s: String);

PROCEDURE MySetColor(color: INTEGER);

FUNCTION MyGetColor:  INTEGER;

FUNCTION MyGetBitColor(color: INTEGER): String;

PROCEDURE MySetTextDir(direction: INTEGER);

PROCEDURE MySetViewPort(x1, y1, x2, y2: SMALLINT; clip: BOOLEAN);

PROCEDURE MyGetViewPort(VAR vp:	Graph.ViewPortType);

PROCEDURE MyClearViewPort;

{===========================================================================}

Implementation

USES
	Crt,
	Dos,
	Printer,
	StringIO,
	DfmModls;

VAR
	GraphDriver :	INTEGER;  { The Graphics device driver }
	GraphMode   :	INTEGER;  { The Graphics mode value }
	Error		:	INTEGER;
	ErrorCode   :	INTEGER;  { Reports any graphics errors }
	MaxColor    :	WORD;     { The maximum color value available }
	MyVP		:	Graph.ViewPortType;
{
TYPE
Graph.ViewPortType = record
						x1: SmallInt;
						y1: SmallInt;
						x2: SmallInt;
						y2: SmallInt;
						Clip: Boolean;
					end; }
{---------------------------------------------------------------------------}
PROCEDURE MySetViewPort(x1, y1, x2, y2: SMALLINT; clip: BOOLEAN);
{	ViewPorts work very differently in SVG compared with the Graph Unit,
	so we need to make viewport adjustments whenever we plot anything }
BEGIN
	Graph.SetViewPort(x1, y1,  x2, y2, clip);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

	MyVP.x1 := x1;
	MyVP.y1 := y1;
	MyVP.x2 := x2;
	MyVP.y2 := y2;
	MyVP.clip := clip;
	writeln(db,'Set ViewPort: (',x1:5,y1:5,'), (',x2:5,y2:5,')');
END;
{---------------------------------------------------------------------------}
PROCEDURE MyGetViewPort(VAR vp:	Graph.ViewPortType);
BEGIN
	Graph.GetViewSettings(vp);
	IF vp.x1<>MyVP.x1 THEN
		BEGIN
			writeln(db,'Graphics GetViewSettings <> MyGetViewPort error ',vp.x1, MyVP.x1);
			Finish(8);
		END;
END;
{---------------------------------------------------------------------------}
PROCEDURE MyClearViewPort;
BEGIN
	Graph.ClearViewPort;
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
END;
{---------------------------------------------------------------------------}
PROCEDURE MyTransformPoint(VAR x,y: SMALLINT);
{ Viewport transformation for SVG output }
{ from 0..MaxX to xoffset..xend 
	i.e. 0..MaxX to MyVP.x1..MyVP.x2 }
VAR
	xlen	:	SMALLINT;
	ylen	:	SMALLINT;
	
BEGIN
	xlen := MyVP.x2 - MyVP.x1; { this should be correct ?}
	ylen := MyVP.y2 - MyVP.y1; { this should be correct ?}
	
	xlen := MaxX; { but this actually works - the plotting procedure is at fault }
	ylen := MaxY; { but this actually works - the plotting procedure is at fault }
	
	x := MyVP.x1 + round(x*xlen/MaxX);
	y := MyVP.y1 + round(y*ylen/MaxY);

	IF MyVP.clip THEN
		BEGIN
			{ if we have the calculation correct it will be inside }
		END;
END;
{---------------------------------------------------------------------------}
PROCEDURE GraphicsErrorDump;
BEGIN
	ErrorCode := GraphResult;               { error? }
	Writeln('Graphics  error: ',
		GraphErrorMsg(ErrorCode));
	Writeln(db,'Graphics  error: ',
		GraphErrorMsg(ErrorCode));
	CloseGraph;
	
	CloseSVG;
	Close(db);
	Finish(6);
END;
{---------------------------------------------------------------------------}
PROCEDURE MySetColor(color: INTEGER);
{ It looks as if it would be nicer to have separate colour settings for TEXT
	and LINES, would reduce color swapping a lot when constructing axes }
BEGIN
	lastcolor := nowcolor;
	nowcolor := color;
	SetColor(nowcolor);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

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
FUNCTION MyGetBitColor(color: SMALLINT): String;
VAR
	RedValue, 
	GreenValue, 
	BlueValue	:	SMALLINT;
	r, g, b		:	String;
BEGIN 
	GetRGBPalette(color, RedValue, GreenValue, BlueValue);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

	Str(RedValue,r);
	Str(GreenValue,g);
	Str(BlueValue,b);
	MyGetBitColor := 'rgb(' + r + ',' + g + ',' + b + ')';
END; { Function MyGetBitColor() }
{---------------------------------------------------------------------------}
procedure	myLine(xx1,yy1,xx2,yy2: SMALLINT);
{ Procedure in the original TurboPascal but unaccountably not documented in fpc }
VAR
	rgb:	String;
BEGIN
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
	Graph.MoveTo(xx1,yy1);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

	{	using current nowcolor }
	Graph.LineTo(xx2,yy2);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

{ --- SVG section --- }	
	MyTransformPoint(xx1,yy1);
	MyTransformPoint(xx2,yy2);
	
	IF (nowcolor <> WHITE) THEN 
		rgb := MyGetBitColor(nowcolor)
	ELSE
		rgb := MyGetBitColor(BLACK);
	writeln(svg,'<line x1="',xx1,'" y1="',yy1,'" x2="',xx2,'" y2="',yy2,'"  style="stroke:',rgb,';"/>');
END; { MyLine }
{---------------------------------------------------------------------------}
PROCEDURE MyRectangle(xx1,yy1,xx2,yy2: SMALLINT);
VAR
	rgb:	String;

BEGIN 
	Rectangle(xx1,yy1,xx2,yy2);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
{ --- SVG section --- }	
	MyTransformPoint(xx1,yy1);
	MyTransformPoint(xx2,yy2);
	IF (nowcolor <> WHITE) THEN 
		rgb := MyGetBitColor(nowcolor)
	ELSE
		rgb := MyGetBitColor(BLACK);
	{SVG equivalent is an opaque white filled, red-edged rectangle}
	writeln(svg,'<rect x="',xx1,'" y="',yy1,'" width="',xx2-xx1,'" height="',yy2-yy1,'"');
	writeln(svg,'    style="stroke: ',rgb,'; fill: #ffffff; fill-opacity: 1.0;" />');
END; { MyRectangle }
{---------------------------------------------------------------------------}
PROCEDURE MyCircle(x,y,r: SMALLINT);
VAR
	rgb:	String;

BEGIN 
	Circle(x,y,r);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
{ --- SVG section --- }	
	MyTransformPoint(x,y);
	IF (nowcolor <> WHITE) THEN 
		rgb := MyGetBitColor(nowcolor)
	ELSE
		rgb := MyGetBitColor(BLACK);
	{SVG equivalent is a semi-transparent (whatever current colour is)-filled circle}
	writeln(svg,'<circle cx="',x,'" cy="',y,'" r="',r,'"');
	writeln(svg,'    style="fill: ',rgb,'; fill-opacity: 0.5" />');
END; { MyCircle }
{---------------------------------------------------------------------------}
PROCEDURE Show_Msg (s:String);
VAR
	precolor	:	INTEGER;
BEGIN
	Writeln(db,s);
	precolor := MyGetColor;
	MySetColor(RED);
	MyPlotText(10,10,s);
	MySetColor(precolor);
END;	{	Show_Msg	}
{---------------------------------------------------------------------------}
PROCEDURE InitSVG (x,y: INTEGER);
VAR
	svgfilename:	string;
BEGIN
	CASE {E_plottype } plottype OF
		strrate	:		svgfilename := matlname + '.s.svg';
		indent	:		svgfilename := matlname + '.i.svg';
		temp	:		svgfilename := matlname + '.t.svg';
	ELSE
		svgfilename := matlname + '.ERRROR.svg';
	END;	{	Case	}
	
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
	Close(svg);
END;	{	CloseSVG;	}
{---------------------------------------------------------------------------}
PROCEDURE Initialize;
{ Initialize graphics and report any errors that may occur }
CONST
	xfac0	: a_real	= 0.125196; { x-axis origin }
	yfac0	: a_real	= 0.050251; { y-axis origin } 
	xfacN	: a_real	= 0.782473; { x-axis limit }
	yfacN	: a_real	= 0.904523; { y-axis limit }
VAR
	st		:	STRING;
	newmode	:	INTEGER;
	lo, hi, 
	tw, th	: INTEGER;
	found	: BOOLEAN;
BEGIN
	{ We want an 8 bit mode }
	GraphDriver := D8bit;
	GraphMode := m800x600;	{ 0..599 x 0..799 x 0..255 }
	
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
	Writeln(db,'Initializing.. 800x600x256 is OK');
	MaxX := getMaxX;          { Get screen resolution values only after Initgraph() }
	MaxY := getMaxY;

	Randomize;                { init random number generator }

{ --- x/y-offset to x/y-end is the data plotting area inside the axes ---}
	xoffset     := Round(xfac0 * MaxX);
	yoffset     := Round(yfac0 * MaxY);
	xlength     := Round(xfacN * MaxX);
	ylength     := Round(yfacN * MaxY);
	xend        := xoffset+xlength;
	yend        := yoffset+ylength;
	xfactor		:= MaxX/(MaxX-1);
	yfactor		:= MaxY/(MaxY-1);
	
	Graph.SetTextJustify(LeftText, CenterText);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	Graph.SetTextStyle(DefaultFont, HorizDir, 1);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

	MySetColor(WHITE);
	MySetTextDir(Graph.HorizDir);
	MySetViewPort(0, 0, MaxX, MaxY, Graph.ClipOn);

	InitSVG (MaxX+1, MaxY+1); {800x600 not 799x599 }
END; { Initialize }
{---------------------------------------------------------------------------}
PROCEDURE ClearTextSpace(x1,y1,x2,y2: SMALLINT; border:BOOLEAN);
{ These x,y are in the original 640,200 = xVGA,yVGA space 
	This is all very overripe for refactoring! }
VAR
	xx1,
	xx2		:	Word;
	yy1,
	yy2		:	Word;
	Ch			:	CHAR;
	vp			:	Graph.ViewPortType;
	ErrorStr	:	String;
	oldcol		:	Graph.ColorType;
	bitcolor	:	String;

BEGIN
	oldcol := Graph.GetColor;

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

{	Now clear the zone by makin a small viewport and Clearing it	}
	MySetViewPort(xx1,yy1,xx2,yy2,ClipOn);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	MyClearViewPort;
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;

{	restore the viewport to full size plottable area 800x600 }
{ --- BUT SUPPOSE WE HAD PREVIOUSLY SET THE VIEWPORT TO SOMETHING ELSE ?
	we should restore it to previous setting, not reset to default !
	PMS 1/12/2020 --- }
	MySetViewPort(0,0,MaxX,MaxY,ClipOn);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
	IF border THEN
		BEGIN
			MySetColor(RED);
			MyRectangle(xx1,yy1,xx2,yy2); {includes SVG bit }
			MySetColor(oldcol);
		END
	ELSE
		BEGIN
		{ --- SVG section --- }	
			MyTransformPoint(xx1,yy1);
			MyTransformPoint(xx2,yy2);
			{SVG equivalent is an opaque white filled, white-edged rectangle}
			writeln(svg,'<rect x="',xx1,'" y="',yy1,'" width="',xx2-xx1,'" height="',yy2-yy1,'"');
			writeln(svg,'    style="stroke: #ffffff; fill: #ffffff; fill-opacity: 1.0;" />');
		END;
	
	WRITELN(db,'Exiting ClearTextSpace: ',round(x1),' ',round(y1),' ',round(x2),' ',round(y2));
END;	{	ClearTextSpace	}
{---------------------------------------------------------------------------}
PROCEDURE MyPlotText(x,y: SMALLINT; s: String);
	{	This converts 640x200 original coords to current pixel x/y coordinates }
CONST
	SVGOFFX = 4;
	SVGOFFY = 5;
VAR
	xx, yy	:	SMALLINT;
	TextInfo: TextSettingsType; { fpc pascal graphics extenson }
BEGIN
	xx:= Round(xfactor*x*MaxX/xVGA);
	yy:= Round(yfactor*y*MaxY/yVGA);
	Graph.OutTextXY(xx,yy,s);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
	
{ --- SVG section --- }	
{		the origin for SVG text is not quite the same as for the Graph Unit
		so we need ot give a little offset }
	xx := xx + SVGOFFX;
	yy := yy + SVGOFFY;
	write(svg,'<text x="',xx,'" y="',yy,'"');
	IF TextDir = Graph.VertDir THEN
		write(svg,' transform="rotate(-90 ',xx,' ',yy,')"');
	writeln(svg,'>',s,'</text>');
END;	{	MyPlotText	}

{---------------------------------------------------------------------------}
PROCEDURE MySetTextDir(direction: SMALLINT);
{ These constants are defined by fpc rtl-graph unit }
BEGIN
	CASE direction OF
		Graph.VertDir	:		TextDir := Graph.VertDir;
		Graph.HorizDir	:		TextDir := Graph.HorizDir;
	ELSE
		BEGIN
			WriteLn(db,'FAULT in MySetTextDir');
			Finish(8);
		END;
	END; { CASE }
	SetTextStyle(DefaultFont, direction, 1);
	ErrorCode := GraphResult;               { error? }
	IF ErrorCode <> grOk THEN GraphicsErrorDump;
END;
{---------------------------------------------------------------------------}
{ Unit Initialization }
BEGIN
	lastcolor := cyan;
	nowcolor  := magenta;
End.
